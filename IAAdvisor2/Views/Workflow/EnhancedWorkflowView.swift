import SwiftUI

/// 增强的案件流程视图
struct EnhancedWorkflowView: View {
    @StateObject private var workflowService: CaseWorkflowService
    @State private var selectedStep: EnhancedWorkflowStep?
    @State private var showingStepDetail = false
    @State private var showingCustomStepOptions = false
    @State private var showingPreservationDetail = false
    @State private var selectedStepForCustomAdd: EnhancedWorkflowStep?
    
    let caseType: CaseType
    let onWorkflowUpdate: ([EnhancedWorkflowStep]) -> Void
    
    init(caseType: CaseType, onWorkflowUpdate: @escaping ([EnhancedWorkflowStep]) -> Void) {
        self.caseType = caseType
        self.onWorkflowUpdate = onWorkflowUpdate
        self._workflowService = StateObject(wrappedValue: CaseWorkflowService())
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(workflowService.currentWorkflow.indices, id: \.self) { index in
                    let step = workflowService.currentWorkflow[index]
                    let isLast = index == workflowService.currentWorkflow.count - 1
                    
                    VStack(spacing: 0) {
                        EnhancedWorkflowStepView(
                            step: step,
                            onTap: {
                                selectedStep = step
                                showingStepDetail = true
                            },
                            onAddCustomStep: step.allowsCustomSubsteps ? {
                                selectedStepForCustomAdd = step
                                showingCustomStepOptions = true
                            } : nil
                        )
                        
                        // 连接线
                        if !isLast {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 2, height: 30)
                                .offset(x: -120) // 对齐到左侧状态指示器
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 20)
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .onAppear {
            workflowService.currentWorkflow = workflowService.generateWorkflow(for: caseType)
        }
        .sheet(isPresented: $showingStepDetail) {
            if let step = selectedStep {
                WorkflowStepDetailView(
                    step: step,
                    onUpdateStep: { updatedStep in
                        if let index = workflowService.currentWorkflow.firstIndex(where: { $0.id == updatedStep.id }) {
                            workflowService.currentWorkflow[index] = updatedStep
                            onWorkflowUpdate(workflowService.currentWorkflow)
                        }
                    }
                )
            }
        }
        .actionSheet(isPresented: $showingCustomStepOptions) {
            ActionSheet(
                title: Text("添加流程步骤"),
                message: Text("选择要添加的步骤类型"),
                buttons: [
                    .default(Text("二审")) {
                        addCustomStep(.secondTrial)
                    },
                    .default(Text("申请执行")) {
                        addCustomStep(.execution)
                    },
                    .default(Text("申请再审")) {
                        addCustomStep(.retrial)
                    },
                    .default(Text("结案")) {
                        addCustomStep(.caseClose)
                    },
                    .cancel(Text("取消"))
                ]
            )
        }
    }
    
    private func addCustomStep(_ stepType: CaseWorkflowStepType) {
        guard let selectedStep = selectedStepForCustomAdd else { return }
        workflowService.addCustomStep(after: selectedStep.id, stepType: stepType)
        onWorkflowUpdate(workflowService.currentWorkflow)
    }
}

/// 增强的流程步骤视图
struct EnhancedWorkflowStepView: View {
    let step: EnhancedWorkflowStep
    let onTap: () -> Void
    let onAddCustomStep: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 左侧状态指示器
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(step.status.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: step.stepType.icon)
                        .font(.title2)
                        .foregroundColor(step.stepType.color)
                }
                
