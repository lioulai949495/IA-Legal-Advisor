import Foundation
import SwiftUI

// MARK: - API Request/Response Models

struct PhoneRequest: Codable {
    let phone_number: String
}

struct LoginRequest: Codable {
    let phone_number: String
    let code: String
}

// 多种登录方式请求模型
struct AppleLoginRequest: Codable {
    let identity_token: String
    let user_identifier: String
    let email: String?
    let full_name: String?
}

struct EmailLoginRequest: Codable {
    let email: String
    let password: String
}

struct EmailRegisterRequest: Codable {
    let email: String
    let password: String
    let username: String
}

struct WeChatLoginRequest: Codable {
    let code: String
}

struct AlipayLoginRequest: Codable {
    let auth_code: String
}

struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let access_token: String
    let token_type: String
}

struct ChatRequest: Codable {
    let category: String
    let role: String?
    let subtype: String?
    let message: String
}

struct ChatResponse: Codable {
    let response: String
    let message_id: String?
    
    // 添加自定义解码器以兼容后端的不同字段名
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 尝试解码 response 字段，如果失败则尝试 message 字段
        if let responseValue = try? container.decode(String.self, forKey: .response) {
            self.response = responseValue
        } else if let messageValue = try? container.decode(String.self, forKey: .message) {
            self.response = messageValue
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, 
                                    debugDescription: "未找到 response 或 message 字段")
            )
        }
        
        self.message_id = try? container.decode(String.self, forKey: .message_id)
    }
    
    // 添加编码器以符合 Codable 协议
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(response, forKey: .response)
        try container.encodeIfPresent(message_id, forKey: .message_id)
    }
    
    private enum CodingKeys: String, CodingKey {
        case response
        case message
        case message_id
    }
}

// 新增：后端 options 响应模型（start-chat / get-roles / get-subtypes）
struct OptionsResponse: Codable {
    let response: String
    let options: [String]
}

// 新增：AI 分析结构
struct AnalysisReportResponse: Codable {
    let analysis_report: AnalysisReport
}

struct AnalysisReport: Codable {
    let applicable_laws: String
    let success_rate_analysis: SuccessRateAnalysis
    let action_suggestion: String
    let next_steps: NextSteps
}

struct SuccessRateAnalysis: Codable {
    let rate: Int
    let reason: String
}

struct NextSteps: Codable {
    let process_guidance: String
    let document_templates: String
}

struct ErrorResponse: Codable {
    let detail: String
}

// MARK: - Extended API Models

// 案件相关API模型
struct CreateCaseRequest: Codable {
    let title: String
    let description: String
    let case_type: String
}

struct UpdateCaseRequest: Codable {
    let title: String?
    let description: String?
}

struct CaseResponse: Codable {
    let id: String
    let title: String
    let description: String
    let case_type: String
    let status: String
    let created_at: String
    let updated_at: String
    let user_id: String
}

// 文档相关API模型
struct DocumentResponse: Codable {
    let id: String
    let case_id: String
    let filename: String
    let file_url: String
    let file_type: String
    let file_size: Int
    let uploaded_at: String
}

// 用户信息相关API模型
struct UserProfileResponse: Codable {
    let id: String
    let username: String?
    let email: String?
    let phone_number: String?
    let created_at: String
    let membership_level: String?
    let membership_expiry: String?
}

struct UpdateProfileRequest: Codable {
    let username: String?
    let email: String?
}

// AI分析相关API模型
struct AIAnalysisRequest: Codable {
    let case_id: String
    let analysis_type: String
}

struct AIAnalysisResponse: Codable {
    let id: String
    let case_id: String
    let analysis_type: String
    let result: String
    let confidence: Double?
    let recommendations: [String]?
    let created_at: String
}

// 文档生成相关API模型
struct DocumentGenerationRequest: Codable {
    let case_id: String
    let document_type: String
    let template: String?
}

struct GeneratedDocumentResponse: Codable {
    let id: String
    let case_id: String
    let document_type: String
    let content: String
    let download_url: String?
    let created_at: String
}

// MARK: - Core Data Models

// Unified User model
struct User: Codable, Identifiable {
    var id: String
    var email: String
    var username: String?
    var phoneNumber: String?
    var avatarUrl: String?
    var membershipLevel: MembershipLevel = .basic
    var membershipExpiry: Date?
    var dailyConsultationsUsed: Int = 0
    var extraCaseSlots: Int = 0 // 额外购买的案件名额
    var dailyConsultationLimit: Int {
        return membershipLevel.dailyConsultationLimit
    }
    var caseLimit: Int {
        return membershipLevel.caseLimit + extraCaseSlots
    }
}

