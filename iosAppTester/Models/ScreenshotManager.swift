//
//  ScreenshotManager.swift
//  iosAppTester
//
//  Created by Elijah Arbee on 8/29/25.
//

import SwiftUI
import AppKit
import ScreenCaptureKit

class ScreenshotManager: ObservableObject {
    @Published var screenshots: [Screenshot] = []
    @Published var isCapturing = false
    @Published var captureProgress: Double = 0.0
    @Published var selectedApp: RunningApp?
    @Published var runningApps: [RunningApp] = []
    @Published var captureErrors: [String] = []
    @Published var hasScreenRecordingPermission = false
    @Published var permissionCheckComplete = false
    
    private let workspace = NSWorkspace.shared
    
    // Helper class for tracking capture progress
    private class CaptureProgress {
        var completed = 0
        let queue = DispatchQueue(label: "capture.progress.queue")
        
        func increment() -> Int {
            queue.sync {
                completed += 1
                return completed
            }
        }
    }
    
    init() {
        checkScreenRecordingPermission()
        refreshRunningApps()
    }
    
    func checkScreenRecordingPermission() {
        Task {
            do {
                // Try to get shareable content - this will trigger permission request if needed
                _ = try await SCShareableContent.current
                await MainActor.run {
                    self.hasScreenRecordingPermission = true
                    self.permissionCheckComplete = true
                }
            } catch {
                await MainActor.run {
                    self.hasScreenRecordingPermission = false
                    self.permissionCheckComplete = true
                    self.captureErrors.append("Screen recording permission required. Please grant permission in System Settings > Privacy & Security > Screen Recording")
                }
            }
        }
    }
    
