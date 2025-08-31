//
//  ToolbarDetector.swift
//  iosAppTester
//
//  Detects and maps iPhone Mirroring toolbar buttons
//

import Foundation
import AppKit
import CoreGraphics
import ScreenCaptureKit

class ToolbarDetector {
    
    struct ToolbarButton {
        let name: String
        let position: CGPoint
        let size: CGSize
        let iconDescription: String?
    }
    
    struct ToolbarLayout {
        let isVisible: Bool
        let bounds: CGRect
        let buttons: [ToolbarButton]
        let detectedAt: Date
    }
    
    // Known button positions based on typical iPhone Mirroring layout
    // These are relative positions from the window origin
    private static let buttonConfigurations: [String: (xOffset: CGFloat, yOffset: CGFloat)] = [
        "back": (30, 30),           // Far left
        "home": (170, 30),          // Center-left  
        "appSwitcher": (210, 30),   // Center-right
        "screenshot": (250, 30),     // Right of center
        "more": (340, 30)           // Far right
    ]
    
    /// Detects toolbar visibility by checking pixel colors at expected toolbar location
    static func detectToolbar(in windowBounds: CGRect) -> ToolbarLayout {
        // The toolbar appears at the top of the window when hovering
        let toolbarHeight: CGFloat = 60
        let toolbarBounds = CGRect(
            x: windowBounds.origin.x,
            y: windowBounds.origin.y,
            width: windowBounds.width,
            height: toolbarHeight
        )
        
        // Check if toolbar is visible (this is a simplified check)
        // In reality, you'd need to capture the screen and analyze pixels
        let isVisible = checkToolbarVisibility(at: toolbarBounds)
        
        // Map buttons based on window width
        let buttons = mapButtons(for: windowBounds)
        
        return ToolbarLayout(
            isVisible: isVisible,
            bounds: toolbarBounds,
            buttons: buttons,
            detectedAt: Date()
        )
    }
    
    /// Maps button positions based on window dimensions
    static func mapButtons(for windowBounds: CGRect) -> [ToolbarButton] {
        let width = windowBounds.width
        
        // Adjust button positions based on window width
        // iPhone Mirroring typically has 372px width
        let scaleFactor = width / 372.0
        
        var buttons: [ToolbarButton] = []
        
        // Back button (if present)
        buttons.append(ToolbarButton(
            name: "back",
            position: CGPoint(x: 30 * scaleFactor, y: 30),
            size: CGSize(width: 30, height: 30),
            iconDescription: "Arrow pointing left"
        ))
        
        // Home button - slightly left of center
        let homeX = (width / 2) - (20 * scaleFactor)
        buttons.append(ToolbarButton(
            name: "home",
            position: CGPoint(x: homeX, y: 30),
            size: CGSize(width: 30, height: 30),
            iconDescription: "Rounded rectangle or circle"
        ))
        
        // App Switcher - slightly right of center
        let appSwitcherX = (width / 2) + (20 * scaleFactor)
        buttons.append(ToolbarButton(
            name: "appSwitcher",
            position: CGPoint(x: appSwitcherX, y: 30),
            size: CGSize(width: 30, height: 30),
            iconDescription: "Two overlapping rectangles"
        ))
        
        // Screenshot button (if present)
        let screenshotX = width - (80 * scaleFactor)
        buttons.append(ToolbarButton(
            name: "screenshot",
            position: CGPoint(x: screenshotX, y: 30),
            size: CGSize(width: 30, height: 30),
            iconDescription: "Camera icon"
        ))
        
        // More options (three dots)
        let moreX = width - (30 * scaleFactor)
        buttons.append(ToolbarButton(
            name: "more",
            position: CGPoint(x: moreX, y: 30),
            size: CGSize(width: 30, height: 30),
            iconDescription: "Three dots"
        ))
        
        return buttons
    }
    
