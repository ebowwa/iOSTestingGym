//
//  AppSwitcherAction.swift
//  iosAppTester
//
//  Service responsible for opening the app switcher
//

import SwiftUI

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
        
        let success = context.automation.openAppSwitcher()
        
        if success {
            print("✅ App Switcher opened successfully")
        } else {
            print("❌ Failed to open App Switcher")
        }
    }
}