                // 状态文本
                Text(statusText)
                    .font(.caption2)
                    .foregroundColor(step.status.color)
            }
            
            // 主要内容区域
            VStack(alignment: .leading, spacing: 12) {
                // 标题和描述
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(step.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if step.isCustomStep {
                            Text("自定义")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.orange.opacity(0.3)))
                                .foregroundColor(.orange)
                        }
                        
                        Text("\(step.estimatedDays)天")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.blue.opacity(0.3)))
                            .foregroundColor(.blue)
                    }
                    
                    Text(step.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(3)
                }
                
                // 快速操作按钮
                HStack(spacing: 12) {
                    Button("查看详情") {
                        onTap()
                    }
                    .buttonStyle(WorkflowSecondaryButtonStyle())
                    
                    if step.isInteractive {
                        Button(actionButtonText) {
                            onTap()
                        }
                        .buttonStyle(WorkflowPrimaryButtonStyle())
                    }
                    
                    if let onAddCustomStep = onAddCustomStep {
                        Button {
                            onAddCustomStep()
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                                .foregroundColor(AppTheme.accentColor)
                        }
                    }
                }
                
                // 关键信息指示器
                if !step.legalNotices.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text("\(step.legalNotices.count)项法律提醒")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Spacer()
                        
                        if !step.requiredDocuments.isEmpty {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                            
                            Text("\(step.requiredDocuments.count)份文档")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(step.status == .inProgress ? 0.15 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(step.status == .inProgress ? AppTheme.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .padding(.horizontal)
    }
    
    private var statusText: String {
        switch step.status {
        case .completed:
            return "已完成"
        case .inProgress:
            return "进行中"
        case .pending:
            return "待处理"
        }
    }
    
    private var actionButtonText: String {
        switch step.stepType {
        case .analysis:
            return "查看分析"
        case .litigation:
            return "开始诉讼"
        case .preTrialPreservation:
            return "申请保全"
        case .evidencePreparation:
            return "上传证据"
        case .judgmentAnalysis:
            return "上传判决书"
        default:
            return "开始执行"
        }
    }
}

/// 流程步骤详情视图
struct WorkflowStepDetailView: View {
    let step: EnhancedWorkflowStep
    let onUpdateStep: (EnhancedWorkflowStep) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingPreservationOptions = false
    @State private var showingEvidenceUpload = false
    @State private var showingJudgmentUpload = false
    @State private var showingDocumentPreview: RequiredDocument?
    @State private var showingNotarizationInfo = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 步骤头部
                    stepHeader
                    
                    // 操作指南
                    actionGuideSection
                    
                    // 所需文档
                    if !step.requiredDocuments.isEmpty {
                        requiredDocumentsSection
                    }
                    
                    // 法律提醒
                    if !step.legalNotices.isEmpty {
                        legalNoticesSection
                    }
                    
                    // 特殊功能区
                    specialFeaturesSection
                    
                    // 主要操作按钮
                    actionButtonsSection
                }
                .padding()
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle(step.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .sheet(item: $showingDocumentPreview) { document in
            DocumentPreviewView(document: document)
        }
        .sheet(isPresented: $showingPreservationOptions) {
            PreTrialPreservationView(step: step)
        }
        .sheet(isPresented: $showingEvidenceUpload) {
            EvidenceUploadView(step: step, onUpdate: onUpdateStep)
        }
        .sheet(isPresented: $showingJudgmentUpload) {
            JudgmentAnalysisView(step: step, onUpdate: onUpdateStep)
        }
        .sheet(isPresented: $showingNotarizationInfo) {
            NotarizationInfoView()
        }
    }
    
    // MARK: - 视图组件
    
    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: step.stepType.icon)
                    .font(.largeTitle)
                    .foregroundColor(step.stepType.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(step.title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text(step.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            HStack {
                StatusBadge(status: step.status)
                
                Spacer()
                
                DifficultyBadge(difficulty: step.actionGuide.difficulty)
                
                TimeBadge(time: step.actionGuide.estimatedTime)
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private var actionGuideSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("操作指南")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(step.actionGuide.steps, id: \.id) { actionStep in
                    ActionStepView(step: actionStep)
                }
            }
            
            // 提示和警告
            if !step.actionGuide.tips.isEmpty {
                TipsSection(tips: step.actionGuide.tips)
            }
            
            if !step.actionGuide.warnings.isEmpty {
                WarningsSection(warnings: step.actionGuide.warnings)
            }
        }
    }
    
    private var requiredDocumentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("所需文档")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(step.requiredDocuments, id: \.id) { document in
                    DocumentCard(
                        document: document,
                        onPreview: {
                            showingDocumentPreview = document
                        },
                        onDownload: {
                            // 处理下载
                        }
                    )
                }
            }
        }
    }
    
    private var legalNoticesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("法律提醒")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(step.legalNotices, id: \.id) { notice in
                    LegalNoticeCard(notice: notice)
                }
            }
        }
    }
    
    private var specialFeaturesSection: some View {
        Group {
            switch step.stepType {
            case .litigation:
                litigationSpecialFeatures
            case .preTrialPreservation:
                preservationSpecialFeatures
            case .evidencePreparation:
                evidenceSpecialFeatures
            default:
                EmptyView()
            }
        }
    }
    
    private var litigationSpecialFeatures: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("特殊选项")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Button {
                showingPreservationOptions = true
            } label: {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("考虑诉前保全")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("保护您的合法权益，防止对方转移财产")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding()
                .liquidGlass()
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var preservationSpecialFeatures: some View {
        PreservationCalculatorView()
    }
    
    private var evidenceSpecialFeatures: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("证据公证")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Button {
                showingNotarizationInfo = true
            } label: {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("了解证据公证")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("增强证据效力，提高胜诉概率")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
                .padding()
                .liquidGlass()
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            switch step.stepType {
            case .analysis:
                CaseAnalysisDetailSection()
                
            case .evidencePreparation:
                Button("上传证据材料") {
                    showingEvidenceUpload = true
                }
                .buttonStyle(WorkflowPrimaryButtonStyle())
                
            case .judgmentAnalysis:
                Button("上传判决书") {
                    showingJudgmentUpload = true
                }
                .buttonStyle(WorkflowPrimaryButtonStyle())
                
            case .litigation:
                Button("开始准备诉讼材料") {
                    // 标记步骤为进行中
                    var updatedStep = step
                    updatedStep.status = .inProgress
                    onUpdateStep(updatedStep)
                }
                .buttonStyle(WorkflowPrimaryButtonStyle())
                
            default:
                if step.isInteractive {
                    Button("开始执行") {
                        var updatedStep = step
                        updatedStep.status = .inProgress
                        onUpdateStep(updatedStep)
                    }
                    .buttonStyle(WorkflowPrimaryButtonStyle())
                }
            }
            
            if step.status != .completed {
                Button("标记为完成") {
                    var updatedStep = step
                    updatedStep.status = .completed
                    onUpdateStep(updatedStep)
                }
                .buttonStyle(WorkflowSecondaryButtonStyle())
            }
        }
    }
}

