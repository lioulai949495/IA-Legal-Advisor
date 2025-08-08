import SwiftUI
import Combine

/// 增强的新建案件视图 - 包含AI咨询界面
struct EnhancedNewCaseView: View {
    @StateObject private var viewModel = EnhancedNewCaseViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingConfirmation = false
    @State private var createdWorkflow: EnhancedCaseWorkflow?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // 顶部进度指示器
                        progressIndicator
                        
                        // 当前步骤内容
                        currentStepView
                            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                        
                        // 底部导航按钮
                        navigationButtons
                    }
                }
                
                // AI咨询浮动按钮
                aiConsultationButton
                
                // 加载覆盖层
                if viewModel.isProcessing {
                    loadingOverlay
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAIConsultation) {
            AIConsultationView(
                caseType: viewModel.selectedCaseType,
                currentInput: viewModel.getAllUserInput(),
                onRecommendation: { recommendation in
                    viewModel.applyAIRecommendation(recommendation)
                }
            )
        }
        .alert("创建案件工作流程", isPresented: $showingConfirmation) {
            Button("创建") {
                Task {
                    await createWorkflowAndDismiss()
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("确认创建\(viewModel.selectedCaseType?.rawValue ?? "")案件的完整工作流程？这将为您提供从案件分析到结案的全程指导。")
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - 进度指示器
    private var progressIndicator: some View {
        VStack(spacing: 16) {
            HStack {
                Button("取消") {
                    dismiss()
                }
                .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text("新建案件")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("重置") {
                    viewModel.resetForm()
                }
                .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal)
            
            // 步骤进度条
            HStack(spacing: 4) {
                ForEach(Array(NewCaseStep.allCases.enumerated()), id: \.element) { index, step in
                    Rectangle()
                        .fill(index <= viewModel.currentStepIndex ? AppTheme.accentColor : Color.white.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut, value: viewModel.currentStepIndex)
                }
            }
            .padding(.horizontal)
            
            Text("\(viewModel.currentStepIndex + 1) / \(NewCaseStep.allCases.count) - \(viewModel.currentStep.title)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical)
    }
    
    // MARK: - 当前步骤视图
    @ViewBuilder
    private var currentStepView: some View {
        VStack(spacing: 24) {
            switch viewModel.currentStep {
            case .caseTypeSelection:
                CaseTypeSelectionView(
                    selectedCaseType: $viewModel.selectedCaseType,
                    aiRecommendations: viewModel.aiRecommendations
                )
                
            case .basicInformation:
                BasicInformationView(
                    title: $viewModel.caseTitle,
                    description: $viewModel.caseDescription,
                    parties: $viewModel.involvedParties,
                    selectedCaseType: viewModel.selectedCaseType
                )
                
            case .aiConsultation:
                AIConsultationStepView(
                    viewModel: viewModel,
                    onStartConsultation: {
                        viewModel.showingAIConsultation = true
                    }
                )
                
            case .evidenceUpload:
                EvidenceUploadView(
                    step: EnhancedWorkflowStep(
                        id: "evidence_upload",
                        title: "证据上传",
                        description: "上传案件相关证据材料",
                        status: .pending,
                        date: nil,
                        estimatedDays: 1,
                        stepType: .evidencePreparation,
                        actionGuide: ActionGuide(
                            title: "证据上传指导",
                            steps: [],
                            tips: ["确保文件清晰可读", "支持多种文件格式"],
                            warnings: ["请确保证据真实有效"],
                            estimatedTime: "30分钟",
                            difficulty: .easy
                        ),
                        requiredDocuments: [],
                        legalNotices: []
                    ),
                    onUpdate: { updatedStep in
                        // Handle step update - mark evidence upload as completed
                        viewModel.handleEvidenceUploadUpdate(updatedStep)
                    }
                )
                
            case .workflowConfiguration:
                WorkflowConfigurationView(
                    selectedWorkflowType: $viewModel.selectedWorkflowType,
                    customizations: $viewModel.workflowCustomizations,
                    caseType: viewModel.selectedCaseType
                )
                
            case .reviewAndConfirm:
                ReviewAndConfirmView(
                    title: viewModel.caseTitle,
                    description: viewModel.caseDescription,
                    caseType: viewModel.selectedCaseType,
                    workflowType: viewModel.selectedWorkflowType,
                    parties: viewModel.involvedParties,
                    documents: viewModel.uploadedDocuments,
                    aiAnalysis: viewModel.aiAnalysisResult
                )
            }
        }
        .padding()
    }
    
    // MARK: - 底部导航按钮
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // 上一步按钮
            Button {
                withAnimation {
                    viewModel.goToPreviousStep()
                }
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("上一步")
                }
                .font(.headline)
                .foregroundColor(viewModel.canGoToPreviousStep ? .white : .white.opacity(0.3))
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(viewModel.canGoToPreviousStep ? 0.2 : 0.1))
                )
            }
            .disabled(!viewModel.canGoToPreviousStep)
            
            // 下一步/完成按钮
            Button {
                if viewModel.isLastStep {
                    showingConfirmation = true
                } else {
                    withAnimation {
                        viewModel.goToNextStep()
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.isLastStep ? "创建工作流程" : "下一步")
                    if !viewModel.isLastStep {
                        Image(systemName: "chevron.right")
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                }
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.canGoToNextStep ? AppTheme.accentColor : AppTheme.accentColor.opacity(0.5))
                )
            }
            .disabled(!viewModel.canGoToNextStep)
        }
        .padding()
    }
    
    // MARK: - AI咨询浮动按钮
    private var aiConsultationButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button {
                    viewModel.showingAIConsultation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                        Text("AI咨询")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(AppTheme.accentColor)
                            .shadow(color: .black.opacity(0.2), radius: 8)
                    )
                }
                .scaleEffect(viewModel.aiConsultationAvailable ? 1.0 : 0.0)
                .animation(.spring(), value: viewModel.aiConsultationAvailable)
            }
            .padding()
        }
    }
    
    // MARK: - 加载覆盖层
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 24) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text(viewModel.processingMessage)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                if !viewModel.processingDetails.isEmpty {
                    Text(viewModel.processingDetails)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            )
            .padding()
        }
    }
    
    // MARK: - 私有方法
    private func createWorkflowAndDismiss() async {
        do {
            let workflow = try await viewModel.createWorkflow()
            createdWorkflow = workflow
            
            // 将案件添加到应用模型
            let newCase = Case(
                id: UUID().uuidString,
                title: viewModel.caseTitle,
                description: viewModel.caseDescription,
                createdAt: Date(),
                lastUpdatedAt: Date(),
                caseType: viewModel.selectedCaseType ?? .contractDispute,
                status: .active,
                messages: [
                    Message(
                        id: UUID().uuidString,
                        content: "案件已创建，工作流程已启动。",
                        createdAt: Date(),
                        isFromAI: true,
                        attachments: [],
                        documentLinks: []
                    )
                ]
            )
            
            await MainActor.run {
                appViewModel.cases.insert(newCase, at: 0)
                dismiss()
            }
            
        } catch {
            await MainActor.run {
                viewModel.handleError(error)
            }
        }
    }
}

