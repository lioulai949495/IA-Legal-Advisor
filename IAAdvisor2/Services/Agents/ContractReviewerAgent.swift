import Foundation

/// 合同审查代理 - 专门进行合同审查和条款分析
class DefaultContractReviewerAgent: AIAgent {
    
    // MARK: - AIAgent Properties
    let id: String = "contract-reviewer-001"
    let name: String = "合同审查师"
    let description: String = "专业的合同审查代理，提供合同条款分析、风险识别和修改建议"
    let agentType: AgentType = .contractReviewer
    let specializations: [String] = [
        "合同条款审查", "风险条款识别", "合同合规检查", 
        "条款修改建议", "合同结构分析", "法律风险评估"
    ]
    var isActive: Bool = true
    
    // MARK: - Private Properties
    private let apiService: APIService
    private let contractTemplates: ContractTemplateLibrary
    private let legalStandards: LegalStandardsDatabase
    
    // MARK: - Initialization
    init(apiService: APIService = .shared) {
        self.apiService = apiService
        self.contractTemplates = ContractTemplateLibrary()
        self.legalStandards = LegalStandardsDatabase()
    }
    
    // MARK: - AIAgent Methods
    
    func processRequest(_ request: AgentRequest) async throws -> AgentResponse {
        let startTime = Date()
        
        guard canHandle(request.caseType ?? .contractDispute) else {
            throw AgentError.unsupportedCaseType(request.caseType?.rawValue ?? "未知")
        }
        
        do {
            // 解析合同审查请求
            let reviewRequest = parseContractReviewRequest(request)
            
            // 执行合同审查
            let reviewResult = try await performContractReview(reviewRequest)
            
            // 生成审查建议
            let recommendations = generateContractRecommendations(reviewResult)
            
            // 创建审查报告附件
            let attachments = generateContractReviewAttachments(reviewResult)
            
            // 生成后续问题
            let followUpQuestions = generateContractFollowUp(reviewResult)
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            return AgentResponse(
                id: UUID().uuidString,
                requestId: request.id,
                agentId: id,
                content: formatContractReviewResponse(reviewResult),
                confidence: reviewResult.confidence,
                recommendations: recommendations,
                attachments: attachments,
                followUpQuestions: followUpQuestions,
                createdAt: Date(),
                processingTime: processingTime
            )
            
        } catch {
            throw AgentError.processingFailed("合同审查失败: \(error.localizedDescription)")
        }
    }
    
    func canHandle(_ caseType: CaseType) -> Bool {
        // 合同审查师主要处理合同相关案件
        return caseType == .contractDispute || 
               caseType == .laborDispute || 
               caseType == .tradingDispute ||
               caseType == .propertyDispute ||
               caseType == .intellectualProperty
    }
    
    // MARK: - Contract Review Methods
    
    fileprivate func reviewContract(_ contractContent: String, contractType: ContractType) async throws -> ContractReviewResult {
        let reviewRequest = ContractReviewRequest(
            content: contractContent,
            type: contractType,
            reviewScope: .comprehensive,
            focusAreas: ContractFocusArea.allCases
        )
        
        return try await performContractReview(reviewRequest)
    }
    
    fileprivate func identifyRiskyClauses(_ contractContent: String) async throws -> [RiskyClause] {
        let prompt = buildRiskIdentificationPrompt(contractContent)
        
        let chatResponse = try await apiService.sendChatMessage(
            category: "合同风险识别",
            role: "合同风险专家",
            subtype: "contract-reviewer",
            message: prompt
        )
        
        return parseRiskyClausesFromResponse(chatResponse.analysis_report.action_suggestion)
    }
    
    fileprivate func suggestClauseImprovements(_ contractContent: String, focusArea: ContractFocusArea) async throws -> [ClauseImprovement] {
        let prompt = buildImprovementPrompt(contractContent, focusArea: focusArea)
        
        let chatResponse = try await apiService.sendChatMessage(
            category: "条款优化",
            role: "合同审查师",
            subtype: "contract-reviewer",
            message: prompt
        )
        
        return parseOptimizationAdvice(chatResponse.analysis_report.action_suggestion)
    }
    
    // MARK: - Private Helper Methods
    
