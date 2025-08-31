#!/usr/bin/swift

import Foundation
import AppKit
import CoreGraphics

// Test program to explore different methods of controlling iPhone Mirroring

class iPhoneMirroringTester {
    
    // MARK: - Detection
    
    static func detectiPhoneMirroring() -> Bool {
        print("\n=== Testing iPhone Mirroring Detection ===")
        
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        
        for app in runningApps {
            if app.bundleIdentifier == "com.apple.ScreenContinuity" ||
               app.localizedName?.contains("iPhone Mirroring") == true {
                print("✅ Found iPhone Mirroring")
                print("  Bundle ID: \(app.bundleIdentifier ?? "unknown")")
                print("  Name: \(app.localizedName ?? "unknown")")
                print("  Process ID: \(app.processIdentifier)")
                return true
            }
        }
        
        print("❌ iPhone Mirroring not found")
        return false
    }
    
    static func getiPhoneMirroringWindow() -> (windowID: CGWindowID, bounds: CGRect)? {
        print("\n=== Finding iPhone Mirroring Window ===")
        
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            print("❌ Could not get window list")
            return nil
        }
        
        for window in windowList {
            if let ownerName = window[kCGWindowOwnerName as String] as? String {
                if ownerName.contains("iPhone Mirroring") {
                    print("✅ Found iPhone Mirroring window")
                    print("  Owner: \(ownerName)")
                    
                    if let windowID = window[kCGWindowNumber as String] as? CGWindowID,
                       let bounds = window[kCGWindowBounds as String] as? [String: Any],
                       let x = bounds["X"] as? CGFloat,
                       let y = bounds["Y"] as? CGFloat,
                       let width = bounds["Width"] as? CGFloat,
                       let height = bounds["Height"] as? CGFloat {
                        
                        let rect = CGRect(x: x, y: y, width: width, height: height)
                        print("  Window ID: \(windowID)")
                        print("  Bounds: \(rect)")
                        return (windowID, rect)
                    }
                }
            }
        }
        
