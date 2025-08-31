//
//  TouchpadMathEngine.swift
//  Composable Mathematical Engine
//
//  Single Responsibility: Compose all mathematical components for touchpad control
//

import Foundation

// Main composition class that brings all components together
class TouchpadMathEngine {
    // Core components
    let touchpadBounds = Bounds2D(width: 250, height: 180)
    let screenBounds = Bounds2D(width: 372, height: 824)
    
    // Transformation
    lazy var coordinateTransform = CoordinateTransform(
        from: TouchpadSpace(),
        to: iPhoneScreenSpace()
    )
    
    // State machine
    let stateMachine = FiniteStateMachine(initialState: TouchpadState.idle)
    
    // Signal processing
    let kalmanFilter = KalmanFilter2D(initialPosition: Vector2D(x: 186, y: 412))
    let lowPassFilter = LowPassFilter2D(cutoffFrequency: 5.0) // 5Hz cutoff
    
    // Dynamics
    let springSystem = SpringDamperSystem(springConstant: 15.0, dampingRatio: 0.8)
    let momentumSystem = MomentumSystem(friction: 0.92)
    
    // Gesture recognition
    let gestureRecognizer = GestureRecognizer()
    
    // Measure theory
    let touchHeatMap = TouchHeatMap(
        bounds: Bounds2D(width: 250, height: 180),
        resolution: 50
    )
    
    // Attractor field for UI elements
    var attractorField: AttractorField?
    
    // Current state
    private var currentPosition = Vector2D(x: 125, y: 90) // Center of touchpad
    private var virtualCursorPosition = Vector2D(x: 186, y: 412) // Center of iPhone
    private var gesturePoints: [Vector2D] = []
    
    init() {
        setupGestureTemplates()
    }
    
    // MARK: - Input Processing Pipeline
    
    func processTouch(at point: Vector2D, phase: TouchPhase) -> CursorUpdate? {
        // 1. Record for heat map
        touchHeatMap.recordTouch(at: point)
        
        // 2. Filter noise
        let filtered = lowPassFilter.filter(point)
        
        // 3. Update Kalman filter
        kalmanFilter.update(measurement: filtered)
        let predicted = kalmanFilter.getPosition()
        
        // 4. Update state machine
        let input: TouchpadState.Input
        switch phase {
        case .began:
            input = .pressStarted
            gesturePoints = [predicted]
        case .moved:
            input = .pressMoved(predicted)
            gesturePoints.append(predicted)
        case .ended:
            input = .pressEnded(predicted)
            
            // Recognize gesture
            if let gesture = gestureRecognizer.recognize(points: gesturePoints) {
                return handleGesture(gesture)
            }
        }
        
        // 5. Process through state machine
        if let output = stateMachine.process(input) {
            return processStateOutput(output, position: predicted)
        }
        
        return nil
    }
    
    // MARK: - State Output Processing
    
    private func processStateOutput(_ output: TouchpadState.Output, position: Vector2D) -> CursorUpdate? {
        switch output {
        case .startHold:
            return CursorUpdate(type: .holdStarted, position: virtualCursorPosition)
            
        case .moveCursor(let delta):
            // Apply momentum
            momentumSystem.addImpulse(delta * 0.1)
            
            // Transform to screen space
            let screenDelta = coordinateTransform.transformVector(delta)
            virtualCursorPosition = screenBounds.clamp(virtualCursorPosition + screenDelta)
            
            // Apply attractor field if present
            if let field = attractorField {
                let force = field.force(at: virtualCursorPosition)
                virtualCursorPosition = virtualCursorPosition + force * 0.1
            }
            
            return CursorUpdate(type: .moved, position: virtualCursorPosition)
            
        case .performClick(let position):
            let screenPos = coordinateTransform.transform(position)
            return CursorUpdate(type: .clicked, position: screenPos)
            
        case .reset:
            resetToCenter()
            return CursorUpdate(type: .reset, position: virtualCursorPosition)
        }
    }
    
    // MARK: - Gesture Handling
    
    private func handleGesture(_ gesture: GestureType) -> CursorUpdate? {
        switch gesture {
        case .tap:
            return CursorUpdate(type: .clicked, position: virtualCursorPosition)
            
        case .doubleTap:
            return CursorUpdate(type: .doubleClicked, position: virtualCursorPosition)
            
        case .swipe(let direction):
            return handleSwipe(direction: direction)
            
        case .longPress:
            return CursorUpdate(type: .longPressed, position: virtualCursorPosition)
            
        default:
            return nil
        }
    }
    
    private func handleSwipe(direction: SwipeDirection) -> CursorUpdate? {
        let swipeDistance: Double = 100
        let swipeVector: Vector2D
        
        switch direction {
        case .up:
            swipeVector = Vector2D(x: 0, y: -swipeDistance)
        case .down:
            swipeVector = Vector2D(x: 0, y: swipeDistance)
        case .left:
            swipeVector = Vector2D(x: -swipeDistance, y: 0)
        case .right:
            swipeVector = Vector2D(x: swipeDistance, y: 0)
        }
        
        virtualCursorPosition = screenBounds.clamp(virtualCursorPosition + swipeVector)
        return CursorUpdate(type: .swiped(direction), position: virtualCursorPosition)
    }
    
    // MARK: - Physics Update
    
    func updatePhysics(deltaTime: Double) -> CursorUpdate? {
        // Update momentum if moving
        if momentumSystem.isMoving {
            virtualCursorPosition = momentumSystem.update(
                currentPosition: virtualCursorPosition,
                deltaTime: deltaTime
            )
            virtualCursorPosition = screenBounds.clamp(virtualCursorPosition)
            return CursorUpdate(type: .moved, position: virtualCursorPosition)
        }
        
        // Update spring system if active
        if let target = attractorField?.nearest(to: virtualCursorPosition),
           virtualCursorPosition.distance(to: target) > 1.0 {
            
            let state = SpringDamperSystem.SystemState(
                position: virtualCursorPosition,
                velocity: kalmanFilter.getVelocity(),
                target: target
            )
            
            let newState = springSystem.evolve(state: state, deltaTime: deltaTime)
            virtualCursorPosition = newState.position
            
            return CursorUpdate(type: .moved, position: virtualCursorPosition)
        }
        
        return nil
    }
    
    // MARK: - Utilities
    
    func resetToCenter() {
        virtualCursorPosition = screenBounds.center
        currentPosition = touchpadBounds.center
        kalmanFilter.reset(to: currentPosition)
        lowPassFilter.reset()
        momentumSystem.reset()
    }
    
    func setAttractors(_ points: [Vector2D]) {
        attractorField = AttractorField(
            attractors: points,
            strength: 50.0,
            radius: 30.0
        )
    }
    
    private func setupGestureTemplates() {
        // Add common gesture templates
        // Circle gesture
        let circlePoints = (0..<32).map { i in
            let angle = Double(i) / 32.0 * 2 * .pi
            return Vector2D(x: cos(angle), y: sin(angle))
        }
        gestureRecognizer.addTemplate(
            GestureTemplate(
                points: circlePoints,
                type: .custom(identifier: "circle"),
                identifier: "circle"
            )
        )
    }
}

// MARK: - Supporting Types

enum TouchPhase {
    case began
    case moved
    case ended
}

struct CursorUpdate {
    enum UpdateType {
        case moved
        case clicked
        case doubleClicked
        case longPressed
        case holdStarted
        case swiped(SwipeDirection)
        case reset
    }
    
    let type: UpdateType
    let position: Vector2D
    let timestamp = Date()
}