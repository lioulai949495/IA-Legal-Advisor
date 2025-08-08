import Foundation
import Combine

@MainActor
class AgentService: ObservableObject {
    @MainActor static let shared = AgentService()
    
    // MARK: - Published Properties
    @Published var availableAgents: [any AIAgent] = []
    @Published var activeRequests: [AgentRequest] = []
    @Published var completedResponses: [AgentResponse] = []
    @Published var agentMetrics: [String: AgentMetrics] = [:]
    @Published var agentHealth: [String: AgentHealth] = [:]
    
    // MARK: - Private Properties
    private var agents: [String: any AIAgent] = [:]
    private var agentConfigurations: [String: AgentConfiguration] = [:]
    private let apiService: APIService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private let maxRetryAttempts = 3
    private let requestTimeout: TimeInterval = 30.0
    
    // MARK: - Initialization
    private init(apiService: APIService = .shared) {
        self.apiService = apiService
        setupDefaultAgents()
        startHealthMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// 获取指定类型的代理
    func getAgent(ofType type: AgentType) -> (any AIAgent)? {
        return availableAgents.first { $0.agentType == type }
    }
    
    /// 获取能处理指定案件类型的代理
    func getAgentsForCaseType(_ caseType: CaseType) -> [any AIAgent] {
        return availableAgents.filter { $0.canHandle(caseType) && $0.isActive }
    }
    
    /// 发送请求到指定代理
    func sendRequest(_ request: AgentRequest) async throws -> AgentResponse {
        guard let agent = agents[request.agentType.rawValue] else {
            throw AgentServiceError.agentNotFound(request.agentType)
        }
        
        guard agent.isActive else {
            throw AgentServiceError.agentInactive(agent.id)
        }
        
        // 添加到活跃请求列表
        activeRequests.append(request)
        
        do {
            let startTime = Date()
            let response = try await agent.processRequest(request)
            let processingTime = Date().timeIntervalSince(startTime)
            
            // 更新响应处理时间
            var updatedResponse = response
            updatedResponse = AgentResponse(
                id: response.id,
                requestId: response.requestId,
                agentId: response.agentId,
                content: response.content,
                confidence: response.confidence,
                recommendations: response.recommendations,
                attachments: response.attachments,
                followUpQuestions: response.followUpQuestions,
                createdAt: response.createdAt,
                processingTime: processingTime
            )
            
            // 移除活跃请求并添加到完成列表
            activeRequests.removeAll { $0.id == request.id }
            completedResponses.append(updatedResponse)
            
            // 更新代理指标
            updateAgentMetrics(agentId: agent.id, successful: true, responseTime: processingTime)
            
            return updatedResponse
            
        } catch {
            // 处理错误
            activeRequests.removeAll { $0.id == request.id }
            updateAgentMetrics(agentId: agent.id, successful: false, responseTime: 0)
            
            throw AgentServiceError.requestFailed(error)
        }
    }
    
    /// 发送请求到最佳代理（根据案件类型自动选择）
    func sendRequestToBestAgent(
        caseType: CaseType,
        content: String,
        context: AgentContext?,
        priority: AgentRequest.RequestPriority = .normal
    ) async throws -> AgentResponse {
        let suitableAgents = getAgentsForCaseType(caseType)
        
        guard !suitableAgents.isEmpty else {
            throw AgentServiceError.noSuitableAgent(caseType)
        }
        
        // 选择最佳代理（基于指标）
        let bestAgent = selectBestAgent(from: suitableAgents)
        
        let request = AgentRequest(
            id: UUID().uuidString,
            agentType: bestAgent.agentType,
            caseType: caseType,
            content: content,
            context: context,
            priority: priority,
            createdAt: Date()
        )
        
        return try await sendRequest(request)
    }
    
    /// 注册新代理
    func registerAgent(_ agent: any AIAgent) {
        agents[agent.id] = agent
        availableAgents.append(agent)
        
        // 初始化代理指标
        agentMetrics[agent.id] = AgentMetrics(
            agentId: agent.id,
            totalRequests: 0,
            successfulResponses: 0,
            averageResponseTime: 0,
            averageConfidence: 0,
            userSatisfactionRating: 0,
            lastUpdated: Date()
        )
        
        // 初始化代理健康状态
        agentHealth[agent.id] = AgentHealth(
            agentId: agent.id,
            status: .active,
            cpuUsage: 0,
            memoryUsage: 0,
            activeConnections: 0,
            lastHealthCheck: Date(),
            errors: []
        )
    }
    
    /// 注销代理
    func unregisterAgent(withId agentId: String) {
        agents.removeValue(forKey: agentId)
        availableAgents.removeAll { $0.id == agentId }
        agentMetrics.removeValue(forKey: agentId)
        agentHealth.removeValue(forKey: agentId)
    }
    
    /// 更新代理配置
    func updateAgentConfiguration(_ configuration: AgentConfiguration) {
        agentConfigurations[configuration.agentId] = configuration
    }
    
    /// 获取代理配置
    func getAgentConfiguration(for agentId: String) -> AgentConfiguration? {
        return agentConfigurations[agentId]
    }
    
    /// 获取代理指标
    func getMetrics(for agentId: String) -> AgentMetrics? {
        return agentMetrics[agentId]
    }
    
    /// 获取所有代理指标汇总
    func getAllMetricsSummary() -> AgentMetricsSummary {
        let allMetrics = Array(agentMetrics.values)
        
        let totalRequests = allMetrics.reduce(0) { $0 + $1.totalRequests }
        let totalSuccessful = allMetrics.reduce(0) { $0 + $1.successfulResponses }
        let avgResponseTime = allMetrics.isEmpty ? 0 : 
            allMetrics.reduce(0) { $0 + $1.averageResponseTime } / Double(allMetrics.count)
        let avgConfidence = allMetrics.isEmpty ? 0 :
            allMetrics.reduce(0) { $0 + $1.averageConfidence } / Double(allMetrics.count)
        let avgSatisfaction = allMetrics.isEmpty ? 0 :
            allMetrics.reduce(0) { $0 + $1.userSatisfactionRating } / Double(allMetrics.count)
        
        return AgentMetricsSummary(
            totalAgents: availableAgents.count,
            activeAgents: availableAgents.filter { $0.isActive }.count,
            totalRequests: totalRequests,
            successfulResponses: totalSuccessful,
            averageResponseTime: avgResponseTime,
            averageConfidence: avgConfidence,
            averageSatisfaction: avgSatisfaction,
            lastUpdated: Date()
        )
    }
    
    /// 清理历史数据
    func cleanupHistory(olderThan date: Date) {
        completedResponses.removeAll { $0.createdAt < date }
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultAgents() {
        // 创建默认代理实例
        let legalConsultant = DefaultLegalConsultantAgent()
        let caseAnalyst = DefaultCaseAnalystAgent()
        let documentGenerator = DefaultDocumentGeneratorAgent()
        let riskAssessor = DefaultRiskAssessorAgent()
        let contractReviewer = DefaultContractReviewerAgent()
        let litigationAdvisor = DefaultLitigationAdvisorAgent()
        
        // 注册代理
        registerAgent(legalConsultant)
        registerAgent(caseAnalyst)
        registerAgent(documentGenerator)
        registerAgent(riskAssessor)
        registerAgent(contractReviewer)
        registerAgent(litigationAdvisor)
    }
    
    private func selectBestAgent(from agents: [any AIAgent]) -> any AIAgent {
        // 根据指标选择最佳代理
        return agents.max { agent1, agent2 in
            let metrics1 = agentMetrics[agent1.id]
            let metrics2 = agentMetrics[agent2.id]
            
            let score1 = calculateAgentScore(metrics1)
            let score2 = calculateAgentScore(metrics2)
            
            return score1 < score2
        } ?? agents.first!
    }
    
    private func calculateAgentScore(_ metrics: AgentMetrics?) -> Double {
        guard let metrics = metrics else { return 0 }
        
        // 综合评分算法
        let successWeight: Double = 0.4
        let speedWeight: Double = 0.3
        let confidenceWeight: Double = 0.2
        let satisfactionWeight: Double = 0.1
        
        let successScore = metrics.successRate
        let speedScore = min(1.0, 10.0 / max(1.0, metrics.averageResponseTime)) // 越快分数越高
        let confidenceScore = metrics.averageConfidence
        let satisfactionScore = metrics.userSatisfactionRating / 5.0 // 假设满分5分
        
        return successScore * successWeight +
               speedScore * speedWeight +
               confidenceScore * confidenceWeight +
               satisfactionScore * satisfactionWeight
    }
    
    private func updateAgentMetrics(agentId: String, successful: Bool, responseTime: TimeInterval) {
        guard var metrics = agentMetrics[agentId] else { return }
        
        metrics.totalRequests += 1
        if successful {
            metrics.successfulResponses += 1
        }
        
        // 更新平均响应时间
        let totalTime = metrics.averageResponseTime * Double(metrics.totalRequests - 1) + responseTime
        metrics.averageResponseTime = totalTime / Double(metrics.totalRequests)
        
        metrics.lastUpdated = Date()
        agentMetrics[agentId] = metrics
    }
    
    private func startHealthMonitoring() {
        // 每30秒检查一次代理健康状态
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.performHealthCheck()
                }
            }
            .store(in: &cancellables)
    }
    
