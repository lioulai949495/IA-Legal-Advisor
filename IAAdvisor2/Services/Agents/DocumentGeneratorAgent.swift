import Foundation

/// 文档生成代理 - 专门生成各类法律文档和合同
class DefaultDocumentGeneratorAgent: DocumentGeneratorAgent {
    
    // MARK: - AIAgent Properties
    let id: String = "document-generator-001"
    let name: String = "文档生成器"
    let description: String = "专业的法律文档生成代理，可生成各类法律文书、合同和法律文档"
    let agentType: AgentType = .documentGenerator
    let specializations: [String] = [
        "起诉书生成", "合同起草", "法律函件", 
        "答辩书生成", "申请书制作", "协议书起草"
    ]
    var isActive: Bool = true
    
    // MARK: - Private Properties
    private let apiService: APIService
    private let documentTemplates: DocumentTemplateManager
    
    // MARK: - Initialization
    init(apiService: APIService = .shared) {
        self.apiService = apiService
        self.documentTemplates = DocumentTemplateManager()
    }
    
    // MARK: - AIAgent Methods
    
    func processRequest(_ request: AgentRequest) async throws -> AgentResponse {
        let startTime = Date()
        
        guard canHandle(request.caseType ?? .contractDispute) else {
            throw AgentError.unsupportedCaseType(request.caseType?.rawValue ?? "未知")
        }
        
        do {
            // 解析文档生成请求
            let documentRequest = parseDocumentRequest(request)
            
            // 生成文档
            let generatedDocument = try await generateDocumentContent(documentRequest)
            
            // 创建响应
            let attachments = [AgentAttachment(
                id: "generated-document",
                name: generatedDocument.title,
                type: .document,
                url: nil,
                content: generatedDocument.content,
                size: Int64(generatedDocument.content.count)
            )]
            
            let recommendations = generateDocumentRecommendations(for: generatedDocument)
            let followUpQuestions = generateDocumentFollowUp(for: documentRequest.type)
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            return AgentResponse(
                id: UUID().uuidString,
                requestId: request.id,
                agentId: id,
                content: formatDocumentResponse(generatedDocument),
                confidence: calculateDocumentConfidence(generatedDocument),
                recommendations: recommendations,
                attachments: attachments,
                followUpQuestions: followUpQuestions,
                createdAt: Date(),
                processingTime: processingTime
            )
            
        } catch {
            throw AgentError.processingFailed("文档生成失败: \(error.localizedDescription)")
        }
    }
    
    func canHandle(_ caseType: CaseType) -> Bool {
        // 文档生成器可以处理大部分案件类型
        return true
    }
    
    // MARK: - DocumentGeneratorAgent Methods
    
    func generateDocument(type: LegalDocumentType, parameters: [String: Any]) async throws -> AgentGeneratedDocument {
        let documentRequest = AgentDocumentGenerationRequest(
            type: type,
            parameters: parameters,
            template: documentTemplates.getTemplate(for: type),
            context: nil
        )
        
        return try await generateDocumentContent(documentRequest)
    }
    
    func generateContract(type: ContractType, terms: ContractTerms) async throws -> AgentGeneratedDocument {
        let parameters = convertContractTermsToParameters(terms)
        let documentRequest = AgentDocumentGenerationRequest(
            type: .contract,
            parameters: parameters,
            template: documentTemplates.getContractTemplate(for: type),
            context: nil // 简化处理，不使用特殊的合同上下文
        )
        
        return try await generateDocumentContent(documentRequest)
    }
    
    // MARK: - Private Helper Methods
    
    private func parseDocumentRequest(_ request: AgentRequest) -> AgentDocumentGenerationRequest {
        // 从请求内容中解析文档类型和参数
        let documentType = determineDocumentType(from: request)
        let parameters = extractParameters(from: request)
        let template = documentTemplates.getTemplate(for: documentType)
        
        return AgentDocumentGenerationRequest(
            type: documentType,
            parameters: parameters,
            template: template,
            context: request.context
        )
    }
    
