import SwiftUI

/// 证据上传视图
struct EvidenceUploadView: View {
    let step: EnhancedWorkflowStep
    let onUpdate: (EnhancedWorkflowStep) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var evidenceService = EvidenceUploadService()
    
    @State private var selectedTab: EvidenceTab = .upload
    @State private var showingDocumentPicker = false
    @State private var showingAIAnalysisResult = false
    @State private var showingGeneratedDefense = false
    @State private var showingNotarizationGuide = false
    
    enum EvidenceTab: String, CaseIterable {
        case upload = "上传证据"
        case analysis = "AI分析"
        case defense = "生成答辩"
        case notarization = "公证指南"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标签页切换
                tabSelector
                
                // 主要内容区域
                TabView(selection: $selectedTab) {
                    evidenceUploadTab
                        .tag(EvidenceTab.upload)
                    
                    aiAnalysisTab
                        .tag(EvidenceTab.analysis)
                    
                    defenseGenerationTab
                        .tag(EvidenceTab.defense)
                    
                    notarizationGuideTab
                        .tag(EvidenceTab.notarization)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("证据准备")
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
                    .disabled(!evidenceService.hasUploadedEvidence)
                }
            }
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerView { documents in
                evidenceService.uploadDocuments(documents)
            }
        }
        .sheet(isPresented: $showingAIAnalysisResult) {
            if let result = evidenceService.analysisResult {
                AIAnalysisResultView(result: result)
            }
        }
        .sheet(isPresented: $showingGeneratedDefense) {
            if let defense = evidenceService.generatedDefense {
                GeneratedDefenseView(defense: defense) { editedDefense in
                    evidenceService.updateGeneratedDefense(editedDefense)
                }
            }
        }
    }
    
    // MARK: - 视图组件
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(EvidenceTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring()) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text(tab.rawValue)
                                .font(.subheadline.bold())
                                .foregroundColor(selectedTab == tab ? AppTheme.accentColor : .white.opacity(0.6))
                            
                            Rectangle()
                                .fill(selectedTab == tab ? AppTheme.accentColor : Color.clear)
                                .frame(height: 3)
                                .animation(.spring(), value: selectedTab)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(Color.black.opacity(0.2))
    }
    
    private var evidenceUploadTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 上传指南
                evidenceUploadGuide
                
                // 上传按钮
                uploadButtons
                
                // 已上传的证据
                if !evidenceService.uploadedEvidence.isEmpty {
                    uploadedEvidenceList
                }
                
                // 证据要求
                evidenceRequirements
            }
            .padding()
        }
    }
    
    private var evidenceUploadGuide: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("证据上传指南")
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                EvidenceGuideItem(
                    icon: "camera.fill",
                    title: "拍照上传",
                    description: "直接拍摄纸质文件，确保清晰可读"
                )
                
                EvidenceGuideItem(
                    icon: "photo.on.rectangle",
                    title: "选择图片",
                    description: "从相册选择已拍摄的证据照片"
                )
                
                EvidenceGuideItem(
                    icon: "doc.fill",
                    title: "上传文档",
                    description: "支持PDF、Word等格式的电子文档"
                )
                
                EvidenceGuideItem(
                    icon: "waveform",
                    title: "音视频文件",
                    description: "上传录音、视频等视听证据"
                )
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private var uploadButtons: some View {
        VStack(spacing: 12) {
            Button {
                // 拍照功能
                showingDocumentPicker = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                    
                    Text("拍照上传证据")
                        .font(.headline)
                    
                    Spacer()
                }
                .foregroundColor(.white)
                .padding()
                .background(AppTheme.accentColor)
                .cornerRadius(12)
            }
            
            Button {
                showingDocumentPicker = true
            } label: {
                HStack {
                    Image(systemName: "doc.badge.plus")
                        .font(.title2)
                    
                    Text("选择文件上传")
                        .font(.headline)
                    
                    Spacer()
                }
                .foregroundColor(.white.opacity(0.8))
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private var uploadedEvidenceList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("已上传证据 (\(evidenceService.uploadedEvidence.count))")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            LazyVStack(spacing: 12) {
                ForEach(evidenceService.uploadedEvidence, id: \.id) { evidence in
                    UploadedEvidenceCard(evidence: evidence) {
                        evidenceService.removeEvidence(evidence.id)
                    }
                }
            }
        }
    }
    
    private var evidenceRequirements: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("证据要求")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                EvidenceRequirement(
                    title: "证据真实性",
                    description: "所有证据必须真实、完整，不得伪造或篡改",
                    severity: .critical
                )
                
                EvidenceRequirement(
                    title: "证据相关性",
                    description: "证据应与案件事实和争议焦点具有关联性",
                    severity: .warning
                )
                
                EvidenceRequirement(
                    title: "证据合法性",
                    description: "证据的取得方式应当合法，违法取得的证据不得作为认定事实的根据",
                    severity: .critical
                )
                
                EvidenceRequirement(
                    title: "文件质量",
                    description: "上传的图片和文档应清晰可读，建议分辨率不低于300DPI",
                    severity: .info
                )
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private var aiAnalysisTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 分析状态
                analysisStatus
                
                // 分析结果
                if let result = evidenceService.analysisResult {
                    analysisResultSummary(result)
                } else if evidenceService.isAnalyzing {
                    analysisInProgress
                } else {
                    analysisPrompt
                }
                
                // 分析说明
                analysisExplanation
            }
            .padding()
        }
    }
    
    private var analysisStatus: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text("AI证据分析")
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            
            HStack {
                Image(systemName: evidenceService.hasUploadedEvidence ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(evidenceService.hasUploadedEvidence ? .green : .red)
                
                Text("已上传证据: \(evidenceService.uploadedEvidence.count)份")
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                if evidenceService.hasUploadedEvidence && !evidenceService.isAnalyzing {
                    Button("开始分析") {
                        evidenceService.startAIAnalysis()
                    }
                    .buttonStyle(CompactButtonStyle())
                }
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private func analysisResultSummary(_ result: AIAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("分析结果")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // 证据强度
                EvidenceStrengthView(strength: result.evidenceStrength)
                
                // 关键发现
                if !result.keyFindings.isEmpty {
                    KeyFindingsView(findings: result.keyFindings)
                }
                
                // 建议行动
                if !result.suggestedActions.isEmpty {
                    SuggestedActionsView(actions: result.suggestedActions)
                }
                
                // 详细分析按钮
                Button("查看详细分析") {
                    showingAIAnalysisResult = true
                }
                .buttonStyle(WorkflowSecondaryButtonStyle())
            }
        }
    }
    
    private var analysisInProgress: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppTheme.accentColor)
            
            Text("AI正在分析您的证据...")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("这可能需要几分钟时间，请耐心等待")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .liquidGlass()
    }
    
    private var analysisPrompt: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text("请先上传证据")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("上传您的证据材料后，AI将自动分析证据强度、识别关键信息，并提供专业建议。")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .liquidGlass()
    }
    
    private var analysisExplanation: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI分析说明")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                AnalysisFeatureItem(
                    icon: "magnifyingglass.circle",
                    title: "证据识别",
                    description: "自动识别和分类不同类型的证据材料"
                )
                
                AnalysisFeatureItem(
                    icon: "chart.bar.fill",
                    title: "强度评估",
                    description: "评估每份证据的证明力和法律效力"
                )
                
                AnalysisFeatureItem(
                    icon: "lightbulb.fill",
                    title: "策略建议",
                    description: "基于证据分析结果提供诉讼策略建议"
                )
                
                AnalysisFeatureItem(
                    icon: "exclamationmark.triangle",
                    title: "风险提示",
                    description: "识别证据中的薄弱环节和潜在风险"
                )
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private var defenseGenerationTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 生成状态
                defenseGenerationStatus
                
                // 生成的答辩书
                if let defense = evidenceService.generatedDefense {
                    generatedDefensePreview(defense)
                } else if evidenceService.isGeneratingDefense {
                    defenseGenerationInProgress
                } else {
                    defenseGenerationPrompt
                }
                
                // 答辩书说明
                defenseDocumentExplanation
            }
            .padding()
        }
    }
    
    private var defenseGenerationStatus: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text.below.ecg")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("AI生成答辩书")
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            
            HStack {
                Image(systemName: evidenceService.analysisResult != nil ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(evidenceService.analysisResult != nil ? .green : .red)
                
                Text("分析完成: \(evidenceService.analysisResult != nil ? "是" : "否")")
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                if evidenceService.analysisResult != nil && !evidenceService.isGeneratingDefense {
                    Button("生成答辩书") {
                        evidenceService.generateDefenseDocument()
                    }
                    .buttonStyle(CompactButtonStyle())
                }
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private func generatedDefensePreview(_ defense: WorkflowGeneratedDocument) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("生成的答辩书")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("文档类型")
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text(defense.documentType)
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("生成时间")
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text(DateFormatter.shortDateTime.string(from: defense.generatedAt))
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("AI信心度")
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text("\(Int(defense.confidence * 100))%")
                        .foregroundColor(defense.confidence > 0.8 ? .green : defense.confidence > 0.6 ? .orange : .red)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
            )
            
            // 内容预览
            VStack(alignment: .leading, spacing: 8) {
                Text("内容预览")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Text(String(defense.content.prefix(200)) + (defense.content.count > 200 ? "..." : ""))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.05))
                    )
            }
            
            HStack(spacing: 12) {
                Button("查看全文") {
                    showingGeneratedDefense = true
                }
                .buttonStyle(WorkflowPrimaryButtonStyle())
                
                Button("重新生成") {
                    evidenceService.generateDefenseDocument()
                }
                .buttonStyle(WorkflowSecondaryButtonStyle())
            }
        }
    }
    
    private var defenseGenerationInProgress: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppTheme.accentColor)
            
            Text("AI正在生成答辩书...")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("正在进行以下步骤:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                DefenseGenerationStep(text: "分析案件争议焦点", isActive: true)
                DefenseGenerationStep(text: "整理证据要点", isActive: evidenceService.generationProgress > 0.3)
                DefenseGenerationStep(text: "起草答辩理由", isActive: evidenceService.generationProgress > 0.6)
                DefenseGenerationStep(text: "完善法律依据", isActive: evidenceService.generationProgress > 0.9)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .liquidGlass()
    }
    
    private var defenseGenerationPrompt: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "doc.text.below.ecg")
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text("请先完成证据分析")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("上传证据并完成AI分析后，系统将自动生成专业的答辩书。答辩书将基于您的证据材料和案件特点量身定制。")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .liquidGlass()
    }
    
    private var defenseDocumentExplanation: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("答辩书说明")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                DefenseFeatureItem(
                    icon: "doc.text",
                    title: "结构化撰写",
                    description: "按照标准答辩书格式生成，包含完整的法律结构"
                )
                
                DefenseFeatureItem(
                    icon: "scale.3d",
                    title: "法律依据",
                    description: "自动添加相关法条和法律依据"
                )
                
                DefenseFeatureItem(
                    icon: "pencil.and.outline",
                    title: "可编辑修改",
                    description: "生成后可以进行个性化编辑和调整"
                )
                
                DefenseFeatureItem(
                    icon: "signature",
                    title: "签名指导",
                    description: "提供签名位置和格式要求指导"
                )
            }
            
            // 重要提示
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("重要提示")
                        .font(.subheadline.bold())
                        .foregroundColor(.orange)
                }
                
                Text("AI生成的答辩书仅供参考，建议您仔细审核并根据具体情况进行调整。如有疑问，请咨询专业律师。")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.1))
            )
        }
        .padding()
        .liquidGlass()
    }
    
    private var notarizationGuideTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 公证概述
                notarizationOverview
                
                // 公证类型
                notarizationTypes
                
                // 费用说明
                notarizationCosts
                
                // 推荐公证处
                recommendedNotaryOffices
            }
            .padding()
        }
    }
    
    private var notarizationOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("证据公证指南")
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            
            Text("公证可以大幅提升证据的法律效力，特别是对于电子证据、合同文件等材料。虽然不是必须的，但建议对关键证据进行公证。")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            VStack(alignment: .leading, spacing: 8) {
                NotarizationBenefit(
                    icon: "arrow.up.circle.fill",
                    title: "提升证明力",
                    description: "公证文书具有较强的证明力"
                )
                
                NotarizationBenefit(
                    icon: "shield.checkered",
                    title: "法律保护",
                    description: "受到法律特殊保护，推翻需要更强证据"
                )
                
                NotarizationBenefit(
                    icon: "clock.arrow.circlepath",
                    title: "节省时间",
                    description: "避免在法庭上就证据真实性进行过多争议"
                )
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private var notarizationTypes: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("公证类型")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                NotarizationTypeCard(
                    type: "合同公证",
                    description: "对签署的合同进行公证，确认合同真实性",
                    cost: "200-500元",
                    timeRequired: "1-3工作日"
                )
                
                NotarizationTypeCard(
                    type: "文书公证",
                    description: "对各类文书、证明材料进行公证",
                    cost: "100-300元",
                    timeRequired: "1-2工作日"
                )
                
                NotarizationTypeCard(
                    type: "电子证据公证",
                    description: "对网页、聊天记录等电子证据进行保全公证",
                    cost: "300-800元",
                    timeRequired: "2-5工作日"
                )
                
                NotarizationTypeCard(
                    type: "事实公证",
                    description: "对某些法律事实或行为进行公证",
                    cost: "500-1500元",
                    timeRequired: "3-7工作日"
                )
            }
        }
    }
    
    private var notarizationCosts: some View {
        NotarizationCostBreakdownView()
    }
    
    private var recommendedNotaryOffices: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("推荐公证处")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                NotaryOfficeCard(
                    office: NotaryOffice(
                        id: "1",
                        name: "市第一公证处",
                        address: "市中心区法院路123号",
                        phone: "0755-12345678",
                        workingHours: "周一至周五 9:00-17:00",
                        appointmentUrl: "https://notary1.example.com",
                        rating: 4.8,
                        distance: 2.5
                    )
                )
                
                NotaryOfficeCard(
                    office: NotaryOffice(
                        id: "2",
                        name: "市第二公证处",
                        address: "高新区科技大道456号",
                        phone: "0755-87654321",
                        workingHours: "周一至周六 8:30-17:30",
                        appointmentUrl: "https://notary2.example.com",
                        rating: 4.6,
                        distance: 3.8
                    )
                )
                
                NotaryOfficeCard(
                    office: NotaryOffice(
                        id: "3",
                        name: "市第三公证处",
                        address: "南山区深南大道789号",
                        phone: "0755-11223344",
                        workingHours: "周一至周五 9:00-18:00",
                        appointmentUrl: nil,
                        rating: 4.5,
                        distance: 5.2
                    )
                )
            }
            
            Button("查找更多公证处") {
                showingNotarizationGuide = true
            }
            .buttonStyle(WorkflowSecondaryButtonStyle())
        }
    }
}