// Unified Message model
struct Message: Codable, Identifiable, Equatable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: String
    var content: String
    var createdAt: Date
    var isFromAI: Bool
    var attachments: [Attachment]?
    var documentLinks: [DocumentLink]?
    var isFromUser: Bool { !isFromAI }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: createdAt)
    }
}

struct Case: Codable, Identifiable, Equatable {
    static func == (lhs: Case, rhs: Case) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: String
    var title: String
    var description: String
    var createdAt: Date
    var lastUpdatedAt: Date
    var caseType: CaseType
    var status: CaseStatus
    var messages: [Message]
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: lastUpdatedAt)
    }
}

struct Attachment: Codable, Identifiable {
    var id: String
    var name: String
    var fileUrl: String
    var fileType: String
}

struct DocumentLink: Codable, Identifiable {
    var id: String
    var title: String
    var description: String
    var url: String
}

struct NewsItem: Codable, Identifiable {
    var id: String
    var title: String
    var summary: String
    var imageUrl: String?
    var publishDate: Date
    var source: String
    var url: String
    var category: NewsCategory
}

// MARK: - Enums

enum AppState {
    case splash
    case unauthenticated
    case authenticated
}

// 一级分类
enum CaseCategory: String, Codable, CaseIterable {
    case civil = "民事"
    case criminal = "刑事"
    case administrative = "行政"
    
    var icon: String {
        switch self {
        case .civil: return "person.2.fill"
        case .criminal: return "exclamationmark.shield.fill"
        case .administrative: return "building.columns.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .civil: return .blue
        case .criminal: return .red
        case .administrative: return .orange
        }
    }
}

// 二级分类
enum CaseType: String, Codable, CaseIterable {
    // 民事案件
    case contractDispute = "合同纠纷"
    case divorceDispute = "离婚纠纷"
    case tradingDispute = "买卖纠纷"
    case propertyDispute = "资产纠纷"
    case intellectualProperty = "知识产权纠纷"
    case laborDispute = "劳动争议"
    case trafficAccident = "交通事故"
    case medicalDispute = "医疗纠纷"
    case neighborDispute = "邻里纠纷"
    case inheritanceDispute = "继承纠纷"
    case debtDispute = "债务纠纷"
    case personalInjury = "人身伤害"
    
    // 刑事案件
    case theft = "盗窃罪"
    case fraud = "诈骗罪"
    case assault = "故意伤害"
    case drugCrime = "毒品犯罪"
    case economicCrime = "经济犯罪"
    case cyberCrime = "网络犯罪"
    case trafficCrime = "交通肇事"
    case corruptionCrime = "贪污受贿"
    case violentCrime = "暴力犯罪"
    case criminalDefense = "刑事辩护"
    case otherCriminal = "其他刑事"
    
    // 行政案件
    case administrativeDispute = "行政争议"
    
    // 其他
    case other = "其他"
    
    var category: CaseCategory {
        switch self {
        case .contractDispute, .divorceDispute, .tradingDispute, .propertyDispute, 
             .intellectualProperty, .laborDispute, .trafficAccident, .medicalDispute,
             .neighborDispute, .inheritanceDispute, .debtDispute, .personalInjury:
            return .civil
        case .theft, .fraud, .assault, .drugCrime, .economicCrime, .cyberCrime,
             .trafficCrime, .corruptionCrime, .violentCrime, .criminalDefense, .otherCriminal:
            return .criminal
        case .administrativeDispute:
            return .administrative
        case .other:
            return .civil
        }
    }
    
