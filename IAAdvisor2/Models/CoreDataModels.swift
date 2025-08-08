import Foundation
import CoreData

// MARK: - Core Data 实体类定义

@objc(CDCase)
public class CDCase: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var caseDescription: String?
    @NSManaged public var caseType: String?
    @NSManaged public var status: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var userId: String?
    @NSManaged public var messages: NSSet?
    @NSManaged public var documents: NSSet?
    @NSManaged public var aiAnalyses: NSSet?
}

// MARK: - CDCase 关系管理

extension CDCase {
    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: CDMessage)
    
    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: CDMessage)
    
    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)
    
    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)
    
    @objc(addDocumentsObject:)
    @NSManaged public func addToDocuments(_ value: CDDocument)
    
    @objc(removeDocumentsObject:)
    @NSManaged public func removeFromDocuments(_ value: CDDocument)
    
    @objc(addDocuments:)
    @NSManaged public func addToDocuments(_ values: NSSet)
    
    @objc(removeDocuments:)
    @NSManaged public func removeFromDocuments(_ values: NSSet)
    
    @objc(addAiAnalysesObject:)
    @NSManaged public func addToAiAnalyses(_ value: CDAIAnalysis)
    
    @objc(removeAiAnalysesObject:)
    @NSManaged public func removeFromAiAnalyses(_ value: CDAIAnalysis)
    
    @objc(addAiAnalyses:)
    @NSManaged public func addToAiAnalyses(_ values: NSSet)
    
    @objc(removeAiAnalyses:)
    @NSManaged public func removeFromAiAnalyses(_ values: NSSet)
}

// MARK: - CDCase FetchRequest

extension CDCase {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDCase> {
        return NSFetchRequest<CDCase>(entityName: "CDCase")
    }
}

@objc(CDMessage)
public class CDMessage: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var content: String?
    @NSManaged public var isFromAI: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var caseId: String?
    @NSManaged public var parentCase: CDCase?
}

extension CDMessage {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDMessage> {
        return NSFetchRequest<CDMessage>(entityName: "CDMessage")
    }
}

@objc(CDDocument)
public class CDDocument: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var caseId: String?
    @NSManaged public var filename: String?
    @NSManaged public var fileUrl: String?
    @NSManaged public var fileType: String?
    @NSManaged public var fileSize: Int64
    @NSManaged public var uploadedAt: Date?
    @NSManaged public var parentCase: CDCase?
}

extension CDDocument {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDDocument> {
        return NSFetchRequest<CDDocument>(entityName: "CDDocument")
    }
}

@objc(CDAIAnalysis)
public class CDAIAnalysis: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var caseId: String?
    @NSManaged public var analysisType: String?
    @NSManaged public var result: String?
    @NSManaged public var confidence: Double
    @NSManaged public var recommendations: String? // 使用分隔符存储数组
    @NSManaged public var createdAt: Date?
    @NSManaged public var parentCase: CDCase?
}

extension CDAIAnalysis {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAIAnalysis> {
        return NSFetchRequest<CDAIAnalysis>(entityName: "CDAIAnalysis")
    }
}

// MARK: - 数据同步状态管理

@objc(CDSyncStatus)
public class CDSyncStatus: NSManagedObject {
    @NSManaged public var entityName: String?
    @NSManaged public var lastSyncDate: Date?
    @NSManaged public var syncVersion: Int32
    @NSManaged public var isFullSyncNeeded: Bool
}

extension CDSyncStatus {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDSyncStatus> {
        return NSFetchRequest<CDSyncStatus>(entityName: "CDSyncStatus")
    }
}

// MARK: - 离线缓存管理

@objc(CDCacheEntry)
public class CDCacheEntry: NSManagedObject {
    @NSManaged public var key: String?
    @NSManaged public var data: Data?
    @NSManaged public var expirationDate: Date?
    @NSManaged public var createdAt: Date?
}

extension CDCacheEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDCacheEntry> {
        return NSFetchRequest<CDCacheEntry>(entityName: "CDCacheEntry")
    }
}

// MARK: - Core Data Stack Helper

class CoreDataStack {
    static let shared = CoreDataStack()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "IAAdvisorDataModel")
        
        // 配置持久化存储
        let description = container.persistentStoreDescriptions.first
        description?.shouldInferMappingModelAutomatically = true
        description?.shouldMigrateStoreAutomatically = true
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    func saveContext() {
        save()
    }
}