import Foundation

/// 诉讼顾问代理 - 专门提供诉讼策略和程序指导
class DefaultLitigationAdvisorAgent: AIAgent {
    
    // MARK: - AIAgent Properties
    let id: String = "litigation-advisor-001"
    let name: String = "诉讼顾问"
    let description: String = "专业的诉讼顾问代理，提供诉讼策略制定、程序指导和胜诉概率分析"
    let agentType: AgentType = .litigationAdvisor
    let specializations: [String] = [
        "诉讼策略制定", "程序指导", "证据规划", 
        "胜诉概率分析", "庭审准备", "上诉建议"
    ]
    var isActive: Bool = true
    
    // MARK: - Private Properties
    private let apiService: APIService
    private let litigationDatabase: LitigationKnowledgeBase
    private let courtRules: CourtRulesDatabase
    
    // MARK: - Initialization
    init(apiService: APIService = .shared) {
        self.apiService = apiService
        self.litigationDatabase = LitigationKnowledgeBase()
        self.courtRules = CourtRulesDatabase()
    }
    
    // MARK: - AIAgent Methods
    
    func processRequest(_ request: AgentRequest) async throws -> AgentResponse {
        let startTime = Date()
        
        guard canHandle(request.caseType ?? .contractDispute) else {
            throw AgentError.unsupportedCaseType(request.caseType?.rawValue ?? "未知")
        }
        
        do {
            // 解析诉讼咨询请求
            let litigationRequest = parseLitigationRequest(request)
            
            // 执行诉讼分析
            let litigationAnalysis = try await performLitigationAnalysis(litigationRequest)
            
            // 生成诉讼建议
            let recommendations = generateLitigationRecommendations(litigationAnalysis)
            
            // 创建诉讼指导附件
            let attachments = generateLitigationAttachments(litigationAnalysis)
            
            // 生成后续问题
            let followUpQuestions = generateLitigationFollowUp(litigationAnalysis)
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            return AgentResponse(
                id: UUID().uuidString,
                requestId: request.id,
                agentId: id,
                content: formatLitigationResponse(litigationAnalysis),
                confidence: litigationAnalysis.confidence,
                recommendations: recommendations,
                attachments: attachments,
                followUpQuestions: followUpQuestions,
                createdAt: Date(),
                processingTime: processingTime
            )
            
        } catch {
            throw AgentError.processingFailed("诉讼咨询失败: \(error.localizedDescription)")
        }
    }
    
    func canHandle(_ caseType: CaseType) -> Bool {
        // 诉讼顾问可以处理大部分需要诉讼的案件类型
        return true
    }
    
    // MARK: - Specialized Litigation Methods
    
    fileprivate func analyzeLitigationProspects(_ caseDetails: CaseDetails) async throws -> LitigationProspects {
        let analysisRequest = LitigationAnalysisRequest(
            caseDetails: caseDetails,
            analysisType: .comprehensive,
            focusAreas: [.winningProbability, .costBenefit, .timeframe, .riskAssessment]
        )
        
        let analysis = try await performLitigationAnalysis(analysisRequest)
        
        return LitigationProspects(
            winningProbability: analysis.winningProbability,
            estimatedDuration: analysis.estimatedDuration,
            estimatedCosts: analysis.estimatedCosts,
            keyRisks: analysis.identifiedRisks,
            strategicOptions: analysis.strategicOptions,
            recommendation: analysis.overallRecommendation
        )
    }
    
    fileprivate func developLitigationStrategy(_ caseDetails: CaseDetails, objectives: [LitigationObjective]) async throws -> LitigationStrategy {
        let prompt = buildStrategyDevelopmentPrompt(caseDetails, objectives: objectives)
        
        let chatResponse = try await apiService.sendChatMessage(
            category: "诉讼策略",
            role: "诉讼策略专家",
            subtype: caseDetails.caseType.rawValue,
            message: prompt
        )
        
        return parseLitigationStrategy(chatResponse.analysis_report.next_steps.process_guidance)
    }
    
    fileprivate func planEvidenceStrategy(_ caseDetails: CaseDetails) async throws -> EvidenceStrategy {
        let prompt = buildEvidenceStrategyPrompt(caseDetails)
        
        let chatResponse = try await apiService.sendChatMessage(
            category: "证据策略",
            role: "证据专家",
            subtype: caseDetails.caseType.rawValue,
            message: prompt
        )
        
        return parseEvidenceStrategy(chatResponse.analysis_report.next_steps.process_guidance)
    }
    
    fileprivate func assessTrialReadiness(_ caseDetails: CaseDetails) async throws -> TrialReadinessAssessment {
        let prompt = buildTrialReadinessPrompt(caseDetails)
        
        let chatResponse = try await apiService.sendChatMessage(
            category: "庭审准备",
            role: "庭审专家",
            subtype: caseDetails.caseType.rawValue,
            message: prompt
        )
        
        return parseTrialReadiness(chatResponse.analysis_report.next_steps.process_guidance)
    }
    
    // MARK: - Private Helper Methods
    
    private func parseLitigationRequest(_ request: AgentRequest) -> LitigationAnalysisRequest {
        let analysisType = determineLitigationAnalysisType(request)
        let focusAreas = determineLitigationFocusAreas(request)
        
        return LitigationAnalysisRequest(
            caseDetails: request.context?.caseDetails,
            analysisType: analysisType,
            focusAreas: focusAreas
        )
    }
    