    private func generateDocumentContent(_ request: AgentDocumentGenerationRequest) async throws -> AgentGeneratedDocument {
        // 构建文档生成提示
        let prompt = buildDocumentGenerationPrompt(request)
        
        // 调用API生成文档内容
        let chatResponse = try await apiService.sendChatMessage(
            category: "文档生成",
            role: "法律文书专家",
            subtype: request.type.rawValue,
            message: prompt
        )
        
        // 后处理文档内容
        let processedContent = postProcessDocumentContent(
            chatResponse.analysis_report.next_steps.process_guidance,
            type: request.type,
            template: request.template
        )
        
        // 创建文档元数据
        let metadata = createDocumentMetadata(for: request)
        
        return AgentGeneratedDocument(
            id: UUID().uuidString,
            type: request.type,
            title: generateDocumentTitle(for: request.type, parameters: request.parameters),
            content: processedContent,
            metadata: metadata,
            templates: [request.template?.id ?? "default"],
            createdAt: Date()
        )
    }
    
    private func buildDocumentGenerationPrompt(_ request: AgentDocumentGenerationRequest) -> String {
        var prompt = """
        请生成一份专业的\(request.type.rawValue)文档。
        
        文档要求：
        - 格式规范，符合法律文书标准
        - 内容完整，逻辑清晰
        - 语言准确，表达严谨
        - 包含必要的法律条款和声明
        """
        
        // 添加模板指导
        if let template = request.template {
            prompt += "\n\n请参考以下模板结构：\n\(template.structure)"
        }
        
        // 添加参数信息
        if !request.parameters.isEmpty {
            prompt += "\n\n请使用以下信息：\n"
            for (key, value) in request.parameters {
                prompt += "- \(key): \(value)\n"
            }
        }
        
        // 添加上下文信息
        if let context = request.context {
            if let caseDetails = context.caseDetails {
                prompt += """
                
                案件背景：
                - 案件类型：\(caseDetails.caseType.rawValue)
                - 案件描述：\(caseDetails.description)
                - 当事人信息：\(caseDetails.involvedParties.map { "\($0.name)(\($0.role.rawValue))" }.joined(separator: ", "))
                """
            }
        }
        
        // 添加具体要求
        prompt += generateSpecificRequirements(for: request.type)
        
        return prompt
    }
    
    private func generateSpecificRequirements(for type: LegalDocumentType) -> String {
        switch type {
        case .complaint:
            return """
            
            起诉书应当包含：
            1. 原告和被告的基本信息
            2. 诉讼请求明确具体
            3. 事实和理由充分
            4. 证据清单完整
            5. 适用的法律条文
            6. 管辖法院信息
            """
            
        case .answer:
            return """
            
            答辩书应当包含：
            1. 答辩人基本信息
            2. 对起诉事实的认定或反驳
            3. 答辩理由和法律依据
            4. 反驳证据
            5. 管辖权异议（如有）
            """
            
        case .contract:
            return """
            
            合同应当包含：
            1. 合同当事人信息
            2. 合同标的明确
            3. 权利义务清晰
            4. 履约条件具体
            5. 违约责任明确
            6. 争议解决条款
            7. 合同生效条件
            """
            
        case .letter:
            return """
            
            律师函应当包含：
            1. 律师事务所和律师信息
            2. 事实陈述客观准确
            3. 法律分析专业
            4. 要求明确具体
            5. 法律后果提示
            6. 回复期限设定
            """
            
        case .motion:
            return """
            
            申请书应当包含：
            1. 申请人基本信息
            2. 申请事项明确
            3. 申请理由充分
            4. 法律依据准确
            5. 证据材料清单
            """
            
        default:
            return "\n\n请确保文档格式专业，内容完整准确。"
        }
    }
    
    private func postProcessDocumentContent(
        _ content: String,
        type: LegalDocumentType,
        template: AgentDocumentTemplate?
    ) -> String {
        var processedContent = content
        
        // 格式化处理
        processedContent = formatDocumentStructure(processedContent, type: type)
        
        // 添加标准条款
        processedContent = addStandardClauses(processedContent, type: type)
        
        // 验证必要元素
        processedContent = validateAndCorrectDocument(processedContent, type: type)
        
        return processedContent
    }
    