        print("❌ iPhone Mirroring window not found")
        return nil
    }
    
    // MARK: - Test Methods
    
    static func testMethod1_BasicCGEvent() {
        print("\n=== Method 1: Basic CGEvent with Unicode ===")
        
        guard let windowInfo = getiPhoneMirroringWindow() else { return }
        
        // Click to focus
        let centerX = windowInfo.bounds.origin.x + windowInfo.bounds.width / 2
        let centerY = windowInfo.bounds.origin.y + windowInfo.bounds.height / 2
        
        print("Clicking at center: (\(centerX), \(centerY))")
        
        let clickDown = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: CGPoint(x: centerX, y: centerY),
            mouseButton: .left
        )
        clickDown?.post(tap: .cghidEventTap)
        
        Thread.sleep(forTimeInterval: 0.1)
        
        let clickUp = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: CGPoint(x: centerX, y: centerY),
            mouseButton: .left
        )
        clickUp?.post(tap: .cghidEventTap)
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Try typing
        print("Attempting to type 'test'...")
        
        let source = CGEventSource(stateID: .hidSystemState)
        let text = "test"
        
        for char in text {
            let utf16Char = String(char).utf16.first!
            
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                keyDown.keyboardSetUnicodeString(stringLength: 1, unicodeString: [utf16Char])
                keyDown.post(tap: .cghidEventTap)
                print("  Sent key down: \(char)")
            }
            
            Thread.sleep(forTimeInterval: 0.05)
            
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
                keyUp.keyboardSetUnicodeString(stringLength: 1, unicodeString: [utf16Char])
                keyUp.post(tap: .cghidEventTap)
                print("  Sent key up: \(char)")
            }
            
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        print("Method 1 complete - check if text appeared")
    }
    
    static func testMethod2_VirtualKeyCodes() {
        print("\n=== Method 2: Virtual Key Codes ===")
        
        guard let windowInfo = getiPhoneMirroringWindow() else { return }
        
        // Focus window first
        let centerX = windowInfo.bounds.origin.x + windowInfo.bounds.width / 2
        let centerY = windowInfo.bounds.origin.y + windowInfo.bounds.height / 2
        
        let click = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: CGPoint(x: centerX, y: centerY),
            mouseButton: .left
        )
        click?.post(tap: .cghidEventTap)
        
        let release = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: CGPoint(x: centerX, y: centerY),
            mouseButton: .left
        )
        release?.post(tap: .cghidEventTap)
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Virtual key codes for "test"
        // t=17, e=14, s=1, t=17
        let keyCodes: [(CGKeyCode, String)] = [
            (17, "t"),
            (14, "e"),
            (1, "s"),
            (17, "t")
        ]
        
        print("Attempting to type 'test' with virtual key codes...")
        
        for (keyCode, char) in keyCodes {
            if let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true) {
                keyDown.post(tap: .cghidEventTap)
                print("  Sent key down: \(char) (code: \(keyCode))")
            }
            
            Thread.sleep(forTimeInterval: 0.05)
            
            if let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) {
                keyUp.post(tap: .cghidEventTap)
                print("  Sent key up: \(char) (code: \(keyCode))")
            }
            
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        print("Method 2 complete - check if text appeared")
    }
    
    static func testMethod3_Pasteboard() {
        print("\n=== Method 3: Pasteboard (Cmd+V) ===")
        
        guard let windowInfo = getiPhoneMirroringWindow() else { return }
        
        // Focus window
        let centerX = windowInfo.bounds.origin.x + windowInfo.bounds.width / 2
        let centerY = windowInfo.bounds.origin.y + windowInfo.bounds.height / 2
        
        let click = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: CGPoint(x: centerX, y: centerY),
            mouseButton: .left
        )
        click?.post(tap: .cghidEventTap)
        
        let release = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: CGPoint(x: centerX, y: centerY),
            mouseButton: .left
        )
        release?.post(tap: .cghidEventTap)
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Copy text to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("test from clipboard", forType: .string)
        print("Set clipboard to: 'test from clipboard'")
        
        // Send Cmd+V
        let source = CGEventSource(stateID: .hidSystemState)
        
        print("Sending Cmd+V...")
        
        // Method 3a: Using flags
        if let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) {
            vDown.flags = .maskCommand
            vDown.post(tap: .cghidEventTap)
            print("  Sent Cmd+V down")
        }
        
        Thread.sleep(forTimeInterval: 0.05)
        
        if let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) {
            vUp.flags = .maskCommand
            vUp.post(tap: .cghidEventTap)
            print("  Sent Cmd+V up")
        }
        
        print("Method 3 complete - check if text was pasted")
    }
    
    static func testMethod4_AppleScript() {
        print("\n=== Method 4: AppleScript ===")
        
        let script = """
        tell application "System Events"
            tell process "iPhone Mirroring"
                set frontmost to true
                delay 0.5
                keystroke "test from applescript"
            end tell
        end tell
        """
        
        print("Running AppleScript:")
        print(script)
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error)
            
            if let error = error {
                print("❌ AppleScript error: \(error)")
            } else {
                print("✅ AppleScript executed successfully")
                if let stringValue = output.stringValue {
                    print("  Output: \(stringValue)")
                }
            }
        }
        
        print("Method 4 complete - check if text appeared")
    }
    
    static func testMethod5_AccessibilityAPI() {
        print("\n=== Method 5: Accessibility API ===")
        
        guard detectiPhoneMirroring() else { return }
        
        // Get the iPhone Mirroring app
        let runningApps = NSWorkspace.shared.runningApplications
        guard let app = runningApps.first(where: { 
            $0.bundleIdentifier == "com.apple.ScreenContinuity" ||
            $0.localizedName?.contains("iPhone Mirroring") == true
        }) else {
            print("❌ Could not find iPhone Mirroring app")
            return
        }
        
        print("Creating AXUIElement for PID: \(app.processIdentifier)")
        
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        
        // Try to get focused element
        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(axApp, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        if result == .success, let element = focusedElement {
            print("✅ Got focused element")
            
            // Try to set value
            let testString = "test from accessibility" as CFString
            let setResult = AXUIElementSetAttributeValue(element as! AXUIElement, kAXValueAttribute as CFString, testString)
            
            if setResult == .success {
                print("✅ Set value via Accessibility API")
            } else {
                print("❌ Failed to set value: \(setResult.rawValue)")
            }
        } else {
            print("❌ Could not get focused element: \(result.rawValue)")
        }
        
        print("Method 5 complete")
    }
    
    static func testMethod6_SimulateRealTyping() {
        print("\n=== Method 6: Simulate Real Typing Pattern ===")
        
        guard let windowInfo = getiPhoneMirroringWindow() else { return }
        
        // Focus with multiple clicks (sometimes helps)
        let centerX = windowInfo.bounds.origin.x + windowInfo.bounds.width / 2
        let centerY = windowInfo.bounds.origin.y + windowInfo.bounds.height / 2
        
        print("Triple-clicking to ensure focus...")
        for i in 1...3 {
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
            
            if i < 3 {
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Try with more realistic timing
        let source = CGEventSource(stateID: .combinedSessionState)
        source?.localEventsSuppressionInterval = 0.0
        
        print("Typing with realistic timing...")
        
        let text = "hello"
        for char in text {
            let utf16 = String(char).utf16.first!
            
            // Create events with source
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                keyDown.keyboardSetUnicodeString(stringLength: 1, unicodeString: [utf16])
                keyDown.flags = []
                keyDown.post(tap: .cgSessionEventTap) // Try different tap location
                print("  Down: \(char)")
            }
            
            // Realistic key press duration
            Thread.sleep(forTimeInterval: Double.random(in: 0.05...0.15))
            
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
                keyUp.keyboardSetUnicodeString(stringLength: 1, unicodeString: [utf16])
                keyUp.flags = []
                keyUp.post(tap: .cgSessionEventTap)
                print("  Up: \(char)")
            }
            
            // Realistic typing speed
            Thread.sleep(forTimeInterval: Double.random(in: 0.1...0.3))
        }
        
        print("Method 6 complete - check if text appeared")
    }
    
    // MARK: - Main Test Runner
    
    static func runAllTests() {
        print("========================================")
        print("iPhone Mirroring Automation Test Suite")
        print("========================================")
        
        // Check for accessibility permission
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let hasPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !hasPermission {
            print("\n⚠️  WARNING: Accessibility permission not granted!")
            print("Please grant accessibility permission in System Settings")
            print("System Settings > Privacy & Security > Accessibility")
            return
        }
        
        print("\n✅ Accessibility permission granted")
        
        // Detect iPhone Mirroring
        guard detectiPhoneMirroring() else {
            print("\n❌ iPhone Mirroring is not running. Please open iPhone Mirroring first.")
            return
        }
        
        print("\n⚠️  IMPORTANT: Make sure iPhone Mirroring has a text field focused!")
        print("Waiting 3 seconds for you to click on a text field...")
        Thread.sleep(forTimeInterval: 3)
        
        // Run tests
        print("\n Starting tests in 2 seconds...")
        Thread.sleep(forTimeInterval: 2)
        
        testMethod1_BasicCGEvent()
        Thread.sleep(forTimeInterval: 2)
        
        testMethod2_VirtualKeyCodes()
        Thread.sleep(forTimeInterval: 2)
        
        testMethod3_Pasteboard()
        Thread.sleep(forTimeInterval: 2)
        
        testMethod4_AppleScript()
        Thread.sleep(forTimeInterval: 2)
        
        testMethod5_AccessibilityAPI()
        Thread.sleep(forTimeInterval: 2)
        
        testMethod6_SimulateRealTyping()
        
        print("\n========================================")
        print("All tests complete!")
        print("Please report which methods worked (if any)")
        print("========================================")
    }
}

// Run the tests
iPhoneMirroringTester.runAllTests()