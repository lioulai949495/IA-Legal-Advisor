import Foundation
import SwiftUI

// MARK: - 案件流程模型

/// 工作流程步骤状态
enum WorkflowStepStatus: String, Codable {
    case completed = "已完成"
    case inProgress = "进行中"
    case pending = "待处理"
    
    var color: Color {
        switch self {
        case .completed: return .green
        case .inProgress: return .orange
        case .pending: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .completed: return "checkmark.circle.fill"
        case .inProgress: return "clock.fill"
        case .pending: return "circle"
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
}

/// 基础工作流程步骤
struct WorkflowStep: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let status: WorkflowStepStatus
    let date: Date?
    let estimatedDays: Int
}

/// 增强的案件流程步骤
struct EnhancedWorkflowStep: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    var status: WorkflowStepStatus
    var date: Date?
    let estimatedDays: Int
    let stepType: CaseWorkflowStepType
    let actionGuide: ActionGuide
    let requiredDocuments: [RequiredDocument]
    let legalNotices: [LegalNotice]
    var isCustomStep: Bool = false
    var allowsCustomSubsteps: Bool = false
    
    /// 是否可以被用户操作（上传文档、提交信息等）
    var isInteractive: Bool {
        switch stepType {
        case .analysis, .litigation, .evidencePreparation, .judgmentAnalysis:
            return true
        case .customStep:
            return true
        default:
            return false
        }
    }
}

/// 案件流程步骤类型
enum CaseWorkflowStepType: String, Codable, CaseIterable {
    case analysis = "案件分析"
    case materialPreparation = "材料准备"
    case caseFilingGuidance = "案件提交指导"
    case litigation = "向法院提起诉讼"
    case preTrialPreservation = "诉前保全"
    case evidencePreparation = "证据准备及答辩文书"
    case defenseResponse = "答辩应对"
    case judgmentAnalysis = "判决书分析"
    case secondTrial = "二审程序"
    case execution = "申请执行"
    case retrial = "申请再审"
    case postTrialHandling = "审后处理"
    case caseClose = "结案"
    case customStep = "自定义步骤"
    
    var icon: String {
        switch self {
        case .analysis: return "magnifyingglass.circle"
        case .materialPreparation: return "folder.badge.plus"
        case .caseFilingGuidance: return "map.fill"
        case .litigation: return "building.columns"
        case .preTrialPreservation: return "lock.shield"
        case .evidencePreparation: return "doc.text"
        case .defenseResponse: return "shield.fill"
        case .judgmentAnalysis: return "scale.3d"
        case .secondTrial: return "arrow.triangle.2.circlepath"
        case .execution: return "hammer"
        case .retrial: return "repeat.circle"
        case .postTrialHandling: return "checklist"
        case .caseClose: return "checkmark.circle"
        case .customStep: return "plus.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .analysis: return .blue
        case .materialPreparation: return .teal
        case .caseFilingGuidance: return .mint
        case .litigation: return .red
        case .preTrialPreservation: return .orange
        case .evidencePreparation: return .green
        case .defenseResponse: return .yellow
        case .judgmentAnalysis: return .purple
        case .secondTrial: return .indigo
        case .execution: return .brown
        case .retrial: return .cyan
        case .postTrialHandling: return .pink
        case .caseClose: return .gray
        case .customStep: return .pink
        }
    }
}

/// 操作指南
struct ActionGuide: Codable {
    let title: String
    let steps: [ActionStep]
    let tips: [String]
    let warnings: [String]
    let estimatedTime: String
    let difficulty: DifficultyLevel
    
    enum DifficultyLevel: String, Codable {
        case easy = "简单"
        case medium = "中等" 
        case hard = "复杂"
        
        var color: Color {
            switch self {
            case .easy: return .green
            case .medium: return .orange
            case .hard: return .red
            }
        }
    }
}

/// 具体行动步骤
struct ActionStep: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let order: Int
    let isRequired: Bool
    let estimatedMinutes: Int
    let relatedDocuments: [String] // 关联的文档ID
    let signatureRequired: Bool // 是否需要签字
    let sealRequired: Bool // 是否需要盖章/按手印
    let signatureInstructions: String? // 签字说明
}

/// 所需文档
struct RequiredDocument: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let isRequired: Bool
    let template: DocumentTemplate?
    let sampleDocument: SampleDocument?
    let submissionDeadline: Date?
    let submissionMethod: SubmissionMethod
    
    enum SubmissionMethod: String, Codable {
        case online = "在线提交"
        case offline = "线下提交"
        case both = "线上线下均可"
    }
}

/// 文档模板
struct DocumentTemplate: Codable {
    let id: String
    let name: String
    let downloadUrl: String?
    let fillableFields: [FillableField]
    let instructions: String
    let fileFormat: String // PDF, DOC等
}