    private func performHealthCheck() async {
        for agent in availableAgents {
            var health = agentHealth[agent.id] ?? AgentHealth(
                agentId: agent.id,
                status: .active,
                cpuUsage: 0,
                memoryUsage: 0,
                activeConnections: 0,
                lastHealthCheck: Date(),
                errors: []
            )
            
            // 模拟健康检查
            health.status = agent.isActive ? .active : .offline
            health.lastHealthCheck = Date()
            
            // 检查是否有过多错误
            let recentErrors = health.errors.filter { 
                Date().timeIntervalSince($0.timestamp) < 300 // 5分钟内的错误
            }
            
            if recentErrors.count > 5 {
                health.status = .error
            }
            
            agentHealth[agent.id] = health
        }
    }
}

// MARK: - Supporting Types

struct AgentMetricsSummary {
    let totalAgents: Int
    let activeAgents: Int
    let totalRequests: Int
    let successfulResponses: Int
    let averageResponseTime: TimeInterval
    let averageConfidence: Double
    let averageSatisfaction: Double
    let lastUpdated: Date
    
    var successRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(successfulResponses) / Double(totalRequests)
    }
}

enum AgentServiceError: LocalizedError {
    case agentNotFound(AgentType)
    case agentInactive(String)
    case noSuitableAgent(CaseType)
    case requestFailed(Error)
    case configurationError(String)
    case timeout
    case conditionsNotMet
    case outputValidationFailed(String)
    case batchExecutionFailed([Error])
    
