//
//  ScreenshotAction.swift
//  iosAppTester
//
//  Service responsible for capturing screenshots
//

import SwiftUI
import AppKit

class ScreenshotAction: QuickAction {
    private let context: QuickActionContext
    
    var name: String { "Capture Screenshot" }
    var icon: String { "camera" }
    
    var isEnabled: Bool {
        context.automation.isConnected
    }
    
    init(context: QuickActionContext) {
        self.context = context
    }
    
    func execute() {
        guard isEnabled else { 
            print("❌ Screenshot action disabled - iPhone not connected")
            return 
        }
        
        guard let screenshotManager = context.screenshotManager else {
            print("❌ Screenshot manager not available")
            return
        }
        
        // Find iPhone Mirroring app  
        guard let app = findIPhoneMirroringApp(in: screenshotManager.runningApps) else {
            print("❌ iPhone Mirroring app not found")
            return
        }
        
        let scenario = createScreenshotScenario()
        
        screenshotManager.captureScreenshot(of: app, scenario: scenario) { result in
            switch result {
            case .success:
                print("✅ iPhone screenshot captured successfully")
            case .failure(let error):
                print("❌ Failed to capture screenshot: \(error.localizedDescription)")
            }
        }
    }
    
    private func findIPhoneMirroringApp(in apps: [RunningApp]) -> RunningApp? {
        apps.first { app in
            app.name.contains("iPhone") || 
            app.bundleIdentifier?.contains("ScreenContinuity") == true
        }
    }
    
    private func createScreenshotScenario() -> TestScenario {
        TestScenario(
            name: "iPhone Screenshot",
            description: "Captured from iPhone Mirroring",
            deviceType: .iPhone,
            delayBeforeCapture: 0.5,
            actions: []
        )
    }
}