//
//  iPhoneAutomationView.swift
//  iosAppTester
//
//  UI for iPhone automation via iPhone Mirroring
//

import SwiftUI

struct iPhoneAutomationView: View {
    @StateObject private var automation = iPhoneAutomation()
    @ObservedObject var screenshotManager: ScreenshotManager
    @State private var selectedScenario: iPhoneTestScenario?
    @State private var isRunning = false
    @State private var customX: String = "200"
    @State private var customY: String = "400"
    @State private var customText: String = ""
    
    var body: some View {
        NavigationView {
            // Sidebar
            List {
                Section("Connection Status") {
                    HStack {
                        Circle()
                            .fill(automation.isConnected ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        Text(automation.isConnected ? "iPhone Connected" : "iPhone Not Connected")
                        Spacer()
                        Button("Refresh") {
                            _ = automation.detectiPhoneMirroring()
                        }
                    }
                    
                    if automation.isConnected {
                        Label(automation.deviceName, systemImage: "iphone")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Quick Actions") {
                    Button(action: executeHome) {
                        Label("Home", systemImage: "house")
                    }
                    .disabled(!automation.isConnected)
                    
                    Button(action: executeAppSwitcher) {
                        Label("App Switcher", systemImage: "square.stack.3d.up")
                    }
                    .disabled(!automation.isConnected)
                    
                    Button(action: captureScreenshot) {
                        Label("Capture Screenshot", systemImage: "camera")
                    }
                    .disabled(!automation.isConnected)
                }
                
                Section("Test Scenarios") {
                    ForEach(iPhoneTestScenario.defaultScenarios) { scenario in
                        Button(action: { runScenario(scenario) }) {
                            VStack(alignment: .leading) {
                                Text(scenario.name)
                                    .font(.headline)
                                Text(scenario.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .disabled(!automation.isConnected || isRunning)
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 250)
            
            // Main Content
            VStack {
                // Custom Controls
                GroupBox("Custom Controls") {
                    VStack(spacing: 15) {
                        HStack {
                            Text("Tap Location:")
                            TextField("X", text: $customX)
                                .frame(width: 60)
                            TextField("Y", text: $customY)
                                .frame(width: 60)
                            Button("Tap") {
                                executeCustomTap()
                            }
                            .disabled(!automation.isConnected)
                        }
                        
                        HStack {
                            Text("Type Text:")
                            TextField("Enter text...", text: $customText)
                            Button("Type") {
                                executeTypeText()
                            }
                            .disabled(!automation.isConnected || customText.isEmpty)
                        }
                        
                        HStack {
                            Text("Swipe:")
                            Button("Up") {
                                executeSwipe(direction: .up)
                            }
                            Button("Down") {
                                executeSwipe(direction: .down)
                            }
                            Button("Left") {
                                executeSwipe(direction: .left)
                            }
                            Button("Right") {
                                executeSwipe(direction: .right)
                            }
                        }
                        .disabled(!automation.isConnected)
                    }
                    .padding()
                }
                .padding()
                
                // Automation Log
                GroupBox("Automation Log") {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(automation.automationLog.enumerated()), id: \.offset) { index, log in
                                    Text(log)
                                        .font(.system(.caption, design: .monospaced))
                                        .id(index)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .onChange(of: automation.automationLog.count) { _ in
                            withAnimation {
                                proxy.scrollTo(automation.automationLog.count - 1, anchor: .bottom)
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
                .padding()
                
                Spacer()
            }
        }
        .navigationTitle("iPhone Automation")
        .onAppear {
            _ = automation.detectiPhoneMirroring()
        }
    }
    
    private func executeHome() {
        automation.pressHome()
    }
    
    private func executeAppSwitcher() {
        automation.openAppSwitcher()
    }
    
    private func captureScreenshot() {
        // Find iPhone Mirroring app
        if let app = screenshotManager.runningApps.first(where: { 
            $0.name.contains("iPhone") || $0.bundleIdentifier?.contains("ScreenContinuity") == true 
        }) {
            let scenario = TestScenario(
                name: "iPhone Screenshot",
                description: "Captured from iPhone",
                deviceType: .iPhone,
                delayBeforeCapture: 0.5,
                actions: []
            )
            
            screenshotManager.captureScreenshot(of: app, scenario: scenario) { result in
                switch result {
                case .success:
                    print("✅ iPhone screenshot captured")
                case .failure(let error):
                    print("❌ Failed to capture: \(error)")
                }
            }
        }
    }
    
    private func executeCustomTap() {
        guard let x = Double(customX),
              let y = Double(customY),
              let windowBounds = automation.getiPhoneMirroringWindow() else { return }
        
        automation.tapAt(x: x, y: y, in: windowBounds)
    }
    
    private func executeTypeText() {
        automation.typeText(customText)
        customText = ""
    }
    
    private func executeSwipe(direction: SwipeDirection) {
        guard let windowBounds = automation.getiPhoneMirroringWindow() else { return }
        
        let centerX = windowBounds.width / 2
        let centerY = windowBounds.height / 2
        
        switch direction {
        case .up:
            automation.swipe(
                from: CGPoint(x: centerX, y: centerY + 100),
                to: CGPoint(x: centerX, y: centerY - 100),
                in: windowBounds
            )
        case .down:
            automation.swipe(
                from: CGPoint(x: centerX, y: centerY - 100),
                to: CGPoint(x: centerX, y: centerY + 100),
                in: windowBounds
            )
        case .left:
            automation.swipe(
                from: CGPoint(x: centerX + 100, y: centerY),
                to: CGPoint(x: centerX - 100, y: centerY),
                in: windowBounds
            )
        case .right:
            automation.swipe(
                from: CGPoint(x: centerX - 100, y: centerY),
                to: CGPoint(x: centerX + 100, y: centerY),
                in: windowBounds
            )
        }
    }
    
    private func runScenario(_ scenario: iPhoneTestScenario) {
        guard let windowBounds = automation.getiPhoneMirroringWindow() else { return }
        
        isRunning = true
        
        Task {
            for action in scenario.actions {
                switch action {
                case .tap(let x, let y):
                    automation.tapAt(x: x, y: y, in: windowBounds)
                case .swipe(let from, let to):
                    automation.swipe(from: from, to: to, in: windowBounds)
                case .typeText(let text):
                    automation.typeText(text)
                case .pressHome:
                    automation.pressHome()
                case .appSwitcher:
                    automation.openAppSwitcher()
                case .wait(let duration):
                    try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                case .screenshot:
                    captureScreenshot()
                }
                
                // Delay between actions
                try? await Task.sleep(nanoseconds: UInt64(scenario.delayBetweenActions * 1_000_000_000))
            }
            
            await MainActor.run {
                isRunning = false
            }
        }
    }
    
    enum SwipeDirection {
        case up, down, left, right
    }
}