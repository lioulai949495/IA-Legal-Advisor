import SwiftUI

/// 判决书分析视图
struct JudgmentAnalysisView: View {
    let step: EnhancedWorkflowStep
    let onUpdate: (EnhancedWorkflowStep) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var analysisService = JudgmentAnalysisService()
    
    @State private var showingDocumentPicker = false
    @State private var showingAnalysisResult = false
    @State private var showingCustomStepOptions = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 上传判决书
                uploadSection
                
                // 分析结果
                if let result = analysisService.analysisResult {
                    analysisResultSection(result)
                } else if analysisService.isAnalyzing {
                    analyzingSection
                } else if !analysisService.uploadedJudgments.isEmpty {
                    waitingAnalysisSection
                }
                
                Spacer()
                
                // 操作按钮
                actionButtons
            }
            .padding()
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("判决书分析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        var updatedStep = step
                        updatedStep.status = .completed
                        onUpdate(updatedStep)
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .disabled(analysisService.analysisResult == nil)
                }
            }
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerView { documents in
                analysisService.uploadJudgments(documents)
            }
        }
        .sheet(isPresented: $showingAnalysisResult) {
            if let result = analysisService.analysisResult {
                JudgmentAnalysisDetailView(result: result)
            }
        }
        .actionSheet(isPresented: $showingCustomStepOptions) {
            ActionSheet(
                title: Text("选择下一步行动"),
                message: Text("根据判决书分析结果，您可以选择："),
                buttons: [
                    .default(Text("提起二审")) {
                        // 添加二审流程
                    },
                    .default(Text("申请执行")) {
                        // 添加执行流程
                    },
                    .default(Text("申请再审")) {
                        // 添加再审流程
                    },
                    .default(Text("结案")) {
                        // 结案处理
                    },
                    .cancel(Text("暂不处理"))
                ]
            )
        }
    }
    
    // MARK: - 视图组件
    
    private var uploadSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text("上传判决书")
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            
            if analysisService.uploadedJudgments.isEmpty {
                Button {
                    showingDocumentPicker = true
                } label: {
                    VStack(spacing: 16) {
                        Image(systemName: "plus.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(AppTheme.accentColor)
                        
                        Text("点击上传判决书")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("支持PDF、图片等格式")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.accentColor.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [10]))
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                VStack(spacing: 12) {
                    ForEach(analysisService.uploadedJudgments, id: \.id) { judgment in
                        JudgmentDocumentCard(judgment: judgment) {
                            analysisService.removeJudgment(judgment.id)
                        }
                    }
                    
                    Button {
                        showingDocumentPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("继续添加判决书")
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private func analysisResultSection(_ result: JudgmentAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("分析结果")
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                // 判决结果
                ResultSummaryCard(
                    title: "判决结果",
                    content: result.judgmentSummary,
                    color: result.isWinning ? .green : .red
                )
                
                // 胜败原因
                if !result.reasonsAnalysis.isEmpty {
                    ReasonsAnalysisView(reasons: result.reasonsAnalysis, isWinning: result.isWinning)
                }
                
                // 建议行动
                if !result.recommendedActions.isEmpty {
                    RecommendedActionsView(actions: result.recommendedActions)
                }
                
                // 详细分析按钮
                Button("查看详细分析报告") {
                    showingAnalysisResult = true
                }
                .buttonStyle(WorkflowSecondaryButtonStyle())
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private var analyzingSection: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppTheme.accentColor)
            
            Text("AI正在分析判决书...")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("分析进度:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                JudgmentAnalysisStep(text: "识别判决内容", isActive: true)
                JudgmentAnalysisStep(text: "分析胜败原因", isActive: analysisService.analysisProgress > 0.3)
                JudgmentAnalysisStep(text: "评估后续选项", isActive: analysisService.analysisProgress > 0.6)
                JudgmentAnalysisStep(text: "生成建议方案", isActive: analysisService.analysisProgress > 0.9)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .liquidGlass()
    }
    
    private var waitingAnalysisSection: some View {
        VStack(spacing: 16) {
            Text("开始分析")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("已上传 \(analysisService.uploadedJudgments.count) 份判决书")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Button("开始AI分析") {
                analysisService.startAnalysis()
            }
            .buttonStyle(WorkflowPrimaryButtonStyle())
        }
        .padding()
        .liquidGlass()
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if let result = analysisService.analysisResult {
                Button("选择下一步行动") {
                    showingCustomStepOptions = true
                }
                .buttonStyle(WorkflowPrimaryButtonStyle())
            }
            
            Button("保存分析结果") {
                // 保存逻辑
                var updatedStep = step
                updatedStep.status = .completed
                onUpdate(updatedStep)
                dismiss()
            }
            .buttonStyle(WorkflowSecondaryButtonStyle())
        }
    }
}

// MARK: - 判决书分析服务

@MainActor
class JudgmentAnalysisService: ObservableObject {
    @Published var uploadedJudgments: [UploadedJudgment] = []
    @Published var isAnalyzing = false
    @Published var analysisResult: JudgmentAnalysisResult?
    @Published var analysisProgress: Double = 0
    
    func uploadJudgments(_ documents: [EvidenceDocumentFile]) {
        let newJudgments = documents.map { doc in
            UploadedJudgment(
                id: UUID().uuidString,
                name: doc.name,
                uploadDate: Date(),
                fileSize: "2.3MB", // 模拟大小
                pageCount: 15 // 模拟页数
            )
        }
        
        uploadedJudgments.append(contentsOf: newJudgments)
    }
    
    func removeJudgment(_ id: String) {
        uploadedJudgments.removeAll { $0.id == id }
    }
    
    func startAnalysis() {
        isAnalyzing = true
        analysisProgress = 0
        
        // 模拟分析过程
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            self.analysisProgress += 0.2
            
            if self.analysisProgress >= 1.0 {
                timer.invalidate()
                self.completeAnalysis()
            }
        }
    }
    
    private func completeAnalysis() {
        analysisResult = JudgmentAnalysisResult(
            id: UUID().uuidString,
            analysisDate: Date(),
            judgmentSummary: "一审法院支持了您的大部分诉讼请求，判决对方支付欠款本金及利息共计45万元。",
            isWinning: true,
            winningPercentage: 0.85,
            reasonsAnalysis: [
                "合同条款明确，证据充分",
                "对方违约事实清楚",
                "损失计算有据可依",
                "法院认定我方主张成立"
            ],
            lostClaims: [
                "律师费赔偿请求未获支持",
                "精神损失费请求被驳回"
            ],
            recommendedActions: [
                RecommendedAction(
                    type: .execution,
                    title: "申请强制执行",
                    description: "判决生效后，对方如不履行可申请法院强制执行",
                    priority: .high,
                    timeLimit: "判决生效后2年内"
                ),
                RecommendedAction(
                    type: .secondTrial,
                    title: "部分上诉",
                    description: "可对律师费等未获支持的请求提起上诉",
                    priority: .medium,
                    timeLimit: "收到判决书15日内"
                )
            ],
            appealOptions: AppealOptions(
                canAppeal: true,
                appealDeadline: Calendar.current.date(byAdding: .day, value: 15, to: Date())!,
                appealCost: CostRange(min: 5000, max: 15000),
                winningProbability: 0.3
            ),
            executionGuidance: ExecutionGuidance(
                executionDeadline: Calendar.current.date(byAdding: .year, value: 2, to: Date())!,
                estimatedDifficulty: .medium,
                requiredDocuments: ["判决书", "执行申请书", "被执行人财产线索"],
                executionCost: CostRange(min: 2000, max: 8000)
            )
        )
        
        isAnalyzing = false
        analysisProgress = 0
    }
}

// MARK: - 数据模型

struct UploadedJudgment: Identifiable {
    let id: String
    let name: String
    let uploadDate: Date
    let fileSize: String
    let pageCount: Int
}

struct JudgmentAnalysisResult: Identifiable {
    let id: String
    let analysisDate: Date
    let judgmentSummary: String
    let isWinning: Bool
    let winningPercentage: Double
    let reasonsAnalysis: [String]
    let lostClaims: [String]
    let recommendedActions: [RecommendedAction]
    let appealOptions: AppealOptions
    let executionGuidance: ExecutionGuidance
}

struct RecommendedAction: Identifiable {
    let id = UUID()
    let type: ActionType
    let title: String
    let description: String
    let priority: Priority
    let timeLimit: String
    
    enum ActionType {
        case execution, secondTrial, retrial, settlement, caseClose
    }
    
    enum Priority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .green
            }
        }
    }
}