    private func parseOptimizationAdvice(_ response: String) -> [ClauseImprovement] {
        let paragraphs = response
            .replacingOccurrences(of: "\r", with: "")
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var improvements: [ClauseImprovement] = []
        for para in paragraphs {
            let lines = para.components(separatedBy: .newlines)
            let current = lines.first ?? para
            let suggestion = lines.dropFirst().joined(separator: "\n")
            let issues = ["条款可读性与风险提示不足"]
            let rationale = "基于AI分析建议优化当前条款表述，增强明确性与可执行性"
            let expectedBenefit = "降低争议风险，提升条款清晰度"
            let item = ClauseImprovement(
                id: UUID().uuidString,
                currentClause: current,
                issues: issues,
                suggestedClause: suggestion.isEmpty ? current : suggestion,
                rationale: rationale,
                priority: .medium,
                expectedBenefit: expectedBenefit
            )
            improvements.append(item)
        }
        return improvements
    }
    
    private func parseContractReviewRequest(_ request: AgentRequest) -> ContractReviewRequest {
        // 从请求中提取合同内容和类型
        let contractContent = request.content
        let contractType = determineContractType(from: request)
        let reviewScope = determineReviewScope(from: request)
        let focusAreas = determineFocusAreas(from: request)
        
        return ContractReviewRequest(
            content: contractContent,
            type: contractType,
            reviewScope: reviewScope,
            focusAreas: focusAreas
        )
    }
    
    private func performContractReview(_ request: ContractReviewRequest) async throws -> ContractReviewResult {
        // 构建合同审查提示
        let prompt = buildContractReviewPrompt(request)
        
        // 调用API进行合同审查
        let chatResponse = try await apiService.sendChatMessage(
            category: "合同审查",
            role: "合同审查师",
            subtype: request.type.rawValue,
            message: prompt
        )
        
        // 解析审查结果
        let analysisResult = parseContractAnalysis(chatResponse.analysis_report.action_suggestion)
        
        // 识别风险条款
        let riskyClause = try await identifyRiskyClauses(request.content)
        
        // 生成改进建议
        var improvements: [ClauseImprovement] = []
        for focusArea in request.focusAreas {
            let areaImprovements = try await suggestClauseImprovements(request.content, focusArea: focusArea)
            improvements.append(contentsOf: areaImprovements)
        }
        
        // 进行合规性检查
        let complianceIssues = performComplianceCheck(request.content, type: request.type)
        
        return ContractReviewResult(
            contractType: request.type,
            overallRating: analysisResult.overallRating,
            strengthAreas: analysisResult.strengthAreas,
            weaknessAreas: analysisResult.weaknessAreas,
            riskyClause: riskyClause,
            improvements: improvements,
            complianceIssues: complianceIssues,
            legalRecommendations: analysisResult.legalRecommendations,
            confidence: analysisResult.confidence,
            reviewDate: Date()
        )
    }
    
    private func buildContractReviewPrompt(_ request: ContractReviewRequest) -> String {
        var prompt = """
        作为专业的合同审查师，请对以下\(request.type.rawValue)进行全面审查：
        
        合同内容：
        \(request.content)
        
        请从以下方面进行审查：
        """
        
        // 添加审查范围
        switch request.reviewScope {
        case .basic:
            prompt += """
            
            基础审查包括：
            1. 合同结构完整性
            2. 基本条款齐全性
            3. 明显的法律风险
            """
        case .standard:
            prompt += """
            
            标准审查包括：
            1. 合同结构和条款完整性
            2. 权利义务平衡性
            3. 风险条款识别
            4. 执行可行性分析
            5. 基本合规性检查
            """
        case .comprehensive:
            prompt += """
            
            全面审查包括：
            1. 合同结构和逻辑分析
            2. 所有条款的法律效力
            3. 权利义务的平衡性和公平性
            4. 潜在风险的全面识别
            5. 执行和履约的可行性
            6. 争议解决机制的有效性
            7. 合规性的深度检查
            8. 与行业标准的对比
            """
        }
        
        // 添加重点关注领域
        if !request.focusAreas.isEmpty {
            prompt += "\n\n重点关注："
            for area in request.focusAreas {
                prompt += "\n- \(area.rawValue)：\(area.description)"
            }
        }
        
        prompt += """
        
        请提供：
        1. 整体评价和评分（1-10分）
        2. 合同优势分析
        3. 存在的问题和风险
        4. 具体的修改建议
        5. 法律合规性意见
        6. 谈判要点建议
        """
        
        return prompt
    }
    
