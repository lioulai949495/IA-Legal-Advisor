import Foundation
import SwiftUI

// MARK: - 扩展的数据模型

// 用户等级枚举
enum UserTier: String, Codable, CaseIterable {
    case free = "免费用户"
    case premium = "高级会员"
    
    var maxFreeConsultations: Int {
        switch self {
        case .free: return 3
        case .premium: return -1 // 无限制
        }
    }
    
    var dailyFreeQuestions: Int {
        switch self {
        case .free: return 5
        case .premium: return -1 // 无限制
        }
    }
}

// 扩展用户模型
struct ExtendedUser: Codable, Identifiable {
    var id: String
    var email: String
    var username: String?
    var phoneNumber: String?
    var avatarUrl: String?
    var tier: UserTier = .free
    var remainingConsultations: Int = 3
    var remainingQuestions: Int = 5
    var totalSpent: Double = 0.0
    var membershipExpiry: Date?
}

// 法律资讯类型
enum LegalNewsType: String, Codable, CaseIterable {
    case hotNews = "法律热点"
    case caseStudy = "案例分析"
    case lawUpdate = "法规更新"
    case courtDecision = "法院判决"
    
    var icon: String {
        switch self {
        case .hotNews: return "flame.fill"
        case .caseStudy: return "doc.text.magnifyingglass"
        case .lawUpdate: return "doc.badge.plus"
        case .courtDecision: return "building.columns.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .hotNews: return .red
        case .caseStudy: return .blue
        case .lawUpdate: return .green
        case .courtDecision: return .purple
        }
    }
}

// 法律资讯模型
struct LegalNews: Codable, Identifiable {
    var id: String
    var title: String
    var summary: String
    var content: String
    var imageUrl: String?
    var publishDate: Date
    var source: String
    var url: String?
    var type: LegalNewsType
    var tags: [String]
    var readCount: Int = 0
    var isFavorite: Bool = false
}

// 法律法规模型
struct LegalRegulation: Codable, Identifiable {
    var id: String
    var title: String
    var category: String
    var effectiveDate: Date
    var content: String
    var articles: [LegalArticle]
    var keywords: [String]
    var downloadUrl: String?
}

struct LegalArticle: Codable, Identifiable {
    var id: String
    var number: String
    var title: String
    var content: String
}

// 案例库模型
struct CaseExample: Codable, Identifiable {
    var id: String
    var title: String
    var caseType: CaseType
    var description: String
    var facts: String
    var legalIssues: [String]
    var courtDecision: String
    var keyPoints: [String]
    var relatedLaws: [String]
    var similarity: Double? // 与用户案件的相似度
}

// 增强的案件分析
struct CaseAnalysis: Codable, Identifiable {
    var id: String
    var caseId: String
    var analysisSteps: [AnalysisStep]
    var winProbability: Double?
    var estimatedCost: CostEstimate?
    var recommendedActions: [String]
    var requiredDocuments: [String]
    var timelineEstimate: String?
    var isPaid: Bool = false
}

struct AnalysisStep: Codable, Identifiable {
    var id: String
    var question: String
    var answer: String?
    var options: [String]?
    var isCompleted: Bool = false
}

struct CostEstimate: Codable {
    var courtFees: Double
    var lawyerFees: ClosedRange<Double>
    var otherCosts: Double
    var total: ClosedRange<Double>
}

// 工具和表单
struct LegalForm: Codable, Identifiable {
    var id: String
    var title: String
    var category: String
    var description: String
    var downloadUrl: String
    var sampleUrl: String?
    var instructions: String
    var requiredFields: [String]
}

struct CourtProcedure: Codable, Identifiable {
    var id: String
    var title: String
    var category: String
    var steps: [ProcedureStep]
    var estimatedTime: String
    var requiredDocuments: [String]
    var fees: String
}

struct ProcedureStep: Codable, Identifiable {
    var id: String
    var stepNumber: Int
    var title: String
    var description: String
    var tips: [String]
    var isCompleted: Bool = false
}

// 人工律师服务
struct LawyerService: Codable, Identifiable {
    var id: String
    var name: String
    var specialization: [String]
    var experience: String
    var rating: Double
    var hourlyRate: Double
    var availability: String
    var contactEmail: String
    var isOnline: Bool
}

struct LawyerConsultation: Codable, Identifiable {
    var id: String
    var caseId: String
    var lawyerId: String
    var requestDate: Date
    var status: ConsultationStatus
    var urgency: UrgencyLevel
    var expectedResponse: String
}

enum ConsultationStatus: String, Codable {
    case pending = "待处理"
    case inProgress = "处理中"
    case completed = "已完成"
    case cancelled = "已取消"
}

enum UrgencyLevel: String, Codable, CaseIterable {
    case low = "一般"
    case medium = "紧急"
    case high = "非常紧急"
    
