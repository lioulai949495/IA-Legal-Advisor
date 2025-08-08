import Foundation
import Combine
import SwiftUI

/// 工作流程进度服务
@MainActor
class WorkflowProgressService: ObservableObject {
    @MainActor static let shared = WorkflowProgressService()
    
    // MARK: - Published Properties
    @Published var progressUpdates: [String: WorkflowProgress] = [:]
    @Published var activeTracking: Set<String> = []
    @Published var recentMilestones: [ProgressMilestone] = []
    @Published var performanceMetrics: [String: WorkflowPerformanceMetrics] = [:]
    @Published var notifications: [ProgressNotification] = []
    
    // MARK: - Private Properties
    private let coreDataService: CoreDataService
    private var progressTrackers: [String: WorkflowProgressTracker] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let notificationCenter = NotificationCenter.default
    
    // MARK: - Constants
    private let updateInterval: TimeInterval = 5.0 // 5秒更新一次
    private let metricsRetentionDays = 30
    private let maxNotifications = 100
    
    // MARK: - Initialization
    private init(coreDataService: CoreDataService = .shared) {
        self.coreDataService = coreDataService
        setupProgressTracking()
        loadStoredProgress()
        startPeriodicUpdates()
    }
    
    // MARK: - Public Methods
    
    /// 开始跟踪工作流程进度
    func startTracking(workflowId: String, initialProgress: WorkflowProgress) async {
        let tracker = WorkflowProgressTracker(
            workflowId: workflowId,
            initialProgress: initialProgress
        )
        
        progressTrackers[workflowId] = tracker
        activeTracking.insert(workflowId)
        progressUpdates[workflowId] = initialProgress
        
        // 持久化初始进度
        try? await saveProgress(workflowId: workflowId, progress: initialProgress)
        
        // 发送开始跟踪通知
        await sendNotification(ProgressNotification(
            id: UUID().uuidString,
            workflowId: workflowId,
            type: .trackingStarted,
            title: "开始进度跟踪",
            message: "已开始跟踪工作流程进度",
            timestamp: Date(),
            priority: .info,
            isRead: false
        ))
    }
    
    /// 停止跟踪工作流程进度
    func stopTracking(workflowId: String) async {
        progressTrackers.removeValue(forKey: workflowId)
        activeTracking.remove(workflowId)
        
        // 发送停止跟踪通知
        await sendNotification(ProgressNotification(
            id: UUID().uuidString,
            workflowId: workflowId,
            type: .trackingStopped,
            title: "停止进度跟踪",
            message: "已停止跟踪工作流程进度",
            timestamp: Date(),
            priority: .info,
            isRead: false
        ))
    }
    
    /// 更新工作流程进度
    func updateProgress(workflowId: String, progress: WorkflowProgress) async {
        guard let tracker = progressTrackers[workflowId] else {
            // 如果没有跟踪器，创建一个新的
            await startTracking(workflowId: workflowId, initialProgress: progress)
            return
        }
        
        let previousProgress = progressUpdates[workflowId]
        progressUpdates[workflowId] = progress
        
        // 更新跟踪器
        await tracker.updateProgress(progress)
        
        // 检查里程碑完成
        await checkMilestoneCompletion(
            workflowId: workflowId,
            previousProgress: previousProgress,
            currentProgress: progress
        )
        
        // 检查阻塞项
        await checkForBlockers(workflowId: workflowId, progress: progress)
        
        // 更新性能指标
        await updatePerformanceMetrics(workflowId: workflowId, progress: progress)
        
        // 持久化进度
        try? await saveProgress(workflowId: workflowId, progress: progress)
        
        // 发送进度更新事件
        notificationCenter.post(
            name: .workflowProgressUpdated,
            object: self,
            userInfo: [
                "workflowId": workflowId,
                "progress": progress
            ]
        )
    }
    
