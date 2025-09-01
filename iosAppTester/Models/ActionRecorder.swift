//
//  ActionRecorder.swift
//  iosAppTester
//
//  Records user interactions for replay automation
//

import Foundation
import AppKit
import CoreGraphics

class ActionRecorder: ObservableObject {
    
    // MARK: - Types
    
    enum ReplayStyle: String, CaseIterable {
        case human = "Human"
        case efficient = "Fast"
        case smart = "Smart"
        
        var icon: String {
            switch self {
            case .human: return "person.fill"
            case .efficient: return "hare.fill"
            case .smart: return "brain"
            }
        }
        
        var description: String {
            switch self {
            case .human: return "Natural speed with all movements"
            case .efficient: return "Optimized for speed"
            case .smart: return "Intelligent optimization"
            }
        }
    }
    
    enum RecordedAction: Codable {
        // Store both absolute and relative positions
        case mouseMove(x: CGFloat, y: CGFloat, relativeX: CGFloat, relativeY: CGFloat)
        case mouseClick(x: CGFloat, y: CGFloat, relativeX: CGFloat, relativeY: CGFloat, clickCount: Int)
        case mouseDown(x: CGFloat, y: CGFloat, relativeX: CGFloat, relativeY: CGFloat)
        case mouseUp(x: CGFloat, y: CGFloat, relativeX: CGFloat, relativeY: CGFloat)
        case mouseDrag(fromX: CGFloat, fromY: CGFloat, toX: CGFloat, toY: CGFloat, 
                       fromRelX: CGFloat, fromRelY: CGFloat, toRelX: CGFloat, toRelY: CGFloat)
        case keyPress(keyCode: UInt16, modifiers: UInt64)
        case wait(seconds: TimeInterval)
        
        var description: String {
            switch self {
            case .mouseMove(_, _, let relX, let relY):
                return "Move to (\(Int(relX*100))%, \(Int(relY*100))%)"
            case .mouseClick(_, _, let relX, let relY, let count):
                return "Click\(count > 1 ? " x\(count)" : "") at (\(Int(relX*100))%, \(Int(relY*100))%)"
            case .mouseDown(_, _, let relX, let relY):
                return "Mouse down at (\(Int(relX*100))%, \(Int(relY*100))%)"
            case .mouseUp(_, _, let relX, let relY):
                return "Mouse up at (\(Int(relX*100))%, \(Int(relY*100))%)"
            case .mouseDrag(_, _, _, _, let fRelX, let fRelY, let tRelX, let tRelY):
                return "Drag from (\(Int(fRelX*100))%, \(Int(fRelY*100))%) to (\(Int(tRelX*100))%, \(Int(tRelY*100))%)"
            case .keyPress(let code, _):
                return "Key press: \(code)"
            case .wait(let seconds):
                return "Wait \(String(format: "%.1f", seconds))s"
            }
        }
    }
    
    struct Recording: Codable {
        let id: UUID
        var name: String
        let windowBounds: CGRect
        var actions: [RecordedAction]
        let recordedAt: Date
        var annotations: [Int: String] // Action index to annotation mapping
        
        init(name: String, windowBounds: CGRect, actions: [RecordedAction], recordedAt: Date, annotations: [Int: String] = [:]) {
            self.id = UUID()
            self.name = name
            self.windowBounds = windowBounds
            self.actions = actions
            self.recordedAt = recordedAt
            self.annotations = annotations
        }
        
        var duration: TimeInterval {
            actions.compactMap { action in
                if case .wait(let seconds) = action {
                    return seconds
                }
                return nil
            }.reduce(0, +)
        }
    }
    
    // MARK: - Properties
    
    @Published var isRecording = false
    @Published var recordings: [Recording] = []
    @Published var currentActions: [RecordedAction] = []
    @Published var lastCapturedEvent: String = "" // For debugging
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var windowBounds: CGRect?
    private var lastActionTime: Date?
    private var lastMousePosition: CGPoint?
    private var isDragging = false
    private var dragStartPoint: CGPoint?
    private var eventCount = 0
    private var windowMonitorTimer: Timer?
    
    // MARK: - Recording
    
