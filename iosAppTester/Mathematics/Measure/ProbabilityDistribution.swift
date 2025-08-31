//
//  ProbabilityDistribution.swift
//  Measure Theory - Probability Distributions
//
//  Single Responsibility: Model touch position probability distributions
//

import Foundation

protocol ProbabilityDistribution2D {
    func probability(at point: Vector2D) -> Double
    func sample() -> Vector2D
    func expectedValue() -> Vector2D
}

// Gaussian/Normal distribution in 2D
struct Gaussian2D: ProbabilityDistribution2D {
    let mean: Vector2D
    let covariance: (xx: Double, yy: Double, xy: Double) // Covariance matrix elements
    
    init(mean: Vector2D, standardDeviation: Vector2D, correlation: Double = 0) {
        self.mean = mean
        self.covariance = (
            xx: standardDeviation.x * standardDeviation.x,
            yy: standardDeviation.y * standardDeviation.y,
            xy: correlation * standardDeviation.x * standardDeviation.y
        )
    }
    
    // Probability density at point
    func probability(at point: Vector2D) -> Double {
        let det = covariance.xx * covariance.yy - covariance.xy * covariance.xy
        guard det > 0 else { return 0 }
        
        let diff = point - mean
        let invCov = (
            xx: covariance.yy / det,
            yy: covariance.xx / det,
            xy: -covariance.xy / det
        )
        
        let exponent = -0.5 * (
            diff.x * (invCov.xx * diff.x + invCov.xy * diff.y) +
            diff.y * (invCov.xy * diff.x + invCov.yy * diff.y)
        )
        
        let normalization = 1.0 / (2 * .pi * sqrt(det))
        return normalization * exp(exponent)
    }
    
    // Sample from distribution (Box-Muller transform)
    func sample() -> Vector2D {
        let u1 = Double.random(in: 0..<1)
        let u2 = Double.random(in: 0..<1)
        
        let z0 = sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
        let z1 = sqrt(-2 * log(u1)) * sin(2 * .pi * u2)
        
        // Transform to correlated variables
        let x = mean.x + sqrt(covariance.xx) * z0
        let y = mean.y + sqrt(covariance.yy) * (covariance.xy / sqrt(covariance.xx) * z0 + 
                sqrt(1 - pow(covariance.xy / sqrt(covariance.xx * covariance.yy), 2)) * z1)
        
        return Vector2D(x: x, y: y)
    }
    
    func expectedValue() -> Vector2D {
        mean
    }
}

// Heat map for touch frequency
class TouchHeatMap {
    private var touchCounts: [[Int]]
    private let resolution: Int
    private let bounds: Bounds2D
    private var totalTouches: Int = 0
    
    init(bounds: Bounds2D, resolution: Int = 50) {
        self.bounds = bounds
        self.resolution = resolution
        self.touchCounts = Array(repeating: Array(repeating: 0, count: resolution), count: resolution)
    }
    
    // Record a touch
    func recordTouch(at point: Vector2D) {
        guard bounds.contains(point) else { return }
        
        let x = Int((point.x - bounds.min.x) / bounds.width * Double(resolution))
        let y = Int((point.y - bounds.min.y) / bounds.height * Double(resolution))
        
        let clampedX = min(resolution - 1, max(0, x))
        let clampedY = min(resolution - 1, max(0, y))
        
        touchCounts[clampedY][clampedX] += 1
        totalTouches += 1
    }
    
    // Get probability at point
    func probability(at point: Vector2D) -> Double {
        guard bounds.contains(point), totalTouches > 0 else { return 0 }
        
        let x = Int((point.x - bounds.min.x) / bounds.width * Double(resolution))
        let y = Int((point.y - bounds.min.y) / bounds.height * Double(resolution))
        
        let clampedX = min(resolution - 1, max(0, x))
        let clampedY = min(resolution - 1, max(0, y))
        
        return Double(touchCounts[clampedY][clampedX]) / Double(totalTouches)
    }
    
    // Get highest probability point
    func mode() -> Vector2D? {
        var maxCount = 0
        var maxX = 0
        var maxY = 0
        
        for y in 0..<resolution {
            for x in 0..<resolution {
                if touchCounts[y][x] > maxCount {
                    maxCount = touchCounts[y][x]
                    maxX = x
                    maxY = y
                }
            }
        }
        
        guard maxCount > 0 else { return nil }
        
        return Vector2D(
            x: bounds.min.x + (Double(maxX) + 0.5) * bounds.width / Double(resolution),
            y: bounds.min.y + (Double(maxY) + 0.5) * bounds.height / Double(resolution)
        )
    }
    
    // Reset heat map
    func reset() {
        touchCounts = Array(repeating: Array(repeating: 0, count: resolution), count: resolution)
        totalTouches = 0
    }
}