    private func formatDocumentStructure(_ content: String, type: LegalDocumentType) -> String {
        // 根据文档类型添加标准格式
        switch type {
        case .complaint:
            return formatComplaintStructure(content)
        case .contract:
            return formatContractStructure(content)
        case .letter:
            return formatLetterStructure(content)
        default:
            return content
        }
    }
    
    private func formatComplaintStructure(_ content: String) -> String {
        var formatted = content
        
        // 确保包含标准起诉书结构
        if !formatted.contains("起诉书") {
            formatted = "起诉书\n\n" + formatted
        }
        
        // 添加标准结尾
        if !formatted.contains("此致") {
            formatted += "\n\n此致\n人民法院\n\n起诉人：\n日期：\(formatDate(Date()))"
        }
        
        return formatted
    }
    
    private func formatContractStructure(_ content: String) -> String {
        var formatted = content
        
        // 确保包含合同标题
        if !formatted.hasPrefix("合同") && !formatted.hasPrefix("协议") {
            formatted = "合同\n\n" + formatted
        }
        
        // 添加签字栏
        if !formatted.contains("甲方") || !formatted.contains("乙方") {
            formatted += "\n\n甲方（签字/盖章）：_______________  日期：___________\n"
            formatted += "乙方（签字/盖章）：_______________  日期：___________"
        }
        
        return formatted
    }
    
    private func formatLetterStructure(_ content: String) -> String {
        var formatted = content
        
        // 确保包含律师函标题
        if !formatted.contains("律师函") {
            formatted = "律师函\n\n" + formatted
        }
        
        // 添加律师事务所结尾
        if !formatted.contains("律师事务所") {
            formatted += "\n\n_______________律师事务所\n律师：_______________\n日期：\(formatDate(Date()))"
        }
        
        return formatted
    }
    
    private func addStandardClauses(_ content: String, type: LegalDocumentType) -> String {
        switch type {
        case .contract:
            return addContractStandardClauses(content)
        case .letter:
            return addLetterStandardClauses(content)
        default:
            return content
        }
    }
    
    private func addContractStandardClauses(_ content: String) -> String {
        var enhanced = content
        
        // 添加争议解决条款（如果没有）
        if !enhanced.contains("争议解决") && !enhanced.contains("仲裁") {
            enhanced += """
            
            第X条 争议解决
            本合同履行过程中发生的争议，双方应友好协商解决；协商不成的，可向合同签订地人民法院提起诉讼。
            """
        }
        
        // 添加合同生效条款
        if !enhanced.contains("生效") {
            enhanced += """
            
            第X条 合同生效
            本合同自双方签字（盖章）之日起生效。
            """
        }
        
        return enhanced
    }
    
    private func addLetterStandardClauses(_ content: String) -> String {
        var enhanced = content
        
        // 添加法律声明
        if !enhanced.contains("法律后果") {
            enhanced += """
            
            特此函告，如贵方不按要求履行相关义务，我方将依法追究贵方的法律责任。
            """
        }
        
        return enhanced
    }
    
    private func validateAndCorrectDocument(_ content: String, type: LegalDocumentType) -> String {
        // 基本验证和修正
        var corrected = content
        
        // 检查必要信息占位符
        corrected = corrected.replacingOccurrences(of: "[当事人姓名]", with: "_______________")
        corrected = corrected.replacingOccurrences(of: "[日期]", with: formatDate(Date()))
        corrected = corrected.replacingOccurrences(of: "[金额]", with: "人民币_______________元")
        
        return corrected
    }
    
    private func determineDocumentType(from request: AgentRequest) -> LegalDocumentType {
        let content = request.content.lowercased()
        
        if content.contains("起诉") || content.contains("诉状") {
            return .complaint
        } else if content.contains("答辩") {
            return .answer
        } else if content.contains("合同") || content.contains("协议") {
            return .contract
        } else if content.contains("律师函") || content.contains("函件") {
            return .letter
        } else if content.contains("申请") {
            return .motion
        } else if content.contains("和解") {
            return .settlement
        } else if content.contains("备忘录") {
            return .memo
        } else {
            return .brief
        }
    }
    
