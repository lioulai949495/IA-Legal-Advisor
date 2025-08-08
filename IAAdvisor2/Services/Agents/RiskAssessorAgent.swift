import Foundation

/// 风险评估代理 - 专门进行法律风险评估和预警
class DefaultRiskAssessorAgent: RiskAssessorAgent {
    
    // MARK: - AIAgent Properties
    let id: String = "risk-assessor-001"
    let name: String = "风险评估师"
    let description: String = "专业的法律风险评估代理，识别潜在风险并提供预防措施"
    let agentType: AgentType = .riskAssessor
    let specializations: [String] = [
        "法律风险识别", "财务风险评估", "合规风险分析", 
        "操作风险评估", "声誉风险预警", "诉讼风险评估"
    ]
    var isActive: Bool = true
    
    // MARK: - Private Properties
    private let apiService: APIService
    private let riskDatabase: RiskKnowledgeBase
    private let riskThresholds: RiskThresholds
    
    // MARK: - Initialization
    init(apiService: APIService = .shared) {
        self.apiService = apiService
        self.riskDatabase = RiskKnowledgeBase()
        self.riskThresholds = RiskThresholds()
    }
    
    // MARK: - AIAgent Methods
    
    func processRequest(_ request: AgentRequest) async throws -> AgentResponse {
        let startTime = Date()
        
        guard canHandle(request.caseType ?? .contractDispute) else {
            throw AgentError.unsupportedCaseType(request.caseType?.rawValue ?? "未知")
        }
        
        do {
            // 进行风险评估
            let riskAssessment = try await performRiskAssessment(request)
            
            // 生成风险缓解建议
            let recommendations = generateRiskMitigationRecommendations(riskAssessment)
            
            // 创建风险报告附件
            let attachments = generateRiskReportAttachments(riskAssessment)
            
            // 生成后续问题
            let followUpQuestions = generateRiskFollowUp(riskAssessment.overallRisk)
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            return AgentResponse(
                id: UUID().uuidString,
                requestId: request.id,
                agentId: id,
                content: formatRiskAssessmentResponse(riskAssessment),
                confidence: riskAssessment.confidence,
                recommendations: recommendations,
                attachments: attachments,
                followUpQuestions: followUpQuestions,
                createdAt: Date(),
                processingTime: processingTime
            )
            
        } catch {
            throw AgentError.processingFailed("风险评估失败: \(error.localizedDescription)")
        }
    }
    
    func canHandle(_ caseType: CaseType) -> Bool {
        // 风险评估师可以处理所有类型的案件
        return true
    }
    
    // MARK: - RiskAssessorAgent Methods
    
    func assessRisk(_ caseDetails: CaseDetails) async throws -> RiskAssessment {
        let request = createRiskAssessmentRequest(from: caseDetails)
        return try await performRiskAssessment(request)
    }
    
    func identifyPotentialIssues(_ caseDetails: CaseDetails) async throws -> [RiskFactor] {
        let prompt = buildRiskIdentificationPrompt(caseDetails)
        
        let chatResponse = try await apiService.sendChatMessage(
            category: "风险识别",
            message: prompt,
            role: "风险分析专家",
            subtype: caseDetails.caseType.rawValue
        )
        
        return parseRiskFactorsFromResponse(chatResponse.response, caseDetails: caseDetails)
    }
    
    // MARK: - Private Helper Methods
    
    private func performRiskAssessment(_ request: AgentRequest) async throws -> RiskAssessment {
        // 构建风险评估提示
        let prompt = buildRiskAssessmentPrompt(request)
        
        // 调用API进行风险分析
        let chatResponse = try await apiService.sendChatMessage(
            category: "风险评估",
            message: prompt,
            role: "风险评估专家",
            subtype: request.caseType?.rawValue
        )
        
        // 解析响应
        let riskFactors = parseRiskFactorsFromResponse(chatResponse.response, caseDetails: request.context?.caseDetails)
        
        // 计算整体风险等级
        let overallRisk = calculateOverallRisk(riskFactors)
        
        // 生成缓解策略
        let mitigationStrategies = generateMitigationStrategies(for: riskFactors)
        
        // 计算置信度
        let confidence = calculateRiskAssessmentConfidence(chatResponse.response, riskFactors: riskFactors)
        
        return RiskAssessment(
            id: UUID().uuidString,
            overallRisk: overallRisk,
            riskFactors: riskFactors,
            mitigationStrategies: mitigationStrategies,
            recommendations: generateRiskRecommendations(overallRisk, riskFactors: riskFactors),
            confidence: confidence
        )
    }
    
