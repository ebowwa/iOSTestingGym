import Foundation

// Check where recordings would be saved
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let filePath = documentsPath.appendingPathComponent("recordings.json")

print("Documents path: \(documentsPath.path)")
print("Recordings file path: \(filePath.path)")
print("File exists: \(FileManager.default.fileExists(atPath: filePath.path))")

// Try to read the file
if FileManager.default.fileExists(atPath: filePath.path) {
    do {
        let data = try Data(contentsOf: filePath)
        print("File size: \(data.count) bytes")
        
        // Try to decode as dictionary to see structure
        if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            print("Found \(json.count) recordings")
            if let first = json.first {
                print("First recording keys: \(first.keys.sorted())")
            }
        }
    } catch {
        print("Error reading file: \(error)")
    }
}

// Check for app sandbox
if documentsPath.path.contains("Containers") {
    print("App is sandboxed")
} else {
    print("App is not sandboxed")
}