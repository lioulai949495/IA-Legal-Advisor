import Foundation
import Combine
import SwiftUI

/// 增强的工作流程服务
@MainActor
class EnhancedWorkflowService: ObservableObject {
    @MainActor static let shared = EnhancedWorkflowService()
    
    // MARK: - Published Properties
    @Published var currentWorkflows: [String: EnhancedCaseWorkflow] = [:]
    @Published var activeSteps: [String: EnhancedWorkflowStep] = [:]
    @Published var workflowProgress: [String: WorkflowProgress] = [:]
    @Published var isProcessingStep = false
    @Published var processingStepId: String?
    @Published var workflowTemplates: [WorkflowType: [EnhancedWorkflowStep]] = [:]
    
    // MARK: - Private Properties
    private lazy var caseWorkflowService: CaseWorkflowService = CaseWorkflowService()
    private let agentService: AgentService
    private let documentService: DocumentGenerationService
    private let progressService: WorkflowProgressService
    private let coreDataService: CoreDataService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    @MainActor
    private init(
        agentService: AgentService = .shared,
        documentService: DocumentGenerationService = .shared,
        progressService: WorkflowProgressService = .shared,
        coreDataService: CoreDataService = .shared
    ) {
        self.agentService = agentService
        self.documentService = documentService
        self.progressService = progressService
        self.coreDataService = coreDataService
        
        setupWorkflowTemplates()
        subscribeToServices()
    }
    
    // MARK: - Public Methods
    
    /// 创建新的增强工作流程
    func createEnhancedWorkflow(
        for caseId: String,
        caseType: CaseType,
        workflowType: WorkflowType = .standardLitigation
    ) async throws -> EnhancedCaseWorkflow {
        
        let workflowId = UUID().uuidString
        
        // 获取工作流程模板步骤
        let stepTypes = workflowType.getDefaultSteps()
        
        // 创建增强的工作流程步骤
        var enhancedSteps: [EnhancedWorkflowStep] = []
        
        for (index, stepType) in stepTypes.enumerated() {
            let step = try await createEnhancedStep(
                stepType: stepType,
                caseType: caseType,
                order: index,
                workflowId: workflowId
            )
            enhancedSteps.append(step)
        }
        
        // 创建工作流程进度
        let progress = WorkflowProgress(
            completedSteps: 0,
            totalSteps: enhancedSteps.count,
            currentPhase: .preparation,
            phaseProgress: 0.0,
            milestones: createMilestones(for: enhancedSteps),
            blockers: []
        )
        
        // 创建工作流程元数据
        let metadata = WorkflowMetadata(
            aiConsultationCount: 0,
            documentGenerationCount: 0,
            userInteractions: [],
            systemRecommendations: [],
            performanceMetrics: WorkflowPerformanceMetrics(
                avgStepCompletionTime: 0,
                totalTimeSpent: 0,
                efficiencyScore: 1.0,
                userSatisfactionScore: 1.0,
                aiAccuracyScore: 1.0,
                costEffectivenessScore: 1.0,
                lastUpdated: Date()
            ),
            customFields: [:]
        )
        
        // 创建完整的工作流程
        let workflow = EnhancedCaseWorkflow(
            id: workflowId,
            caseId: caseId,
            workflowType: workflowType,
            steps: enhancedSteps,
            currentStepIndex: 0,
            progress: progress,
            createdAt: Date(),
            updatedAt: Date(),
            metadata: metadata
        )
        
        // 保存工作流程
        currentWorkflows[workflowId] = workflow
        workflowProgress[workflowId] = progress
        
        // 持久化存储
        try await saveWorkflow(workflow)
        
        return workflow
    }
    
    /// 获取指定案件的工作流程
    func getWorkflow(for caseId: String) -> EnhancedCaseWorkflow? {
        return currentWorkflows.values.first { $0.caseId == caseId }
    }
    
