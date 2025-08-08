import Foundation

/// 案件分析代理 - 专门分析案件强度、法律问题和策略
class DefaultCaseAnalystAgent: CaseAnalystAgent {
    
    // MARK: - AIAgent Properties
    let id: String = "case-analyst-001"
    let name: String = "案件分析师"
    let description: String = "专业的案件分析代理，提供案件强度分析、法律问题识别和策略建议"
    let agentType: AgentType = .caseAnalyst
    let specializations: [String] = [
        "案件强度评估", "法律问题识别", "证据分析", 
        "风险评估", "策略制定", "胜诉概率分析"
    ]
    var isActive: Bool = true
    
    // MARK: - Private Properties
    private let apiService: APIService
    private let analysisDepth: AnalysisDepth = .comprehensive
    
    // MARK: - Initialization
    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }
    
    // MARK: - AIAgent Methods
    
    func processRequest(_ request: AgentRequest) async throws -> AgentResponse {
        let startTime = Date()
        
        guard canHandle(request.caseType ?? .contractDispute) else {
            throw AgentError.unsupportedCaseType(request.caseType?.rawValue ?? "未知")
        }
        
        do {
            // 构建案件分析提示
            let prompt = buildCaseAnalysisPrompt(request)
            
            // 调用API进行分析
            let chatResponse = try await apiService.sendChatMessage(
                category: "案件分析",
                role: "案件分析师",
                subtype: request.caseType?.rawValue ?? "一般案件",
                message: prompt
            )
            let responseText = chatResponse.analysis_report.action_suggestion
            
            // 分析回复并提取结构化信息
            let analysisResult = parseAnalysisResponse(responseText)
            
            // 生成专业建议
            let recommendations = generateAnalysisRecommendations(
                for: request,
                analysis: analysisResult
            )
            
            // 生成相关附件
            let attachments = generateAnalysisAttachments(for: request.caseType)
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            return AgentResponse(
                id: UUID().uuidString,
                requestId: request.id,
                agentId: id,
                content: formatAnalysisResponse(analysisResult),
                confidence: analysisResult.confidence,
                recommendations: recommendations,
                attachments: attachments,
                followUpQuestions: generateAnalysisFollowUp(for: request.caseType),
                createdAt: Date(),
                processingTime: processingTime
            )
            
        } catch {
            throw AgentError.processingFailed("案件分析失败: \(error.localizedDescription)")
        }
    }
    
    func canHandle(_ caseType: CaseType) -> Bool {
        // 案件分析师可以处理所有类型的案件
        return true
    }
    
    // MARK: - CaseAnalystAgent Methods
    
    func analyzeCaseStrength(_ caseDetails: CaseDetails) async throws -> CaseStrengthAnalysis {
        let prompt = buildCaseStrengthPrompt(caseDetails)
        
        let chatResponse = try await apiService.sendChatMessage(
            category: "案件分析",
            role: "法律分析专家",
            subtype: caseDetails.caseType.rawValue,
            message: prompt
        )
        
        return parseCaseStrengthResponse(chatResponse.analysis_report.action_suggestion, caseDetails: caseDetails)
    }
    
    func identifyLegalIssues(_ caseDetails: CaseDetails) async throws -> [LegalIssue] {
        let prompt = buildLegalIssuesPrompt(caseDetails)
        
        let chatResponse = try await apiService.sendChatMessage(
            category: "法律问题识别",
            role: "法律问题专家",
            subtype: caseDetails.caseType.rawValue,
            message: prompt
        )
        
        return parseLegalIssuesResponse(chatResponse.analysis_report.action_suggestion)
    }
    
    func suggestLegalStrategy(_ caseDetails: CaseDetails) async throws -> LegalStrategy {
        let prompt = buildStrategyPrompt(caseDetails)
        
        let chatResponse = try await apiService.sendChatMessage(
            category: "法律策略",
            role: "法律策略专家",
            subtype: caseDetails.caseType.rawValue,
            message: prompt
        )
        
        return parseStrategyResponse(chatResponse.analysis_report.action_suggestion, caseDetails: caseDetails)
    }
    
    // MARK: - Private Helper Methods
    
    private func buildCaseAnalysisPrompt(_ request: AgentRequest) -> String {
        var prompt = """
        作为专业的案件分析师，请对以下案件进行全面分析：
        
        案件类型：\(request.caseType?.rawValue ?? "一般案件")
        案件描述：\(request.content)
        """
        
        if let context = request.context {
            if let caseDetails = context.caseDetails {
                prompt += """
                
                详细信息：
                - 案件标题：\(caseDetails.title)
                - 案件描述：\(caseDetails.description)
                - 涉及当事人：\(caseDetails.involvedParties.map { $0.name + "(\($0.role.rawValue))" }.joined(separator: ", "))
                - 相关文档：\(caseDetails.documents.joined(separator: ", "))
                """
                
                if !caseDetails.timeline.isEmpty {
                    prompt += "\n- 案件时间线：\n"
                    for event in caseDetails.timeline.sorted(by: { $0.date < $1.date }) {
                        prompt += "  \(formatDate(event.date)): \(event.description)\n"
                    }
                }
            }
        }
        
        prompt += """
        
        请提供以下分析：
        1. 案件强度评估（强/中/弱）
        2. 主要法律问题识别
        3. 证据充分性分析
        4. 潜在风险评估
        5. 胜诉概率估算
        6. 建议的法律策略
        7. 需要补充的证据或信息
        8. 预估的时间和成本
        """
        
        return prompt
    }
    
    private func buildCaseStrengthPrompt(_ caseDetails: CaseDetails) -> String {
        return """
        请分析以下案件的强度：
        
        案件类型：\(caseDetails.caseType.rawValue)
        案件标题：\(caseDetails.title)
        案件描述：\(caseDetails.description)
        
        请从以下角度进行分析：
        1. 法律依据是否充分
        2. 事实证据是否清晰
        3. 法律程序是否完备
        4. 对方可能的抗辩理由
        5. 案件的优势和劣势
        6. 整体胜诉概率
        
        并提供具体的改进建议。
        """
    }
    
    private func buildLegalIssuesPrompt(_ caseDetails: CaseDetails) -> String {
        return """
        请识别以下案件中的主要法律问题：
        
        案件信息：
        - 类型：\(caseDetails.caseType.rawValue)
        - 描述：\(caseDetails.description)
        - 当事人：\(caseDetails.involvedParties.map { "\($0.name)(\($0.role.rawValue))" }.joined(separator: ", "))
        
        请识别：
        1. 主要争议焦点
        2. 适用的法律条文
        3. 可能的法律障碍
        4. 需要证明的关键事实
        5. 程序性问题
        6. 实体性问题
        
        对每个问题请评估其严重程度和解决难度。
        """
    }
    
    private func buildStrategyPrompt(_ caseDetails: CaseDetails) -> String {
        return """
        请为以下案件制定法律策略：
        
        案件概况：
        - 类型：\(caseDetails.caseType.rawValue)
        - 标题：\(caseDetails.title)
        - 描述：\(caseDetails.description)
        - 状态：\(caseDetails.status.rawValue)
        
        请制定：
        1. 整体策略方向（协商/调解/诉讼）
        2. 具体执行步骤
        3. 时间安排和里程碑
        4. 所需资源和预算
        5. 风险控制措施
        6. 备选方案
        7. 成功指标
        
        请考虑成本效益和实现可能性。
        """
    }
    
    private func parseAnalysisResponse(_ response: String) -> InternalCaseAnalysisResult {
        // 简化的响应解析 - 实际应用中可以使用更复杂的NLP技术
        let confidence = extractConfidenceFromResponse(response)
        let strength = extractCaseStrengthFromResponse(response)
        let issues = extractIssuesFromResponse(response)
        let recommendations = extractRecommendationsFromResponse(response)
        
        return InternalCaseAnalysisResult(
            confidence: confidence,
            caseStrength: strength,
            identifiedIssues: issues,
            keyRecommendations: recommendations,
            rawResponse: response
        )
    }
    
    private func parseCaseStrengthResponse(_ response: String, caseDetails: CaseDetails) -> CaseStrengthAnalysis {
        let strengthLevel = extractStrengthLevel(from: response)
        let strengths = extractListItems(from: response, pattern: "优势|强项|有利")
        let weaknesses = extractListItems(from: response, pattern: "劣势|弱点|不利")
        let opportunities = extractListItems(from: response, pattern: "机会|可能")
        let threats = extractListItems(from: response, pattern: "威胁|风险|危险")
        let actions = extractListItems(from: response, pattern: "建议|应该|需要")
        
        return CaseStrengthAnalysis(
            overallStrength: strengthLevel,
            strengths: strengths,
            weaknesses: weaknesses,
            opportunities: opportunities,
            threats: threats,
            recommendedActions: actions
        )
    }
    
    private func parseLegalIssuesResponse(_ response: String) -> [LegalIssue] {
        var issues: [LegalIssue] = []
        
        // 简化的问题提取逻辑
        let issuePatterns = [
            "主要问题", "争议焦点", "法律问题", "关键问题", "核心问题"
        ]
        
        for (index, pattern) in issuePatterns.enumerated() {
            if response.contains(pattern) {
                issues.append(LegalIssue(
                    id: "issue-\(index)",
                    title: "\(pattern)\(index + 1)",
                    description: extractIssueDescription(from: response, pattern: pattern),
                    severity: determineSeverity(from: response, pattern: pattern),
                    legalArea: determineLegalArea(from: response),
                    applicableLaws: extractApplicableLaws(from: response),
                    suggestedActions: extractActionItems(from: response, for: pattern)
                ))
            }
        }
        
        return issues
    }
    
    private func parseStrategyResponse(_ response: String, caseDetails: CaseDetails) -> LegalStrategy {
        let approach = extractStrategyApproach(from: response)
        let milestones = extractMilestones(from: response)
        let alternatives = extractAlternatives(from: response)
        let estimatedCost = extractCost(from: response)
        let successProbability = extractSuccessProbability(from: response)
        let risks = extractRisks(from: response)
        
        return LegalStrategy(
            id: UUID().uuidString,
            title: "针对\(caseDetails.caseType.rawValue)的法律策略",
            description: response,
            approach: approach,
            timeline: milestones,
            estimatedCost: estimatedCost,
            successProbability: successProbability,
            risks: risks,
            alternatives: alternatives
        )
    }
    
    private func generateAnalysisRecommendations(
        for request: AgentRequest,
        analysis: InternalCaseAnalysisResult
    ) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // 基于案件强度生成建议
        switch analysis.caseStrength {
        case .veryStrong, .strong:
            recommendations.append(Recommendation(
                id: "pursue-litigation",
                title: "积极推进诉讼",
                description: "案件强度较高，建议积极推进法律程序",
                actionType: .litigate,
                priority: .high,
                estimatedCost: 2000,
                timeframe: "3-6个月",
                requirements: ["完善证据链", "选择专业律师"]
            ))
        case .moderate:
            recommendations.append(Recommendation(
                id: "consider-mediation",
                title: "考虑调解方案",
                description: "案件强度中等，可以考虑调解或协商解决",
                actionType: .mediate,
                priority: .medium,
                estimatedCost: 800,
                timeframe: "1-2个月",
                requirements: ["对方协商意愿", "调解机构联系"]
            ))
        case .weak, .veryWeak:
            recommendations.append(Recommendation(
                id: "strengthen-case",
                title: "加强案件论证",
                description: "案件需要进一步补强证据和法律依据",
                actionType: .investigate,
                priority: .high,
                estimatedCost: 1000,
                timeframe: "2-4周",
                requirements: ["补充证据", "专家意见", "法律研究"]
            ))
        }
        
        // 基于识别的问题生成建议
        for issue in analysis.identifiedIssues {
            if issue.contains("证据") {
                recommendations.append(Recommendation(
                    id: "evidence-collection",
                    title: "证据收集完善",
                    description: "针对证据不足问题，建议进行专门的证据收集",
                    actionType: .investigate,
                    priority: .high,
                    estimatedCost: 500,
                    timeframe: "2-3周",
                    requirements: ["证据清单", "取证计划", "专业协助"]
                ))
            }
        }
        
        return recommendations
    }
    
    private func generateAnalysisAttachments(for caseType: CaseType?) -> [AgentAttachment] {
        var attachments: [AgentAttachment] = []
        
        // 通用分析文档
        attachments.append(AgentAttachment(
            id: "analysis-template",
            name: "案件分析模板",
            type: .template,
            url: nil,
            content: "标准化的案件分析模板，帮助整理案件信息",
            size: nil
        ))
        
        attachments.append(AgentAttachment(
            id: "evidence-checklist",
            name: "证据清单模板",
            type: .checklist,
            url: nil,
            content: "证据收集和整理的标准化清单",
            size: nil
        ))
        
        // 案件特定文档
        if let caseType = caseType {
            switch caseType.category {
            case .civil:
                attachments.append(AgentAttachment(
                    id: "civil-procedure-guide",
                    name: "民事诉讼程序指南",
                    type: .reference,
                    url: nil,
                    content: "民事案件的标准程序和注意事项",
                    size: nil
                ))
            case .criminal:
                attachments.append(AgentAttachment(
                    id: "criminal-defense-guide",
                    name: "刑事辩护指南",
                    type: .reference,
                    url: nil,
                    content: "刑事案件辩护的关键要点和策略",
                    size: nil
                ))
            case .administrative:
                attachments.append(AgentAttachment(
                    id: "administrative-procedure-guide",
                    name: "行政诉讼程序指南",
                    type: .reference,
                    url: nil,
                    content: "行政案件的程序要点和申请复议流程",
                    size: nil
                ))
            }
        }
        
        return attachments
    }
    
    private func generateAnalysisFollowUp(for caseType: CaseType?) -> [String] {
        guard let caseType = caseType else {
            return [
                "是否需要更详细的案件分析？",
                "您希望重点分析哪个方面？",
                "是否需要风险评估报告？"
            ]
        }
        
        let commonQuestions = [
            "您对当前的案件强度评估有什么看法？",
            "是否需要针对具体法律问题进行深入分析？",
            "您希望优先考虑哪种解决策略？"
        ]
        
        let specificQuestions: [String]
        
        switch caseType {
        case .contractDispute:
            specificQuestions = [
                "合同中是否有仲裁条款？",
                "双方的违约损失如何计算？"
            ]
        case .laborDispute:
            specificQuestions = [
                "是否已申请劳动仲裁？",
                "公司的违法行为是否有证据支持？"
            ]
        case .divorceDispute:
            specificQuestions = [
                "财产分割是否涉及争议？",
                "子女抚养权归属如何确定？"
            ]
        default:
            specificQuestions = [
                "案件的关键争议点是什么？",
                "对方的主要抗辩理由可能是什么？"
            ]
        }
        
        return commonQuestions + specificQuestions
    }
    
    private func formatAnalysisResponse(_ analysis: InternalCaseAnalysisResult) -> String {
        var formatted = """
        ## 案件分析报告
        
        **案件强度评估：** \(analysis.caseStrength.rawValue)
        **分析置信度：** \(String(format: "%.1f", analysis.confidence * 100))%
        
        ### 主要发现
        """
        
        if !analysis.identifiedIssues.isEmpty {
            formatted += "\n\n**识别的关键问题：**\n"
            for (index, issue) in analysis.identifiedIssues.enumerated() {
                formatted += "\(index + 1). \(issue)\n"
            }
        }
        
        if !analysis.keyRecommendations.isEmpty {
            formatted += "\n\n**核心建议：**\n"
            for (index, recommendation) in analysis.keyRecommendations.enumerated() {
                formatted += "\(index + 1). \(recommendation)\n"
            }
        }
        
        formatted += "\n\n### 详细分析\n\(analysis.rawResponse)"
        
        return formatted
    }
    
    // MARK: - Text Extraction Helper Methods
    
    private func extractConfidenceFromResponse(_ response: String) -> Double {
        // 基于响应内容的质量和完整性评估置信度
        let indicators = [
            response.contains("明确") || response.contains("清楚"): 0.1,
            response.contains("证据") || response.contains("依据"): 0.2,
            response.contains("法律") || response.contains("法规"): 0.2,
            response.contains("建议") || response.contains("策略"): 0.1,
            response.count > 200: 0.2,
            response.count > 500: 0.2
        ]
        
        let baseConfidence = 0.5
        let additionalConfidence = indicators.compactMap { $0.key ? $0.value : nil }.reduce(0, +)
        
        return min(1.0, baseConfidence + additionalConfidence)
    }
    
    private func extractCaseStrengthFromResponse(_ response: String) -> CaseStrengthAnalysis.StrengthLevel {
        let strongIndicators = ["很强", "非常强", "强势", "有利", "胜算大"]
        let weakIndicators = ["较弱", "不利", "困难", "风险大", "胜算小"]
        
        let strongCount = strongIndicators.filter { response.contains($0) }.count
        let weakCount = weakIndicators.filter { response.contains($0) }.count
        
        if strongCount > weakCount + 1 {
            return .strong
        } else if weakCount > strongCount + 1 {
            return .weak
        } else {
            return .moderate
        }
    }
    
    private func extractIssuesFromResponse(_ response: String) -> [String] {
        let issueKeywords = ["问题", "争议", "难点", "障碍", "风险"]
        var issues: [String] = []
        
        for keyword in issueKeywords {
            if let range = response.range(of: keyword) {
                // 提取包含关键词的句子
                let sentenceStart = response.lastIndex(of: "。", before: range.lowerBound) ?? response.startIndex
                let sentenceEnd = response.firstIndex(of: "。", after: range.upperBound) ?? response.endIndex
                
                if sentenceStart < sentenceEnd {
                    let sentence = String(response[sentenceStart..<sentenceEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !sentence.isEmpty && sentence.count > 5 {
                        issues.append(sentence)
                    }
                }
            }
        }
        
        return Array(Set(issues)).prefix(5).map { String($0) }
    }
    
    private func extractRecommendationsFromResponse(_ response: String) -> [String] {
        let recommendationKeywords = ["建议", "应该", "需要", "可以考虑", "推荐"]
        var recommendations: [String] = []
        
        for keyword in recommendationKeywords {
            if let range = response.range(of: keyword) {
                let sentenceStart = response.lastIndex(of: "。", before: range.lowerBound) ?? response.startIndex
                let sentenceEnd = response.firstIndex(of: "。", after: range.upperBound) ?? response.endIndex
                
                if sentenceStart < sentenceEnd {
                    let sentence = String(response[sentenceStart..<sentenceEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !sentence.isEmpty && sentence.count > 10 {
                        recommendations.append(sentence)
                    }
                }
            }
        }
        
        return Array(Set(recommendations)).prefix(3).map { String($0) }
    }
    
    // MARK: - Additional Helper Methods
    
    private func extractStrengthLevel(from response: String) -> CaseStrengthAnalysis.StrengthLevel {
        if response.contains("非常强") || response.contains("很强") {
            return .veryStrong
        } else if response.contains("强") || response.contains("有利") {
            return .strong
        } else if response.contains("弱") || response.contains("不利") {
            return .weak
        } else if response.contains("很弱") || response.contains("非常弱") {
            return .veryWeak
        } else {
            return .moderate
        }
    }
    
    private func extractListItems(from response: String, pattern: String) -> [String] {
        // 简化的列表项提取
        let lines = response.components(separatedBy: .newlines)
        return lines.compactMap { line in
            if line.contains(pattern) && line.count > 10 {
                return line.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return nil
        }.prefix(5).map { String($0) }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    // 其他辅助方法的简化实现
    private func extractIssueDescription(from response: String, pattern: String) -> String {
        return "关于\(pattern)的详细分析"
    }
    
    private func determineSeverity(from response: String, pattern: String) -> LegalIssue.IssueSeverity {
        if response.contains("严重") || response.contains("重大") {
            return .serious
        } else if response.contains("关键") || response.contains("核心") {
            return .critical
        } else if response.contains("轻微") || response.contains("小") {
            return .minor
        } else {
            return .moderate
        }
    }
    
    private func determineLegalArea(from response: String) -> String {
        let areas = ["民法", "刑法", "行政法", "劳动法", "合同法", "侵权法"]
        return areas.first { response.contains($0) } ?? "综合法律"
    }
    
    private func extractApplicableLaws(from response: String) -> [String] {
        let laws = ["民法典", "刑法", "合同法", "劳动法", "公司法"]
        return laws.filter { response.contains($0) }
    }
    
    private func extractActionItems(from response: String, for pattern: String) -> [String] {
        return ["针对\(pattern)采取相应措施", "收集相关证据", "咨询专业律师"]
    }
    
    private func extractStrategyApproach(from response: String) -> LegalStrategy.StrategyApproach {
        if response.contains("诉讼") { return .litigation }
        if response.contains("调解") { return .mediation }
        if response.contains("仲裁") { return .arbitration }
        if response.contains("协商") { return .negotiation }
        if response.contains("和解") { return .settlement }
        return .negotiation
    }
    
    private func extractMilestones(from response: String) -> [StrategyMilestone] {
        return [
            StrategyMilestone(
                id: "milestone-1",
                title: "准备阶段",
                description: "收集证据，准备材料",
                targetDate: Calendar.current.date(byAdding: .weekOfYear, value: 2, to: Date()) ?? Date(),
                dependencies: [],
                deliverables: ["证据清单", "法律分析"]
            )
        ]
    }
    
    private func extractAlternatives(from response: String) -> [AlternativeStrategy] {
        return [
            AlternativeStrategy(
                id: "alt-1",
                title: "备选方案",
                description: "根据情况发展制定的备选策略",
                pros: ["风险较低", "成本可控"],
                cons: ["效果可能有限"],
                estimatedCost: 500
            )
        ]
    }
    
    private func extractCost(from response: String) -> Double? {
        // 简化的成本提取
        if response.contains("万") {
            return 10000
        } else if response.contains("千") {
            return 1000
        }
        return nil
    }
    
    private func extractSuccessProbability(from response: String) -> Double {
        if response.contains("很高") || response.contains("90%") { return 0.9 }
        if response.contains("较高") || response.contains("70%") { return 0.7 }
        if response.contains("一般") || response.contains("50%") { return 0.5 }
        if response.contains("较低") || response.contains("30%") { return 0.3 }
        return 0.6 // 默认值
    }
    
    private func extractRisks(from response: String) -> [String] {
        return ["程序风险", "证据风险", "时间成本风险"].filter { response.contains($0.prefix(2)) }
    }
}

// MARK: - Supporting Types

private struct InternalCaseAnalysisResult {
    let confidence: Double
    let caseStrength: CaseStrengthAnalysis.StrengthLevel
    let identifiedIssues: [String]
    let keyRecommendations: [String]
    let rawResponse: String
}

private enum AnalysisDepth {
    case basic
    case standard
    case comprehensive
    case expert
}

extension String {
    func firstIndex(of character: Character, after index: String.Index) -> String.Index? {
        let range = self.index(after: index)..<self.endIndex
        return self[range].firstIndex(of: character).map { self.index(index, offsetBy: self.distance(from: index, to: $0)) }
    }
    
    func lastIndex(of character: Character, before index: String.Index) -> String.Index? {
        let range = self.startIndex..<index
        return self[range].lastIndex(of: character)
    }
}
