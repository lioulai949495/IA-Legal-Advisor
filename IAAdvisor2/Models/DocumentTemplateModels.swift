import Foundation
import SwiftUI

// MARK: - Document Template Models

/// 增强的文档模板系统
struct EnhancedDocumentTemplate: Identifiable, Codable {
    let id: String
    let name: String
    let category: DocumentTemplateCategory
    let templateType: TemplateType
    let version: String
    let description: String
    let applicableCaseTypes: [CaseType]
    var content: DocumentContent
    var metadata: TemplateMetadata
    let fillableFields: [EnhancedFillableField]
    let validationRules: [ValidationRule]
    let generationSettings: DocumentGenerationSettings
    let createdAt: Date
    var updatedAt: Date
    
    /// 检查模板是否适用于指定案件类型
    func isApplicableFor(_ caseType: CaseType) -> Bool {
        return applicableCaseTypes.contains(caseType) || applicableCaseTypes.isEmpty
    }
    
    /// 获取必填字段
    var requiredFields: [EnhancedFillableField] {
        return fillableFields.filter { $0.isRequired }
    }
    
    /// 获取可选字段
    var optionalFields: [EnhancedFillableField] {
        return fillableFields.filter { !$0.isRequired }
    }
}

/// 文档模板类别
enum DocumentTemplateCategory: String, Codable, CaseIterable {
    case legalPleading = "法律文书"
    case evidence = "证据材料"
    case contract = "合同协议"
    case application = "申请书"
    case response = "答辩书"
    case motion = "动议书"
    case analysis = "分析报告"
    case strategy = "策略文档"
    case checklist = "检查清单"
    case guideline = "操作指南"
    
    var icon: String {
        switch self {
        case .legalPleading: return "doc.text.fill"
        case .evidence: return "folder.badge.gear"
        case .contract: return "doc.on.doc.fill"
        case .application: return "square.and.pencil"
        case .response: return "arrowshape.turn.up.left.fill"
        case .motion: return "hand.raised.fill"
        case .analysis: return "chart.bar.doc.horizontal"
        case .strategy: return "map.fill"
        case .checklist: return "checklist"
        case .guideline: return "book.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .legalPleading: return .blue
        case .evidence: return .green
        case .contract: return .purple
        case .application: return .orange
        case .response: return .yellow
        case .motion: return .red
        case .analysis: return .indigo
        case .strategy: return .teal
        case .checklist: return .mint
        case .guideline: return .cyan
        }
    }
}

/// 模板类型
enum TemplateType: String, Codable {
    case staticTemplate = "静态模板"
    case dynamic = "动态模板"
    case aiGenerated = "AI生成"
    case userCustom = "用户自定义"
    case smart = "智能模板"
    
    var description: String {
        switch self {
        case .staticTemplate:
            return "固定格式的标准模板"
        case .dynamic:
            return "根据输入动态调整的模板"
        case .aiGenerated:
            return "AI智能生成的个性化模板"
        case .userCustom:
            return "用户自定义创建的模板"
        case .smart:
            return "自适应的智能模板"
        }
    }
}

/// 文档内容
struct DocumentContent: Codable {
    var templateBody: String
    var sections: [DocumentSection]
    var formatting: DocumentFormatting
    var layout: DocumentLayout
    var assets: [DocumentAsset]
    
    /// 获取纯文本内容
    var plainTextContent: String {
        return templateBody.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
    
    /// 获取字符数
    var characterCount: Int {
        return plainTextContent.count
    }
}

/// 文档章节
struct DocumentSection: Identifiable, Codable {
    let id: String
    let title: String
    var content: String
    let sectionType: SectionType
    let order: Int
    var isRequired: Bool
    var conditional: ConditionalLogic?
    
    enum SectionType: String, Codable {
        case header = "页眉"
        case footer = "页脚"
        case title = "标题"
        case paragraph = "段落"
        case list = "列表"
        case table = "表格"
        case signature = "签名区"
        case appendix = "附录"
    }
}

/// 条件逻辑
struct ConditionalLogic: Codable {
    let condition: String
    let showWhen: ConditionalOperator
    let dependsOn: [String] // 依赖的字段ID
    
