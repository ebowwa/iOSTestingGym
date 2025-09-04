//
//  AppSwitcherCloserAction.swift
//  iosAppTester
//
//  Service responsible for closing the app switcher
//  Based on analytics: Closes by clicking at 93% width, 2% height (same as opener)
//

import SwiftUI
import CoreGraphics

class AppSwitcherCloserAction: QuickAction {
    private let context: QuickActionContext
    
    var name: String { "Close App Switcher" }
    var icon: String { "xmark.square.fill" }
    
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
            print("❌ App Switcher Closer action disabled - check permissions and connection")
            return 
        }
        
        guard let windowBounds = context.automation.getiPhoneMirroringWindow() else {
            print("❌ Cannot close App Switcher - window not found")
            return
        }
        
        print("🔄 Starting App Switcher Closer sequence...")
        
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
        
        // 4. Click to close App Switcher - analytics shows same position as opener (93% width, 2% height)
        let closerX = windowBounds.origin.x + (windowBounds.width * 0.93)
        let closerY = windowBounds.origin.y + (windowBounds.height * 0.02)  // 2% from top based on analytics
        let clickPoint = CGPoint(x: closerX, y: closerY)
        
        print("🎯 Clicking to close App Switcher at 93% width, 2% height: (\(Int(clickPoint.x)), \(Int(clickPoint.y)))")
        
        // Click to close
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
        
        print("✅ App Switcher Closer executed - clicked at 93% width, 2% height")
    }
}