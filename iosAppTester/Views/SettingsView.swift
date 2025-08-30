//
//  SettingsView.swift
//  iosAppTester
//
//  Created by Elijah Arbee on 8/29/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("autoRefreshApps") private var autoRefreshApps = true
    @AppStorage("captureDelay") private var captureDelay = 1.5
    @AppStorage("exportQuality") private var exportQuality = 1.0
    @AppStorage("includeMetadata") private var includeMetadata = true
    @AppStorage("useSystemLocale") private var useSystemLocale = false
    @AppStorage("captureRetries") private var captureRetries = 3
    
    var body: some View {
        Form {
            Section("General") {
                Toggle("Auto-refresh running apps", isOn: $autoRefreshApps)
                Toggle("Use system locale for captures", isOn: $useSystemLocale)
                Toggle("Include metadata in exports", isOn: $includeMetadata)
            }
            
            Section("Capture Settings") {
                HStack {
                    Text("Default capture delay")
                    Slider(value: $captureDelay, in: 0.5...5.0, step: 0.5)
                    Text("\(captureDelay, specifier: "%.1f")s")
                        .monospacedDigit()
                        .frame(width: 50)
                }
                
                Stepper("Capture retries: \(captureRetries)", value: $captureRetries, in: 1...5)
            }
            
            Section("Export Settings") {
                HStack {
                    Text("Export quality")
                    Slider(value: $exportQuality, in: 0.5...1.0, step: 0.1)
                    Text("\(Int(exportQuality * 100))%")
                        .monospacedDigit()
                        .frame(width: 50)
                }
            }
            
            Section("About") {
                LabeledContent("Version") {
                    Text("1.0.0")
                }
                
                LabeledContent("Build") {
                    Text("1")
                }
                
                Link("Documentation", destination: URL(string: "https://github.com/yourusername/iosAppTester")!)
                Link("Report Issue", destination: URL(string: "https://github.com/yourusername/iosAppTester/issues")!)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .frame(minWidth: 500)
    }
}