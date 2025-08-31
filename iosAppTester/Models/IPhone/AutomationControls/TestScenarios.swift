//
//  TestScenarios.swift
//  iosAppTester
//
//  Predefined test scenarios for iPhone automation
//

import Foundation
import CoreGraphics

// MARK: - iPhone Test Scenario Implementation

typealias iPhoneTestScenario = iPhoneTestScenarioImpl

struct iPhoneTestScenarioImpl: AutomationScenario, Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let actions: [AutomationAction]
    let delayBetweenActions: TimeInterval
    
    static var defaultScenarios: [iPhoneTestScenario] {
        [
            PredefinedScenarios.openApp,
            PredefinedScenarios.scrollFeed,
            PredefinedScenarios.typeAndSearch,
            PredefinedScenarios.navigateBack,
            PredefinedScenarios.switchApps,
            PredefinedScenarios.fillForm
        ]
    }
    
    func execute(with controller: iPhoneAutomationController) async throws {
        guard controller.isConnected else {
            throw AutomationError.deviceNotConnected
        }
        
        guard controller.hasAccessibilityPermission else {
            throw AutomationError.noPermission
        }
        
        for action in actions {
            switch action {
            case .tap(let x, let y):
                _ = controller.tap(at: CGPoint(x: x, y: y))
                
            case .swipe(let from, let to):
                _ = controller.swipe(from: from, to: to)
                
            case .typeText(let text):
                _ = controller.typeText(text)
                
            case .pasteText(let text):
                _ = controller.pasteText(text)
                
            case .pressHome:
                _ = controller.pressHome()
                
            case .openAppSwitcher:
                _ = controller.openAppSwitcher()
                
            case .wait(let duration):
                try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                
            case .screenshot:
                // Handled externally by ScreenshotManager
                break
            }
            
            // Delay between actions
            if delayBetweenActions > 0 {
                try await Task.sleep(nanoseconds: UInt64(delayBetweenActions * 1_000_000_000))
            }
        }
    }
}

// MARK: - Predefined Scenarios

struct PredefinedScenarios {
    
    static let openApp = iPhoneTestScenarioImpl(
        name: "Open App",
        description: "Navigate to home and open an app",
        actions: [
            .pressHome,
            .wait(2.0),
            .tap(x: 100, y: 200), // Tap on app icon position
            .wait(3.0)
        ],
        delayBetweenActions: 0.5
    )
    
    static let scrollFeed = iPhoneTestScenarioImpl(
        name: "Scroll Feed",
        description: "Scroll through a feed or list",
        actions: [
            .swipe(from: CGPoint(x: 200, y: 500), to: CGPoint(x: 200, y: 200)),
            .wait(1.0),
            .swipe(from: CGPoint(x: 200, y: 500), to: CGPoint(x: 200, y: 200)),
            .wait(1.0),
            .swipe(from: CGPoint(x: 200, y: 500), to: CGPoint(x: 200, y: 200))
        ],
        delayBetweenActions: 0.5
    )
    
    static let typeAndSearch = iPhoneTestScenarioImpl(
        name: "Type and Search",
        description: "Type text in a search field",
        actions: [
            .tap(x: 200, y: 100), // Tap search field
            .wait(0.5),
            .typeText("test search"),
            .wait(1.0),
            .tap(x: 350, y: 100) // Tap search button
        ],
        delayBetweenActions: 0.5
    )
    
    static let navigateBack = iPhoneTestScenarioImpl(
        name: "Navigate Back",
        description: "Use swipe gesture to go back",
        actions: [
            .swipe(from: CGPoint(x: 20, y: 400), to: CGPoint(x: 350, y: 400)),
            .wait(1.0)
        ],
        delayBetweenActions: 0.5
    )
    
    static let switchApps = iPhoneTestScenarioImpl(
        name: "Switch Apps",
        description: "Open app switcher and select different app",
        actions: [
            .openAppSwitcher,
            .wait(1.5),
            .swipe(from: CGPoint(x: 200, y: 400), to: CGPoint(x: 50, y: 400)),
            .wait(0.5),
            .tap(x: 200, y: 400)
        ],
        delayBetweenActions: 0.5
    )
    
    static let fillForm = iPhoneTestScenarioImpl(
        name: "Fill Form",
        description: "Fill out a form with multiple fields",
        actions: [
            .tap(x: 200, y: 200), // First field
            .wait(0.5),
            .typeText("john doe"),
            .wait(0.5),
            .tap(x: 200, y: 280), // Second field
            .wait(0.5),
            .typeText("john@example.com"),
            .wait(0.5),
            .tap(x: 200, y: 360), // Third field
            .wait(0.5),
            .pasteText("Pasted password text"),
            .wait(0.5),
            .tap(x: 200, y: 450) // Submit button
        ],
        delayBetweenActions: 0.3
    )
    
    static let takeMultipleScreenshots = iPhoneTestScenarioImpl(
        name: "Screenshot Series",
        description: "Navigate and take screenshots at different points",
        actions: [
            .screenshot,
            .swipe(from: CGPoint(x: 200, y: 500), to: CGPoint(x: 200, y: 200)),
            .wait(1.0),
            .screenshot,
            .tap(x: 200, y: 300),
            .wait(2.0),
            .screenshot
        ],
        delayBetweenActions: 0.5
    )
    
    // MARK: - All Scenarios
    
    static var all: [iPhoneTestScenarioImpl] {
        [
            openApp,
            scrollFeed,
            typeAndSearch,
            navigateBack,
            switchApps,
            fillForm,
            takeMultipleScreenshots
        ]
    }
    
    // MARK: - Scenario Builder
    
    static func custom(
        name: String,
        description: String,
        actions: [AutomationAction],
        delayBetweenActions: TimeInterval = 0.5
    ) -> iPhoneTestScenarioImpl {
        iPhoneTestScenarioImpl(
            name: name,
            description: description,
            actions: actions,
            delayBetweenActions: delayBetweenActions
        )
    }
}

// MARK: - Scenario Categories

enum ScenarioCategory: String, CaseIterable {
    case navigation = "Navigation"
    case input = "Text Input"
    case gestures = "Gestures"
    case system = "System Controls"
    case testing = "Testing"
    
    var scenarios: [iPhoneTestScenarioImpl] {
        switch self {
        case .navigation:
            return [PredefinedScenarios.openApp, PredefinedScenarios.navigateBack, PredefinedScenarios.switchApps]
        case .input:
            return [PredefinedScenarios.typeAndSearch, PredefinedScenarios.fillForm]
        case .gestures:
            return [PredefinedScenarios.scrollFeed]
        case .system:
            return [PredefinedScenarios.openApp, PredefinedScenarios.switchApps]
        case .testing:
            return [PredefinedScenarios.takeMultipleScreenshots]
        }
    }
}