// MARK: - 证据上传服务

@MainActor
class EvidenceUploadService: ObservableObject {
    @Published var uploadedEvidence: [UploadedEvidence] = []
    @Published var isAnalyzing = false
    @Published var analysisResult: AIAnalysisResult?
    @Published var isGeneratingDefense = false
    @Published var generatedDefense: WorkflowGeneratedDocument?
    @Published var generationProgress: Double = 0
    
    var hasUploadedEvidence: Bool {
        !uploadedEvidence.isEmpty
    }
    
    func uploadDocuments(_ documents: [EvidenceDocumentFile]) {
        let newEvidence = documents.map { doc in
            UploadedEvidence(
                id: UUID().uuidString,
                name: doc.name,
                type: mapDocumentType(doc.type),
                uploadDate: Date(),
                fileSize: "1.2MB", // 模拟大小
                status: .uploaded,
                thumbnailUrl: nil,
                analysisNote: nil
            )
        }
        
        uploadedEvidence.append(contentsOf: newEvidence)
    }
    
    func removeEvidence(_ id: String) {
        uploadedEvidence.removeAll { $0.id == id }
    }
    
    func startAIAnalysis() {
        isAnalyzing = true
        
        // 模拟分析过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.completeAnalysis()
        }
    }
    
    private func completeAnalysis() {
        analysisResult = AIAnalysisResult(
            id: UUID().uuidString,
            documentType: "综合证据分析",
            analysisDate: Date(),
            keyFindings: [
                "发现3份关键合同文件，合同条款明确",
                "银行转账记录完整，资金流向清晰",
                "对方违约事实证据充分",
                "损失金额计算有据可依"
            ],
            suggestedActions: [
                "重点强调对方违约的时间节点和具体行为",
                "补充提供银行对账单作为辅助证据",
                "建议对电子邮件进行公证以增强证明力",
                "准备专业的损失评估报告"
            ],
            evidenceStrength: 0.82,
            riskAssessment: "证据较为完整，胜诉概率较高，建议积极应诉",
            generatedDocument: nil,
            confidence: 0.87
        )
        
        isAnalyzing = false
    }
    
    func generateDefenseDocument() {
        guard analysisResult != nil else { return }
        
        isGeneratingDefense = true
        generationProgress = 0
        
        // 模拟生成过程
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            self.generationProgress += 0.2
            
            if self.generationProgress >= 1.0 {
                timer.invalidate()
                self.completeDefenseGeneration()
            }
        }
    }
    
    private func completeDefenseGeneration() {
        let defenseContent = generateMockDefenseContent()
        
        generatedDefense = WorkflowGeneratedDocument(
            id: UUID().uuidString,
            documentType: "民事答辩状",
            content: defenseContent,
            generatedAt: Date(),
            templateUsed: "标准民事答辩状模板",
            editableFields: ["当事人信息", "答辩理由", "法律依据"],
            reviewRequired: true,
            downloadUrl: "/generated/defense_\(UUID().uuidString).pdf"
        )
        
        isGeneratingDefense = false
        generationProgress = 0
    }
    
    private func generateMockDefenseContent() -> String {
        return """
        民事答辩状
        
        答辩人：[姓名]
        性别：[性别]
        身份证号：[身份证号]
        住址：[住址]
        
        针对[原告姓名]诉[被告姓名][案件性质]纠纷一案，答辩人依法提出如下答辩意见：
        
        一、答辩人对原告的诉讼请求不予认可，请求法院驳回原告的诉讼请求。
        
        二、事实与理由：
        
        1. 原告所述事实与客观事实不符。根据答辩人提供的证据材料显示...
        
        2. 原告的诉讼请求缺乏事实和法律依据...
        
        3. 答辩人已按约履行了相关义务...
        
        三、法律依据：
        
        根据《中华人民共和国合同法》第xxx条、《中华人民共和国民法典》第xxx条等相关法律规定...
        
        综上所述，原告的诉讼请求缺乏事实和法律依据，请求法院依法驳回原告的诉讼请求。
        
        此致
        [法院名称]
        
        答辩人：[签名]
        日期：[日期]
        """
    }
    
    func updateGeneratedDefense(_ defense: WorkflowGeneratedDocument) {
        generatedDefense = defense
    }
    
    private func mapDocumentType(_ type: EvidenceDocumentType) -> EvidenceType {
        switch type {
        case .pdf, .word: return .document
        case .image: return .photo
        case .text: return .document
        }
    }
}

