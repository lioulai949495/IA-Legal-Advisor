import SwiftUI

struct NewCaseView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedCase: Case?
    @State private var showingNewCase = false
    @State private var showingAnalysis = false
    @State private var currentAnalysis: CaseAnalysis?
    @State private var sidebarVisible = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    
    var body: some View {
        ZStack {
                // 背景填充整个屏幕
                AppTheme.backgroundGradient
                    .ignoresSafeArea(.all)
                // 主内容区域
                HStack(spacing: 0) {
                    // 固定的图标边栏
                    iconSidebar
                    
                    // 右侧主内容区域
                    if let selectedCase = selectedCase {
                        CaseDetailView(
                            caseItem: selectedCase,
                            analysis: currentAnalysis,
                            onStartAnalysis: {
                                startIntelligentAnalysis(for: selectedCase)
                            }
                        )
                    } else {
                        emptyCaseView
                    }
                }
                
                // 滑出的侧边栏（覆盖在页面上层）
                if sidebarVisible {
                    HStack(spacing: 0) {
                        sidebarContent
                            .transition(.move(edge: .leading))
                        
                        // 透明遮罩区域，点击可关闭侧边栏
                        AppTheme.secondaryColor.opacity(0.2)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    sidebarVisible = false
                                }
                            }
                    }
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
        .sheet(isPresented: $showingNewCase) {
            NavigationView {
                NewCaseWizard { newCase in
                    viewModel.cases.insert(newCase, at: 0)
                    selectedCase = newCase
                    showingNewCase = false
                }
                .navigationTitle("新建案件")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("取消") {
                            showingNewCase = false
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAnalysis) {
            if let analysis = currentAnalysis {
                CaseAnalysisView(analysis: analysis) { updatedAnalysis in
                    currentAnalysis = updatedAnalysis
                }
            }
        }
        .onAppear {
            if selectedCase == nil && !viewModel.cases.isEmpty {
                selectedCase = viewModel.cases.first
            }
        }
        .alert("创建案件受限", isPresented: $showingPermissionAlert) {
            Button("升级会员") {
                viewModel.showMembershipUpgrade()
            }
            Button("单独购买") {
                viewModel.showMembershipUpgrade()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text(permissionAlertMessage)
        }
    }
    
    // MARK: - 固定图标边栏
    private var iconSidebar: some View {
        VStack(spacing: 20) {
            // 案件列表图标
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    sidebarVisible.toggle()
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                        .font(.title2)
                        .foregroundColor(sidebarVisible ? AppTheme.accentColor : .white)
                    
                    Text("案件")
                        .font(.caption2)
                        .foregroundColor(sidebarVisible ? AppTheme.accentColor : .white)
                }
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(sidebarVisible ? AppTheme.accentColor.opacity(0.2) : Color.white.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(sidebarVisible ? AppTheme.accentColor : Color.white.opacity(0.3), lineWidth: 1)
                )
            }
            
            // 分割线
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 30, height: 1)
            
            // 其他快捷功能图标
            Button {
                checkCreateCasePermission()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("新建")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
            
            Spacer()
        }
        .padding(.top, 100) // 为导航栏留出空间
        .padding(.bottom, 20)
        .frame(width: 80)
        .frame(maxHeight: .infinity)
        .background(
            Rectangle()
                .fill(AppTheme.secondaryColor.opacity(0.3))
                .background(.regularMaterial, in: Rectangle())
                .ignoresSafeArea(.all)
        )
        .overlay(
            Rectangle()
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                .ignoresSafeArea(.all)
        )
    }
    
    // MARK: - 滑出侧边栏内容
    private var sidebarContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 侧边栏标题和控制
            HStack {
                Text("我的案件")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                // 新建案件按钮
                Button {
                    checkCreateCasePermission()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("新建")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.accentColor)
                    .cornerRadius(8)
                }
                
                Text("\(viewModel.cases.count)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding()
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // 案件列表
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.cases) { caseItem in
                        FullScreenCaseListItem(
                            caseItem: caseItem,
                            isSelected: selectedCase?.id == caseItem.id
                        ) {
                            selectedCase = caseItem
                            loadAnalysisForCase(caseItem)
                        }
                    }
                    
                    // 空状态提示
                    if viewModel.cases.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("还没有案件记录")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            
                            Text("点击上方\"新建\"按钮创建你的第一个案件")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)
                    }
                }
                .padding()
            }
        }
        .frame(width: 320)
        .background(
            Rectangle()
                .fill(AppTheme.secondaryColor.opacity(0.4))
                .background(.regularMaterial, in: Rectangle())
        )
        .overlay(
            Rectangle()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .blur(radius: 0.5)
        )
    }
    
    // MARK: - 空状态视图
    private var emptyCaseView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.6))
            
            Text("选择一个案件查看详情")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("点击左侧图标栏中的\"案件\"查看案件列表，或点击\"新建\"创建新案件")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button("创建新案件") {
                checkCreateCasePermission()
            }
            .primaryButtonStyle()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .padding()
    }
    
    // 加载案件分析
    private func loadAnalysisForCase(_ caseItem: Case) {
        // 模拟加载已有的分析或创建新分析
        currentAnalysis = CaseAnalysis(
            id: UUID().uuidString,
            caseId: caseItem.id,
            analysisSteps: [],
            winProbability: nil,
            estimatedCost: nil,
            recommendedActions: [],
            requiredDocuments: [],
            timelineEstimate: nil,
            isPaid: false
        )
    }
    
    // 开始智能分析
    private func startIntelligentAnalysis(for caseItem: Case) {
        showingAnalysis = true
    }
    
    private func checkCreateCasePermission() {
        // 直接进入新建案件向导，不检查权限
        showingNewCase = true
    }
}

