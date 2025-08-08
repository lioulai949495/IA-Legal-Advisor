import Foundation
import SwiftUI

// MARK: - Enhanced Workflow Models

/// 增强的案件工作流程
struct EnhancedCaseWorkflow: Identifiable, Codable {
    let id: String
    let caseId: String
    let workflowType: WorkflowType
    var steps: [EnhancedWorkflowStep]
    var currentStepIndex: Int
    var progress: WorkflowProgress
    let createdAt: Date
    var updatedAt: Date
    var metadata: WorkflowMetadata
    
    var currentStep: EnhancedWorkflowStep? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }
    
    var isCompleted: Bool {
        return steps.allSatisfy { $0.status == .completed }
    }
    
    var completionPercentage: Double {
        let completedSteps = steps.filter { $0.status == .completed }.count
        return Double(completedSteps) / Double(steps.count)
    }
}

/// 工作流程类型
enum WorkflowType: String, Codable, CaseIterable {
    case standardLitigation = "标准诉讼流程"
    case fastTrackLitigation = "简易诉讼流程"
    case mediationFirst = "调解优先流程"
    case arbitrationProcess = "仲裁流程"
    case administrativeLitigation = "行政诉讼流程"
    case customWorkflow = "自定义流程"
    
    var description: String {
        switch self {
        case .standardLitigation:
            return "完整的民事诉讼流程，适用于复杂案件"
        case .fastTrackLitigation:
            return "简化的诉讼流程，适用于争议较少的案件"
        case .mediationFirst:
            return "优先考虑调解的解决方案"
        case .arbitrationProcess:
            return "仲裁程序，适用于有仲裁条款的合同纠纷"
        case .administrativeLitigation:
            return "行政案件专用流程"
        case .customWorkflow:
            return "根据具体情况定制的工作流程"
        }
    }
    
    var estimatedDuration: String {
        switch self {
        case .standardLitigation:
            return "6-18个月"
        case .fastTrackLitigation:
            return "3-6个月"
        case .mediationFirst:
            return "1-3个月"
        case .arbitrationProcess:
            return "3-9个月"
        case .administrativeLitigation:
            return "6-12个月"
        case .customWorkflow:
            return "待定"
        }
    }
}

/// 工作流程进度
struct WorkflowProgress: Codable {
    var completedSteps: Int
    var totalSteps: Int
    var currentPhase: WorkflowPhase
    var phaseProgress: Double // 0.0 - 1.0
    var milestones: [ProgressMilestone]
    var blockers: [WorkflowBlocker]
    
    var overallProgress: Double {
        return Double(completedSteps) / Double(totalSteps)
    }
    
    var nextMilestone: ProgressMilestone? {
        return milestones.first { !$0.isCompleted }
    }
}

/// 工作流程阶段
enum WorkflowPhase: String, Codable, CaseIterable {
    case preparation = "准备阶段"
    case filing = "提交阶段"
    case discovery = "证据收集阶段"
    case trial = "审理阶段"
    case judgment = "判决阶段"
    case postTrial = "审后阶段"
    case completion = "完结阶段"
    
    var color: Color {
        switch self {
        case .preparation: return .blue
        case .filing: return .orange
        case .discovery: return .green
        case .trial: return .red
        case .judgment: return .purple
        case .postTrial: return .indigo
        case .completion: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .preparation: return "folder.badge.plus"
        case .filing: return "paperplane.fill"
        case .discovery: return "magnifyingglass"
        case .trial: return "building.columns"
        case .judgment: return "scale.3d"
        case .postTrial: return "checklist"
        case .completion: return "checkmark.circle.fill"
        }
    }
}

/// 进度里程碑
struct ProgressMilestone: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let targetDate: Date
    var actualCompletionDate: Date?
    var isCompleted: Bool
    let importance: MilestoneImportance
    let dependencies: [String] // 依赖的步骤ID
    
    enum MilestoneImportance: String, Codable {
        case critical = "关键"
        case important = "重要"
        case normal = "普通"
        
        var color: Color {
            switch self {
            case .critical: return .red
            case .important: return .orange
            case .normal: return .blue
            }
        }
    }
}