    private func performLitigationAnalysis(_ request: LitigationAnalysisRequest) async throws -> LitigationAnalysisResult {
        // 构建诉讼分析提示
        let prompt = buildLitigationAnalysisPrompt(request)
        
        // 调用API进行分析
        let chatResponse = try await apiService.sendChatMessage(
            category: "诉讼分析",
            role: "诉讼分析专家",
            subtype: request.caseDetails?.caseType.rawValue ?? "一般案件",
            message: prompt
        )
        
        // 解析分析结果
        let winningProbability = extractWinningProbability(from: chatResponse.analysis_report.next_steps.process_guidance)
        let estimatedDuration = extractEstimatedDuration(from: chatResponse.analysis_report.next_steps.process_guidance)
        let estimatedCosts = extractEstimatedCosts(from: chatResponse.analysis_report.next_steps.process_guidance)
        let identifiedRisks = extractLitigationRisks(from: chatResponse.analysis_report.next_steps.process_guidance)
        let strategicOptions = extractStrategicOptions(from: chatResponse.analysis_report.next_steps.process_guidance)
        let overallRecommendation = extractOverallRecommendation(from: chatResponse.analysis_report.next_steps.process_guidance)
        let confidence = calculateLitigationConfidence(chatResponse.analysis_report.next_steps.process_guidance)
        
        // 获取程序指导
        let proceduralGuidance = generateProceduralGuidance(request.caseDetails?.caseType)
        
        return LitigationAnalysisResult(
            winningProbability: winningProbability,
            estimatedDuration: estimatedDuration,
            estimatedCosts: estimatedCosts,
            identifiedRisks: identifiedRisks,
            strategicOptions: strategicOptions,
            proceduralGuidance: proceduralGuidance,
            overallRecommendation: overallRecommendation,
            confidence: confidence,
            analysisDate: Date()
        )
    }
    
    private func buildLitigationAnalysisPrompt(_ request: LitigationAnalysisRequest) -> String {
        var prompt = """
        作为专业的诉讼顾问，请对以下案件进行全面的诉讼分析：
        """
        
        if let caseDetails = request.caseDetails {
            prompt += """
            
            案件信息：
            - 案件类型：\(caseDetails.caseType.rawValue)
            - 案件标题：\(caseDetails.title)
            - 案件描述：\(caseDetails.description)
            - 案件状态：\(caseDetails.status.rawValue)
            - 当事人：\(caseDetails.involvedParties.map { "\($0.name)(\($0.role.rawValue))" }.joined(separator: ", "))
            """
            
            if !caseDetails.documents.isEmpty {
                prompt += "\n- 相关文档：\(caseDetails.documents.joined(separator: ", "))"
            }
            
            if !caseDetails.timeline.isEmpty {
                prompt += "\n- 案件时间线：\n"
                for event in caseDetails.timeline.sorted(by: { $0.date < $1.date }) {
                    prompt += "  \(formatDate(event.date)): \(event.description)\n"
                }
            }
        }
        
        prompt += """
        
        请从以下方面进行分析：
        
        1. 胜诉概率评估
           - 基于现有证据和法律依据
           - 考虑对方可能的抗辩
           - 分析法院倾向和类似案例
           - 给出具体概率估算（百分比）
        
        2. 诉讼时间预估
           - 一审预计时长
           - 可能的二审时间
           - 执行阶段时长
           - 总体时间框架
        
        3. 诉讼成本分析
           - 律师费预估
           - 法院费用
           - 其他相关费用
           - 败诉风险成本
        
        4. 风险因素识别
           - 证据风险
           - 程序风险
           - 执行风险
           - 其他潜在风险
        
        5. 策略选择建议
           - 是否适合诉讼
           - 最佳诉讼时机
           - 诉讼策略方向
           - 替代解决方案
        
        6. 程序指导要点
           - 管辖法院选择
           - 起诉材料准备
           - 证据收集要求
           - 关键程序节点
        """
        
        // 添加特定分析重点
        if !request.focusAreas.isEmpty {
            prompt += "\n\n特别关注："
            for area in request.focusAreas {
                prompt += "\n- \(area.rawValue)"
            }
        }
        
        return prompt
    }
    
    private func buildStrategyDevelopmentPrompt(_ caseDetails: CaseDetails, objectives: [LitigationObjective]) -> String {
        return """
        请为以下案件制定详细的诉讼策略：
        
        案件信息：
        - 类型：\(caseDetails.caseType.rawValue)
        - 描述：\(caseDetails.description)
        - 当事人：\(caseDetails.involvedParties.map { "\($0.name)(\($0.role.rawValue))" }.joined(separator: ", "))
        
        诉讼目标：
        \(objectives.map { "- \($0.rawValue)" }.joined(separator: "\n"))
        
        请制定包含以下内容的策略：
        
        1. 整体策略框架
           - 主要论点和主张
           - 核心争议焦点
           - 策略优先级
        
        2. 分阶段策略计划
           - 准备阶段策略
           - 一审阶段策略
           - 可能的二审策略
           - 执行阶段策略
        
        3. 证据收集和使用策略
           - 关键证据识别
           - 证据收集计划
           - 证据展示策略
        
        4. 法庭论辩策略
           - 开庭陈述要点
           - 质证策略
           - 辩论重点
           - 最后陈述框架
        
        5. 风险应对策略
           - 对方可能抗辩及应对
           - 程序风险防范
           - 不利情况应急预案
        
        6. 和解谈判策略
           - 和解时机把握
           - 谈判底线设定
           - 和解条件设计
        """
    }
    
