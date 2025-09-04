//
//  AppsView.swift
//  iosAppTester
//
//  Created by Elijah Arbee on 8/29/25.
//

import SwiftUI
import AppKit

struct AppsView: View {
    @ObservedObject var screenshotManager: ScreenshotManager
    @State private var searchText = ""
    @State private var showingCaptureSheet = false
    
    var filteredApps: [RunningApp] {
        if searchText.isEmpty {
            return screenshotManager.runningApps
        } else {
            return screenshotManager.runningApps.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) 
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(filteredApps, selection: $screenshotManager.selectedApp) { app in
                AppRowView(app: app)
                    .tag(app)
            }
            .searchable(text: $searchText, prompt: "Search apps")
            .navigationTitle("Running Apps")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: screenshotManager.refreshRunningApps) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
        } detail: {
            if let selectedApp = screenshotManager.selectedApp {
                AppDetailView(
                    app: selectedApp,
                    screenshotManager: screenshotManager,
                    showingCaptureSheet: $showingCaptureSheet
                )
            } else {
                ContentUnavailableView(
                    "Select an App",
                    systemImage: "apps.iphone",
                    description: Text("Choose an app from the list to start capturing screenshots")
                )
            }
        }
        .sheet(isPresented: $showingCaptureSheet) {
            CaptureProgressView(screenshotManager: screenshotManager)
        }
    }
}

struct AppRowView: View {
    let app: RunningApp
    
    var body: some View {
        HStack {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
                    .cornerRadius(6)
            } else {
                Image(systemName: "app")
                    .frame(width: 32, height: 32)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading) {
                Text(app.name)
                    .font(.headline)
                if let bundleId = app.bundleIdentifier {
                    Text(bundleId)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AppDetailView: View {
    let app: RunningApp
    @ObservedObject var screenshotManager: ScreenshotManager
    @Binding var showingCaptureSheet: Bool
    @StateObject private var scenarioManager = TestScenarioManager()
    
    var body: some View {
        VStack(spacing: 20) {
            // Permission Warning
            if !screenshotManager.hasScreenRecordingPermission && screenshotManager.permissionCheckComplete {
                VStack(spacing: 10) {
                    Label("Screen Recording Permission Required", systemImage: "exclamationmark.shield.fill")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text("This app needs screen recording permission to capture screenshots.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    
                    Button("Open System Settings") {
                        screenshotManager.requestScreenRecordingPermission()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
                .padding()
            }
            // App Info Header
            VStack(spacing: 12) {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 128, height: 128)
                        .cornerRadius(20)
                }
                
                Text(app.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if let bundleId = app.bundleIdentifier {
                    Text(bundleId)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Divider()
            
            // Quick Stats
            HStack(spacing: 40) {
                VStack {
                    Text("\(scenarioManager.allEnabledScenarios.count)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Scenarios")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(screenshotManager.screenshots.filter { $0.appName == app.name }.count)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    Text("Captured")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // Capture Button
            Button(action: startCapture) {
                Label("Start Capture", systemImage: "camera.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(screenshotManager.isCapturing || 
                     scenarioManager.allEnabledScenarios.isEmpty ||
                     !screenshotManager.hasScreenRecordingPermission)
            .padding(.horizontal)
            
            if scenarioManager.allEnabledScenarios.isEmpty {
                Label("Please enable at least one scenario", systemImage: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(app.name)
    }
    
    private func startCapture() {
        showingCaptureSheet = true
        screenshotManager.captureAllScreenshots(
            for: app,
            scenarios: scenarioManager.allEnabledScenarios
        )
    }
}

struct CaptureProgressView: View {
    @ObservedObject var screenshotManager: ScreenshotManager
    @Environment(\.dismiss) var dismiss
    @State private var latestScreenshot: Screenshot?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Capturing Screenshots")
                .font(.title)
                .fontWeight(.bold)
            
            ProgressView(value: screenshotManager.captureProgress)
                .progressViewStyle(.linear)
                .frame(width: 300)
            
            Text("\(Int(screenshotManager.captureProgress * 100))%")
                .font(.title2)
                .monospacedDigit()
            
            // Show last captured screenshot
            if let latest = screenshotManager.screenshots.last {
                VStack {
                    Text("Last captured:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Image(nsImage: latest.image)
                        .renderingMode(.original)  // Prevents blank images on macOS
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 150)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    
                    Text(latest.scenario.name)
                        .font(.caption)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            
            if !screenshotManager.captureErrors.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(screenshotManager.captureErrors, id: \.self) { error in
                            Label(error, systemImage: "exclamationmark.triangle")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                .frame(maxHeight: 200)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            HStack {
                if !screenshotManager.isCapturing && !screenshotManager.screenshots.isEmpty {
                    Button("View Screenshots") {
                        dismiss()
                        // User should navigate to Screenshots tab
                    }
                }
                
                Button("Done") {
                    dismiss()
                }
                .disabled(screenshotManager.isCapturing)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
        .frame(minWidth: 400)
    }
}