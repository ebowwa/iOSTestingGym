//
//  iPhoneAutomationView.swift
//  iosAppTester
//
//  UI for iPhone automation via iPhone Mirroring
//

import SwiftUI

struct iPhoneAutomationView: View {
    @ObservedObject var automation: iPhoneAutomation
    @ObservedObject var screenshotManager: ScreenshotManager
    @StateObject private var focusManager = AppFocusManager.shared
    
    init(screenshotManager: ScreenshotManager, automation: iPhoneAutomation? = nil) {
        self.screenshotManager = screenshotManager
        self.automation = automation ?? iPhoneAutomation()
    }
    @State private var selectedScenario: iPhoneTestScenario?
    @State private var isRunning = false
    @State private var customX: String = "200"
    @State private var customY: String = "400"
    @State private var customText: String = ""
    @State private var savedCursorPosition: CGPoint? = nil
    
    // Disclosure Group expansion states
    @State private var statusExpanded = true
    @State private var quickActionsExpanded = false
    @State private var touchpadExpanded = false
    @State private var scenariosExpanded = false
    @State private var customControlsExpanded = false
    @State private var automationLogExpanded = false
    
    var body: some View {
        NavigationView {
            // Sidebar
            List {
                // Permission Status
                if !automation.hasAccessibilityPermission && automation.permissionCheckComplete {
                    Section("⚠️ Permission Required") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Accessibility permission is required for automation")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Button("Grant Permission") {
                                automation.requestAccessibilityPermission()
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Text("After granting, restart the app")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                DisclosureGroup("Status", isExpanded: $statusExpanded) {
                    // App Focus Status
                    HStack {
                        Circle()
                            .fill(focusManager.canAcceptInput ? Color.green : Color.orange)
                            .frame(width: 10, height: 10)
                        Text(focusManager.canAcceptInput ? "App Focused" : "App Not Focused")
                        Spacer()
                    }
                    
                    // Accessibility Permission
                    HStack {
                        Circle()
                            .fill(automation.hasAccessibilityPermission ? Color.green : Color.orange)
                            .frame(width: 10, height: 10)
                        Text(automation.hasAccessibilityPermission ? "Accessibility Granted" : "Accessibility Required")
                        Spacer()
                        if !automation.hasAccessibilityPermission {
                            Button("Grant") {
                                automation.requestAccessibilityPermission()
                            }
                            .font(.caption)
                        }
                    }
                    
                    // iPhone Connection
                    HStack {
                        Circle()
                            .fill(automation.isConnected ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        Text(automation.isConnected ? "iPhone Connected" : "iPhone Not Connected")
                        Spacer()
                        Button("Refresh") {
                            automation.checkAccessibilityPermission()
                            _ = automation.detectiPhoneMirroring()
                        }
                    }
                    
                    // Connection Quality
                    if automation.isConnected {
                        HStack {
                            Text("\(automation.connectionQuality.color)")
                                .font(.system(size: 14))
                            Text("Connection: \(automation.connectionQuality.rawValue)")
                                .font(.caption)
                                .foregroundColor(connectionQualityColor(for: automation.connectionQuality))
                            if automation.lastResponseTime > 0 {
                                Text("(\(Int(automation.lastResponseTime))ms)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Test") {
                                automation.testConnectionQuality()
                            }
                            .font(.caption)
                        }
                    }
                    
                    if automation.isConnected {
                        Label(automation.deviceName, systemImage: "iphone")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
                
                QuickActionsView(
                    automation: automation,
                    screenshotManager: screenshotManager,
                    isExpanded: $quickActionsExpanded
                )
                .padding(.vertical, 4)
                
                DisclosureGroup("Touchpad Control", isExpanded: $touchpadExpanded) {
                    TouchpadView(automation: automation, isExpanded: $touchpadExpanded)
                        .frame(height: 300)
                        .padding(.vertical, 4)
                }
                .padding(.vertical, 4)
                
                DisclosureGroup("Test Scenarios", isExpanded: $scenariosExpanded) {
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
                        .disabled(!automation.isConnected || !automation.hasAccessibilityPermission || isRunning || !focusManager.canAcceptInput)
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 250)
            
            // Main Content
            VStack {
                // Custom Controls
                DisclosureGroup("Custom Controls", isExpanded: $customControlsExpanded) {
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
                            .disabled(!automation.isConnected || !automation.hasAccessibilityPermission || !focusManager.canAcceptInput)
                        }
                        
                        HStack {
                            Text("Type Text:")
                            TextField("Enter text...", text: $customText)
                            Button("Type") {
                                executeTypeText()
                            }
                            .disabled(!automation.isConnected || customText.isEmpty || !automation.hasAccessibilityPermission || !focusManager.canAcceptInput)
                            
                            Button("Paste") {
                                executePasteText()
                            }
                            .disabled(!automation.isConnected || customText.isEmpty || !automation.hasAccessibilityPermission || !focusManager.canAcceptInput)
                        }
                        
                        VStack(spacing: 10) {
                            // Directional controls with center click
                            HStack {
                                Text("Controls:")
                                Spacer()
                            }
                            
                            HStack(spacing: 20) {
                                // Left side - swipe controls
                                VStack(spacing: 5) {
                                    Button("↑") {
                                        executeSwipe(direction: .up)
                                    }
                                    .frame(width: 40, height: 30)
                                    
                                    HStack(spacing: 5) {
                                        Button("←") {
                                            executeSwipe(direction: .left)
                                        }
                                        .frame(width: 40, height: 30)
                                        
                                        Button("Click") {
                                            executeClickAtCenter()
                                        }
                                        .frame(width: 50, height: 30)
                                        .buttonStyle(.borderedProminent)
                                        
                                        Button("→") {
                                            executeSwipe(direction: .right)
                                        }
                                        .frame(width: 40, height: 30)
                                    }
                                    
                                    Button("↓") {
                                        executeSwipe(direction: .down)
                                    }
                                    .frame(width: 40, height: 30)
                                }
                                
                                Spacer()
                            }
                        }
                        .disabled(!automation.isConnected || !automation.hasAccessibilityPermission || !focusManager.canAcceptInput)
                    }
                    .padding()
                }
                .padding()
                
                // Automation Log
                DisclosureGroup("Automation Log", isExpanded: $automationLogExpanded) {
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
                        .onChange(of: automation.automationLog.count) {
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
            automation.checkAccessibilityPermission()
            _ = automation.detectiPhoneMirroring()
            
            // Set up timer to check permission status
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                automation.checkAccessibilityPermission()
            }
            
            // Set up timer to check connection quality less frequently
            Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
                if automation.isConnected {
                    automation.testConnectionQuality()
                }
            }
        }
    }
    
    private func connectionQualityColor(for quality: iPhoneAutomation.ConnectionQuality) -> Color {
        switch quality {
        case .excellent, .good:
            return .green
        case .fair:
            return .yellow
        case .poor:
            return .orange
        case .bad, .disconnected:
            return .red
        case .unknown:
            return .gray
        }
    }
    
    private func executeCustomTap() {
        guard let x = Double(customX),
              let y = Double(customY),
              let windowBounds = automation.getiPhoneMirroringWindow() else { return }
        
        automation.tapAt(x: x, y: y, in: windowBounds)
    }
    
    private func executeClickAtCenter() {
        guard let windowBounds = automation.getiPhoneMirroringWindow() else { return }
        
        // Click at the center of the iPhone screen
        let centerX = windowBounds.width / 2
        let centerY = windowBounds.height / 2
        
        automation.tapAt(x: centerX, y: centerY, in: windowBounds)
    }
    
    private func executeTypeText() {
        _ = automation.typeText(customText)
        customText = ""
    }
    
    private func executePasteText() {
        _ = automation.pasteText(customText)
        customText = ""
    }
    
    private func executeSwipe(direction: SwipeDirection) {
        guard let windowBounds = automation.getiPhoneMirroringWindow() else { return }
        
        let centerX = windowBounds.width / 2
        let centerY = windowBounds.height / 2
        
        // Save current cursor position if we have touchpad view's position
        // For now, we'll just perform the swipe from center
        
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
        
        // Return cursor to center after swipe
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let moveEvent = CGEvent(
                mouseEventSource: nil,
                mouseType: .mouseMoved,
                mouseCursorPosition: CGPoint(x: windowBounds.origin.x + centerX, y: windowBounds.origin.y + centerY),
                mouseButton: .left
            ) {
                if let windowInfo = WindowDetector.getiPhoneMirroringWindow() {
                    moveEvent.postToPid(windowInfo.processID)
                }
            }
        }
    }
    
    private func runScenario(_ scenario: iPhoneTestScenario) {
        guard let windowBounds = automation.getiPhoneMirroringWindow() else { return }
        
        isRunning = true
        
        // Ensure window is focused before starting the scenario
        automation.ensureWindowFocused()
        
        Task {
            for action in scenario.actions {
                switch action {
                case .tap(let x, let y):
                    automation.tapAt(x: x, y: y, in: windowBounds)
                case .swipe(let from, let to):
                    automation.swipe(from: from, to: to, in: windowBounds)
                case .typeText(let text):
                    _ = automation.typeText(text)
                case .pasteText(let text):
                    _ = automation.pasteText(text)
                case .pressHome:
                    _ = automation.pressHome()
                case .openAppSwitcher:
                    _ = automation.openAppSwitcher()
                case .wait(let duration):
                    try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                case .screenshot:
                    let context = DefaultQuickActionContext(
                        automation: automation,
                        screenshotManager: screenshotManager,
                        focusManager: focusManager
                    )
                    let screenshotAction = ScreenshotAction(context: context)
                    screenshotAction.execute()
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