    var icon: String {
        switch self {
        // 民事案件图标
        case .contractDispute: return "doc.text.fill"
        case .divorceDispute: return "heart.slash.fill"
        case .tradingDispute: return "cart.fill"
        case .propertyDispute: return "house.fill"
        case .intellectualProperty: return "lightbulb.fill"
        case .laborDispute: return "person.fill.and.arrow.left.and.arrow.right"
        case .trafficAccident: return "car.fill"
        case .medicalDispute: return "cross.case.fill"
        case .neighborDispute: return "building.2.fill"
        case .inheritanceDispute: return "person.3.fill"
        case .debtDispute: return "creditcard.fill"
        case .personalInjury: return "bandage.fill"
        
        // 刑事案件图标
        case .theft: return "hand.raised.slash.fill"
        case .fraud: return "exclamationmark.triangle.fill"
        case .assault: return "figure.wave"
        case .drugCrime: return "pills.fill"
        case .economicCrime: return "dollarsign.circle.fill"
        case .cyberCrime: return "wifi.exclamationmark"
        case .trafficCrime: return "car.side.and.exclamationmark.fill"
        case .corruptionCrime: return "banknote.fill"
        case .violentCrime: return "exclamationmark.shield.fill"
        case .criminalDefense: return "scale.3d"
        case .otherCriminal: return "questionmark.square.fill"
        
        // 行政案件图标
        case .administrativeDispute: return "building.columns.fill"
        
        // 其他
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    // 根据分类获取对应的案件类型
    static func typesForCategory(_ category: CaseCategory) -> [CaseType] {
        return CaseType.allCases.filter { $0.category == category }
    }
}

enum CaseStatus: String, Codable {
    case active = "进行中"
    case completed = "已完成"
    case archived = "已归档"
}

enum NewsCategory: String, Codable, CaseIterable {
    case latestLaws = "最新法规"
    case hotCases = "热门案例"
    case legalExplain = "法律解读"
}

// MARK: - API Error Handling

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case unauthorized
    case rateLimited
    case serverError(message: String)
    case networkUnavailable
    case timeout
    case serverColdStart  // 新增：服务器冷启动

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .requestFailed(let error):
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    return "网络连接不可用，请检查网络设置"
                case .timedOut:
                    return "请求超时，请稍后重试"
                case .networkConnectionLost:
                    return "网络连接已断开"
                case .cannotFindHost, .dnsLookupFailed:
                    return "无法连接到服务器"
                default:
                    return "网络请求失败: \(error.localizedDescription)"
                }
            }
            return "请求失败: \(error.localizedDescription)"
        case .invalidResponse:
            return "服务器响应格式错误"
        case .decodingError:
            return "数据解析失败"
        case .unauthorized:
            return "登录已过期，请重新登录"
        case .rateLimited:
            return "请求过于频繁，请稍后重试"
        case .serverError(let message):
            return message.isEmpty ? "服务器内部错误" : message
        case .networkUnavailable:
            return "网络不可用，请检查网络连接"
        case .timeout:
            return "请求超时，请稍后重试"
        case .serverColdStart:
            return "服务器正在启动中，请稍等片刻后重试"
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .networkUnavailable, .timeout, .rateLimited, .serverError, .serverColdStart:
            return true
        case .unauthorized:
            return false // 需要重新登录
        case .invalidURL, .decodingError, .invalidResponse:
            return false // 客户端错误
        case .requestFailed(let error):
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                    return true
                default:
                    return false
                }
            }
            return false
        }
    }
}

// MARK: - Membership System

enum MembershipLevel: String, Codable, CaseIterable {
    case basic = "免费版"
    case standard = "标准版"
    case professional = "专业版"
    case enterprise = "企业版"
    
    var price: Double {
        switch self {
        case .basic: return 0
        case .standard: return 29
        case .professional: return 99
        case .enterprise: return 299
        }
    }
    
    var dailyConsultationLimit: Int {
        switch self {
        case .basic: return 10
        case .standard: return 50
        case .professional: return -1 // 无限制
        case .enterprise: return -1
        }
    }
    
    var caseLimit: Int {
        switch self {
        case .basic: return 0
        case .standard: return 1
        case .professional: return -1 // 无限制
        case .enterprise: return -1
        }
    }
    
    var features: [String] {
        switch self {
        case .basic:
            return ["每日10次基础AI咨询", "不能创建案件", "基础法律资讯浏览", "可单独购买咨询次数或案件"]
        case .standard:
            return ["每日50次AI咨询", "创建最多1个案件", "详细案件分析报告", "基础法律文书生成", "优先客服支持", "可单独购买咨询次数或案件"]
        case .professional:
            return ["无限次AI咨询", "无限案件创建", "全功能分析报告", "专业法律文书生成", "每月2次专家律师咨询", "案件风险评估", "法律法规更新推送", "数据导出功能"]
        case .enterprise:
            return ["多用户管理(最多10人)", "专属客户经理", "每月10次专家律师咨询", "定制化解决方案", "API接入权限", "企业数据安全保障", "培训服务支持"]
        }
    }
    