    private func buildEvidenceStrategyPrompt(_ caseDetails: CaseDetails) -> String {
        return """
        请为以下\(caseDetails.caseType.rawValue)案件制定证据策略：
        
        案件描述：\(caseDetails.description)
        现有文档：\(caseDetails.documents.joined(separator: ", "))
        
        请分析：
        
        1. 证据需求分析
           - 需要证明的关键事实
           - 每个事实对应的证据类型
           - 证据的证明力评估
        
        2. 现有证据评估
           - 证据充分性分析
           - 证据质量评价
           - 证据链完整性检查
        
        3. 补充证据计划
           - 需要补充的证据
           - 证据收集方法
           - 收集时间安排
           - 可能的困难和解决方案
        
        4. 证据保全建议
           - 需要保全的关键证据
           - 保全的紧急程度
           - 保全程序和方法
        
        5. 证据展示策略
           - 证据提交顺序
           - 证据组织方式
           - 关键证据突出方法
        
        6. 对方证据应对
           - 预判对方可能的证据
           - 质证策略准备
           - 反驳证据收集
        """
    }
    
    private func buildTrialReadinessPrompt(_ caseDetails: CaseDetails) -> String {
        return """
        请评估以下案件的庭审准备情况：
        
        案件信息：
        - 类型：\(caseDetails.caseType.rawValue)
        - 描述：\(caseDetails.description)
        - 状态：\(caseDetails.status.rawValue)
        
        请从以下方面评估：
        
        1. 材料准备情况
           - 起诉状/答辩状完整性
           - 证据材料齐全性
           - 法律依据充分性
        
        2. 程序准备情况
           - 管辖异议处理
           - 财产保全执行
           - 证据交换完成
        
        3. 论辩准备情况
           - 争议焦点梳理
           - 论辩要点准备
           - 质证策略制定
        
        4. 团队准备情况
           - 律师团队配置
           - 专家证人准备
           - 当事人培训
        
        5. 风险防范准备
           - 程序风险识别
           - 应急预案制定
           - 备选策略准备
        
        请给出准备充分度评分（1-10分）和改进建议。
        """
    }
    
    private func generateProceduralGuidance(_ caseType: CaseType?) -> [ProceduralStep] {
        guard let caseType = caseType else {
            return getGeneralProceduralSteps()
        }
        
        let specificSteps = courtRules.getProceduralSteps(for: caseType)
        return specificSteps.isEmpty ? getGeneralProceduralSteps() : specificSteps
    }
    
    private func getGeneralProceduralSteps() -> [ProceduralStep] {
        return [
            ProceduralStep(
                id: "step-1",
                title: "准备起诉材料",
                description: "准备起诉状、证据材料和相关文档",
                timeframe: "1-2周",
                requirements: ["起诉状", "身份证明", "证据清单"],
                isOptional: false
            ),
            ProceduralStep(
                id: "step-2",
                title: "法院立案",
                description: "向有管辖权的法院提交起诉材料",
                timeframe: "1-3天",
                requirements: ["起诉材料", "诉讼费", "送达地址"],
                isOptional: false
            ),
            ProceduralStep(
                id: "step-3",
                title: "庭前准备",
                description: "准备开庭相关材料和策略",
                timeframe: "2-4周",
                requirements: ["庭审提纲", "证据整理", "质证策略"],
                isOptional: false
            ),
            ProceduralStep(
                id: "step-4",
                title: "开庭审理",
                description: "参加法庭审理，进行举证质证和辩论",
                timeframe: "1-2天",
                requirements: ["出庭人员", "证据原件", "代理手续"],
                isOptional: false
            ),
            ProceduralStep(
                id: "step-5",
                title: "判决执行",
                description: "申请强制执行或履行判决",
                timeframe: "根据情况而定",
                requirements: ["生效判决书", "执行申请书"],
                isOptional: true
            )
        ]
    }
    
    private func generateLitigationRecommendations(_ analysis: LitigationAnalysisResult) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // 基于胜诉概率的建议
        if analysis.winningProbability >= 0.7 {
            recommendations.append(Recommendation(
                id: "pursue-litigation",
                title: "积极推进诉讼",
                description: "胜诉概率较高(\(Int(analysis.winningProbability * 100))%)，建议积极推进诉讼程序",
                actionType: .litigate,
                priority: .high,
                estimatedCost: analysis.estimatedCosts.total,
                timeframe: analysis.estimatedDuration,
                requirements: ["完善证据材料", "选择专业律师团队", "制定详细诉讼策略"]
            ))
        } else if analysis.winningProbability >= 0.4 {
            recommendations.append(Recommendation(
                id: "cautious-litigation",
                title: "谨慎推进诉讼",
                description: "胜诉概率中等(\(Int(analysis.winningProbability * 100))%)，建议在充分准备后谨慎推进",
                actionType: .litigate,
                priority: .medium,
                estimatedCost: analysis.estimatedCosts.total,
                timeframe: analysis.estimatedDuration,
                requirements: ["强化证据链", "评估和解可能", "制定风险控制措施"]
            ))
        } else {
            recommendations.append(Recommendation(
                id: "consider-alternatives",
                title: "考虑替代方案",
                description: "胜诉概率较低(\(Int(analysis.winningProbability * 100))%)，建议优先考虑和解或调解",
                actionType: .mediate,
                priority: .high,
                estimatedCost: analysis.estimatedCosts.total * 0.3,
                timeframe: "1-2个月",
                requirements: ["评估和解底线", "寻找调解机构", "准备谈判策略"]
            ))
        }
        