// MARK: - 辅助视图组件

struct StatusBadge: View {
    let status: WorkflowStepStatus
    
    var body: some View {
        Text(statusText)
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(status.color.opacity(0.3)))
            .foregroundColor(status.color)
    }
    
    private var statusText: String {
        switch status {
        case .completed: return "已完成"
        case .inProgress: return "进行中"
        case .pending: return "待处理"
        }
    }
}

struct DifficultyBadge: View {
    let difficulty: ActionGuide.DifficultyLevel
    
    var body: some View {
        Text(difficulty.rawValue)
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(difficulty.color.opacity(0.3)))
            .foregroundColor(difficulty.color)
    }
}

struct TimeBadge: View {
    let time: String
    
    var body: some View {
        Text(time)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.blue.opacity(0.3)))
            .foregroundColor(.blue)
    }
}

struct ActionStepView: View {
    let step: ActionStep
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 步骤编号
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 32, height: 32)
                
                Text("\(step.order)")
                    .font(.caption.bold())
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(step.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if step.isRequired {
                        Text("必需")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.red.opacity(0.3)))
                            .foregroundColor(.red)
                    }
                    
                    Text("\(step.estimatedMinutes)分钟")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Text(step.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                // 签字说明
                if step.signatureRequired, let instructions = step.signatureInstructions {
                    HStack {
                        Image(systemName: "signature")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text(instructions)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                if step.sealRequired {
                    HStack {
                        Image(systemName: "hand.thumbsup.fill")
                            .foregroundColor(.purple)
                            .font(.caption)
                        
                        Text("需要按手印或盖章")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct TipsSection: View {
    let tips: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("实用提示")
                    .font(.subheadline.bold())
                    .foregroundColor(.yellow)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(tips.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.yellow)
                        
                        Text(tips[index])
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
        )
    }
}

struct WarningsSection: View {
    let warnings: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                Text("重要警告")
                    .font(.subheadline.bold())
                    .foregroundColor(.red)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(warnings.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 8) {
                        Text("⚠️")
                        
                        Text(warnings[index])
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
        )
    }
}

struct DocumentCard: View {
    let document: RequiredDocument
    let onPreview: () -> Void
    let onDownload: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(document.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if document.isRequired {
                        Text("必需")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.red.opacity(0.3)))
                            .foregroundColor(.red)
                    }
                }
                
                Text(document.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 12) {
                    if document.template != nil {
                        Button("下载模板") {
                            onDownload()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    if document.sampleDocument != nil {
                        Button("查看样表") {
                            onPreview()
                        }
                        .font(.caption)
                        .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: getDocumentIcon())
                .font(.title2)
                .foregroundColor(.blue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
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
}


struct LegalNoticeCard: View {
    let notice: LegalNotice
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: severityIcon)
                    .foregroundColor(notice.severity.color)
                
                Text(notice.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(notice.noticeType.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(notice.severity.color.opacity(0.3)))
                    .foregroundColor(notice.severity.color)
            }
            
            Text(notice.content)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            if !notice.relatedLaws.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("相关法条:")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.6))
                    
                    ForEach(notice.relatedLaws.indices, id: \.self) { index in
                        Text("• \(notice.relatedLaws[index])")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                Text("后果: \(notice.consequences)")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(notice.severity.color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(notice.severity.color.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var severityIcon: String {
        switch notice.severity {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}

// MARK: - 按钮样式

struct WorkflowPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.accentColor.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct WorkflowSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.8))
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(configuration.isPressed ? 0.15 : 0.1))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

/// 案件分析详情展示组件
struct CaseAnalysisDetailSection: View {
    @State private var showingFullAnalysis = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 分析结果概览
            VStack(alignment: .leading, spacing: 16) {
                Text("🔍 AI案件分析结果")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                // 胜诉概率
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("胜诉概率:")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("75%")
                            .font(.title.bold())
                            .foregroundColor(.green)
                    }
                    
                    ProgressView(value: 0.75)
                        .accentColor(.green)
                        .scaleEffect(y: 2.0)
                    
                    Text("根据证据强度和法律条款分析，您的案件胜诉可能性较高")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                )
            }
            
            // 关键发现
            VStack(alignment: .leading, spacing: 12) {
                Text("🎯 关键发现")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    AnalysisPointView(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        title: "证据充分",
                        description: "您提供的合同、聊天记录等证据链完整"
                    )
                    
                    AnalysisPointView(
                        icon: "scale.3d",
                        color: .blue,
                        title: "法律依据明确",
                        description: "《合同法》第107条、《民法典》第577条适用"
                    )
                    
                    AnalysisPointView(
                        icon: "exclamationmark.triangle.fill",
                        color: .orange,
                        title: "风险提示",
                        description: "对方可能以不可抗力为由进行抗辩"
                    )
                }
            }
            
            // 赔偿预估
            VStack(alignment: .leading, spacing: 12) {
                Text("💰 赔偿预估")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    HStack {
                        Text("直接损失:")
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text("¥50,000")
                            .font(.headline.bold())
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("可得利益损失:")
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text("¥25,000")
                            .font(.headline.bold())
                            .foregroundColor(.blue)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    HStack {
                        Text("预估总赔偿:")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        Spacer()
                        Text("¥75,000")
                            .font(.title2.bold())
                            .foregroundColor(.yellow)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                )
            }
            
            // 推荐策略
            VStack(alignment: .leading, spacing: 12) {
                Text("⚖️ 推荐诉讼策略")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    StrategyPointView(
                        number: "1",
                        title: "优先协商调解",
                        description: "可节省时间成本，建议先尝试庭外和解",
                        priority: .high
                    )
                    
                    StrategyPointView(
                        number: "2", 
                        title: "考虑诉前保全",
                        description: "防止对方转移财产，保护您的合法权益",
                        priority: .medium
                    )
                    
                    StrategyPointView(
                        number: "3",
                        title: "补强证据链", 
                        description: "收集更多证明损失金额的材料",
                        priority: .medium
                    )
                }
            }
            
            // 展开详细分析按钮
            Button {
                showingFullAnalysis = true
            } label: {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("查看完整分析报告")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.accentColor.opacity(0.8))
                )
            }
            .sheet(isPresented: $showingFullAnalysis) {
                FullAnalysisReportView()
            }
        }
    }
}