    /// 执行工作流程步骤
    func executeStep(
        workflowId: String,
        stepId: String,
        userInput: [String: Any] = [:]
    ) async throws -> StepExecutionResult {
        
        guard var workflow = currentWorkflows[workflowId],
              let stepIndex = workflow.steps.firstIndex(where: { $0.id == stepId })
        else {
            throw WorkflowError.workflowNotFound(workflowId)
        }
        
        var step = workflow.steps[stepIndex]
        
        // 检查步骤是否可以执行
        guard step.canStart() else {
            throw WorkflowError.stepNotReady(stepId)
        }
        
        isProcessingStep = true
        processingStepId = stepId
        
        let startTime = Date()
        
        do {
            // 更新步骤状态
            step.status = .inProgress
            workflow.steps[stepIndex] = step
            currentWorkflows[workflowId] = workflow
            
            // 记录用户交互
            let interaction = UserInteraction(
                id: UUID().uuidString,
                stepId: stepId,
                interactionType: .stepCompleted,
                description: "开始执行步骤: \(step.title)",
                timestamp: Date(),
                duration: nil
            )
            
            // 执行步骤特定逻辑
            let stepResult = try await executeStepLogic(step: step, userInput: userInput)
            
            // 集成AI代理
            if let agentIntegration = step.getAgentIntegration() {
                let agentResult = try await executeAgentIntegration(
                    integration: agentIntegration,
                    step: step,
                    userInput: userInput
                )
                
                // 合并AI代理结果
                await incorporateAgentResult(
                    agentResult: agentResult,
                    into: &step,
                    stepResult: stepResult
                )
            }
            
            // 更新步骤完成状态
            step.status = .completed
            step.date = Date()
            workflow.steps[stepIndex] = step
            
            // 更新工作流程进度
            try await updateWorkflowProgress(workflowId: workflowId)
            
            // 检查是否触发下一步骤
            await checkAndTriggerNextStep(workflowId: workflowId)
            
            // 保存更新
            currentWorkflows[workflowId] = workflow
            try await saveWorkflow(workflow)
            
            let executionTime = Date().timeIntervalSince(startTime)
            
            // 记录完成的用户交互
            let completedInteraction = UserInteraction(
                id: UUID().uuidString,
                stepId: stepId,
                interactionType: .stepCompleted,
                description: "完成步骤: \(step.title)",
                timestamp: Date(),
                duration: executionTime
            )
            
            workflow.metadata.userInteractions.append(completedInteraction)
            
            isProcessingStep = false
            processingStepId = nil
            
            return StepExecutionResult(
                stepId: stepId,
                success: true,
                executionTime: executionTime,
                outputs: stepResult.outputs,
                aiAnalysis: stepResult.aiAnalysis,
                generatedDocuments: stepResult.generatedDocuments,
                nextRecommendedStep: getNextRecommendedStep(workflowId: workflowId),
                warnings: stepResult.warnings,
                errors: []
            )
            
        } catch {
            // 处理执行失败
            step.status = .pending
            workflow.steps[stepIndex] = step
            currentWorkflows[workflowId] = workflow
            
            isProcessingStep = false
            processingStepId = nil
            
            let executionTime = Date().timeIntervalSince(startTime)
            
            throw WorkflowError.stepExecutionFailed(stepId, error.localizedDescription)
        }
    }
    
    /// 添加自定义步骤到工作流程
    func addCustomStep(
        to workflowId: String,
        stepType: CaseWorkflowStepType,
        after stepId: String
    ) async throws {
        
        guard var workflow = currentWorkflows[workflowId],
              let afterIndex = workflow.steps.firstIndex(where: { $0.id == stepId })
        else {
            throw WorkflowError.workflowNotFound(workflowId)
        }
        
        let customStep = try await createEnhancedStep(
            stepType: stepType,
            caseType: .contractDispute, // TODO: Get from case
            order: afterIndex + 1,
            workflowId: workflowId,
            isCustom: true
        )
        
        workflow.steps.insert(customStep, at: afterIndex + 1)
        
        // 更新后续步骤的顺序
        for i in (afterIndex + 2)..<workflow.steps.count {
            // 可以在这里更新步骤顺序，如果需要的话
        }
        
        workflow.progress.totalSteps += 1
        workflow.updatedAt = Date()
        
        currentWorkflows[workflowId] = workflow
        try await saveWorkflow(workflow)
    }
    
    /// 获取工作流程分析数据
    func getWorkflowAnalytics(workflowId: String) async throws -> WorkflowAnalytics {
        guard let workflow = currentWorkflows[workflowId] else {
            throw WorkflowError.workflowNotFound(workflowId)
        }
        
        // 生成步骤分析数据
        let stepAnalytics = workflow.steps.map { step -> StepAnalytics in
            StepAnalytics(
                id: step.id,
                stepId: step.id,
                completionRate: step.status == .completed ? 1.0 : 0.0,
                avgExecutionTime: calculateAvgExecutionTime(for: step),
                errorRate: calculateErrorRate(for: step),
                userSatisfactionScore: 4.0, // TODO: 从实际数据获取
                aiAccuracy: 0.85, // TODO: 从AI代理获取
                resourceUtilization: ResourceUtilization(
                    cpuUsage: 0.2,
                    memoryUsage: 0.3,
                    networkUsage: 0.1,
                    storageUsage: 0.05,
                    aiModelUsage: 0.4,
                    apiCallCount: 5,
                    timestamp: Date()
                )
            )
        }
        
        let overallMetrics = OverallWorkflowMetrics(
            totalExecutionTime: workflow.metadata.performanceMetrics.totalTimeSpent,
            successRate: Double(workflow.progress.completedSteps) / Double(workflow.progress.totalSteps),
            userEngagementScore: workflow.metadata.performanceMetrics.userSatisfactionScore,
            costEfficiency: workflow.metadata.performanceMetrics.costEffectivenessScore,
            timeToCompletion: estimateTimeToCompletion(workflow: workflow),
            qualityScore: calculateQualityScore(workflow: workflow)
        )
        
        return WorkflowAnalytics(
            workflowId: workflowId,
            analysisDate: Date(),
            stepAnalytics: stepAnalytics,
            overallMetrics: overallMetrics,
            userBehaviorInsights: generateUserBehaviorInsights(workflow: workflow),
            performanceTrends: generatePerformanceTrends(workflow: workflow),
            recommendations: generateAnalyticsRecommendations(workflow: workflow)
        )
    }
    
