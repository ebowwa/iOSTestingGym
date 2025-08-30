//
//  iPhoneAutomationRefactored.swift
//  iosAppTester
//
//  Main iPhone automation controller using modular components
//
//  IMPORTANT: iPhone Mirroring Automation Notes
//  ============================================
//  
//  WHAT WORKS:
//  ✅ AppleScript System Events for typing text (not in sandboxed apps)
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
//  - AppleScript provides the most reliable text input method (when not sandboxed)
//  - Mouse events work normally through CGEvent
//  - Always use actual virtual key codes, not 0
//

import Foundation
import AppKit
import CoreGraphics

class iPhoneAutomationRefactored: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isConnected = false
    @Published var deviceName = ""
    @Published var automationLog: [String] = []
    @Published var hasAccessibilityPermission = false
    @Published var permissionCheckComplete = false
    
    // MARK: - Private Properties
    
    private var currentWindow: WindowDetector.WindowInfo?
    
    // MARK: - Initialization
    
    init() {
        checkAccessibilityPermission()
    }
    
    // MARK: - Permission Management
    
    func checkAccessibilityPermission() {
        // Check if we have accessibility permissions
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        permissionCheckComplete = true
        
        if !hasAccessibilityPermission {
            log("⚠️ Accessibility permission required for automation", level: .warning)
        } else {
            log("✅ Accessibility permission granted", level: .success)
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
        
        log("📝 Please grant accessibility permission in System Settings", level: .info)
    }
    
    // MARK: - Detection
    
    func detectiPhoneMirroring() -> Bool {
        let (isRunning, processInfo) = WindowDetector.detectiPhoneMirroring()
        
        if isRunning, let info = processInfo {
            isConnected = true
            deviceName = "iPhone (via Mirroring)"
            log("✅ iPhone Mirroring detected (PID: \(info.processID))", level: .success)
            
            // Try to get window info
            if let windowInfo = WindowDetector.getiPhoneMirroringWindow() {
                currentWindow = windowInfo
                log("📱 Window found: \(windowInfo.description)", level: .info)
            }
            
            return true
        }
        
        isConnected = false
        log("❌ iPhone Mirroring not found", level: .error)
        return false
    }
    
    // MARK: - Window Management
    
    func getiPhoneMirroringWindow() -> CGRect? {
        if let window = currentWindow {
            return window.bounds
        }
        
        // Try to find it again
        if let windowInfo = WindowDetector.getiPhoneMirroringWindow() {
            currentWindow = windowInfo
            return windowInfo.bounds
        }
        
        return nil
    }
    
    private func focusWindow() {
        guard let window = currentWindow else {
            // Try to find window
            if let windowInfo = WindowDetector.getiPhoneMirroringWindow() {
                currentWindow = windowInfo
                MouseController.focusWindow(windowInfo.bounds)
            }
            return
        }
        
        MouseController.focusWindow(window.bounds)
    }
    
    // MARK: - Text Input
    
    func typeTextInternal(_ text: String) {
        guard hasAccessibilityPermission else {
            log("❌ Cannot type - accessibility permission required", level: .error)
            return
        }
        
        let success = KeyboardController.typeText(text) { [weak self] in
            self?.focusWindow()
        }
        
        if success {
            log("⌨️ Typed: \(text)", level: .success)
        } else {
            log("❌ Failed to type text", level: .error)
        }
    }
    
    func pasteTextInternal(_ text: String) {
        guard hasAccessibilityPermission else {
            log("❌ Cannot paste - accessibility permission required", level: .error)
            return
        }
        
        let success = KeyboardController.pasteText(text) { [weak self] in
            self?.focusWindow()
        }
        
        if success {
            log("📋 Pasted: \(text)", level: .success)
        } else {
            log("❌ Failed to paste text", level: .error)
        }
    }
    
    // MARK: - Mouse/Gesture Control
    
    func tapAt(x: CGFloat, y: CGFloat, in windowBounds: CGRect) {
        guard hasAccessibilityPermission else {
            log("❌ Cannot tap - accessibility permission required", level: .error)
            return
        }
        
        MouseController.tapAt(x: x, y: y, in: windowBounds)
        log("👆 Tapped at (\(Int(x)), \(Int(y)))", level: .info)
    }
    
    func swipe(from: CGPoint, to: CGPoint, in windowBounds: CGRect, duration: TimeInterval = 0.5) {
        guard hasAccessibilityPermission else {
            log("❌ Cannot swipe - accessibility permission required", level: .error)
            return
        }
        
        MouseController.swipe(from: from, to: to, in: windowBounds, duration: duration)
        log("👉 Swiped from (\(Int(from.x)), \(Int(from.y))) to (\(Int(to.x)), \(Int(to.y)))", level: .info)
    }
    
    // MARK: - System Controls
    
    func pressHomeInternal() {
        guard hasAccessibilityPermission else {
            log("❌ Cannot press Home - accessibility permission required", level: .error)
            return
        }
        
        // Command+Shift+H
        KeyboardController.sendKeyboardShortcut(
            keyCode: KeyboardController.KeyCodes.h,
            modifiers: [.maskCommand, .maskShift]
        )
        
        log("🏠 Pressed Home", level: .info)
    }
    
    func openAppSwitcherInternal() {
        guard hasAccessibilityPermission else {
            log("❌ Cannot open App Switcher - accessibility permission required", level: .error)
            return
        }
        
        // Command+Shift+A
        KeyboardController.sendKeyboardShortcut(
            keyCode: KeyboardController.KeyCodes.a,
            modifiers: [.maskCommand, .maskShift]
        )
        
        log("📱 Opened App Switcher", level: .info)
    }
    
    // MARK: - Action Execution
    
    func executeAction(_ action: AutomationAction) async throws {
        guard let windowBounds = getiPhoneMirroringWindow() else {
            throw AutomationError.windowNotFound
        }
        
        switch action {
        case .tap(let x, let y):
            tapAt(x: x, y: y, in: windowBounds)
            
        case .swipe(let from, let to):
            swipe(from: from, to: to, in: windowBounds)
            
        case .typeText(let text):
            typeTextInternal(text)
            
        case .pasteText(let text):
            pasteTextInternal(text)
            
        case .pressHome:
            pressHomeInternal()
            
        case .openAppSwitcher:
            openAppSwitcherInternal()
            
        case .wait(let duration):
            try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            
        case .screenshot:
            log("📸 Screenshot action (handled by ScreenshotManager)", level: .info)
        }
    }
    
    // MARK: - Logging
    
    private func log(_ message: String, level: LogLevel) {
        let emoji: String
        switch level {
        case .info: emoji = "📱"
        case .warning: emoji = "⚠️"
        case .error: emoji = "❌"
        case .success: emoji = "✅"
        }
        
        let logMessage = "\(Date().formatted(.dateTime.hour().minute().second())): \(message)"
        
        DispatchQueue.main.async {
            self.automationLog.append(logMessage)
            print("\(emoji) \(message)")
        }
    }
}

// MARK: - Conformance to Protocol

extension iPhoneAutomationRefactored: iPhoneAutomationController {
    func tap(at point: CGPoint) -> Bool {
        guard let windowBounds = getiPhoneMirroringWindow() else { return false }
        tapAt(x: point.x, y: point.y, in: windowBounds)
        return true
    }
    
    func swipe(from: CGPoint, to: CGPoint) -> Bool {
        guard let windowBounds = getiPhoneMirroringWindow() else { return false }
        swipe(from: from, to: to, in: windowBounds)
        return true
    }
    
    func typeText(_ text: String) -> Bool {
        typeTextInternal(text)
        return true
    }
    
    func pasteText(_ text: String) -> Bool {
        pasteTextInternal(text)
        return true
    }
    
    func pressHome() -> Bool {
        pressHomeInternal()
        return true
    }
    
    func openAppSwitcher() -> Bool {
        openAppSwitcherInternal()
        return true
    }
}