/// 工作流程阻塞项
struct WorkflowBlocker: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let blockerType: BlockerType
    let severity: BlockerSeverity
    let affectedSteps: [String] // 受影响的步骤ID
    let createdAt: Date
    var resolvedAt: Date?
    var resolution: String?
    
    var isResolved: Bool {
        return resolvedAt != nil
    }
    
    enum BlockerType: String, Codable {
        case documentMissing = "文档缺失"
        case legalCompliance = "法律合规"
        case procedural = "程序问题"
        case external = "外部依赖"
        case technical = "技术问题"
        case financial = "资金问题"
    }
    
    enum BlockerSeverity: String, Codable {
        case low = "低"
        case medium = "中"
        case high = "高"
        case critical = "严重"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
}

/// 工作流程元数据
struct WorkflowMetadata: Codable {
    var aiConsultationCount: Int
    var documentGenerationCount: Int
    var userInteractions: [UserInteraction]
    var systemRecommendations: [SystemRecommendation]
    var performanceMetrics: WorkflowPerformanceMetrics
    var customFields: [String: String]
}

/// 用户交互记录
struct UserInteraction: Identifiable, Codable {
    let id: String
    let stepId: String
    let interactionType: InteractionType
    let description: String
    let timestamp: Date
    let duration: TimeInterval?
    
    enum InteractionType: String, Codable {
        case stepCompleted = "步骤完成"
        case documentUploaded = "文档上传"
        case aiConsultation = "AI咨询"
        case formFilled = "表单填写"
        case decisionMade = "决策制定"
    }
}

/// 系统推荐
struct SystemRecommendation: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let recommendationType: RecommendationType
    let targetStepId: String?
    let priority: RecommendationPriority
    let createdAt: Date
    var isAccepted: Bool?
    var userFeedback: String?
    
    enum RecommendationType: String, Codable {
        case processOptimization = "流程优化"
        case documentSuggestion = "文档建议"
        case strategicAdvice = "策略建议"
        case riskMitigation = "风险缓解"
        case costSaving = "成本节约"
    }
    
    enum RecommendationPriority: String, Codable {
        case low = "低"
        case medium = "中"
        case high = "高"
        case urgent = "紧急"
        
        var color: Color {
            switch self {
            case .low: return .gray
            case .medium: return .blue
            case .high: return .orange
            case .urgent: return .red
            }
        }
    }
}

/// 工作流程性能指标
struct WorkflowPerformanceMetrics: Codable {
    var avgStepCompletionTime: TimeInterval
    var totalTimeSpent: TimeInterval
    var efficiencyScore: Double // 0.0 - 1.0
    var userSatisfactionScore: Double // 0.0 - 1.0
    var aiAccuracyScore: Double // 0.0 - 1.0
    var costEffectivenessScore: Double // 0.0 - 1.0
    var lastUpdated: Date
}

// MARK: - AI Agent Integration Models

/// AI代理工作流程集成
struct AgentWorkflowIntegration: Codable {
    let stepId: String
    let agentType: AgentType
    let integrationMode: IntegrationMode
    let triggerConditions: [TriggerCondition]
    let expectedOutputs: [ExpectedOutput]
    var configuration: AgentConfiguration
    
    enum IntegrationMode: String, Codable {
        case automatic = "自动"
        case userTriggered = "用户触发"
        case conditional = "条件触发"
        case scheduled = "定时触发"
    }
}

/// 触发条件
struct TriggerCondition: Codable {
    let conditionType: ConditionType
    let parameter: String
    let expectedValue: String
    let comparisonOperator: ComparisonOperator
    
    enum ConditionType: String, Codable {
        case stepStatus = "步骤状态"
        case documentUploaded = "文档上传"
        case timeElapsed = "时间经过"
        case userAction = "用户操作"
        case dataThreshold = "数据阈值"
    }
    
    enum ComparisonOperator: String, Codable {
        case equals = "等于"
        case notEquals = "不等于"
        case greaterThan = "大于"
        case lessThan = "小于"
        case contains = "包含"
    }
}

/// 预期输出
struct ExpectedOutput: Codable {
    let outputType: OutputType
    let description: String
    let formatSpecification: String?
    let qualityThreshold: Double
    
