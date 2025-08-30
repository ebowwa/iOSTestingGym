//
//  AutomationProtocols.swift
//  iosAppTester
//
//  Defines protocols and interfaces for iPhone automation components
//

import Foundation
import CoreGraphics

// MARK: - Automation Capability Protocol

protocol AutomationCapability {
    var isAvailable: Bool { get }
    var requiresPermission: Bool { get }
    func checkPermission() -> Bool
}

// MARK: - Input Protocol

protocol InputController {
    func sendInput(_ input: String) -> Bool
    func sendKeyCode(_ keyCode: CGKeyCode, modifiers: CGEventFlags?) -> Bool
}

// MARK: - Gesture Protocol

protocol GestureController {
    func tap(at point: CGPoint) -> Bool
    func swipe(from: CGPoint, to: CGPoint, duration: TimeInterval) -> Bool
    func longPress(at point: CGPoint, duration: TimeInterval) -> Bool
}

// MARK: - Window Management Protocol

protocol WindowManager {
    associatedtype WindowType
    func detectWindow() -> WindowType?
    func focusWindow(_ window: WindowType) -> Bool
    func getWindowBounds(_ window: WindowType) -> CGRect?
}

// MARK: - Automation Logger Protocol

protocol AutomationLogger {
    func log(_ message: String, level: LogLevel)
}

enum LogLevel {
    case info
    case warning
    case error
    case success
}

// MARK: - Automation Scenario Protocol

protocol AutomationScenario {
    var name: String { get }
    var description: String { get }
    func execute(with controller: iPhoneAutomationController) async throws
}

// MARK: - Main Controller Protocol

protocol iPhoneAutomationController {
    // Detection
    var isConnected: Bool { get }
    var deviceName: String { get }
    
    // Permissions
    var hasAccessibilityPermission: Bool { get }
    func requestAccessibilityPermission()
    
    // Input
    func typeText(_ text: String) -> Bool
    func pasteText(_ text: String) -> Bool
    
    // Gestures
    func tap(at point: CGPoint) -> Bool
    func swipe(from: CGPoint, to: CGPoint) -> Bool
    
    // System
    func pressHome() -> Bool
    func openAppSwitcher() -> Bool
}

// MARK: - Automation Result

enum AutomationResult<T> {
    case success(T)
    case failure(AutomationError)
}

enum AutomationError: Error, LocalizedError {
    case noPermission
    case windowNotFound
    case deviceNotConnected
    case invalidInput
    case timeout
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .noPermission:
            return "Accessibility permission required"
        case .windowNotFound:
            return "iPhone Mirroring window not found"
        case .deviceNotConnected:
            return "iPhone not connected via Mirroring"
        case .invalidInput:
            return "Invalid input provided"
        case .timeout:
            return "Operation timed out"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Automation Action

enum AutomationAction {
    case tap(x: CGFloat, y: CGFloat)
    case swipe(from: CGPoint, to: CGPoint)
    case typeText(String)
    case pasteText(String)
    case pressHome
    case openAppSwitcher
    case wait(TimeInterval)
    case screenshot
    
    var description: String {
        switch self {
        case .tap(let x, let y):
            return "Tap at (\(x), \(y))"
        case .swipe(let from, let to):
            return "Swipe from \(from) to \(to)"
        case .typeText(let text):
            return "Type: \(text)"
        case .pasteText(let text):
            return "Paste: \(text)"
        case .pressHome:
            return "Press Home"
        case .openAppSwitcher:
            return "Open App Switcher"
        case .wait(let duration):
            return "Wait \(duration)s"
        case .screenshot:
            return "Take Screenshot"
        }
    }
}