    /// 暂停工作流程
    func pauseWorkflow(workflowId: String) async throws {
        guard var workflow = currentWorkflows[workflowId] else {
            throw WorkflowError.workflowNotFound(workflowId)
        }
        
        // 暂停当前进行中的步骤
        if let currentStep = workflow.currentStep,
           currentStep.status == .inProgress {
            // 这里可以添加暂停逻辑
        }
        
        workflow.updatedAt = Date()
        currentWorkflows[workflowId] = workflow
        try await saveWorkflow(workflow)
    }
    
    /// 恢复工作流程
    func resumeWorkflow(workflowId: String) async throws {
        guard var workflow = currentWorkflows[workflowId] else {
            throw WorkflowError.workflowNotFound(workflowId)
        }
        
        // 恢复工作流程逻辑
        workflow.updatedAt = Date()
        currentWorkflows[workflowId] = workflow
        try await saveWorkflow(workflow)
    }
    
    // MARK: - Private Methods
    
    private func setupWorkflowTemplates() {
        // 设置各种工作流程类型的模板
        for workflowType in WorkflowType.allCases {
            let stepTypes = workflowType.getDefaultSteps()
            // TODO: 为每种工作流程类型创建模板步骤
        }
    }
    
    private func subscribeToServices() {
        // 订阅各种服务的状态变化
        agentService.$completedResponses
            .sink { [weak self] responses in
                // 处理AI代理响应
                Task { @MainActor in
                    await self?.handleAgentResponses(responses)
                }
            }
            .store(in: &cancellables)
        
        progressService.$progressUpdates
            .sink { [weak self] updates in
                // 处理进度更新
                Task { @MainActor in
                    await self?.handleProgressUpdates(updates)
                }
            }
            .store(in: &cancellables)
    }
    
    private func createEnhancedStep(
        stepType: CaseWorkflowStepType,
        caseType: CaseType,
        order: Int,
        workflowId: String,
        isCustom: Bool = false
    ) async throws -> EnhancedWorkflowStep {
        
        // 基于现有的案件工作流程服务创建基础步骤
        let baseSteps = caseWorkflowService.generateWorkflow(for: caseType)
        let baseStep = baseSteps.first { $0.stepType == stepType }
        
        if let baseStep = baseStep {
            // 增强基础步骤
            return EnhancedWorkflowStep(
                id: UUID().uuidString,
                title: baseStep.title,
                description: baseStep.description,
                status: order == 0 ? .pending : .pending,
                date: baseStep.date,
                estimatedDays: baseStep.estimatedDays,
                stepType: baseStep.stepType,
                actionGuide: baseStep.actionGuide,
                requiredDocuments: baseStep.requiredDocuments,
                legalNotices: baseStep.legalNotices,
                isCustomStep: isCustom,
                allowsCustomSubsteps: baseStep.allowsCustomSubsteps
            )
        } else {
            // 创建新的自定义步骤
            return createDefaultStep(stepType: stepType, order: order, isCustom: isCustom)
        }
    }
    
    private func createDefaultStep(
        stepType: CaseWorkflowStepType,
        order: Int,
        isCustom: Bool
    ) -> EnhancedWorkflowStep {
        
        return EnhancedWorkflowStep(
            id: UUID().uuidString,
            title: stepType.rawValue,
            description: "这是一个\(stepType.rawValue)步骤",
            status: .pending,
            date: nil,
            estimatedDays: 7,
            stepType: stepType,
            actionGuide: ActionGuide(
                title: "\(stepType.rawValue)指南",
                steps: [],
                tips: [],
                warnings: [],
                estimatedTime: "1周",
                difficulty: .medium
            ),
            requiredDocuments: [],
            legalNotices: [],
            isCustomStep: isCustom,
            allowsCustomSubsteps: true
        )
    }
    