    enum ConditionalOperator: String, Codable {
        case equals = "等于"
        case notEquals = "不等于"
        case contains = "包含"
        case greaterThan = "大于"
        case lessThan = "小于"
        case isEmpty = "为空"
        case isNotEmpty = "不为空"
    }
}

/// 文档格式化
struct DocumentFormatting: Codable {
    var fontFamily: String
    var fontSize: Double
    var lineSpacing: Double
    var paragraphSpacing: Double
    var margins: DocumentMargins
    var alignment: TextAlignment
    var style: DocumentStyle
    
    enum TextAlignment: String, Codable {
        case left = "左对齐"
        case center = "居中"
        case right = "右对齐"
        case justified = "两端对齐"
    }
    
    enum DocumentStyle: String, Codable {
        case formal = "正式"
        case business = "商务"
        case academic = "学术"
        case legal = "法律"
        case casual = "日常"
    }
}

/// 文档边距
struct DocumentMargins: Codable {
    var top: Double
    var bottom: Double
    var left: Double
    var right: Double
}

/// 文档布局
struct DocumentLayout: Codable {
    var pageSize: PageSize
    var orientation: PageOrientation
    var columns: Int
    var headerHeight: Double
    var footerHeight: Double
    
    enum PageSize: String, Codable {
        case a4 = "A4"
        case a3 = "A3"
        case letter = "Letter"
        case legal = "Legal"
        case custom = "自定义"
    }
    
    enum PageOrientation: String, Codable {
        case portrait = "纵向"
        case landscape = "横向"
    }
}

/// 文档资源
struct DocumentAsset: Identifiable, Codable {
    let id: String
    let name: String
    let assetType: AssetType
    let url: String?
    let data: Data?
    let description: String
    
    enum AssetType: String, Codable {
        case image = "图片"
        case logo = "标志"
        case signature = "签名"
        case seal = "印章"
        case attachment = "附件"
    }
}

/// 模板元数据
struct TemplateMetadata: Codable {
    var author: String
    var organization: String?
    var jurisdiction: String? // 适用法域
    var language: String
    var tags: [String]
    var usageCount: Int
    var rating: Double // 0.0 - 5.0
    var reviews: [TemplateReview]
    var lastUsed: Date?
    var isOfficial: Bool // 是否为官方模板
    var compliance: ComplianceInfo?
}

/// 模板评价
struct TemplateReview: Identifiable, Codable {
    let id: String
    let userId: String
    let rating: Int // 1-5
    let comment: String?
    let createdAt: Date
    let helpful: Int // 有用票数
}

/// 合规信息
struct ComplianceInfo: Codable {
    let standards: [String] // 符合的标准
    let certifications: [String] // 认证信息
    let lastAudit: Date?
    let auditResults: String?
    let expiryDate: Date?
}

/// 增强的可填写字段
struct EnhancedFillableField: Identifiable, Codable {
    let id: String
    var fieldName: String
    var displayName: String
    let fieldType: FieldType
    var isRequired: Bool
    var placeholder: String
    var helpText: String?
    var defaultValue: String?
    var validationRules: [ValidationRule]
    var options: [FieldOption]? // 用于选择类型字段
    var formatting: FieldFormatting
    var positioning: FieldPosition
    var behavior: FieldBehavior
    var accessibility: FieldAccessibility
    
    enum FieldType: String, Codable {
        case text = "文本"
        case number = "数字"
        case decimal = "小数"
        case currency = "货币"
        case date = "日期"
        case time = "时间"
        case datetime = "日期时间"
        case email = "邮箱"
        case phone = "电话"
        case url = "网址"
        case password = "密码"
        case textarea = "多行文本"
        case richtext = "富文本"
        case dropdown = "下拉选择"
        case radio = "单选"
        case checkbox = "复选框"
        case multiselect = "多选"
        case file = "文件"
        case image = "图片"
        case signature = "签名"
        case seal = "印章"
        case barcode = "条形码"
        case qrcode = "二维码"
        case calculation = "计算字段"
        case reference = "引用字段"
    }
    
