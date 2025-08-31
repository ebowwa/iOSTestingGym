//
//  Vector2D.swift
//  Mathematical Foundation - 2D Vector Operations
//
//  Single Responsibility: 2D vector mathematics and operations
//

import Foundation

struct Vector2D: Equatable {
    let x: Double
    let y: Double
    
    // Vector addition
    static func +(lhs: Vector2D, rhs: Vector2D) -> Vector2D {
        Vector2D(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    // Vector subtraction
    static func -(lhs: Vector2D, rhs: Vector2D) -> Vector2D {
        Vector2D(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    // Scalar multiplication
    static func *(vector: Vector2D, scalar: Double) -> Vector2D {
        Vector2D(x: vector.x * scalar, y: vector.y * scalar)
    }
    
    // Dot product
    func dot(_ other: Vector2D) -> Double {
        x * other.x + y * other.y
    }
    
    // Magnitude
    var magnitude: Double {
        sqrt(x * x + y * y)
    }
    
    // Normalized vector
    var normalized: Vector2D {
        let mag = magnitude
        guard mag > 0 else { return self }
        return Vector2D(x: x / mag, y: y / mag)
    }
    
    // Distance to another point
    func distance(to other: Vector2D) -> Double {
        (self - other).magnitude
    }
    
    // Angle in radians
    var angle: Double {
        atan2(y, x)
    }
    
    // Rotate by angle
    func rotated(by angle: Double) -> Vector2D {
        let cos = Darwin.cos(angle)
        let sin = Darwin.sin(angle)
        return Vector2D(
            x: x * cos - y * sin,
            y: x * sin + y * cos
        )
    }
}