    /// 添加里程碑
    func addMilestone(workflowId: String, milestone: ProgressMilestone) async {
        guard var progress = progressUpdates[workflowId] else { return }
        
        progress.milestones.append(milestone)
        await updateProgress(workflowId: workflowId, progress: progress)
        
        await sendNotification(ProgressNotification(
            id: UUID().uuidString,
            workflowId: workflowId,
            type: .milestoneAdded,
            title: "新增里程碑",
            message: "已添加里程碑: \(milestone.title)",
            timestamp: Date(),
            priority: .info,
            isRead: false
        ))
    }
    
    /// 完成里程碑
    func completeMilestone(workflowId: String, milestoneId: String) async {
        guard var progress = progressUpdates[workflowId] else { return }
        
        if let index = progress.milestones.firstIndex(where: { $0.id == milestoneId }) {
            progress.milestones[index].isCompleted = true
            progress.milestones[index].actualCompletionDate = Date()
            
            let milestone = progress.milestones[index]
            recentMilestones.insert(milestone, at: 0)
            
            // 保持最近里程碑列表不超过20个
            if recentMilestones.count > 20 {
                recentMilestones.removeLast()
            }
            
            await updateProgress(workflowId: workflowId, progress: progress)
            
            await sendNotification(ProgressNotification(
                id: UUID().uuidString,
                workflowId: workflowId,
                type: .milestoneCompleted,
                title: "里程碑完成",
                message: "已完成里程碑: \(milestone.title)",
                timestamp: Date(),
                priority: .success,
                isRead: false
            ))
        }
    }
    
    /// 添加阻塞项
    func addBlocker(workflowId: String, blocker: WorkflowBlocker) async {
        guard var progress = progressUpdates[workflowId] else { return }
        
        progress.blockers.append(blocker)
        await updateProgress(workflowId: workflowId, progress: progress)
        
        await sendNotification(ProgressNotification(
            id: UUID().uuidString,
            workflowId: workflowId,
            type: .blockerAdded,
            title: "发现阻塞项",
            message: "检测到阻塞: \(blocker.title)",
            timestamp: Date(),
            priority: blocker.severity == .critical ? .critical : .warning,
            isRead: false
        ))
    }
    
    /// 解决阻塞项
    func resolveBlocker(workflowId: String, blockerId: String, resolution: String) async {
        guard var progress = progressUpdates[workflowId] else { return }
        
        if let index = progress.blockers.firstIndex(where: { $0.id == blockerId }) {
            progress.blockers[index].resolvedAt = Date()
            progress.blockers[index].resolution = resolution
            
            let blocker = progress.blockers[index]
            
            await updateProgress(workflowId: workflowId, progress: progress)
            
            await sendNotification(ProgressNotification(
                id: UUID().uuidString,
                workflowId: workflowId,
                type: .blockerResolved,
                title: "阻塞项已解决",
                message: "已解决阻塞: \(blocker.title)",
                timestamp: Date(),
                priority: .success,
                isRead: false
            ))
        }
    }
    
    /// 获取工作流程统计信息
    func getWorkflowStatistics(workflowId: String) -> WorkflowStatistics? {
        guard let progress = progressUpdates[workflowId],
              let tracker = progressTrackers[workflowId] else {
            return nil
        }
        
        return WorkflowStatistics(
            workflowId: workflowId,
            currentProgress: progress,
            totalTimeSpent: tracker.totalTimeSpent,
            averageStepTime: tracker.averageStepCompletionTime,
            completionRate: progress.overallProgress,
            efficiency: calculateEfficiency(progress: progress, tracker: tracker),
            predictedCompletion: tracker.predictedCompletionDate,
            riskLevel: assessRiskLevel(progress: progress),
            recommendations: generateProgressRecommendations(progress: progress, tracker: tracker)
        )
    }
    
    /// 获取所有活跃工作流程的统计
    func getAllWorkflowStatistics() -> [WorkflowStatistics] {
        return activeTracking.compactMap { workflowId in
            getWorkflowStatistics(workflowId: workflowId)
        }
    }
    
