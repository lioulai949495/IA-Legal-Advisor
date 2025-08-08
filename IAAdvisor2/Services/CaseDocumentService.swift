import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// 案件文书管理服务
@MainActor
class CaseDocumentService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var documents: [String: [CaseDocument]] = [:] // caseId -> documents
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let apiService = APIService.shared
    
    // MARK: - Singleton
    @MainActor static let shared = CaseDocumentService()
    
    private init() {
        self.documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        setupDocumentsDirectory()
        loadDocuments()
    }
    
    // MARK: - Setup
    private func setupDocumentsDirectory() {
        let caseDocumentsDir = documentsDirectory.appendingPathComponent("CaseDocuments")
        if !fileManager.fileExists(atPath: caseDocumentsDir.path) {
            try? fileManager.createDirectory(at: caseDocumentsDir, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Public Methods
    
    /// 获取指定案件的所有文书
    func getDocuments(for caseId: String) -> [CaseDocument] {
        return documents[caseId] ?? []
    }
    
    /// 获取文书统计信息
    func getDocumentStats(for caseId: String) -> CaseDocumentStats {
        let caseDocuments = getDocuments(for: caseId)
        return caseDocuments.getStats()
    }
    
    /// 上传文档到指定案件
    func uploadDocument(
        to caseId: String,
        name: String,
        type: CaseDocumentType,
        fileURL: URL,
        description: String? = nil,
        tags: [String] = []
    ) async -> DocumentOperationResult {
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 验证文件
            guard fileURL.startAccessingSecurityScopedResource() else {
                return .failure(error: .permissionDenied)
            }
            defer { fileURL.stopAccessingSecurityScopedResource() }
            
            // 检查文件大小（限制50MB）
            let fileSize = try getFileSize(at: fileURL)
            if fileSize > 50 * 1024 * 1024 {
                return .failure(error: .fileSizeTooLarge)
            }
            
            // 创建本地存储路径
            let fileName = name.isEmpty ? fileURL.lastPathComponent : name
            let fileExtension = fileURL.pathExtension
            let localURL = getCaseDocumentsDirectory(for: caseId)
                .appendingPathComponent("\(UUID().uuidString).\(fileExtension)")
            
            // 复制文件到本地
            try fileManager.copyItem(at: fileURL, to: localURL)
            
            // 创建文档记录
            let document = CaseDocument(
                caseId: caseId,
                name: fileName,
                type: type,
                fileExtension: fileExtension,
                filePath: localURL.path,
                fileSize: fileSize,
                createdBy: .user,
                tags: tags,
                description: description
            )
            
            // 保存到内存和持久化存储
            addDocument(document)
            saveDocuments()
            
            // 异步上传到服务器（可选）
            Task {
                await uploadToServer(document: document, fileURL: localURL)
            }
            
            return .success(document: document, message: "文档上传成功")
            
        } catch {
            return .failure(error: .networkError)
        }
    }
    
    /// 创建AI生成的文书
    func createGeneratedDocument(
        for caseId: String,
        name: String,
        type: CaseDocumentType,
        content: String,
        description: String? = nil,
        tags: [String] = []
    ) -> DocumentOperationResult {
        
        // 创建文档记录
        let document = CaseDocument(
            caseId: caseId,
            name: name,
            type: type,
            content: content,
            fileSize: Int64(content.utf8.count),
            createdBy: .ai,
            tags: tags,
            description: description
        )
        
        // 保存到内存和持久化存储
        addDocument(document)
        saveDocuments()
        
        return .success(document: document, message: "文书创建成功")
    }
    
    /// 删除文档
    func deleteDocument(_ documentId: String, from caseId: String) -> DocumentOperationResult {
        guard let documentIndex = documents[caseId]?.firstIndex(where: { $0.id == documentId }),
              let document = documents[caseId]?[documentIndex] else {
            return .failure(error: .fileNotFound)
        }
        
        // 删除本地文件
        if let filePath = document.filePath {
            let fileURL = URL(fileURLWithPath: filePath)
            try? fileManager.removeItem(at: fileURL)
        }
        
        // 从内存中删除
        documents[caseId]?.remove(at: documentIndex)
        saveDocuments()
        
        return .success(document: document, message: "文档删除成功")
    }
    
    /// 下载文档
    func downloadDocument(_ documentId: String, from caseId: String) async -> DocumentOperationResult {
        guard let document = getDocuments(for: caseId).first(where: { $0.id == documentId }) else {
            return .failure(error: .fileNotFound)
        }
        
        if document.isDownloaded, let filePath = document.filePath, fileManager.fileExists(atPath: filePath) {
            return .success(document: document, message: "文档已下载")
        }
        
        // 从服务器下载文档
        // TODO: 实现服务器下载逻辑
        
        return .success(document: document, message: "文档下载成功")
    }
    
    /// 分享文档
    func shareDocument(_ documentId: String, from caseId: String) -> DocumentOperationResult {
        guard let document = getDocuments(for: caseId).first(where: { $0.id == documentId }) else {
            return .failure(error: .fileNotFound)
        }
        
        // 更新分享状态
        updateDocument(documentId, in: caseId) { doc in
            var updatedDoc = doc
            updatedDoc = CaseDocument(
                id: updatedDoc.id,
                caseId: updatedDoc.caseId,
                name: updatedDoc.name,
                type: updatedDoc.type,
                fileExtension: updatedDoc.fileExtension,
                filePath: updatedDoc.filePath,
                content: updatedDoc.content,
                fileSize: updatedDoc.fileSize,
                createdBy: updatedDoc.createdBy,
                tags: updatedDoc.tags,
                description: updatedDoc.description
            )
            return updatedDoc
        }
        
        return .success(document: document, message: "文档分享成功")
    }
    
    /// 搜索和过滤文档
    func searchDocuments(
        in caseId: String,
        filter: DocumentFilter,
        sortBy: DocumentSortOption = .dateUpdated
    ) -> [CaseDocument] {
        
        let allDocs = getDocuments(for: caseId)
        
        // 应用过滤器
        let filteredDocs = allDocs.filter { document in
            // 分类过滤
            if let category = filter.category, document.type.category != category {
                return false
            }
            
            // 类型过滤
            if let type = filter.type, document.type != type {
                return false
            }
            
            // 来源过滤
            if let source = filter.source, document.createdBy != source {
                return false
            }
            
            // 文本搜索
            if !filter.searchText.isEmpty {
                let searchText = filter.searchText.lowercased()
                let nameMatch = document.name.lowercased().contains(searchText)
                let contentMatch = document.content?.lowercased().contains(searchText) ?? false
                let tagMatch = document.tags.contains { $0.lowercased().contains(searchText) }
                
                if !nameMatch && !contentMatch && !tagMatch {
                    return false
                }
            }
            
            // 日期范围过滤
            if let dateRange = filter.dateRange {
                if !dateRange.contains(document.createdAt) {
                    return false
                }
            }
            
            // 标签过滤
            if !filter.tags.isEmpty {
                let hasMatchingTag = filter.tags.contains { filterTag in
                    document.tags.contains { docTag in
                        docTag.lowercased().contains(filterTag.lowercased())
                    }
                }
                if !hasMatchingTag {
                    return false
                }
            }
            
            return true
        }
        
        // 应用排序
        return sortDocuments(filteredDocs, by: sortBy)
    }
    
    // MARK: - Private Helper Methods
    
    private func addDocument(_ document: CaseDocument) {
        if documents[document.caseId] == nil {
            documents[document.caseId] = []
        }
        documents[document.caseId]?.append(document)
    }
    
    private func updateDocument(
        _ documentId: String,
        in caseId: String,
        update: (CaseDocument) -> CaseDocument
    ) {
        guard let index = documents[caseId]?.firstIndex(where: { $0.id == documentId }),
              let document = documents[caseId]?[index] else { return }
        
        documents[caseId]?[index] = update(document)
        saveDocuments()
    }
    
    private func getCaseDocumentsDirectory(for caseId: String) -> URL {
        let caseDir = documentsDirectory
            .appendingPathComponent("CaseDocuments")
            .appendingPathComponent(caseId)
        
        if !fileManager.fileExists(atPath: caseDir.path) {
            try? fileManager.createDirectory(at: caseDir, withIntermediateDirectories: true)
        }
        
        return caseDir
    }
    
    private func getFileSize(at url: URL) throws -> Int64 {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        return attributes[.size] as? Int64 ?? 0
    }
    
    private func sortDocuments(_ documents: [CaseDocument], by sortOption: DocumentSortOption) -> [CaseDocument] {
        switch sortOption {
        case .nameAscending:
            return documents.sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .nameDescending:
            return documents.sorted { $0.name.lowercased() > $1.name.lowercased() }
        case .dateCreated:
            return documents.sorted { $0.createdAt > $1.createdAt }
        case .dateUpdated:
            return documents.sorted { $0.updatedAt > $1.updatedAt }
        case .typeAscending:
            return documents.sorted { $0.type.rawValue < $1.type.rawValue }
        case .sizeAscending:
            return documents.sorted { $0.fileSize < $1.fileSize }
        case .sizeDescending:
            return documents.sorted { $0.fileSize > $1.fileSize }
        }
    }
    
    // MARK: - Persistence
    
    private func saveDocuments() {
        let url = documentsDirectory.appendingPathComponent("case_documents.json")
        
        do {
            let data = try JSONEncoder().encode(documents)
            try data.write(to: url)
        } catch {
            print("Failed to save documents: \(error)")
            errorMessage = "保存文档失败"
        }
    }
    
    private func loadDocuments() {
        let url = documentsDirectory.appendingPathComponent("case_documents.json")
        
        guard fileManager.fileExists(atPath: url.path) else { return }
        
        do {
            let data = try Data(contentsOf: url)
            documents = try JSONDecoder().decode([String: [CaseDocument]].self, from: data)
        } catch {
            print("Failed to load documents: \(error)")
            // 不设置错误消息，因为这是启动时的操作
        }
    }
    
    // MARK: - Server Integration
    
    private func uploadToServer(document: CaseDocument, fileURL: URL) async {
        // TODO: 实现服务器上传逻辑
        print("Uploading document to server: \(document.name)")
    }
}

// MARK: - 便利方法扩展

extension CaseDocumentService {
    /// 批量上传文档
    func uploadDocuments(
        to caseId: String,
        files: [(name: String, type: CaseDocumentType, url: URL)],
        description: String? = nil,
        tags: [String] = []
    ) async -> [DocumentOperationResult] {
        
        var results: [DocumentOperationResult] = []
        
        for file in files {
            let result = await uploadDocument(
                to: caseId,
                name: file.name,
                type: file.type,
                fileURL: file.url,
                description: description,
                tags: tags
            )
            results.append(result)
        }
        
        return results
    }
    
    /// 获取所有案件的文书统计
    func getAllDocumentsStats() -> [String: CaseDocumentStats] {
        var stats: [String: CaseDocumentStats] = [:]
        
        for (caseId, docs) in documents {
            stats[caseId] = docs.getStats()
        }
        
        return stats
    }
    
    /// 清理指定案件的所有文档
    func clearCaseDocuments(_ caseId: String) {
        // 删除本地文件
        let caseDir = getCaseDocumentsDirectory(for: caseId)
        try? fileManager.removeItem(at: caseDir)
        
        // 清理内存数据
        documents[caseId] = nil
        saveDocuments()
    }
    
    /// 导出文档列表为JSON
    func exportDocumentsList(for caseId: String) -> Data? {
        let docs = getDocuments(for: caseId)
        return try? JSONEncoder().encode(docs)
    }
}