// MARK: - 数据模型

struct UploadedEvidence: Identifiable {
    let id: String
    let name: String
    let type: EvidenceType
    let uploadDate: Date
    let fileSize: String
    var status: EvidenceStatus
    let thumbnailUrl: String?
    var analysisNote: String?
}

enum EvidenceType {
    case document, photo, audio, video
    
    var icon: String {
        switch self {
        case .document: return "doc.fill"
        case .photo: return "photo.fill"
        case .audio: return "waveform"
        case .video: return "video.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .document: return .blue
        case .photo: return .green
        case .audio: return .orange
        case .video: return .purple
        }
    }
}

enum EvidenceStatus {
    case uploading, uploaded, analyzing, analyzed, error
    
    var color: Color {
        switch self {
        case .uploading: return .yellow
        case .uploaded: return .green
        case .analyzing: return .blue
        case .analyzed: return .purple
        case .error: return .red
        }
    }
}

// MARK: - 辅助视图组件

struct EvidenceGuideItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
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
    }
}

struct UploadedEvidenceCard: View {
    let evidence: UploadedEvidence
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: evidence.type.icon)
                .font(.title2)
                .foregroundColor(evidence.type.color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(evidence.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack {
                    Text(evidence.fileSize)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(DateFormatter.shortDateTime.string(from: evidence.uploadDate))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundColor(evidence.status.color)
                    
                    Text(statusText(for: evidence.status))
                        .font(.caption)
                        .foregroundColor(evidence.status.color)
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
    
    private func statusText(for status: EvidenceStatus) -> String {
        switch status {
        case .uploading: return "上传中"
        case .uploaded: return "已上传"
        case .analyzing: return "分析中"
        case .analyzed: return "已分析"
        case .error: return "上传失败"
        }
    }
}

struct EvidenceRequirement: View {
    let title: String
    let description: String
    let severity: LegalNotice.NoticeSeverity
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: severityIcon)
                .foregroundColor(severity.color)
                .font(.subheadline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    private var severityIcon: String {
        switch severity {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}

struct EvidenceStrengthView: View {
    let strength: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("证据强度")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(strength * 100))%")
                    .font(.subheadline.bold())
                    .foregroundColor(strengthColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(strengthColor)
                        .frame(width: geometry.size.width * strength, height: 8)
                        .animation(.easeInOut(duration: 0.5), value: strength)
                }
            }
            .frame(height: 8)
            
            Text(strengthDescription)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var strengthColor: Color {
        if strength >= 0.8 {
            return .green
        } else if strength >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var strengthDescription: String {
        if strength >= 0.8 {
            return "证据充分，证明力强"
        } else if strength >= 0.6 {
            return "证据一般，建议补充"
        } else {
            return "证据不足，需要加强"
        }
    }
}

struct KeyFindingsView: View {
    let findings: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("关键发现")
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(findings.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.3))
                                .frame(width: 20, height: 20)
                            
                            Text("\(index + 1)")
                                .font(.caption2.bold())
                                .foregroundColor(.green)
                        }
                        
                        Text(findings[index])
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
    }
}