    func requestScreenRecordingPermission() {
        // Open System Settings to Screen Recording
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func refreshRunningApps() {
        runningApps = workspace.runningApplications
            .filter { app in
                app.activationPolicy == .regular && 
                app.localizedName != nil &&
                !app.isTerminated &&
                app.bundleIdentifier != Bundle.main.bundleIdentifier && // Exclude self
                !app.bundleIdentifier!.contains("com.apple.finder") // Exclude Finder
            }
            .map { RunningApp(from: $0) }
            .sorted { $0.name < $1.name }
    }
    
    func captureScreenshot(
        of app: RunningApp,
        scenario: TestScenario,
        completion: @escaping (Result<Screenshot, CaptureError>) -> Void
    ) {
        // Check permissions first
        guard hasScreenRecordingPermission else {
            completion(.failure(.noPermission))
            return
        }
        
        guard let runningApp = workspace.runningApplications.first(where: { 
            $0.processIdentifier == app.processIdentifier 
        }) else {
            completion(.failure(.appNotFound))
            return
        }
        
        // Activate the app
        runningApp.activate()
        
        // Wait for app to come to foreground
        DispatchQueue.main.asyncAfter(deadline: .now() + scenario.delayBeforeCapture) {
            self.performScreenCapture(
                app: app,
                runningApp: runningApp,
                scenario: scenario,
                completion: completion
            )
        }
    }
    
    private func performScreenCapture(
        app: RunningApp,
        runningApp: NSRunningApplication,
        scenario: TestScenario,
        completion: @escaping (Result<Screenshot, CaptureError>) -> Void
    ) {
        Task {
            do {
                // Get available content
                let availableContent = try await SCShareableContent.current
                
                // Find windows for the target app
                let appWindows = availableContent.windows.filter { window in
                    window.owningApplication?.processID == app.processIdentifier
                }
                
                // Filter out tiny windows (like title bars) and find the main window
                let mainWindows = appWindows.filter { window in
                    window.frame.height > 100 && window.frame.width > 100
                }
                
                let window: SCWindow
                let filter: SCContentFilter
                
                if let mainWindow = mainWindows.first {
                    window = mainWindow
                    filter = SCContentFilter(desktopIndependentWindow: window)
                    print("🪟 Found main window: \(window.title ?? "Untitled") - Size: \(window.frame.size)")
                } else if let firstWindow = appWindows.first {
                    // If no main window, try to capture the display area where the app is
                    window = firstWindow
                    
                    // Use display capture with the app's windows
                    if let display = availableContent.displays.first,
                       let scApp = availableContent.applications.first(where: { $0.processID == app.processIdentifier }) {
                        filter = SCContentFilter(
                            display: display,
                            including: [scApp],
                            exceptingWindows: []
                        )
                        print("🖥️ Using display capture for app: \(app.name)")
                    } else {
                        filter = SCContentFilter(desktopIndependentWindow: window)
                        print("🪟 Using small window: \(window.title ?? "Untitled") - Size: \(window.frame.size)")
                    }
                } else {
                    await MainActor.run {
                        completion(.failure(.noWindowFound))
                    }
                    return
                }
                
                let configuration = SCStreamConfiguration()
                
                // Set resolution based on window size or use default for display capture
                if window.frame.height > 100 {
                    configuration.width = Int(window.frame.width * 2) // Retina resolution
                    configuration.height = Int(window.frame.height * 2)
                } else {
                    // Use a reasonable default size
                    configuration.width = 1920
                    configuration.height = 1080
                }
                configuration.scalesToFit = true
                configuration.showsCursor = false
                
                // Capture the window
                let screenshotImage = try await SCScreenshotManager.captureImage(
                    contentFilter: filter,
                    configuration: configuration
                )
                
                // Convert to NSImage
                let nsImage = NSImage(cgImage: screenshotImage, size: NSSize(width: window.frame.width, height: window.frame.height))
                
                let screenshot = Screenshot(
                    id: UUID(),
                    image: nsImage,
                    locale: LocaleInfo.current,
                    scenario: scenario,
                    appName: app.name,
                    bundleId: app.bundleIdentifier ?? "",
                    timestamp: Date(),
                    deviceType: scenario.deviceType,
                    resolution: CGSize(width: window.frame.width, height: window.frame.height)
                )
                
                await MainActor.run {
                    self.screenshots.append(screenshot)
                    print("📸 Screenshot captured: \(screenshot.scenario.name) for \(screenshot.appName)")
                    print("📸 Total screenshots: \(self.screenshots.count)")
                    completion(.success(screenshot))
                }
                
            } catch {
                await MainActor.run {
                    completion(.failure(.captureError))
                }
            }
        }
    }
    
    func captureAllScreenshots(
        for app: RunningApp,
        scenarios: [TestScenario]
    ) {
        isCapturing = true
        captureProgress = 0.0
        captureErrors.removeAll()
        
        let totalCaptures = scenarios.count
        let progress = CaptureProgress()
        
        for (index, scenario) in scenarios.enumerated() {
            let delay = Double(index) * 2.0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.performCapture(
                    app: app,
                    scenario: scenario,
                    progress: progress,
                    totalCaptures: totalCaptures
                )
            }
        }
    }
    