    private func buildRiskAssessmentPrompt(_ request: AgentRequest) -> String {
        var prompt = """
        作为专业的风险评估师，请对以下案件进行全面的风险评估：
        
        案件类型：\(request.caseType?.rawValue ?? "一般案件")
        案件描述：\(request.content)
        """
        
        if let context = request.context {
            if let caseDetails = context.caseDetails {
                prompt += """
                
                详细信息：
                - 案件标题：\(caseDetails.title)
                - 案件描述：\(caseDetails.description)
                - 案件状态：\(caseDetails.status.rawValue)
                - 当事人：\(caseDetails.involvedParties.map { "\($0.name)(\($0.role.rawValue))" }.joined(separator: ", "))
                """
                
                if !caseDetails.timeline.isEmpty {
                    prompt += "\n- 重要事件时间线：\n"
                    for event in caseDetails.timeline.sorted(by: { $0.date < $1.date }) {
                        prompt += "  \(formatDate(event.date)): \(event.description)\n"
                    }
                }
            }
        }
        
        prompt += """
        
        请从以下维度进行风险评估：
        
        1. 法律风险
           - 法律依据不足风险
           - 程序违法风险
           - 适用法律错误风险
           - 时效超期风险
        
        2. 财务风险
           - 败诉赔偿风险
           - 诉讼成本风险
           - 执行困难风险
           - 资产损失风险
        
        3. 操作风险
           - 证据灭失风险
           - 证人不配合风险
           - 程序错误风险
           - 时间延误风险
        
        4. 声誉风险
           - 公众形象损害风险
           - 媒体负面报道风险
           - 行业声誉影响风险
        
        5. 监管风险
           - 政策变化风险
           - 合规要求变更风险
           - 行政处罚风险
        
        对每项风险请评估：
        - 风险发生概率（0-1）
        - 风险影响程度（0-1）
        - 风险等级（很低/低/中等/高/很高）
        - 预防和缓解措施
        """
        
        return prompt
    }
    
    private func buildRiskIdentificationPrompt(_ caseDetails: CaseDetails) -> String {
        return """
        请识别以下案件中的潜在风险因素：
        
        案件信息：
        - 类型：\(caseDetails.caseType.rawValue)
        - 标题：\(caseDetails.title)
        - 描述：\(caseDetails.description)
        - 状态：\(caseDetails.status.rawValue)
        
        当事人信息：
        \(caseDetails.involvedParties.map { "- \($0.name)：\($0.role.rawValue)" }.joined(separator: "\n"))
        
        请识别并分析：
        1. 最可能发生的风险
        2. 影响最大的风险
        3. 最难控制的风险
        4. 时间敏感的风险
        5. 隐藏的风险
        
        对每个风险因素请说明：
        - 风险描述
        - 触发条件
        - 可能后果
        - 严重程度
        - 建议措施
        """
    }
    
