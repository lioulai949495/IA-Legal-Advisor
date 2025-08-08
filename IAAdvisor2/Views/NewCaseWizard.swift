import SwiftUI

// 导入步骤视图和方法扩展
// 这些扩展定义在 NewCaseWizardSteps.swift 和 NewCaseWizardMethods.swift 中

struct NewCaseWizard: View {
    let onComplete: (Case) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State var currentStep = 0
    @State var caseTitle = ""
    @State var selectedCaseCategory: CaseCategory = .civil
    @State var selectedCaseType: CaseType = .contractDispute
    @State var iaQuestions: [IAQuestion] = []
    @State var currentQuestionIndex = 0
    @State var questionAnswers: [String: String] = [:]
    @State var caseDescription = ""
    @State var uploadedDocuments: [DocumentFile] = []
    @State var agentAnalysisResult: AgentAnalysisResult?
    @State var generatedWorkflow: [WorkflowStep] = []
    @State var showingDocumentPicker = false
    @State var showingCaseTypeSelector = false
    @State var isAnalyzing = false
    @State var isGeneratingWorkflow = false
    
    private let totalSteps = 6
    
    var body: some View {
        VStack(spacing: 0) {
            // 进度指示器
            ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor))
                .padding()
            
            // 步骤内容
            TabView(selection: $currentStep) {
                // 步骤1：案件名称
                caseTitleStep
                    .tag(0)
                
                // 步骤2：案件类型
                caseTypeStep
                    .tag(1)
                
                // 步骤3：现在让我们来了解一些基本情况
                iaQuestionStep
                    .tag(2)
                
                // 步骤4：案件描述和相关文档
                descriptionAndDocumentsStep
                    .tag(3)
                
                // 步骤5：专业分析结果
                agentAnalysisStep
                    .tag(4)
                
                // 步骤6：开始执行流程（跳过原“生成流程”）
                startExecutionStep
                    .tag(5)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .allowsHitTesting(true)
            
            // 底部按钮
            HStack {
                if currentStep == 0 {
                    // 第一步显示取消按钮
                    Button("取消") {
                        dismiss()
                    }
                    .secondaryButtonStyle()
                } else if currentStep > 0 {
                    // 后续步骤显示上一步按钮
                    Button("上一步") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .secondaryButtonStyle()
                }
                
                Spacer()
                
                Button(getNextButtonText()) {
                    handleNextStep()
                }
                .primaryButtonStyle()
                .disabled(!canProceed())
            }
            .padding()
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker { documents in
                uploadedDocuments.append(contentsOf: documents)
                generateDescriptionFromDocuments()
                // 选择完成后，直接跳到下一步（专业分析）
                withAnimation {
                    currentStep = 4
                }
            }
        }
        .sheet(isPresented: $showingCaseTypeSelector) {
            CaseTypeSelector(
                selectedCategory: $selectedCaseCategory,
                selectedType: $selectedCaseType
            )
        }
    }
}

#Preview {
    NewCaseWizard { _ in }
        .environmentObject(AppViewModel())
}