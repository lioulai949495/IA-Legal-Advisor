import Foundation
import SwiftUI

// MARK: - Agent Base Types

protocol AIAgent {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var agentType: AgentType { get }
    var specializations: [String] { get }
    var isActive: Bool { get set }
    
    func processRequest(_ request: AgentRequest) async throws -> AgentResponse
    func canHandle(_ caseType: CaseType) -> Bool
}

enum AgentType: String, Codable, CaseIterable {
    case legalConsultant = "法律咨询师"
    case caseAnalyst = "案件分析师"
    case documentGenerator = "文档生成器"
    case riskAssessor = "风险评估师"
    case contractReviewer = "合同审查师"
    case litigationAdvisor = "诉讼顾问"
    
    var icon: String {
        switch self {
        case .legalConsultant: return "person.crop.circle.badge.questionmark"
        case .caseAnalyst: return "magnifyingglass.circle"
        case .documentGenerator: return "doc.text"
        case .riskAssessor: return "exclamationmark.triangle"
        case .contractReviewer: return "doc.plaintext"
        case .litigationAdvisor: return "scale.3d"
        }
    }
    
    var color: Color {
        switch self {
        case .legalConsultant: return .blue
        case .caseAnalyst: return .green
        case .documentGenerator: return .orange
        case .riskAssessor: return .red
        case .contractReviewer: return .purple
        case .litigationAdvisor: return .indigo
        }
    }
}

// MARK: - Agent Request/Response Models

struct AgentRequest: Codable {
    let id: String
    let agentType: AgentType
    let caseType: CaseType?
    let content: String
    let context: AgentContext?
    let priority: RequestPriority
    let createdAt: Date
    
    enum RequestPriority: String, Codable {
        case low = "低"
        case normal = "普通"
        case high = "高"
        case urgent = "紧急"
    }
}

struct AgentResponse: Codable {
    let id: String
    let requestId: String
    let agentId: String
    let content: String
    let confidence: Double
    let recommendations: [Recommendation]?
    let attachments: [AgentAttachment]?
    let followUpQuestions: [String]?
    let createdAt: Date
    let processingTime: TimeInterval
}

struct AgentContext: Codable {
    let caseId: String?
    let userId: String
    let previousMessages: [Message]?
    let caseDetails: CaseDetails?
    let userPreferences: UserPreferences?
}

struct CaseDetails: Codable {
    let id: String
    let title: String
    let description: String
    let caseType: CaseType
    let status: CaseStatus
    let documents: [String]
    let timeline: [CaseEvent]
    let involvedParties: [Party]
    let createdAt: Date
    let lastUpdatedAt: Date
}

struct CaseEvent: Codable, Identifiable {
    let id: String
    let date: Date
    let description: String
    let importance: EventImportance
    
    enum EventImportance: String, Codable {
        case low = "低"
        case medium = "中"
        case high = "高"
        case critical = "关键"
    }
}

struct Party: Codable, Identifiable {
    let id: String
    let name: String
    let role: PartyRole
    let contactInfo: String?
    
    enum PartyRole: String, Codable {
        case plaintiff = "原告"
        case defendant = "被告"
        case witness = "证人"
        case expert = "专家"
        case lawyer = "律师"
        case other = "其他"
    }
}

struct UserPreferences: Codable {
    let preferredLanguage: String
    let communicationStyle: CommunicationStyle
    let expertiseLevel: ExpertiseLevel
    
    enum CommunicationStyle: String, Codable {
        case formal = "正式"
        case casual = "随意"
        case detailed = "详细"
        case concise = "简洁"
    }
    
    enum ExpertiseLevel: String, Codable {
        case beginner = "初学者"
        case intermediate = "中级"
        case advanced = "高级"
        case expert = "专家"
    }
}

// MARK: - Recommendation System

struct Recommendation: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let actionType: ActionType
    let priority: RecommendationPriority
    let estimatedCost: Double?
    let timeframe: String
    let requirements: [String]
    
    enum ActionType: String, Codable {
        case consult = "咨询"
        case investigate = "调查"
        case negotiate = "协商"
        case mediate = "调解"
        case litigate = "诉讼"
        case appeal = "上诉"
        case settle = "和解"
        case fileComplaint = "申请复议"
        case fileLawsuit = "提起诉讼"
        case other = "其他"
    }
    
    enum RecommendationPriority: String, Codable {
        case low = "低优先级"
        case medium = "中优先级"
        case high = "高优先级"
        case critical = "紧急"
    }
}