// MARK: - 新建案件步骤枚举
enum NewCaseStep: String, CaseIterable {
    case caseTypeSelection = "选择案件类型"
    case basicInformation = "基本信息"
    case aiConsultation = "AI咨询分析"
    case evidenceUpload = "证据上传"
    case workflowConfiguration = "工作流程配置"
    case reviewAndConfirm = "确认创建"
    
    var title: String {
        return self.rawValue
    }
    
    var description: String {
        switch self {
        case .caseTypeSelection:
            return "选择您的案件类型，AI将据此提供专业建议"
        case .basicInformation:
            return "填写案件的基本信息，包括当事人和案件描述"
        case .aiConsultation:
            return "AI将分析您的案件并提供专业咨询建议"
        case .evidenceUpload:
            return "上传相关证据材料，AI将协助分析证据强度"
        case .workflowConfiguration:
            return "配置适合您案件的工作流程类型"
        case .reviewAndConfirm:
            return "确认所有信息并创建完整的案件工作流程"
        }
    }
    
    var icon: String {
        switch self {
        case .caseTypeSelection:
            return "list.bullet.rectangle"
        case .basicInformation:
            return "info.circle"
        case .aiConsultation:
            return "brain.head.profile"
        case .evidenceUpload:
            return "doc.badge.plus"
        case .workflowConfiguration:
            return "flowchart"
        case .reviewAndConfirm:
            return "checkmark.seal"
        }
    }
}