        // 基于风险的建议
        let highRisks = analysis.identifiedRisks.filter { $0.severity == .high }
        if !highRisks.isEmpty {
            recommendations.append(Recommendation(
                id: "risk-mitigation",
                title: "风险缓解措施",
                description: "识别出\(highRisks.count)个高风险因素，需要制定专门的缓解策略",
                actionType: .other,
                priority: .critical,
                estimatedCost: 1000,
                timeframe: "立即执行",
                requirements: ["风险评估报告", "缓解措施制定", "应急预案准备"]
            ))
        }
        
        // 基于成本效益的建议
        if let costBenefit = calculateCostBenefit(analysis.estimatedCosts, winningProbability: analysis.winningProbability) {
            if costBenefit < 0.5 {
                recommendations.append(Recommendation(
                    id: "cost-benefit-review",
                    title: "成本效益评估",
                    description: "诉讼成本效益比较低，建议重新评估诉讼必要性",
                    actionType: .other,
                    priority: .medium,
                    estimatedCost: 300,
                    timeframe: "1周内",
                    requirements: ["详细成本分析", "预期收益评估", "替代方案比较"]
                ))
            }
        }
        
        // 程序相关建议
        recommendations.append(Recommendation(
            id: "procedural-compliance",
            title: "程序合规确保",
            description: "确保所有诉讼程序符合法院要求，避免程序性败诉",
            actionType: .other,
            priority: .high,
            estimatedCost: 500,
            timeframe: "持续关注",
            requirements: analysis.proceduralGuidance.map { $0.title }
        ))
        