struct AgentAttachment: Codable, Identifiable {
    let id: String
    let name: String
    let type: AttachmentType
    let url: String?
    let content: String?
    let size: Int64?
    
    enum AttachmentType: String, Codable {
        case document = "文档"
        case template = "模板"
        case form = "表格"
        case reference = "参考资料"
        case example = "示例"
        case checklist = "检查清单"
    }
}

// MARK: - Agent Performance Metrics

struct AgentMetrics: Codable {
    let agentId: String
    var totalRequests: Int
    var successfulResponses: Int
    var averageResponseTime: TimeInterval
    var averageConfidence: Double
    var userSatisfactionRating: Double
    var lastUpdated: Date
    
    var successRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(successfulResponses) / Double(totalRequests)
    }
}

// MARK: - Agent Configuration

struct AgentConfiguration: Codable {
    let agentId: String
    let maxConcurrentRequests: Int
    let responseTimeoutSeconds: TimeInterval
    let confidenceThreshold: Double
    let enabledFeatures: [AgentFeature]
    let customPrompts: [String: String]
    
    enum AgentFeature: String, Codable, CaseIterable {
        case caseAnalysis = "案件分析"
        case documentGeneration = "文档生成"
        case riskAssessment = "风险评估"
        case legalResearch = "法律研究"
        case contractReview = "合同审查"
        case complianceCheck = "合规检查"
    }
}

// MARK: - Agent Status and Health

enum AgentStatus: String, Codable {
    case active = "活跃"
    case idle = "空闲"
    case busy = "忙碌"
    case maintenance = "维护中"
    case error = "错误"
    case offline = "离线"
}

struct AgentHealth: Codable {
    let agentId: String
    var status: AgentStatus
    let cpuUsage: Double
    let memoryUsage: Double
    let activeConnections: Int
    var lastHealthCheck: Date
    var errors: [AgentErrorInfo]
}

struct AgentErrorInfo: Codable, Identifiable {
    let id: String
    let agentId: String
    let errorType: ErrorType
    let message: String
    let timestamp: Date
    let severity: ErrorSeverity
    
    enum ErrorType: String, Codable {
        case connection = "连接错误"
        case processing = "处理错误"
        case timeout = "超时错误"
        case authentication = "认证错误"
        case validation = "验证错误"
        case system = "系统错误"
    }
    
    enum ErrorSeverity: String, Codable {
        case info = "信息"
        case warning = "警告"
        case error = "错误"
        case critical = "严重"
    }
}

// MARK: - Agent Error Handling

enum AgentError: LocalizedError {
    case unsupportedCaseType(String)
    case processingFailed(String)
    case invalidRequest(String)
    case configurationError(String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedCaseType(let type):
            return "不支持的案件类型: \(type)"
        case .processingFailed(let message):
            return "处理失败: \(message)"
        case .invalidRequest(let message):
            return "无效请求: \(message)"
        case .configurationError(let message):
            return "配置错误: \(message)"
        }
    }
}

// MARK: - Specialized Agent Interfaces

protocol LegalConsultantAgent: AIAgent {
    func provideLegalAdvice(for caseType: CaseType, query: String) async throws -> LegalAdvice
    func answerLegalQuestion(_ question: String, context: AgentContext?) async throws -> String
}

protocol CaseAnalystAgent: AIAgent {
    func analyzeCaseStrength(_ caseDetails: CaseDetails) async throws -> CaseStrengthAnalysis
    func identifyLegalIssues(_ caseDetails: CaseDetails) async throws -> [LegalIssue]
    func suggestLegalStrategy(_ caseDetails: CaseDetails) async throws -> LegalStrategy
}

protocol DocumentGeneratorAgent: AIAgent {
    func generateDocument(type: LegalDocumentType, parameters: [String: Any]) async throws -> AgentGeneratedDocument
    func generateContract(type: ContractType, terms: ContractTerms) async throws -> AgentGeneratedDocument
}

protocol RiskAssessorAgent: AIAgent {
    func assessRisk(_ caseDetails: CaseDetails) async throws -> RiskAssessment
    func identifyPotentialIssues(_ caseDetails: CaseDetails) async throws -> [RiskFactor]
}

// MARK: - Supporting Data Structures

struct LegalAdvice: Codable {
    let id: String
    let advice: String
    let legalBasis: String
    let applicableLaws: [String]
    let nextSteps: [String]
    let confidence: Double
    let disclaimers: [String]
}

