//
//  PersistenceController.swift
//  iosAppTester
//
//  Simplified Core Data stack for recordings
//

import CoreData
import Foundation

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        // Create the model programmatically
        let model = NSManagedObjectModel()
        
        // Create RecordingEntity
        let recordingEntity = NSEntityDescription()
        recordingEntity.name = "RecordingEntity"
        recordingEntity.managedObjectClassName = NSStringFromClass(RecordingEntity.self)
        
        // Add attributes
        let attributes: [(String, NSAttributeType)] = [
            ("id", .UUIDAttributeType),
            ("name", .stringAttributeType),
            ("actionsData", .binaryDataAttributeType),
            ("windowBoundsData", .binaryDataAttributeType),
            ("recordedAt", .dateAttributeType),
            ("annotationsData", .binaryDataAttributeType),
            ("screenshotIdsData", .binaryDataAttributeType),
            ("localeCode", .stringAttributeType),
            ("localeDisplayName", .stringAttributeType),
            ("localeFlag", .stringAttributeType)
        ]
        
        var properties: [NSAttributeDescription] = []
        for (name, type) in attributes {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = true // Make all optional for flexibility
            properties.append(attribute)
        }
        
        recordingEntity.properties = properties
        model.entities = [recordingEntity]
        
        // Create container with the model
        container = NSPersistentContainer(name: "RecordingsModel", managedObjectModel: model)
        
        // Configure persistent store
        let storeURL = applicationDocumentsDirectory().appendingPathComponent("Recordings.sqlite")
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.shouldInferMappingModelAutomatically = true
        
        container.persistentStoreDescriptions = [storeDescription]
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("❌ Core Data failed to load: \(error.localizedDescription)")
            } else {
                print("✅ Core Data loaded successfully")
                print("📁 Store location: \(description.url?.path ?? "unknown")")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    private func applicationDocumentsDirectory() -> URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ Failed to save context: \(error)")
            }
        }
    }
}

// MARK: - Managed Object Subclass

@objc(RecordingEntity)
public class RecordingEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var actionsData: Data?
    @NSManaged public var windowBoundsData: Data?
    @NSManaged public var recordedAt: Date?
    @NSManaged public var annotationsData: Data?
    @NSManaged public var screenshotIdsData: Data?
    @NSManaged public var localeCode: String?
    @NSManaged public var localeDisplayName: String?
    @NSManaged public var localeFlag: String?
}

extension RecordingEntity {
    static func fetchRequest() -> NSFetchRequest<RecordingEntity> {
        return NSFetchRequest<RecordingEntity>(entityName: "RecordingEntity")
    }
}