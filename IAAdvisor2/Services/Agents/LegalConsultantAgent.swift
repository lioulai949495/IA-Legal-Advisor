import Foundation

/// 法律咨询代理 - 专门处理法律咨询和建议
class DefaultLegalConsultantAgent: LegalConsultantAgent {
    
    // MARK: - AIAgent Properties
    let id: String = "legal-consultant-001"
    let name: String = "法律咨询助手"
    let description: String = "专业的法律咨询代理，提供各类法律问题的咨询和建议"
    let agentType: AgentType = .legalConsultant
    let specializations: [String] = [
        "民事纠纷咨询", "刑事案件咨询", "合同法咨询", 
        "劳动法咨询", "知识产权咨询", "公司法咨询"
    ]
    var isActive: Bool = true
    
    // MARK: - Private Properties
    private let apiService: APIService
    private let maxResponseLength = 2000
    private let confidenceThreshold = 0.7
    
    // MARK: - Initialization
    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }
    
    // MARK: - AIAgent Methods
    
    func processRequest(_ request: AgentRequest) async throws -> AgentResponse {
        let startTime = Date()
        
        // 验证请求
        guard canHandle(request.caseType ?? .contractDispute) else {
            throw AgentError.unsupportedCaseType(request.caseType?.rawValue ?? "未知")
        }
        
        do {
            // 构建法律咨询提示
            let prompt = buildLegalConsultationPrompt(request)
            
            // 调用API获取AI回复
            let chatResponse = try await apiService.sendChatMessage(
                category: "法律咨询",
                role: "法律咨询师",
                subtype: request.caseType?.rawValue,
                message: prompt
            )
            
            // 分析回复内容
            let analysis = analyzeLegalResponse(chatResponse.analysis_report.action_suggestion)
            
            // 生成建议和后续问题
            let recommendations = generateRecommendations(for: request, analysis: analysis)
            let followUpQuestions = generateFollowUpQuestions(for: request.caseType)
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            return AgentResponse(
                id: UUID().uuidString,
                requestId: request.id,
                agentId: id,
                content: formatLegalResponse(chatResponse.analysis_report.action_suggestion, analysis: analysis),
                confidence: analysis.confidence,
                recommendations: recommendations,
                attachments: generateLegalAttachments(for: request.caseType),
                followUpQuestions: followUpQuestions,
                createdAt: Date(),
                processingTime: processingTime
            )
            
        } catch {
            throw AgentError.processingFailed("法律咨询处理失败: \(error.localizedDescription)")
        }
    }
    
    func canHandle(_ caseType: CaseType) -> Bool {
        // 法律咨询代理可以处理所有类型的案件
        return true
    }
    
    // MARK: - LegalConsultantAgent Methods
    
    func provideLegalAdvice(for caseType: CaseType, query: String) async throws -> LegalAdvice {
        let prompt = """
        作为专业法律顾问，请对以下\(caseType.rawValue)案件问题提供专业建议：
        
        问题：\(query)
        
        请提供：
        1. 法律分析和建议
        2. 相关法律依据
        3. 适用的法律法规
        4. 建议的下一步行动
        """
        
        let chatResponse = try await apiService.sendChatMessage(
            category: "法律咨询",
            role: "法律咨询师",
            subtype: caseType.rawValue,
            message: prompt
        )
        return parseConsultationResponse(chatResponse.analysis_report.action_suggestion)
    }
    
    func answerLegalQuestion(_ question: String, context: AgentContext?) async throws -> String {
        var prompt = "作为专业法律顾问，请回答以下法律问题：\n\(question)"
        
        // 添加上下文信息
        if let context = context {
            if let caseDetails = context.caseDetails {
                prompt += "\n\n相关案件信息：\(caseDetails.description)"
            }
            
            if let previousMessages = context.previousMessages, !previousMessages.isEmpty {
                let recentMessages = previousMessages.suffix(3)
                prompt += "\n\n对话历史：\n"
                for message in recentMessages {
                    prompt += "- \(message.isFromAI ? "AI" : "用户"): \(message.content)\n"
                }
            }
        }
        
        let chatResponse = try await apiService.sendChatMessage(
            category: "法律咨询",
            role: "法律咨询师",
            subtype: caseDetails.caseType.rawValue,
            message: detailedPrompt
        )
        return parseDetailedAdviceResponse(chatResponse.analysis_report.action_suggestion)
    }
    
    // MARK: - Private Helper Methods
    
    private func buildLegalConsultationPrompt(_ request: AgentRequest) -> String {
        var prompt = """
        您好，我是您的专业法律顾问。针对您的问题，我将为您提供专业的法律分析和建议。
        
        问题类型：\(request.caseType?.rawValue ?? "一般法律咨询")
        咨询内容：\(request.content)
        """
        
        // 添加上下文信息
        if let context = request.context {
            if let caseDetails = context.caseDetails {
                prompt += "\n\n案件背景：\(caseDetails.description)"
            }
            
            if let userPreferences = context.userPreferences {
                prompt += "\n\n回复要求：请以\(userPreferences.communicationStyle.rawValue)的方式，"
                prompt += "适合\(userPreferences.expertiseLevel.rawValue)水平的用户理解"
            }
        }
        
        prompt += """
        
        请为我提供：
        1. 法律问题分析
        2. 相关法律法规
        3. 可能的解决方案
        4. 风险提示
        5. 建议的下一步行动
        """
        
        return prompt
    }
    
    private func analyzeLegalResponse(_ response: String) -> LegalResponseAnalysis {
        // 简单的文本分析来评估回复质量
        let wordCount = response.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let hasLegalTerms = containsLegalTerminology(response)
        let hasStructuredContent = hasStructuredFormat(response)
        let hasActionItems = containsActionItems(response)
        
        var confidence = 0.5
        
        // 根据各种因素调整置信度
        if wordCount > 100 { confidence += 0.1 }
        if wordCount > 300 { confidence += 0.1 }
        if hasLegalTerms { confidence += 0.2 }
        if hasStructuredContent { confidence += 0.1 }
        if hasActionItems { confidence += 0.1 }
        
        confidence = min(1.0, confidence)
        
        return LegalResponseAnalysis(
            confidence: confidence,
            hasLegalTerms: hasLegalTerms,
            hasStructuredContent: hasStructuredContent,
            hasActionItems: hasActionItems,
            wordCount: wordCount
        )
    }
    
    private func generateRecommendations(
        for request: AgentRequest, 
        analysis: LegalResponseAnalysis
    ) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // 基于案件类型生成建议
        if let caseType = request.caseType {
            switch caseType.category {
            case .civil:
                recommendations.append(contentsOf: generateCivilRecommendations(caseType))
            case .criminal:
                recommendations.append(contentsOf: generateCriminalRecommendations(caseType))
            case .administrative:
                recommendations.append(contentsOf: generateAdministrativeRecommendations(caseType))
            }
        }
        
        // 基于请求优先级调整建议
        if request.priority == .urgent {
            recommendations.insert(Recommendation(
                id: "urgent-action",
                title: "紧急行动建议",
                description: "鉴于此问题的紧急性，建议立即咨询专业律师并采取必要的法律行动",
                actionType: .consult,
                priority: .critical,
                estimatedCost: nil,
                timeframe: "24小时内",
                requirements: ["专业律师咨询", "相关证据收集"]
            ), at: 0)
        }
        
        return recommendations
    }
    
    private func generateCivilRecommendations(_ caseType: CaseType) -> [Recommendation] {
        switch caseType {
        case .contractDispute:
            return [
                Recommendation(
                    id: "contract-review",
                    title: "合同条款审查",
                    description: "详细审查合同条款，识别有利和不利条件",
                    actionType: .investigate,
                    priority: .high,
                    estimatedCost: 200,
                    timeframe: "3-5个工作日",
                    requirements: ["完整合同文件", "相关通信记录"]
                ),
                Recommendation(
                    id: "negotiation-strategy",
                    title: "协商策略制定",
                    description: "制定有效的协商策略，争取最佳解决方案",
                    actionType: .negotiate,
                    priority: .medium,
                    estimatedCost: 500,
                    timeframe: "1-2周",
                    requirements: ["对方联系方式", "争议焦点分析"]
                )
            ]
        case .divorceDispute:
            return [
                Recommendation(
                    id: "mediation-first",
                    title: "优先考虑调解",
                    description: "通过专业调解减少情感创伤和经济损失",
                    actionType: .mediate,
                    priority: .high,
                    estimatedCost: 300,
                    timeframe: "2-4周",
                    requirements: ["双方同意", "财产清单", "子女抚养计划"]
                )
            ]
        default:
            return [
                Recommendation(
                    id: "general-consultation",
                    title: "专业法律咨询",
                    description: "建议咨询专业律师获得详细的法律建议",
                    actionType: .consult,
                    priority: .medium,
                    estimatedCost: 300,
                    timeframe: "1周内",
                    requirements: ["相关证据材料", "案件详细描述"]
                )
            ]
        }
    }
    
    private func generateCriminalRecommendations(_ caseType: CaseType) -> [Recommendation] {
        return [
            Recommendation(
                id: "immediate-legal-counsel",
                title: "立即寻求法律援助",
                description: "刑事案件性质严重，建议立即咨询专业刑事辩护律师",
                actionType: .consult,
                priority: .critical,
                estimatedCost: 1000,
                timeframe: "立即",
                requirements: ["案件详情", "相关证据", "个人身份证明"]
            ),
            Recommendation(
                id: "evidence-collection",
                title: "证据收集保全",
                description: "及时收集和保全有利证据，避免证据灭失",
                actionType: .investigate,
                priority: .high,
                estimatedCost: 500,
                timeframe: "48小时内",
                requirements: ["证据清单", "证人信息", "专业取证协助"]
            )
        ]
    }
    
    private func generateAdministrativeRecommendations(_ caseType: CaseType) -> [Recommendation] {
        return [
            Recommendation(
                id: "administrative-review",
                title: "申请行政复议",
                description: "对行政行为不服，可以在60日内向上级行政机关申请复议",
                actionType: .fileComplaint,
                priority: .high,
                estimatedCost: 300,
                timeframe: "60日内",
                requirements: ["行政决定书", "申请复议书", "相关证据材料"]
            ),
            Recommendation(
                id: "administrative-litigation",
                title: "提起行政诉讼",
                description: "如复议不成功或超过复议期限，可向法院提起行政诉讼",
                actionType: .fileLawsuit,
                priority: .medium,
                estimatedCost: 800,
                timeframe: "6个月内",
                requirements: ["起诉状", "证据材料", "行政复议决定书或不作为证明"]
            )
        ]
    }
    
    private func generateFollowUpQuestions(for caseType: CaseType?) -> [String] {
        guard let caseType = caseType else {
            return [
                "您还有其他法律问题需要咨询吗？",
                "是否需要我为您推荐专业律师？",
                "您希望了解相关的法律程序吗？"
            ]
        }
        
        switch caseType {
        case .contractDispute:
            return [
                "合同是否有书面形式？",
                "双方是否有履行部分合同义务？",
                "是否尝试过协商解决？",
                "您希望继续履行合同还是解除合同？"
            ]
        case .divorceDispute:
            return [
                "双方是否有共同财产需要分割？",
                "是否涉及子女抚养问题？",
                "是否尝试过婚姻调解？",
                "您希望通过什么方式解决争议？"
            ]
        case .laborDispute:
            return [
                "劳动合同的具体条款是什么？",
                "公司是否有违反劳动法的行为？",
                "您是否有保留相关证据？",
                "是否已向劳动仲裁委员会申请仲裁？"
            ]
        default:
            return [
                "您能提供更多案件细节吗？",
                "是否有相关的证据材料？",
                "您希望通过什么方式解决问题？",
                "是否需要专业律师介入？"
            ]
        }
    }
    
    private func generateLegalAttachments(for caseType: CaseType?) -> [AgentAttachment] {
        guard let caseType = caseType else { return [] }
        
        var attachments: [AgentAttachment] = []
        
        // 通用法律文档
        attachments.append(AgentAttachment(
            id: "legal-rights-guide",
            name: "法律权利指南",
            type: .reference,
            url: nil,
            content: "了解您在 \(caseType.rawValue) 中的基本法律权利和义务",
            size: nil
        ))
        
        // 案件特定文档
        switch caseType {
        case .contractDispute:
            attachments.append(AgentAttachment(
                id: "contract-checklist",
                name: "合同审查清单",
                type: .checklist,
                url: nil,
                content: "检查合同关键条款的详细清单",
                size: nil
            ))
        case .divorceDispute:
            attachments.append(AgentAttachment(
                id: "divorce-process-guide",
                name: "离婚程序指南",
                type: .reference,
                url: nil,
                content: "离婚案件的完整流程和注意事项",
                size: nil
            ))
        default:
            break
        }
        
        return attachments
    }
    
    // MARK: - Text Analysis Helper Methods
    
    private func containsLegalTerminology(_ text: String) -> Bool {
        let legalTerms = [
            "法律", "法规", "条款", "规定", "权利", "义务", "责任", "合同", "协议",
            "诉讼", "仲裁", "调解", "赔偿", "违约", "侵权", "证据", "程序"
        ]
        
        return legalTerms.contains { text.contains($0) }
    }
    
    private func hasStructuredFormat(_ text: String) -> Bool {
        // 检查是否包含结构化内容（如编号列表、分段等）
        let patterns = ["1.", "2.", "一、", "二、", "首先", "其次", "最后"]
        return patterns.contains { text.contains($0) }
    }
    
    private func containsActionItems(_ text: String) -> Bool {
        let actionWords = ["建议", "应该", "需要", "可以", "建议您", "下一步"]
        return actionWords.contains { text.contains($0) }
    }
    
    private func formatLegalResponse(_ response: String, analysis: LegalResponseAnalysis) -> String {
        var formatted = response
        
        // 如果回复太长，添加摘要
        if analysis.wordCount > maxResponseLength {
            formatted = "【回复摘要】\n" + String(response.prefix(maxResponseLength)) + "\n\n..." +
                       "\n\n如需完整回复，请联系专业法律顾问。"
        }
        
        // 添加置信度说明
        if analysis.confidence < confidenceThreshold {
            formatted += "\n\n⚠️ 提示：此问题较为复杂，建议咨询专业律师获得更准确的法律建议。"
        }
        
        return formatted
    }
    
    // MARK: - Content Extraction Methods
    
    private func extractLegalBasis(from response: String) -> String {
        // 简化的法律依据提取
        let patterns = ["根据.*?法", "依照.*?规定", "按照.*?条款"]
        
        for pattern in patterns {
            if let range = response.range(of: pattern, options: .regularExpression) {
                let start = max(range.lowerBound, response.startIndex)
                let end = min(response.index(range.upperBound, offsetBy: 50, limitedBy: response.endIndex) ?? response.endIndex, response.endIndex)
                return String(response[start..<end])
            }
        }
        
        return "建议咨询专业律师获得具体法律依据"
    }
    
    private func extractApplicableLaws(from response: String) -> [String] {
        let commonLaws = [
            "民法典", "合同法", "劳动法", "公司法", "刑法", "行政法", 
            "婚姻法", "继承法", "物权法", "侵权责任法"
        ]
        
        return commonLaws.filter { response.contains($0) }
    }
    
    private func extractNextSteps(from response: String) -> [String] {
        let actionPatterns = [
            "建议.*?。", "应该.*?。", "需要.*?。", "可以.*?。"
        ]
        
        var steps: [String] = []
        
        for pattern in actionPatterns {
            let regex = try? NSRegularExpression(pattern: pattern)
            let matches = regex?.matches(in: response, range: NSRange(response.startIndex..., in: response))
            
            for match in matches ?? [] {
                if let range = Range(match.range, in: response) {
                    steps.append(String(response[range]))
                }
            }
        }
        
        return Array(steps.prefix(5)) // 最多返回5个步骤
    }
    
    private func calculateConfidence(_ response: String) -> Double {
        let analysis = analyzeLegalResponse(response)
        return analysis.confidence
    }
    
    private func getStandardDisclaimers() -> [String] {
        return [
            "本建议仅供参考，不构成正式法律意见",
            "具体案件请咨询专业律师",
            "法律法规可能发生变化，请以最新规定为准",
            "每个案件情况不同，需要根据具体情况分析"
        ]
    }
}

// MARK: - Supporting Types

private struct LegalResponseAnalysis {
    let confidence: Double
    let hasLegalTerms: Bool
    let hasStructuredContent: Bool
    let hasActionItems: Bool
    let wordCount: Int
}