struct CaseStrengthAnalysis: Codable {
    let overallStrength: StrengthLevel
    let strengths: [String]
    let weaknesses: [String]
    let opportunities: [String]
    let threats: [String]
    let recommendedActions: [String]
    
    enum StrengthLevel: String, Codable {
        case veryWeak = "非常弱"
        case weak = "弱"
        case moderate = "中等"
        case strong = "强"
        case veryStrong = "非常强"
    }
}

struct LegalIssue: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let severity: IssueSeverity
    let legalArea: String
    let applicableLaws: [String]
    let suggestedActions: [String]
    
    enum IssueSeverity: String, Codable {
        case minor = "轻微"
        case moderate = "中等"
        case serious = "严重"
        case critical = "关键"
    }
}

struct LegalStrategy: Codable {
    let id: String
    let title: String
    let description: String
    let approach: StrategyApproach
    let timeline: [StrategyMilestone]
    let estimatedCost: Double?
    let successProbability: Double
    let risks: [String]
    let alternatives: [AlternativeStrategy]
    
    enum StrategyApproach: String, Codable {
        case negotiation = "协商"
        case mediation = "调解"
        case arbitration = "仲裁"
        case litigation = "诉讼"
        case settlement = "和解"
    }
}

struct StrategyMilestone: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let targetDate: Date
    let dependencies: [String]
    let deliverables: [String]
}

struct AlternativeStrategy: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let pros: [String]
    let cons: [String]
    let estimatedCost: Double?
}

enum LegalDocumentType: String, Codable, CaseIterable {
    case complaint = "起诉书"
    case answer = "答辞书"
    case motion = "申请书"
    case settlement = "和解协议"
    case contract = "合同"
    case letter = "律师函"
    case memo = "法律备忘录"
    case brief = "法律简报"
}

enum ContractType: String, Codable, CaseIterable {
    case employment = "劳动合同"
    case lease = "租赁合同"
    case purchase = "买卖合同"
    case service = "服务合同"
    case partnership = "合伙协议"
    case nda = "保密协议"
    case license = "许可协议"
}

struct ContractTerms: Codable {
    let parties: [ContractParty]
    let subject: String
    let terms: [String: String]
    let duration: String?
    let compensation: String?
    let obligations: [String: [String]]
    let conditions: [String]
}

struct ContractParty: Codable, Identifiable {
    let id: String
    let name: String
    let type: PartyType
    let address: String
    let contactInfo: String
    
    enum PartyType: String, Codable {
        case individual = "个人"
        case company = "公司"
        case organization = "组织"
        case government = "政府"
    }
}

struct AgentGeneratedDocument: Codable {
    let id: String
    let type: LegalDocumentType
    let title: String
    let content: String
    let metadata: DocumentMetadata
    let templates: [String]
    let createdAt: Date
}

struct DocumentMetadata: Codable {
    let author: String
    let version: String
    let jurisdiction: String
    let language: String
    let tags: [String]
    let reviewStatus: ReviewStatus
    
    enum ReviewStatus: String, Codable {
        case draft = "草稿"
        case review = "审查中"
        case approved = "已批准"
        case final = "最终版"
    }
}

struct RiskAssessment: Codable {
    let id: String
    let overallRisk: RiskLevel
    let riskFactors: [RiskFactor]
    let mitigationStrategies: [MitigationStrategy]
    let recommendations: [String]
    let confidence: Double
    
    enum RiskLevel: String, Codable {
        case veryLow = "很低"
        case low = "低"
        case medium = "中等"
        case high = "高"
        case veryHigh = "很高"
    }
}

struct RiskFactor: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let category: RiskCategory
    let severity: RiskSeverity
    let probability: Double
    let impact: Double
    let mitigationActions: [String]
    
    enum RiskCategory: String, Codable {
        case legal = "法律风险"
        case financial = "财务风险"
        case operational = "运营风险"
        case reputational = "声誉风险"
        case regulatory = "监管风险"
    }
    
    enum RiskSeverity: String, Codable {
        case negligible = "可忽略"
        case minor = "轻微"
        case moderate = "中等"
        case major = "重大"
        case catastrophic = "灾难性"
    }
}

struct MitigationStrategy: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let targetRisks: [String]
    let actions: [MitigationAction]
    let timeline: String
    let estimatedCost: Double?
    let effectiveness: Double
}

struct MitigationAction: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let responsible: String
    let deadline: Date
    let status: ActionStatus
    
    enum ActionStatus: String, Codable {
        case pending = "待办"
        case inProgress = "进行中"
        case completed = "完成"
        case blocked = "受阻"
        case cancelled = "取消"
    }
}