    /// 生成进度报告
    func generateProgressReport(
        workflowId: String,
        reportType: ProgressReportType = .summary
    ) async -> ProgressReport? {
        
        guard let statistics = getWorkflowStatistics(workflowId: workflowId) else {
            return nil
        }
        
        let metrics = performanceMetrics[workflowId] ?? WorkflowPerformanceMetrics(
            avgStepCompletionTime: 0,
            totalTimeSpent: 0,
            efficiencyScore: 1.0,
            userSatisfactionScore: 1.0,
            aiAccuracyScore: 1.0,
            costEffectivenessScore: 1.0,
            lastUpdated: Date()
        )
        
        return ProgressReport(
            id: UUID().uuidString,
            workflowId: workflowId,
            reportType: reportType,
            generatedAt: Date(),
            statistics: statistics,
            metrics: metrics,
            insights: generateProgressInsights(statistics: statistics, metrics: metrics),
            recommendations: generateActionableRecommendations(statistics: statistics),
            charts: generateProgressCharts(statistics: statistics),
            summary: generateReportSummary(statistics: statistics, metrics: metrics)
        )
    }
    
    /// 保存工作流程
    func saveWorkflow(_ workflow: EnhancedCaseWorkflow) async throws {
        // 保存到Core Data
        try await coreDataService.saveWorkflow(workflow)
        
        // 更新进度跟踪
        await updateProgress(workflowId: workflow.id, progress: workflow.progress)
    }
    
    /// 加载工作流程
    func loadWorkflow(workflowId: String) async throws -> EnhancedCaseWorkflow? {
        // 从Core Data加载
        return try await coreDataService.loadWorkflow(id: workflowId)
    }
    
    // MARK: - Private Methods
    
    private func setupProgressTracking() {
        // 设置定时器和通知监听
        Timer.publish(every: updateInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.performPeriodicUpdate()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadStoredProgress() {
        Task {
            // 从持久存储加载之前的进度数据
            do {
                let storedProgress = try await coreDataService.loadAllWorkflowProgress()
                for (workflowId, progress) in storedProgress {
                    progressUpdates[workflowId] = progress
                    activeTracking.insert(workflowId)
                }
            } catch {
                print("加载存储进度失败: \(error)")
            }
        }
    }
    
    private func startPeriodicUpdates() {
        // 启动定期更新
        Timer.publish(every: 60, on: .main, in: .common) // 每分钟
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.performMaintenanceTasks()
                }
            }
            .store(in: &cancellables)
    }
    
    private func performPeriodicUpdate() async {
        // 更新所有活跃跟踪器
        for workflowId in activeTracking {
            if let tracker = progressTrackers[workflowId] {
                await tracker.performPeriodicUpdate()
                
                // 检查是否需要发送提醒
                await checkForReminders(workflowId: workflowId, tracker: tracker)
            }
        }
        
        // 清理过期的通知
        cleanupNotifications()
    }
    
    private func performMaintenanceTasks() async {
        // 清理过期数据
        await cleanupExpiredData()
        
        // 压缩历史数据
        await compressHistoricalData()
        
        // 备份重要数据
        await backupCriticalData()
    }
    
    private func checkMilestoneCompletion(
        workflowId: String,
        previousProgress: WorkflowProgress?,
        currentProgress: WorkflowProgress
    ) async {
        
        guard let previousProgress = previousProgress else { return }
        
        // 检查新完成的里程碑
        for milestone in currentProgress.milestones {
            let wasCompleted = previousProgress.milestones.first { $0.id == milestone.id }?.isCompleted ?? false
            
            if milestone.isCompleted && !wasCompleted {
                recentMilestones.insert(milestone, at: 0)
                
                await sendNotification(ProgressNotification(
                    id: UUID().uuidString,
                    workflowId: workflowId,
                    type: .milestoneCompleted,
                    title: "里程碑达成",
                    message: "恭喜！已完成里程碑: \(milestone.title)",
                    timestamp: Date(),
                    priority: .success,
                    isRead: false
                ))
            }
        }
    }
    