// MARK: - 增强新建案件视图模型
@MainActor
class EnhancedNewCaseViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentStep: NewCaseStep = .caseTypeSelection
    @Published var selectedCaseType: CaseType?
    @Published var caseTitle: String = ""
    @Published var caseDescription: String = ""
    @Published var involvedParties: [CaseParty] = []
    @Published var uploadedDocuments: [UploadedDocument] = []
    @Published var selectedWorkflowType: WorkflowType = .standardLitigation
    @Published var workflowCustomizations: [String: Any] = [:]
    
    @Published var isProcessing = false
    @Published var processingMessage = ""
    @Published var processingDetails = ""
    @Published var showingAIConsultation = false
    
    @Published var aiRecommendations: [CaseTypeRecommendation] = []
    @Published var aiAnalysisResult: AIAnalysisResult?
    @Published var aiConsultationAvailable = false
    
    // MARK: - Private Properties
    private let enhancedWorkflowService = EnhancedWorkflowService.shared
    private let agentService = AgentService.shared
    private let documentService = DocumentGenerationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var currentStepIndex: Int {
        return NewCaseStep.allCases.firstIndex(of: currentStep) ?? 0
    }
    
    var canGoToPreviousStep: Bool {
        return currentStepIndex > 0
    }
    
    var canGoToNextStep: Bool {
        switch currentStep {
        case .caseTypeSelection:
            return selectedCaseType != nil
        case .basicInformation:
            return !caseTitle.isEmpty && !caseDescription.isEmpty
        case .aiConsultation:
            return aiAnalysisResult != nil
        case .evidenceUpload:
            return true // 证据上传是可选的
        case .workflowConfiguration:
            return true
        case .reviewAndConfirm:
            return true
        }
    }
    
    var isLastStep: Bool {
        return currentStep == .reviewAndConfirm
    }
    
    // MARK: - Initialization
    init() {
        setupObservers()
        updateAIConsultationAvailability()
    }
    
    // MARK: - Public Methods
    
    func goToNextStep() {
        guard canGoToNextStep else { return }
        
        if let nextIndex = NewCaseStep.allCases.indices.first(where: { $0 > currentStepIndex }) {
            currentStep = NewCaseStep.allCases[nextIndex]
            performStepTransitionActions()
        }
    }
    
    func goToPreviousStep() {
        guard canGoToPreviousStep else { return }
        
        if let previousIndex = NewCaseStep.allCases.indices.last(where: { $0 < currentStepIndex }) {
            currentStep = NewCaseStep.allCases[previousIndex]
        }
    }
    
    func resetForm() {
        selectedCaseType = nil
        caseTitle = ""
        caseDescription = ""
        involvedParties = []
        uploadedDocuments = []
        selectedWorkflowType = .standardLitigation
        workflowCustomizations = [:]
        aiRecommendations = []
        aiAnalysisResult = nil
        currentStep = .caseTypeSelection
    }
    
    func getAllUserInput() -> [String: Any] {
        var input: [String: Any] = [:]
        
        if let caseType = selectedCaseType {
            input["case_type"] = caseType.rawValue
        }
        input["title"] = caseTitle
        input["description"] = caseDescription
        input["parties"] = involvedParties.map { party in
            [
                "name": party.name,
                "role": party.role.rawValue,
                "contact": party.contactInfo ?? ""
            ]
        }
        input["documents"] = uploadedDocuments.map { $0.name }
        input["workflow_type"] = selectedWorkflowType.rawValue
        
        return input
    }
    
    func applyAIRecommendation(_ recommendation: AIRecommendation) {
        // 应用AI推荐
        switch recommendation.type {
        case .caseTypeChange:
            if let newCaseType = CaseType.allCases.first(where: { $0.rawValue == recommendation.value }) {
                selectedCaseType = newCaseType
            }
        case .workflowTypeChange:
            if let newWorkflowType = WorkflowType.allCases.first(where: { $0.rawValue == recommendation.value }) {
                selectedWorkflowType = newWorkflowType
            }
        case .additionalParties:
            // 添加建议的当事人
            break
        case .documentSuggestion:
            // 提示用户上传建议的文档
            break
        }
    }
    
    func createWorkflow() async throws -> EnhancedCaseWorkflow {
        guard let caseType = selectedCaseType else {
            throw NewCaseError.missingCaseType
        }
        
        isProcessing = true
        processingMessage = "正在创建工作流程..."
        processingDetails = "AI正在为您量身定制专业的法律工作流程"
        
        defer {
            isProcessing = false
            processingMessage = ""
            processingDetails = ""
        }
        
        do {
            // 创建案件ID
            let caseId = UUID().uuidString
            
            // 创建增强工作流程
            let workflow = try await enhancedWorkflowService.createEnhancedWorkflow(
                for: caseId,
                caseType: caseType,
                workflowType: selectedWorkflowType
            )
            
            processingMessage = "工作流程创建完成!"
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒延迟以显示成功消息
            
            return workflow
            
        } catch {
            throw NewCaseError.workflowCreationFailed(error.localizedDescription)
        }
    }
    
    func handleError(_ error: Error) {
        // 处理错误，可以显示错误提示
        print("新建案件错误: \(error.localizedDescription)")
    }
    
    func handleEvidenceUploadUpdate(_ step: EnhancedWorkflowStep) {
        // Handle evidence upload step update
        // Update any necessary state when evidence upload is completed
        if step.status == .completed {
            // Evidence upload is completed, can proceed to next step
            updateAIConsultationAvailability()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // 监听案件类型变化
        $selectedCaseType
            .sink { [weak self] caseType in
                self?.onCaseTypeChanged(caseType)
            }
            .store(in: &cancellables)
        
        // 监听用户输入变化
        Publishers.CombineLatest4($caseTitle, $caseDescription, $selectedCaseType, $involvedParties)
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _, _, _, _ in
                self?.updateAIConsultationAvailability()
                self?.requestAIRecommendationsIfNeeded()
            }
            .store(in: &cancellables)
    }
    
    private func performStepTransitionActions() {
        switch currentStep {
        case .aiConsultation:
            Task {
                await performAIConsultation()
            }
        case .evidenceUpload:
            updateAIConsultationAvailability()
        case .workflowConfiguration:
            generateWorkflowRecommendations()
        default:
            break
        }
    }
    
    private func onCaseTypeChanged(_ caseType: CaseType?) {
        guard let caseType = caseType else { return }
        
        // 根据案件类型推荐工作流程类型
        selectedWorkflowType = recommendWorkflowType(for: caseType)
        
        // 请求AI案件类型建议
        Task {
            await requestCaseTypeRecommendations(for: caseType)
        }
    }
    
    private func updateAIConsultationAvailability() {
        aiConsultationAvailable = selectedCaseType != nil && 
                                 !caseTitle.isEmpty && 
                                 !caseDescription.isEmpty
    }
    
    private func requestAIRecommendationsIfNeeded() {
        guard aiConsultationAvailable else { return }
        
        Task {
            await requestGeneralRecommendations()
        }
    }
    
    private func performAIConsultation() async {
        guard let caseType = selectedCaseType else { return }
        
        isProcessing = true
        processingMessage = "AI正在分析您的案件..."
        processingDetails = "这可能需要几秒钟时间"
        
        do {
            let request = AgentRequest(
                id: UUID().uuidString,
                agentType: .caseAnalyst,
                caseType: caseType,
                content: buildConsultationContent(),
                context: buildConsultationContext(),
                priority: .normal,
                createdAt: Date()
            )
            
            let response = try await agentService.sendRequest(request)
            
            // 处理AI分析结果
            aiAnalysisResult = AIAnalysisResult(
                id: response.id,
                documentType: "初步咨询分析",
                analysisDate: Date(),
                keyFindings: extractKeyFindings(from: response.content),
                suggestedActions: response.recommendations?.map { $0.description } ?? [],
                evidenceStrength: response.confidence,
                riskAssessment: extractRiskAssessment(from: response.content),
                generatedDocument: nil,
                confidence: response.confidence
            )
            
        } catch {
            print("AI咨询失败: \(error.localizedDescription)")
        }
        
        isProcessing = false
        processingMessage = ""
        processingDetails = ""
    }
    
    private func requestCaseTypeRecommendations(for caseType: CaseType) async {
        // 请求案件类型特定的建议
        do {
            let content = "案件类型: \(caseType.rawValue)\n标题: \(caseTitle)\n描述: \(caseDescription)"
            
            let request = AgentRequest(
                id: UUID().uuidString,
                agentType: .legalConsultant,
                caseType: caseType,
                content: content,
                context: nil,
                priority: .low,
                createdAt: Date()
            )
            
            let response = try await agentService.sendRequest(request)
            
            // 处理推荐结果
            aiRecommendations = parseRecommendations(from: response.content)
            
        } catch {
            print("获取推荐失败: \(error.localizedDescription)")
        }
    }
    
    private func requestGeneralRecommendations() async {
        // 请求一般性建议
        // TODO: 实现一般性建议逻辑
    }
    
    private func recommendWorkflowType(for caseType: CaseType) -> WorkflowType {
        switch caseType {
        case .contractDispute, .debtDispute:
            return .standardLitigation
        case .laborDispute:
            return .mediationFirst
        case .divorceDispute:
            return .fastTrackLitigation
        default:
            return .standardLitigation
        }
    }
    
    private func generateWorkflowRecommendations() {
        // 根据当前信息生成工作流程建议
        // TODO: 实现工作流程推荐逻辑
    }
    
    private func buildConsultationContent() -> String {
        var content = "案件基本信息:\n"
        content += "类型: \(selectedCaseType?.rawValue ?? "未知")\n"
        content += "标题: \(caseTitle)\n"
        content += "描述: \(caseDescription)\n"
        
        if !involvedParties.isEmpty {
            content += "\n当事人信息:\n"
            for party in involvedParties {
                content += "- \(party.name) (\(party.role.rawValue))\n"
            }
        }
        
        if !uploadedDocuments.isEmpty {
            content += "\n已上传文档:\n"
            for doc in uploadedDocuments {
                content += "- \(doc.name)\n"
            }
        }
        
        content += "\n请提供专业的法律分析和建议。"
        
        return content
    }
    
    private func buildConsultationContext() -> AgentContext {
        // TODO: 构建更详细的咨询上下文
        return AgentContext(
            caseId: nil,
            userId: UUID().uuidString,
            previousMessages: [],
            caseDetails: nil,
            userPreferences: nil
        )
    }
    
    private func extractKeyFindings(from content: String) -> [String] {
        // 从AI响应中提取关键发现
        let lines = content.components(separatedBy: .newlines)
        return lines.compactMap { line in
            if line.contains("关键") || line.contains("重要") || line.contains("发现") {
                return line.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return nil
        }.prefix(5).map { String($0) }
    }
    
    private func extractRiskAssessment(from content: String) -> String {
        if content.contains("风险") {
            let lines = content.components(separatedBy: .newlines)
            return lines.first { $0.contains("风险") } ?? "需要进一步评估风险"
        }
        return "风险程度待评估"
    }
    
    private func parseRecommendations(from content: String) -> [CaseTypeRecommendation] {
        // 解析AI推荐内容
        // TODO: 实现更复杂的推荐解析逻辑
        return []
    }
}