    /// 获取字段的输入组件类型
    var inputComponent: InputComponentType {
        switch fieldType {
        case .text, .email, .phone, .url, .password:
            return .textField
        case .number, .decimal, .currency:
            return .numericField
        case .date, .time, .datetime:
            return .datePicker
        case .textarea:
            return .textArea
        case .richtext:
            return .richTextEditor
        case .dropdown:
            return .dropdown
        case .radio:
            return .radioGroup
        case .checkbox:
            return .checkboxGroup
        case .multiselect:
            return .multiSelectList
        case .file, .image:
            return .filePicker
        case .signature:
            return .signaturePad
        case .seal:
            return .sealPad
        case .calculation:
            return .calculatedField
        case .reference:
            return .referenceField
        default:
            return .textField
        }
    }
    
    enum InputComponentType {
        case textField
        case numericField
        case datePicker
        case textArea
        case richTextEditor
        case dropdown
        case radioGroup
        case checkboxGroup
        case multiSelectList
        case filePicker
        case signaturePad
        case sealPad
        case calculatedField
        case referenceField
    }
}

/// 字段选项
struct FieldOption: Identifiable, Codable {
    let id: String
    let label: String
    let value: String
    var isDefault: Bool
    var condition: ConditionalLogic?
}

/// 字段格式化
struct FieldFormatting: Codable {
    var mask: String? // 输入掩码
    var pattern: String? // 格式化模式
    var prefix: String? // 前缀
    var suffix: String? // 后缀
    var uppercase: Bool // 是否转大写
    var lowercase: Bool // 是否转小写
    var trim: Bool // 是否去空格
}

/// 字段位置
struct FieldPosition: Codable {
    var x: Double // 相对位置X (0-1)
    var y: Double // 相对位置Y (0-1)
    var width: Double // 宽度 (0-1)
    var height: Double // 高度 (0-1)
    var page: Int // 页码
    var section: String? // 章节ID
    var order: Int // 排序
}

/// 字段行为
struct FieldBehavior: Codable {
    var readOnly: Bool
    var hidden: Bool
    var autoFocus: Bool
    var clearOnEdit: Bool
    var autoComplete: String?
    var dependencies: [FieldDependency]
    var calculations: [FieldCalculation]?
    var validationTrigger: ValidationTrigger
    
    enum ValidationTrigger: String, Codable {
        case onChange = "值改变时"
        case onBlur = "失焦时"
        case onSubmit = "提交时"
        case realTime = "实时"
    }
}

/// 字段依赖
struct FieldDependency: Codable {
    let dependsOnFieldId: String
    let condition: ConditionalLogic
    let action: DependencyAction
    
    enum DependencyAction: String, Codable {
        case show = "显示"
        case hide = "隐藏"
        case enable = "启用"
        case disable = "禁用"
        case setValue = "设置值"
        case clearValue = "清空值"
        case validate = "验证"
    }
}

/// 字段计算
struct FieldCalculation: Codable {
    let formula: String
    let dependsOnFields: [String]
    let calculationType: CalculationType
    
    enum CalculationType: String, Codable {
        case sum = "求和"
        case average = "平均值"
        case count = "计数"
        case min = "最小值"
        case max = "最大值"
        case formula = "公式"
        case lookup = "查找"
    }
}

/// 字段无障碍访问
struct FieldAccessibility: Codable {
    var ariaLabel: String?
    var ariaDescription: String?
    var tabIndex: Int
    var role: String?
    var screenReaderText: String?
}

/// 验证规则
struct ValidationRule: Identifiable, Codable {
    let id: String
    let ruleType: ValidationRuleType
    let parameter: String?
    let errorMessage: String
    let severity: ValidationSeverity
    
    enum ValidationRuleType: String, Codable {
        case required = "必填"
        case minLength = "最小长度"
        case maxLength = "最大长度"
        case pattern = "正则表达式"
        case range = "数值范围"
        case email = "邮箱格式"
        case phone = "电话格式"
        case url = "网址格式"
        case date = "日期格式"
        case custom = "自定义验证"
        case uniqueness = "唯一性"
        case crossField = "跨字段验证"
    }
    
    enum ValidationSeverity: String, Codable {
        case error = "错误"
        case warning = "警告"
        case info = "提示"
    }
}

/// 文档生成设置
struct DocumentGenerationSettings: Codable {
    var outputFormat: OutputFormat
    var quality: GenerationQuality
    var watermark: WatermarkSettings?
    var security: SecuritySettings?
    var metadata: GenerationMetadata
    var postProcessing: PostProcessingOptions
    
