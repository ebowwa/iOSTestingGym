import AppKit
import CoreGraphics

print("Testing Home Button Action...")

// Simulate the exact steps from HomeButtonAction.swift

// 1. Find the window
let windows = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] ?? []
var windowFound = false

for window in windows {
    if let name = window[kCGWindowName as String] as? String,
       name.contains("iPhone Mirroring") {
        windowFound = true
        
        if let bounds = window[kCGWindowBounds as String] as? [String: CGFloat] {
            let x = bounds["X"] ?? 0
            let y = bounds["Y"] ?? 0
            let width = bounds["Width"] ?? 0
            let height = bounds["Height"] ?? 0
            
            print("✅ Window found at (\(x), \(y)) size: \(width)x\(height)")
            
            // 2. Calculate hover position (50% width, 5% height)
            let hoverX = x + (width * 0.5)
            let hoverY = y + (height * 0.05)
            print("   Hover position: (\(hoverX), \(hoverY))")
            
            // 3. Calculate click position (85% width, 2% height)
            let clickX = x + (width * 0.85)
            let clickY = y + (height * 0.02)
            print("   Click position: (\(clickX), \(clickY))")
            
            // Try the action
            print("\nAttempting Home button action...")
            
            // Move to hover position
            if let moveEvent = CGEvent(
                mouseEventSource: nil,
                mouseType: .mouseMoved,
                mouseCursorPosition: CGPoint(x: hoverX, y: hoverY),
                mouseButton: .left
            ) {
                moveEvent.post(tap: .cghidEventTap)
                print("   ✅ Moved to hover position")
            }
            
            Thread.sleep(forTimeInterval: 0.5)
            
            // Click at home button position
            let clickPoint = CGPoint(x: clickX, y: clickY)
            
            if let downEvent = CGEvent(
                mouseEventSource: nil,
                mouseType: .leftMouseDown,
                mouseCursorPosition: clickPoint,
                mouseButton: .left
            ) {
                downEvent.post(tap: .cghidEventTap)
                Thread.sleep(forTimeInterval: 0.05)
                
                if let upEvent = CGEvent(
                    mouseEventSource: nil,
                    mouseType: .leftMouseUp,
                    mouseCursorPosition: clickPoint,
                    mouseButton: .left
                ) {
                    upEvent.post(tap: .cghidEventTap)
                    print("   ✅ Clicked at home button position")
                }
            }
            
            print("\nHome button action completed!")
            print("If it didn't work, try:")
            print("1. Make sure iPhone Mirroring is focused")
            print("2. Try increasing the wait time after hover")
            print("3. Check if the toolbar is visible at the top")
        }
        break
    }
}

if !windowFound {
    print("❌ iPhone Mirroring window not found!")
    print("Please open iPhone Mirroring first")
}