    private func createMilestones(for steps: [EnhancedWorkflowStep]) -> [ProgressMilestone] {
        var milestones: [ProgressMilestone] = []
        
        // 为每个阶段创建里程碑
        let phases = WorkflowPhase.allCases
        for phase in phases {
            let relevantSteps = steps.filter { step in
                // 根据步骤类型判断属于哪个阶段
                switch phase {
                case .preparation:
                    return [.analysis, .materialPreparation].contains(step.stepType)
                case .filing:
                    return [.caseFilingGuidance, .litigation].contains(step.stepType)
                case .discovery:
                    return [.evidencePreparation].contains(step.stepType)
                case .trial:
                    return [.defenseResponse].contains(step.stepType)
                case .judgment:
                    return [.judgmentAnalysis].contains(step.stepType)
                case .postTrial:
                    return [.postTrialHandling, .secondTrial, .execution, .retrial].contains(step.stepType)
                case .completion:
                    return [.caseClose].contains(step.stepType)
                }
            }
            
            if !relevantSteps.isEmpty {
                milestones.append(ProgressMilestone(
                    id: UUID().uuidString,
                    title: "\(phase.rawValue)完成",
                    description: "完成\(phase.rawValue)的所有必要步骤",
                    targetDate: Calendar.current.date(
                        byAdding: .day,
                        value: (phases.firstIndex(of: phase) ?? 0) * 30 + 30,
                        to: Date()
                    ) ?? Date(),
                    actualCompletionDate: nil,
                    isCompleted: false,
                    importance: phase == .judgment ? .critical : .important,
                    dependencies: relevantSteps.map { $0.id }
                ))
            }
        }
        
        return milestones
    }
    
    private func executeStepLogic(
        step: EnhancedWorkflowStep,
        userInput: [String: Any]
    ) async throws -> StepExecutionResult {
        
        var outputs: [String: Any] = [:]
        var warnings: [String] = []
        var generatedDocuments: [GeneratedDocument] = []
        var aiAnalysis: AIAnalysisResult?
        
        // 根据步骤类型执行特定逻辑
        switch step.stepType {
        case .analysis:
            aiAnalysis = try await performCaseAnalysis(step: step, userInput: userInput)
            outputs["analysis"] = aiAnalysis
            
        case .materialPreparation:
            let preparedMaterials = try await prepareMaterials(step: step, userInput: userInput)
            outputs["materials"] = preparedMaterials
            
        case .caseFilingGuidance:
            let guidance = try await generateFilingGuidance(step: step, userInput: userInput)
            outputs["guidance"] = guidance
            
        case .evidencePreparation:
            let evidence = try await prepareEvidence(step: step, userInput: userInput)
            outputs["evidence"] = evidence
            
        case .defenseResponse:
            let response = try await generateDefenseResponse(step: step, userInput: userInput)
            outputs["response"] = response
            if let document = response as? GeneratedDocument {
                generatedDocuments.append(document)
            }
            
        case .judgmentAnalysis:
            aiAnalysis = try await analyzeJudgment(step: step, userInput: userInput)
            outputs["judgment_analysis"] = aiAnalysis
            
        default:
            // 默认处理
            outputs["status"] = "completed"
        }
        
        return StepExecutionResult(
            stepId: step.id,
            success: true,
            executionTime: 0, // 将在调用处计算
            outputs: outputs,
            aiAnalysis: aiAnalysis,
            generatedDocuments: generatedDocuments,
            nextRecommendedStep: nil, // 将在调用处设置
            warnings: warnings,
            errors: []
        )
    }
    
    private func executeAgentIntegration(
        integration: AgentWorkflowIntegration,
        step: EnhancedWorkflowStep,
        userInput: [String: Any]
    ) async throws -> AgentResponse {
        
        // 构建AI代理请求
        let request = AgentRequest(
            id: UUID().uuidString,
            agentType: integration.agentType,
            caseType: .contractDispute, // TODO: 从实际案件获取
            content: buildAgentContent(step: step, userInput: userInput),
            context: buildAgentContext(step: step, userInput: userInput),
            priority: .normal,
            createdAt: Date()
        )
        
        return try await agentService.sendRequest(request)
    }
    
    private func buildAgentContent(step: EnhancedWorkflowStep, userInput: [String: Any]) -> String {
        var content = "请协助处理以下工作流程步骤：\n"
        content += "步骤类型：\(step.stepType.rawValue)\n"
        content += "步骤描述：\(step.description)\n"
        
        if !userInput.isEmpty {
            content += "用户输入：\n"
            for (key, value) in userInput {
                content += "- \(key): \(value)\n"
            }
        }
        
        return content
    }
    
    private func buildAgentContext(step: EnhancedWorkflowStep, userInput: [String: Any]) -> AgentContext? {
        // TODO: 构建更详细的上下文信息
        return nil
    }
    