    private func parseRiskFactorsFromResponse(_ response: String, caseDetails: CaseDetails?) -> [RiskFactor] {
        var riskFactors: [RiskFactor] = []
        
        // 预定义风险模式识别
        let riskPatterns = [
            ("法律风险", RiskFactor.RiskCategory.legal),
            ("财务风险", RiskFactor.RiskCategory.financial),
            ("操作风险", RiskFactor.RiskCategory.operational),
            ("声誉风险", RiskFactor.RiskCategory.reputational),
            ("监管风险", RiskFactor.RiskCategory.regulatory)
        ]
        
        for (index, (pattern, category)) in riskPatterns.enumerated() {
            if response.contains(pattern) {
                let riskDescription = extractRiskDescription(from: response, pattern: pattern)
                let severity = extractRiskSeverity(from: response, pattern: pattern)
                let probability = extractRiskProbability(from: response, pattern: pattern)
                let impact = extractRiskImpact(from: response, pattern: pattern)
                
                riskFactors.append(RiskFactor(
                    id: "risk-\(index)",
                    title: "\(pattern)分析",
                    description: riskDescription,
                    category: category,
                    severity: severity,
                    probability: probability,
                    impact: impact,
                    mitigationActions: extractMitigationActions(from: response, pattern: pattern)
                ))
            }
        }
        
        // 识别特定风险因素
        let specificRisks = identifySpecificRisks(response, caseType: caseDetails?.caseType)
        riskFactors.append(contentsOf: specificRisks)
        
        return riskFactors
    }
    
    private func identifySpecificRisks(_ response: String, caseType: CaseType?) -> [RiskFactor] {
        var specificRisks: [RiskFactor] = []
        
        // 基于案件类型的特定风险
        if let caseType = caseType {
            switch caseType {
            case .contractDispute:
                if response.contains("违约") || response.contains("合同") {
                    specificRisks.append(createContractRisk(response))
                }
            case .laborDispute:
                if response.contains("劳动") || response.contains("工资") {
                    specificRisks.append(createLaborRisk(response))
                }
            case .divorceDispute:
                if response.contains("财产") || response.contains("子女") {
                    specificRisks.append(createDivorceRisk(response))
                }
            default:
                break
            }
        }
        
        // 通用风险识别
        if response.contains("证据") && (response.contains("不足") || response.contains("缺乏")) {
            specificRisks.append(createEvidenceRisk(response))
        }
        
        if response.contains("时效") || response.contains("期限") {
            specificRisks.append(createTimeRisk(response))
        }
        
        return specificRisks
    }
    
    private func createContractRisk(_ response: String) -> RiskFactor {
        return RiskFactor(
            id: "contract-risk",
            title: "合同履约风险",
            description: "合同条款执行和履约相关风险",
            category: .legal,
            severity: .moderate,
            probability: 0.6,
            impact: 0.7,
            mitigationActions: [
                "详细审查合同条款",
                "明确履约标准",
                "建立履约监督机制"
            ]
        )
    }
    
    private func createLaborRisk(_ response: String) -> RiskFactor {
        return RiskFactor(
            id: "labor-risk",
            title: "劳动关系风险",
            description: "劳动争议和合规风险",
            category: .legal,
            severity: .moderate,
            probability: 0.5,
            impact: 0.6,
            mitigationActions: [
                "完善劳动合同",
                "建立规范的HR流程",
                "定期进行合规审查"
            ]
        )
    }
    
    private func createDivorceRisk(_ response: String) -> RiskFactor {
        return RiskFactor(
            id: "divorce-risk",
            title: "家庭财产分割风险",
            description: "财产分割和子女抚养争议风险",
            category: .financial,
            severity: .major,
            probability: 0.7,
            impact: 0.8,
            mitigationActions: [
                "完善财产清单",
                "保全重要资产",
                "制定子女抚养方案"
            ]
        )
    }
    
    private func createEvidenceRisk(_ response: String) -> RiskFactor {
        return RiskFactor(
            id: "evidence-risk",
            title: "证据不足风险",
            description: "关键证据缺失或不充分的风险",
            category: .legal,
            severity: .major,
            probability: 0.6,
            impact: 0.9,
            mitigationActions: [
                "全面收集相关证据",
                "申请证据保全",
                "寻找替代证据"
            ]
        )
    }
    
    private func createTimeRisk(_ response: String) -> RiskFactor {
        return RiskFactor(
            id: "time-risk",
            title: "时效风险",
            description: "诉讼时效或法定期限风险",
            category: .legal,
            severity: .major,
            probability: 0.3,
            impact: 1.0,
            mitigationActions: [
                "立即核实相关期限",
                "尽快采取法律行动",
                "申请时效中断或中止"
            ]
        )
    }
    