// MARK: - 错误类型
enum NewCaseError: LocalizedError {
    case missingCaseType
    case workflowCreationFailed(String)
    case aiConsultationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .missingCaseType:
            return "请选择案件类型"
        case .workflowCreationFailed(let message):
            return "工作流程创建失败: \(message)"
        case .aiConsultationFailed(let message):
            return "AI咨询失败: \(message)"
        }
    }
}

// MARK: - 支持类型
struct CaseTypeRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let confidence: Double
    let reasons: [String]
}

struct CaseParty {
    let id = UUID()
    let name: String
    let role: PartyRole
    let contactInfo: String?
    
    enum PartyRole: String, CaseIterable {
        case plaintiff = "原告"
        case defendant = "被告"
        case thirdParty = "第三人"
        case witness = "证人"
        case agent = "代理人"
        case expert = "专家"
    }
}

struct UploadedDocument: Identifiable {
    let id = UUID()
    let name: String
    let size: Int64
    let type: String
    let uploadDate: Date
    let url: URL?
}

struct AIRecommendation {
    let type: RecommendationType
    let title: String
    let description: String
    let value: String
    let confidence: Double
    
    enum RecommendationType {
        case caseTypeChange
        case workflowTypeChange
        case additionalParties
        case documentSuggestion
    }
}