    private func buildRiskIdentificationPrompt(_ contractContent: String) -> String {
        return """
        请仔细分析以下合同内容，识别所有可能的风险条款：
        
        合同内容：
        \(contractContent)
        
        请识别以下类型的风险条款：
        
        1. 不公平条款
           - 权利义务明显不对等
           - 单方面有利条款
           - 免责条款过度
        
        2. 模糊条款
           - 表述不清晰
           - 标准不明确
           - 执行困难
        
        3. 法律风险条款
           - 可能违法的条款
           - 与法律法规冲突
           - 无法执行的条款
        
        4. 经济风险条款
           - 费用承担不合理
           - 赔偿责任过重
           - 付款条件苛刻
        
        5. 程序风险条款
           - 变更程序复杂
           - 解除条件严格
           - 争议解决不利
        
        对每个风险条款请说明：
        - 具体条款内容
        - 风险类型和等级
        - 可能的不利后果
        - 修改建议
        """
    }
    
    private func buildImprovementPrompt(_ contractContent: String, focusArea: ContractFocusArea) -> String {
        return """
        请针对以下合同在\(focusArea.rawValue)方面提出改进建议：
        
        合同内容：
        \(contractContent)
        
        重点分析：\(focusArea.description)
        
        请提供：
        1. 现有条款的问题分析
        2. 具体的改进建议
        3. 建议的条款文本
        4. 改进后的预期效果
        5. 实施的注意事项
        """
    }
    
    private func parseContractAnalysis(_ response: String) -> ContractAnalysisResult {
        // 提取整体评分
        let overallRating = extractOverallRating(from: response)
        
        // 提取优势和劣势
        let strengthAreas = extractStrengthAreas(from: response)
        let weaknessAreas = extractWeaknessAreas(from: response)
        
        // 提取法律建议
        let legalRecommendations = extractLegalRecommendations(from: response)
        
        // 计算置信度
        let confidence = calculateAnalysisConfidence(response)
        
        return ContractAnalysisResult(
            overallRating: overallRating,
            strengthAreas: strengthAreas,
            weaknessAreas: weaknessAreas,
            legalRecommendations: legalRecommendations,
            confidence: confidence
        )
    }
    
    private func parseRiskyClausesFromResponse(_ response: String) -> [RiskyClause] {
        var riskyClauses: [RiskyClause] = []
        
        // 预定义风险类型模式
        let riskPatterns = [
            ("不公平条款", RiskyClause.RiskType.unfair),
            ("模糊条款", RiskyClause.RiskType.ambiguous),
            ("法律风险", RiskyClause.RiskType.legal),
            ("经济风险", RiskyClause.RiskType.financial),
            ("程序风险", RiskyClause.RiskType.procedural)
        ]
        
        for (index, (pattern, riskType)) in riskPatterns.enumerated() {
            if response.contains(pattern) {
                let clauseContent = extractClauseContent(from: response, pattern: pattern)
                let riskLevel = extractRiskLevel(from: response, pattern: pattern)
                let consequences = extractConsequences(from: response, pattern: pattern)
                let suggestions = extractSuggestions(from: response, pattern: pattern)
                
                riskyClauses.append(RiskyClause(
                    id: "risky-clause-\(index)",
                    clauseContent: clauseContent,
                    riskType: riskType,
                    riskLevel: riskLevel,
                    description: "发现\(pattern)相关风险",
                    potentialConsequences: consequences,
                    suggestions: suggestions
                ))
            }
        }
        
        return riskyClauses
    }
    
    private func parseImprovementsFromResponse(_ response: String) -> [ClauseImprovement] {
        var improvements: [ClauseImprovement] = []
        
        // 查找改进建议模式
        let improvementSections = extractImprovementSections(from: response)
        
        for (index, section) in improvementSections.enumerated() {
            let currentClause = extractCurrentClause(from: section)
            let issues = extractIssues(from: section)
            let suggestedClause = extractSuggestedClause(from: section)
            let rationale = extractRationale(from: section)
            let priority = extractPriority(from: section)
            
            improvements.append(ClauseImprovement(
                id: "improvement-\(index)",
                currentClause: currentClause,
                issues: issues,
                suggestedClause: suggestedClause,
                rationale: rationale,
                priority: priority,
                expectedBenefit: "提升合同条款的准确性和可执行性"
            ))
        }
        
        return improvements
    }
    