    enum OutputType: String, Codable {
        case analysis = "分析报告"
        case document = "生成文档"
        case recommendation = "建议方案"
        case riskAssessment = "风险评估"
        case strategy = "策略规划"
    }
}

// MARK: - Step Enhancement Models

/// 步骤执行状态
struct StepExecutionStatus: Codable {
    var startedAt: Date?
    var completedAt: Date?
    var pausedAt: Date?
    var resumedAt: Date?
    var executionTime: TimeInterval
    var attempts: Int
    var errors: [StepExecutionError]
    var warnings: [StepExecutionWarning]
}

/// 步骤执行错误
struct StepExecutionError: Identifiable, Codable {
    let id: String
    let errorCode: String
    let message: String
    let timestamp: Date
    let severity: ErrorSeverity
    let context: [String: String]
    var resolution: String?
    
    enum ErrorSeverity: String, Codable {
        case info = "信息"
        case warning = "警告"
        case error = "错误"
        case critical = "严重"
    }
}

/// 步骤执行警告
struct StepExecutionWarning: Identifiable, Codable {
    let id: String
    let message: String
    let timestamp: Date
    let warningType: WarningType
    let actionRequired: Bool
    
    enum WarningType: String, Codable {
        case dataQuality = "数据质量"
        case compliance = "合规性"
        case performance = "性能"
        case security = "安全性"
    }
}

// MARK: - Workflow Analytics

/// 工作流程分析数据
struct WorkflowAnalytics: Codable {
    let workflowId: String
    let analysisDate: Date
    var stepAnalytics: [StepAnalytics]
    var overallMetrics: OverallWorkflowMetrics
    var userBehaviorInsights: UserBehaviorInsights
    var performanceTrends: [PerformanceTrend]
    var recommendations: [AnalyticsRecommendation]
}

/// 步骤分析数据
struct StepAnalytics: Identifiable, Codable {
    let id: String
    let stepId: String
    var completionRate: Double
    var avgExecutionTime: TimeInterval
    var errorRate: Double
    var userSatisfactionScore: Double
    var aiAccuracy: Double
    var resourceUtilization: ResourceUtilization
}

/// 整体工作流程指标
struct OverallWorkflowMetrics: Codable {
    var totalExecutionTime: TimeInterval
    var successRate: Double
    var userEngagementScore: Double
    var costEfficiency: Double
    var timeToCompletion: TimeInterval
    var qualityScore: Double
}

/// 用户行为洞察
struct UserBehaviorInsights: Codable {
    var mostTimeConsumingSteps: [String]
    var frequentlySkippedSteps: [String]
    var highErrorRateSteps: [String]
    var userPreferences: [String: String]
    var accessPatterns: [AccessPattern]
}

/// 访问模式
struct AccessPattern: Codable {
    let timeOfDay: Int // 0-23
    let dayOfWeek: Int // 1-7
    let frequency: Int
    let avgSessionDuration: TimeInterval
}

/// 性能趋势
struct PerformanceTrend: Identifiable, Codable {
    let id: String
    let metricName: String
    let dataPoints: [TrendDataPoint]
    let trendDirection: TrendDirection
    let significance: Double
    
    enum TrendDirection: String, Codable {
        case improving = "改善"
        case declining = "下降"
        case stable = "稳定"
        case volatile = "波动"
    }
}

/// 趋势数据点
struct TrendDataPoint: Codable {
    let timestamp: Date
    let value: Double
    let context: [String: String]
}

/// 分析建议
struct AnalyticsRecommendation: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let impact: RecommendationImpact
    let effort: ImplementationEffort
    let category: RecommendationCategory
    let metrics: [String]
    let expectedImprovement: Double
    
    enum RecommendationImpact: String, Codable {
        case low = "低"
        case medium = "中"
        case high = "高"
        case critical = "严重"
    }
    
    enum ImplementationEffort: String, Codable {
        case minimal = "很少"
        case moderate = "中等"
        case significant = "较多"
        case extensive = "很多"
    }
    
    enum RecommendationCategory: String, Codable {
        case userExperience = "用户体验"
        case performance = "性能优化"
        case automation = "自动化"
        case costReduction = "成本降低"
        case qualityImprovement = "质量提升"
    }
}