    private func extractParameters(from request: AgentRequest) -> [String: Any] {
        var parameters: [String: Any] = [:]
        
        // 基础参数
        parameters["content"] = request.content
        parameters["requestId"] = request.id
        parameters["priority"] = request.priority.rawValue
        
        // 从上下文提取参数
        if let context = request.context {
            if let caseDetails = context.caseDetails {
                parameters["caseTitle"] = caseDetails.title
                parameters["caseDescription"] = caseDetails.description
                parameters["caseType"] = caseDetails.caseType.rawValue
                parameters["parties"] = caseDetails.involvedParties.map { 
                    ["name": $0.name, "role": $0.role.rawValue]
                }
            }
            
            parameters["userId"] = context.userId
        }
        
        return parameters
    }
    
    private func convertContractTermsToParameters(_ terms: ContractTerms) -> [String: Any] {
        var parameters: [String: Any] = [:]
        
        parameters["parties"] = terms.parties.map { party in
            [
                "name": party.name,
                "type": party.type.rawValue,
                "address": party.address,
                "contact": party.contactInfo
            ]
        }
        
        parameters["subject"] = terms.subject
        parameters["terms"] = terms.terms
        parameters["duration"] = terms.duration ?? "待定"
        parameters["compensation"] = terms.compensation ?? "待定"
        parameters["obligations"] = terms.obligations
        parameters["conditions"] = terms.conditions
        
        return parameters
    }
    
    private func generateDocumentTitle(for type: LegalDocumentType, parameters: [String: Any]) -> String {
        let baseTitle = type.rawValue
        
        if let caseTitle = parameters["caseTitle"] as? String {
            return "\(caseTitle) - \(baseTitle)"
        } else if let subject = parameters["subject"] as? String {
            return "\(subject) - \(baseTitle)"
        } else {
            return baseTitle
        }
    }
    
    private func createDocumentMetadata(for request: AgentDocumentGenerationRequest) -> DocumentMetadata {
        return DocumentMetadata(
            author: "AI文档生成器",
            version: "1.0",
            jurisdiction: "中华人民共和国",
            language: "zh-CN",
            tags: generateDocumentTags(for: request.type),
            reviewStatus: .draft
        )
    }
    
    private func generateDocumentTags(for type: LegalDocumentType) -> [String] {
        let baseTags = ["AI生成", "法律文档"]
        
        switch type {
        case .complaint:
            return baseTags + ["起诉书", "民事诉讼"]
        case .answer:
            return baseTags + ["答辩书", "民事诉讼"]
        case .contract:
            return baseTags + ["合同", "协议"]
        case .letter:
            return baseTags + ["律师函", "法律函件"]
        case .motion:
            return baseTags + ["申请书", "法院申请"]
        case .settlement:
            return baseTags + ["和解协议", "争议解决"]
        case .memo:
            return baseTags + ["法律备忘录", "内部文档"]
        case .brief:
            return baseTags + ["法律简报", "案件分析"]
        }
    }
    
    private func calculateDocumentConfidence(_ document: AgentGeneratedDocument) -> Double {
        var confidence = 0.7 // 基础置信度
        
        // 根据文档完整性调整
        if document.content.count > 500 {
            confidence += 0.1
        }
        
        if document.content.contains("第") && document.content.contains("条") {
            confidence += 0.1 // 包含条款结构
        }
        
        if document.content.contains("法") || document.content.contains("规") {
            confidence += 0.1 // 包含法律术语
        }
        
        return min(1.0, confidence)
    }
    
    private func generateDocumentRecommendations(for document: AgentGeneratedDocument) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // 通用建议
        recommendations.append(Recommendation(
            id: "review-document",
            title: "专业审查",
            description: "建议请专业律师审查生成的文档，确保准确性和合规性",
            actionType: .consult,
            priority: .high,
            estimatedCost: 500,
            timeframe: "1-2天",
            requirements: ["专业律师", "文档审查"]
        ))
        
        // 文档特定建议
        switch document.type {
        case .contract:
            recommendations.append(Recommendation(
                id: "contract-negotiation",
                title: "合同谈判",
                description: "在签署前与对方就合同条款进行充分协商",
                actionType: .negotiate,
                priority: .medium,
                estimatedCost: 300,
                timeframe: "1周",
                requirements: ["双方协商意愿", "谈判要点准备"]
            ))
            
        case .complaint:
            recommendations.append(Recommendation(
                id: "evidence-preparation",
                title: "证据准备",
                description: "完善证据材料，确保支持诉讼请求",
                actionType: .investigate,
                priority: .high,
                estimatedCost: 800,
                timeframe: "2-3周",
                requirements: ["证据收集", "证据整理", "证人准备"]
            ))
            
        default:
            break
        }
        