    private func incorporateAgentResult(
        agentResult: AgentResponse,
        into step: inout EnhancedWorkflowStep,
        stepResult: StepExecutionResult
    ) async {
        // 将AI代理结果整合到步骤结果中
        // TODO: 实现AI结果整合逻辑
    }
    
    private func updateWorkflowProgress(workflowId: String) async throws {
        guard var workflow = currentWorkflows[workflowId] else { return }
        
        let completedSteps = workflow.steps.filter { $0.status == .completed }.count
        workflow.progress.completedSteps = completedSteps
        
        // 更新当前阶段
        let currentPhase = determineCurrentPhase(workflow: workflow)
        workflow.progress.currentPhase = currentPhase
        
        // 更新阶段进度
        workflow.progress.phaseProgress = calculatePhaseProgress(workflow: workflow, phase: currentPhase)
        
        // 检查里程碑完成状态
        for i in 0..<workflow.progress.milestones.count {
            var milestone = workflow.progress.milestones[i]
            if !milestone.isCompleted {
                let dependencySteps = workflow.steps.filter { milestone.dependencies.contains($0.id) }
                if dependencySteps.allSatisfy({ $0.status == .completed }) {
                    milestone.isCompleted = true
                    milestone.actualCompletionDate = Date()
                    workflow.progress.milestones[i] = milestone
                }
            }
        }
        
        workflow.updatedAt = Date()
        currentWorkflows[workflowId] = workflow
        workflowProgress[workflowId] = workflow.progress
        
        // 通知进度服务
        await progressService.updateProgress(workflowId: workflowId, progress: workflow.progress)
    }
    
    private func checkAndTriggerNextStep(workflowId: String) async {
        guard var workflow = currentWorkflows[workflowId] else { return }
        
        // 检查是否可以自动触发下一个步骤
        if workflow.currentStepIndex < workflow.steps.count - 1 {
            let nextStep = workflow.steps[workflow.currentStepIndex + 1]
            
            // 如果下一步骤的前置条件满足，可以自动开始
            if nextStep.canStart() && shouldAutoStart(step: nextStep) {
                workflow.currentStepIndex += 1
                workflow.updatedAt = Date()
                currentWorkflows[workflowId] = workflow
                
                // 可以在这里添加自动开始逻辑
            }
        }
    }
    
    private func shouldAutoStart(step: EnhancedWorkflowStep) -> Bool {
        // 根据步骤类型决定是否自动开始
        switch step.stepType {
        case .analysis:
            return true // 分析步骤可以自动开始
        default:
            return false // 其他步骤需要用户主动触发
        }
    }
    
    private func saveWorkflow(_ workflow: EnhancedCaseWorkflow) async throws {
        // TODO: 实现工作流程的持久化存储
        // 可以使用Core Data或其他存储方案
        try await progressService.saveWorkflow(workflow)
    }
    
    // MARK: - Step Execution Methods
    
    private func performCaseAnalysis(
        step: EnhancedWorkflowStep,
        userInput: [String: Any]
    ) async throws -> AIAnalysisResult {
        
        // 构建分析请求
        let analysisContent = userInput["caseDescription"] as? String ?? ""
        
        let request = AgentRequest(
            id: UUID().uuidString,
            agentType: .caseAnalyst,
            caseType: .contractDispute, // TODO: 从实际案件获取
            content: analysisContent,
            context: nil,
            priority: .normal,
            createdAt: Date()
        )
        
        let response = try await agentService.sendRequest(request)
        
        return AIAnalysisResult(
            id: response.id,
            documentType: "案件分析",
            analysisDate: Date(),
            keyFindings: response.recommendations?.map { $0.title } ?? [],
            suggestedActions: response.recommendations?.map { $0.description } ?? [],
            evidenceStrength: response.confidence,
            riskAssessment: extractRiskAssessment(from: response.content),
            generatedDocument: nil,
            confidence: response.confidence
        )
    }
    
    private func prepareMaterials(
        step: EnhancedWorkflowStep,
        userInput: [String: Any]
    ) async throws -> [String: Any] {
        
        var materials: [String: Any] = [:]
        
        // 准备必需的文档
        let requiredDocs = step.requiredDocuments.filter { $0.isRequired }
        materials["required_documents"] = requiredDocs.map { $0.name }
        
        // 生成文档清单
        let checklist = requiredDocs.map { doc in
            [
                "name": doc.name,
                "description": doc.description,
                "template_available": doc.template != nil,
                "sample_available": doc.sampleDocument != nil
            ]
        }
        materials["document_checklist"] = checklist
        
        return materials
    }
    
