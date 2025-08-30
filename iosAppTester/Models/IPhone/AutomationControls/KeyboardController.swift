//
//  KeyboardController.swift
//  iosAppTester
//
//  Handles keyboard input for iPhone Mirroring automation
//
//  IMPORTANT: iPhone Mirroring Keyboard Notes
//  ==========================================
//  
//  WHAT WORKS:
//  ✅ Virtual key codes WITH proper key code values (not 0)
//  ✅ AppleScript System Events for typing text (but not in sandboxed apps)
//  ✅ Character-to-keycode mapping with CGEvent
//  ✅ Paste operations using Cmd+V with proper modifier keys
//
//  WHAT DOESN'T WORK:
//  ❌ CGEvent with virtualKey: 0 and unicode strings
//     - Results in typing 'aaaaa' instead of actual characters
//     - The unicode character information gets lost
//  ❌ Direct CGEvent keyboard events without proper virtual key codes
//  ❌ AppleScript in sandboxed applications (System Events not accessible)
//
//  KEY FINDINGS:
//  - iPhone Mirroring (com.apple.ScreenContinuity) doesn't handle
//    synthetic keyboard events the same way as regular macOS apps
//  - Must use actual virtual key codes for each character
//  - Paste works but requires explicit Command key press/release
//

import Foundation
import AppKit
import CoreGraphics

class KeyboardController {
    
    // MARK: - Type Text
    
    /// Types text using direct key codes - works reliably with iPhone Mirroring
    static func typeText(_ text: String, focusWindow: (() -> Void)? = nil) -> Bool {
        // Focus window if closure provided
        focusWindow?()
        
        // Use direct key codes approach that worked in testing
        let source = CGEventSource(stateID: .combinedSessionState)
        
        for char in text.lowercased() {
            guard let keyCode = characterToKeyCode(char) else {
                print("⚠️ Unsupported character: \(char)")
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
        
        return true
    }
    
    // MARK: - Paste Text
    
    /// Pastes text using Cmd+V - works with iPhone Mirroring
    /// NOTE: iPhone Mirroring requires explicit Command key press/release sequence
    static func pasteText(_ text: String, focusWindow: (() -> Void)? = nil) -> Bool {
        // Copy text to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Focus window if closure provided
        focusWindow?()
        
        Thread.sleep(forTimeInterval: 0.1) // Give window time to focus
        
        // Use the sequence that actually works: Press Cmd, Press V, Release V, Release Cmd
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
        
        return true
    }
    
    // MARK: - Keyboard Shortcuts
    
    /// Sends a keyboard shortcut (e.g., Cmd+Shift+H for Home)
    static func sendKeyboardShortcut(keyCode: CGKeyCode, modifiers: CGEventFlags) {
        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = modifiers
        keyDown?.post(tap: .cghidEventTap)
        
        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = modifiers
        keyUp?.post(tap: .cghidEventTap)
    }
    
    // MARK: - Character to Key Code Mapping
    
    /// Maps characters to their macOS virtual key codes
    /// Note: Direct CGEvent approach with virtualKey: 0 doesn't work with iPhone Mirroring
    /// The unicode string gets lost and results in typing 'aaaaa' instead of actual characters
    private static func characterToKeyCode(_ char: Character) -> CGKeyCode? {
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
    
    // MARK: - Common Key Codes
    
    struct KeyCodes {
        static let command: CGKeyCode = 55
        static let shift: CGKeyCode = 56
        static let option: CGKeyCode = 58
        static let control: CGKeyCode = 59
        static let escape: CGKeyCode = 53
        static let delete: CGKeyCode = 51
        static let `return`: CGKeyCode = 36
        static let tab: CGKeyCode = 48
        static let space: CGKeyCode = 49
        
        // Letters are defined in characterToKeyCode
        // Numbers are defined in characterToKeyCode
        
        // Special keys for iPhone Mirroring
        static let h: CGKeyCode = 4  // Used for Home (Cmd+Shift+H)
        static let a: CGKeyCode = 0  // Used for App Switcher (Cmd+Shift+A)
        static let v: CGKeyCode = 9  // Used for Paste (Cmd+V)
    }
}