    var errorDescription: String? {
        switch self {
        case .agentNotFound(let type):
            return "未找到类型为 \(type.rawValue) 的代理"
        case .agentInactive(let id):
            return "代理 \(id) 当前不可用"
        case .noSuitableAgent(let caseType):
            return "没有合适的代理处理 \(caseType.rawValue) 类型的案件"
        case .requestFailed(let error):
            return "请求处理失败: \(error.localizedDescription)"
        case .configurationError(let message):
            return "配置错误: \(message)"
        case .timeout:
            return "请求超时"
        case .conditionsNotMet:
            return "触发条件未满足"
        case .outputValidationFailed(let message):
            return "输出验证失败: \(message)"
        case .batchExecutionFailed(let errors):
            return "批量执行失败: \(errors.map { $0.localizedDescription }.joined(separator: ", "))"
        }
    }
}

// MARK: - Agent Registry Extension
extension AgentService {
    
    /// 批量注册代理
    func registerAgents(_ agents: [any AIAgent]) {
        for agent in agents {
            registerAgent(agent)
        }
    }
    
    /// 根据类型启用/禁用代理
    func setAgentActive(_ agentType: AgentType, isActive: Bool) {
        if let index = availableAgents.firstIndex(where: { $0.agentType == agentType }) {
            availableAgents[index].isActive = isActive
        }
    }
    
    /// 重启代理
    func restartAgent(withId agentId: String) async {
        guard let agent = agents[agentId] else { return }
        
        // 设置为维护状态
        if var health = agentHealth[agentId] {
            health.status = .maintenance
            agentHealth[agentId] = health
        }
        
        // 等待当前请求完成
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
        
        // 重新激活
        if let index = availableAgents.firstIndex(where: { $0.id == agentId }) {
            availableAgents[index].isActive = true
        }
        
        // 更新健康状态
        if var health = agentHealth[agentId] {
            health.status = .active
            health.lastHealthCheck = Date()
            health.errors.removeAll()
            agentHealth[agentId] = health
        }
    }
    
    // MARK: - Workflow Integration Methods
    
