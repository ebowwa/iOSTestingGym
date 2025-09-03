//
//  RecordingExporter.swift
//  iosAppTester
//
//  Export recordings for use in iOS app
//

import Foundation
import AppKit

class RecordingExporter {
    
    static func exportRecordings(_ recordings: [ActionRecorder.Recording]) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "recordings_export.json"
        savePanel.title = "Export Recordings for iOS"
        savePanel.message = "Save this file to share with the iOS app via AirDrop or iCloud"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                encoder.dateEncodingStrategy = .iso8601
                
                let data = try encoder.encode(recordings)
                try data.write(to: url)
                
                print("✅ Exported \(recordings.count) recordings to: \(url.path)")
                
                // Open in Finder
                NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
                
            } catch {
                print("❌ Failed to export: \(error)")
            }
        }
    }
    
    static func exportToiCloud(_ recordings: [ActionRecorder.Recording]) {
        // Export directly to iCloud Drive if available
        if let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
            let documentsURL = iCloudURL.appendingPathComponent("Documents")
            let exportURL = documentsURL.appendingPathComponent("recordings_\(Date().timeIntervalSince1970).json")
            
            do {
                try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
                
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                encoder.dateEncodingStrategy = .iso8601
                
                let data = try encoder.encode(recordings)
                try data.write(to: exportURL)
                
                print("✅ Exported to iCloud: \(exportURL.path)")
                NSWorkspace.shared.open(documentsURL)
                
            } catch {
                print("❌ Failed to export to iCloud: \(error)")
            }
        } else {
            print("❌ iCloud Drive not available")
            // Fallback to regular export
            exportRecordings(recordings)
        }
    }
}