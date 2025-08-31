//
//  CoordinateTransform.swift
//  Transformation Spaces
//
//  Single Responsibility: Transform coordinates between different spaces
//

import Foundation

protocol CoordinateSpace {
    var bounds: Bounds2D { get }
    var identifier: String { get }
}

struct CoordinateTransform {
    let sourceSpace: CoordinateSpace
    let targetSpace: CoordinateSpace
    
    // Linear transformation matrix [a, b, c, d] for:
    // x' = ax + by
    // y' = cx + dy
    private var matrix: (a: Double, b: Double, c: Double, d: Double)
    private var translation: Vector2D
    
    init(from source: CoordinateSpace, to target: CoordinateSpace) {
        self.sourceSpace = source
        self.targetSpace = target
        
        // Calculate scale factors
        let scaleX = target.bounds.width / source.bounds.width
        let scaleY = target.bounds.height / source.bounds.height
        
        // Simple scaling transformation
        self.matrix = (scaleX, 0, 0, scaleY)
        
        // Translation to align origins
        self.translation = target.bounds.min - source.bounds.min
    }
    
    // Transform a point from source to target space
    func transform(_ point: Vector2D) -> Vector2D {
        let transformed = Vector2D(
            x: matrix.a * point.x + matrix.b * point.y,
            y: matrix.c * point.x + matrix.d * point.y
        )
        return transformed + translation
    }
    
    // Inverse transform from target to source space
    func inverseTransform(_ point: Vector2D) -> Vector2D {
        let det = matrix.a * matrix.d - matrix.b * matrix.c
        guard abs(det) > 0.0001 else { return point } // Singular matrix
        
        let shifted = point - translation
        return Vector2D(
            x: (matrix.d * shifted.x - matrix.b * shifted.y) / det,
            y: (-matrix.c * shifted.x + matrix.a * shifted.y) / det
        )
    }
    
    // Transform a vector (no translation)
    func transformVector(_ vector: Vector2D) -> Vector2D {
        Vector2D(
            x: matrix.a * vector.x + matrix.b * vector.y,
            y: matrix.c * vector.x + matrix.d * vector.y
        )
    }
}

// Concrete coordinate spaces
struct TouchpadSpace: CoordinateSpace {
    let bounds = Bounds2D(width: 250, height: 180)
    let identifier = "touchpad"
}

struct iPhoneScreenSpace: CoordinateSpace {
    let bounds = Bounds2D(width: 372, height: 824)
    let identifier = "iphone"
}