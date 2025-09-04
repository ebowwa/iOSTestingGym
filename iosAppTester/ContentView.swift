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
    @StateObject private var automation = iPhoneAutomation()
    @State private var selectedTab = 1
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Apps Tab - Commented out for future macOS automation features
            /*
            AppsView(screenshotManager: screenshotManager)
                .tabItem {
                    Label("Apps", systemImage: "macwindow")
                }
                .tag(0)
            */
            
            // iPhone Automation Tab
            iPhoneAutomationView(screenshotManager: screenshotManager, automation: automation)
                .tabItem {
                    Label("iPhone", systemImage: "iphone")
                }
                .tag(1)
            
            // Screenshots Tab - Commented out due to rendering issues
            /*
            ScreenshotsView(screenshotManager: screenshotManager)
                .tabItem {
                    Label("Screenshots", systemImage: "photo.stack")
                }
                .tag(2)
            */
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)  // Changed from tag(3) to tag(2) since Screenshots is commented out
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}

#Preview {
    ContentView()
}