    /// 为工作流程步骤执行AI代理集成
    func executeWorkflowIntegration(
        integration: AgentWorkflowIntegration,
        stepContext: WorkflowStepContext
    ) async throws -> WorkflowAgentResponse {
        
        guard let agent = agents[integration.agentType.rawValue] else {
            throw AgentServiceError.agentNotFound(integration.agentType)
        }
        
        // 检查触发条件
        let conditionsMet = try await checkTriggerConditions(
            conditions: integration.triggerConditions,
            context: stepContext
        )
        
        guard conditionsMet else {
            throw AgentServiceError.conditionsNotMet
        }
        
        // 构建工作流程特定的请求
        let request = try buildWorkflowRequest(
            integration: integration,
            stepContext: stepContext
        )
        
        // 执行请求
        let response = try await sendRequest(request)
        
        // 验证输出质量
        try validateWorkflowOutput(response: response, expectedOutputs: integration.expectedOutputs)
        
        return WorkflowAgentResponse(
            agentResponse: response,
            stepId: stepContext.stepId,
            integrationId: integration.stepId,
            qualityScore: calculateOutputQuality(response: response, integration: integration),
            executionTime: response.processingTime ?? 0,
            validationResults: validateAgentOutput(response: response, integration: integration)
        )
    }
    
    /// 批量执行多个代理请求（用于复杂工作流程步骤）
    func executeBatchRequests(
        requests: [BatchAgentRequest]
    ) async throws -> [AgentResponse] {
        
        var responses: [AgentResponse] = []
        var errors: [Error] = []
        
        // 并行执行支持并行的请求
        await withTaskGroup(of: Result<AgentResponse, Error>.self) { group in
            for request in requests {
                if request.allowParallel {
                    group.addTask {
                        do {
                            let response = try await self.sendRequest(request.agentRequest)
                            return .success(response)
                        } catch {
                            return .failure(error)
                        }
                    }
                }
            }
            
            for await result in group {
                switch result {
                case .success(let response):
                    responses.append(response)
                case .failure(let error):
                    errors.append(error)
                }
            }
        }
        
        // 串行执行需要串行的请求
        let serialRequests = requests.filter { !$0.allowParallel }
        for request in serialRequests {
            do {
                let response = try await sendRequest(request.agentRequest)
                responses.append(response)
            } catch {
                errors.append(error)
            }
        }
        
        // 如果有错误但不是全部失败，记录错误但返回成功的响应
        if !errors.isEmpty && !responses.isEmpty {
            print("批量请求部分失败: \(errors.map { $0.localizedDescription }.joined(separator: ", "))")
        }
        
        // 如果全部失败，抛出第一个错误
        if responses.isEmpty && !errors.isEmpty {
            throw errors.first!
        }
        
        return responses
    }
    
    /// 获取代理的工作流程能力
    func getAgentWorkflowCapabilities(agentType: AgentType) -> AgentWorkflowCapabilities? {
        guard let agent = agents[agentType.rawValue] else { return nil }
        
        return AgentWorkflowCapabilities(
            agentId: agent.id,
            agentType: agentType,
            supportedStepTypes: getSupportedStepTypes(for: agentType),
            integrationModes: getSupportedIntegrationModes(for: agentType),
            outputTypes: getSupportedOutputTypes(for: agentType),
            qualityThresholds: getQualityThresholds(for: agentType),
            performanceMetrics: getAgentPerformanceMetrics(agentId: agent.id)
        )
    }
    
    // MARK: - Private Workflow Helper Methods
    
    private func checkTriggerConditions(
        conditions: [TriggerCondition],
        context: WorkflowStepContext
    ) async throws -> Bool {
        
        for condition in conditions {
            let conditionMet = try await evaluateCondition(condition, context: context)
            if !conditionMet {
                return false
            }
        }
        
        return true
    }
    
    private func evaluateCondition(
        _ condition: TriggerCondition,
        context: WorkflowStepContext
    ) async throws -> Bool {
        
        switch condition.conditionType {
        case .stepStatus:
            return context.stepStatus == condition.expectedValue
        case .documentUploaded:
            return context.uploadedDocuments.contains(condition.parameter)
        case .timeElapsed:
            guard let elapsed = Double(condition.expectedValue) else { return false }
            return context.timeElapsed >= elapsed
        case .userAction:
            return context.userActions.contains(condition.expectedValue)
        case .dataThreshold:
            // TODO: 实现数据阈值检查
            return true
        }
    }
    
    private func buildWorkflowRequest(
        integration: AgentWorkflowIntegration,
        stepContext: WorkflowStepContext
    ) throws -> AgentRequest {
        
        let contextualContent = buildContextualContent(
            stepContext: stepContext,
            integration: integration
        )
        
        return AgentRequest(
            id: UUID().uuidString,
            agentType: integration.agentType,
            caseType: stepContext.caseType,
            content: contextualContent,
            context: buildWorkflowAgentContext(stepContext: stepContext),
            priority: determineRequestPriority(stepContext: stepContext),
            createdAt: Date()
        )
    }
    