    private func performCapture(
        app: RunningApp,
        scenario: TestScenario,
        progress: CaptureProgress,
        totalCaptures: Int
    ) {
        print("🎯 Starting capture for scenario: \(scenario.name)")
        captureScreenshot(of: app, scenario: scenario) { result in
            let completed = progress.increment()
            
            switch result {
            case .success(let screenshot):
                print("✅ Successfully captured: \(scenario.name)")
                print("   App: \(screenshot.appName)")
                print("   Resolution: \(screenshot.resolution)")
                print("   Total screenshots now: \(self.screenshots.count)")
            case .failure(let error):
                print("❌ Failed to capture \(scenario.name): \(error.localizedDescription)")
                self.captureErrors.append("Failed to capture \(scenario.name): \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                self.updateProgress(completed, total: totalCaptures)
            }
        }
    }
    
    private func updateProgress(_ completed: Int, total: Int) {
        captureProgress = Double(completed) / Double(total)
        
        if completed == total {
            isCapturing = false
        }
    }
    
    
    func exportScreenshots(to url: URL, format: ExportFormat = .organized) {
        let fileManager = FileManager.default
        
        switch format {
        case .organized:
            exportOrganized(to: url, fileManager: fileManager)
        case .flat:
            exportFlat(to: url, fileManager: fileManager)
        case .appStore:
            exportForAppStore(to: url, fileManager: fileManager)
        }
    }
    
    private func exportOrganized(to url: URL, fileManager: FileManager) {
        for screenshot in screenshots {
            let folderPath = url
                .appendingPathComponent(screenshot.appName)
                .appendingPathComponent(screenshot.locale.code)
                .appendingPathComponent(screenshot.deviceType.rawValue)
            
            try? fileManager.createDirectory(at: folderPath, withIntermediateDirectories: true)
            
            let fileName = "\(screenshot.scenario.name)_\(screenshot.locale.code)_\(Int(screenshot.timestamp.timeIntervalSince1970)).png"
            let filePath = folderPath.appendingPathComponent(fileName)
            
            saveImage(screenshot.image, to: filePath)
        }
    }
    
    private func exportFlat(to url: URL, fileManager: FileManager) {
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        
        for screenshot in screenshots {
            let fileName = "\(screenshot.appName)_\(screenshot.scenario.name)_\(screenshot.locale.code)_\(screenshot.deviceType.rawValue).png"
            let filePath = url.appendingPathComponent(fileName)
            
            saveImage(screenshot.image, to: filePath)
        }
    }
    
    private func exportForAppStore(to url: URL, fileManager: FileManager) {
        // Group by locale for App Store Connect upload
        let groupedByLocale = Dictionary(grouping: screenshots) { $0.locale.code }
        
        for (locale, localeScreenshots) in groupedByLocale {
            let localePath = url.appendingPathComponent(locale)
            try? fileManager.createDirectory(at: localePath, withIntermediateDirectories: true)
            
            for (index, screenshot) in localeScreenshots.enumerated() {
                let fileName = String(format: "%02d_%@_%@.png", 
                                    index + 1,
                                    screenshot.deviceType.rawValue.replacingOccurrences(of: " ", with: ""),
                                    screenshot.scenario.name.replacingOccurrences(of: " ", with: "_"))
                let filePath = localePath.appendingPathComponent(fileName)
                
                saveImage(screenshot.image, to: filePath)
            }
        }
    }
    
    private func saveImage(_ image: NSImage, to url: URL) {
        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            try? pngData.write(to: url)
        }
    }
    
    func deleteScreenshot(_ screenshot: Screenshot) {
        screenshots.removeAll { $0.id == screenshot.id }
    }
    
    func clearAllScreenshots() {
        screenshots.removeAll()
    }
}

// MARK: - Supporting Types

struct RunningApp: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String?
    let processIdentifier: pid_t
    let icon: NSImage?
    
    init(from app: NSRunningApplication) {
        self.name = app.localizedName ?? "Unknown"
        self.bundleIdentifier = app.bundleIdentifier
        self.processIdentifier = app.processIdentifier
        self.icon = app.icon
    }
}

struct Screenshot: Identifiable {
    let id: UUID
    let image: NSImage
    let locale: LocaleInfo
    let scenario: TestScenario
    let appName: String
    let bundleId: String
    let timestamp: Date
    let deviceType: DeviceType
    let resolution: CGSize
    
    var fileSize: String {
        if let tiffData = image.tiffRepresentation {
            let bytes = tiffData.count
            let formatter = ByteCountFormatter()
            return formatter.string(fromByteCount: Int64(bytes))
        }
        return "Unknown"
    }
}

enum DeviceType: String, CaseIterable, Codable {
    case iPhone = "iPhone"
    case iPad = "iPad"
    case mac = "Mac"
    case appleWatch = "Apple Watch"
    case appleTV = "Apple TV"
    case visionPro = "Vision Pro"
}

enum CaptureError: LocalizedError {
    case appNotFound
    case windowListError
    case noWindowFound
    case captureError
    case noPermission
    
    var errorDescription: String? {
        switch self {
        case .appNotFound:
            return "Application not found or has terminated"
        case .windowListError:
            return "Failed to get window list"
        case .noWindowFound:
            return "No suitable window found for the application"
        case .captureError:
            return "Failed to capture screenshot"
        case .noPermission:
            return "Screen recording permission required. Grant permission in System Settings > Privacy & Security > Screen Recording"
        }
    }
}

enum ExportFormat {
    case organized  // Organized by app/locale/device
    case flat      // All in one folder
    case appStore  // Formatted for App Store Connect
}