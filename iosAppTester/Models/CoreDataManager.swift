//
//  CoreDataManager.swift
//  iosAppTester
//
//  Core Data management for persistent storage
//

import CoreData
import Foundation

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    private let persistenceController = PersistenceController.shared
    
    var context: NSManagedObjectContext {
        return persistenceController.container.viewContext
    }
    
    // MARK: - Recording Operations
    
    func saveRecording(_ recording: ActionRecorder.Recording) throws {
        let entity = RecordingEntity(context: context)
        
        entity.id = recording.id
        entity.name = recording.name
        entity.recordedAt = recording.recordedAt
        
        // Encode complex data as JSON
        entity.actionsData = try JSONEncoder().encode(recording.actions)
        entity.windowBoundsData = try JSONEncoder().encode(recording.windowBounds)
        
        if !recording.annotations.isEmpty {
            entity.annotationsData = try JSONEncoder().encode(recording.annotations)
        }
        
        if let screenshotIds = recording.screenshotIds {
            entity.screenshotIdsData = try JSONEncoder().encode(screenshotIds)
        }
        
        if let locale = recording.locale {
            entity.localeCode = locale.code
            entity.localeDisplayName = locale.displayName
            entity.localeFlag = locale.flag
        }
        
        try save()
        print("💾 Saved recording '\(recording.name)' to Core Data")
    }
    
    func fetchAllRecordings() throws -> [ActionRecorder.Recording] {
        let request: NSFetchRequest<RecordingEntity> = RecordingEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: false)]
        
        let entities = try context.fetch(request)
        print("📂 Fetched \(entities.count) recordings from Core Data")
        
        return try entities.compactMap { entity -> ActionRecorder.Recording? in
            guard let id = entity.id,
                  let name = entity.name,
                  let recordedAt = entity.recordedAt,
                  let actionsData = entity.actionsData,
                  let windowBoundsData = entity.windowBoundsData else {
                return nil
            }
            
            let actions = try JSONDecoder().decode([ActionRecorder.RecordedAction].self, from: actionsData)
            let windowBounds = try JSONDecoder().decode(CGRect.self, from: windowBoundsData)
            
            var annotations: [Int: String] = [:]
            if let annotationsData = entity.annotationsData {
                annotations = try JSONDecoder().decode([Int: String].self, from: annotationsData)
            }
            
            var screenshotIds: [UUID]? = nil
            if let screenshotIdsData = entity.screenshotIdsData {
                screenshotIds = try JSONDecoder().decode([UUID].self, from: screenshotIdsData)
            }
            
            var locale: LocaleInfo? = nil
            if let localeCode = entity.localeCode, 
               let localeDisplayName = entity.localeDisplayName,
               let localeFlag = entity.localeFlag {
                locale = LocaleInfo(code: localeCode, displayName: localeDisplayName, flag: localeFlag)
            }
            
            return ActionRecorder.Recording(
                id: id,
                name: name,
                windowBounds: windowBounds,
                actions: actions,
                recordedAt: recordedAt,
                annotations: annotations,
                screenshotIds: screenshotIds,
                locale: locale
            )
        }
    }
    
    func updateRecording(_ recording: ActionRecorder.Recording) throws {
        let request: NSFetchRequest<RecordingEntity> = RecordingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", recording.id as CVarArg)
        
        let entities = try context.fetch(request)
        
        if let entity = entities.first {
            entity.name = recording.name
            entity.actionsData = try JSONEncoder().encode(recording.actions)
            entity.annotationsData = try JSONEncoder().encode(recording.annotations)
            
            if let screenshotIds = recording.screenshotIds {
                entity.screenshotIdsData = try JSONEncoder().encode(screenshotIds)
            }
            
            if let locale = recording.locale {
                entity.localeCode = locale.code
                entity.localeDisplayName = locale.displayName
                entity.localeFlag = locale.flag
            }
            
            try save()
            print("📝 Updated recording '\(recording.name)' in Core Data")
        }
    }
    
    func deleteRecording(_ recording: ActionRecorder.Recording) throws {
        let request: NSFetchRequest<RecordingEntity> = RecordingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", recording.id as CVarArg)
        
        let entities = try context.fetch(request)
        
        if let entity = entities.first {
            context.delete(entity)
            try save()
            print("🗑️ Deleted recording '\(recording.name)' from Core Data")
        }
    }
    
    func deleteAllRecordings() throws {
        let request: NSFetchRequest<NSFetchRequestResult> = RecordingEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        try context.execute(deleteRequest)
        try save()
        print("🗑️ Deleted all recordings from Core Data")
    }
    
    // MARK: - Migration from JSON
    
    func migrateFromJSON() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsPath.appendingPathComponent("recordings.json")
        
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            print("ℹ️ No JSON file to migrate")
            return
        }
        
        do {
            let data = try Data(contentsOf: filePath)
            let recordings = try JSONDecoder().decode([ActionRecorder.Recording].self, from: data)
            
            print("🔄 Migrating \(recordings.count) recordings from JSON to Core Data...")
            
            for recording in recordings {
                try saveRecording(recording)
            }
            
            // Optionally rename the old file instead of deleting
            let backupPath = filePath.appendingPathExtension("backup")
            try FileManager.default.moveItem(at: filePath, to: backupPath)
            
            print("✅ Migration complete! Old file backed up to: \(backupPath.lastPathComponent)")
        } catch {
            print("⚠️ Migration failed: \(error)")
        }
    }
    
    // MARK: - Private
    
    private func save() throws {
        if context.hasChanges {
            try context.save()
        }
    }
}