// MARK: - Missing View Components

/// AI咨询视图
struct AIConsultationView: View {
    let caseType: CaseType?
    let currentInput: [String: Any]
    let onRecommendation: (AIRecommendation) -> Void
    
    var body: some View {
        VStack {
            Text("AI咨询功能")
                .font(.title)
            Text("功能开发中...")
                .foregroundColor(.gray)
        }
        .padding()
    }
}

/// 案件类型选择视图
struct CaseTypeSelectionView: View {
    @Binding var selectedCaseType: CaseType?
    let aiRecommendations: [CaseTypeRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("请选择您的案件类型")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(CaseType.allCases, id: \.self) { caseType in
                    Button {
                        selectedCaseType = caseType
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: caseType.icon)
                                .font(.title2)
                            Text(caseType.rawValue)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .foregroundColor(selectedCaseType == caseType ? .white : .white.opacity(0.7))
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedCaseType == caseType ? 
                                     AppTheme.accentColor : 
                                     Color.white.opacity(0.1))
                        )
                    }
                }
            }
        }
        .padding()
    }
}

/// 基本信息视图
struct BasicInformationView: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var parties: [CaseParty]
    let selectedCaseType: CaseType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("请填写案件基本信息")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("案件标题")
                        .foregroundColor(.white.opacity(0.8))
                    TextField("请输入案件标题", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("案件描述")
                        .foregroundColor(.white.opacity(0.8))
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}