    private func checkForBlockers(workflowId: String, progress: WorkflowProgress) async {
        // 检查新的阻塞项
        let activeBlockers = progress.blockers.filter { !$0.isResolved }
        
        for blocker in activeBlockers {
            // 检查阻塞项是否是新的或者变得更严重
            if shouldNotifyAboutBlocker(blocker) {
                await sendNotification(ProgressNotification(
                    id: UUID().uuidString,
                    workflowId: workflowId,
                    type: .blockerDetected,
                    title: "检测到阻塞项",
                    message: "\(blocker.title) - \(blocker.description)",
                    timestamp: Date(),
                    priority: blocker.severity == .critical ? .critical : .warning,
                    isRead: false
                ))
            }
        }
    }
    
    private func shouldNotifyAboutBlocker(_ blocker: WorkflowBlocker) -> Bool {
        // 检查是否应该为这个阻塞项发送通知
        let timeSinceCreated = Date().timeIntervalSince(blocker.createdAt)
        
        switch blocker.severity {
        case .critical:
            return true // 严重阻塞总是通知
        case .high:
            return timeSinceCreated < 3600 // 高级阻塞1小时内通知
        case .medium:
            return timeSinceCreated < 3600 * 24 // 中级阻塞24小时内通知一次
        case .low:
            return timeSinceCreated < 3600 * 24 * 7 // 低级阻塞一周内通知一次
        }
    }
    
    private func updatePerformanceMetrics(workflowId: String, progress: WorkflowProgress) async {
        guard let tracker = progressTrackers[workflowId] else { return }
        
        let metrics = WorkflowPerformanceMetrics(
            avgStepCompletionTime: tracker.averageStepCompletionTime,
            totalTimeSpent: tracker.totalTimeSpent,
            efficiencyScore: calculateEfficiency(progress: progress, tracker: tracker),
            userSatisfactionScore: 1.0, // TODO: 从实际用户反馈获取
            aiAccuracyScore: 1.0, // TODO: 从AI代理获取准确度
            costEffectivenessScore: calculateCostEffectiveness(progress: progress, tracker: tracker),
            lastUpdated: Date()
        )
        
        performanceMetrics[workflowId] = metrics
    }
    
    private func calculateEfficiency(progress: WorkflowProgress, tracker: WorkflowProgressTracker) -> Double {
        // 计算效率分数 (0.0 - 1.0)
        let expectedTime = tracker.estimatedTotalTime
        let actualTime = tracker.totalTimeSpent
        
        guard expectedTime > 0 else { return 1.0 }
        
        let timeEfficiency = min(1.0, expectedTime / actualTime)
        let progressEfficiency = progress.overallProgress
        
        return (timeEfficiency + progressEfficiency) / 2.0
    }
    
    private func calculateCostEffectiveness(progress: WorkflowProgress, tracker: WorkflowProgressTracker) -> Double {
        // TODO: 实现成本效益计算
        return 0.8 // 简化实现
    }
    
    private func assessRiskLevel(progress: WorkflowProgress) -> RiskLevel {
        let activeBlockers = progress.blockers.filter { !$0.isResolved }
        let overdueMilestones = progress.milestones.filter { !$0.isCompleted && $0.targetDate < Date() }
        
        if activeBlockers.contains(where: { $0.severity == .critical }) {
            return .high
        }
        
        if overdueMilestones.count > 2 || activeBlockers.count > 3 {
            return .medium
        }
        
        if overdueMilestones.count > 0 || activeBlockers.count > 0 {
            return .low
        }
        
        return .none
    }
    
