import SwiftUI
import Combine

struct CaseView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @StateObject private var workflowService = CaseWorkflowService()
    @StateObject private var documentService = CaseDocumentService.shared
    @State private var showingNewCaseSheet = false
    @State private var showingCasesList = false
    @State private var selectedWorkflowStep: EnhancedWorkflowStep?
    @State private var showingStepDetail = false
    @State private var showingDocumentsList = false
    @State private var showingUploadSheet = false
    @State private var selectedTab = 0 // 0: 工作流程, 1: 案件文书
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            topNavigationBar
            
            // 主内容区域
            mainContent
        }
        .background(AppTheme.backgroundGradient)
        .onAppear {
            // 初始化工作流程服务
            if let selectedCase = viewModel.selectedCase {
                workflowService.currentWorkflow = workflowService.generateWorkflow(for: selectedCase.caseType)
            }
        }
        .onChange(of: viewModel.selectedCase) { newCase in
            // 切换案件时更新工作流程
            if let caseItem = newCase {
                workflowService.currentWorkflow = workflowService.generateWorkflow(for: caseItem.caseType)
            }
        }
        .sheet(isPresented: $showingNewCaseSheet) {
            NewCaseWizard { newCase in
                viewModel.cases.insert(newCase, at: 0)
                viewModel.selectedCase = newCase
                showingNewCaseSheet = false
            }
        }
        .sheet(isPresented: $showingCasesList) {
            CasesListSheet(showingCasesList: $showingCasesList)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingDocumentsList) {
            if let selectedCase = viewModel.selectedCase {
                CaseDocumentListView(caseId: selectedCase.id, caseName: selectedCase.title)
            }
        }
        .sheet(isPresented: $showingUploadSheet) {
            if let selectedCase = viewModel.selectedCase {
                DocumentUploadSheet(caseId: selectedCase.id)
            }
        }
    }
    
    // 顶部导航栏
    private var topNavigationBar: some View {
        VStack(spacing: 0) {
            // 状态栏占位
            Color.clear
                .frame(height: 44)
            
            // 导航栏内容
            HStack {
                // 左侧 - 案件列表按钮（加长）
                Button {
                    showingCasesList = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 16))
                        Text("案件")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                    )
                }
                
                Spacer(minLength: 16)
                
                // 右侧 - 新建按钮（加长）
                Button {
                    showingNewCaseSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                        Text("新建")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(AppTheme.accentColor)
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                Color.black.opacity(0.2)
            )
        }
    }
    
    // 主内容区域
    private var mainContent: some View {
        VStack(spacing: 0) {
            if let selectedCase = viewModel.selectedCase {
                // 标签页切换
                tabSwitcher
                
                // 内容区域
                TabView(selection: $selectedTab) {
                    // 工作流程页面
                    workflowView(for: selectedCase)
                        .tag(0)
                    
                    // 案件文书页面
                    caseDocumentsView(for: selectedCase)
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            } else {
                emptyCaseView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // 案件工作流程视图
    private func workflowView(for caseItem: Case) -> some View {
        VStack(spacing: 0) {
            // 案件基本信息卡片
            caseInfoCard(for: caseItem)
            
            // 工作流程时间线
            workflowTimelineScrollView(for: caseItem)
        }
    }

    // 案件信息卡片
    private func caseInfoCard(for caseItem: Case) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 案件基本信息
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(caseItem.title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Label(caseItem.caseType.rawValue, systemImage: caseItem.caseType.icon)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        // 状态徽章
                        Text(caseItem.status.rawValue)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor(for: caseItem.status).opacity(0.3))
                            .cornerRadius(8)
                            .foregroundColor(statusColor(for: caseItem.status))
                    }
                }
                
                Spacer()
                
                // 进度环形图
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 5)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: getProgressPercentage(for: caseItem))
                            .stroke(AppTheme.accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.8), value: getProgressPercentage(for: caseItem))
                        
                        Text("\(Int(getProgressPercentage(for: caseItem) * 100))%")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                    }
                    
                    Text("完成度")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // 案件描述
            Text(caseItem.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            // 工作流程统计
            let stats = getWorkflowStats(for: caseItem)
            HStack(spacing: 20) {
                StatItem(title: "已完成", value: "\(stats.completed)", color: .green)
                StatItem(title: "进行中", value: "\(stats.inProgress)", color: .orange)
                StatItem(title: "待处理", value: "\(stats.pending)", color: .gray)
                StatItem(title: "总步骤", value: "\(stats.total)", color: .blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .padding(.top)
    }

    // 工作流程时间线滚动视图
    private func workflowTimelineScrollView(for caseItem: Case) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(getEnhancedWorkflowSteps(for: caseItem), id: \.id) { step in
                    InteractiveWorkflowStepView(
                        step: step,
                        onTap: {
                            selectedWorkflowStep = step
                            showingStepDetail = true
                        }
                    )
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingStepDetail) {
            if let selectedStep = selectedWorkflowStep {
                WorkflowStepDetailView(
                    step: selectedStep,
                    onUpdateStep: { updatedStep in
                        updateWorkflowStep(updatedStep, for: caseItem)
                    }
                )
            }
        }
    }

    
    // 空案件视图
    private var emptyCaseView: some View {
        VStack {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 70))
                .foregroundColor(.white.opacity(0.5))
            
            Text("请选择一个案件或创建新案件")
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
                .padding()
            
            Button {
                showingNewCaseSheet = true
            } label: {
                Text("新建案件")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppTheme.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // 获取案件进度百分比
    private func getProgressPercentage(for caseItem: Case) -> Double {
        let steps = getEnhancedWorkflowSteps(for: caseItem)
        let completedSteps = steps.filter { $0.status == .completed }.count
        return Double(completedSteps) / Double(steps.count)
    }
    
    // 获取增强的工作流程步骤
    private func getEnhancedWorkflowSteps(for caseItem: Case) -> [EnhancedWorkflowStep] {
        return workflowService.generateWorkflow(for: caseItem.caseType)
    }
    
    // 更新工作流程步骤
    private func updateWorkflowStep(_ updatedStep: EnhancedWorkflowStep, for caseItem: Case) {
        if let index = workflowService.currentWorkflow.firstIndex(where: { $0.id == updatedStep.id }) {
            workflowService.currentWorkflow[index] = updatedStep
        }
    }
    
    // 推进工作流程
    private func advanceWorkflow(for caseItem: Case) {
        // 找到当前进行中的步骤，将其标记为完成
        // 并推进到下一个步骤
        // 这里可以添加实际的状态更新逻辑
        
        // 暂时模拟推进流程的效果
        // 在实际应用中，这里会调用API更新后端状态
        print("推进案件 \(caseItem.title) 的工作流程")
    }
    
    // 显示案件详情
    private func showCaseDetails(for caseItem: Case) {
        // 显示案件的详细信息，包括文档、证据等
        // 可以通过Sheet或NavigationLink跳转到详情页面
        print("显示案件详情: \(caseItem.title)")
    }
    
    // 获取工作流程总体统计
    private func getWorkflowStats(for caseItem: Case) -> (completed: Int, inProgress: Int, pending: Int, total: Int) {
        let steps = getEnhancedWorkflowSteps(for: caseItem)
        let completed = steps.filter { $0.status == .completed }.count
        let inProgress = steps.filter { $0.status == .inProgress }.count
        let pending = steps.filter { $0.status == .pending }.count
        return (completed: completed, inProgress: inProgress, pending: pending, total: steps.count)
    }
    
    // 获取状态颜色
    private func statusColor(for status: CaseStatus) -> Color {
        switch status {
        case .active: return .green
        case .completed: return .blue
        case .archived: return .gray
        }
    }

// 案件列表项视图
struct CaseListItemView: View {
    let caseItem: Case
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                // 左侧图标
                Image(systemName: caseItem.caseType.icon)
                    .foregroundColor(isSelected ? AppTheme.accentColor : .white.opacity(0.7))
                    .font(.system(size: 24))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isSelected ? AppTheme.accentColor.opacity(0.2) : Color.white.opacity(0.1))
                    )
                
                // 右侧内容
                VStack(alignment: .leading, spacing: 4) {
                    Text(caseItem.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(caseItem.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Text(caseItem.formattedDate)
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(caseItem.status.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(statusColor(for: caseItem.status).opacity(0.2))
                            )
                            .foregroundColor(statusColor(for: caseItem.status))
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.1) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.accentColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statusColor(for status: CaseStatus) -> Color {
        switch status {
        case .active: return .green
        case .completed: return .blue
        case .archived: return .gray
        }
    }
}

// 案件列表Sheet
struct CasesListSheet: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Binding var showingCasesList: Bool
    @State private var showingNewCaseSheet = false
    @State private var caseToDelete: Case? = nil
    @State private var showingDeleteConfirm = false
    @StateObject private var docService = CaseDocumentService.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部统计信息
                casesStatsView
                
                // 案件列表
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.cases) { caseItem in
                            CaseListItemView(
                                caseItem: caseItem,
                                isSelected: viewModel.selectedCase?.id == caseItem.id
                            ) {
                                viewModel.selectCase(caseItem)
                                showingCasesList = false
                            }
                            .contextMenu {
                                Button("打开") {
                                    viewModel.selectCase(caseItem)
                                    showingCasesList = false
                                }
                                Button("删除案件", role: .destructive) {
                                    caseToDelete = caseItem
                                    showingDeleteConfirm = true
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                // 如果没有案件，显示空状态
                if viewModel.cases.isEmpty {
                    emptyCasesView
                }
            }
            .navigationTitle("案件列表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showingCasesList = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewCaseSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .background(AppTheme.backgroundGradient)
            .confirmationDialog(
                "确认删除该案件？\n删除后将同时移除本地已保存的文书与图片，且无法恢复。",
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("确认删除", role: .destructive) { performDelete() }
                Button("取消", role: .cancel) { caseToDelete = nil }
            }
        }
        .sheet(isPresented: $showingNewCaseSheet) {
            NewCaseWizard { newCase in
                viewModel.cases.insert(newCase, at: 0)
                viewModel.selectedCase = newCase
                showingNewCaseSheet = false
                showingCasesList = false
            }
        }
    }
    
    private func performDelete() {
        guard let item = caseToDelete else { return }
        let caseId = item.id
        // 本地文书清理
        docService.clearCaseDocuments(caseId)
        // 前端列表移除
        viewModel.cases.removeAll { $0.id == caseId }
        if viewModel.selectedCase?.id == caseId {
            viewModel.selectedCase = viewModel.cases.first
        }
        // 后端删除（若未实现则忽略错误）
        Task { try? await APIService.shared.deleteCase(id: caseId) }
        // 收尾
        caseToDelete = nil
    }
    // 案件统计视图
    private var casesStatsView: some View {
        HStack(spacing: 20) {
            VStack {
                Text("\(viewModel.cases.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.accentColor)
                Text("总案件")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack {
                Text("\(viewModel.cases.filter { $0.status == .active }.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                Text("进行中")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack {
                Text("\(viewModel.cases.filter { $0.status == .completed }.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Text("已完成")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal)
        .padding(.top)
    }
    
    // 空案件视图
    private var emptyCasesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("暂无案件")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text("点击右上角的 + 按钮创建第一个案件")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showingNewCaseSheet = true
            } label: {
                Text("创建案件")
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppTheme.accentColor)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// 工作流程步骤数据模型 - 保留以兼容旧代码
// 新的可交互工作流程步骤组件
struct InteractiveWorkflowStepView: View {
    let step: EnhancedWorkflowStep
    let onTap: () -> Void
    
    @State private var buttonPressed = false
    @State private var showingDocumentPreview: RequiredDocument?
    
    var body: some View {
        VStack(spacing: 0) {
            // 主要步骤内容
            Button(action: onTap) {
                HStack(alignment: .top, spacing: 16) {
                    // 左侧状态指示器
                    VStack(spacing: 8) {
                        // 状态图标
                        ZStack {
                            Circle()
                                .fill(step.status.color.opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: step.stepType.icon)
                                .font(.title3)
                                .foregroundColor(step.stepType.color)
                        }
                        
                        // 连接线（如果不是最后一个）
                        Rectangle()
                            .fill(step.status == .completed ? step.status.color : Color.white.opacity(0.3))
                            .frame(width: 2, height: 60)
                    }
                    
                    // 右侧内容
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.title)
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                                
                                Text(step.description)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            // 状态和时间信息
                            VStack(alignment: .trailing, spacing: 4) {
                                // 状态标签
                                Text(step.status.displayName)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(step.status.color.opacity(0.3))
                                    .cornerRadius(8)
                                    .foregroundColor(step.status.color)
                                
                                // 完成日期或预估时间
                                if let date = step.date {
                                    Text(formatDate(date))
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.6))
                                } else {
                                    Text("预计 \(step.estimatedDays) 天")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        
                        // 交互指示器
                        HStack(spacing: 8) {
                            if step.isInteractive {
                                Image(systemName: "hand.tap")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.accentColor)
                                
                                Text("点击与 AI 交互")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.accentColor)
                            } else {
                                Image(systemName: "info.circle")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Text("点击查看详情")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            // 文档数量指示
                            if !step.requiredDocuments.isEmpty {
                                Image(systemName: "doc.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text("\(step.requiredDocuments.count)份文档")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            // 法律提醒指示
                            if !step.legalNotices.isEmpty {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text("\(step.legalNotices.count)项提醒")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        // 进度条（仅对进行中的步骤显示）
                        if step.status == .inProgress {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("进度")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                    Spacer()
                                    Text("65%")
                                        .font(.caption.bold())
                                        .foregroundColor(step.status.color)
                                }
                                
                                ProgressView(value: 0.65)
                                    .progressViewStyle(LinearProgressViewStyle(tint: step.status.color))
                                    .scaleEffect(y: 1.2)
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(step.isInteractive ? Color.white.opacity(0.12) : Color.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            step.status == .inProgress ? step.status.color : 
                            (step.isInteractive ? AppTheme.accentColor.opacity(0.5) : Color.white.opacity(0.2)),
                            lineWidth: step.status == .inProgress ? 2 : (step.isInteractive ? 1.5 : 0.5)
                        )
                )
                // 添加微妙的阴影效果
                .shadow(
                    color: step.isInteractive ? AppTheme.accentColor.opacity(0.1) : Color.clear,
                    radius: step.isInteractive ? 4 : 0,
                    x: 0, y: 2
                )
                // 添加点击反馈效果
                .scaleEffect(buttonPressed ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: buttonPressed)
            }
            .buttonStyle(PlainButtonStyle())
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, perform: {}, onPressingChanged: { pressing in
                buttonPressed = pressing
            })
            
            // 文档区域 - 直接显示在步骤下方
            if !step.requiredDocuments.isEmpty {
                VStack(spacing: 0) {
                    // 视觉分隔区域
                    VStack(spacing: 12) {
                        // 分隔线和标题
                        HStack {
                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [Color.clear, Color.white.opacity(0.3), Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(height: 1)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "doc.fill")
                                    .font(.caption2)
                                    .foregroundColor(.blue.opacity(0.8))
                                
                                Text("相关文档")
                                    .font(.caption.bold())
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.3))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                    )
                            )
                            
                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [Color.clear, Color.white.opacity(0.3), Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(height: 1)
                        }
                        .padding(.top, 16)
                        
                        // 文档列表
                        VStack(spacing: 8) {
                            ForEach(step.requiredDocuments, id: \.id) { document in
                                CompactDocumentCard(
                                    document: document,
                                    onPreview: {
                                        showingDocumentPreview = document
                                    },
                                    onDownload: {
                                        handleDocumentDownload(document)
                                    },
                                    onShare: {
                                        handleDocumentShare(document)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    
                    // 底部装饰线
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [Color.clear, Color.white.opacity(0.1), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 0.5)
                        .padding(.horizontal, 32)
                }
                // 文档区域背景
                .background(
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.black.opacity(0.1))
                        .blur(radius: 1)
                )
            }
        }
        .sheet(item: $showingDocumentPreview) { document in
            DocumentPreviewView(document: document)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func handleDocumentDownload(_ document: RequiredDocument) {
        // 处理文档下载
        print("下载文档: \(document.name)")
        
        // 模拟下载过程
        if let template = document.template {
            // 下载模板文件
            downloadFile(name: template.name, url: template.downloadUrl)
        } else {
            // 提示用户无可下载内容
            showAlert(title: "提示", message: "此文档暂无可下载的模板")
        }
    }
    
    private func handleDocumentShare(_ document: RequiredDocument) {
        // 处理文档分享
        print("分享文档: \(document.name)")
        
        // 创建分享内容
        var shareItems: [Any] = []
        shareItems.append("文档名称: \(document.name)")
        shareItems.append("描述: \(document.description)")
        
        if let template = document.template, let url = template.downloadUrl {
            shareItems.append("下载链接: \(url)")
        }
        
        // 显示分享界面
        showShareSheet(items: shareItems)
    }
    
    private func downloadFile(name: String, url: String?) {
        // 实际的文件下载逻辑
        guard let urlString = url, let downloadUrl = URL(string: urlString) else {
            showAlert(title: "下载失败", message: "无效的下载链接")
            return
        }
        
        // 这里可以实现实际的下载逻辑
        // 例如使用 URLSession 下载文件
        print("开始下载文件: \(name) from \(downloadUrl)")
    }
    
    private func showAlert(title: String, message: String) {
        // 显示警告对话框
        // 在实际实现中，可以使用 UIKit 的 UIAlertController
        // 或者使用 SwiftUI 的 .alert() modifier
        print("Alert: \(title) - \(message)")
    }
    
    private func showShareSheet(items: [Any]) {
        // 显示系统分享界面
        // 在实际实现中，可以使用 UIActivityViewController
        print("分享内容: \(items)")
    }
}

// WorkflowStepStatus is now defined in CaseWorkflowModels.swift

// 增强的可视化修饰符已定义在 CommonComponents.swift 中

// 工作流程步骤视图组件
struct WorkflowStepView: View {
    let step: WorkflowStep
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 左侧状态指示器
            VStack(spacing: 8) {
                // 状态图标
                ZStack {
                    Circle()
                        .fill(step.status.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: step.status.icon)
                        .font(.title3)
                        .foregroundColor(step.status.color)
                }
                
                // 连接线（如果不是最后一个）
                Rectangle()
                    .fill(step.status == .completed ? step.status.color : Color.white.opacity(0.3))
                    .frame(width: 2, height: 60)
            }
            
            // 右侧内容
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        
                        Text(step.description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    // 状态和时间信息
                    VStack(alignment: .trailing, spacing: 4) {
                        // 状态标签
                        Text(step.status.displayName)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(step.status.color.opacity(0.3))
                            .cornerRadius(8)
                            .foregroundColor(step.status.color)
                        
                        // 完成日期或预估时间
                        if let date = step.date {
                            Text(formatDate(date))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        } else {
                            Text("预计 \(step.estimatedDays) 天")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                // 进度条（仅对进行中的步骤显示）
                if step.status == .inProgress {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("进度")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("65%")
                                .font(.caption.bold())
                                .foregroundColor(step.status.color)
                        }
                        
                        ProgressView(value: 0.65)
                            .progressViewStyle(LinearProgressViewStyle(tint: step.status.color))
                            .scaleEffect(y: 1.2)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(step.status == .inProgress ? step.status.color : Color.clear, lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

// 统计项组件
struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

/// 紧凑版文档卡片组件 - 用于在工作流步骤中显示
struct CompactDocumentCard: View {
    let document: RequiredDocument
    let onPreview: () -> Void
    let onDownload: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 文档图标
            Image(systemName: getDocumentIcon())
                .font(.title3)
                .foregroundColor(getDocumentColor())
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(getDocumentColor().opacity(0.2))
                )
            
            // 文档信息
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(document.name)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if document.isRequired {
                        Text("必需")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.red.opacity(0.3)))
                    }
                }
                
                Text(document.description)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 操作按钮
            HStack(spacing: 8) {
                if document.template != nil {
                    Button(action: onDownload) {
                        Image(systemName: "arrow.down.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                if document.sampleDocument != nil {
                    Button(action: onPreview) {
                        Image(systemName: "eye.circle")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up.circle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                )
        )
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 2,
            x: 0,
            y: 1
        )
    }
    
    private func getDocumentIcon() -> String {
        if document.template != nil {
            return "doc.badge.gearshape"
        } else if document.sampleDocument != nil {
            return "doc.text.magnifyingglass"
        } else {
            return "doc"
        }
    }
    
    private func getDocumentColor() -> Color {
        if document.template != nil {
            return .blue
        } else if document.sampleDocument != nil {
            return .green
        } else {
            return .gray
        }
    }
}

    // MARK: - 标签页切换器
    private var tabSwitcher: some View {
        HStack(spacing: 0) {
            // 工作流程标签
            tabButton(
                title: "工作流程",
                icon: "timeline.selection",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            // 案件文书标签
            tabButton(
                title: "案件文书",
                icon: "doc.on.doc.fill",
                count: documentService.getDocumentStats(for: viewModel.selectedCase?.id ?? "").totalCount,
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(Color.clear)
    }
    
    // 标签按钮
    private func tabButton(
        title: String,
        icon: String,
        count: Int? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.subheadline.bold())
                    
                    Text(title)
                        .font(.subheadline.bold())
                    
                    if let count = count, count > 0 {
                        Text("\(count)")
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isSelected ? Color.white.opacity(0.3) : AppTheme.accentColor)
                            .cornerRadius(10)
                    }
                }
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                
                // 底部指示条
                Rectangle()
                    .fill(isSelected ? AppTheme.accentColor : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 案件文书视图
    private func caseDocumentsView(for caseItem: Case) -> some View {
        VStack(spacing: 0) {
            // 文书统计卡片
            documentStatsCard(for: caseItem)
                .padding(.horizontal)
                .padding(.top)
            
            // 文书快速预览
            documentQuickPreview(for: caseItem)
        }
    }
    
    // 文书统计卡片
    private func documentStatsCard(for caseItem: Case) -> some View {
        let stats = documentService.getDocumentStats(for: caseItem.id)
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("文书管理")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("查看全部") {
                    showingDocumentsList = true
                }
                .font(.subheadline.bold())
                .foregroundColor(AppTheme.accentColor)
            }
            
            // 统计数据
            HStack(spacing: 16) {
                DocumentStatItem(
                    title: "总文档",
                    count: stats.totalCount,
                    icon: "doc.fill",
                    color: .blue
                )
                
                DocumentStatItem(
                    title: "上传文件",
                    count: stats.uploadedCount,
                    icon: "arrow.up.doc",
                    color: .green
                )
                
                DocumentStatItem(
                    title: "生成文书",
                    count: stats.generatedCount,
                    icon: "doc.richtext",
                    color: .orange
                )
                
                DocumentStatItem(
                    title: "分析报告",
                    count: stats.analysisCount,
                    icon: "chart.bar.doc.horizontal",
                    color: .purple
                )
            }
            
            if stats.totalCount > 0 {
                HStack {
                    Text("总大小：\(ByteCountFormatter.string(fromByteCount: stats.totalSize, countStyle: .file))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    if let lastUpdated = stats.lastUpdated {
                        Text("更新：\(RelativeDateTimeFormatter().localizedString(for: lastUpdated, relativeTo: Date()))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .padding()
        .liquidGlass()
    }
    
    // 文书快速预览
    private func documentQuickPreview(for caseItem: Case) -> some View {
        let documents = documentService.getDocuments(for: caseItem.id)
        let recentDocuments = Array(documents.sorted { $0.updatedAt > $1.updatedAt }.prefix(3))
        
        return VStack(alignment: .leading, spacing: 16) {
            if recentDocuments.isEmpty {
                // 空状态
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.below.ecg")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("暂无文档")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    
                    Text("上传证据文件或让AI为您生成法律文书")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    Button("上传文档") {
                        showingUploadSheet = true
                    }
                    .primaryButtonStyle()
                    .frame(maxWidth: 200)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        // 最近文档标题
                        HStack {
                            Text("最近文档")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button("管理文书") {
                                showingDocumentsList = true
                            }
                            .font(.subheadline)
                            .foregroundColor(AppTheme.accentColor)
                        }
                        .padding(.horizontal)
                        
                        // 文档列表
                        ForEach(recentDocuments) { document in
                            DocumentPreviewCard(document: document, caseId: caseItem.id)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - 文书统计项
struct DocumentStatItem: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 文档预览卡片
struct DocumentPreviewCard: View {
    let document: CaseDocument
    let caseId: String
    @StateObject private var documentService = CaseDocumentService.shared
    
    var body: some View {
        Button {
            // TODO: 显示文档详情
        } label: {
            HStack(spacing: 12) {
                // 文档图标
                Image(systemName: document.fileIcon)
                    .font(.title2)
                    .foregroundColor(document.type.color)
                    .frame(width: 40, height: 40)
                    .background(document.type.color.opacity(0.1))
                    .cornerRadius(8)
                
                // 文档信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(document.type.rawValue)
                        .font(.caption)
                        .foregroundColor(document.type.color)
                    
                    HStack {
                        Text(document.formattedFileSize)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.4))
                        
                        Text(RelativeDateTimeFormatter().localizedString(for: document.updatedAt, relativeTo: Date()))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // 文档来源标识
                VStack(alignment: .trailing, spacing: 2) {
                    Text(document.createdBy.rawValue)
                        .font(.caption.bold())
                        .foregroundColor(document.createdBy == .ai ? .green : .blue)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding()
            .liquidGlass()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CaseView()
        .environmentObject(AppViewModel())
}