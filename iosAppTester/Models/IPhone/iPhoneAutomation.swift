//
//  iPhoneAutomation.swift
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

class iPhoneAutomation: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isConnected = false
    @Published var deviceName = ""
    @Published var automationLog: [String] = []
    @Published var hasAccessibilityPermission = false
    @Published var permissionCheckComplete = false
    @Published var connectionQuality: ConnectionQuality = .unknown
    @Published var lastResponseTime: TimeInterval = 0
    
    enum ConnectionQuality: String {
        case excellent = "Excellent"  // < 100ms
        case good = "Good"            // 100-300ms
        case fair = "Fair"            // 300-500ms
        case poor = "Poor"            // 500-1000ms
        case bad = "Bad"              // > 1000ms
        case disconnected = "Disconnected"
        case unknown = "Unknown"
        
        var color: String {
            switch self {
            case .excellent: return "🟢"
            case .good: return "🟢"
            case .fair: return "🟡"
            case .poor: return "🟠"
            case .bad: return "🔴"
            case .disconnected: return "⚫"
            case .unknown: return "⚪"
            }
        }
    }
    
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
        let previousStatus = hasAccessibilityPermission
        hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        permissionCheckComplete = true
        
        // Only log if status changed or this is the first check
        if previousStatus != hasAccessibilityPermission {
            if !hasAccessibilityPermission {
                log("⚠️ Accessibility permission required for automation", level: .warning)
            } else {
                log("✅ Accessibility permission granted", level: .success)
            }
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
        
        guard AppFocusManager.shared.canAcceptInput else {
            log("⚠️ Cannot type - app not in focus", level: .warning)
            return
        }
        
        let success = KeyboardController.typeText(text) { 
            // No focus action - just type
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
        
        guard AppFocusManager.shared.canAcceptInput else {
            log("⚠️ Cannot paste - app not in focus", level: .warning)
            return
        }
        
        let success = KeyboardController.pasteText(text) {
            // No focus action - just paste
        }
        
        if success {
            log("📋 Pasted: \(text)", level: .success)
        } else {
            log("❌ Failed to paste text", level: .error)
        }
    }
    
    // MARK: - Mouse/Gesture Control
    
    func tapAt(x: CGFloat, y: CGFloat, in windowBounds: CGRect, retryCount: Int = 0) {
        guard hasAccessibilityPermission else {
            log("❌ Cannot tap - accessibility permission required", level: .error)
            return
        }
        
        guard AppFocusManager.shared.canAcceptInput else {
            log("⚠️ Cannot tap - app not in focus", level: .warning)
            return
        }
        
        // Check connection quality before action
        if connectionQuality == .disconnected || connectionQuality == .bad {
            log("⚠️ Poor connection detected, attempting action...", level: .warning)
        }
        
        // Try the tap
        MouseController.tapAt(x: x, y: y, in: windowBounds)
        
        // Verify window still exists (connection still active)
        if WindowDetector.getiPhoneMirroringWindow() == nil {
            if retryCount < 3 {
                log("🔄 Connection lost, retrying tap... (attempt \(retryCount + 1)/3)", level: .warning)
                Thread.sleep(forTimeInterval: 1.0) // Wait a second before retry
                
                // Try to detect window again
                if detectiPhoneMirroring() {
                    if let newBounds = getiPhoneMirroringWindow() {
                        tapAt(x: x, y: y, in: newBounds, retryCount: retryCount + 1)
                        return
                    }
                }
            } else {
                log("❌ Failed to tap after 3 retries - connection lost", level: .error)
                connectionQuality = .disconnected
                return
            }
        }
        
        log("👆 Tapped at (\(Int(x)), \(Int(y)))", level: .info)
    }
    
    /// Ensures the iPhone Mirroring window is focused before performing actions
    func ensureWindowFocused() {
        guard let windowInfo = WindowDetector.getiPhoneMirroringWindow() else { 
            log("❌ Cannot focus - window not found", level: .error)
            connectionQuality = .disconnected
            return 
        }
        
        // Activate the iPhone Mirroring app first
        WindowDetector.activateiPhoneMirroring()
        Thread.sleep(forTimeInterval: 0.2)
        
        // Click once in a safe area to ensure the window has focus
        let safeX = windowInfo.bounds.origin.x + windowInfo.bounds.width / 2
        let safeY = windowInfo.bounds.origin.y + 50 // Near top but not in title bar
        
        MouseController.click(at: CGPoint(x: safeX, y: safeY), clickCount: 1)
        Thread.sleep(forTimeInterval: 0.1)
        
        log("🎯 Window focused", level: .info)
    }
    
    private var lastLoggedQuality: ConnectionQuality?
    
    /// Tests connection quality by checking window existence without moving cursor
    func testConnectionQuality() {
        let startTime = Date()
        
        // Simply check if window exists without any cursor movement
        guard let _ = WindowDetector.getiPhoneMirroringWindow() else {
            connectionQuality = .disconnected
            log("⚫ Connection lost - iPhone Mirroring window not found", level: .error)
            return
        }
        
        // Measure how fast we can detect the window
        let responseTime = Date().timeIntervalSince(startTime) * 1000 // Convert to ms
        lastResponseTime = responseTime
        
        // Update connection quality based on detection speed
        if responseTime < 10 {
            connectionQuality = .excellent
        } else if responseTime < 30 {
            connectionQuality = .good
        } else if responseTime < 50 {
            connectionQuality = .fair
        } else if responseTime < 100 {
            connectionQuality = .poor
        } else {
            connectionQuality = .bad
        }
        
        // Only log if quality changed
        if lastLoggedQuality != connectionQuality {
            log("\(connectionQuality.color) Connection: \(connectionQuality.rawValue) (\(Int(responseTime))ms)", level: .info)
            lastLoggedQuality = connectionQuality
        }
    }
    
    func swipe(from: CGPoint, to: CGPoint, in windowBounds: CGRect, duration: TimeInterval = 0.5) {
        guard hasAccessibilityPermission else {
            log("❌ Cannot swipe - accessibility permission required", level: .error)
            return
        }
        
        guard AppFocusManager.shared.canAcceptInput else {
            log("⚠️ Cannot swipe - app not in focus", level: .warning)
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
        
        guard AppFocusManager.shared.canAcceptInput else {
            log("⚠️ Cannot press Home - app not in focus", level: .warning)
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
        
        guard AppFocusManager.shared.canAcceptInput else {
            log("⚠️ Cannot open App Switcher - app not in focus", level: .warning)
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
    
    func log(_ message: String, level: LogLevel) {
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

extension iPhoneAutomation: iPhoneAutomationController {
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