/// 资源利用率
struct ResourceUtilization: Codable {
    var cpuUsage: Double
    var memoryUsage: Double
    var networkUsage: Double
    var storageUsage: Double
    var aiModelUsage: Double
    var apiCallCount: Int
    var timestamp: Date
}

// MARK: - Workflow Extensions

extension EnhancedWorkflowStep {
    /// 检查步骤是否可以开始执行
    func canStart() -> Bool {
        // 检查前置条件和依赖
        return status == .pending && 
               requiredDocuments.allSatisfy { !$0.isRequired || hasDocument($0.id) }
    }
    
    /// 检查是否有指定文档
    private func hasDocument(_ documentId: String) -> Bool {
        // 这里需要与文档管理系统集成
        return true // 临时实现
    }
    
    /// 获取步骤的AI代理集成配置
    func getAgentIntegration() -> AgentWorkflowIntegration? {
        // 根据步骤类型返回相应的AI代理集成配置
        switch stepType {
        case .analysis:
            return AgentWorkflowIntegration(
                stepId: id,
                agentType: .caseAnalyst,
                integrationMode: .automatic,
                triggerConditions: [
                    TriggerCondition(
                        conditionType: .stepStatus,
                        parameter: "status",
                        expectedValue: "inProgress",
                        comparisonOperator: .equals
                    )
                ],
                expectedOutputs: [
                    ExpectedOutput(
                        outputType: .analysis,
                        description: "案件分析报告",
                        formatSpecification: "JSON",
                        qualityThreshold: 0.8
                    )
                ],
                configuration: AgentConfiguration(
                    agentId: "case-analyst-001",
                    maxConcurrentRequests: 1,
                    responseTimeoutSeconds: 30,
                    confidenceThreshold: 0.8,
                    enabledFeatures: [.caseAnalysis, .legalResearch],
                    customPrompts: ["analysis_mode": "detailed", "depth": "comprehensive"]
                )
            )
        case .evidencePreparation:
            return AgentWorkflowIntegration(
                stepId: id,
                agentType: .documentGenerator,
                integrationMode: .userTriggered,
                triggerConditions: [],
                expectedOutputs: [
                    ExpectedOutput(
                        outputType: .document,
                        description: "法律文书",
                        formatSpecification: "PDF",
                        qualityThreshold: 0.9
                    )
                ],
                configuration: AgentConfiguration(
                    agentId: "document-generator-001",
                    maxConcurrentRequests: 1,
                    responseTimeoutSeconds: 60,
                    confidenceThreshold: 0.9,
                    enabledFeatures: [.documentGeneration, .contractReview],
                    customPrompts: ["response_length": "detailed", "analysis_depth": "standard"]
                )
            )
        default:
            return nil
        }
    }
}

extension WorkflowType {
    /// 获取工作流程类型对应的默认步骤
    func getDefaultSteps() -> [CaseWorkflowStepType] {
        switch self {
        case .standardLitigation:
            return [
                .analysis,
                .materialPreparation,
                .caseFilingGuidance,
                .litigation,
                .evidencePreparation,
                .defenseResponse,
                .judgmentAnalysis,
                .postTrialHandling,
                .caseClose
            ]
        case .fastTrackLitigation:
            return [
                .analysis,
                .materialPreparation,
                .litigation,
                .evidencePreparation,
                .judgmentAnalysis,
                .caseClose
            ]
        case .mediationFirst:
            return [
                .analysis,
                .materialPreparation,
                .defenseResponse,
                .postTrialHandling,
                .caseClose
            ]
        case .arbitrationProcess:
            return [
                .analysis,
                .materialPreparation,
                .evidencePreparation,
                .judgmentAnalysis,
                .postTrialHandling,
                .caseClose
            ]
        case .administrativeLitigation:
            return [
                .analysis,
                .materialPreparation,
                .caseFilingGuidance,
                .litigation,
                .evidencePreparation,
                .judgmentAnalysis,
                .retrial,
                .caseClose
            ]
        case .customWorkflow:
            return []
        }
    }
}