    private func generateFilingGuidance(
        step: EnhancedWorkflowStep,
        userInput: [String: Any]
    ) async throws -> [String: Any] {
        
        var guidance: [String: Any] = [:]
        
        // 提取案件信息
        let caseValue = userInput["case_value"] as? Double ?? 0
        let caseLocation = userInput["case_location"] as? String ?? ""
        
        // 确定管辖法院
        let court = determineJurisdiction(caseValue: caseValue, location: caseLocation)
        guidance["court"] = court
        
        // 计算诉讼费用
        let fees = calculateLitigationFees(caseValue: caseValue)
        guidance["fees"] = fees
        
        // 生成提交指导
        guidance["filing_steps"] = generateFilingSteps()
        guidance["required_copies"] = calculateRequiredCopies(caseValue: caseValue)
        
        return guidance
    }
    
    private func prepareEvidence(
        step: EnhancedWorkflowStep,
        userInput: [String: Any]
    ) async throws -> [String: Any] {
        
        var evidence: [String: Any] = [:]
        
        // 分析上传的证据
        if let uploadedFiles = userInput["uploaded_files"] as? [String] {
            let analysisResults = try await analyzeEvidenceFiles(files: uploadedFiles)
            evidence["analysis_results"] = analysisResults
        }
        
        // 生成证据清单
        evidence["evidence_list"] = generateEvidenceList(from: userInput)
        
        // 建议补充证据
        evidence["suggestions"] = generateEvidenceSuggestions(from: userInput)
        
        return evidence
    }
    
    private func generateDefenseResponse(
        step: EnhancedWorkflowStep,
        userInput: [String: Any]
    ) async throws -> GeneratedDocument {
        
        // 使用文档生成服务创建答辩书
        let templateId = "defense_response_template"
        let fieldValues = extractFieldValues(from: userInput)
        
        return try await documentService.generateDocument(
            templateId: templateId,
            fieldValues: fieldValues
        )
    }
    
    private func analyzeJudgment(
        step: EnhancedWorkflowStep,
        userInput: [String: Any]
    ) async throws -> AIAnalysisResult {
        
        // 获取判决书内容
        guard let judgmentContent = userInput["judgment_content"] as? String else {
            throw WorkflowError.invalidInput("缺少判决书内容")
        }
        
        let request = AgentRequest(
            id: UUID().uuidString,
            agentType: .caseAnalyst,
            caseType: .contractDispute,
            content: "请分析以下判决书内容：\n\(judgmentContent)",
            context: nil,
            priority: .normal,
            createdAt: Date()
        )
        
        let response = try await agentService.sendRequest(request)
        
        return AIAnalysisResult(
            id: response.id,
            documentType: "判决书分析",
            analysisDate: Date(),
            keyFindings: extractKeyFindings(from: response.content),
            suggestedActions: response.recommendations?.map { $0.description } ?? [],
            evidenceStrength: response.confidence,
            riskAssessment: extractRiskAssessment(from: response.content),
            generatedDocument: nil,
            confidence: response.confidence
        )
    }
    
    // MARK: - Helper Methods
    
    private func extractRiskAssessment(from content: String) -> String {
        // 从AI响应中提取风险评估
        if content.contains("风险") {
            let lines = content.components(separatedBy: .newlines)
            return lines.first { $0.contains("风险") } ?? "未识别具体风险"
        }
        return "需要进一步分析风险因素"
    }
    