    var responseTime: String {
        switch self {
        case .low: return "3-5个工作日"
        case .medium: return "1-2个工作日"
        case .high: return "24小时内"
        }
    }
}

// 付费相关
struct PaymentPlan: Codable, Identifiable {
    var id: String
    var name: String
    var price: Double
    var duration: Int // 天数
    var features: [String]
    var consultationCredits: Int
    var questionCredits: Int
    var isPopular: Bool = false
}

struct Transaction: Codable, Identifiable {
    var id: String
    var userId: String
    var type: TransactionType
    var amount: Double
    var description: String
    var date: Date
    var status: TransactionStatus
}

enum TransactionType: String, Codable {
    case consultation = "案件咨询"
    case question = "问题询问"
    case membership = "会员充值"
    case lawyerService = "律师服务"
}

enum TransactionStatus: String, Codable {
    case pending = "待支付"
    case completed = "已完成"
    case failed = "支付失败"
    case refunded = "已退款"
}

// MARK: - 示例数据

class NewSampleData {
    static let legalNews: [LegalNews] = [
        LegalNews(
            id: "1",
            title: "最高法发布《关于审理网络消费纠纷案件适用法律若干问题的规定》",
            summary: "针对网络消费中的新问题，最高法出台司法解释，明确平台责任和消费者权益保护。",
            content: "详细内容...",
            publishDate: Date().addingTimeInterval(-86400),
            source: "最高人民法院",
            type: .lawUpdate,
            tags: ["网络消费", "平台责任", "消费者权益"]
        ),
        LegalNews(
            id: "2",
            title: "某知名电商平台因违规收集个人信息被罚款500万元",
            summary: "该平台未经用户同意收集敏感个人信息，被监管部门依法处罚。",
            content: "详细内容...",
            publishDate: Date().addingTimeInterval(-172800),
            source: "网信办",
            type: .hotNews,
            tags: ["个人信息保护", "行政处罚", "电商平台"]
        )
    ]
    
    static let legalForms: [LegalForm] = [
        LegalForm(
            id: "1",
            title: "民事起诉状",
            category: "诉讼文书",
            description: "用于向法院提起民事诉讼的标准格式文书",
            downloadUrl: "https://example.com/forms/civil_complaint.pdf",
            sampleUrl: "https://example.com/samples/civil_complaint_sample.pdf",
            instructions: "1. 填写当事人基本信息\n2. 明确诉讼请求\n3. 陈述事实和理由\n4. 提供证据清单",
            requiredFields: ["原告信息", "被告信息", "诉讼请求", "事实和理由"]
        ),
        LegalForm(
            id: "2",
            title: "劳动仲裁申请书",
            category: "劳动争议",
            description: "用于申请劳动争议仲裁的标准格式文书",
            downloadUrl: "https://example.com/forms/labor_arbitration.pdf",
            instructions: "1. 填写申请人和被申请人信息\n2. 明确仲裁请求\n3. 陈述争议事实\n4. 提供相关证据",
            requiredFields: ["申请人信息", "被申请人信息", "仲裁请求", "争议事实"]
        )
    ]
    
    static let courtProcedures: [CourtProcedure] = [
        CourtProcedure(
            id: "1",
            title: "民事诉讼流程",
            category: "诉讼程序",
            steps: [
                ProcedureStep(id: "1", stepNumber: 1, title: "准备起诉材料", description: "收集证据，撰写起诉状", tips: ["确保证据完整", "起诉状格式正确"]),
                ProcedureStep(id: "2", stepNumber: 2, title: "向法院递交材料", description: "到法院立案庭提交起诉状和证据", tips: ["带齐所有材料", "缴纳案件受理费"]),
                ProcedureStep(id: "3", stepNumber: 3, title: "等待开庭", description: "法院安排开庭时间并通知当事人", tips: ["准备庭审发言", "通知证人出庭"])
            ],
            estimatedTime: "3-6个月",
            requiredDocuments: ["起诉状", "身份证明", "证据材料", "委托书（如有代理人）"],
            fees: "根据争议金额确定，一般为50-500元"
        )
    ]
    
    static let paymentPlans: [PaymentPlan] = [
        PaymentPlan(
            id: "basic",
            name: "基础套餐",
            price: 29.9,
            duration: 30,
            features: ["10次AI咨询", "3份案件分析", "表单下载"],
            consultationCredits: 3,
            questionCredits: 10
        ),
        PaymentPlan(
            id: "premium",
            name: "高级会员",
            price: 99.9,
            duration: 365,
            features: ["无限AI咨询", "无限案件分析", "律师咨询", "优先客服"],
            consultationCredits: -1,
            questionCredits: -1,
            isPopular: true
        )
    ]
}