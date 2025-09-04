//
//  HomeButtonAction.swift
//  iosAppTester
//
//  Service responsible for simulating Home button press
//

import SwiftUI
import CoreGraphics

class HomeButtonAction: QuickAction {
    private let context: QuickActionContext
    
    var name: String { "Home" }
    var icon: String { "house" }
    
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
            print("❌ Home action disabled - check permissions and connection")
            return 
        }
        
        guard let windowBounds = context.automation.getiPhoneMirroringWindow() else {
            print("❌ Cannot press Home - window not found")
            return
        }
        
        // Use the same approach as ActionRecorder which works:
        // 1. Activate the window first
        _ = WindowDetector.activateiPhoneMirroring()
        Thread.sleep(forTimeInterval: 0.1)
        
        // 2. Move mouse to hover position to reveal toolbar (middle of window, near top)
        let hoverX = windowBounds.origin.x + (windowBounds.width * 0.5)
        let hoverY = windowBounds.origin.y + (windowBounds.height * 0.05)  // 5% from top for hover
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
        
        // 4. Click the Home button (85% from left edge, 7% from top - based on analytics)
        let homeButtonX = windowBounds.origin.x + (windowBounds.width * 0.85)
        let homeButtonY = windowBounds.origin.y + (windowBounds.height * 0.07)  // 7% from top based on analytics
        let clickPoint = CGPoint(x: homeButtonX, y: homeButtonY)
        
        // Click the Home button
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
        
        print("✅ Home button pressed at (\(Int(clickPoint.x)), \(Int(clickPoint.y)))")
    }
}