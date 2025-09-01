//
//  AppSwitcherAction.swift
//  iosAppTester
//
//  Service responsible for opening the app switcher
//

import SwiftUI
import CoreGraphics

class AppSwitcherAction: QuickAction {
    private let context: QuickActionContext
    
    var name: String { "App Switcher" }
    var icon: String { "square.stack.3d.up" }
    
    var isEnabled: Bool {
        context.automation.isConnected &&
        context.automation.hasAccessibilityPermission &&
        context.focusManager.canAcceptInput
    }
    
    init(context: QuickActionContext) {
        self.context = context
    }
    
    func execute() {
        guard isEnabled else { 
            print("❌ App Switcher action disabled - check permissions and connection")
            return 
        }
        
        guard let windowBounds = context.automation.getiPhoneMirroringWindow() else {
            print("❌ Cannot open App Switcher - window not found")
            return
        }
        
        // Use the same approach as ActionRecorder which works:
        // 1. Activate the window first
        _ = WindowDetector.activateiPhoneMirroring()
        Thread.sleep(forTimeInterval: 0.1)
        
        // 2. Move mouse to hover position to reveal toolbar
        let hoverX = windowBounds.origin.x + windowBounds.width / 2
        let hoverY = windowBounds.origin.y + 30
        let hoverPoint = CGPoint(x: hoverX, y: hoverY)
        
        if let moveEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: hoverPoint,
            mouseButton: .left
        ) {
            moveEvent.post(tap: .cghidEventTap)
        }
        
        // 3. Wait for toolbar to appear
        Thread.sleep(forTimeInterval: 0.5)
        
        // 4. Click the App Switcher button (52% from left edge)
        let appSwitcherX = windowBounds.origin.x + (windowBounds.width * 0.52)
        let appSwitcherY = windowBounds.origin.y + 30
        let clickPoint = CGPoint(x: appSwitcherX, y: appSwitcherY)
        
        // Click the App Switcher button
        if let downEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: clickPoint,
            mouseButton: .left
        ) {
            downEvent.post(tap: .cghidEventTap)
        }
        
        Thread.sleep(forTimeInterval: 0.05)
        
        if let upEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: clickPoint,
            mouseButton: .left
        ) {
            upEvent.post(tap: .cghidEventTap)
        }
        
        print("✅ App Switcher pressed at (\(Int(clickPoint.x)), \(Int(clickPoint.y)))")
    }
}