    enum OutputFormat: String, Codable {
        case pdf = "PDF"
        case docx = "DOCX"
        case html = "HTML"
        case rtf = "RTF"
        case txt = "TXT"
        case odt = "ODT"
    }
    
    enum GenerationQuality: String, Codable {
        case draft = "草稿"
        case standard = "标准"
        case high = "高质量"
        case print = "印刷质量"
    }
}

/// 水印设置
struct WatermarkSettings: Codable {
    var text: String?
    var image: String? // 图片URL或base64
    var opacity: Double // 0.0 - 1.0
    var position: WatermarkPosition
    var rotation: Double // 角度
    var size: Double // 相对大小
    
    enum WatermarkPosition: String, Codable {
        case center = "居中"
        case topLeft = "左上"
        case topRight = "右上"
        case bottomLeft = "左下"
        case bottomRight = "右下"
        case diagonal = "对角"
        case repeatPattern = "重复"
    }
}

/// 安全设置
struct SecuritySettings: Codable {
    var passwordProtection: PasswordSettings?
    var permissions: DocumentPermissions
    var digitalSignature: DigitalSignatureSettings?
    var encryption: EncryptionSettings?
    
    struct PasswordSettings: Codable {
        var openPassword: String?
        var editPassword: String?
        var passwordStrength: PasswordStrength
        
        enum PasswordStrength: String, Codable {
            case weak = "弱"
            case medium = "中"
            case strong = "强"
        }
    }
    
    struct DocumentPermissions: Codable {
        var allowPrint: Bool
        var allowCopy: Bool
        var allowEdit: Bool
        var allowAnnotations: Bool
        var allowFillForms: Bool
        var allowAssembly: Bool
        var allowScreenReading: Bool
    }
    
    struct DigitalSignatureSettings: Codable {
        var enabled: Bool
        var certificatePath: String?
        var signatureReason: String?
        var signatureLocation: String?
        var timestampServer: String?
    }
    
    struct EncryptionSettings: Codable {
        var algorithm: EncryptionAlgorithm
        var keyLength: Int
        
        enum EncryptionAlgorithm: String, Codable {
            case aes128 = "AES-128"
            case aes256 = "AES-256"
            case rc4 = "RC4"
        }
    }
}

/// 生成元数据
struct GenerationMetadata: Codable {
    var includeMetadata: Bool
    var author: String?
    var title: String?
    var subject: String?
    var keywords: [String]
    var creator: String
    var producer: String
    var creationDate: Date
    var modificationDate: Date
    var customProperties: [String: String]
}

/// 后处理选项
struct PostProcessingOptions: Codable {
    var autoSave: Bool
    var backup: Bool
    var versioning: Bool
    var notification: NotificationSettings?
    var integration: IntegrationSettings?
    
    struct NotificationSettings: Codable {
        var email: Bool
        var sms: Bool
        var push: Bool
        var webhook: String?
    }
    
    struct IntegrationSettings: Codable {
        var cloudStorage: CloudStorageSettings?
        var documentManagement: DocumentManagementSettings?
        
        struct CloudStorageSettings: Codable {
            var provider: String
            var folder: String
            var autoUpload: Bool
        }
        
        struct DocumentManagementSettings: Codable {
            var systemType: String
            var apiEndpoint: String
            var autoIndex: Bool
        }
    }
}

// MARK: - Template Management

/// 模板管理器
protocol TemplateManager {
    func getTemplate(id: String) async throws -> EnhancedDocumentTemplate?
    func getTemplatesForCaseType(_ caseType: CaseType) async throws -> [EnhancedDocumentTemplate]
    func createTemplate(_ template: EnhancedDocumentTemplate) async throws -> String
    func updateTemplate(_ template: EnhancedDocumentTemplate) async throws
    func deleteTemplate(id: String) async throws
    func validateTemplate(_ template: EnhancedDocumentTemplate) async throws -> ValidationResult
    func generateDocument(templateId: String, fieldValues: [String: Any]) async throws -> GeneratedDocument
}

/// 生成的文档
struct GeneratedDocument: Identifiable, Codable {
    let id: String
    let templateId: String
    let content: Data
    let format: DocumentGenerationSettings.OutputFormat
    let metadata: GeneratedDocumentMetadata
    let generatedAt: Date
    var downloadURL: String?
    var isTemporary: Bool
    var expiresAt: Date?
}

/// 生成文档的元数据
struct GeneratedDocumentMetadata: Codable {
    let templateVersion: String
    let fieldValues: [String: String]
    let generationSettings: DocumentGenerationSettings
    let fileSize: Int64
    let pageCount: Int?
    let checksum: String
}

/// 验证结果
struct ValidationResult: Codable {
    let isValid: Bool
    let errors: [ValidationError]
    let warnings: [ValidationWarning]
    let suggestions: [ValidationSuggestion]
    
