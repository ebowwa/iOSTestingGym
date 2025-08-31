//
//  BezierCurve.swift
//  Differential Geometry - Bezier Curves
//
//  Single Responsibility: Generate smooth curves for gesture paths
//

import Foundation

struct BezierCurve {
    let controlPoints: [Vector2D]
    
    init(controlPoints: [Vector2D]) {
        assert(controlPoints.count >= 2, "Need at least 2 control points")
        self.controlPoints = controlPoints
    }
    
    // Evaluate curve at parameter t (0-1)
    func evaluate(at t: Double) -> Vector2D {
        let clampedT = min(1.0, max(0.0, t))
        return deCasteljau(points: controlPoints, t: clampedT)
    }
    
    // De Casteljau's algorithm for curve evaluation
    private func deCasteljau(points: [Vector2D], t: Double) -> Vector2D {
        if points.count == 1 {
            return points[0]
        }
        
        var newPoints: [Vector2D] = []
        for i in 0..<(points.count - 1) {
            let interpolated = lerp(points[i], points[i + 1], t: t)
            newPoints.append(interpolated)
        }
        
        return deCasteljau(points: newPoints, t: t)
    }
    
    // Linear interpolation
    private func lerp(_ a: Vector2D, _ b: Vector2D, t: Double) -> Vector2D {
        a + (b - a) * t
    }
    
    // Get tangent vector at parameter t
    func tangent(at t: Double) -> Vector2D {
        let delta = 0.001
        let p1 = evaluate(at: t - delta)
        let p2 = evaluate(at: t + delta)
        return (p2 - p1).normalized
    }
    
    // Sample curve at n points
    func sample(count: Int) -> [Vector2D] {
        guard count > 1 else { return [evaluate(at: 0.5)] }
        
        return (0..<count).map { i in
            let t = Double(i) / Double(count - 1)
            return evaluate(at: t)
        }
    }
    
    // Calculate arc length (approximate)
    func arcLength(samples: Int = 100) -> Double {
        let points = sample(count: samples)
        var length = 0.0
        
        for i in 1..<points.count {
            length += points[i].distance(to: points[i - 1])
        }
        
        return length
    }
}

// Quadratic Bezier (3 control points)
struct QuadraticBezier {
    let start: Vector2D
    let control: Vector2D
    let end: Vector2D
    
    var curve: BezierCurve {
        BezierCurve(controlPoints: [start, control, end])
    }
    
    func evaluate(at t: Double) -> Vector2D {
        curve.evaluate(at: t)
    }
}

// Cubic Bezier (4 control points)
struct CubicBezier {
    let start: Vector2D
    let control1: Vector2D
    let control2: Vector2D
    let end: Vector2D
    
    var curve: BezierCurve {
        BezierCurve(controlPoints: [start, control1, control2, end])
    }
    
    func evaluate(at t: Double) -> Vector2D {
        curve.evaluate(at: t)
    }
}