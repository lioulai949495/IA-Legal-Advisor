import Foundation
import SwiftUI

// MARK: - 案件文书管理数据模型

/// 案件文书类型
enum CaseDocumentType: String, CaseIterable, Codable {
    // 上传的证据文件
    case evidence = "证据文件"
    case contract = "合同文件" 
    case correspondence = "通信记录"
    case photo = "照片证据"
    case audio = "音频文件"
    case video = "视频文件"
    
    // AI生成的法律文书
    case complaint = "起诉状"
    case response = "答辩状"
    case evidence_list = "证据清单"
    case proxy_letter = "委托书"
    case settlement_agreement = "和解协议"
    case appeal = "上诉状"
    case execution_application = "执行申请书"
    
    // 案件分析文档
    case case_analysis = "案件分析报告"
    case legal_opinion = "法律意见书"
    case risk_assessment = "风险评估报告"
    case strategy_plan = "诉讼策略书"
    
    var icon: String {
        switch self {
        case .evidence, .photo: return "doc.text.image"
        case .contract: return "doc.on.doc"
        case .correspondence: return "message.fill"
        case .audio: return "waveform"
        case .video: return "video.fill"
        case .complaint, .response: return "doc.richtext"
        case .evidence_list: return "list.bullet.clipboard"
        case .proxy_letter: return "person.crop.circle.badge.checkmark"
        case .settlement_agreement: return "handshake"
        case .appeal: return "arrow.up.doc"
        case .execution_application: return "hammer"
        case .case_analysis: return "chart.bar.doc.horizontal"
        case .legal_opinion: return "scale.3d"
        case .risk_assessment: return "exclamationmark.triangle"
        case .strategy_plan: return "map"
        }
    }
    
    var color: Color {
        switch self {
        case .evidence, .contract, .correspondence, .photo, .audio, .video:
            return .blue
        case .complaint, .response, .evidence_list, .proxy_letter, .settlement_agreement, .appeal, .execution_application:
            return .green
        case .case_analysis, .legal_opinion, .risk_assessment, .strategy_plan:
            return .orange
        }
    }
    
    var category: CaseDocumentCategory {
        switch self {
        case .evidence, .contract, .correspondence, .photo, .audio, .video:
            return .uploaded
        case .complaint, .response, .evidence_list, .proxy_letter, .settlement_agreement, .appeal, .execution_application:
            return .generated
        case .case_analysis, .legal_opinion, .risk_assessment, .strategy_plan:
            return .analysis
        }
    }
}

/// 案件文档分类
enum CaseDocumentCategory: String, CaseIterable {
    case uploaded = "上传文件"
    case generated = "生成文书"
    case analysis = "分析报告"
    
    var color: Color {
        switch self {
        case .uploaded: return .blue
        case .generated: return .green
        case .analysis: return .orange
        }
    }
}

/// 案件文书模型
struct CaseDocument: Identifiable, Codable, Equatable {
    let id: String
    let caseId: String
    let name: String
    let type: CaseDocumentType
    let fileExtension: String?
    let filePath: String? // 本地文件路径
    let content: String? // 文本内容（用于AI生成的文书）
    let fileSize: Int64 // 文件大小（字节）
    let createdAt: Date
    let updatedAt: Date
    let createdBy: DocumentSource
    let isDownloaded: Bool // 是否已下载到本地
    let isShared: Bool // 是否已分享
    let tags: [String] // 标签
    let description: String? // 文档描述
    let version: Int // 版本号
    
    init(
        id: String = UUID().uuidString,
        caseId: String,
        name: String,
        type: CaseDocumentType,
        fileExtension: String? = nil,
        filePath: String? = nil,
        content: String? = nil,
        fileSize: Int64 = 0,
        createdBy: DocumentSource = .user,
        tags: [String] = [],
        description: String? = nil
    ) {
        self.id = id
        self.caseId = caseId
        self.name = name
        self.type = type
        self.fileExtension = fileExtension
        self.filePath = filePath
        self.content = content
        self.fileSize = fileSize
        self.createdAt = Date()
        self.updatedAt = Date()
        self.createdBy = createdBy
        self.isDownloaded = filePath != nil
        self.isShared = false
        self.tags = tags
        self.description = description
        self.version = 1
    }
    
    static func == (lhs: CaseDocument, rhs: CaseDocument) -> Bool {
        return lhs.id == rhs.id
    }
}

/// 文档来源
enum DocumentSource: String, Codable {
    case user = "用户上传"
    case ai = "AI生成"
    case template = "模板生成"
    case imported = "导入文件"
}