    struct ValidationError: Identifiable, Codable {
        let id: String
        let field: String?
        let message: String
        let code: String
    }
    
    struct ValidationWarning: Identifiable, Codable {
        let id: String
        let field: String?
        let message: String
        let code: String
    }
    
    struct ValidationSuggestion: Identifiable, Codable {
        let id: String
        let field: String?
        let message: String
        let improvement: String
    }
}

// MARK: - Extensions

extension EnhancedDocumentTemplate {
    /// 检查模板是否需要更新
    func needsUpdate() -> Bool {
        let daysSinceUpdate = Calendar.current.dateComponents([.day], from: updatedAt, to: Date()).day ?? 0
        return daysSinceUpdate > 30 && metadata.usageCount > 100
    }
    
    /// 获取模板复杂度评分
    func complexityScore() -> TemplateComplexity {
        let fieldCount = fillableFields.count
        let validationCount = validationRules.count
        let sectionCount = content.sections.count
        
        let score = fieldCount + validationCount * 2 + sectionCount
        
        switch score {
        case 0...5: return .simple
        case 6...15: return .moderate
        case 16...30: return .complex
        default: return .veryComplex
        }
    }
    
    enum TemplateComplexity: String {
        case simple = "简单"
        case moderate = "中等"
        case complex = "复杂"
        case veryComplex = "非常复杂"
        
        var color: Color {
            switch self {
            case .simple: return .green
            case .moderate: return .yellow
            case .complex: return .orange
            case .veryComplex: return .red
            }
        }
    }
}

extension EnhancedFillableField {
    /// 验证字段值
    func validate(value: String?) -> [ValidationResult.ValidationError] {
        var errors: [ValidationResult.ValidationError] = []
        
        // 检查必填字段
        if isRequired && (value?.isEmpty ?? true) {
            errors.append(ValidationResult.ValidationError(
                id: UUID().uuidString,
                field: fieldName,
                message: "此字段为必填项",
                code: "REQUIRED_FIELD"
            ))
        }
        
        guard let value = value, !value.isEmpty else {
            return errors
        }
        
        // 应用验证规则
        for rule in validationRules {
            switch rule.ruleType {
            case .minLength:
                if let minLength = Int(rule.parameter ?? "0"), value.count < minLength {
                    errors.append(ValidationResult.ValidationError(
                        id: UUID().uuidString,
                        field: fieldName,
                        message: rule.errorMessage,
                        code: "MIN_LENGTH"
                    ))
                }
            case .maxLength:
                if let maxLength = Int(rule.parameter ?? "100"), value.count > maxLength {
                    errors.append(ValidationResult.ValidationError(
                        id: UUID().uuidString,
                        field: fieldName,
                        message: rule.errorMessage,
                        code: "MAX_LENGTH"
                    ))
                }
            case .pattern:
                if let pattern = rule.parameter {
                    let regex = try? NSRegularExpression(pattern: pattern)
                    let range = NSRange(location: 0, length: value.utf16.count)
                    if regex?.firstMatch(in: value, options: [], range: range) == nil {
                        errors.append(ValidationResult.ValidationError(
                            id: UUID().uuidString,
                            field: fieldName,
                            message: rule.errorMessage,
                            code: "PATTERN_MISMATCH"
                        ))
                    }
                }
            case .email:
                let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
                let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegex)
                if !emailTest.evaluate(with: value) {
                    errors.append(ValidationResult.ValidationError(
                        id: UUID().uuidString,
                        field: fieldName,
                        message: rule.errorMessage,
                        code: "INVALID_EMAIL"
                    ))
                }
            default:
                break
            }
        }
        
        return errors
    }
}