    private func calculateOverallRisk(_ riskFactors: [RiskFactor]) -> RiskAssessment.RiskLevel {
        guard !riskFactors.isEmpty else { return .low }
        
        // 计算加权风险分数
        let totalRiskScore = riskFactors.reduce(0.0) { total, factor in
            let factorScore = factor.probability * factor.impact
            let severityMultiplier = getSeverityMultiplier(factor.severity)
            return total + (factorScore * severityMultiplier)
        }
        
        let averageRiskScore = totalRiskScore / Double(riskFactors.count)
        
        // 根据分数确定风险等级
        switch averageRiskScore {
        case 0.0..<0.2:
            return .veryLow
        case 0.2..<0.4:
            return .low
        case 0.4..<0.6:
            return .medium
        case 0.6..<0.8:
            return .high
        default:
            return .veryHigh
        }
    }
    
    private func getSeverityMultiplier(_ severity: RiskFactor.RiskSeverity) -> Double {
        switch severity {
        case .negligible: return 0.1
        case .minor: return 0.5
        case .moderate: return 1.0
        case .major: return 1.5
        case .catastrophic: return 2.0
        }
    }
    
    private func generateMitigationStrategies(for riskFactors: [RiskFactor]) -> [MitigationStrategy] {
        var strategies: [MitigationStrategy] = []
        
        // 按风险类别分组
        let risksByCategory = Dictionary(grouping: riskFactors) { $0.category }
        
        for (category, risks) in risksByCategory {
            let strategy = createMitigationStrategy(for: category, risks: risks)
            strategies.append(strategy)
        }
        
        // 添加综合缓解策略
        if riskFactors.count > 3 {
            strategies.append(createComprehensiveMitigationStrategy(riskFactors))
        }
        
        return strategies
    }
    
    private func createMitigationStrategy(for category: RiskFactor.RiskCategory, risks: [RiskFactor]) -> MitigationStrategy {
        let targetRiskIds = risks.map { $0.id }
        let actions = risks.flatMap { $0.mitigationActions }.unique()
        
        let title: String
        let description: String
        let timeline: String
        let estimatedCost: Double
        let effectiveness: Double
        
        switch category {
        case .legal:
            title = "法律风险缓解策略"
            description = "通过法律审查、程序规范和专业咨询降低法律风险"
            timeline = "2-4周"
            estimatedCost = 2000
            effectiveness = 0.8
            
        case .financial:
            title = "财务风险控制策略"
            description = "通过资产保全、成本控制和保险保障降低财务风险"
            timeline = "1-2周"
            estimatedCost = 1500
            effectiveness = 0.7
            
        case .operational:
            title = "操作风险管理策略"
            description = "通过流程规范、培训教育和监督检查降低操作风险"
            timeline = "3-6周"
            estimatedCost = 1000
            effectiveness = 0.75
            
        case .reputational:
            title = "声誉风险防护策略"
            description = "通过危机公关、媒体管理和形象维护降低声誉风险"
            timeline = "持续进行"
            estimatedCost = 3000
            effectiveness = 0.6
            
        case .regulatory:
            title = "合规风险应对策略"
            description = "通过合规审查、政策跟踪和关系维护降低监管风险"
            timeline = "持续进行"
            estimatedCost = 2500
            effectiveness = 0.85
        }
        
        let mitigationActions = actions.enumerated().map { index, action in
            MitigationAction(
                id: "action-\(category.rawValue)-\(index)",
                title: action,
                description: "针对\(category.rawValue)的具体行动",
                responsible: "法务团队",
                deadline: Calendar.current.date(byAdding: .weekOfYear, value: 2, to: Date()) ?? Date(),
                status: .pending
            )
        }
        
        return MitigationStrategy(
            id: "strategy-\(category.rawValue)",
            title: title,
            description: description,
            targetRisks: targetRiskIds,
            actions: mitigationActions,
            timeline: timeline,
            estimatedCost: estimatedCost,
            effectiveness: effectiveness
        )
    }
    
