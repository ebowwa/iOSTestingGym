//
//  KalmanFilter.swift
//  Signal Processing - Kalman Filtering
//
//  Single Responsibility: Predict and filter noisy position measurements
//

import Foundation

class KalmanFilter2D {
    // State vector [x, y, vx, vy] - position and velocity
    private var state: (x: Double, y: Double, vx: Double, vy: Double)
    
    // Covariance matrix (4x4 simplified to diagonal)
    private var covariance: (p: Double, v: Double) // position and velocity variances
    
    // Process noise
    private let processNoise: (position: Double, velocity: Double)
    
    // Measurement noise
    private let measurementNoise: Double
    
    init(
        initialPosition: Vector2D,
        processNoise: (position: Double, velocity: Double) = (0.1, 0.01),
        measurementNoise: Double = 1.0
    ) {
        self.state = (initialPosition.x, initialPosition.y, 0, 0)
        self.covariance = (1000, 1000) // High initial uncertainty
        self.processNoise = processNoise
        self.measurementNoise = measurementNoise
    }
    
    // Predict next state based on motion model
    func predict(deltaTime: Double) {
        // Update position based on velocity
        state.x += state.vx * deltaTime
        state.y += state.vy * deltaTime
        
        // Increase uncertainty
        covariance.p += processNoise.position
        covariance.v += processNoise.velocity
    }
    
    // Update with measurement
    func update(measurement: Vector2D) {
        // Calculate Kalman gain
        let gain = covariance.p / (covariance.p + measurementNoise)
        
        // Update state with measurement
        let innovationX = measurement.x - state.x
        let innovationY = measurement.y - state.y
        
        state.x += gain * innovationX
        state.y += gain * innovationY
        
        // Update velocity estimate
        state.vx = innovationX * gain
        state.vy = innovationY * gain
        
        // Update covariance
        covariance.p *= (1 - gain)
        covariance.v *= (1 - gain * 0.5) // Velocity uncertainty decreases slower
    }
    
    // Get filtered position
    func getPosition() -> Vector2D {
        Vector2D(x: state.x, y: state.y)
    }
    
    // Get predicted position after time
    func getPredictedPosition(after deltaTime: Double) -> Vector2D {
        Vector2D(
            x: state.x + state.vx * deltaTime,
            y: state.y + state.vy * deltaTime
        )
    }
    
    // Get velocity
    func getVelocity() -> Vector2D {
        Vector2D(x: state.vx, y: state.vy)
    }
    
    // Reset filter
    func reset(to position: Vector2D) {
        state = (position.x, position.y, 0, 0)
        covariance = (1000, 1000)
    }
}