    private func generateProgressRecommendations(
        progress: WorkflowProgress,
        tracker: WorkflowProgressTracker
    ) -> [ProgressRecommendation] {
        
        var recommendations: [ProgressRecommendation] = []
        
        // 基于进度生成建议
        if progress.overallProgress < 0.3 && tracker.totalTimeSpent > tracker.estimatedTotalTime * 0.5 {
            recommendations.append(ProgressRecommendation(
                id: UUID().uuidString,
                type: .efficiency,
                title: "提高执行效率",
                description: "当前进度较慢，建议重新评估步骤复杂度或寻求额外帮助",
                priority: .high,
                actionItems: [
                    "审查当前步骤的执行方法",
                    "考虑并行处理可能性",
                    "寻求专业协助"
                ]
            ))
        }
        
        // 基于阻塞项生成建议
        let criticalBlockers = progress.blockers.filter { $0.severity == .critical && !$0.isResolved }
        if !criticalBlockers.isEmpty {
            recommendations.append(ProgressRecommendation(
                id: UUID().uuidString,
                type: .blocker,
                title: "解决关键阻塞",
                description: "存在\(criticalBlockers.count)个关键阻塞项需要立即处理",
                priority: .critical,
                actionItems: criticalBlockers.map { "解决: \($0.title)" }
            ))
        }
        
        return recommendations
    }
    
    private func checkForReminders(workflowId: String, tracker: WorkflowProgressTracker) async {
        // 检查是否需要发送提醒
        if let nextReminder = tracker.nextReminderTime,
           Date() >= nextReminder {
            
            await sendNotification(ProgressNotification(
                id: UUID().uuidString,
                workflowId: workflowId,
                type: .reminder,
                title: "进度提醒",
                message: "请检查工作流程进度并更新相关信息",
                timestamp: Date(),
                priority: .info,
                isRead: false
            ))
            
            // 设置下一次提醒时间
            tracker.nextReminderTime = Calendar.current.date(byAdding: .hour, value: 24, to: Date())
        }
    }
    
    private func sendNotification(_ notification: ProgressNotification) async {
        notifications.insert(notification, at: 0)
        
        // 保持通知列表不超过最大数量
        if notifications.count > maxNotifications {
            notifications = Array(notifications.prefix(maxNotifications))
        }
        
        // 发送系统通知
        notificationCenter.post(
            name: .progressNotificationReceived,
            object: self,
            userInfo: ["notification": notification]
        )
    }
    
    private func cleanupNotifications() {
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        notifications.removeAll { $0.timestamp < oneDayAgo && $0.isRead }
    }
    
    private func cleanupExpiredData() async {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -metricsRetentionDays, to: Date()) ?? Date()
        
