//
//  iPhoneAutomation.swift
//  iosAppTester
//
//  Automation support for iPhone via iPhone Mirroring
//
//  IMPORTANT: iPhone Mirroring Automation Notes
//  ============================================
//  
//  WHAT WORKS:
//  ✅ AppleScript System Events for typing text
//  ✅ AppleScript for paste operations (Cmd+V)
//  ✅ Virtual key codes WITH proper key code values (not 0)
//  ✅ Mouse clicks and swipes via CGEvent
//  ✅ Window detection and focusing
//
//  WHAT DOESN'T WORK:
//  ❌ CGEvent with virtualKey: 0 and unicode strings
//     - Results in typing 'aaaaa' instead of actual characters
//     - The unicode character information gets lost
//  ❌ Direct CGEvent keyboard events without proper virtual key codes
//  ❌ Accessibility API direct text setting (AXUIElement)
//
//  KEY FINDINGS:
//  - iPhone Mirroring (com.apple.ScreenContinuity) doesn't handle
//    synthetic keyboard events the same way as regular macOS apps
//  - AppleScript provides the most reliable text input method
//  - Mouse events work normally through CGEvent
//  - Always use actual virtual key codes, not 0
//

import Foundation
import AppKit
import CoreGraphics

class iPhoneAutomation: ObservableObject {
    @Published var isConnected = false
    @Published var deviceName = ""
    @Published var automationLog: [String] = []
    @Published var hasAccessibilityPermission = false
    @Published var permissionCheckComplete = false
    
    private let workspace = NSWorkspace.shared
    
    init() {
        checkAccessibilityPermission()
    }
    
    func checkAccessibilityPermission() {
        // Check if we have accessibility permissions
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        permissionCheckComplete = true
        
        if !hasAccessibilityPermission {
            log("⚠️ Accessibility permission required for automation")
        } else {
            log("✅ Accessibility permission granted")
        }
    }
    
    func requestAccessibilityPermission() {
        // This will prompt the user to grant accessibility permission
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // Open System Settings to Accessibility
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
        
        log("📝 Please grant accessibility permission in System Settings")
    }
    
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
        guard hasAccessibilityPermission else {
            log("❌ Cannot tap - accessibility permission required")
            return
        }
        
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
        guard hasAccessibilityPermission else {
            log("❌ Cannot swipe - accessibility permission required")
            return
        }
        
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
    