// MARK: - 案件列表项
struct CaseListItem: View {
    let caseItem: Case
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // 案件类型图标
                    Image(systemName: caseItem.caseType.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? AppTheme.accentColor : .white.opacity(0.7))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(caseItem.title)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(caseItem.caseType.rawValue)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // 状态指示器
                    Circle()
                        .fill(statusColor(for: caseItem.status))
                        .frame(width: 8, height: 8)
                }
                
                // 最后更新时间
                Text("最后更新: \(caseItem.formattedDate)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                
                // 进度指示器（如果有分析的话）
                if caseItem.messages.count > 1 {
                    ProgressView(value: 0.6) // 模拟进度
                        .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor))
                        .scaleEffect(y: 0.5)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.clear)
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
        case .active:
            return .green
        case .completed:
            return .blue
        case .archived:
            return .gray
        }
    }
}

// MARK: - 案件详情视图
struct CaseDetailView: View {
    let caseItem: Case
    let analysis: CaseAnalysis?
    let onStartAnalysis: () -> Void
    
    @State private var showingPayment = false
    @State private var selectedStep: ProcessStep?
    
    // 模拟案件处理流程步骤
    private var processSteps: [ProcessStep] {
        switch caseItem.caseType {
        case .laborDispute:
            return [
                ProcessStep(id: "1", title: "案件接收", description: "收集基本信息和相关材料", status: .completed, date: Date().addingTimeInterval(-86400 * 7)),
                ProcessStep(id: "2", title: "初步分析", description: "分析案件性质和胜诉可能性", status: .completed, date: Date().addingTimeInterval(-86400 * 5)),
                ProcessStep(id: "3", title: "证据整理", description: "整理和完善相关证据材料", status: .inProgress, date: Date().addingTimeInterval(-86400 * 2)),
                ProcessStep(id: "4", title: "法律研究", description: "研究相关法律条文和判例", status: .pending, date: nil),
                ProcessStep(id: "5", title: "和解协商", description: "尝试与对方进行和解协商", status: .pending, date: nil),
                ProcessStep(id: "6", title: "起草文书", description: "准备诉讼相关法律文书", status: .pending, date: nil),
                ProcessStep(id: "7", title: "案件结案", description: "完成诉讼程序并结案", status: .pending, date: nil)
            ]
        default:
            return [
                ProcessStep(id: "1", title: "案件接收", description: "收集基本信息和相关材料", status: .completed, date: Date().addingTimeInterval(-86400 * 3)),
                ProcessStep(id: "2", title: "初步分析", description: "分析案件性质和法律依据", status: .inProgress, date: Date().addingTimeInterval(-86400 * 1)),
                ProcessStep(id: "3", title: "方案制定", description: "制定详细的解决方案", status: .pending, date: nil),
                ProcessStep(id: "4", title: "执行实施", description: "按照方案执行相关程序", status: .pending, date: nil),
                ProcessStep(id: "5", title: "案件结案", description: "完成所有程序并结案", status: .pending, date: nil)
            ]
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 案件信息头部
            caseHeader
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // 处理流程区域
            ScrollView {
                VStack(spacing: 20) {
                    // 进度概览卡片
                    progressOverviewCard
                    
                    // 处理流程时间线
                    processTimelineView
                    
                    // 下一步建议
                    nextStepSuggestionCard
                }
                .padding()
            }
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .sheet(isPresented: $showingPayment) {
            PaymentView(
                title: "解锁详细分析报告",
                description: "获取完整的案件分析、胜诉概率评估和详细建议",
                price: 29.9
            )
        }
    }
    
    // MARK: - 案件信息头部
    private var caseHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(caseItem.title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    HStack {
                        Label(caseItem.caseType.rawValue, systemImage: caseItem.caseType.icon)
                        Spacer()
                        CaseStatusBadge(status: caseItem.status)
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            Text(caseItem.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
    }
    
    // MARK: - 进度概览卡片
    private var progressOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("案件进度概览")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                Spacer()
            }
            
            let completedSteps = processSteps.filter { $0.status == .completed }.count
            let totalSteps = processSteps.count
            let progress = Double(completedSteps) / Double(totalSteps)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("整体进度")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(completedSteps)/\(totalSteps) 已完成")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.accentColor)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor))
                    .scaleEffect(y: 1.5)
                
                HStack {
                    HStack(spacing: 4) {
                        Circle().fill(.green).frame(width: 8, height: 8)
                        Text("已完成: \(completedSteps)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    HStack(spacing: 4) {
                        Circle().fill(.orange).frame(width: 8, height: 8)
                        Text("进行中: \(processSteps.filter { $0.status == .inProgress }.count)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    HStack(spacing: 4) {
                        Circle().fill(.gray).frame(width: 8, height: 8)
                        Text("待处理: \(processSteps.filter { $0.status == .pending }.count)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .liquidGlass()
    }
    
    // MARK: - 处理流程时间线
    private var processTimelineView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "timeline.selection")
                    .foregroundColor(.blue)
                Text("处理流程")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                Spacer()
            }
            
            VStack(spacing: 0) {
                ForEach(Array(processSteps.enumerated()), id: \.element.id) { index, step in
                    ProcessStepRow(
                        step: step,
                        isLast: index == processSteps.count - 1
                    )
                }
            }
        }
        .padding()
        .liquidGlass()
    }
    
    // MARK: - 下一步建议卡片
    private var nextStepSuggestionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("下一步建议")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                Spacer()
            }
            
            if let currentStep = processSteps.first(where: { $0.status == .inProgress }) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("当前正在进行: \(currentStep.title)")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.accentColor)
                    