    private func createComprehensiveMitigationStrategy(_ riskFactors: [RiskFactor]) -> MitigationStrategy {
        let targetRiskIds = riskFactors.map { $0.id }
        
        let comprehensiveActions = [
            MitigationAction(
                id: "comprehensive-review",
                title: "全面风险审查",
                description: "对所有识别的风险进行全面审查和评估",
                responsible: "风险管理团队",
                deadline: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
                status: .pending
            ),
            MitigationAction(
                id: "risk-monitoring",
                title: "建立风险监控机制",
                description: "建立持续的风险监控和预警机制",
                responsible: "法务部门",
                deadline: Calendar.current.date(byAdding: .weekOfYear, value: 2, to: Date()) ?? Date(),
                status: .pending
            ),
            MitigationAction(
                id: "contingency-planning",
                title: "制定应急预案",
                description: "针对高风险情况制定详细的应急处理预案",
                responsible: "管理层",
                deadline: Calendar.current.date(byAdding: .weekOfYear, value: 3, to: Date()) ?? Date(),
                status: .pending
            )
        ]
        
        return MitigationStrategy(
            id: "comprehensive-strategy",
            title: "综合风险管理策略",
            description: "全面的风险管理和控制策略，涵盖所有识别的风险因素",
            targetRisks: targetRiskIds,
            actions: comprehensiveActions,
            timeline: "4-6周",
            estimatedCost: 5000,
            effectiveness: 0.85
        )
    }
    
    private func generateRiskRecommendations(_ overallRisk: RiskAssessment.RiskLevel, riskFactors: [RiskFactor]) -> [String] {
        var recommendations: [String] = []
        
        // 基于整体风险等级的建议
        switch overallRisk {
        case .veryHigh, .high:
            recommendations.append("立即采取紧急风险控制措施")
            recommendations.append("寻求专业法律团队支持")
            recommendations.append("考虑和解或其他替代解决方案")
            
        case .medium:
            recommendations.append("制定详细的风险管理计划")
            recommendations.append("定期监控风险变化情况")
            recommendations.append("准备风险应对预案")
            
        case .low, .veryLow:
            recommendations.append("继续监控潜在风险发展")
            recommendations.append("维护现有风险控制措施")
            recommendations.append("定期进行风险评估更新")
        }
        
        // 基于特定风险的建议
        let highRiskFactors = riskFactors.filter { $0.severity == .major || $0.severity == .catastrophic }
        for riskFactor in highRiskFactors {
            recommendations.append("重点关注\(riskFactor.title)，采取专门的缓解措施")
        }
        
        return recommendations
    }
    
    private func generateRiskMitigationRecommendations(_ riskAssessment: RiskAssessment) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // 基于整体风险等级生成建议
        switch riskAssessment.overallRisk {
        case .veryHigh, .high:
            recommendations.append(Recommendation(
                id: "urgent-risk-control",
                title: "紧急风险控制",
                description: "风险等级较高，需要立即采取控制措施",
                actionType: .other,
                priority: .critical,
                estimatedCost: 3000,
                timeframe: "立即执行",
                requirements: ["专业风险评估", "紧急行动计划", "充足资源配置"]
            ))
            
        case .medium:
            recommendations.append(Recommendation(
                id: "systematic-risk-management",
                title: "系统风险管理",
                description: "建立系统的风险管理体系",
                actionType: .other,
                priority: .high,
                estimatedCost: 2000,
                timeframe: "2-4周",
                requirements: ["风险管理计划", "监控机制", "应急预案"]
            ))
            
        case .low, .veryLow:
            recommendations.append(Recommendation(
                id: "risk-monitoring",
                title: "风险持续监控",
                description: "维持当前风险控制水平，持续监控",
                actionType: .other,
                priority: .medium,
                estimatedCost: 500,
                timeframe: "持续进行",
                requirements: ["定期评估", "监控指标", "报告机制"]
            ))
        }
        
