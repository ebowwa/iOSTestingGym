//
//  GestureRecognizer.swift
//  Pattern Recognition and Classification
//
//  Single Responsibility: Recognize and classify touch gestures
//

import Foundation

enum GestureType {
    case tap
    case doubleTap
    case longPress
    case swipe(direction: SwipeDirection)
    case pinch(scale: Double)
    case rotate(angle: Double)
    case custom(identifier: String)
}

enum SwipeDirection {
    case up, down, left, right
    
    static func from(vector: Vector2D) -> SwipeDirection {
        let angle = vector.angle
        
        // Normalize angle to 0-2π
        let normalizedAngle = angle < 0 ? angle + 2 * .pi : angle
        
        // Determine direction based on angle
        switch normalizedAngle {
        case 0..<(.pi/4), (7 * .pi/4)...(2 * .pi):
            return .right
        case (.pi/4)...(3 * .pi/4):
            return .up
        case (3 * .pi/4)...(5 * .pi/4):
            return .left
        default:
            return .down
        }
    }
}

// Gesture template for matching
struct GestureTemplate {
    let points: [Vector2D]
    let type: GestureType
    let identifier: String
    
    // Normalize points to unit square centered at origin
    var normalizedPoints: [Vector2D] {
        guard !points.isEmpty else { return [] }
        
        // Find bounding box
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }
        let minX = xs.min()!
        let maxX = xs.max()!
        let minY = ys.min()!
        let maxY = ys.max()!
        
        let width = maxX - minX
        let height = maxY - minY
        let scale = max(width, height)
        
        guard scale > 0 else { return points }
        
        // Normalize to [-1, 1] square
        let centerX = (minX + maxX) / 2
        let centerY = (minY + maxY) / 2
        
        return points.map { point in
            Vector2D(
                x: (point.x - centerX) / scale * 2,
                y: (point.y - centerY) / scale * 2
            )
        }
    }
}

// $1 Gesture Recognizer (simplified)
class GestureRecognizer {
    private var templates: [GestureTemplate] = []
    private let samplePoints = 64 // Number of points to resample to
    
    // Add a template
    func addTemplate(_ template: GestureTemplate) {
        templates.append(template)
    }
    
    // Recognize gesture from points
    func recognize(points: [Vector2D], threshold: Double = 0.7) -> GestureType? {
        guard points.count >= 2 else { return nil }
        
        // Check for simple gestures first
        if let simple = recognizeSimpleGesture(points: points) {
            return simple
        }
        
        // Prepare candidate for matching
        let candidate = resample(points: points, count: samplePoints)
        let normalizedCandidate = normalize(points: candidate)
        
        // Find best matching template
        var bestScore = 0.0
        var bestTemplate: GestureTemplate?
        
        for template in templates {
            let templatePoints = resample(points: template.normalizedPoints, count: samplePoints)
            let score = computeSimilarity(normalizedCandidate, templatePoints)
            
            if score > bestScore {
                bestScore = score
                bestTemplate = template
            }
        }
        
        if bestScore > threshold, let best = bestTemplate {
            return best.type
        }
        
        return nil
    }
    
    // Recognize simple gestures
    private func recognizeSimpleGesture(points: [Vector2D]) -> GestureType? {
        let distance = points.first!.distance(to: points.last!)
        let pathLength = calculatePathLength(points: points)
        
        // Tap: short distance and time
        if distance < 10 && points.count < 10 {
            return .tap
        }
        
        // Swipe: significant distance, relatively straight
        if distance > 50 && pathLength < distance * 1.5 {
            let direction = points.last! - points.first!
            return .swipe(direction: SwipeDirection.from(vector: direction))
        }
        
        return nil
    }
    
    // Resample points to fixed count
    private func resample(points: [Vector2D], count: Int) -> [Vector2D] {
        let pathLength = calculatePathLength(points: points)
        let interval = pathLength / Double(count - 1)
        
        var mutablePoints = points  // Create mutable copy
        var resampled = [mutablePoints[0]]
        var accumulated = 0.0
        
        var i = 1
        while i < mutablePoints.count {
            let distance = mutablePoints[i].distance(to: mutablePoints[i - 1])
            
            if accumulated + distance >= interval {
                let ratio = (interval - accumulated) / distance
                let interpolated = mutablePoints[i - 1] + (mutablePoints[i] - mutablePoints[i - 1]) * ratio
                resampled.append(interpolated)
                
                // Reset for next interval
                mutablePoints[i - 1] = interpolated
                accumulated = 0.0
            } else {
                accumulated += distance
                i += 1
            }
            
            if resampled.count >= count {
                break
            }
        }
        
        // Ensure we have exactly 'count' points
        while resampled.count < count {
            resampled.append(mutablePoints.last!)
        }
        
        return Array(resampled.prefix(count))
    }
    
    // Normalize points
    private func normalize(points: [Vector2D]) -> [Vector2D] {
        let template = GestureTemplate(points: points, type: .custom(identifier: ""), identifier: "")
        return template.normalizedPoints
    }
    
    // Calculate path length
    private func calculatePathLength(points: [Vector2D]) -> Double {
        var length = 0.0
        for i in 1..<points.count {
            length += points[i].distance(to: points[i - 1])
        }
        return length
    }
    
    // Compute similarity between two point sets
    private func computeSimilarity(_ points1: [Vector2D], _ points2: [Vector2D]) -> Double {
        guard points1.count == points2.count else { return 0 }
        
        var totalDistance = 0.0
        for i in 0..<points1.count {
            totalDistance += points1[i].distance(to: points2[i])
        }
        
        let averageDistance = totalDistance / Double(points1.count)
        let maxDistance = 2.0 * sqrt(2) // Maximum distance in normalized square
        
        return 1.0 - (averageDistance / maxDistance)
    }
}