    func startRecording(windowBounds: CGRect) {
        guard !isRecording else { return }
        
        self.windowBounds = windowBounds
        self.currentActions = []
        self.lastActionTime = Date()
        self.isRecording = true
        self.eventCount = 0
        
        print("🔴 Recording started for window at \(windowBounds)")
        print("📍 Window: origin(\(windowBounds.origin.x), \(windowBounds.origin.y)) size(\(windowBounds.width)x\(windowBounds.height))")
        
        // Start monitoring window position changes
        windowMonitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkWindowPosition()
        }
        
        // Monitor BOTH global and local events for better capture
        let eventMask: NSEvent.EventTypeMask = [
            .leftMouseDown, .leftMouseUp, .leftMouseDragged,
            .rightMouseDown, .rightMouseUp,
            .mouseMoved, .keyDown, .keyUp,
            .scrollWheel, .otherMouseDown, .otherMouseUp
        ]
        
        // Global monitor for events outside our app
        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: eventMask,
            handler: { [weak self] event in
                self?.handleEvent(event, isLocal: false)
            }
        )
        
        // Local monitor for events within our app
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: eventMask,
            handler: { [weak self] event in
                self?.handleEvent(event, isLocal: true)
                return event // Pass through the event
            }
        )
        
        print("✅ Event monitors installed (global + local)")
    }
    
    func stopRecording(name: String? = nil) {
        guard isRecording else { return }
        
        isRecording = false
        
        // Stop window monitoring
        windowMonitorTimer?.invalidate()
        windowMonitorTimer = nil
        
        // Remove both monitors
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        
        print("📊 Total events captured: \(eventCount)")
        
        // Save recording
        if !currentActions.isEmpty, let bounds = windowBounds {
            let recording = Recording(
                name: name ?? "Recording \(recordings.count + 1)",
                windowBounds: bounds,
                actions: currentActions,
                recordedAt: Date()
            )
            recordings.append(recording)
            saveRecordings()
            
            print("⏹ Recording stopped: \(currentActions.count) actions recorded")
            
            // Print summary
            var summary: [String: Int] = [:]
            for action in currentActions {
                let key = String(describing: action).split(separator: "(").first ?? "unknown"
                summary[String(key), default: 0] += 1
            }
            print("📈 Action summary: \(summary)")
        } else {
            print("⚠️ No actions recorded")
        }
        
        windowBounds = nil
        lastActionTime = nil
        lastCapturedEvent = ""
    }
    
    private func handleEvent(_ event: NSEvent, isLocal: Bool) {
        guard isRecording,
              let windowBounds = windowBounds else { return }
        
        eventCount += 1
        
        // Get mouse location from NSEvent (bottom-left origin)
        let mouseLocationBottomLeft = NSEvent.mouseLocation
        
        // Convert to top-left origin to match window bounds coordinate system
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let mouseLocationTopLeft = CGPoint(
            x: mouseLocationBottomLeft.x,
            y: screenHeight - mouseLocationBottomLeft.y
        )
        
        // Now both mouse location and window bounds use top-left origin
        let screenLocation = mouseLocationTopLeft
        
        // Disable visual feedback during recording to prevent crashes
        // Visual feedback was causing EXC_BAD_ACCESS errors
        /*
        Task { @MainActor in
            showRecordingFeedback(at: screenLocation, type: event.type)
        }
        */
        
        // Debug logging
        let eventType = String(describing: event.type).replacingOccurrences(of: "NSEvent.EventType.", with: "")
        lastCapturedEvent = "\(eventType) at (\(Int(screenLocation.x)), \(Int(screenLocation.y))) [\(isLocal ? "local" : "global")]"
        print("🎯 Event #\(eventCount): \(lastCapturedEvent)")
        print("   Window bounds: \(windowBounds)")
        
        // IMPORTANT: We need to capture events that occur over the iPhone Mirroring window
        // Even if they're "local" to our app, if the mouse is over the iPhone window area, record them
        // Only skip if it's a local event AND outside the iPhone window bounds
        
        // Check if event is within iPhone Mirroring window bounds
        let windowRect = NSRect(
            x: windowBounds.origin.x,
            y: windowBounds.origin.y,
            width: windowBounds.width,
            height: windowBounds.height
        )
        
        // Check if this is a mouse event
        let isMouseEvent = [.leftMouseDown, .leftMouseUp, .leftMouseDragged, .rightMouseDown, 
                           .rightMouseUp, .mouseMoved, .scrollWheel].contains(event.type)
        
        // For mouse events, only record if within iPhone Mirroring window
        if isMouseEvent {
            if !windowRect.contains(screenLocation) {
                print("⚠️ Mouse event at \(screenLocation) outside iPhone window \(windowRect), skipping")
                return
            } else {
                print("✅ Mouse event at \(screenLocation) INSIDE iPhone window \(windowRect)")
            }
        }
        
        // Add wait time since last action
        if let lastTime = lastActionTime {
            let timeDiff = Date().timeIntervalSince(lastTime)
            if timeDiff > 0.1 { // Only add wait if more than 100ms
                currentActions.append(.wait(seconds: timeDiff))
            }
        }
        
        // Record the action
        switch event.type {
        case .leftMouseDown:
            isDragging = true
            dragStartPoint = screenLocation
            // Calculate relative position within window
            let relX = (screenLocation.x - windowBounds.origin.x) / windowBounds.width
            let relY = (screenLocation.y - windowBounds.origin.y) / windowBounds.height
            
            print("🖱️ Mouse down - Absolute: (\(Int(screenLocation.x)), \(Int(screenLocation.y))), Relative: (\(Int(relX*100))%, \(Int(relY*100))%)")
            
            currentActions.append(.mouseDown(
                x: screenLocation.x, 
                y: screenLocation.y, 
                relativeX: relX, 
                relativeY: relY
            ))
            
        case .leftMouseUp:
            if isDragging, let startPoint = dragStartPoint {
                // Record as drag if mouse moved significantly
                let distance = hypot(screenLocation.x - startPoint.x, screenLocation.y - startPoint.y)
                if distance > 5 {
                    let fromRelX = (startPoint.x - windowBounds.origin.x) / windowBounds.width
                    let fromRelY = (startPoint.y - windowBounds.origin.y) / windowBounds.height
                    let toRelX = (screenLocation.x - windowBounds.origin.x) / windowBounds.width
                    let toRelY = (screenLocation.y - windowBounds.origin.y) / windowBounds.height
                    currentActions.append(.mouseDrag(
                        fromX: startPoint.x,
                        fromY: startPoint.y,
                        toX: screenLocation.x,
                        toY: screenLocation.y,
                        fromRelX: fromRelX,
                        fromRelY: fromRelY,
                        toRelX: toRelX,
                        toRelY: toRelY
                    ))
                } else {
                    // Not a drag - just record mouseUp (mouseDown was already recorded)
                    let relX = (screenLocation.x - windowBounds.origin.x) / windowBounds.width
                    let relY = (screenLocation.y - windowBounds.origin.y) / windowBounds.height
                    
                    print("🖱️ Mouse up - Absolute: (\(Int(screenLocation.x)), \\(Int(screenLocation.y))), Relative: (\(Int(relX*100))%, \(Int(relY*100))%)")
                    
                    // Always record as separate mouseUp - mouseDown was already recorded
                    currentActions.append(.mouseUp(
                        x: screenLocation.x,
                        y: screenLocation.y,
                        relativeX: relX,
                        relativeY: relY
                    ))
                }
            } else {
                let relX = (screenLocation.x - windowBounds.origin.x) / windowBounds.width
                let relY = (screenLocation.y - windowBounds.origin.y) / windowBounds.height
                currentActions.append(.mouseUp(
                    x: screenLocation.x, 
                    y: screenLocation.y,
                    relativeX: relX,
                    relativeY: relY
                ))
            }
            isDragging = false
            dragStartPoint = nil
            
        case .leftMouseDragged:
            // Track dragging but don't record intermediate points
            break
            
        case .mouseMoved:
            // Only record significant moves
            if let lastPos = lastMousePosition {
                let distance = hypot(screenLocation.x - lastPos.x, screenLocation.y - lastPos.y)
                if distance > 20 { // Only record if moved more than 20 pixels
                    let relX = (screenLocation.x - windowBounds.origin.x) / windowBounds.width
                    let relY = (screenLocation.y - windowBounds.origin.y) / windowBounds.height
                    currentActions.append(.mouseMove(
                        x: screenLocation.x, 
                        y: screenLocation.y,
                        relativeX: relX,
                        relativeY: relY
                    ))
                    lastMousePosition = screenLocation
                }
            } else {
                lastMousePosition = screenLocation
            }
            
        case .keyDown:
            currentActions.append(.keyPress(
                keyCode: event.keyCode,
                modifiers: UInt64(event.modifierFlags.rawValue)
            ))
            
        default:
            break
        }
        
        lastActionTime = Date()
    }
    
    // MARK: - Action Filtering
    
    private func filterActions(_ actions: [RecordedAction], style: ReplayStyle) -> [RecordedAction] {
        switch style {
        case .human:
            // Return all actions as-is for natural replay
            return actions
            
        case .efficient:
            // Remove unnecessary movements but KEEP toolbar sequence
            var filtered: [RecordedAction] = []
            var foundToolbarSequence = false
            
            // First, find if there's a click in toolbar area (Home button)
            let hasToolbarClick = actions.contains { action in
                if case .mouseClick(_, _, _, let relY, _) = action {
                    return relY < 0.1
                } else if case .mouseDown(_, _, _, let relY) = action {
                    return relY < 0.1
                }
                return false
            }
            
            if hasToolbarClick {
                // Add essential toolbar activation sequence at the start
                // Move to center top to trigger toolbar (50% width, 5% height)
                filtered.append(.mouseMove(x: 0, y: 0, relativeX: 0.5, relativeY: 0.05))
                filtered.append(.wait(seconds: 0.5)) // Wait for toolbar to appear
                foundToolbarSequence = true
            }
            
            // Now process the actions
            var lastMove: RecordedAction?
            
            for action in actions {
                switch action {
                case .mouseMove(_, _, _, let relY):
                    if relY < 0.1 && foundToolbarSequence {
                        // Skip toolbar moves since we added our own
                        continue
                    }
                    lastMove = action
                    
                case .mouseClick, .mouseDown, .mouseUp:
                    // For toolbar clicks, don't add extra moves
                    if case .mouseClick(_, _, _, let relY, _) = action, relY < 0.1 {
                        filtered.append(action)
                    } else if case .mouseDown(_, _, _, let relY) = action, relY < 0.1 {
                        filtered.append(action)
                    } else if case .mouseUp(_, _, _, let relY) = action, relY < 0.1 {
                        filtered.append(action)
                    } else {
                        // Non-toolbar clicks - add last move if exists
                        if let move = lastMove {
                            filtered.append(move)
                            lastMove = nil
                        }
                        filtered.append(action)
                    }
                    
                case .wait(let seconds):
                    if !foundToolbarSequence || seconds > 1.0 {
                        filtered.append(.wait(seconds: min(seconds, 0.5)))
                    }
                    
                default:
                    filtered.append(action)
                }
            }
            
            return filtered
            
        case .smart:
            // Intelligent filtering - only essential actions
            var filtered: [RecordedAction] = []
            
            // Analyze what this recording does
            let hasToolbarClick = actions.contains { action in
                if case .mouseClick(_, _, _, let relY, _) = action {
                    return relY < 0.1
                } else if case .mouseDown(_, _, _, let relY) = action {
                    return relY < 0.1
                }
                return false
            }
            
            // If it uses toolbar, add proper activation sequence
            if hasToolbarClick {
                // Standard toolbar activation: hover center-top, wait, then click
                filtered.append(.mouseMove(x: 0, y: 0, relativeX: 0.5, relativeY: 0.05))
                filtered.append(.wait(seconds: 0.5))
                
                // Find and add the actual toolbar clicks
                for action in actions {
                    switch action {
                    case .mouseClick(_, _, _, let relY, _) where relY < 0.1,
                         .mouseDown(_, _, _, let relY) where relY < 0.1,
                         .mouseUp(_, _, _, let relY) where relY < 0.1:
                        filtered.append(action)
                    case .keyPress:
                        filtered.append(action)
                    default:
                        break
                    }
                }
            } else {
                // Non-toolbar recording - just keep clicks and essential moves
                var lastMove: RecordedAction?
                
                for action in actions {
                    switch action {
                    case .mouseMove:
                        lastMove = action
                    case .mouseClick, .mouseDown, .mouseUp:
                        if let move = lastMove {
                            filtered.append(move)
                            lastMove = nil
                        }
                        filtered.append(action)
                    case .keyPress:
                        filtered.append(action)
                    case .wait(let seconds) where seconds > 1.0:
                        filtered.append(.wait(seconds: 0.5))
                    default:
                        break
                    }
                }
            }
            
            return filtered
        }
    }
    
    // MARK: - Replay
    
    func replay(_ recording: Recording, in initialWindowBounds: CGRect, style: ReplayStyle = .human, progressHandler: ((Int, Int, String) -> Void)? = nil) async {
        print("▶️ Replaying: \(recording.name) in \(style.rawValue) mode")
        print("📐 Original window: \(recording.windowBounds.size), Current: \(initialWindowBounds.size)")
        
        // Filter actions based on replay style
        let actionsToReplay = filterActions(recording.actions, style: style)
        print("📦 Actions: \(recording.actions.count) original → \(actionsToReplay.count) filtered")
        
        // Ensure iPhone Mirroring window is focused before replay
        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.ScreenContinuity").first {
            app.activate(options: [])
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s to ensure focus
        }
        
        // Smart replay - check window position before each action
        for (index, action) in actionsToReplay.enumerated() {
            // Get current window position for each action
            guard let currentWindow = WindowDetector.getiPhoneMirroringWindow() else {
                print("❌ Window lost during replay at action \(index + 1)")
                
                // Try to find it again
                if let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.ScreenContinuity").first {
                    app.activate(options: [])
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    
                    if let recoveredWindow = WindowDetector.getiPhoneMirroringWindow() {
                        print("✅ Window recovered, continuing...")
                        await executeAction(action, in: recoveredWindow.bounds)
                        continue
                    }
                }
                
                print("❌ Could not recover window, stopping replay")
                break
            }
            
            print("🅰️ Action \(index + 1)/\(recording.actions.count): \(action.description)")
            print("   Window currently at: origin(\(Int(currentWindow.bounds.origin.x)), \(Int(currentWindow.bounds.origin.y)))")
            
            // Report progress
            progressHandler?(index + 1, actionsToReplay.count, action.description)
            
            // IMPORTANT: Use the CURRENT window bounds, not the initial ones!
            // This allows replay to work even if the window has moved
            
            // Check if this is a wait action - if not, add a small delay for stability
            if case .wait = action {
                // Execute wait as-is
                await executeAction(action, in: currentWindow.bounds)
            } else {
                // Execute the action with CURRENT window position
                await executeAction(action, in: currentWindow.bounds)
                
                // Add a small delay between actions for stability
                // This helps ensure the UI has time to respond
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            }
        }
        
        print("✅ Replay complete")
    }
    
    // Public method for executing actions with visual feedback
    func executeActionWithVisualFeedback(_ action: RecordedAction, in windowBounds: CGRect) async {
        // Execute the action first
        await executeAction(action, in: windowBounds)
        
        // Small delay to make actions visible
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        // Optionally show visual feedback - disable if causing issues
        // Commented out to prevent crashes during replay
        /*
        if NSApp?.isActive == true {
            await MainActor.run { [weak self] in
                self?.showSimpleVisualIndicator(for: action, in: windowBounds)
            }
        }
        */
    }
    
    @MainActor
    private func showSimpleVisualIndicator(for action: RecordedAction, in windowBounds: CGRect) {
        // Safety check
        guard NSApp != nil, NSApp.isActive else { return }
        
        // Create a simple, non-blocking visual indicator
        switch action {
        case .mouseClick(_, _, let relX, let relY, _),
             .mouseDown(_, _, let relX, let relY),
             .mouseUp(_, _, let relX, let relY):
            let point = CGPoint(
                x: windowBounds.origin.x + (relX * windowBounds.width),
                y: windowBounds.origin.y + (relY * windowBounds.height)
            )
            showQuickPulse(at: point, color: .green)
            
        case .mouseDrag(_, _, _, _, let fromRelX, let fromRelY, let toRelX, let toRelY):
            let fromPoint = CGPoint(
                x: windowBounds.origin.x + (fromRelX * windowBounds.width),
                y: windowBounds.origin.y + (fromRelY * windowBounds.height)
            )
            let toPoint = CGPoint(
                x: windowBounds.origin.x + (toRelX * windowBounds.width),
                y: windowBounds.origin.y + (toRelY * windowBounds.height)
            )
            showQuickPulse(at: fromPoint, color: .yellow)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.showQuickPulse(at: toPoint, color: .orange)
            }
            
        case .mouseMove(_, _, let relX, let relY):
            let point = CGPoint(
                x: windowBounds.origin.x + (relX * windowBounds.width),
                y: windowBounds.origin.y + (relY * windowBounds.height)
            )
            showQuickPulse(at: point, color: .blue, size: 15)
            
        default:
            break
        }
    }
    
    @MainActor
    private func showQuickPulse(at point: CGPoint, color: NSColor, size: CGFloat = 25) {
        // Comprehensive safety checks
        guard NSApp != nil,
              NSApp.isActive,
              NSApp.mainWindow != nil else { return }
        
        // Validate point is reasonable
        guard point.x >= 0, point.y >= 0,
              point.x < 10000, point.y < 10000 else { return }
        
        // Create a lightweight indicator window
        let indicatorWindow = NSWindow(
            contentRect: NSRect(x: point.x - size/2, y: point.y - size/2, width: size, height: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        indicatorWindow.backgroundColor = .clear
        indicatorWindow.isOpaque = false
        indicatorWindow.level = .floating  // Even safer level
        indicatorWindow.ignoresMouseEvents = true
        indicatorWindow.collectionBehavior = [.transient, .ignoresCycle, .fullScreenNone, .stationary]
        indicatorWindow.isReleasedWhenClosed = true
        indicatorWindow.animationBehavior = .none  // Disable animations
        
        let pulseView = NSView(frame: NSRect(x: 0, y: 0, width: size, height: size))
        pulseView.wantsLayer = true
        
        // Safely configure layer
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        if let layer = pulseView.layer {
            layer.backgroundColor = color.withAlphaComponent(0.4).cgColor
            layer.cornerRadius = size / 2
            layer.borderWidth = 2
            layer.borderColor = color.cgColor
        }
        
        CATransaction.commit()
        
        indicatorWindow.contentView = pulseView
        indicatorWindow.orderFront(nil)
        
        // Use a timer with weak reference for cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak indicatorWindow] in
            if let window = indicatorWindow {
                window.orderOut(nil)
                window.close()
            }
        }
    }
    
    func executeAction(_ action: RecordedAction, in windowBounds: CGRect) async {
        // Debug logging for replay
        switch action {
        case .mouseMove(_, _, let relX, let relY):
            // Both window bounds and our stored relative positions use top-left origin
            // So we can directly apply the relative position
            let adjustedPoint = CGPoint(
                x: windowBounds.origin.x + (relX * windowBounds.width),
                y: windowBounds.origin.y + (relY * windowBounds.height)
            )
            print("🎮 Replay: Move to (\(Int(adjustedPoint.x)), \(Int(adjustedPoint.y))) [\(Int(relX*100))%, \(Int(relY*100))%]")
            
            // Move mouse to position first
            if let moveEvent = CGEvent(
                mouseEventSource: nil,
                mouseType: .mouseMoved,
                mouseCursorPosition: adjustedPoint,
                mouseButton: .left
            ) {
                moveEvent.post(tap: .cghidEventTap)
                // Small delay to ensure move completes
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
            
        case .mouseClick(_, _, let relX, let relY, let count):
            // Use the window bounds passed in (which are the CURRENT bounds from replay loop)
            // Apply the relative position to wherever the window is NOW
            let clickX = windowBounds.origin.x + (relX * windowBounds.width)
            let clickY = windowBounds.origin.y + (relY * windowBounds.height)
            
            let adjustedPoint = CGPoint(x: clickX, y: clickY)
            print("🎮 Replay: Click at (\(Int(adjustedPoint.x)), \(Int(adjustedPoint.y))) [\(Int(relX*100))%, \(Int(relY*100))%]")
            
            // Ensure window is focused first
            WindowDetector.activateiPhoneMirroring()
            
            // First move to the position
            if let moveEvent = CGEvent(
                mouseEventSource: nil,
                mouseType: .mouseMoved,
                mouseCursorPosition: adjustedPoint,
                mouseButton: .left
            ) {
                moveEvent.post(tap: .cghidEventTap)
                
                // If clicking in toolbar area, wait for it to appear
                if relY < 0.1 { // Top 10% of window
                    print("🕰 Clicking in toolbar area - waiting for toolbar to appear")
                    try? await Task.sleep(nanoseconds: 500_000_000) // 500ms for toolbar
                } else {
                    try? await Task.sleep(nanoseconds: 20_000_000) // 20ms normal delay
                }
            }
            
            // Then perform the click
            for _ in 0..<count {
                if let downEvent = CGEvent(
                    mouseEventSource: nil,
                    mouseType: .leftMouseDown,
                    mouseCursorPosition: adjustedPoint,
                    mouseButton: .left
                ) {
                    downEvent.post(tap: .cghidEventTap)
                }
                
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms between down and up
                
                if let upEvent = CGEvent(
                    mouseEventSource: nil,
                    mouseType: .leftMouseUp,
                    mouseCursorPosition: adjustedPoint,
                    mouseButton: .left
                ) {
                    upEvent.post(tap: .cghidEventTap)
                }
                
                if count > 1 {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms between clicks for double-click
                }
            }
            
        case .mouseDown(_, _, let relX, let relY):
            let adjustedPoint = CGPoint(
                x: windowBounds.origin.x + (relX * windowBounds.width),
                y: windowBounds.origin.y + (relY * windowBounds.height)
            )
            print("🎮 Replay: Mouse down at (\(Int(adjustedPoint.x)), \(Int(adjustedPoint.y)))")
            
            if let event = CGEvent(
                mouseEventSource: nil,
                mouseType: .leftMouseDown,
                mouseCursorPosition: adjustedPoint,
                mouseButton: .left
            ) {
                event.post(tap: .cghidEventTap)
            }
            
        case .mouseUp(_, _, let relX, let relY):
            let adjustedPoint = CGPoint(
                x: windowBounds.origin.x + (relX * windowBounds.width),
                y: windowBounds.origin.y + (relY * windowBounds.height)
            )
            print("🎮 Replay: Mouse up at (\(Int(adjustedPoint.x)), \(Int(adjustedPoint.y)))")
            
            if let event = CGEvent(
                mouseEventSource: nil,
                mouseType: .leftMouseUp,
                mouseCursorPosition: adjustedPoint,
                mouseButton: .left
            ) {
                event.post(tap: .cghidEventTap)
            }
            
        case .mouseDrag(_, _, _, _, let fromRelX, let fromRelY, let toRelX, let toRelY):
            // Both window bounds and our stored relative positions use top-left origin
            let fromPoint = CGPoint(
                x: windowBounds.origin.x + (fromRelX * windowBounds.width),
                y: windowBounds.origin.y + (fromRelY * windowBounds.height)
            )
            let toPoint = CGPoint(
                x: windowBounds.origin.x + (toRelX * windowBounds.width),
                y: windowBounds.origin.y + (toRelY * windowBounds.height)
            )
            
            print("🎮 Replay: Drag from (\(Int(fromPoint.x)), \(Int(fromPoint.y))) to (\(Int(toPoint.x)), \(Int(toPoint.y)))")
            
            // Perform a proper drag with mouse down, move, and up
            if let downEvent = CGEvent(
                mouseEventSource: nil,
                mouseType: .leftMouseDown,
                mouseCursorPosition: fromPoint,
                mouseButton: .left
            ) {
                downEvent.post(tap: .cghidEventTap)
            }
            
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            
            // Smooth drag with intermediate points
            let steps = 10
            for i in 1...steps {
                let progress = Double(i) / Double(steps)
                let intermediatePoint = CGPoint(
                    x: fromPoint.x + (toPoint.x - fromPoint.x) * progress,
                    y: fromPoint.y + (toPoint.y - fromPoint.y) * progress
                )
                
                if let dragEvent = CGEvent(
                    mouseEventSource: nil,
                    mouseType: .leftMouseDragged,
                    mouseCursorPosition: intermediatePoint,
                    mouseButton: .left
                ) {
                    dragEvent.post(tap: .cghidEventTap)
                }
                
                try? await Task.sleep(nanoseconds: 20_000_000) // 20ms between steps
            }
            
            if let upEvent = CGEvent(
                mouseEventSource: nil,
                mouseType: .leftMouseUp,
                mouseCursorPosition: toPoint,
                mouseButton: .left
            ) {
                upEvent.post(tap: .cghidEventTap)
            }
            
        case .keyPress(let keyCode, let modifiers):
            print("🎮 Replay: Key press code \(keyCode)")
            
            if let event = CGEvent(
                keyboardEventSource: nil,
                virtualKey: CGKeyCode(keyCode),
                keyDown: true
            ) {
                event.flags = CGEventFlags(rawValue: modifiers)
                event.post(tap: .cghidEventTap)
            }
            
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            
            if let event = CGEvent(
                keyboardEventSource: nil,
                virtualKey: CGKeyCode(keyCode),
                keyDown: false
            ) {
                event.flags = CGEventFlags(rawValue: modifiers)
                event.post(tap: .cghidEventTap)
            }
            
        case .wait(let seconds):
            print("🎮 Replay: Wait \(String(format: "%.1f", seconds))s")
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        }
    }
    
    // MARK: - Persistence
    
    func saveRecordings() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsPath.appendingPathComponent("recordings.json")
        
        do {
            let data = try JSONEncoder().encode(recordings)
            try data.write(to: filePath)
            print("💾 Saved \(recordings.count) recordings")
        } catch {
            print("❌ Failed to save recordings: \(error)")
        }
    }
    
    func loadRecordings() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsPath.appendingPathComponent("recordings.json")
        
        do {
            let data = try Data(contentsOf: filePath)
            recordings = try JSONDecoder().decode([Recording].self, from: data)
            print("📂 Loaded \(recordings.count) recordings")
        } catch {
            print("ℹ️ No saved recordings found")
        }
    }
    
    func deleteRecording(_ recording: Recording) {
        recordings.removeAll { $0.id == recording.id }
        saveRecordings()
    }
    
    func updateRecording(_ recording: Recording) {
        if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings[index] = recording
            saveRecordings()
        }
    }
    
    func addRecording(_ recording: Recording) {
        recordings.append(recording)
        saveRecordings()
    }
    
    // MARK: - Window Monitoring
    
    private func checkWindowPosition() {
        guard isRecording else { return }
        
        // Get current window position
        guard let currentWindow = WindowDetector.getiPhoneMirroringWindow() else {
            print("⚠️ Window lost during recording!")
            return
        }
        
        // Check if window moved
        if let lastBounds = windowBounds {
            if lastBounds.origin != currentWindow.bounds.origin {
                print("🔄 Window moved from \(lastBounds.origin) to \(currentWindow.bounds.origin)")
                
                // Update our stored window bounds
                self.windowBounds = currentWindow.bounds
                
                // You could add a special "window moved" action here if needed
                // currentActions.append(.windowMoved(to: currentWindow.bounds))
            }
        }
    }
    
    // MARK: - Visual Feedback During Recording
    
    @MainActor
    private func showRecordingFeedback(at point: CGPoint, type: NSEvent.EventType) {
        // Only show feedback for significant events and if app is active
        guard NSApp.isActive,
              [.leftMouseDown, .leftMouseUp, .leftMouseDragged].contains(type) else { return }
        
        let color: NSColor
        let size: CGFloat
        
        switch type {
        case .leftMouseDown:
            color = .red
            size = 25
        case .leftMouseUp:
            color = .orange
            size = 20
        case .leftMouseDragged:
            color = .yellow
            size = 15
        default:
            return
        }
        
        // Create a temporary feedback window
        let feedbackWindow = NSWindow(
            contentRect: NSRect(x: point.x - size/2, y: point.y - size/2, width: size, height: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        feedbackWindow.backgroundColor = .clear
        feedbackWindow.isOpaque = false
        feedbackWindow.level = .popUpMenu  // Use lower level
        feedbackWindow.ignoresMouseEvents = true
        feedbackWindow.collectionBehavior = [.transient, .ignoresCycle, .fullScreenNone]
        feedbackWindow.isReleasedWhenClosed = true
        
        let pulseView = NSView(frame: NSRect(x: 0, y: 0, width: size, height: size))
        pulseView.wantsLayer = true
        
        if let layer = pulseView.layer {
            layer.backgroundColor = color.withAlphaComponent(0.3).cgColor
            layer.cornerRadius = size / 2
            layer.borderWidth = 2
            layer.borderColor = color.cgColor
        }
        
        feedbackWindow.contentView = pulseView
        feedbackWindow.orderFront(nil)
        
        // Use timer for cleanup to avoid animation issues
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak feedbackWindow] in
            feedbackWindow?.close()
        }
    }
}