    /// Checks if toolbar is visible (simplified - would need actual pixel analysis)
    private static func checkToolbarVisibility(at bounds: CGRect) -> Bool {
        // This would need to:
        // 1. Capture screenshot of the toolbar area
        // 2. Analyze pixels for toolbar background (usually dark translucent)
        // 3. Look for button shapes/icons
        
        // For now, return true after hover
        return true
    }
    
    /// Captures a screenshot of the toolbar area for analysis using ScreenCaptureKit
    static func captureToolbarArea(windowBounds: CGRect) async -> NSImage? {
        let toolbarHeight: CGFloat = 60
        let captureRect = CGRect(
            x: windowBounds.origin.x,
            y: windowBounds.origin.y,
            width: windowBounds.width,
            height: toolbarHeight
        )
        
        do {
            // Get available content
            let availableContent = try await SCShareableContent.current
            
            // Find the display containing our window
            guard let display = availableContent.displays.first(where: { display in
                let displayBounds = CGRect(
                    x: 0,
                    y: 0,
                    width: CGFloat(display.width),
                    height: CGFloat(display.height)
                )
                return displayBounds.contains(captureRect)
            }) else {
                print("❌ No display found containing the toolbar area")
                return nil
            }
            
            // Create stream configuration
            let config = SCStreamConfiguration()
            config.sourceRect = captureRect
            config.width = Int(captureRect.width)
            config.height = Int(captureRect.height)
            config.scalesToFit = false
            
            // Create content filter for the display
            let filter = SCContentFilter(display: display, excludingWindows: [])
            
            // Capture a single frame
            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
            
            return NSImage(cgImage: image, size: captureRect.size)
            
        } catch {
            print("❌ Failed to capture toolbar area: \(error)")
            return nil
        }
    }
    
    /// Analyzes toolbar screenshot to find exact button positions
    static func analyzeToolbarImage(_ image: NSImage) -> [ToolbarButton] {
        // This would involve:
        // 1. Convert to bitmap
        // 2. Look for circular/rectangular button shapes
        // 3. Identify icons within buttons
        // 4. Return precise positions
        
        // Placeholder for actual image analysis
        return []
    }
    
    /// Finds a specific button by name
    static func findButton(named name: String, in windowBounds: CGRect) -> CGPoint? {
        let layout = detectToolbar(in: windowBounds)
        
        if let button = layout.buttons.first(where: { $0.name == name }) {
            return CGPoint(
                x: windowBounds.origin.x + button.position.x,
                y: windowBounds.origin.y + button.position.y
            )
        }
        
        return nil
    }
    
    /// Calibrates button positions by testing clicks
    static func calibrateButtons(windowBounds: CGRect, automation: iPhoneAutomation) async {
        print("🎯 Starting toolbar calibration...")
        
        // Hover to reveal toolbar
        let hoverPoint = CGPoint(
            x: windowBounds.origin.x + windowBounds.width / 2,
            y: windowBounds.origin.y + 30
        )
        
        if let moveEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: hoverPoint,
            mouseButton: .left
        ) {
            moveEvent.post(tap: .cghidEventTap)
        }
        
        // Wait for toolbar to appear
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Capture toolbar screenshot
        if let toolbarImage = await captureToolbarArea(windowBounds: windowBounds) {
            // Save for analysis
            saveToolbarImage(toolbarImage)
            
            // Analyze to find buttons
            let buttons = analyzeToolbarImage(toolbarImage)
            
            print("📍 Found \(buttons.count) buttons in toolbar")
            for button in buttons {
                print("  - \(button.name) at (\(button.position.x), \(button.position.y))")
            }
        }
    }
    
    private static func saveToolbarImage(_ image: NSImage) {
        // Save to desktop for manual analysis
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let fileURL = desktopURL.appendingPathComponent("toolbar_capture_\(Date().timeIntervalSince1970).png")
        
        if let tiffData = image.tiffRepresentation,
           let bitmapRep = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapRep.representation(using: .png, properties: [:]) {
            try? pngData.write(to: fileURL)
            print("💾 Toolbar screenshot saved to: \(fileURL.path)")
        }
    }
}