/// 案件文书统计
struct CaseDocumentStats {
    let totalCount: Int
    let uploadedCount: Int
    let generatedCount: Int
    let analysisCount: Int
    let totalSize: Int64
    let lastUpdated: Date?
    
    static let empty = CaseDocumentStats(
        totalCount: 0,
        uploadedCount: 0,
        generatedCount: 0,
        analysisCount: 0,
        totalSize: 0,
        lastUpdated: nil
    )
}

/// 文档搜索过滤器
struct DocumentFilter {
    var category: CaseDocumentCategory?
    var type: CaseDocumentType?
    var source: DocumentSource?
    var searchText: String = ""
    var dateRange: ClosedRange<Date>?
    var tags: [String] = []
    
    static let all = DocumentFilter()
}

/// 文档排序选项
enum DocumentSortOption: String, CaseIterable {
    case nameAscending = "名称（升序）"
    case nameDescending = "名称（降序）"
    case dateCreated = "创建时间"
    case dateUpdated = "更新时间"
    case typeAscending = "类型（升序）"
    case sizeAscending = "大小（升序）"
    case sizeDescending = "大小（降序）"
    
    var systemImage: String {
        switch self {
        case .nameAscending: return "textformat.abc"
        case .nameDescending: return "textformat.abc"
        case .dateCreated: return "calendar.badge.plus"
        case .dateUpdated: return "calendar.badge.clock"
        case .typeAscending: return "doc.badge.gearshape"
        case .sizeAscending, .sizeDescending: return "archivebox"
        }
    }
}

// MARK: - 文档操作结果

/// 文档操作结果
struct DocumentOperationResult {
    let success: Bool
    let message: String
    let document: CaseDocument?
    let error: DocumentError?
    
    static func success(document: CaseDocument, message: String = "操作成功") -> DocumentOperationResult {
        return DocumentOperationResult(success: true, message: message, document: document, error: nil)
    }
    
    static func failure(error: DocumentError) -> DocumentOperationResult {
        return DocumentOperationResult(success: false, message: error.localizedDescription, document: nil, error: error)
    }
}

/// 文档错误类型
enum DocumentError: LocalizedError {
    case fileNotFound
    case invalidFileType
    case fileSizeTooLarge
    case insufficientStorage
    case networkError
    case permissionDenied
    case corruptedFile
    case duplicateDocument
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound: return "文件未找到"
        case .invalidFileType: return "不支持的文件类型"
        case .fileSizeTooLarge: return "文件过大"
        case .insufficientStorage: return "存储空间不足"
        case .networkError: return "网络错误"
        case .permissionDenied: return "权限不足"
        case .corruptedFile: return "文件已损坏"
        case .duplicateDocument: return "文档已存在"
        }
    }
}

// MARK: - 扩展方法

extension CaseDocument {
    /// 格式化文件大小
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    /// 是否为文本类型
    var isTextType: Bool {
        return content != nil
    }
    
    /// 是否为图片类型
    var isImageType: Bool {
        guard let ext = fileExtension?.lowercased() else { return false }
        return ["jpg", "jpeg", "png", "gif", "heic", "webp"].contains(ext)
    }
    
    /// 是否为PDF类型
    var isPDFType: Bool {
        return fileExtension?.lowercased() == "pdf"
    }
    
    /// 获取文件图标
    var fileIcon: String {
        if isTextType {
            return type.icon
        } else if isImageType {
            return "photo"
        } else if isPDFType {
            return "doc.fill"
        } else {
            return "doc"
        }
    }
}

extension Array where Element == CaseDocument {
    /// 按类型分组
    func groupedByType() -> [CaseDocumentType: [CaseDocument]] {
        return Dictionary(grouping: self) { $0.type }
    }
    
    /// 按分类分组
    func groupedByCategory() -> [CaseDocumentCategory: [CaseDocument]] {
        return Dictionary(grouping: self) { $0.type.category }
    }
    
    /// 计算总文件大小
    var totalSize: Int64 {
        return self.reduce(0) { $0 + $1.fileSize }
    }
    
    /// 获取统计信息
    func getStats() -> CaseDocumentStats {
        let grouped = groupedByCategory()
        return CaseDocumentStats(
            totalCount: self.count,
            uploadedCount: grouped[.uploaded]?.count ?? 0,
            generatedCount: grouped[.generated]?.count ?? 0,
            analysisCount: grouped[.analysis]?.count ?? 0,
            totalSize: totalSize,
            lastUpdated: self.map { $0.updatedAt }.max()
        )
    }
}