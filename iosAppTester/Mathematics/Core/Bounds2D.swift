//
//  Bounds2D.swift
//  Mathematical Foundation - 2D Boundary Management
//
//  Single Responsibility: Managing 2D rectangular boundaries and clamping
//

import Foundation

struct Bounds2D {
    let min: Vector2D
    let max: Vector2D
    
    init(min: Vector2D, max: Vector2D) {
        self.min = min
        self.max = max
    }
    
    init(width: Double, height: Double) {
        self.min = Vector2D(x: 0, y: 0)
        self.max = Vector2D(x: width, y: height)
    }
    
    // Clamp a point within bounds
    func clamp(_ point: Vector2D) -> Vector2D {
        Vector2D(
            x: Swift.min(Swift.max(point.x, min.x), max.x),
            y: Swift.min(Swift.max(point.y, min.y), max.y)
        )
    }
    
    // Check if point is within bounds
    func contains(_ point: Vector2D) -> Bool {
        point.x >= min.x && point.x <= max.x &&
        point.y >= min.y && point.y <= max.y
    }
    
    // Get center point
    var center: Vector2D {
        Vector2D(
            x: (min.x + max.x) / 2,
            y: (min.y + max.y) / 2
        )
    }
    
    // Get dimensions
    var width: Double { max.x - min.x }
    var height: Double { max.y - min.y }
    
    // Get area
    var area: Double { width * height }
    
    // Scale bounds by factor
    func scaled(by factor: Double) -> Bounds2D {
        let center = self.center
        let halfWidth = width * factor / 2
        let halfHeight = height * factor / 2
        
        return Bounds2D(
            min: Vector2D(x: center.x - halfWidth, y: center.y - halfHeight),
            max: Vector2D(x: center.x + halfWidth, y: center.y + halfHeight)
        )
    }
}