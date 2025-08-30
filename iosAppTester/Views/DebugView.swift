//
//  DebugView.swift
//  iosAppTester
//
//  Debug view to check screenshot manager state
//

import SwiftUI

struct DebugView: View {
    @ObservedObject var screenshotManager: ScreenshotManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Debug Information")
                .font(.title)
                .fontWeight(.bold)
            
            Group {
                Text("Screenshot Count: \(screenshotManager.screenshots.count)")
                Text("Is Capturing: \(screenshotManager.isCapturing ? "Yes" : "No")")
                Text("Has Permission: \(screenshotManager.hasScreenRecordingPermission ? "Yes" : "No")")
                Text("Permission Check Complete: \(screenshotManager.permissionCheckComplete ? "Yes" : "No")")
                Text("Capture Progress: \(Int(screenshotManager.captureProgress * 100))%")
            }
            .font(.system(.body, design: .monospaced))
            
            if !screenshotManager.captureErrors.isEmpty {
                Text("Errors:")
                    .font(.headline)
                ForEach(screenshotManager.captureErrors, id: \.self) { error in
                    Text("• \(error)")
                        .foregroundColor(.red)
                }
            }
            
            if !screenshotManager.screenshots.isEmpty {
                Text("Screenshots:")
                    .font(.headline)
                ScrollView {
                    ForEach(screenshotManager.screenshots) { screenshot in
                        HStack {
                            Image(nsImage: screenshot.image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 60)
                                .border(Color.gray)
                            
                            VStack(alignment: .leading) {
                                Text(screenshot.appName)
                                    .font(.caption)
                                Text(screenshot.scenario.name)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .frame(maxHeight: 300)
            }
            
            Spacer()
            
            Button("Test Add Fake Screenshot") {
                addTestScreenshot()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(minWidth: 400)
    }
    
    private func addTestScreenshot() {
        // Create a simple test image
        let image = NSImage(size: NSSize(width: 200, height: 100))
        image.lockFocus()
        NSColor.blue.set()
        NSBezierPath.fill(NSRect(x: 0, y: 0, width: 200, height: 100))
        NSColor.white.set()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 20),
            .foregroundColor: NSColor.white
        ]
        let text = "Test Screenshot"
        let textSize = text.size(withAttributes: attributes)
        let textRect = NSRect(
            x: (200 - textSize.width) / 2,
            y: (100 - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: textRect, withAttributes: attributes)
        image.unlockFocus()
        
        let screenshot = Screenshot(
            id: UUID(),
            image: image,
            locale: LocaleInfo.current,
            scenario: TestScenario(
                name: "Test",
                description: "Test screenshot",
                deviceType: .mac,
                delayBeforeCapture: 0,
                actions: []
            ),
            appName: "Test App",
            bundleId: "com.test.app",
            timestamp: Date(),
            deviceType: .mac,
            resolution: CGSize(width: 200, height: 100)
        )
        
        screenshotManager.screenshots.append(screenshot)
        print("Added test screenshot. Total count: \(screenshotManager.screenshots.count)")
    }
}