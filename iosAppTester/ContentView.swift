//
//  ContentView.swift
//  iosAppTester
//
//  Created by Elijah Arbee on 8/29/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var screenshotManager = ScreenshotManager()
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var scenarioManager = TestScenarioManager()
    @StateObject private var automation = iPhoneAutomation()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Apps Tab
            AppsView(screenshotManager: screenshotManager)
                .tabItem {
                    Label("Apps", systemImage: "macwindow")
                }
                .tag(0)
            
            // iPhone Automation Tab
            iPhoneAutomationView(screenshotManager: screenshotManager, automation: automation)
                .tabItem {
                    Label("iPhone", systemImage: "iphone")
                }
                .tag(1)
            
            // Scenarios Tab
            ScenariosView(scenarioManager: scenarioManager)
                .tabItem {
                    Label("Capture Settings", systemImage: "camera.filters")
                }
                .tag(2)
            
            // Screenshots Tab
            ScreenshotsView(screenshotManager: screenshotManager)
                .tabItem {
                    Label("Screenshots", systemImage: "photo.stack")
                }
                .tag(3)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
            
            // Debug Tab
            DebugView(screenshotManager: screenshotManager)
                .tabItem {
                    Label("Debug", systemImage: "ladybug")
                }
                .tag(5)
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}

#Preview {
    ContentView()
}