/// 可填写字段
struct FillableField: Identifiable, Codable {
    let id: String
    let fieldName: String
    let fieldType: FieldType
    let isRequired: Bool
    let placeholder: String
    let validationRules: [String]
    let signatureField: Bool
    let sealField: Bool
    
    enum FieldType: String, Codable {
        case text = "文本"
        case number = "数字"
        case date = "日期"
        case signature = "签名"
        case seal = "印章"
        case checkbox = "复选框"
    }
}

/// 样表文档
struct SampleDocument: Codable {
    let id: String
    let name: String
    let previewUrl: String?
    let downloadUrl: String?
    let description: String
    let annotations: [DocumentAnnotation] // 标注说明
}

/// 文档标注
struct DocumentAnnotation: Identifiable, Codable {
    let id: String
    let x: Double // 相对位置X
    let y: Double // 相对位置Y
    let width: Double
    let height: Double
    let content: String
    let annotationType: AnnotationType
    
    enum AnnotationType: String, Codable {
        case signature = "签字处"
        case seal = "盖章处"
        case fillText = "填写处"
        case attention = "注意事项"
    }
}

/// 法律提醒
struct LegalNotice: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let noticeType: NoticeType
    let severity: NoticeSeverity
    let relatedLaws: [String] // 相关法条
    let consequences: String // 后果说明
    
    enum NoticeType: String, Codable {
        case obligation = "法律义务"
        case responsibility = "法律责任"
        case deadline = "期限提醒"
        case procedure = "程序要求"
        case evidence = "证据要求"
        case cost = "费用说明"
    }
    
    enum NoticeSeverity: String, Codable {
        case info = "信息"
        case warning = "警告"
        case critical = "重要"
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .critical: return .red
            }
        }
    }
}

/// 诉前保全配置
struct PreTrialPreservation: Codable {
    let targetAssets: [AssetType] // 保全标的
    let estimatedValue: Double // 预估价值
    let securityDeposit: Double // 担保金额
    let validityPeriod: Int // 有效期（天）
    let applicationFee: Double // 申请费
    let procedures: [PreservationProcedure]
    
    enum AssetType: String, Codable, CaseIterable {
        case bankAccount = "银行账户"
        case realEstate = "不动产"
        case vehicles = "车辆"
        case stocks = "股权"
        case other = "其他财产"
        
        var icon: String {
            switch self {
            case .bankAccount: return "creditcard"
            case .realEstate: return "house"
            case .vehicles: return "car"
            case .stocks: return "chart.line.uptrend.xyaxis"
            case .other: return "dollarsign.circle"
            }
        }
    }
}

/// 保全程序
struct PreservationProcedure: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let requiredDocuments: [String]
    let estimatedDays: Int
    let cost: Double
}

/// 公证配置
struct NotarizationInfo: Codable {
    let notaryOffices: [NotaryOffice] // 推荐公证处
    let notarizationTypes: [NotarizationType]
    let estimatedCost: CostRange
    let requiredDocuments: [String]
    let processingTime: String
    let appointmentRequired: Bool
}

/// 公证处信息
struct NotaryOffice: Identifiable, Codable {
    let id: String
    let name: String
    let address: String
    let phone: String
    let workingHours: String
    let appointmentUrl: String?
    let rating: Double
    let distance: Double? // 距离（公里）
}

/// 公证类型
struct NotarizationType: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let baseFee: Double
    let additionalFees: [FeeItem]
    
    struct FeeItem: Codable {
        let description: String
        let amount: Double
        let unit: String // 例如：/页、/份等
    }
}

/// 费用范围
struct CostRange: Codable {
    let min: Double
    let max: Double
    let currency: String = "CNY"
    
    var formattedRange: String {
        if min == max {
            return "¥\(Int(min))"
        } else {
            return "¥\(Int(min)) - ¥\(Int(max))"
        }
    }
}

/// AI分析结果
struct AIAnalysisResult: Identifiable, Codable {
    let id: String
    let documentType: String // 文档类型
    let analysisDate: Date
    let keyFindings: [String] // 关键发现
    let suggestedActions: [String] // 建议行动
    let evidenceStrength: Double // 证据强度 0-1
    let riskAssessment: String // 风险评估
    let generatedDocument: WorkflowGeneratedDocument? // 生成的文档
    let confidence: Double // AI信心度 0-1
}

/// AI生成文档 (工作流程专用)
struct WorkflowGeneratedDocument: Identifiable, Codable {
    let id: String
    let documentType: String
    let content: String
    let generatedAt: Date
    let templateUsed: String
    let editableFields: [String] // 可编辑字段
    let reviewRequired: Bool // 是否需要人工审核
    let downloadUrl: String?
    
    var confidence: Double = 0.8 // AI信心度
}

// MARK: - 工作流程状态扩展

// WorkflowStepStatus 已在上方定义为 Codable enum