        // 为每个缓解策略生成具体建议
        for strategy in riskAssessment.mitigationStrategies {
            recommendations.append(Recommendation(
                id: "implement-\(strategy.id)",
                title: "实施\(strategy.title)",
                description: strategy.description,
                actionType: .other,
                priority: determinePriority(for: strategy),
                estimatedCost: strategy.estimatedCost,
                timeframe: strategy.timeline,
                requirements: strategy.actions.map { $0.title }
            ))
        }
        
        return recommendations
    }
    
    private func determinePriority(for strategy: MitigationStrategy) -> Recommendation.RecommendationPriority {
        if strategy.effectiveness > 0.8 {
            return .critical
        } else if strategy.effectiveness > 0.6 {
            return .high
        } else {
            return .medium
        }
    }
    
    private func generateRiskReportAttachments(_ riskAssessment: RiskAssessment) -> [AgentAttachment] {
        var attachments: [AgentAttachment] = []
        
        // 风险评估报告
        attachments.append(AgentAttachment(
            id: "risk-assessment-report",
            name: "风险评估报告",
            type: .document,
            url: nil,
            content: generateRiskReportContent(riskAssessment),
            size: nil
        ))
        
        // 风险矩阵
        attachments.append(AgentAttachment(
            id: "risk-matrix",
            name: "风险矩阵图",
            type: .reference,
            url: nil,
            content: "风险概率与影响度的矩阵分析图表",
            size: nil
        ))
        
        // 缓解行动计划
        attachments.append(AgentAttachment(
            id: "mitigation-plan",
            name: "风险缓解行动计划",
            type: .checklist,
            url: nil,
            content: generateMitigationPlanContent(riskAssessment.mitigationStrategies),
            size: nil
        ))
        
        return attachments
    }
    
    private func generateRiskReportContent(_ riskAssessment: RiskAssessment) -> String {
        var report = """
        # 风险评估报告
        
        ## 评估概要
        - 整体风险等级：\(riskAssessment.overallRisk.rawValue)
        - 识别风险数量：\(riskAssessment.riskFactors.count)
        - 评估置信度：\(String(format: "%.1f", riskAssessment.confidence * 100))%
        - 评估日期：\(formatDate(Date()))
        
        ## 风险因素详情
        """
        
        for (index, riskFactor) in riskAssessment.riskFactors.enumerated() {
            report += """
            
            ### \(index + 1). \(riskFactor.title)
            - **类别**：\(riskFactor.category.rawValue)
            - **严重程度**：\(riskFactor.severity.rawValue)
            - **发生概率**：\(String(format: "%.1f", riskFactor.probability * 100))%
            - **影响程度**：\(String(format: "%.1f", riskFactor.impact * 100))%
            - **描述**：\(riskFactor.description)
            - **缓解措施**：\(riskFactor.mitigationActions.joined(separator: "；"))
            """
        }
        
        report += """
        
        ## 总体建议
        \(riskAssessment.recommendations.joined(separator: "\n"))
        """
        
        return report
    }
    
    private func generateMitigationPlanContent(_ strategies: [MitigationStrategy]) -> String {
        var plan = "# 风险缓解行动计划\n\n"
        
        for (index, strategy) in strategies.enumerated() {
            plan += """
            ## \(index + 1). \(strategy.title)
            
            **目标**：\(strategy.description)
            **时间框架**：\(strategy.timeline)
            **预估成本**：\(strategy.estimatedCost.map { "¥\($0)" } ?? "待定")
            **预期效果**：\(String(format: "%.1f", strategy.effectiveness * 100))%
            
            **行动项目**：
            \(strategy.actions.enumerated().map { index, action in
                "\(index + 1). \(action.title) - 责任人：\(action.responsible) - 截止：\(formatDate(action.deadline))"
            }.joined(separator: "\n"))
            
            ---
            
            """
        }
        
        return plan
    }
    
    private func generateRiskFollowUp(_ overallRisk: RiskAssessment.RiskLevel) -> [String] {
        let commonQuestions = [
            "是否需要更详细的风险分析？",
            "您对当前的风险评估结果有什么看法？",
            "是否需要制定具体的风险应对计划？"
        ]
        
        let riskSpecificQuestions: [String]
        
        switch overallRisk {
        case .veryHigh, .high:
            riskSpecificQuestions = [
                "是否立即启动紧急风险控制措施？",
                "需要多长时间将风险降低到可接受水平？",
                "是否考虑寻求外部专业支持？"
            ]
        case .medium:
            riskSpecificQuestions = [
                "哪些风险因素需要优先处理？",
                "现有资源是否足够应对这些风险？",
                "多久进行一次风险评估更新？"
            ]
        case .low, .veryLow:
            riskSpecificQuestions = [
                "当前的风险控制措施是否需要调整？",
                "是否需要建立长期的风险监控机制？",
                "有没有潜在的隐藏风险需要关注？"
            ]
        }
        
        return commonQuestions + riskSpecificQuestions
    }
    
    private func formatRiskAssessmentResponse(_ riskAssessment: RiskAssessment) -> String {
        return """
        ## 风险评估结果
        
        **整体风险等级：** \(riskAssessment.overallRisk.rawValue)
        **评估置信度：** \(String(format: "%.1f", riskAssessment.confidence * 100))%
        **识别风险数量：** \(riskAssessment.riskFactors.count)个
        
        ### 风险分布
        \(generateRiskDistributionSummary(riskAssessment.riskFactors))
        
        ### 关键风险因素
        \(riskAssessment.riskFactors.prefix(3).enumerated().map { index, risk in
            "\(index + 1). **\(risk.title)** - \(risk.severity.rawValue)风险"
        }.joined(separator: "\n"))
        
        ### 核心建议
        \(riskAssessment.recommendations.prefix(3).enumerated().map { index, rec in
            "\(index + 1). \(rec)"
        }.joined(separator: "\n"))
        
        详细的风险分析报告请查看附件。
        
        ⚠️ **重要提示**：本评估基于当前可获得的信息，建议定期更新风险评估。
        """
    }
    
    private func generateRiskDistributionSummary(_ riskFactors: [RiskFactor]) -> String {
        let categoryCount = Dictionary(grouping: riskFactors) { $0.category }
            .mapValues { $0.count }
        
        return categoryCount.map { category, count in
            "- \(category.rawValue)：\(count)个"
        }.joined(separator: "\n")
    }
    
    private func calculateRiskAssessmentConfidence(_ response: String, riskFactors: [RiskFactor]) -> Double {
        var confidence = 0.6 // 基础置信度
        
        // 基于响应质量调整
        if response.count > 500 { confidence += 0.1 }
        if response.contains("概率") || response.contains("影响") { confidence += 0.1 }
        if response.contains("缓解") || response.contains("控制") { confidence += 0.1 }
        
        // 基于风险因素数量调整
        if riskFactors.count >= 3 { confidence += 0.1 }
        if riskFactors.count >= 5 { confidence += 0.1 }
        
        return min(1.0, confidence)
    }
    
    private func createRiskAssessmentRequest(from caseDetails: CaseDetails) -> AgentRequest {
        return AgentRequest(
            id: UUID().uuidString,
            agentType: .riskAssessor,
            caseType: caseDetails.caseType,
            content: "请对以下案件进行风险评估：\(caseDetails.description)",
            context: AgentContext(
                caseId: caseDetails.id,
                userId: "system",
                previousMessages: nil,
                caseDetails: caseDetails,
                userPreferences: nil
            ),
            priority: .normal,
            createdAt: Date()
        )
    }
    
    // MARK: - Text Extraction Helper Methods
    
    private func extractRiskDescription(from response: String, pattern: String) -> String {
        // 查找包含模式的段落
        let paragraphs = response.components(separatedBy: "\n\n")
        
        for paragraph in paragraphs {
            if paragraph.contains(pattern) {
                return paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return "关于\(pattern)的详细分析"
    }
    
    private func extractRiskSeverity(from response: String, pattern: String) -> RiskFactor.RiskSeverity {
        let context = extractRiskDescription(from: response, pattern: pattern)
        
        if context.contains("严重") || context.contains("重大") || context.contains("灾难") {
            return .catastrophic
        } else if context.contains("高") || context.contains("重要") {
            return .major
        } else if context.contains("中等") || context.contains("一般") {
            return .moderate
        } else if context.contains("轻微") || context.contains("小") {
            return .minor
        } else {
            return .negligible
        }
    }
    
    private func extractRiskProbability(from response: String, pattern: String) -> Double {
        let context = extractRiskDescription(from: response, pattern: pattern)
        
        // 查找概率相关的关键词
        if context.contains("很高") || context.contains("90%") { return 0.9 }
        if context.contains("高") || context.contains("70%") { return 0.7 }
        if context.contains("中等") || context.contains("50%") { return 0.5 }
        if context.contains("低") || context.contains("30%") { return 0.3 }
        if context.contains("很低") || context.contains("10%") { return 0.1 }
        
        return 0.5 // 默认值
    }
    
    private func extractRiskImpact(from response: String, pattern: String) -> Double {
        let context = extractRiskDescription(from: response, pattern: pattern)
        
        // 查找影响程度相关的关键词
        if context.contains("巨大") || context.contains("严重影响") { return 1.0 }
        if context.contains("重大") || context.contains("显著影响") { return 0.8 }
        if context.contains("中等") || context.contains("一定影响") { return 0.6 }
        if context.contains("轻微") || context.contains("小影响") { return 0.3 }
        if context.contains("微小") || context.contains("几乎无影响") { return 0.1 }
        
        return 0.6 // 默认值
    }
    
    private func extractMitigationActions(from response: String, pattern: String) -> [String] {
        let context = extractRiskDescription(from: response, pattern: pattern)
        let actionKeywords = ["建议", "应该", "需要", "可以", "措施"]
        
        var actions: [String] = []
        
        for keyword in actionKeywords {
            if let range = context.range(of: keyword) {
                // 提取包含关键词的句子
                let sentenceStart = context.lastIndex(of: "。", before: range.lowerBound) ?? context.startIndex
                let sentenceEnd = context.firstIndex(of: "。", after: range.upperBound) ?? context.endIndex
                
                if sentenceStart < sentenceEnd {
                    let sentence = String(context[sentenceStart..<sentenceEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !sentence.isEmpty && sentence.count > 5 {
                        actions.append(sentence)
                    }
                }
            }
        }
        
        // 如果没有找到具体行动，返回通用建议
        if actions.isEmpty {
            actions = [
                "制定针对性的风险控制计划",
                "建立相应的监控和预警机制",
                "定期评估和更新风险状况"
            ]
        }
        
        return Array(Set(actions)).prefix(5).map { String($0) }
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

private class RiskKnowledgeBase {
    // 风险知识库，存储常见风险模式和应对策略
    private let commonRisks: [String: RiskPattern] = [:]
    
    func getRiskPattern(for caseType: CaseType) -> RiskPattern? {
        return commonRisks[caseType.rawValue]
    }
}

private struct RiskPattern {
    let caseType: CaseType
    let commonRisks: [String]
    let riskFactors: [String]
    let mitigationStrategies: [String]
}

private struct RiskThresholds {
    let highRiskThreshold: Double = 0.7
    let mediumRiskThreshold: Double = 0.4
    let lowRiskThreshold: Double = 0.2
    
    func getRiskLevel(for score: Double) -> RiskAssessment.RiskLevel {
        switch score {
        case highRiskThreshold...:
            return .high
        case mediumRiskThreshold..<highRiskThreshold:
            return .medium
        case lowRiskThreshold..<mediumRiskThreshold:
            return .low
        default:
            return .veryLow
        }
    }
}

// Array extension for unique elements
extension Array where Element: Hashable {
    func unique() -> [Element] {
        return Array(Set(self))
    }
}