struct SuggestedActionsView: View {
    let actions: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("建议行动")
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(actions.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        Text(actions[index])
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

struct AnalysisFeatureItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.purple)
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
    }
}

struct DefenseGenerationStep: View {
    let text: String
    let isActive: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isActive ? .green : .white.opacity(0.5))
            
            Text(text)
                .font(.caption)
                .foregroundColor(isActive ? .white : .white.opacity(0.5))
                .strikethrough(!isActive)
        }
    }
}

struct DefenseFeatureItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
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
    }
}

struct NotarizationBenefit: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
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
    }
}

struct NotarizationTypeCard: View {
    let type: String
    let description: String
    let cost: String
    let timeRequired: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(type)
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("费用")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(cost)
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("时间")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(timeRequired)
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

struct NotaryOfficeCard: View {
    let office: NotaryOffice
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(office.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text(String(format: "%.1f", office.rating))
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text(office.address)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text(office.phone)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text(office.workingHours)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                if let distance = office.distance {
                    HStack {
                        Image(systemName: "car.fill")
                            .foregroundColor(.purple)
                            .font(.caption)
                        
                        Text("距离 \(String(format: "%.1f", distance))公里")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            HStack {
                if office.appointmentUrl != nil {
                    Button("在线预约") {
                        // 处理在线预约
                    }
                    .buttonStyle(CompactButtonStyle())
                }
                
                Button("拨打电话") {
                    if let url = URL(string: "tel://\(office.phone)") {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(CompactButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

struct NotarizationCostBreakdownView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("费用明细")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                CostBreakdownItem(category: "基础费用", items: [
                    ("公证费", "100-300元"),
                    ("材料费", "50-100元"),
                    ("服务费", "50-150元")
                ])
                
                CostBreakdownItem(category: "附加费用", items: [
                    ("翻译费", "200-500元/页"),
                    ("复印费", "2-5元/页"),
                    ("邮寄费", "20-50元")
                ])
                
                CostBreakdownItem(category: "特殊费用", items: [
                    ("上门服务", "200-500元"),
                    ("加急费", "基础费用的50%"),
                    ("节假日费", "基础费用的30%")
                ])
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    
                    Text("费用说明")
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)
                }
                
                Text("具体费用以公证处收费标准为准，建议提前咨询确认。部分公证处提供优惠政策，如批量公证折扣等。")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
            )
        }
        .padding()
        .liquidGlass()
    }
}

struct CostBreakdownItem: View {
    let category: String
    let items: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category)
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 4) {
                ForEach(items.indices, id: \.self) { index in
                    HStack {
                        Text(items[index].0)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text(items[index].1)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct CompactButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppTheme.accentColor.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Additional Views Referenced

struct DocumentPickerView: UIViewControllerRepresentable {
    let onDocumentsPicked: ([EvidenceDocumentFile]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .text, .image])
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            let documents = urls.map { url in
                EvidenceDocumentFile(
                    id: UUID().uuidString,
                    name: url.lastPathComponent,
                    type: .pdf, // 简化处理
                    url: url,
                    size: 0
                )
            }
            parent.onDocumentsPicked(documents)
        }
    }
}

struct EvidenceDocumentFile: Identifiable {
    let id: String
    let name: String
    let type: EvidenceDocumentType
    let url: URL
    let size: Int64
}

enum EvidenceDocumentType {
    case pdf, word, image, text
}

struct AIAnalysisResultView: View {
    let result: AIAnalysisResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 详细的AI分析结果视图内容
                    Text("AI分析结果详情")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    // 这里可以展示更详细的分析结果
                }
                .padding()
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("分析结果")
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

struct GeneratedDefenseView: View {
    let defense: WorkflowGeneratedDocument
    let onUpdate: (WorkflowGeneratedDocument) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("生成的答辩书")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text(defense.content)
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
            .navigationTitle("答辩书")
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
    }
}

extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}