                    Text(getSuggestionForStep(currentStep))
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Button("查看详细指导") {
                        showingPayment = true
                    }
                    .primaryButtonStyle()
                }
            } else if let nextStep = processSteps.first(where: { $0.status == .pending }) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("即将开始: \(nextStep.title)")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.accentColor)
                    
                    Text(getSuggestionForStep(nextStep))
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Button("获取专业指导") {
                        showingPayment = true
                    }
                    .primaryButtonStyle()
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("所有流程已完成")
                        .font(.subheadline.bold())
                        .foregroundColor(.green)
                    
                    Text("恭喜！您的案件已成功处理完毕。如需后续服务或有其他法律问题，请随时联系我们。")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private func getSuggestionForStep(_ step: ProcessStep) -> String {
        switch step.id {
        case "1":
            return "请确保收集所有相关的证据材料，包括合同、协议、通信记录等。完整的材料有助于案件的顺利进行。"
        case "2":
            return "我们正在深入分析您的案件，评估法律依据和胜诉可能性。这个阶段需要1-2个工作日。"
        case "3":
            return "正在整理和完善证据材料，确保所有文件符合法律要求。如有需要，我们会联系您补充材料。"
        case "4":
            return "我们将研究相关的法律条文和类似案例，为您的案件制定最佳策略。"
        case "5":
            return "尝试与对方进行和解协商，这通常是最经济高效的解决方案。"
        default:
            return "我们会根据案件具体情况，为您制定最适合的处理方案。"
        }
    }
    
}

// MARK: - 处理步骤数据模型
struct ProcessStep: Identifiable {
    let id: String
    let title: String
    let description: String
    let status: ProcessStatus
    let date: Date?
}

enum ProcessStatus {
    case completed
    case inProgress
    case pending
    
    var color: Color {
        switch self {
        case .completed: return .green
        case .inProgress: return .orange
        case .pending: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .completed: return "checkmark.circle.fill"
        case .inProgress: return "clock.fill"
        case .pending: return "circle"
        }
    }
}

// MARK: - 处理步骤行组件
struct ProcessStepRow: View {
    let step: ProcessStep
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 左侧时间线
            VStack(spacing: 0) {
                // 状态图标
                Image(systemName: step.status.icon)
                    .font(.title3)
                    .foregroundColor(step.status.color)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(step.status.color.opacity(0.2))
                            .frame(width: 32, height: 32)
                    )
                
