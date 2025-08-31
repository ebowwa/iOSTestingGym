#!/usr/bin/swift

import Foundation
import AppKit
import CoreGraphics

// Focused test to understand why we're getting 'aaaaa' instead of proper characters

class KeyboardTester {
    
    static func getiPhoneMirroringWindow() -> CGRect? {
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
    
    static func focusWindow() {
        guard let bounds = getiPhoneMirroringWindow() else {
            print("❌ Could not find iPhone Mirroring window")
            return
        }
        
        let centerX = bounds.origin.x + bounds.width / 2
        let centerY = bounds.origin.y + bounds.height / 2
        
        print("Focusing window at (\(centerX), \(centerY))...")
        
        // Triple click to ensure focus
        for _ in 1...3 {
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
            
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        Thread.sleep(forTimeInterval: 0.5)
    }
    
    // Test 1: Using actual virtual key codes for each character
    static func test1_ActualKeyCodes() {
        print("\n=== Test 1: Actual Virtual Key Codes ===")
        focusWindow()
        
        // Mapping of characters to their actual macOS virtual key codes
        let keyMap: [(Character, CGKeyCode, String)] = [
            ("h", 4, "h"),
            ("e", 14, "e"),
            ("l", 37, "l"),
            ("l", 37, "l"),
            ("o", 31, "o")
        ]
        
        print("Typing 'hello' with proper virtual key codes...")
        
        for (_, keyCode, desc) in keyMap {
            if let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true) {
                keyDown.post(tap: .cgSessionEventTap)
                print("  Down: \(desc) (code: \(keyCode))")
            }
            
            Thread.sleep(forTimeInterval: 0.05)
            
            if let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) {
                keyUp.post(tap: .cgSessionEventTap)
                print("  Up: \(desc) (code: \(keyCode))")
            }
            
            Thread.sleep(forTimeInterval: 0.15)
        }
        
        print("Test 1 complete - should show 'hello'")
    }
    
    // Test 2: Using AppleScript with System Events
    static func test2_AppleScriptSystemEvents() {
        print("\n=== Test 2: AppleScript System Events ===")
        focusWindow()
        
        let script = """
        tell application "System Events"
            keystroke "hello"
        end tell
        """
        
        print("Running AppleScript to type 'hello'...")
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error)
            
            if let error = error {
                print("❌ Error: \(error)")
            } else {
                print("✅ AppleScript executed")
            }
        }
        
        print("Test 2 complete")
    }
    
    // Test 3: Individual AppleScript keystrokes
    static func test3_AppleScriptIndividual() {
        print("\n=== Test 3: Individual AppleScript Keystrokes ===")
        focusWindow()
        
        let chars = ["h", "e", "l", "l", "o"]
        
        for char in chars {
            let script = """
            tell application "System Events"
                keystroke "\(char)"
            end tell
            """
            
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: script) {
                scriptObject.executeAndReturnError(&error)
                print("  Typed: \(char)")
            }
            
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        print("Test 3 complete")
    }
    
    // Test 4: Using key codes with explicit characters
    static func test4_KeyCodesWithCharacters() {
        print("\n=== Test 4: Key Codes with Character Info ===")
        focusWindow()
        
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // Map of virtual key codes
        let keyMap: [(CGKeyCode, String)] = [
            (4, "h"),   // H key
            (14, "e"),  // E key
            (37, "l"),  // L key
            (37, "l"),  // L key
            (31, "o")   // O key
        ]
        
        print("Typing with key codes and character info...")
        
        for (keyCode, char) in keyMap {
            // Create event with both key code and character
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
                // Also set the character string
                let charArray = Array(char.utf16)
                keyDown.keyboardSetUnicodeString(stringLength: charArray.count, unicodeString: charArray)
                keyDown.post(tap: .cghidEventTap)
                print("  Down: \(char) (code: \(keyCode))")
            }
            
            Thread.sleep(forTimeInterval: 0.05)
            
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
                keyUp.post(tap: .cghidEventTap)
                print("  Up: \(char)")
            }
            
            Thread.sleep(forTimeInterval: 0.15)
        }
        
        print("Test 4 complete")
    }
    
    // Test 5: Paste with different approach
    static func test5_PasteAlternative() {
        print("\n=== Test 5: Alternative Paste Method ===")
        focusWindow()
        
        // Set clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("hello from paste", forType: .string)
        print("Clipboard set to: 'hello from paste'")
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Use AppleScript to paste
        let script = """
        tell application "System Events"
            keystroke "v" using command down
        end tell
        """
        
        print("Pasting via AppleScript...")
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                print("❌ Error: \(error)")
            } else {
                print("✅ Paste command sent")
            }
        }
        
        print("Test 5 complete")
    }
    
    static func runTests() {
        print("========================================")
        print("Keyboard Input Testing for iPhone Mirroring")
        print("========================================")
        
        // Check permissions
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        if !AXIsProcessTrustedWithOptions(options as CFDictionary) {
            print("❌ Need accessibility permission!")
            return
        }
        
        print("✅ Accessibility permission granted")
        print("\n⚠️  Click on a text field in iPhone Mirroring!")
        print("Starting in 3 seconds...")
        Thread.sleep(forTimeInterval: 3)
        
        // Run each test with delay between
        test1_ActualKeyCodes()
        Thread.sleep(forTimeInterval: 2)
        
        print("\nPress Enter to continue to next test...")
        _ = readLine()
        
        test2_AppleScriptSystemEvents()
        Thread.sleep(forTimeInterval: 2)
        
        print("\nPress Enter to continue to next test...")
        _ = readLine()
        
        test3_AppleScriptIndividual()
        Thread.sleep(forTimeInterval: 2)
        
        print("\nPress Enter to continue to next test...")
        _ = readLine()
        
        test4_KeyCodesWithCharacters()
        Thread.sleep(forTimeInterval: 2)
        
        print("\nPress Enter to continue to next test...")
        _ = readLine()
        
        test5_PasteAlternative()
        
        print("\n========================================")
        print("Testing complete!")
        print("Which methods worked correctly?")
        print("========================================")
    }
}

KeyboardTester.runTests()