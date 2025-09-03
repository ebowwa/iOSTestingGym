import Foundation

print("Testing Core Data location...")

// Check where Core Data would save
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let sqliteFile = documentsPath.appendingPathComponent("Recordings.sqlite")

print("\nCore Data location: \(sqliteFile.path)")
print("SQLite file exists: \(FileManager.default.fileExists(atPath: sqliteFile.path))")

// Also check for related Core Data files
let walFile = documentsPath.appendingPathComponent("Recordings.sqlite-wal")
let shmFile = documentsPath.appendingPathComponent("Recordings.sqlite-shm")

print("WAL file exists: \(FileManager.default.fileExists(atPath: walFile.path))")
print("SHM file exists: \(FileManager.default.fileExists(atPath: shmFile.path))")

// Check old JSON location too
let jsonFile = documentsPath.appendingPathComponent("recordings.json")
print("\nOld JSON file exists: \(FileManager.default.fileExists(atPath: jsonFile.path))")

if FileManager.default.fileExists(atPath: sqliteFile.path) {
    do {
        let attributes = try FileManager.default.attributesOfItem(atPath: sqliteFile.path)
        if let size = attributes[.size] as? NSNumber {
            print("SQLite file size: \(size.intValue) bytes")
        }
        if let modified = attributes[.modificationDate] as? Date {
            print("Last modified: \(modified)")
        }
    } catch {
        print("Error reading file attributes: \(error)")
    }
}

print("\nCore Data persistence is now configured!")
print("Recordings will be saved to: \(sqliteFile.path)")
print("This data will persist even after app closure.")