        // 清理过期的性能指标
        for (workflowId, metrics) in performanceMetrics {
            if metrics.lastUpdated < cutoffDate {
                performanceMetrics.removeValue(forKey: workflowId)
            }
        }
    }
    
    private func compressHistoricalData() async {
        // TODO: 压缩历史数据以节省存储空间
    }
    
    private func backupCriticalData() async {
        // TODO: 备份关键数据
    }
    
    // MARK: - Progress Report Generation
    
    private func generateProgressInsights(
        statistics: WorkflowStatistics,
        metrics: WorkflowPerformanceMetrics
    ) -> [ProgressInsight] {
        
        var insights: [ProgressInsight] = []
        
        // 效率洞察
        if metrics.efficiencyScore > 0.8 {
            insights.append(ProgressInsight(
                id: UUID().uuidString,
                category: .efficiency,
                title: "高效执行",
                description: "当前工作流程执行效率较高，保持良好状态",
                severity: .positive,
                metrics: ["efficiency": metrics.efficiencyScore]
            ))
        } else if metrics.efficiencyScore < 0.5 {
            insights.append(ProgressInsight(
                id: UUID().uuidString,
                category: .efficiency,
                title: "效率偏低",
                description: "工作流程执行效率较低，建议分析原因并优化",
                severity: .negative,
                metrics: ["efficiency": metrics.efficiencyScore]
            ))
        }
        
        // 进度洞察
        if statistics.completionRate > 0.7 {
            insights.append(ProgressInsight(
                id: UUID().uuidString,
                category: .progress,
                title: "进展顺利",
                description: "工作流程已完成\(Int(statistics.completionRate * 100))%，进展良好",
                severity: .positive,
                metrics: ["completion_rate": statistics.completionRate]
            ))
        }
        
        return insights
    }
    
    private func generateActionableRecommendations(
        statistics: WorkflowStatistics
    ) -> [ActionableRecommendation] {
        
        var recommendations: [ActionableRecommendation] = []
        
        // 基于风险等级生成建议
        switch statistics.riskLevel {
        case .high:
            recommendations.append(ActionableRecommendation(
                id: UUID().uuidString,
                title: "高风险警报",
                description: "当前工作流程存在高风险，需要立即干预",
                priority: .critical,
                category: .risk,
                actions: [
                    ActionItem(title: "识别主要风险源", isCompleted: false),
                    ActionItem(title: "制定风险缓解计划", isCompleted: false),
                    ActionItem(title: "增加监控频率", isCompleted: false)
                ],
                expectedImpact: .high,
                estimatedEffort: .medium
            ))
        case .medium:
            recommendations.append(ActionableRecommendation(
                id: UUID().uuidString,
                title: "中等风险提醒",
                description: "工作流程存在一些风险，建议关注",
                priority: .medium,
                category: .risk,
                actions: [
                    ActionItem(title: "审查当前风险状况", isCompleted: false),
                    ActionItem(title: "更新风险应对措施", isCompleted: false)
                ],
                expectedImpact: .medium,
                estimatedEffort: .low
            ))
        default:
            break
        }
        
        return recommendations
    }
    
    private func generateProgressCharts(statistics: WorkflowStatistics) -> [ProgressChart] {
        return [
            ProgressChart(
                id: UUID().uuidString,
                type: .progress,
                title: "整体进度",
                data: [
                    ChartDataPoint(label: "已完成", value: statistics.completionRate * 100),
                    ChartDataPoint(label: "未完成", value: (1 - statistics.completionRate) * 100)
                ]
            ),
            ProgressChart(
                id: UUID().uuidString,
                type: .efficiency,
                title: "效率趋势",
                data: [
                    ChartDataPoint(label: "当前效率", value: statistics.efficiency * 100)
                ]
            )
        ]
    }
    
    private func generateReportSummary(
        statistics: WorkflowStatistics,
        metrics: WorkflowPerformanceMetrics
    ) -> ReportSummary {
        
        let completionPercentage = Int(statistics.completionRate * 100)
        let efficiencyPercentage = Int(metrics.efficiencyScore * 100)
        
        var summaryText = "工作流程当前完成度为\(completionPercentage)%"
        
        if statistics.riskLevel != .none {
            summaryText += "，存在\(statistics.riskLevel.rawValue)风险"
        }
        
        summaryText += "。执行效率为\(efficiencyPercentage)%"
        
        if let prediction = statistics.predictedCompletion {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM月dd日"
            summaryText += "，预计完成时间为\(formatter.string(from: prediction))"
        }
        
        let keyMetrics: [String: Double] = [
            "completion_rate": statistics.completionRate,
            "efficiency": metrics.efficiencyScore,
            "satisfaction": metrics.userSatisfactionScore
        ]
        
        return ReportSummary(
            overallStatus: determineOverallStatus(statistics: statistics),
            summaryText: summaryText,
            keyMetrics: keyMetrics,
            nextActions: extractNextActions(statistics: statistics),
            criticalIssues: extractCriticalIssues(statistics: statistics)
        )
    }
    
    private func determineOverallStatus(statistics: WorkflowStatistics) -> OverallStatus {
        switch statistics.riskLevel {
        case .high:
            return .critical
        case .medium:
            return .warning
        case .low:
            return statistics.completionRate > 0.5 ? .good : .attention
        case .none:
            return statistics.completionRate > 0.7 ? .excellent : .good
        }
    }
    
    private func extractNextActions(statistics: WorkflowStatistics) -> [String] {
        var actions: [String] = []
        
        if statistics.completionRate < 0.3 {
            actions.append("加快当前步骤的执行")
        }
        
        if statistics.riskLevel != .none {
            actions.append("处理识别的风险项")
        }
        
        let activeBlockers = statistics.currentProgress.blockers.filter { !$0.isResolved }
        if !activeBlockers.isEmpty {
            actions.append("解决\(activeBlockers.count)个活跃阻塞项")
        }
        
        return actions
    }
    
    private func extractCriticalIssues(statistics: WorkflowStatistics) -> [String] {
        var issues: [String] = []
        
        let criticalBlockers = statistics.currentProgress.blockers.filter { 
            $0.severity == .critical && !$0.isResolved 
        }
        
        for blocker in criticalBlockers {
            issues.append(blocker.title)
        }
        
        let overdueMilestones = statistics.currentProgress.milestones.filter { 
            !$0.isCompleted && $0.targetDate < Date() 
        }
        
        for milestone in overdueMilestones {
            issues.append("里程碑延期: \(milestone.title)")
        }
        
        return issues
    }
    
    // MARK: - Storage Methods
    
    private func saveProgress(workflowId: String, progress: WorkflowProgress) async throws {
        try await coreDataService.saveWorkflowProgress(workflowId: workflowId, progress: progress)
    }
}