    private func performComplianceCheck(_ contractContent: String, type: ContractType) -> [ComplianceIssue] {
        var complianceIssues: [ComplianceIssue] = []
        
        // 基于合同类型检查特定合规要求
        let requiredElements = legalStandards.getRequiredElements(for: type)
        
        for element in requiredElements {
            if !contractContent.contains(element.keyword) {
                complianceIssues.append(ComplianceIssue(
                    id: "compliance-\(element.id)",
                    type: .missingRequiredClause,
                    description: "缺少必要条款：\(element.name)",
                    legalBasis: element.legalBasis,
                    severity: element.severity,
                    recommendation: "建议添加：\(element.description)"
                ))
            }
        }
        
        // 检查违法条款
        let prohibitedPatterns = legalStandards.getProhibitedPatterns()
        for pattern in prohibitedPatterns {
            if contractContent.contains(pattern.keyword) {
                complianceIssues.append(ComplianceIssue(
                    id: "compliance-prohibited-\(pattern.id)",
                    type: .prohibitedClause,
                    description: "发现可能违法条款：\(pattern.description)",
                    legalBasis: pattern.legalBasis,
                    severity: .high,
                    recommendation: "建议删除或修改相关条款"
                ))
            }
        }
        
        return complianceIssues
    }
    
    private func generateContractRecommendations(_ reviewResult: ContractReviewResult) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // 基于整体评分生成建议
        if reviewResult.overallRating < 6 {
            recommendations.append(Recommendation(
                id: "comprehensive-revision",
                title: "全面修订合同",
                description: "合同存在较大问题，建议进行全面修订",
                actionType: .other,
                priority: .critical,
                estimatedCost: 2000,
                timeframe: "1-2周",
                requirements: ["专业律师参与", "全面条款审查", "多轮修改完善"]
            ))
        } else if reviewResult.overallRating < 8 {
            recommendations.append(Recommendation(
                id: "targeted-improvements",
                title: "针对性改进",
                description: "对识别的问题进行针对性修改",
                actionType: .other,
                priority: .high,
                estimatedCost: 1000,
                timeframe: "3-5天",
                requirements: ["重点条款修改", "风险条款优化", "合规性完善"]
            ))
        }
        
        // 基于风险条款生成建议
        let highRiskClauses = reviewResult.riskyClause.filter { $0.riskLevel == .high }
        if !highRiskClauses.isEmpty {
            recommendations.append(Recommendation(
                id: "risk-mitigation",
                title: "风险条款处理",
                description: "优先处理\(highRiskClauses.count)个高风险条款",
                actionType: .other,
                priority: .critical,
                estimatedCost: 800,
                timeframe: "立即处理",
                requirements: ["风险评估", "条款重写", "法律咨询"]
            ))
        }
        
        // 基于合规问题生成建议
        if !reviewResult.complianceIssues.isEmpty {
            recommendations.append(Recommendation(
                id: "compliance-fixing",
                title: "合规性整改",
                description: "修正\(reviewResult.complianceIssues.count)个合规性问题",
                actionType: .other,
                priority: .high,
                estimatedCost: 600,
                timeframe: "1周内",
                requirements: ["法规研究", "条款补充", "合规验证"]
            ))
        }
        
        // 基于改进建议生成行动项
        let highPriorityImprovements = reviewResult.improvements.filter { $0.priority == .high }
        if !highPriorityImprovements.isEmpty {
            recommendations.append(Recommendation(
                id: "priority-improvements",
                title: "优先改进项",
                description: "实施\(highPriorityImprovements.count)个高优先级改进",
                actionType: .other,
                priority: .medium,
                estimatedCost: 400,
                timeframe: "5-7天",
                requirements: ["条款优化", "文本完善", "逻辑梳理"]
            ))
        }
        
