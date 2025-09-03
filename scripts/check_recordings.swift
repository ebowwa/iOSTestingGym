import Foundation

// Check where recordings would be saved
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let filePath = documentsPath.appendingPathComponent("recordings.json")

print("Checking path: \(filePath.path)")

if FileManager.default.fileExists(atPath: filePath.path) {
    do {
        let data = try Data(contentsOf: filePath)
        print("File size: \(data.count) bytes")
        
        // Try to decode as raw JSON to see structure
        if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            print("\nFound \(json.count) recording(s)")
            
            for (index, recording) in json.enumerated() {
                print("\n--- Recording \(index + 1) ---")
                print("Keys: \(recording.keys.sorted())")
                
                if let name = recording["name"] as? String {
                    print("Name: \(name)")
                }
                
                if let actions = recording["actions"] as? [[String: Any]] {
                    print("Actions count: \(actions.count)")
                }
                
                // Check for the new fields we added
                let hasScreenshotIds = recording["screenshotIds"] != nil
                let hasLocale = recording["locale"] != nil
                
                print("Has screenshotIds field: \(hasScreenshotIds)")
                print("Has locale field: \(hasLocale)")
                
                if hasScreenshotIds {
                    if let ids = recording["screenshotIds"] as? [String] {
                        print("  - \(ids.count) screenshot IDs linked")
                    }
                }
                
                if hasLocale {
                    if let locale = recording["locale"] as? [String: Any] {
                        print("  - Locale info: \(locale)")
                    }
                }
            }
        } else {
            print("Could not parse as JSON array")
        }
    } catch {
        print("Error: \(error)")
    }
} else {
    print("No recordings file found at expected location")
    print("\nThis means either:")
    print("1. No recordings have been created yet")
    print("2. Recordings were lost when the app was closed")
    print("3. They're saved in a different location")
}