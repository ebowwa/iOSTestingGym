//
//  FocusWindowAction.swift
//  iosAppTester
//
//  Service responsible for focusing the iPhone Mirroring window
//

import SwiftUI

class FocusWindowAction: QuickAction {
    private let context: QuickActionContext
    
    var name: String { "Focus Window" }
    var icon: String { "macwindow.on.rectangle" }
    
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
            print("❌ Focus Window action disabled - check permissions and connection")
            return 
        }
        
        context.automation.ensureWindowFocused()
        print("✅ Window focus requested")
    }
}