struct AppealOptions {
    let canAppeal: Bool
    let appealDeadline: Date
    let appealCost: CostRange
    let winningProbability: Double
}

struct ExecutionGuidance {
    let executionDeadline: Date
    let estimatedDifficulty: Difficulty
    let requiredDocuments: [String]
    let executionCost: CostRange
    
    enum Difficulty {
        case easy, medium, hard
        
        var color: Color {
            switch self {
            case .easy: return .green
            case .medium: return .orange
            case .hard: return .red
            }
        }
        
        var description: String {
            switch self {
            case .easy: return "较容易"
            case .medium: return "一般难度"
            case .hard: return "较困难"
            }
        }
    }
}

// MARK: - 辅助视图组件

struct JudgmentDocumentCard: View {
    let judgment: UploadedJudgment
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "doc.text.fill")
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(judgment.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack {
                    Text(judgment.fileSize)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("\(judgment.pageCount)页")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(DateFormatter.shortDateTime.string(from: judgment.uploadDate))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

struct ResultSummaryCard: View {
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: color == .green ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ReasonsAnalysisView: View {
    let reasons: [String]
    let isWinning: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.circle.fill")
                    .foregroundColor(isWinning ? .green : .red)
                
                Text(isWinning ? "胜诉原因" : "败诉原因")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(reasons.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.caption)
                            .foregroundColor(isWinning ? .green : .red)
                        
                        Text(reasons[index])
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
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

struct RecommendedActionsView: View {
    let actions: [RecommendedAction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("建议行动")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                ForEach(actions) { action in
                    RecommendedActionCard(action: action)
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

struct RecommendedActionCard: View {
    let action: RecommendedAction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(action.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(priorityText)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(action.priority.color.opacity(0.3)))
                    .foregroundColor(action.priority.color)
            }
            
            Text(action.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            HStack {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text("时限: \(action.timeLimit)")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var priorityText: String {
        switch action.priority {
        case .high: return "高优先级"
        case .medium: return "中优先级"
        case .low: return "低优先级"
        }
    }
}

struct JudgmentAnalysisStep: View {
    let text: String
    let isActive: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isActive ? .green : .white.opacity(0.5))
            
            Text(text)
                .font(.caption)
                .foregroundColor(isActive ? .white : .white.opacity(0.5))
        }
    }
}

struct JudgmentAnalysisDetailView: View {
    let result: JudgmentAnalysisResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("判决书分析详情")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    // 这里可以展示更详细的分析结果
                    Text(result.judgmentSummary)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                }
                .padding()
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("分析详情")
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

#Preview {
    JudgmentAnalysisView(
        step: EnhancedWorkflowStep(
            id: "judgment-analysis",
            title: "判决书分析",
            description: "上传判决书进行AI分析",
            status: .pending,
            date: nil,
            estimatedDays: 1,
            stepType: .judgmentAnalysis,
            actionGuide: ActionGuide(title: "", steps: [], tips: [], warnings: [], estimatedTime: "", difficulty: .medium),
            requiredDocuments: [],
            legalNotices: []
        ),
        onUpdate: { _ in }
    )
}