// MARK: - Supporting Types

/// 工作流程进度跟踪器
class WorkflowProgressTracker {
    let workflowId: String
    private var progress: WorkflowProgress
    private var startTime: Date
    private var stepStartTimes: [String: Date] = [:]
    private var stepCompletionTimes: [String: TimeInterval] = [:]
    
    var totalTimeSpent: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }
    
    var averageStepCompletionTime: TimeInterval {
        let completionTimes = Array(stepCompletionTimes.values)
        guard !completionTimes.isEmpty else { return 0 }
        return completionTimes.reduce(0, +) / Double(completionTimes.count)
    }
    
    var estimatedTotalTime: TimeInterval {
        // TODO: 基于历史数据和步骤复杂度估算
        return 30 * 24 * 3600 // 30天的简化估算
    }
    
    var predictedCompletionDate: Date? {
        let remainingProgress = 1.0 - progress.overallProgress
        guard remainingProgress > 0 else { return Date() }
        
        let estimatedRemainingTime = averageStepCompletionTime * Double(progress.totalSteps - progress.completedSteps)
        return Calendar.current.date(byAdding: .second, value: Int(estimatedRemainingTime), to: Date())
    }
    
    var nextReminderTime: Date?
    
    init(workflowId: String, initialProgress: WorkflowProgress) {
        self.workflowId = workflowId
        self.progress = initialProgress
        self.startTime = Date()
    }
    
    func updateProgress(_ newProgress: WorkflowProgress) async {
        // 检查新完成的步骤
        if newProgress.completedSteps > progress.completedSteps {
            let newlyCompletedSteps = newProgress.completedSteps - progress.completedSteps
            // 记录步骤完成时间
        }
        
        progress = newProgress
    }
    
    func performPeriodicUpdate() async {
        // 执行定期更新任务
        // TODO: 实现定期更新逻辑
    }
}

/// 工作流程统计信息
struct WorkflowStatistics {
    let workflowId: String
    let currentProgress: WorkflowProgress
    let totalTimeSpent: TimeInterval
    let averageStepTime: TimeInterval
    let completionRate: Double
    let efficiency: Double
    let predictedCompletion: Date?
    let riskLevel: RiskLevel
    let recommendations: [ProgressRecommendation]
}

/// 风险等级
enum RiskLevel: String, CaseIterable {
    case none = "无风险"
    case low = "低风险"
    case medium = "中风险"
    case high = "高风险"
    
    var color: Color {
        switch self {
        case .none: return .green
        case .low: return .yellow
        case .medium: return .orange
        case .high: return .red
        }
    }
}

/// 进度建议
struct ProgressRecommendation: Identifiable {
    let id: String
    let type: RecommendationType
    let title: String
    let description: String
    let priority: RecommendationPriority
    let actionItems: [String]
    
    enum RecommendationType {
        case efficiency
        case blocker
        case milestone
        case resource
        case quality
    }
    
    enum RecommendationPriority {
        case low
        case medium
        case high
        case critical
    }
}

/// 进度通知
struct ProgressNotification: Identifiable {
    let id: String
    let workflowId: String
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    let priority: NotificationPriority
    var isRead: Bool
    