    // Type text - Using direct key codes since AppleScript has sandbox issues
    func typeText(_ text: String) {
        guard hasAccessibilityPermission else {
            log("❌ Cannot type - accessibility permission required")
            return
        }
        
        // Ensure iPhone Mirroring window is focused
        if let window = getiPhoneMirroringWindow() {
            // Click to focus the window first
            let centerX = window.origin.x + window.width / 2
            let centerY = window.origin.y + window.height / 2
            
            let clickEvent = CGEvent(
                mouseEventSource: nil,
                mouseType: .leftMouseDown,
                mouseCursorPosition: CGPoint(x: centerX, y: centerY),
                mouseButton: .left
            )
            clickEvent?.post(tap: .cghidEventTap)
            
            let releaseEvent = CGEvent(
                mouseEventSource: nil,
                mouseType: .leftMouseUp,
                mouseCursorPosition: CGPoint(x: centerX, y: centerY),
                mouseButton: .left
            )
            releaseEvent?.post(tap: .cghidEventTap)
            
            Thread.sleep(forTimeInterval: 0.2)
        }
        
        // Use direct key codes approach that worked in testing
        let source = CGEventSource(stateID: .combinedSessionState)
        
        for char in text.lowercased() {
            guard let keyCode = characterToKeyCode(char) else {
                log("⚠️ Unsupported character: \(char)")
                continue
            }
            
            // Create key down event with proper key code
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
                // Also set the unicode string for better compatibility
                let utf16 = Array(String(char).utf16)
                keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
                keyDown.post(tap: .cghidEventTap)
            }
            
            Thread.sleep(forTimeInterval: 0.05)
            
            // Create key up event
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
                keyUp.post(tap: .cghidEventTap)
            }
            
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        log("⌨️ Typed: \(text)")
    }
    
    // Helper function to map characters to virtual key codes
    private func characterToKeyCode(_ char: Character) -> CGKeyCode? {
        switch char {
        case "a": return 0
        case "b": return 11
        case "c": return 8
        case "d": return 2
        case "e": return 14
        case "f": return 3
        case "g": return 5
        case "h": return 4
        case "i": return 34
        case "j": return 38
        case "k": return 40
        case "l": return 37
        case "m": return 46
        case "n": return 45
        case "o": return 31
        case "p": return 35
        case "q": return 12
        case "r": return 15
        case "s": return 1
        case "t": return 17
        case "u": return 32
        case "v": return 9
        case "w": return 13
        case "x": return 7
        case "y": return 16
        case "z": return 6
        case "0": return 29
        case "1": return 18
        case "2": return 19
        case "3": return 20
        case "4": return 21
        case "5": return 23
        case "6": return 22
        case "7": return 26
        case "8": return 28
        case "9": return 25
        case " ": return 49  // Space
        case ".": return 47
        case ",": return 43
        case "!": return 18  // Would need shift
        case "?": return 44  // Would need shift
        case "-": return 27
        case "=": return 24
        case "\n": return 36  // Return
        default: return nil
        }
    }
    
    // Alternative: Use paste with direct CGEvent
    // NOTE: iPhone Mirroring requires explicit Command key press/release sequence
    // The .maskCommand flag alone doesn't work - outputs 'v' instead of pasting
    func pasteText(_ text: String) {
        guard hasAccessibilityPermission else {
            log("❌ Cannot paste - accessibility permission required")
            return
        }
        
        // Copy text to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Ensure window is focused
        if let window = getiPhoneMirroringWindow() {
            let centerX = window.origin.x + window.width / 2
            let centerY = window.origin.y + window.height / 2
            
            let click = CGEvent(
                mouseEventSource: nil,
                mouseType: .leftMouseDown,
                mouseCursorPosition: CGPoint(x: centerX, y: centerY),
                mouseButton: .left
            )
            click?.post(tap: .cghidEventTap)
            
            Thread.sleep(forTimeInterval: 0.05)
            
            let release = CGEvent(
                mouseEventSource: nil,
                mouseType: .leftMouseUp,
                mouseCursorPosition: CGPoint(x: centerX, y: centerY),
                mouseButton: .left
            )
            release?.post(tap: .cghidEventTap)
            
            Thread.sleep(forTimeInterval: 0.2)
        }
        
        // Use the sequence: Press Cmd, Press V, Release V, Release Cmd
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // 1. Press Command key
        if let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 55, keyDown: true) { // Command key
            cmdDown.post(tap: .cghidEventTap)
        }
        
        Thread.sleep(forTimeInterval: 0.02)
        
        // 2. Press V key (without flag since Cmd is already pressed)
        if let vDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true) { // V key
            vDown.post(tap: .cghidEventTap)
        }
        
        Thread.sleep(forTimeInterval: 0.02)
        
        // 3. Release V key
        if let vUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) {
            vUp.post(tap: .cghidEventTap)
        }
        
        Thread.sleep(forTimeInterval: 0.02)
        
        // 4. Release Command key
        if let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 55, keyDown: false) {
            cmdUp.post(tap: .cghidEventTap)
        }
        
        log("📋 Pasted: \(text)")
    }
    
    // Press home button (Command+Shift+H in iPhone Mirroring)
    func pressHome() {
        guard hasAccessibilityPermission else {
            log("❌ Cannot press Home - accessibility permission required")
            return
        }
        
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
        guard hasAccessibilityPermission else {
            log("❌ Cannot open App Switcher - accessibility permission required")
            return
        }
        
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