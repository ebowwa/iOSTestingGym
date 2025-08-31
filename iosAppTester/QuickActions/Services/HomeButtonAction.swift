//
//  HomeButtonAction.swift
//  iosAppTester
//
//  Service responsible for simulating Home button press
//

import SwiftUI

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
        
        let success = context.automation.pressHome()
        
        if success {
            print("✅ Home button pressed successfully")
        } else {
            print("❌ Failed to press Home button")
        }
    }
}