        return recommendations
    }
    
    private func generateDocumentFollowUp(for type: LegalDocumentType) -> [String] {
        let commonQuestions = [
            "文档内容是否需要修改？",
            "是否需要生成其他相关文档？"
        ]
        
        let specificQuestions: [String]
        
        switch type {
        case .contract:
            specificQuestions = [
                "是否需要添加特殊条款？",
                "合同期限是否合适？",
                "违约责任条款是否需要调整？"
            ]
        case .complaint:
            specificQuestions = [
                "诉讼请求是否完整？",
                "是否需要增加证据清单？",
                "管辖法院选择是否正确？"
            ]
        case .letter:
            specificQuestions = [
                "律师函的语气是否合适？",
                "要求的期限是否合理？",
                "是否需要添加法律后果警告？"
            ]
        default:
            specificQuestions = [
                "文档格式是否符合要求？",
                "内容是否需要补充？"
            ]
        }
        
        return commonQuestions + specificQuestions
    }
    
    private func formatDocumentResponse(_ document: AgentGeneratedDocument) -> String {
        return """
        ## 文档生成完成
        
        **文档类型：** \(document.type.rawValue)
        **文档标题：** \(document.title)
        **生成时间：** \(formatDate(document.createdAt))
        **文档版本：** \(document.metadata.version)
        
        ### 文档预览
        \(document.content.prefix(300))...
        
        完整文档请查看附件。
        
        ### 注意事项
        - 此文档为AI生成，建议请专业律师审查
        - 请根据具体情况调整文档内容
        - 使用前请确认所有信息准确无误
        """
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

private struct AgentDocumentGenerationRequest {
    let type: LegalDocumentType
    let parameters: [String: Any]
    let template: AgentDocumentTemplate?
    let context: AgentContext?
}

// ContractContext 已移除，简化为使用通用的 AgentContext

private class DocumentTemplateManager {
    private var templates: [LegalDocumentType: AgentDocumentTemplate] = [:]
    private var contractTemplates: [ContractType: AgentDocumentTemplate] = [:]
    
    init() {
        loadDefaultTemplates()
    }
    
    func getTemplate(for type: LegalDocumentType) -> AgentDocumentTemplate? {
        return templates[type] ?? createDefaultTemplate(for: type)
    }
    
    func getContractTemplate(for type: ContractType) -> AgentDocumentTemplate? {
        return contractTemplates[type] ?? createDefaultContractTemplate(for: type)
    }
    
    private func loadDefaultTemplates() {
        // 加载默认模板
        templates[.complaint] = AgentDocumentTemplate(
            id: "complaint-template",
            name: "起诉书模板",
            structure: "标题-当事人-诉讼请求-事实理由-证据-结尾",
            requiredFields: ["原告", "被告", "诉讼请求", "事实", "证据"]
        )
        
        templates[.contract] = AgentDocumentTemplate(
            id: "contract-template",
            name: "合同模板",
            structure: "标题-当事人-标的-条款-签字",
            requiredFields: ["甲方", "乙方", "合同标的", "权利义务", "签字日期"]
        )
    }
    
    private func createDefaultTemplate(for type: LegalDocumentType) -> AgentDocumentTemplate {
        return AgentDocumentTemplate(
            id: "\(type.rawValue)-default",
            name: "\(type.rawValue)默认模板",
            structure: "标准法律文档结构",
            requiredFields: ["标题", "内容", "日期"]
        )
    }
    
    private func createDefaultContractTemplate(for type: ContractType) -> AgentDocumentTemplate {
        return AgentDocumentTemplate(
            id: "\(type.rawValue)-contract-template",
            name: "\(type.rawValue)合同模板",
            structure: "合同标准结构",
            requiredFields: ["当事人", "标的", "条款", "签字"]
        )
    }
}

private struct AgentDocumentTemplate {
    let id: String
    let name: String
    let structure: String
    let requiredFields: [String]
}