    enum NotificationType {
        case trackingStarted
        case trackingStopped
        case milestoneAdded
        case milestoneCompleted
        case blockerAdded
        case blockerResolved
        case blockerDetected
        case reminder
        case phaseChanged
        case riskAlert
    }
    
    enum NotificationPriority {
        case info
        case success
        case warning
        case critical
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .success: return .green
            case .warning: return .orange
            case .critical: return .red
            }
        }
    }
}

/// 进度报告
struct ProgressReport: Identifiable {
    let id: String
    let workflowId: String
    let reportType: ProgressReportType
    let generatedAt: Date
    let statistics: WorkflowStatistics
    let metrics: WorkflowPerformanceMetrics
    let insights: [ProgressInsight]
    let recommendations: [ActionableRecommendation]
    let charts: [ProgressChart]
    let summary: ReportSummary
}

/// 进度报告类型
enum ProgressReportType: String, CaseIterable {
    case summary = "摘要报告"
    case detailed = "详细报告"
    case analytical = "分析报告"
    case executive = "执行摘要"
}

/// 进度洞察
struct ProgressInsight: Identifiable {
    let id: String
    let category: InsightCategory
    let title: String
    let description: String
    let severity: InsightSeverity
    let metrics: [String: Double]
    
    enum InsightCategory {
        case progress
        case efficiency
        case quality
        case risk
        case user
    }
    
    enum InsightSeverity {
        case positive
        case neutral
        case negative
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .neutral: return .blue
            case .negative: return .red
            }
        }
    }
}

/// 可执行建议
struct ActionableRecommendation: Identifiable {
    let id: String
    let title: String
    let description: String
    let priority: RecommendationPriority
    let category: RecommendationCategory
    let actions: [ActionItem]
    let expectedImpact: Impact
    let estimatedEffort: Effort
    
    enum RecommendationPriority {
        case low, medium, high, critical
    }
    
    enum RecommendationCategory {
        case efficiency, quality, risk, user, cost
    }
    
    enum Impact {
        case low, medium, high
    }
    
    enum Effort {
        case low, medium, high
    }
}

/// 行动项目
struct ActionItem: Identifiable {
    let id = UUID().uuidString
    let title: String
    var isCompleted: Bool
    var completedDate: Date?
}

/// 进度图表
struct ProgressChart: Identifiable {
    let id: String
    let type: ChartType
    let title: String
    let data: [ChartDataPoint]
    
    enum ChartType {
        case progress
        case efficiency
        case milestones
        case blockers
        case timeline
    }
}

/// 图表数据点
struct ChartDataPoint {
    let label: String
    let value: Double
    let timestamp: Date?
    
    init(label: String, value: Double, timestamp: Date? = nil) {
        self.label = label
        self.value = value
        self.timestamp = timestamp
    }
}

/// 报告摘要
struct ReportSummary {
    let overallStatus: OverallStatus
    let summaryText: String
    let keyMetrics: [String: Double]
    let nextActions: [String]
    let criticalIssues: [String]
}

/// 整体状态
enum OverallStatus: String {
    case excellent = "优秀"
    case good = "良好"
    case attention = "需要关注"
    case warning = "警告"
    case critical = "严重"
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .attention: return .yellow
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let workflowProgressUpdated = Notification.Name("workflowProgressUpdated")
    static let progressNotificationReceived = Notification.Name("progressNotificationReceived")
}

// MARK: - Core Data Extensions

extension CoreDataService {
    func saveWorkflow(_ workflow: EnhancedCaseWorkflow) async throws {
        // TODO: 实现工作流程的Core Data保存
    }
    
    func loadWorkflow(id: String) async throws -> EnhancedCaseWorkflow? {
        // TODO: 实现工作流程的Core Data加载
        return nil
    }
    
    func saveWorkflowProgress(workflowId: String, progress: WorkflowProgress) async throws {
        // TODO: 实现进度的Core Data保存
    }
    
    func loadAllWorkflowProgress() async throws -> [String: WorkflowProgress] {
        // TODO: 实现进度的Core Data加载
        return [:]
    }
}