import CoreData
import Foundation
import Combine

@MainActor
class CoreDataService: ObservableObject {
    @MainActor static let shared = CoreDataService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "IAAdvisorDataModel")
        
        container.loadPersistentStores { [weak self] _, error in
            if let error = error as NSError? {
                print("Core Data错误: \(error), \(error.userInfo)")
                Task { @MainActor [weak self] in
                    self?.errorMessage = "数据库加载失败: \(error.localizedDescription)"
                }
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - 初始化
    
    private init() {
        // 预加载数据模型
        _ = persistentContainer
    }
    
    // MARK: - 保存操作
    
    func saveContext() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Core Data保存错误: \(error)")
            errorMessage = "数据保存失败: \(error.localizedDescription)"
        }
    }
    
    func saveContextAsync() async {
        await MainActor.run {
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    print("Core Data保存错误: \(error)")
                    errorMessage = "数据保存失败: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - 案件管理
    
    func createCase(from response: CaseResponse) -> CDCase {
        let cdCase = CDCase(context: context)
        cdCase.id = response.id
        cdCase.title = response.title
        cdCase.caseDescription = response.description
        cdCase.caseType = response.case_type
        cdCase.status = response.status
        cdCase.createdAt = parseDate(response.created_at) ?? Date()
        cdCase.updatedAt = parseDate(response.updated_at) ?? Date()
        cdCase.userId = response.user_id
        
        saveContext()
        return cdCase
    }
    
    func fetchCases(userId: String? = nil) -> [CDCase] {
        let request: NSFetchRequest<CDCase> = CDCase.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDCase.updatedAt, ascending: false)]
        
        if let userId = userId {
            request.predicate = NSPredicate(format: "userId == %@", userId)
        }
        
        do {
            return try context.fetch(request)
        } catch {
            print("获取案件失败: \(error)")
            errorMessage = "获取案件数据失败: \(error.localizedDescription)"
            return []
        }
    }
    
    func updateCase(_ cdCase: CDCase, from response: CaseResponse) {
        cdCase.title = response.title
        cdCase.caseDescription = response.description
        cdCase.caseType = response.case_type
        cdCase.status = response.status
        cdCase.updatedAt = parseDate(response.updated_at) ?? Date()
        
        saveContext()
    }
    
    func deleteCase(_ cdCase: CDCase) {
        // 先删除相关的消息和文档
        if let messages = cdCase.messages {
            for message in messages {
                if let cdMessage = message as? CDMessage {
                    context.delete(cdMessage)
                }
            }
        }
        
        if let documents = cdCase.documents {
            for document in documents {
                if let cdDocument = document as? CDDocument {
                    context.delete(cdDocument)
                }
            }
        }
        
        context.delete(cdCase)
        saveContext()
    }
    
    // MARK: - 消息管理
    
    func createMessage(content: String, isFromAI: Bool, caseId: String) -> CDMessage {
        let cdMessage = CDMessage(context: context)
        cdMessage.id = UUID().uuidString
        cdMessage.content = content
        cdMessage.isFromAI = isFromAI
        cdMessage.createdAt = Date()
        cdMessage.caseId = caseId
        
        // 关联到案件
        if let cdCase = fetchCase(byId: caseId) {
            cdMessage.parentCase = cdCase
        }
        
        saveContext()
        return cdMessage
    }
    
    func fetchMessages(for caseId: String) -> [CDMessage] {
        let request: NSFetchRequest<CDMessage> = CDMessage.fetchRequest()
        request.predicate = NSPredicate(format: "caseId == %@", caseId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMessage.createdAt, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("获取消息失败: \(error)")
            errorMessage = "获取消息数据失败: \(error.localizedDescription)"
            return []
        }
    }
    
    // MARK: - 文档管理
    
    func createDocument(from response: DocumentResponse) -> CDDocument {
        let cdDocument = CDDocument(context: context)
        cdDocument.id = response.id
        cdDocument.caseId = response.case_id
        cdDocument.filename = response.filename
        cdDocument.fileUrl = response.file_url
        cdDocument.fileType = response.file_type
        cdDocument.fileSize = Int64(response.file_size)
        cdDocument.uploadedAt = parseDate(response.uploaded_at) ?? Date()
        
        // 关联到案件
        if let cdCase = fetchCase(byId: response.case_id) {
            cdDocument.parentCase = cdCase
        }
        
        saveContext()
        return cdDocument
    }
    
    func fetchDocuments(for caseId: String? = nil) -> [CDDocument] {
        let request: NSFetchRequest<CDDocument> = CDDocument.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDDocument.uploadedAt, ascending: false)]
        
        if let caseId = caseId {
            request.predicate = NSPredicate(format: "caseId == %@", caseId)
        }
        
        do {
            return try context.fetch(request)
        } catch {
            print("获取文档失败: \(error)")
            errorMessage = "获取文档数据失败: \(error.localizedDescription)"
            return []
        }
    }
    
    func deleteDocument(_ cdDocument: CDDocument) {
        context.delete(cdDocument)
        saveContext()
    }
    
    // MARK: - AI分析结果管理
    
    func createAIAnalysis(from response: AIAnalysisResponse) -> CDAIAnalysis {
        let cdAnalysis = CDAIAnalysis(context: context)
        cdAnalysis.id = response.id
        cdAnalysis.caseId = response.case_id
        cdAnalysis.analysisType = response.analysis_type
        cdAnalysis.result = response.result
        cdAnalysis.confidence = response.confidence ?? 0.0
        cdAnalysis.recommendations = (response.recommendations ?? []).joined(separator: "|||")
        cdAnalysis.createdAt = parseDate(response.created_at) ?? Date()
        
        // 关联到案件
        if let cdCase = fetchCase(byId: response.case_id) {
            cdAnalysis.parentCase = cdCase
        }
        
        saveContext()
        return cdAnalysis
    }
    
    func fetchAIAnalyses(for caseId: String) -> [CDAIAnalysis] {
        let request: NSFetchRequest<CDAIAnalysis> = CDAIAnalysis.fetchRequest()
        request.predicate = NSPredicate(format: "caseId == %@", caseId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDAIAnalysis.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("获取AI分析失败: \(error)")
            errorMessage = "获取AI分析数据失败: \(error.localizedDescription)"
            return []
        }
    }
    
    // MARK: - 辅助方法
    
    private func fetchCase(byId id: String) -> CDCase? {
        let request: NSFetchRequest<CDCase> = CDCase.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("获取案件失败: \(error)")
            return nil
        }
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
    
    // MARK: - 数据同步
    
    func syncWithServer() async {
        await MainActor.run { isLoading = true }
        
        do {
            // 从服务器获取最新案件
            let serverCases = try await APIService.shared.getCases()
            
            await MainActor.run {
                for serverCase in serverCases {
                    if let existingCase = fetchCase(byId: serverCase.id) {
                        // 更新现有案件
                        updateCase(existingCase, from: serverCase)
                    } else {
                        // 创建新案件
                        _ = createCase(from: serverCase)
                    }
                }
            }
            
            // 获取文档
            let serverDocuments = try await APIService.shared.getDocuments()
            await MainActor.run {
                for serverDocument in serverDocuments {
                    if !documentExists(id: serverDocument.id) {
                        _ = createDocument(from: serverDocument)
                    }
                }
            }
            
        } catch {
            print("数据同步失败: \(error)")
            await MainActor.run {
                errorMessage = "数据同步失败: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run { isLoading = false }
    }
    
    private func documentExists(id: String) -> Bool {
        let request: NSFetchRequest<CDDocument> = CDDocument.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            return false
        }
    }
    
    // MARK: - 数据清理
    
    func clearAllData() {
        let entities = ["CDCase", "CDMessage", "CDDocument", "CDAIAnalysis"]
        
        for entityName in entities {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            
            do {
                try persistentContainer.persistentStoreCoordinator.execute(
                    deleteRequest, 
                    with: context
                )
            } catch {
                print("清理\(entityName)数据失败: \(error)")
            }
        }
        
        saveContext()
    }
}

// MARK: - 数据转换扩展

extension CDCase {
    func toCase() -> Case {
        return Case(
            id: self.id ?? UUID().uuidString,
            title: self.title ?? "",
            description: self.caseDescription ?? "",
            createdAt: self.createdAt ?? Date(),
            lastUpdatedAt: self.updatedAt ?? Date(),
            caseType: CaseType(rawValue: self.caseType ?? "") ?? .other,
            status: CaseStatus(rawValue: self.status ?? "") ?? .active,
            messages: self.messages?.compactMap { ($0 as? CDMessage)?.toMessage() } ?? []
        )
    }
}

extension CDMessage {
    func toMessage() -> Message {
        return Message(
            id: self.id ?? UUID().uuidString,
            content: self.content ?? "",
            createdAt: self.createdAt ?? Date(),
            isFromAI: self.isFromAI,
            attachments: nil,
            documentLinks: nil
        )
    }
}

extension CDAIAnalysis {
    var recommendationsArray: [String] {
        return self.recommendations?.components(separatedBy: "|||") ?? []
    }
}