                // 连接线
                if !isLast {
                    Rectangle()
                        .fill(step.status == .completed ? step.status.color : Color.white.opacity(0.3))
                        .frame(width: 2, height: 40)
                        .padding(.top, 4)
                }
            }
            
            // 右侧内容
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(step.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if let date = step.date {
                        Text(formatDate(date))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Text(step.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                
                // 状态标签
                HStack {
                    Text(statusText(for: step.status))
                        .font(.caption.bold())
                        .foregroundColor(step.status.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(step.status.color.opacity(0.2))
                        )
                    
                    Spacer()
                }
            }
            .padding(.bottom, isLast ? 0 : 16)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    private func statusText(for status: ProcessStatus) -> String {
        switch status {
        case .completed: return "已完成"
        case .inProgress: return "进行中"
        case .pending: return "待处理"
        }
    }
}

// MARK: - 状态徽章
struct CaseStatusBadge: View {
    let status: CaseStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.3))
            .cornerRadius(8)
            .foregroundColor(statusColor)
    }
    
    private var statusColor: Color {
        switch status {
        case .active:
            return .green
        case .completed:
            return .blue
        case .archived:
            return .gray
        }
    }
}

// MARK: - 全屏案件列表项
struct FullScreenCaseListItem: View {
    let caseItem: Case
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // 案件类型图标
                    Image(systemName: caseItem.caseType.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? AppTheme.accentColor : .white.opacity(0.7))
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(caseItem.title)
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text(caseItem.caseType.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // 状态指示器
                    VStack(alignment: .trailing, spacing: 4) {
                        CaseStatusBadge(status: caseItem.status)
                        
                        Circle()
                            .fill(statusColor(for: caseItem.status))
                            .frame(width: 10, height: 10)
                    }
                }
                
                // 案件描述预览
                Text(caseItem.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    // 消息数量
                    HStack(spacing: 4) {
                        Image(systemName: "message.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("\(caseItem.messages.count) 条对话")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // 最后更新时间
                    Text("最后更新: \(caseItem.formattedDate)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                // 进度指示器（如果有分析的话）
                if caseItem.messages.count > 1 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("分析进度")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                        
                        ProgressView(value: 0.6) // 模拟进度
                            .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor))
                            .scaleEffect(y: 0.8)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppTheme.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statusColor(for status: CaseStatus) -> Color {
        switch status {
        case .active:
            return .green
        case .completed:
            return .blue
        case .archived:
            return .gray
        }
    }
}

// MARK: - Missing Views

struct CaseAnalysisView: View {
    let analysis: CaseAnalysis
    let onUpdate: (CaseAnalysis) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingPaid = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 分析概览
                    VStack(alignment: .leading, spacing: 16) {
                        Text("分析概览")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        if let winProbability = analysis.winProbability {
                            HStack {
                                Text("胜诉概率")
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(Int(winProbability * 100))%")
                                    .font(.headline)
                                    .foregroundColor(winProbability > 0.7 ? .green : winProbability > 0.4 ? .orange : .red)
                            }
                            .padding()
                            .liquidGlass()
                        }
                        
                        if let timelineEstimate = analysis.timelineEstimate {
                            HStack {
                                Text("预估时间")
                                    .foregroundColor(.white)
                                Spacer()
                                Text(timelineEstimate)
                                    .font(.headline)
                                    .foregroundColor(AppTheme.accentColor)
                            }
                            .padding()
                            .liquidGlass()
                        }
                    }
                    
                    // 建议行动
                    if !analysis.recommendedActions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("建议行动")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            ForEach(analysis.recommendedActions.indices, id: \.self) { index in
                                Text("• \(analysis.recommendedActions[index])")
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding()
                                    .liquidGlass()
                            }
                        }
                    }
                    
                    // 所需文档
                    if !analysis.requiredDocuments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("所需文档")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            ForEach(analysis.requiredDocuments.indices, id: \.self) { index in
                                Text("• \(analysis.requiredDocuments[index])")
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding()
                                    .liquidGlass()
                            }
                        }
                    }
                    
                    if !analysis.isPaid {
                        Button {
                            showingPaid = true
                        } label: {
                            Text("解锁完整分析报告")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.accentColor)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("案件分析")
            .navigationBarTitleDisplayMode(.inline)
            // 移除导航栏“完成”按钮，避免与新建案件流程冲突
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
        }
    }
}

struct PaymentView: View {
    let title: String
    let description: String
    let price: Double
    
    @Environment(\.dismiss) private var dismiss
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.accentColor)
                    
                    Text(title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    Text("价格")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("¥\(price, specifier: "%.1f")")
                        .font(.largeTitle.bold())
                        .foregroundColor(AppTheme.accentColor)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button {
                        isProcessing = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isProcessing = false
                            dismiss()
                        }
                    } label: {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("立即支付")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.accentColor)
                    .cornerRadius(12)
                    .disabled(isProcessing)
                    
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding()
            .navigationTitle("支付")
            .navigationBarTitleDisplayMode(.inline)
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
        }
    }
}

#Preview {
    NewCaseView()
        .environmentObject(AppViewModel())
}