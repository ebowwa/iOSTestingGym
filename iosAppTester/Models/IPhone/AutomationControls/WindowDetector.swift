//
//  WindowDetector.swift
//  iosAppTester
//
//  Handles detection and management of iPhone Mirroring windows
//
//  IMPORTANT: Window Detection Notes
//  =================================
//  
//  WHAT WORKS:
//  ✅ Detecting iPhone Mirroring via bundle ID (com.apple.ScreenContinuity)
//  ✅ Finding window bounds via CGWindowListCopyWindowInfo
//  ✅ Process detection via NSWorkspace
//  ✅ Window focusing via mouse clicks
//
//  KEY FINDINGS:
//  - iPhone Mirroring runs as com.apple.ScreenContinuity
//  - Window size is typically 372x824 pixels (iPhone dimensions)
//  - Multiple detection methods available for redundancy
//

import Foundation
import AppKit
import CoreGraphics

class WindowDetector {
    
    // MARK: - Properties
    
    static let iPhoneMirroringBundleID = "com.apple.ScreenContinuity"
    static let iPhoneMirroringAppName = "iPhone Mirroring"
    
    // MARK: - Process Detection
    
    /// Detects if iPhone Mirroring is running
    static func detectiPhoneMirroring() -> (isRunning: Bool, processInfo: ProcessInfo?) {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        
        for app in runningApps {
            if app.bundleIdentifier == iPhoneMirroringBundleID ||
               app.localizedName?.contains(iPhoneMirroringAppName) == true {
                
                let info = ProcessInfo(
                    bundleID: app.bundleIdentifier ?? "unknown",
                    name: app.localizedName ?? "unknown",
                    processID: app.processIdentifier
                )
                
                return (true, info)
            }
        }
        
        return (false, nil)
    }
    
    // MARK: - Window Detection
    
    /// Finds the iPhone Mirroring window and returns its bounds
    static func getiPhoneMirroringWindow() -> WindowInfo? {
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        
        for window in windowList {
            if let ownerName = window[kCGWindowOwnerName as String] as? String,
               ownerName.contains(iPhoneMirroringAppName) {
                
                if let windowID = window[kCGWindowNumber as String] as? CGWindowID,
                   let bounds = window[kCGWindowBounds as String] as? [String: Any],
                   let x = bounds["X"] as? CGFloat,
                   let y = bounds["Y"] as? CGFloat,
                   let width = bounds["Width"] as? CGFloat,
                   let height = bounds["Height"] as? CGFloat {
                    
                    // Filter out tiny windows (like title bars)
                    // iPhone Mirroring window should be around 372x824
                    if width > 100 && height > 100 {
                        return WindowInfo(
                            windowID: windowID,
                            bounds: CGRect(x: x, y: y, width: width, height: height),
                            ownerName: ownerName
                        )
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Multiple Windows
    
    /// Gets all iPhone Mirroring windows (in case multiple are open)
    static func getAlliPhoneMirroringWindows() -> [WindowInfo] {
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        
        var windows: [WindowInfo] = []
        
        for window in windowList {
            if let ownerName = window[kCGWindowOwnerName as String] as? String,
               ownerName.contains(iPhoneMirroringAppName) {
                
                if let windowID = window[kCGWindowNumber as String] as? CGWindowID,
                   let bounds = window[kCGWindowBounds as String] as? [String: Any],
                   let x = bounds["X"] as? CGFloat,
                   let y = bounds["Y"] as? CGFloat,
                   let width = bounds["Width"] as? CGFloat,
                   let height = bounds["Height"] as? CGFloat {
                    
                    // Filter out tiny windows
                    if width > 100 && height > 100 {
                        windows.append(WindowInfo(
                            windowID: windowID,
                            bounds: CGRect(x: x, y: y, width: width, height: height),
                            ownerName: ownerName
                        ))
                    }
                }
            }
        }
        
        return windows
    }
    
    // MARK: - App Activation
    
    /// Brings iPhone Mirroring to the foreground
    static func activateiPhoneMirroring() -> Bool {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        
        for app in runningApps {
            if app.bundleIdentifier == iPhoneMirroringBundleID ||
               app.localizedName?.contains(iPhoneMirroringAppName) == true {
                return app.activate()
            }
        }
        
        return false
    }
    
    // MARK: - Validation
    
    /// Validates that a window is suitable for automation
    static func isValidAutomationWindow(_ window: WindowInfo) -> Bool {
        // iPhone windows are typically around 372x824
        // But allow some variation for different iPhone models
        let minWidth: CGFloat = 300
        let maxWidth: CGFloat = 500
        let minHeight: CGFloat = 600
        let maxHeight: CGFloat = 1000
        
        return window.bounds.width >= minWidth &&
               window.bounds.width <= maxWidth &&
               window.bounds.height >= minHeight &&
               window.bounds.height <= maxHeight
    }
    
    // MARK: - Helper Types
    
    struct ProcessInfo {
        let bundleID: String
        let name: String
        let processID: pid_t
    }
    
    struct WindowInfo {
        let windowID: CGWindowID
        let bounds: CGRect
        let ownerName: String
        
        var center: CGPoint {
            CGPoint(
                x: bounds.origin.x + bounds.width / 2,
                y: bounds.origin.y + bounds.height / 2
            )
        }
        
        var description: String {
            "Window '\(ownerName)' ID:\(windowID) at \(bounds)"
        }
    }
}