/// 分析要点视图
struct AnalysisPointView: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }
}

/// 策略要点视图
struct StrategyPointView: View {
    let number: String
    let title: String
    let description: String
    let priority: Priority
    
    enum Priority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .blue
            }
        }
        
        var text: String {
            switch self {
            case .high: return "高优先级"
            case .medium: return "中等优先级"
            case .low: return "低优先级"
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(priority.color)
                    .frame(width: 32, height: 32)
                
                Text(number)
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(priority.text)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(priority.color.opacity(0.3)))
                        .foregroundColor(priority.color)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }
}

/// 完整分析报告视图
struct FullAnalysisReportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 案件概况
                    VStack(alignment: .leading, spacing: 16) {
                        Text("📋 案件概况")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(label: "案件类型", value: "合同纠纷")
                            InfoRow(label: "争议金额", value: "¥100,000")
                            InfoRow(label: "案件复杂度", value: "中等")
                            InfoRow(label: "预估审理周期", value: "6-12个月")
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.08))
                        )
                    }
                    
                    // 证据分析
                    VStack(alignment: .leading, spacing: 16) {
                        Text("🔍 证据分析")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            EvidenceAnalysisCard(
                                title: "合同文件",
                                strength: "强",
                                color: .green,
                                analysis: "合同条款清晰，双方签字盖章完整，具有较强的证明力"
                            )
                            
                            EvidenceAnalysisCard(
                                title: "聊天记录",
                                strength: "中等",
                                color: .orange,
                                analysis: "能够证明双方沟通过程，但需要进一步公证以增强证明力"
                            )
                            
                            EvidenceAnalysisCard(
                                title: "银行转账记录",
                                strength: "强",
                                color: .green,
                                analysis: "银行流水清晰显示付款记录，证明力强"
                            )
                        }
                    }
                    
                    // 法律分析
                    VStack(alignment: .leading, spacing: 16) {
                        Text("⚖️ 法律分析")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("适用法条:")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            LegalProvisionView(
                                title: "《民法典》第577条",
                                content: "当事人一方不履行合同义务或者履行合同义务不符合约定的，应当承担继续履行、采取补救措施或者赔偿损失等违约责任。"
                            )
                            
                            LegalProvisionView(
                                title: "《民法典》第584条",
                                content: "当事人一方不履行合同义务或者履行合同义务不符合约定，造成对方损失的，损失赔偿额应当相当于因违约所造成的损失。"
                            )
                        }
                    }
                    
                    // 风险评估
                    VStack(alignment: .leading, spacing: 16) {
                        Text("⚠️ 风险评估")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            RiskAssessmentCard(
                                title: "败诉风险",
                                level: "低",
                                color: .green,
                                probability: "25%",
                                description: "证据充分，法律依据明确，败诉风险较低"
                            )
                            
                            RiskAssessmentCard(
                                title: "成本风险",
                                level: "中等",
                                color: .orange,
                                probability: "60%",
                                description: "诉讼周期可能较长，需考虑时间成本和律师费用"
                            )
                            
                            RiskAssessmentCard(
                                title: "执行风险",
                                level: "中等",
                                color: .orange,
                                probability: "40%",
                                description: "需要调查对方财产状况，建议考虑诉前保全"
                            )
                        }
                    }
                }
                .padding()
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("完整分析报告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

/// 信息行组件
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
    }
}

/// 证据分析卡片
struct EvidenceAnalysisCard: View {
    let title: String
    let strength: String
    let color: Color
    let analysis: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(strength)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(color.opacity(0.3)))
                    .foregroundColor(color)
            }
            
            Text(analysis)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }
}

/// 法律条文视图
struct LegalProvisionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.blue)
            
            Text(content)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .padding(.leading, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

/// 风险评估卡片
struct RiskAssessmentCard: View {
    let title: String
    let level: String
    let color: Color
    let probability: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(level)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(color.opacity(0.3)))
                    .foregroundColor(color)
                
                Text(probability)
                    .font(.caption.bold())
                    .foregroundColor(color)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    EnhancedWorkflowView(
        caseType: .contractDispute,
        onWorkflowUpdate: { _ in }
    )
}