    private func extractKeyFindings(from content: String) -> [String] {
        // 从AI响应中提取关键发现
        let lines = content.components(separatedBy: .newlines)
        return lines.compactMap { line in
            if line.contains("关键") || line.contains("重要") || line.contains("发现") {
                return line.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return nil
        }
    }
    
    private func determineJurisdiction(caseValue: Double, location: String) -> [String: Any] {
        var court: [String: Any] = [:]
        
        if caseValue > 500000 { // 50万以上
            court["level"] = "中级人民法院"
            court["name"] = "\(location)中级人民法院"
        } else if caseValue > 100000 { // 10万-50万
            court["level"] = "区县人民法院"
            court["name"] = "\(location)区人民法院"
        } else {
            court["level"] = "基层人民法院"
            court["name"] = "\(location)人民法院"
        }
        
        court["address"] = "需要查询具体地址"
        court["phone"] = "需要查询联系方式"
        
        return court
    }
    
    private func calculateLitigationFees(caseValue: Double) -> [String: Any] {
        var fees: [String: Any] = [:]
        
        // 简化的诉讼费计算
        let baseFee = min(caseValue * 0.02, 10000) // 2%，最高1万
        fees["court_fee"] = baseFee
        fees["attorney_fee_estimated"] = caseValue * 0.03 // 预估律师费3%
        fees["other_fees"] = baseFee * 0.1 // 其他费用
        fees["total_estimated"] = baseFee + caseValue * 0.03 + baseFee * 0.1
        
        return fees
    }
    
    private func generateFilingSteps() -> [String] {
        return [
            "准备起诉状及相关证据材料",
            "制作证据清单和目录",
            "准备身份证明和授权委托书",
            "到法院立案庭提交材料",
            "缴纳诉讼费用",
            "等待法院立案通知"
        ]
    }
    
    private func calculateRequiredCopies(caseValue: Double) -> Int {
        // 根据案件价值和可能的被告数量计算需要的副本数
        return 3 // 简化实现
    }
    
    private func analyzeEvidenceFiles(files: [String]) async throws -> [String: Any] {
        // 模拟证据文件分析
        return [
            "total_files": files.count,
            "file_types": ["PDF", "图片", "Word文档"],
            "completeness_score": 0.8,
            "quality_score": 0.75
        ]
    }
    
    private func generateEvidenceList(from userInput: [String: Any]) -> [String] {
        // 基于用户输入生成证据清单
        return [
            "合同原件",
            "付款凭证",
            "通讯记录",
            "银行流水"
        ]
    }
    
    private func generateEvidenceSuggestions(from userInput: [String: Any]) -> [String] {
        return [
            "建议补充收集对方确认收货的证据",
            "如有见证人，建议收集证人证言",
            "补充银行转账记录的完整性"
        ]
    }
    
    private func extractFieldValues(from userInput: [String: Any]) -> [String: Any] {
        // 从用户输入中提取字段值，用于文档生成
        var fieldValues: [String: Any] = [:]
        
        fieldValues["plaintiff_name"] = userInput["plaintiff_name"] ?? ""
        fieldValues["defendant_name"] = userInput["defendant_name"] ?? ""
        fieldValues["case_description"] = userInput["case_description"] ?? ""
        fieldValues["claim_amount"] = userInput["claim_amount"] ?? 0
        
        return fieldValues
    }
    
    private func getNextRecommendedStep(workflowId: String) -> String? {
        guard let workflow = currentWorkflows[workflowId] else { return nil }
        
        if workflow.currentStepIndex < workflow.steps.count - 1 {
            return workflow.steps[workflow.currentStepIndex + 1].id
        }
        
        return nil
    }
    
    // MARK: - Analytics and Progress Methods
    
    private func calculateAvgExecutionTime(for step: EnhancedWorkflowStep) -> TimeInterval {
        // TODO: 从历史数据计算平均执行时间
        return TimeInterval(step.estimatedDays * 24 * 3600) // 简化实现
    }
    
    private func calculateErrorRate(for step: EnhancedWorkflowStep) -> Double {
        // TODO: 计算步骤的错误率
        return 0.05 // 简化实现：5%错误率
    }
    
    private func determineCurrentPhase(workflow: EnhancedCaseWorkflow) -> WorkflowPhase {
        guard let currentStep = workflow.currentStep else { return .completion }
        
        switch currentStep.stepType {
        case .analysis, .materialPreparation:
            return .preparation
        case .caseFilingGuidance, .litigation:
            return .filing
        case .evidencePreparation:
            return .discovery
        case .defenseResponse:
            return .trial
        case .judgmentAnalysis:
            return .judgment
        case .postTrialHandling, .secondTrial, .execution, .retrial:
            return .postTrial
        case .caseClose:
            return .completion
        default:
            return .preparation
        }
    }
    
    private func calculatePhaseProgress(workflow: EnhancedCaseWorkflow, phase: WorkflowPhase) -> Double {
        let phaseSteps = workflow.steps.filter { step in
            let stepPhase = getStepPhase(stepType: step.stepType)
            return stepPhase == phase
        }
        
        guard !phaseSteps.isEmpty else { return 0.0 }
        
        let completedPhaseSteps = phaseSteps.filter { $0.status == .completed }.count
        return Double(completedPhaseSteps) / Double(phaseSteps.count)
    }
    
    private func getStepPhase(stepType: CaseWorkflowStepType) -> WorkflowPhase {
        switch stepType {
        case .analysis, .materialPreparation:
            return .preparation
        case .caseFilingGuidance, .litigation:
            return .filing
        case .evidencePreparation:
            return .discovery
        case .defenseResponse:
            return .trial
        case .judgmentAnalysis:
            return .judgment
        case .postTrialHandling, .secondTrial, .execution, .retrial:
            return .postTrial
        case .caseClose:
            return .completion
        default:
            return .preparation
        }
    }
    
    private func estimateTimeToCompletion(workflow: EnhancedCaseWorkflow) -> TimeInterval {
        let remainingSteps = workflow.steps.filter { $0.status != .completed }
        let estimatedDays = remainingSteps.reduce(0) { $0 + $1.estimatedDays }
        return TimeInterval(estimatedDays * 24 * 3600)
    }
    
    private func calculateQualityScore(workflow: EnhancedCaseWorkflow) -> Double {
        // 基于多个因素计算质量评分
        var score = 1.0
        
        // 考虑AI准确度
        score *= workflow.metadata.performanceMetrics.aiAccuracyScore
        
        // 考虑用户满意度
        score *= workflow.metadata.performanceMetrics.userSatisfactionScore
        
        // 考虑效率
        score *= workflow.metadata.performanceMetrics.efficiencyScore
        
        return score
    }
    
    private func generateUserBehaviorInsights(workflow: EnhancedCaseWorkflow) -> UserBehaviorInsights {
        // 分析用户行为模式
        let interactions = workflow.metadata.userInteractions
        
        // 找出耗时最长的步骤
        let timeConsumingSteps = interactions
            .filter { $0.duration != nil }
            .sorted { ($0.duration ?? 0) > ($1.duration ?? 0) }
            .prefix(3)
            .map { $0.stepId }
        
        return UserBehaviorInsights(
            mostTimeConsumingSteps: Array(timeConsumingSteps),
            frequentlySkippedSteps: [], // TODO: 实现跳过步骤分析
            highErrorRateSteps: [], // TODO: 实现错误率分析
            userPreferences: [:], // TODO: 分析用户偏好
            accessPatterns: [] // TODO: 分析访问模式
        )
    }
    
    private func generatePerformanceTrends(workflow: EnhancedCaseWorkflow) -> [PerformanceTrend] {
        // 生成性能趋势数据
        return [
            PerformanceTrend(
                id: UUID().uuidString,
                metricName: "执行效率",
                dataPoints: [
                    TrendDataPoint(timestamp: Date(), value: workflow.metadata.performanceMetrics.efficiencyScore, context: [:])
                ],
                trendDirection: .stable,
                significance: 0.7
            )
        ]
    }
    
    private func generateAnalyticsRecommendations(workflow: EnhancedCaseWorkflow) -> [AnalyticsRecommendation] {
        var recommendations: [AnalyticsRecommendation] = []
        
        // 基于性能指标生成建议
        if workflow.metadata.performanceMetrics.efficiencyScore < 0.7 {
            recommendations.append(AnalyticsRecommendation(
                id: UUID().uuidString,
                title: "优化工作流程效率",
                description: "当前工作流程效率较低，建议重新评估步骤设置和自动化程度",
                impact: .high,
                effort: .moderate,
                category: .performance,
                metrics: ["efficiencyScore"],
                expectedImprovement: 0.2
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Event Handlers
    
    private func handleAgentResponses(_ responses: [AgentResponse]) async {
        // 处理AI代理响应
        for response in responses {
            // 更新相关工作流程的AI分析结果
            await updateWorkflowWithAgentResponse(response)
        }
    }
    
    private func handleProgressUpdates(_ updates: [String: WorkflowProgress]) async {
        // 处理进度更新
        for (workflowId, progress) in updates {
            workflowProgress[workflowId] = progress
            
            if var workflow = currentWorkflows[workflowId] {
                workflow.progress = progress
                workflow.updatedAt = Date()
                currentWorkflows[workflowId] = workflow
            }
        }
    }
    
    private func updateWorkflowWithAgentResponse(_ response: AgentResponse) async {
        // 根据AI代理响应更新相关工作流程
        // TODO: 实现AI响应与工作流程的关联逻辑
    }
}

// MARK: - Supporting Types

/// 步骤执行结果
struct StepExecutionResult {
    let stepId: String
    let success: Bool
    let executionTime: TimeInterval
    let outputs: [String: Any]
    let aiAnalysis: AIAnalysisResult?
    let generatedDocuments: [GeneratedDocument]
    let nextRecommendedStep: String?
    let warnings: [String]
    let errors: [String]
}

/// 工作流程错误
enum WorkflowError: LocalizedError {
    case workflowNotFound(String)
    case stepNotFound(String)
    case stepNotReady(String)
    case stepExecutionFailed(String, String)
    case invalidInput(String)
    case agentIntegrationFailed(String)
    case documentGenerationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .workflowNotFound(let id):
            return "找不到工作流程: \(id)"
        case .stepNotFound(let id):
            return "找不到步骤: \(id)"
        case .stepNotReady(let id):
            return "步骤未准备就绪: \(id)"
        case .stepExecutionFailed(let stepId, let reason):
            return "步骤 \(stepId) 执行失败: \(reason)"
        case .invalidInput(let message):
            return "无效输入: \(message)"
        case .agentIntegrationFailed(let reason):
            return "AI代理集成失败: \(reason)"
        case .documentGenerationFailed(let reason):
            return "文档生成失败: \(reason)"
        }
    }
}