//
//  ScreenshotsView.swift
//  iosAppTester
//
//  Created by Elijah Arbee on 8/29/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ScreenshotsView: View {
    @ObservedObject var screenshotManager: ScreenshotManager
    @State private var selectedScreenshots = Set<Screenshot.ID>()
    @State private var exportFormat = ExportFormat.organized
    @State private var showingExporter = false
    @State private var groupBy = GroupingOption.locale
    @State private var searchText = ""
    
    enum GroupingOption: String, CaseIterable {
        case none = "None"
        case locale = "Language"
        case scenario = "Scenario"
        case device = "Device"
    }
    
    var groupedScreenshots: [(key: String, screenshots: [Screenshot])] {
        let filtered = screenshotManager.screenshots.filter { screenshot in
            searchText.isEmpty ||
            screenshot.appName.localizedCaseInsensitiveContains(searchText) ||
            screenshot.scenario.name.localizedCaseInsensitiveContains(searchText) ||
            screenshot.locale.displayName.localizedCaseInsensitiveContains(searchText)
        }
        
        switch groupBy {
        case .none:
            return [(key: "All Screenshots", screenshots: filtered)]
        case .locale:
            let grouped = Dictionary(grouping: filtered) { $0.locale.displayName }
            return grouped.sorted { $0.key < $1.key }.map { (key: $0.key, screenshots: $0.value) }
        case .scenario:
            let grouped = Dictionary(grouping: filtered) { $0.scenario.name }
            return grouped.sorted { $0.key < $1.key }.map { (key: $0.key, screenshots: $0.value) }
        case .device:
            let grouped = Dictionary(grouping: filtered) { $0.deviceType.rawValue }
            return grouped.sorted { $0.key < $1.key }.map { (key: $0.key, screenshots: $0.value) }
        }
    }
    
    var body: some View {
        NavigationView {
            if screenshotManager.screenshots.isEmpty {
                ContentUnavailableView(
                    "No Screenshots",
                    systemImage: "photo.stack",
                    description: Text("Capture screenshots from the Apps tab to see them here")
                )
            } else {
                VStack {
                    // Toolbar
                    HStack {
                        Text("\(screenshotManager.screenshots.count) screenshots")
                            .font(.headline)
                        
                        Button(action: { 
                            // Force refresh
                            print("🔄 Force refresh - Screenshots count: \(screenshotManager.screenshots.count)")
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .help("Refresh")
                        
                        Spacer()
                        
                        Picker("Group by", selection: $groupBy) {
                            ForEach(GroupingOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 300)
                        
                        Button(action: { showingExporter = true }) {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        .disabled(screenshotManager.screenshots.isEmpty)
                        
                        Button(action: { screenshotManager.clearAllScreenshots() }) {
                            Label("Clear All", systemImage: "trash")
                        }
                        .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    
                    // Screenshots Grid
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(groupedScreenshots, id: \.key) { group in
                                if groupBy != .none {
                                    Text(group.key)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal)
                                }
                                
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16)
                                ], spacing: 16) {
                                    ForEach(group.screenshots) { screenshot in
                                        ScreenshotCard(
                                            screenshot: screenshot,
                                            isSelected: selectedScreenshots.contains(screenshot.id),
                                            onDelete: { screenshotManager.deleteScreenshot(screenshot) }
                                        )
                                        .onTapGesture {
                                            toggleSelection(screenshot.id)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                .searchable(text: $searchText, prompt: "Search screenshots")
                .sheet(isPresented: $showingExporter) {
                    ExportView(
                        screenshotManager: screenshotManager,
                        exportFormat: $exportFormat
                    )
                }
            }
        }
        .navigationTitle("Screenshots")
    }
    
    private func toggleSelection(_ id: Screenshot.ID) {
        if selectedScreenshots.contains(id) {
            selectedScreenshots.remove(id)
        } else {
            selectedScreenshots.insert(id)
        }
    }
}

struct ScreenshotCard: View {
    let screenshot: Screenshot
    let isSelected: Bool
    let onDelete: () -> Void
    
    @State private var isHovering = false
    @State private var showingPreview = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Screenshot Image
            ZStack(alignment: .topTrailing) {
                Image(nsImage: screenshot.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 150)
                    .frame(maxWidth: 280)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                    )
                    .onTapGesture(count: 2) {
                        showingPreview = true
                    }
                
                if isHovering {
                    Button(action: onDelete) {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.red)
                            .background(Circle().fill(Color.white))
                            .imageScale(.large)
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                }
            }
            
            // Metadata
            VStack(alignment: .leading, spacing: 4) {
                Text(screenshot.scenario.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text(screenshot.locale.flag)
                    Text(screenshot.locale.code)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label(screenshot.deviceType.rawValue, systemImage: deviceIcon(for: screenshot.deviceType))
                        .font(.caption2)
                    
                    Spacer()
                    
                    Text(screenshot.fileSize)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
        .onHover { hovering in
            isHovering = hovering
        }
        .help("Double-click to preview")
        .sheet(isPresented: $showingPreview) {
            ScreenshotPreviewView(screenshot: screenshot)
        }
    }
    
    private func deviceIcon(for deviceType: DeviceType) -> String {
        switch deviceType {
        case .iPhone: return "iphone"
        case .iPad: return "ipad"
        case .mac: return "macbook"
        case .appleWatch: return "applewatch"
        case .appleTV: return "appletv"
        case .visionPro: return "visionpro"
        }
    }
}

struct ScreenshotPreviewView: View {
    let screenshot: Screenshot
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                VStack(alignment: .leading) {
                    Text(screenshot.scenario.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("\(screenshot.appName) • \(Int(screenshot.resolution.width))×\(Int(screenshot.resolution.height))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: { saveToFile() }) {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    
                    Button(action: { copyToClipboard() }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Screenshot Image
            ScrollView([.horizontal, .vertical]) {
                Image(nsImage: screenshot.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            .background(Color.black.opacity(0.1))
        }
        .frame(minWidth: 600, minHeight: 400)
    }
    
    private func saveToFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "\(screenshot.appName)_\(screenshot.scenario.name).png"
        
        if panel.runModal() == .OK, let url = panel.url {
            if let tiffData = screenshot.image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                try? pngData.write(to: url)
            }
        }
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([screenshot.image])
    }
}

struct ExportView: View {
    @ObservedObject var screenshotManager: ScreenshotManager
    @Binding var exportFormat: ExportFormat
    @Environment(\.dismiss) var dismiss
    @State private var exportURL: URL?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export Screenshots")
                .font(.title)
                .fontWeight(.bold)
            
            Picker("Export Format", selection: $exportFormat) {
                Text("Organized (App/Locale/Device)").tag(ExportFormat.organized)
                Text("Flat (All in one folder)").tag(ExportFormat.flat)
                Text("App Store Connect").tag(ExportFormat.appStore)
            }
            .pickerStyle(.radioGroup)
            
            Text("\(screenshotManager.screenshots.count) screenshots will be exported")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Choose Location") {
                    chooseExportLocation()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
        .frame(width: 400)
    }
    
    private func chooseExportLocation() {
        let panel = NSOpenPanel()
        panel.title = "Choose Export Location"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            screenshotManager.exportScreenshots(to: url, format: exportFormat)
            dismiss()
            
            // Show success notification
            NSWorkspace.shared.open(url)
        }
    }
}