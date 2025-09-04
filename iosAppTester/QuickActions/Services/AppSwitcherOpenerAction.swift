//
//  AppSwitcherOpenerAction.swift
//  iosAppTester
//
//  Service responsible for opening the app switcher with correct positioning
//  Based on analytics: App Switcher opens by clicking at 93% width, 2% height (toolbar right side)
//

import SwiftUI
import CoreGraphics

class AppSwitcherOpenerAction: QuickAction {
    private let context: QuickActionContext
    
    var name: String { "App Switcher Opener" }
    var icon: String { "square.stack.3d.up.fill" }
    
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
            print("❌ App Switcher Opener action disabled - check permissions and connection")
            return 
        }
        
        guard let windowBounds = context.automation.getiPhoneMirroringWindow() else {
            print("❌ Cannot open App Switcher - window not found")
            return
        }
        
        print("🔄 Starting App Switcher Opener sequence...")
        
        // 1. Activate the window first
        _ = WindowDetector.activateiPhoneMirroring()
        Thread.sleep(forTimeInterval: 0.1)
        
        // 2. Move mouse to hover position to reveal toolbar
        let hoverX = windowBounds.origin.x + (windowBounds.width * 0.5)
        let hoverY = windowBounds.origin.y + (windowBounds.height * 0.05)  // 5% from top for hover
        let hoverPoint = CGPoint(x: hoverX, y: hoverY)
        
        print("📍 Hovering at toolbar position: (\(Int(hoverX)), \(Int(hoverY)))")
        
        if let moveEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: hoverPoint,
            mouseButton: .left
        ) {
            moveEvent.post(tap: .cghidEventTap)
        }
        
        // 3. Wait for toolbar to appear (500ms based on analytics)
        Thread.sleep(forTimeInterval: 0.5)
        
        // 4. Click to open App Switcher - analytics shows toolbar buttons at 93% width, 2% height
        // Multiple recordings confirm this position
        let appSwitcherX = windowBounds.origin.x + (windowBounds.width * 0.93)
        let appSwitcherY = windowBounds.origin.y + (windowBounds.height * 0.02)  // 2% from top based on analytics
        let clickPoint = CGPoint(x: appSwitcherX, y: appSwitcherY)
        
        print("🎯 Clicking to open App Switcher at 93% width, 2% height: (\(Int(clickPoint.x)), \(Int(clickPoint.y)))")
        
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
        
        print("✅ App Switcher Opener executed - clicked at 93% width, 2% height")
    }
}