    private func buildContextualContent(
        stepContext: WorkflowStepContext,
        integration: AgentWorkflowIntegration
    ) -> String {
        
        var content = "工作流程步骤: \(stepContext.stepTitle)\n"
        content += "步骤描述: \(stepContext.stepDescription)\n"
        content += "当前阶段: \(stepContext.currentPhase)\n\n"
        
        if !stepContext.userInput.isEmpty {
            content += "用户输入:\n"
            for (key, value) in stepContext.userInput {
                content += "- \(key): \(value)\n"
            }
            content += "\n"
        }
        
        if !stepContext.previousStepOutputs.isEmpty {
            content += "前序步骤输出:\n"
            for (stepId, output) in stepContext.previousStepOutputs {
                content += "- 步骤\(stepId): \(output)\n"
            }
            content += "\n"
        }
        
        // 添加预期输出要求
        content += "请提供以下类型的输出:\n"
        for expectedOutput in integration.expectedOutputs {
            content += "- \(expectedOutput.outputType.rawValue): \(expectedOutput.description)\n"
        }
        
        return content
    }
    
    private func buildWorkflowAgentContext(stepContext: WorkflowStepContext) -> AgentContext {
        // 构建工作流程特定的代理上下文
        return AgentContext(
            caseId: nil,
            userId: stepContext.workflowId,
            previousMessages: [],
            caseDetails: nil,
            userPreferences: nil
        )
    }
    
    private func determineRequestPriority(stepContext: WorkflowStepContext) -> AgentRequest.RequestPriority {
        // 根据步骤上下文确定请求优先级
        if stepContext.isUrgent {
            return .urgent
        } else if stepContext.isCritical {
            return .high
        } else {
            return .normal
        }
    }
    
    private func validateWorkflowOutput(
        response: AgentResponse,
        expectedOutputs: [ExpectedOutput]
    ) throws {
        
        for expectedOutput in expectedOutputs {
            // 检查质量阈值
            if response.confidence < expectedOutput.qualityThreshold {
                throw AgentServiceError.outputValidationFailed(
                    "输出质量低于预期阈值 \(expectedOutput.qualityThreshold)"
                )
            }
            
            // 根据输出类型进行特定验证
            try validateSpecificOutputType(
                response: response,
                expectedOutput: expectedOutput
            )
        }
    }
    
    private func validateSpecificOutputType(
        response: AgentResponse,
        expectedOutput: ExpectedOutput
    ) throws {
        
        switch expectedOutput.outputType {
        case .analysis:
            if response.content.count < 100 {
                throw AgentServiceError.outputValidationFailed("分析报告内容过短")
            }
        case .document:
            // TODO: 验证生成的文档格式和内容
            break
        case .recommendation:
            if response.recommendations?.isEmpty ?? true {
                throw AgentServiceError.outputValidationFailed("缺少推荐建议")
            }
        case .riskAssessment:
            if !response.content.contains("风险") {
                throw AgentServiceError.outputValidationFailed("缺少风险评估内容")
            }
        case .strategy:
            if response.content.count < 200 {
                throw AgentServiceError.outputValidationFailed("策略内容不够详细")
            }
        }
    }
    
    private func calculateOutputQuality(
        response: AgentResponse,
        integration: AgentWorkflowIntegration
    ) -> Double {
        
        var qualityScore = response.confidence
        
        // 根据输出完整性调整质量分数
        if !(response.recommendations?.isEmpty ?? true) {
            qualityScore += 0.1
        }
        
        if !(response.attachments?.isEmpty ?? true) {
            qualityScore += 0.1
        }
        
        if response.content.count > 500 {
            qualityScore += 0.1
        }
        
        return min(1.0, qualityScore)
    }
    
    private func validateAgentOutput(
        response: AgentResponse,
        integration: AgentWorkflowIntegration
    ) -> [WorkflowValidationResult] {
        
        var results: [WorkflowValidationResult] = []
        
        for expectedOutput in integration.expectedOutputs {
            let isValid = (try? validateSpecificOutputType(
                response: response,
                expectedOutput: expectedOutput
            )) != nil
            
            results.append(WorkflowValidationResult(
                outputType: expectedOutput.outputType,
                isValid: isValid,
                qualityScore: response.confidence,
                issues: isValid ? [] : ["输出验证失败"]
            ))
        }
        
        return results
    }
    
