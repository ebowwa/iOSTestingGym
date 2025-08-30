//
//  iPhoneAutomation.swift
//  iosAppTester
//
//  Automation support for iPhone via iPhone Mirroring
//

import Foundation
import AppKit
import CoreGraphics

class iPhoneAutomation: ObservableObject {
    @Published var isConnected = false
    @Published var deviceName = ""
    @Published var automationLog: [String] = []
    
    private let workspace = NSWorkspace.shared
    
    // iPhone Mirroring window detection
    func detectiPhoneMirroring() -> Bool {
        let runningApps = workspace.runningApplications
        for app in runningApps {
            if app.bundleIdentifier == "com.apple.ScreenContinuity" ||
               app.localizedName?.contains("iPhone Mirroring") == true {
                isConnected = true
                deviceName = "iPhone (via Mirroring)"
                log("✅ iPhone Mirroring detected")
                return true
            }
        }
        isConnected = false
        log("❌ iPhone Mirroring not found")
        return false
    }
    
    // Get iPhone Mirroring window bounds
    func getiPhoneMirroringWindow() -> CGRect? {
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        
        for window in windowList {
            if let ownerName = window[kCGWindowOwnerName as String] as? String,
               ownerName.contains("iPhone Mirroring") {
                if let bounds = window[kCGWindowBounds as String] as? [String: Any],
                   let x = bounds["X"] as? CGFloat,
                   let y = bounds["Y"] as? CGFloat,
                   let width = bounds["Width"] as? CGFloat,
                   let height = bounds["Height"] as? CGFloat {
                    return CGRect(x: x, y: y, width: width, height: height)
                }
            }
        }
        return nil
    }
    
    // Simulate touch at specific coordinates
    func tapAt(x: CGFloat, y: CGFloat, in windowBounds: CGRect) {
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
        let clickDown = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: CGPoint(x: absoluteX, y: absoluteY),
            mouseButton: .left
        )
        clickDown?.post(tap: .cghidEventTap)
        
        Thread.sleep(forTimeInterval: 0.05)
        
        let clickUp = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: CGPoint(x: absoluteX, y: absoluteY),
            mouseButton: .left
        )
        clickUp?.post(tap: .cghidEventTap)
        
        log("👆 Tapped at (\(Int(x)), \(Int(y)))")
    }
    
    // Simulate swipe
    func swipe(from: CGPoint, to: CGPoint, in windowBounds: CGRect, duration: TimeInterval = 0.5) {
        let startX = windowBounds.origin.x + from.x
        let startY = windowBounds.origin.y + from.y
        let endX = windowBounds.origin.x + to.x
        let endY = windowBounds.origin.y + to.y
        
        let steps = 20
        let stepDuration = duration / Double(steps)
        
        // Press down
        let mouseDown = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: CGPoint(x: startX, y: startY),
            mouseButton: .left
        )
        mouseDown?.post(tap: .cghidEventTap)
        
        // Drag
        for i in 1...steps {
            let progress = CGFloat(i) / CGFloat(steps)
            let currentX = startX + (endX - startX) * progress
            let currentY = startY + (endY - startY) * progress
            
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
            mouseCursorPosition: CGPoint(x: endX, y: endY),
            mouseButton: .left
        )
        mouseUp?.post(tap: .cghidEventTap)
        
        log("👉 Swiped from (\(Int(from.x)), \(Int(from.y))) to (\(Int(to.x)), \(Int(to.y)))")
    }
    
    // Type text
    func typeText(_ text: String) {
        for char in text {
            if let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) {
                event.keyboardSetUnicodeString(stringLength: 1, unicodeString: [UniChar(String(char).utf16.first!)])
                event.post(tap: .cghidEventTap)
            }
            
            if let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) {
                event.keyboardSetUnicodeString(stringLength: 1, unicodeString: [UniChar(String(char).utf16.first!)])
                event.post(tap: .cghidEventTap)
            }
            
            Thread.sleep(forTimeInterval: 0.05)
        }
        log("⌨️ Typed: \(text)")
    }
    
    // Press home button (Command+Shift+H in iPhone Mirroring)
    func pressHome() {
        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 4, keyDown: true) // H key
        keyDown?.flags = [.maskCommand, .maskShift]
        keyDown?.post(tap: .cghidEventTap)
        
        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 4, keyDown: false)
        keyUp?.flags = [.maskCommand, .maskShift]
        keyUp?.post(tap: .cghidEventTap)
        
        log("🏠 Pressed Home")
    }
    
    // App switcher (Command+Shift+A)
    func openAppSwitcher() {
        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) // A key
        keyDown?.flags = [.maskCommand, .maskShift]
        keyDown?.post(tap: .cghidEventTap)
        
        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)
        keyUp?.flags = [.maskCommand, .maskShift]
        keyUp?.post(tap: .cghidEventTap)
        
        log("📱 Opened App Switcher")
    }
    
    private func log(_ message: String) {
        DispatchQueue.main.async {
            self.automationLog.append("\(Date().formatted(.dateTime.hour().minute().second())): \(message)")
            print("📱 \(message)")
        }
    }
}

// iPhone-specific test scenarios
struct iPhoneTestScenario: Identifiable {
    let id = UUID()
    var name: String
    var description: String
    var actions: [iPhoneAction]
    var delayBetweenActions: TimeInterval = 0.5
    
    static var defaultScenarios: [iPhoneTestScenario] {
        [
            iPhoneTestScenario(
                name: "Open App",
                description: "Navigate to home and open an app",
                actions: [
                    .pressHome,
                    .wait(2.0),
                    .tap(x: 100, y: 200), // Tap on app icon
                    .wait(3.0)
                ]
            ),
            iPhoneTestScenario(
                name: "Scroll Feed",
                description: "Scroll through a feed",
                actions: [
                    .swipe(from: CGPoint(x: 200, y: 500), to: CGPoint(x: 200, y: 200)),
                    .wait(1.0),
                    .swipe(from: CGPoint(x: 200, y: 500), to: CGPoint(x: 200, y: 200)),
                    .wait(1.0)
                ]
            ),
            iPhoneTestScenario(
                name: "Type and Search",
                description: "Type text in search field",
                actions: [
                    .tap(x: 200, y: 100), // Tap search field
                    .wait(0.5),
                    .typeText("Test search"),
                    .wait(1.0)
                ]
            )
        ]
    }
}

enum iPhoneAction {
    case tap(x: CGFloat, y: CGFloat)
    case swipe(from: CGPoint, to: CGPoint)
    case typeText(String)
    case pressHome
    case appSwitcher
    case wait(TimeInterval)
    case screenshot
}