    var color: Color {
        switch self {
        case .basic: return .gray
        case .standard: return .blue
        case .professional: return .purple
        case .enterprise: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .basic: return "person.circle"
        case .standard: return "star.circle"
        case .professional: return "crown.fill"
        case .enterprise: return "building.2.fill"
        }
    }
}

struct PaidService: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let type: ServiceType
    
    enum ServiceType: String, Codable {
        case analysis = "案件分析"
        case document = "文书生成"
        case consultation = "专家咨询"
        case riskAssessment = "风险评估"
        case extraConsultations = "额外咨询次数"
        case caseSlot = "案件名额"
    }
    
    // 单独购买服务配置
    static let availableServices: [PaidService] = [
        PaidService(id: "consultation_10", name: "10次咨询", description: "额外增加10次AI咨询机会", price: 9.9, type: .extraConsultations),
        PaidService(id: "consultation_50", name: "50次咨询", description: "额外增加50次AI咨询机会", price: 39.9, type: .extraConsultations),
        PaidService(id: "case_1", name: "1个案件名额", description: "增加1个案件创建名额", price: 19.9, type: .caseSlot),
        PaidService(id: "case_3", name: "3个案件名额", description: "增加3个案件创建名额", price: 49.9, type: .caseSlot),
        PaidService(id: "analysis", name: "详细案件分析", description: "获得专业的案件分析报告", price: 19.9, type: .analysis),
        PaidService(id: "document", name: "法律文书生成", description: "生成专业法律文书", price: 39.9, type: .document),
        PaidService(id: "expert", name: "专家律师咨询", description: "1小时专业律师一对一咨询", price: 199.9, type: .consultation),
        PaidService(id: "risk", name: "案件风险评估", description: "专业的风险评估和建议", price: 29.9, type: .riskAssessment)
    ]
}

struct UserSubscription: Codable {
    let id: String
    let userId: String
    let membershipLevel: MembershipLevel
    let startDate: Date
    let endDate: Date
    let isActive: Bool
    let autoRenew: Bool
}

// MARK: - Sample Data

class SampleData {
    static let messages: [Message] = [
        Message(id: "1", 
                content: "您好，我是IA法律顾问。请问您遇到了什么法律问题？", 
                createdAt: Date().addingTimeInterval(-3600), 
                isFromAI: true),
        Message(id: "2", 
                content: "我和邻居有一个土地边界纠纷，对方占用了我的土地。", 
                createdAt: Date().addingTimeInterval(-3500), 
                isFromAI: false),
        Message(id: "3", 
                content: "了解了。请问您有相关的土地权属证明文件吗？例如土地使用权证、宅基地使用证或其他产权证明。", 
                createdAt: Date().addingTimeInterval(-3400), 
                isFromAI: true)
    ]
    
    static let cases: [Case] = [
        Case(id: "1", 
             title: "邻居土地纠纷", 
             description: "与张姓邻居的土地边界争议，涉及约20平方米区域", 
             createdAt: Date().addingTimeInterval(-86400), 
             lastUpdatedAt: Date().addingTimeInterval(-3600), 
             caseType: .neighborDispute, 
             status: .active, 
             messages: messages),
        Case(id: "2", 
             title: "劳动合同纠纷", 
             description: "公司未按合同支付加班费，且存在不合理调岗", 
             createdAt: Date().addingTimeInterval(-86400*3), 
             lastUpdatedAt: Date().addingTimeInterval(-86400), 
             caseType: .laborDispute, 
             status: .active, 
             messages: [])
    ]
    
    static let newsItems: [NewsItem] = [
        NewsItem(id: "1", 
                 title: "最高法：明确不动产登记错误纠正程序", 
                 summary: "最高人民法院发布司法解释，明确不动产登记错误纠正程序，保护善意第三人合法权益。", 
                 imageUrl: nil, 
                 publishDate: Date().addingTimeInterval(-86400), 
                 source: "最高人民法院", 
                 url: "https://example.com", 
                 category: .latestLaws),
        NewsItem(id: "2", 
                 title: "商标侵权案例：某知名品牌胜诉获赔500万", 
                 summary: "法院判决被告停止侵权并赔偿原告经济损失及合理开支共计500万元。", 
                 imageUrl: nil, 
                 publishDate: Date().addingTimeInterval(-86400*2), 
                 source: "人民法院报", 
                 url: "https://example.com", 
                 category: .hotCases)
    ]
} 