    private func getSupportedStepTypes(for agentType: AgentType) -> [CaseWorkflowStepType] {
        switch agentType {
        case .caseAnalyst:
            return [.analysis, .judgmentAnalysis]
        case .documentGenerator:
            return [.materialPreparation, .evidencePreparation, .defenseResponse]
        case .legalConsultant:
            return [.caseFilingGuidance, .postTrialHandling]
        case .riskAssessor:
            return [.analysis, .preTrialPreservation]
        case .contractReviewer:
            return [.evidencePreparation, .materialPreparation]
        case .litigationAdvisor:
            return [.litigation, .secondTrial, .execution, .retrial]
        }
    }
    
    private func getSupportedIntegrationModes(for agentType: AgentType) -> [AgentWorkflowIntegration.IntegrationMode] {
        switch agentType {
        case .caseAnalyst:
            return [.automatic, .conditional]
        case .documentGenerator:
            return [.userTriggered, .conditional]
        case .legalConsultant:
            return [.userTriggered]
        default:
            return [.userTriggered, .conditional]
        }
    }
    
    private func getSupportedOutputTypes(for agentType: AgentType) -> [ExpectedOutput.OutputType] {
        switch agentType {
        case .caseAnalyst:
            return [.analysis, .riskAssessment]
        case .documentGenerator:
            return [.document]
        case .legalConsultant:
            return [.recommendation, .strategy]
        case .riskAssessor:
            return [.riskAssessment, .analysis]
        case .contractReviewer:
            return [.analysis, .recommendation]
        case .litigationAdvisor:
            return [.strategy, .recommendation]
        }
    }
    
    private func getQualityThresholds(for agentType: AgentType) -> [String: Double] {
        switch agentType {
        case .caseAnalyst:
            return ["analysis": 0.8, "confidence": 0.7]
        case .documentGenerator:
            return ["document": 0.9, "accuracy": 0.85]
        case .legalConsultant:
            return ["recommendation": 0.75, "completeness": 0.8]
        default:
            return ["general": 0.7]
        }
    }
    
    private func getAgentPerformanceMetrics(agentId: String) -> AgentPerformanceMetrics? {
        guard let metrics = agentMetrics[agentId] else { return nil }
        
        return AgentPerformanceMetrics(
            averageResponseTime: metrics.averageResponseTime,
            successRate: metrics.successRate,
            averageConfidence: metrics.averageConfidence,
            userSatisfaction: metrics.userSatisfactionRating,
            lastUpdated: metrics.lastUpdated
        )
    }
}

// MARK: - Workflow Integration Supporting Types

/// 工作流程代理响应
struct WorkflowAgentResponse {
    let agentResponse: AgentResponse
    let stepId: String
    let integrationId: String
    let qualityScore: Double
    let executionTime: TimeInterval
    let validationResults: [WorkflowValidationResult]
}

/// 工作流程验证结果
struct WorkflowValidationResult {
    let outputType: ExpectedOutput.OutputType
    let isValid: Bool
    let qualityScore: Double
    let issues: [String]
}

/// 工作流程步骤上下文
struct WorkflowStepContext {
    let workflowId: String
    let stepId: String
    let stepTitle: String
    let stepDescription: String
    let caseType: CaseType
    let currentPhase: String
    let stepStatus: String
    let userInput: [String: Any]
    let previousStepOutputs: [String: String]
    let uploadedDocuments: [String]
    let userActions: [String]
    let timeElapsed: TimeInterval
    let isUrgent: Bool
    let isCritical: Bool
}

/// 批量代理请求
struct BatchAgentRequest {
    let agentRequest: AgentRequest
    let allowParallel: Bool
    let dependencies: [String] // 依赖的其他请求ID
    let priority: Int // 执行优先级
}

/// 代理工作流程能力
struct AgentWorkflowCapabilities {
    let agentId: String
    let agentType: AgentType
    let supportedStepTypes: [CaseWorkflowStepType]
    let integrationModes: [AgentWorkflowIntegration.IntegrationMode]
    let outputTypes: [ExpectedOutput.OutputType]
    let qualityThresholds: [String: Double]
    let performanceMetrics: AgentPerformanceMetrics?
}

/// 代理性能指标
struct AgentPerformanceMetrics {
    let averageResponseTime: TimeInterval
    let successRate: Double
    let averageConfidence: Double
    let userSatisfaction: Double
    let lastUpdated: Date
}