        return recommendations
    }
    
    private func generateContractReviewAttachments(_ reviewResult: ContractReviewResult) -> [AgentAttachment] {
        var attachments: [AgentAttachment] = []
        
        // 审查报告
        attachments.append(AgentAttachment(
            id: "contract-review-report",
            name: "合同审查报告",
            type: .document,
            url: nil,
            content: generateReviewReportContent(reviewResult),
            size: nil
        ))
        
        // 风险条款清单
        if !reviewResult.riskyClause.isEmpty {
            attachments.append(AgentAttachment(
                id: "risky-clauses-list",
                name: "风险条款清单",
                type: .checklist,
                url: nil,
                content: generateRiskyClausesContent(reviewResult.riskyClause),
                size: nil
            ))
        }
        
        // 改进建议文档
        if !reviewResult.improvements.isEmpty {
            attachments.append(AgentAttachment(
                id: "improvement-suggestions",
                name: "条款改进建议",
                type: .template,
                url: nil,
                content: generateImprovementSuggestionsContent(reviewResult.improvements),
                size: nil
            ))
        }
        
        // 合规检查报告
        if !reviewResult.complianceIssues.isEmpty {
            attachments.append(AgentAttachment(
                id: "compliance-report",
                name: "合规检查报告",
                type: .reference,
                url: nil,
                content: generateComplianceReportContent(reviewResult.complianceIssues),
                size: nil
            ))
        }
        
        return attachments
    }
    
    private func generateContractFollowUp(_ reviewResult: ContractReviewResult) -> [String] {
        var questions: [String] = []
        
        // 基础问题
        questions.append("您对当前的审查结果满意吗？")
        questions.append("是否需要针对特定条款进行深入分析？")
        
        // 基于评分的问题
        if reviewResult.overallRating < 7 {
            questions.append("您希望优先修改哪些问题条款？")
            questions.append("是否需要重新起草某些关键条款？")
        }
        
        // 基于风险的问题
        if !reviewResult.riskyClause.isEmpty {
            questions.append("对于识别的风险条款，您倾向于修改还是删除？")
            questions.append("这些风险在您的业务场景中是否可以接受？")
        }
        
        // 基于合规的问题
        if !reviewResult.complianceIssues.isEmpty {
            questions.append("您需要了解相关法规的具体要求吗？")
            questions.append("是否需要帮助起草合规条款？")
        }
        
        // 实施相关问题
        questions.append("您计划何时开始合同修改工作？")
        questions.append("是否需要我们协助准备谈判要点？")
        
        return questions
    }
    
    private func formatContractReviewResponse(_ reviewResult: ContractReviewResult) -> String {
        return """
        ## 合同审查结果
        
        **合同类型：** \(reviewResult.contractType.rawValue)
        **整体评分：** \(reviewResult.overallRating)/10
        **审查日期：** \(formatDate(reviewResult.reviewDate))
        **分析置信度：** \(String(format: "%.1f", reviewResult.confidence * 100))%
        
        ### 审查摘要
        
        **优势领域：**
        \(reviewResult.strengthAreas.enumerated().map { index, area in
            "\(index + 1). \(area)"
        }.joined(separator: "\n"))
        
        **需要改进：**
        \(reviewResult.weaknessAreas.enumerated().map { index, area in
            "\(index + 1). \(area)"
        }.joined(separator: "\n"))
        
        ### 关键发现
        
        **风险条款：** \(reviewResult.riskyClause.count)个
        **改进建议：** \(reviewResult.improvements.count)条
        **合规问题：** \(reviewResult.complianceIssues.count)个
        
        ### 主要建议
        \(reviewResult.legalRecommendations.prefix(3).enumerated().map { index, rec in
            "\(index + 1). \(rec)"
        }.joined(separator: "\n"))
        
        详细的审查报告和具体建议请查看附件。
        
        ⚠️ **重要提示**：建议在签署前请专业律师进行最终审查确认。
        """
    }
    
    // MARK: - Content Generation Methods
    
    private func generateReviewReportContent(_ reviewResult: ContractReviewResult) -> String {
        return """
        # 合同审查报告
        
        ## 基本信息
        - 合同类型：\(reviewResult.contractType.rawValue)
        - 审查日期：\(formatDate(reviewResult.reviewDate))
        - 整体评分：\(reviewResult.overallRating)/10
        - 分析置信度：\(String(format: "%.1f", reviewResult.confidence * 100))%
        
        ## 审查结论
        
        ### 优势分析
        \(reviewResult.strengthAreas.enumerated().map { index, area in
            "\(index + 1). \(area)"
        }.joined(separator: "\n"))
        
        ### 问题识别
        \(reviewResult.weaknessAreas.enumerated().map { index, area in
            "\(index + 1). \(area)"
        }.joined(separator: "\n"))
        
        ## 风险评估
        
        共识别 \(reviewResult.riskyClause.count) 个风险条款：
        
        \(reviewResult.riskyClause.enumerated().map { index, clause in
            """
            ### \(index + 1). \(clause.riskType.rawValue)风险
            - **风险等级**：\(clause.riskLevel.rawValue)
            - **条款内容**：\(clause.clauseContent)
            - **风险描述**：\(clause.description)
            - **潜在后果**：\(clause.potentialConsequences.joined(separator: "；"))
            - **建议措施**：\(clause.suggestions.joined(separator: "；"))
            """
        }.joined(separator: "\n\n"))
        
        ## 法律建议
        
        \(reviewResult.legalRecommendations.enumerated().map { index, rec in
            "\(index + 1). \(rec)"
        }.joined(separator: "\n"))
        
        ## 审查结论
        
        \(generateReviewConclusion(reviewResult))
        """
    }
    
    private func generateRiskyClausesContent(_ riskyClauses: [RiskyClause]) -> String {
        return """
        # 风险条款清单
        
        \(riskyClauses.enumerated().map { index, clause in
            """
            ## \(index + 1). \(clause.riskType.rawValue)风险条款
            
            **风险等级：** \(clause.riskLevel.rawValue)
            **条款内容：** \(clause.clauseContent)
            **风险描述：** \(clause.description)
            
            **潜在后果：**
            \(clause.potentialConsequences.enumerated().map { i, consequence in
                "- \(consequence)"
            }.joined(separator: "\n"))
            
            **改进建议：**
            \(clause.suggestions.enumerated().map { i, suggestion in
                "- \(suggestion)"
            }.joined(separator: "\n"))
            
            ---
            """
        }.joined(separator: "\n"))
        """
    }
    
    private func generateImprovementSuggestionsContent(_ improvements: [ClauseImprovement]) -> String {
        return """
        # 条款改进建议
        
        \(improvements.enumerated().map { index, improvement in
            """
            ## \(index + 1). 改进建议 - \(improvement.priority.rawValue)优先级
            
            **当前条款：**
            \(improvement.currentClause)
            
            **存在问题：**
            \(improvement.issues.enumerated().map { i, issue in
                "- \(issue)"
            }.joined(separator: "\n"))
            
            **建议条款：**
            \(improvement.suggestedClause)
            
            **改进理由：**
            \(improvement.rationale)
            
            **预期效果：**
            \(improvement.expectedBenefit)
            
            ---
            """
        }.joined(separator: "\n"))
        """
    }
    
    private func generateComplianceReportContent(_ complianceIssues: [ComplianceIssue]) -> String {
        return """
        # 合规检查报告
        
        共发现 \(complianceIssues.count) 个合规性问题：
        
        \(complianceIssues.enumerated().map { index, issue in
            """
            ## \(index + 1). \(issue.type.rawValue)
            
            **问题描述：** \(issue.description)
            **法律依据：** \(issue.legalBasis)
            **严重程度：** \(issue.severity.rawValue)
            **整改建议：** \(issue.recommendation)
            
            ---
            """
        }.joined(separator: "\n"))
        """
    }
    
    private func generateReviewConclusion(_ reviewResult: ContractReviewResult) -> String {
        let ratingDescription: String
        
        switch reviewResult.overallRating {
        case 9...10:
            ratingDescription = "合同质量优秀，条款完善，风险可控"
        case 7..<9:
            ratingDescription = "合同质量良好，存在少量需要优化的地方"
        case 5..<7:
            ratingDescription = "合同质量一般，存在一些需要改进的问题"
        case 3..<5:
            ratingDescription = "合同存在较大问题，建议进行重大修改"
        default:
            ratingDescription = "合同存在严重问题，建议重新起草"
        }
        
        return """
        基于本次审查，该合同\(ratingDescription)。
        
        建议在签署前：
        1. 处理所有高风险条款
        2. 解决合规性问题
        3. 实施关键改进建议
        4. 请专业律师进行最终确认
        
        如需进一步的法律支持，建议咨询专业律师团队。
        """
    }
    
    // MARK: - Helper Methods
    
    private func determineContractType(from request: AgentRequest) -> ContractType {
        let content = request.content.lowercased()
        
        if content.contains("劳动") || content.contains("雇佣") {
            return .employment
        } else if content.contains("租赁") || content.contains("出租") {
            return .lease
        } else if content.contains("买卖") || content.contains("购买") {
            return .purchase
        } else if content.contains("服务") {
            return .service
        } else if content.contains("合伙") {
            return .partnership
        } else if content.contains("保密") {
            return .nda
        } else if content.contains("许可") || content.contains("授权") {
            return .license
        } else {
            return .service // 默认类型
        }
    }
    
    private func determineReviewScope(from request: AgentRequest) -> ReviewScope {
        if request.priority == .urgent {
            return .basic
        } else if request.content.count > 2000 {
            return .comprehensive
        } else {
            return .standard
        }
    }
    
    private func determineFocusAreas(from request: AgentRequest) -> [ContractFocusArea] {
        var focusAreas: [ContractFocusArea] = []
        
        let content = request.content.lowercased()
        
        if content.contains("权利") || content.contains("义务") {
            focusAreas.append(.rightsAndObligations)
        }
        if content.contains("付款") || content.contains("费用") {
            focusAreas.append(.paymentTerms)
        }
        if content.contains("违约") || content.contains("责任") {
            focusAreas.append(.liabilityAndBreach)
        }
        if content.contains("终止") || content.contains("解除") {
            focusAreas.append(.terminationClauses)
        }
        if content.contains("争议") || content.contains("仲裁") {
            focusAreas.append(.disputeResolution)
        }
        
        // 如果没有特定关注点，返回所有常见领域
        if focusAreas.isEmpty {
            focusAreas = [.rightsAndObligations, .paymentTerms, .liabilityAndBreach]
        }
        
        return focusAreas
    }
    
    // MARK: - Text Extraction Methods
    
    private func extractOverallRating(from response: String) -> Int {
        // 查找评分模式
        let patterns = ["评分.*?([0-9]+)", "得分.*?([0-9]+)", "分数.*?([0-9]+)"]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: response, range: NSRange(response.startIndex..., in: response)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: response),
               let rating = Int(response[range]) {
                return min(10, max(1, rating))
            }
        }
        
        // 如果没有找到具体分数，根据描述推断
        if response.contains("优秀") || response.contains("很好") {
            return 9
        } else if response.contains("良好") || response.contains("不错") {
            return 7
        } else if response.contains("一般") || response.contains("普通") {
            return 5
        } else if response.contains("较差") || response.contains("问题") {
            return 3
        } else {
            return 6 // 默认值
        }
    }
    
    private func extractStrengthAreas(from response: String) -> [String] {
        return extractListItems(from: response, keywords: ["优势", "优点", "强项", "好的地方"])
    }
    
    private func extractWeaknessAreas(from response: String) -> [String] {
        return extractListItems(from: response, keywords: ["劣势", "缺点", "问题", "不足", "需要改进"])
    }
    
    private func extractLegalRecommendations(from response: String) -> [String] {
        return extractListItems(from: response, keywords: ["建议", "推荐", "应该", "需要"])
    }
    
    private func extractListItems(from response: String, keywords: [String]) -> [String] {
        var items: [String] = []
        
        for keyword in keywords {
            let lines = response.components(separatedBy: .newlines)
            for line in lines {
                if line.contains(keyword) && (line.contains("1.") || line.contains("-") || line.contains("•")) {
                    let cleanedLine = line
                        .replacingOccurrences(of: "^[0-9]+\\.", with: "", options: .regularExpression)
                        .replacingOccurrences(of: "^-", with: "")
                        .replacingOccurrences(of: "^•", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !cleanedLine.isEmpty && cleanedLine.count > 5 {
                        items.append(cleanedLine)
                    }
                }
            }
        }
        
        return Array(Set(items)).prefix(5).map { String($0) }
    }
    
    private func calculateAnalysisConfidence(_ response: String) -> Double {
        var confidence = 0.7 // 基础置信度
        
        // 基于响应质量调整
        if response.count > 1000 { confidence += 0.1 }
        if response.contains("具体") || response.contains("详细") { confidence += 0.05 }
        if response.contains("分析") || response.contains("评估") { confidence += 0.05 }
        if response.contains("建议") || response.contains("推荐") { confidence += 0.05 }
        if response.contains("风险") || response.contains("问题") { confidence += 0.05 }
        
        return min(1.0, confidence)
    }
    
    // 其他提取方法的简化实现
    private func extractClauseContent(from response: String, pattern: String) -> String {
        return "相关条款内容"
    }
    
    private func extractRiskLevel(from response: String, pattern: String) -> RiskyClause.RiskLevel {
        if response.contains("高") || response.contains("严重") {
            return .high
        } else if response.contains("中") || response.contains("一般") {
            return .medium
        } else {
            return .low
        }
    }
    
    private func extractConsequences(from response: String, pattern: String) -> [String] {
        return ["可能导致法律争议", "影响合同执行", "增加经济损失风险"]
    }
    
    private func extractSuggestions(from response: String, pattern: String) -> [String] {
        return ["修改相关条款", "增加保护措施", "明确责任界限"]
    }
    
    private func extractImprovementSections(from response: String) -> [String] {
        return response.components(separatedBy: "建议").filter { !$0.isEmpty }
    }
    
    private func extractCurrentClause(from section: String) -> String {
        return "当前条款内容"
    }
    
    private func extractIssues(from section: String) -> [String] {
        return ["条款不够明确", "权利义务不平衡"]
    }
    
    private func extractSuggestedClause(from section: String) -> String {
        return "建议的修改条款"
    }
    
    private func extractRationale(from section: String) -> String {
        return "改进理由说明"
    }
    
    private func extractPriority(from section: String) -> ClauseImprovement.Priority {
        if section.contains("紧急") || section.contains("重要") {
            return .high
        } else if section.contains("一般") {
            return .medium
        } else {
            return .low
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

private struct ContractReviewRequest {
    let content: String
    let type: ContractType
    let reviewScope: ReviewScope
    let focusAreas: [ContractFocusArea]
}

private enum ReviewScope {
    case basic      // 基础审查
    case standard   // 标准审查
    case comprehensive // 全面审查
}

private enum ContractFocusArea: String, CaseIterable {
    case rightsAndObligations = "权利义务"
    case paymentTerms = "付款条款"
    case liabilityAndBreach = "责任违约"
    case terminationClauses = "终止条款"
    case disputeResolution = "争议解决"
    case complianceRequirements = "合规要求"
    case intellectualProperty = "知识产权"
    case confidentiality = "保密条款"
    
    var description: String {
        switch self {
        case .rightsAndObligations:
            return "分析双方权利义务的平衡性和合理性"
        case .paymentTerms:
            return "审查付款方式、时间和条件的合理性"
        case .liabilityAndBreach:
            return "评估违约责任和赔偿条款的公平性"
        case .terminationClauses:
            return "检查合同终止和解除条件的合理性"
        case .disputeResolution:
            return "分析争议解决机制的有效性"
        case .complianceRequirements:
            return "检查法律法规合规性要求"
        case .intellectualProperty:
            return "审查知识产权保护和归属条款"
        case .confidentiality:
            return "评估保密义务和信息保护条款"
        }
    }
}

private struct ContractReviewResult {
    let contractType: ContractType
    let overallRating: Int
    let strengthAreas: [String]
    let weaknessAreas: [String]
    let riskyClause: [RiskyClause]
    let improvements: [ClauseImprovement]
    let complianceIssues: [ComplianceIssue]
    let legalRecommendations: [String]
    let confidence: Double
    let reviewDate: Date
}

private struct ContractAnalysisResult {
    let overallRating: Int
    let strengthAreas: [String]
    let weaknessAreas: [String]
    let legalRecommendations: [String]
    let confidence: Double
}

private struct RiskyClause {
    let id: String
    let clauseContent: String
    let riskType: RiskType
    let riskLevel: RiskLevel
    let description: String
    let potentialConsequences: [String]
    let suggestions: [String]
    
    enum RiskType: String {
        case unfair = "不公平条款"
        case ambiguous = "模糊条款"
        case legal = "法律风险"
        case financial = "经济风险"
        case procedural = "程序风险"
    }
    
    enum RiskLevel: String {
        case low = "低风险"
        case medium = "中风险"
        case high = "高风险"
    }
}

private struct ClauseImprovement {
    let id: String
    let currentClause: String
    let issues: [String]
    let suggestedClause: String
    let rationale: String
    let priority: Priority
    let expectedBenefit: String
    
    enum Priority: String {
        case low = "低"
        case medium = "中"
        case high = "高"
    }
}

private struct ComplianceIssue {
    let id: String
    let type: ComplianceType
    let description: String
    let legalBasis: String
    let severity: ComplianceSeverity
    let recommendation: String
    
    enum ComplianceType: String {
        case missingRequiredClause = "缺少必要条款"
        case prohibitedClause = "违法条款"
        case inadequateProtection = "保护不足"
        case proceduralIssue = "程序问题"
    }
    
    enum ComplianceSeverity: String {
        case low = "低"
        case medium = "中"
        case high = "高"
        case critical = "严重"
    }
}

private class ContractTemplateLibrary {
    // 合同模板库的简化实现
    func getTemplate(for contractType: ContractType) -> ContractTemplate? {
        return nil // 简化实现
    }
}

private struct ContractTemplate {
    let id: String
    let name: String
    let type: ContractType
    let requiredClauses: [String]
    let optionalClauses: [String]
}

private class LegalStandardsDatabase {
    // 法律标准数据库的简化实现
    func getRequiredElements(for contractType: ContractType) -> [RequiredElement] {
        return [] // 简化实现
    }
    
    func getProhibitedPatterns() -> [ProhibitedPattern] {
        return [] // 简化实现
    }
}

private struct RequiredElement {
    let id: String
    let name: String
    let keyword: String
    let description: String
    let legalBasis: String
    let severity: ComplianceIssue.ComplianceSeverity
}

private struct ProhibitedPattern {
    let id: String
    let keyword: String
    let description: String
    let legalBasis: String
}