/// AI咨询步骤视图
struct AIConsultationStepView: View {
    @ObservedObject var viewModel: EnhancedNewCaseViewModel
    let onStartConsultation: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("AI分析咨询")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            if let analysisResult = viewModel.aiAnalysisResult {
                VStack(alignment: .leading, spacing: 16) {
                    Text("分析结果")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if !analysisResult.keyFindings.isEmpty {
                        Text("关键发现：")
                            .foregroundColor(.white.opacity(0.8))
                        ForEach(analysisResult.keyFindings, id: \.self) { finding in
                            Text("• \(finding)")
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            } else {
                Button(action: onStartConsultation) {
                    Text("开始AI咨询分析")
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
}

/// 工作流程配置视图
struct WorkflowConfigurationView: View {
    @Binding var selectedWorkflowType: WorkflowType
    @Binding var customizations: [String: Any]
    let caseType: CaseType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("选择工作流程类型")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(WorkflowType.allCases, id: \.self) { workflowType in
                    Button {
                        selectedWorkflowType = workflowType
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(workflowType.rawValue)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                if selectedWorkflowType == workflowType {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppTheme.accentColor)
                                }
                            }
                            
                            Text(workflowType.description)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.leading)
                            
                            Text("预计耗时: \(workflowType.estimatedDuration)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedWorkflowType == workflowType ?
                                     Color.white.opacity(0.2) :
                                     Color.white.opacity(0.1))
                        )
                    }
                }
            }
        }
        .padding()
    }
}

/// 确认创建视图
struct ReviewAndConfirmView: View {
    let title: String
    let description: String
    let caseType: CaseType?
    let workflowType: WorkflowType
    let parties: [CaseParty]
    let documents: [UploadedDocument]
    let aiAnalysis: AIAnalysisResult?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("确认案件信息")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                CaseInfoRow(title: "案件标题", value: title)
                CaseInfoRow(title: "案件类型", value: caseType?.rawValue ?? "未选择")
                CaseInfoRow(title: "工作流程", value: workflowType.rawValue)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("案件描述")
                        .font(.subheadline.bold())
                        .foregroundColor(.white.opacity(0.8))
                    Text(description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                if !parties.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("当事人信息")
                            .font(.subheadline.bold())
                            .foregroundColor(.white.opacity(0.8))
                        ForEach(parties, id: \.id) { party in
                            Text("\(party.name) (\(party.role.rawValue))")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                
                if !documents.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("上传文档")
                            .font(.subheadline.bold())
                            .foregroundColor(.white.opacity(0.8))
                        Text("\(documents.count) 个文档")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
    }
}

struct CaseInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value)
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - 预览
#Preview {
    EnhancedNewCaseView()
        .environmentObject(AppViewModel())
}