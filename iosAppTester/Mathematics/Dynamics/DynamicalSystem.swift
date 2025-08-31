//
//  DynamicalSystem.swift
//  Dynamical Systems Theory
//
//  Single Responsibility: Model cursor dynamics with attractors and physics
//

import Foundation

protocol DynamicalSystem {
    associatedtype SystemState
    func evolve(state: SystemState, deltaTime: Double) -> SystemState
}

// Spring-damper system for smooth cursor movement
struct SpringDamperSystem: DynamicalSystem {
    let springConstant: Double  // k - stiffness
    let dampingRatio: Double    // ζ - damping ratio (0 = no damping, 1 = critical)
    let mass: Double = 1.0      // m - virtual mass
    
    init(springConstant: Double = 10.0, dampingRatio: Double = 0.7) {
        self.springConstant = springConstant
        self.dampingRatio = dampingRatio
    }
    
    struct SystemState {
        var position: Vector2D
        var velocity: Vector2D
        let target: Vector2D
    }
    
    func evolve(state: SystemState, deltaTime: Double) -> SystemState {
        // F = -k(x - target) - c*v
        let displacement = state.position - state.target
        let dampingCoefficient = 2 * dampingRatio * sqrt(springConstant * mass)
        
        let springForce = displacement * (-springConstant)
        let dampingForce = state.velocity * (-dampingCoefficient)
        let totalForce = springForce + dampingForce
        
        // a = F/m
        let acceleration = totalForce * (1.0 / mass)
        
        // Update velocity and position (Euler integration)
        let newVelocity = state.velocity + acceleration * deltaTime
        let newPosition = state.position + newVelocity * deltaTime
        
        return SystemState(
            position: newPosition,
            velocity: newVelocity,
            target: state.target
        )
    }
    
    // Calculate settling time (time to reach 2% of target)
    func settlingTime() -> Double {
        4.0 / (dampingRatio * sqrt(springConstant / mass))
    }
}

// Attractor field for snap-to-grid behavior
struct AttractorField {
    let attractors: [Vector2D]
    let strength: Double
    let radius: Double
    
    // Calculate force at position
    func force(at position: Vector2D) -> Vector2D {
        var totalForce = Vector2D(x: 0, y: 0)
        
        for attractor in attractors {
            let distance = position.distance(to: attractor)
            
            if distance < radius && distance > 0.01 {
                // Force increases as we get closer (inverse square)
                let forceMagnitude = strength / (distance * distance)
                let direction = (attractor - position).normalized
                totalForce = totalForce + direction * forceMagnitude
            }
        }
        
        return totalForce
    }
    
    // Find nearest attractor
    func nearest(to position: Vector2D) -> Vector2D? {
        attractors.min(by: { $0.distance(to: position) < $1.distance(to: position) })
    }
    
    // Check if position is captured by an attractor
    func isCaptured(position: Vector2D, captureRadius: Double = 5.0) -> Bool {
        attractors.contains { $0.distance(to: position) < captureRadius }
    }
}

// Momentum system for gesture inertia
class MomentumSystem {
    private var velocity: Vector2D = Vector2D(x: 0, y: 0)
    private let friction: Double
    private let minSpeed: Double = 0.1
    
    init(friction: Double = 0.95) {
        self.friction = min(1.0, max(0.0, friction))
    }
    
    // Add impulse to system
    func addImpulse(_ impulse: Vector2D) {
        velocity = velocity + impulse
    }
    
    // Update and get position
    func update(currentPosition: Vector2D, deltaTime: Double) -> Vector2D {
        // Apply friction
        velocity = velocity * friction
        
        // Stop if too slow
        if velocity.magnitude < minSpeed {
            velocity = Vector2D(x: 0, y: 0)
        }
        
        // Update position
        return currentPosition + velocity * deltaTime
    }
    
    // Check if still moving
    var isMoving: Bool {
        velocity.magnitude > minSpeed
    }
    
    // Reset momentum
    func reset() {
        velocity = Vector2D(x: 0, y: 0)
    }
}