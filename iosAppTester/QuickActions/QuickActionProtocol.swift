//
//  QuickActionProtocol.swift
//  iosAppTester
//
//  Protocol defining the interface for quick actions
//

import SwiftUI

protocol QuickAction {
    var name: String { get }
    var icon: String { get }
    var isEnabled: Bool { get }
    
    func execute()
}

protocol QuickActionContext {
    var automation: iPhoneAutomation { get }
    var screenshotManager: ScreenshotManager? { get }
    var focusManager: AppFocusManager { get }
}

struct DefaultQuickActionContext: QuickActionContext {
    let automation: iPhoneAutomation
    let screenshotManager: ScreenshotManager?
    let focusManager: AppFocusManager
    
    init(automation: iPhoneAutomation, 
         screenshotManager: ScreenshotManager? = nil,
         focusManager: AppFocusManager = .shared) {
        self.automation = automation
        self.screenshotManager = screenshotManager
        self.focusManager = focusManager
    }
}