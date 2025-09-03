import AppKit
import CoreGraphics

// Find iPhone Mirroring window
let windows = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] ?? []

for window in windows {
    if let name = window[kCGWindowName as String] as? String,
       name.contains("iPhone Mirroring") {
        
        if let bounds = window[kCGWindowBounds as String] as? [String: CGFloat] {
            let x = bounds["X"] ?? 0
            let y = bounds["Y"] ?? 0
            let width = bounds["Width"] ?? 0
            let height = bounds["Height"] ?? 0
            
            print("iPhone Mirroring window found:")
            print("  Position: (\(x), \(y))")
            print("  Size: \(width) x \(height)")
            print("\nHome button calculations:")
            print("  85% from left = \(x + width * 0.85)")
            print("  2% from top = \(y + height * 0.02)")
            print("\nPrevious working position (if different):")
            print("  42% from left = \(x + width * 0.42)")
            
            // Check if window is too small
            if height < 600 {
                print("\n⚠️ Window might be too small - toolbar may not be visible")
                print("   Try resizing the window to be taller")
            }
        }
        break
    }
}

print("\nIf home button isn't working:")
print("1. Make sure iPhone Mirroring is open and focused")
print("2. Try manually hovering at top to reveal toolbar")
print("3. Note where the home button actually appears")
print("4. Window size might affect toolbar position")