        return recommendations
    }
    
    private func generateLitigationAttachments(_ analysis: LitigationAnalysisResult) -> [AgentAttachment] {
        var attachments: [AgentAttachment] = []
        
        // 诉讼分析报告
        attachments.append(AgentAttachment(
            id: "litigation-analysis-report",
            name: "诉讼分析报告",
            type: .document,
            url: nil,
            content: generateLitigationReportContent(analysis),
            size: nil
        ))
        
        // 程序指导清单
        attachments.append(AgentAttachment(
            id: "procedural-checklist",
            name: "诉讼程序清单",
            type: .checklist,
            url: nil,
            content: generateProceduralChecklistContent(analysis.proceduralGuidance),
            size: nil
        ))
        
        // 风险评估表
        if !analysis.identifiedRisks.isEmpty {
            attachments.append(AgentAttachment(
                id: "litigation-risks",
                name: "诉讼风险评估表",
                type: .reference,
                url: nil,
                content: generateRiskAssessmentContent(analysis.identifiedRisks),
                size: nil
            ))
        }
        
        // 策略选择指南
        if !analysis.strategicOptions.isEmpty {
            attachments.append(AgentAttachment(
                id: "strategic-options",
                name: "诉讼策略选择指南",
                type: .reference,
                url: nil,
                content: generateStrategicOptionsContent(analysis.strategicOptions),
                size: nil
            ))
        }
        
        return attachments
    }
    
    private func generateLitigationFollowUp(_ analysis: LitigationAnalysisResult) -> [String] {
        var questions: [String] = []
        
        // 基础问题
        questions.append("您对当前的诉讼分析结果有什么看法？")
        questions.append("是否需要针对特定方面进行更详细的分析？")
        
        // 基于胜诉概率的问题
        if analysis.winningProbability >= 0.7 {
            questions.append("您希望立即启动诉讼程序吗？")
            questions.append("需要我们协助制定详细的诉讼策略吗？")
        } else if analysis.winningProbability < 0.4 {
            questions.append("您是否愿意考虑和解或调解方案？")
            questions.append("需要评估其他解决途径的可行性吗？")
        }
        
        // 基于成本的问题
        questions.append("预估的诉讼成本是否在您的预算范围内？")
        questions.append("是否需要了解降低诉讼成本的方法？")
        
        // 基于时间的问题
        questions.append("预估的诉讼时间是否符合您的预期？")
        questions.append("是否有时间上的紧急要求需要考虑？")
        
        // 程序相关问题
        questions.append("您对诉讼程序有哪些具体疑问？")
        questions.append("需要我们协助准备起诉材料吗？")
        
        // 风险相关问题
        if !analysis.identifiedRisks.isEmpty {
            questions.append("对于识别的风险，您希望如何应对？")
            questions.append("是否需要制定详细的风险控制计划？")
        }
        
        return questions
    }
    
    private func formatLitigationResponse(_ analysis: LitigationAnalysisResult) -> String {
        return """
        ## 诉讼分析结果
        
        **胜诉概率：** \(Int(analysis.winningProbability * 100))%
        **预估时长：** \(analysis.estimatedDuration)
        **预估成本：** ¥\(analysis.estimatedCosts.total)
        **分析置信度：** \(String(format: "%.1f", analysis.confidence * 100))%
        
        ### 成本构成
        - 律师费：¥\(analysis.estimatedCosts.lawyerFees)
        - 法院费用：¥\(analysis.estimatedCosts.courtFees)
        - 其他费用：¥\(analysis.estimatedCosts.otherCosts)
        
        ### 风险评估
        识别风险因素 \(analysis.identifiedRisks.count) 个：
        \(analysis.identifiedRisks.prefix(3).enumerated().map { index, risk in
            "- \(risk.type.rawValue)：\(risk.severity.rawValue)风险"
        }.joined(separator: "\n"))
        
        ### 策略建议
        \(analysis.strategicOptions.prefix(3).enumerated().map { index, option in
            "\(index + 1). \(option.title) - \(option.description)"
        }.joined(separator: "\n"))
        
        ### 总体建议
        \(analysis.overallRecommendation)
        
        详细的分析报告和程序指导请查看附件。
        
        ⚠️ **重要提示**：此分析基于现有信息，实际情况可能因新证据或法律变化而有所不同。
        """
    }
    
    // MARK: - Content Generation Methods
    
    private func generateLitigationReportContent(_ analysis: LitigationAnalysisResult) -> String {
        return """
        # 诉讼分析报告
        
        ## 分析概要
        - 分析日期：\(formatDate(analysis.analysisDate))
        - 胜诉概率：\(Int(analysis.winningProbability * 100))%
        - 预估时长：\(analysis.estimatedDuration)
        - 预估总成本：¥\(analysis.estimatedCosts.total)
        - 分析置信度：\(String(format: "%.1f", analysis.confidence * 100))%
        
        ## 胜诉概率分析
        
        基于现有证据和法律依据，预估胜诉概率为 **\(Int(analysis.winningProbability * 100))%**。
        
        **影响因素：**
        - 证据强度和完整性
        - 法律依据的充分性
        - 对方可能的抗辩策略
        - 类似案例的判决倾向
        
        ## 成本效益分析
        
        ### 成本构成
        - **律师费**：¥\(analysis.estimatedCosts.lawyerFees)
        - **法院费用**：¥\(analysis.estimatedCosts.courtFees)
        - **其他费用**：¥\(analysis.estimatedCosts.otherCosts)
        - **总计**：¥\(analysis.estimatedCosts.total)
        
        ### 时间成本
        预计诉讼周期：\(analysis.estimatedDuration)
        
        ## 风险因素分析
        
        \(analysis.identifiedRisks.enumerated().map { index, risk in
            """
            ### \(index + 1). \(risk.type.rawValue)
            - **严重程度**：\(risk.severity.rawValue)
            - **描述**：\(risk.description)
            - **缓解措施**：\(risk.mitigationMeasures.joined(separator: "；"))
            """
        }.joined(separator: "\n\n"))
        
        ## 策略选择分析
        
        \(analysis.strategicOptions.enumerated().map { index, option in
            """
            ### \(index + 1). \(option.title)
            - **描述**：\(option.description)
            - **优势**：\(option.advantages.joined(separator: "；"))
            - **劣势**：\(option.disadvantages.joined(separator: "；"))
            - **适用场景**：\(option.applicableScenarios.joined(separator: "；"))
            """
        }.joined(separator: "\n\n"))
        
        ## 总体建议
        
        \(analysis.overallRecommendation)
        
        ## 下一步行动
        
        1. 根据分析结果决定是否启动诉讼程序
        2. 如决定诉讼，按照程序清单准备相关材料
        3. 实施风险缓解措施
        4. 定期评估案件进展并调整策略
        """
    }
    
    private func generateProceduralChecklistContent(_ steps: [ProceduralStep]) -> String {
        return """
        # 诉讼程序清单
        
        \(steps.enumerated().map { index, step in
            """
            ## \(index + 1). \(step.title) \(step.isOptional ? "(可选)" : "(必需)")
            
            **描述**：\(step.description)
            **时间框架**：\(step.timeframe)
            
            **所需材料/条件**：
            \(step.requirements.enumerated().map { i, requirement in
                "- [ ] \(requirement)"
            }.joined(separator: "\n"))
            
            ---
            """
        }.joined(separator: "\n"))
        
        ## 注意事项
        
        1. 请严格按照时间要求完成各项程序
        2. 所有材料必须真实、完整、准确
        3. 如有疑问及时咨询专业律师
        4. 保留所有程序性文件的副本
        """
    }
    
    private func generateRiskAssessmentContent(_ risks: [LitigationRisk]) -> String {
        return """
        # 诉讼风险评估表
        
        \(risks.enumerated().map { index, risk in
            """
            ## \(index + 1). \(risk.type.rawValue)
            
            | 项目 | 内容 |
            |------|------|
            | 严重程度 | \(risk.severity.rawValue) |
            | 风险描述 | \(risk.description) |
            | 可能影响 | \(risk.potentialImpact) |
            | 缓解措施 | \(risk.mitigationMeasures.joined(separator: "；")) |
            
            ---
            """
        }.joined(separator: "\n"))
        
        ## 风险控制建议
        
        1. **高风险项目**：立即制定详细的应对方案
        2. **中风险项目**：密切关注并准备预案
        3. **低风险项目**：定期评估和监控
        
        ## 总体风险评级
        
        基于识别的风险因素，建议采取积极的风险管理措施。
        """
    }
    
    private func generateStrategicOptionsContent(_ options: [LitigationStrategicOption]) -> String {
        return """
        # 诉讼策略选择指南
        
        \(options.enumerated().map { index, option in
            """
            ## \(index + 1). \(option.title)
            
            **策略描述**：\(option.description)
            
            **主要优势**：
            \(option.advantages.enumerated().map { i, advantage in
                "- \(advantage)"
            }.joined(separator: "\n"))
            
            **潜在劣势**：
            \(option.disadvantages.enumerated().map { i, disadvantage in
                "- \(disadvantage)"
            }.joined(separator: "\n"))
            
            **适用场景**：
            \(option.applicableScenarios.enumerated().map { i, scenario in
                "- \(scenario)"
            }.joined(separator: "\n"))
            
            **成功关键因素**：
            \(option.successFactors.enumerated().map { i, factor in
                "- \(factor)"
            }.joined(separator: "\n"))
            
            ---
            """
        }.joined(separator: "\n"))
        
        ## 策略选择建议
        
        根据案件具体情况，建议：
        1. 综合考虑各策略的优劣势
        2. 结合自身资源和风险承受能力
        3. 制定主策略和备选方案
        4. 保持策略的灵活性和可调整性
        """
    }
    
    // MARK: - Parsing and Extraction Methods
    
    private func parseLitigationStrategy(_ response: String) -> LitigationStrategy {
        // 简化的策略解析实现
        return LitigationStrategy(
            id: UUID().uuidString,
            title: "诉讼策略建议",
            phases: extractStrategyPhases(from: response),
            keyArguments: extractKeyArguments(from: response),
            evidenceRequirements: extractEvidenceRequirements(from: response),
            riskMitigations: extractRiskMitigations(from: response),
            timeline: extractStrategyTimeline(from: response),
            successFactors: extractSuccessFactors(from: response)
        )
    }
    
    private func parseEvidenceStrategy(_ response: String) -> EvidenceStrategy {
        return EvidenceStrategy(
            requiredEvidence: extractRequiredEvidence(from: response),
            evidenceGaps: extractEvidenceGaps(from: response),
            collectionPlan: extractCollectionPlan(from: response),
            preservationNeeds: extractPreservationNeeds(from: response),
            presentationStrategy: extractPresentationStrategy(from: response)
        )
    }
    
    private func parseTrialReadiness(_ response: String) -> TrialReadinessAssessment {
        let readinessScore = extractReadinessScore(from: response)
        
        return TrialReadinessAssessment(
            overallScore: readinessScore,
            materialPreparation: extractMaterialPreparation(from: response),
            proceduralCompliance: extractProceduralCompliance(from: response),
            argumentPreparation: extractArgumentPreparation(from: response),
            teamReadiness: extractTeamReadiness(from: response),
            improvementAreas: extractImprovementAreas(from: response),
            recommendations: extractReadinessRecommendations(from: response)
        )
    }
    
    // MARK: - Extraction Helper Methods
    
    private func extractWinningProbability(from response: String) -> Double {
        // 查找概率相关的关键词和数字
        let patterns = ["胜诉概率.*?([0-9]+)%", "胜算.*?([0-9]+)%", "获胜可能.*?([0-9]+)%"]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: response, range: NSRange(response.startIndex..., in: response)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: response),
               let percentage = Double(response[range]) {
                return percentage / 100.0
            }
        }
        
        // 基于文本描述推断
        if response.contains("很高") || response.contains("非常有利") {
            return 0.8
        } else if response.contains("较高") || response.contains("有利") {
            return 0.65
        } else if response.contains("一般") || response.contains("中等") {
            return 0.5
        } else if response.contains("较低") || response.contains("不利") {
            return 0.3
        } else {
            return 0.5 // 默认值
        }
    }
    
    private func extractEstimatedDuration(from response: String) -> String {
        // 查找时间相关表述
        let timePatterns = ["([0-9]+)个月", "([0-9]+)年", "([0-9]+)-([0-9]+)个月"]
        
        for pattern in timePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: response, range: NSRange(response.startIndex..., in: response)),
               let range = Range(match.range, in: response) {
                return String(response[range])
            }
        }
        
        return "6-12个月" // 默认预估
    }
    
    private func extractEstimatedCosts(from response: String) -> LitigationCosts {
        // 简化的成本提取
        let lawyerFees = extractCostAmount(from: response, type: "律师费") ?? 20000
        let courtFees = extractCostAmount(from: response, type: "法院费用") ?? 5000
        let otherCosts = extractCostAmount(from: response, type: "其他费用") ?? 3000
        
        return LitigationCosts(
            lawyerFees: lawyerFees,
            courtFees: courtFees,
            otherCosts: otherCosts,
            total: lawyerFees + courtFees + otherCosts
        )
    }
    
    private func extractCostAmount(from response: String, type: String) -> Double? {
        let pattern = "\(type).*?([0-9]+)"
        
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: response, range: NSRange(response.startIndex..., in: response)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: response),
           let amount = Double(response[range]) {
            return amount
        }
        
        return nil
    }
    
    private func extractLitigationRisks(from response: String) -> [LitigationRisk] {
        var risks: [LitigationRisk] = []
        
        let riskTypes: [(String, LitigationRisk.RiskType)] = [
            ("证据风险", .evidence),
            ("程序风险", .procedural),
            ("执行风险", .execution),
            ("时间风险", .time),
            ("成本风险", .cost)
        ]
        
        for (index, (keyword, riskType)) in riskTypes.enumerated() {
            if response.contains(keyword) {
                risks.append(LitigationRisk(
                    id: "risk-\(index)",
                    type: riskType,
                    severity: extractRiskSeverity(from: response, keyword: keyword),
                    description: "关于\(keyword)的分析",
                    potentialImpact: "可能影响诉讼结果",
                    mitigationMeasures: extractMitigationMeasures(from: response, keyword: keyword)
                ))
            }
        }
        
        return risks
    }
    
    private func extractRiskSeverity(from response: String, keyword: String) -> LitigationRisk.Severity {
        let context = extractContext(from: response, around: keyword, length: 100)
        
        if context.contains("高") || context.contains("严重") {
            return .high
        } else if context.contains("中") || context.contains("一般") {
            return .medium
        } else {
            return .low
        }
    }
    
    private func extractMitigationMeasures(from response: String, keyword: String) -> [String] {
        // 简化实现
        return ["制定专门的应对策略", "加强相关准备工作", "寻求专业支持"]
    }
    
    private func extractContext(from text: String, around keyword: String, length: Int) -> String {
        guard let range = text.range(of: keyword) else { return "" }
        
        let start = text.index(range.lowerBound, offsetBy: -length/2, limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(range.upperBound, offsetBy: length/2, limitedBy: text.endIndex) ?? text.endIndex
        
        return String(text[start..<end])
    }
    
    private func extractStrategicOptions(from response: String) -> [LitigationStrategicOption] {
        // 简化的策略选项提取
        var options: [LitigationStrategicOption] = []
        
        let commonOptions = [
            ("积极诉讼策略", "主动出击，充分利用优势证据"),
            ("防守反击策略", "稳守待攻，针对对方弱点反击"),
            ("和解导向策略", "以和解为目标，适时展示实力")
        ]
        
        for (index, (title, description)) in commonOptions.enumerated() {
            if response.contains(title) || response.contains(description) {
                options.append(LitigationStrategicOption(
                    id: "option-\(index)",
                    title: title,
                    description: description,
                    advantages: ["有利于实现预期目标", "符合案件特点"],
                    disadvantages: ["存在一定风险", "需要充分准备"],
                    applicableScenarios: ["证据充分时", "对方配合度较高时"],
                    successFactors: ["充分的准备工作", "专业的执行团队"]
                ))
            }
        }
        
        return options
    }
    
    private func extractOverallRecommendation(from response: String) -> String {
        // 查找总结性建议
        let keywords = ["总体建议", "综合建议", "整体推荐", "最终建议"]
        
        for keyword in keywords {
            if let range = response.range(of: keyword) {
                let start = range.upperBound
                let end = response.firstIndex(of: "。", after: start) ?? response.endIndex
                
                if start < end {
                    return String(response[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        return "建议根据具体情况制定合适的诉讼策略"
    }
    
    private func calculateLitigationConfidence(_ response: String) -> Double {
        var confidence = 0.7 // 基础置信度
        
        // 基于回复质量调整
        if response.count > 1500 { confidence += 0.1 }
        if response.contains("概率") || response.contains("预估") { confidence += 0.05 }
        if response.contains("风险") || response.contains("策略") { confidence += 0.05 }
        if response.contains("建议") || response.contains("推荐") { confidence += 0.05 }
        if response.contains("程序") || response.contains("步骤") { confidence += 0.05 }
        
        return min(1.0, confidence)
    }
    
    private func calculateCostBenefit(_ costs: LitigationCosts, winningProbability: Double) -> Double? {
        // 简化的成本效益计算
        // 假设胜诉后的预期收益是成本的3倍
        let expectedBenefit = Double(costs.total) * 3 * winningProbability
        return expectedBenefit / Double(costs.total)
    }
    
    // MARK: - Determination Helper Methods
    
    private func determineLitigationAnalysisType(_ request: AgentRequest) -> LitigationAnalysisType {
        if request.priority == .urgent {
            return .basic
        } else if request.content.count > 1000 {
            return .comprehensive
        } else {
            return .standard
        }
    }
    
    private func determineLitigationFocusAreas(_ request: AgentRequest) -> [LitigationFocusArea] {
        var areas: [LitigationFocusArea] = []
        
        let content = request.content.lowercased()
        
        if content.contains("胜诉") || content.contains("概率") {
            areas.append(.winningProbability)
        }
        if content.contains("成本") || content.contains("费用") {
            areas.append(.costBenefit)
        }
        if content.contains("时间") || content.contains("期限") {
            areas.append(.timeframe)
        }
        if content.contains("风险") {
            areas.append(.riskAssessment)
        }
        if content.contains("程序") || content.contains("流程") {
            areas.append(.procedural)
        }
        
        // 如果没有特定关注点，返回全面分析
        if areas.isEmpty {
            areas = [.winningProbability, .costBenefit, .timeframe, .riskAssessment]
        }
        
        return areas
    }
    
    // 其他提取方法的简化实现
    private func extractStrategyPhases(from response: String) -> [String] {
        return ["准备阶段", "审理阶段", "执行阶段"]
    }
    
    private func extractKeyArguments(from response: String) -> [String] {
        return ["主要法律依据", "核心事实主张", "关键争议点"]
    }
    
    private func extractEvidenceRequirements(from response: String) -> [String] {
        return ["书面证据", "证人证言", "专家意见"]
    }
    
    private func extractRiskMitigations(from response: String) -> [String] {
        return ["风险预案", "应急措施", "备选策略"]
    }
    
    private func extractStrategyTimeline(from response: String) -> [String] {
        return ["第1阶段：准备工作", "第2阶段：正式开庭", "第3阶段：判决执行"]
    }
    
    private func extractSuccessFactors(from response: String) -> [String] {
        return ["充分的证据准备", "专业的律师团队", "合理的策略执行"]
    }
    
    private func extractRequiredEvidence(from response: String) -> [String] {
        return ["合同文件", "通信记录", "财务资料"]
    }
    
    private func extractEvidenceGaps(from response: String) -> [String] {
        return ["缺少关键证据", "证据链不完整"]
    }
    
    private func extractCollectionPlan(from response: String) -> [String] {
        return ["证据收集计划", "取证时间安排"]
    }
    
    private func extractPreservationNeeds(from response: String) -> [String] {
        return ["证据保全申请", "关键证据备份"]
    }
    
    private func extractPresentationStrategy(from response: String) -> [String] {
        return ["证据展示顺序", "重点证据突出"]
    }
    
    private func extractReadinessScore(from response: String) -> Int {
        // 查找评分
        if let regex = try? NSRegularExpression(pattern: "([0-9]+)分"),
           let match = regex.firstMatch(in: response, range: NSRange(response.startIndex..., in: response)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: response),
           let score = Int(response[range]) {
            return min(10, max(1, score))
        }
        
        return 7 // 默认分数
    }
    
    private func extractMaterialPreparation(from response: String) -> String {
        return "材料准备情况评估"
    }
    
    private func extractProceduralCompliance(from response: String) -> String {
        return "程序合规性检查"
    }
    
    private func extractArgumentPreparation(from response: String) -> String {
        return "论辩准备情况"
    }
    
    private func extractTeamReadiness(from response: String) -> String {
        return "团队准备状态"
    }
    
    private func extractImprovementAreas(from response: String) -> [String] {
        return ["需要改进的方面", "待完善的工作"]
    }
    
    private func extractReadinessRecommendations(from response: String) -> [String] {
        return ["准备工作建议", "改进措施推荐"]
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

private struct LitigationAnalysisRequest {
    let caseDetails: CaseDetails?
    let analysisType: LitigationAnalysisType
    let focusAreas: [LitigationFocusArea]
}

private enum LitigationAnalysisType {
    case basic
    case standard
    case comprehensive
}

private enum LitigationFocusArea: String {
    case winningProbability = "胜诉概率分析"
    case costBenefit = "成本效益分析"
    case timeframe = "时间框架评估"
    case riskAssessment = "风险评估"
    case procedural = "程序指导"
}

private struct LitigationAnalysisResult {
    let winningProbability: Double
    let estimatedDuration: String
    let estimatedCosts: LitigationCosts
    let identifiedRisks: [LitigationRisk]
    let strategicOptions: [LitigationStrategicOption]
    let proceduralGuidance: [ProceduralStep]
    let overallRecommendation: String
    let confidence: Double
    let analysisDate: Date
}

private struct LitigationCosts {
    let lawyerFees: Double
    let courtFees: Double
    let otherCosts: Double
    let total: Double
}

private struct LitigationRisk {
    let id: String
    let type: RiskType
    let severity: Severity
    let description: String
    let potentialImpact: String
    let mitigationMeasures: [String]
    
    enum RiskType: String {
        case evidence = "证据风险"
        case procedural = "程序风险"
        case execution = "执行风险"
        case time = "时间风险"
        case cost = "成本风险"
        case legal = "法律风险"
    }
    
    enum Severity: String {
        case low = "低"
        case medium = "中"
        case high = "高"
    }
}

private struct LitigationStrategicOption {
    let id: String
    let title: String
    let description: String
    let advantages: [String]
    let disadvantages: [String]
    let applicableScenarios: [String]
    let successFactors: [String]
}

private struct ProceduralStep {
    let id: String
    let title: String
    let description: String
    let timeframe: String
    let requirements: [String]
    let isOptional: Bool
}

private struct LitigationProspects {
    let winningProbability: Double
    let estimatedDuration: String
    let estimatedCosts: LitigationCosts
    let keyRisks: [LitigationRisk]
    let strategicOptions: [LitigationStrategicOption]
    let recommendation: String
}

private enum LitigationObjective: String {
    case winCase = "胜诉"
    case minimizeCosts = "控制成本"
    case fastResolution = "快速解决"
    case maximizeCompensation = "最大化赔偿"
    case protectReputation = "保护声誉"
}

private struct LitigationStrategy {
    let id: String
    let title: String
    let phases: [String]
    let keyArguments: [String]
    let evidenceRequirements: [String]
    let riskMitigations: [String]
    let timeline: [String]
    let successFactors: [String]
}

private struct EvidenceStrategy {
    let requiredEvidence: [String]
    let evidenceGaps: [String]
    let collectionPlan: [String]
    let preservationNeeds: [String]
    let presentationStrategy: [String]
}

private struct TrialReadinessAssessment {
    let overallScore: Int
    let materialPreparation: String
    let proceduralCompliance: String
    let argumentPreparation: String
    let teamReadiness: String
    let improvementAreas: [String]
    let recommendations: [String]
}

private class LitigationKnowledgeBase {
    // 诉讼知识库的简化实现
    func getHistoricalData(for caseType: CaseType) -> LitigationHistoricalData? {
        return nil
    }
}

private struct LitigationHistoricalData {
    let caseType: CaseType
    let averageWinRate: Double
    let averageDuration: String
    let commonRisks: [String]
}

private class CourtRulesDatabase {
    // 法院规则数据库的简化实现
    func getProceduralSteps(for caseType: CaseType) -> [ProceduralStep] {
        return []
    }
}