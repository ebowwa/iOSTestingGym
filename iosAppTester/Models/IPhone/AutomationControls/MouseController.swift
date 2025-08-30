//
//  MouseController.swift
//  iosAppTester
//
//  Handles mouse and gesture controls for iPhone Mirroring automation
//
//  IMPORTANT: Mouse/Gesture Control Notes
//  ======================================
//  
//  WHAT WORKS:
//  ✅ Mouse clicks via CGEvent at specific coordinates
//  ✅ Mouse drag/swipe gestures
//  ✅ Triple-click for focus
//  ✅ All standard mouse event types
//
//  KEY FINDINGS:
//  - Mouse events work normally through CGEvent with iPhone Mirroring
//  - Multiple clicks help ensure proper focus
//  - Realistic timing between events improves reliability
//

import Foundation
import CoreGraphics

class MouseController {
    
    // MARK: - Basic Click
    
    /// Performs a click at specific coordinates
    static func click(at point: CGPoint, clickCount: Int = 1) {
        for _ in 0..<clickCount {
            // Mouse down
            let mouseDown = CGEvent(
                mouseEventSource: nil,
                mouseType: .leftMouseDown,
                mouseCursorPosition: point,
                mouseButton: .left
            )
            mouseDown?.post(tap: .cghidEventTap)
            
            Thread.sleep(forTimeInterval: 0.05)
            
            // Mouse up
            let mouseUp = CGEvent(
                mouseEventSource: nil,
                mouseType: .leftMouseUp,
                mouseCursorPosition: point,
                mouseButton: .left
            )
            mouseUp?.post(tap: .cghidEventTap)
            
            if clickCount > 1 {
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }
    
    // MARK: - Tap at Relative Position
    
    /// Taps at a position relative to a window
    static func tapAt(x: CGFloat, y: CGFloat, in windowBounds: CGRect) {
        let absoluteX = windowBounds.origin.x + x
        let absoluteY = windowBounds.origin.y + y
        
        // Move mouse to position
        let moveEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: CGPoint(x: absoluteX, y: absoluteY),
            mouseButton: .left
        )
        moveEvent?.post(tap: .cghidEventTap)
        
        // Small delay
        Thread.sleep(forTimeInterval: 0.1)
        
        // Click
        click(at: CGPoint(x: absoluteX, y: absoluteY))
    }
    
    // MARK: - Swipe Gesture
    
    /// Performs a swipe gesture from one point to another
    static func swipe(from startPoint: CGPoint, to endPoint: CGPoint, duration: TimeInterval = 0.5) {
        let steps = 20
        let stepDuration = duration / Double(steps)
        
        // Press down
        let mouseDown = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: startPoint,
            mouseButton: .left
        )
        mouseDown?.post(tap: .cghidEventTap)
        
        // Drag
        for i in 1...steps {
            let progress = CGFloat(i) / CGFloat(steps)
            let currentX = startPoint.x + (endPoint.x - startPoint.x) * progress
            let currentY = startPoint.y + (endPoint.y - startPoint.y) * progress
            
            let dragEvent = CGEvent(
                mouseEventSource: nil,
                mouseType: .leftMouseDragged,
                mouseCursorPosition: CGPoint(x: currentX, y: currentY),
                mouseButton: .left
            )
            dragEvent?.post(tap: .cghidEventTap)
            Thread.sleep(forTimeInterval: stepDuration)
        }
        
        // Release
        let mouseUp = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: endPoint,
            mouseButton: .left
        )
        mouseUp?.post(tap: .cghidEventTap)
    }
    
    // MARK: - Relative Swipe
    
    /// Performs a swipe within a window's bounds
    static func swipe(from: CGPoint, to: CGPoint, in windowBounds: CGRect, duration: TimeInterval = 0.5) {
        let startX = windowBounds.origin.x + from.x
        let startY = windowBounds.origin.y + from.y
        let endX = windowBounds.origin.x + to.x
        let endY = windowBounds.origin.y + to.y
        
        swipe(
            from: CGPoint(x: startX, y: startY),
            to: CGPoint(x: endX, y: endY),
            duration: duration
        )
    }
    
    // MARK: - Focus Window
    
    /// Focuses a window by clicking in its center
    /// Triple-clicking helps ensure proper focus for iPhone Mirroring
    static func focusWindow(_ bounds: CGRect, clickCount: Int = 3) {
        let centerX = bounds.origin.x + bounds.width / 2
        let centerY = bounds.origin.y + bounds.height / 2
        
        click(at: CGPoint(x: centerX, y: centerY), clickCount: clickCount)
        Thread.sleep(forTimeInterval: 0.2)
    }
    
    // MARK: - Common Gestures
    
    /// Performs a pinch gesture (zoom in/out)
    static func pinch(center: CGPoint, startRadius: CGFloat, endRadius: CGFloat, in windowBounds: CGRect, duration: TimeInterval = 0.5) {
        // This would require multi-touch simulation which isn't directly supported
        // Leaving as placeholder for potential future implementation
        print("Pinch gesture not yet implemented for iPhone Mirroring")
    }
    
    /// Performs a long press at a point
    static func longPress(at point: CGPoint, duration: TimeInterval = 1.0) {
        let mouseDown = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: point,
            mouseButton: .left
        )
        mouseDown?.post(tap: .cghidEventTap)
        
        Thread.sleep(forTimeInterval: duration)
        
        let mouseUp = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: point,
            mouseButton: .left
        )
        mouseUp?.post(tap: .cghidEventTap)
    }
    
    // MARK: - Directional Swipes
    
    enum SwipeDirection {
        case up, down, left, right
    }
    
    /// Performs a directional swipe from the center of a window
    static func swipeInDirection(_ direction: SwipeDirection, in windowBounds: CGRect, distance: CGFloat = 200) {
        let centerX = windowBounds.width / 2
        let centerY = windowBounds.height / 2
        
        let from: CGPoint
        let to: CGPoint
        
        switch direction {
        case .up:
            from = CGPoint(x: centerX, y: centerY + distance/2)
            to = CGPoint(x: centerX, y: centerY - distance/2)
        case .down:
            from = CGPoint(x: centerX, y: centerY - distance/2)
            to = CGPoint(x: centerX, y: centerY + distance/2)
        case .left:
            from = CGPoint(x: centerX + distance/2, y: centerY)
            to = CGPoint(x: centerX - distance/2, y: centerY)
        case .right:
            from = CGPoint(x: centerX - distance/2, y: centerY)
            to = CGPoint(x: centerX + distance/2, y: centerY)
        }
        
        swipe(from: from, to: to, in: windowBounds)
    }
    
    // MARK: - Right Click
    
    /// Performs a right-click (control-click) at a point
    static func rightClick(at point: CGPoint) {
        let mouseDown = CGEvent(
            mouseEventSource: nil,
            mouseType: .rightMouseDown,
            mouseCursorPosition: point,
            mouseButton: .right
        )
        mouseDown?.post(tap: .cghidEventTap)
        
        Thread.sleep(forTimeInterval: 0.05)
        
        let mouseUp = CGEvent(
            mouseEventSource: nil,
            mouseType: .rightMouseUp,
            mouseCursorPosition: point,
            mouseButton: .right
        )
        mouseUp?.post(tap: .cghidEventTap)
    }
}