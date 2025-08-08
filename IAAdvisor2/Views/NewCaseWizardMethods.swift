import SwiftUI

// MARK: - NewCaseWizard 辅助方法

extension NewCaseWizard {
    
    // MARK: - 导航控制
    
    func getNextButtonText() -> String {
        switch currentStep {
        case 0: return caseTitle.isEmpty ? "请输入案件名称" : "下一步"
        case 1: return "下一步"
        case 2: return iaQuestions.isEmpty ? "开始了解基本情况" : (currentQuestionIndex < iaQuestions.count - 1 ? "下一题" : "完成了解")
        case 3: return "下一步"
        case 4: return agentAnalysisResult == nil ? "开始专业分析" : "下一步"
        case 5: return generatedWorkflow.isEmpty ? "生成流程" : "下一步"
        case 6: return "创建案件"
        default: return "下一步"
        }
    }
    
    func canProceed() -> Bool {
        switch currentStep {
        case 0: return !caseTitle.isEmpty
        case 1: return true
        case 2: 
            if iaQuestions.isEmpty {
                return true
            } else {
                return currentQuestionIndex >= iaQuestions.count || !questionAnswers.isEmpty
            }
        case 3: return !caseDescription.isEmpty
        // 步骤5（专业分析）：允许点击“开始专业分析”以启动分析
        case 4: return true
        case 5: return !generatedWorkflow.isEmpty
        case 6: return true
        default: return true
        }
    }
    
    func handleNextStep() {
        switch currentStep {
        case 0:
            // 案件名称 -> 案件类型
            withAnimation {
                currentStep = 1
            }
        case 1:
            // 案件类型 -> 现在让我们来了解一些基本情况
            withAnimation {
                currentStep = 2
            }
        case 2:
            // 基本情况了解逻辑
            if iaQuestions.isEmpty {
                generateIAQuestions()
            } else if currentQuestionIndex < iaQuestions.count - 1 {
                currentQuestionIndex += 1
            } else {
                // 基本情况了解完成，进入描述和文档步骤
                withAnimation {
                    currentStep = 3
                }
            }
        case 3:
            // 案件描述和文档 -> 专业分析
            withAnimation {
                currentStep = 4
            }
        case 4:
            // 专业分析
            if agentAnalysisResult == nil {
                isAnalyzing = true
                startAgentAnalysis()
            } else {
                withAnimation {
                    currentStep = 5
                }
            }
        case 5:
            // 生成案件流程
            if generatedWorkflow.isEmpty {
                isGeneratingWorkflow = true
            } else {
                withAnimation {
                    currentStep = 6
                }
            }
        case 6:
            // 创建案件并完成
            createCaseAndStart()
        default:
            break
        }
    }
    
    // MARK: - 基本情况了解逻辑
    
    func generateIAQuestions() {
        // 根据案件类型生成相应的问题
        let questions: [IAQuestion]
        
        switch selectedCaseType {
        case .contractDispute:
            questions = [
                IAQuestion(
                    id: "contract_1",
                    question: "您与对方签订的合同是什么类型？",
                    options: ["买卖合同", "服务合同", "租赁合同", "其他"]
                ),
                IAQuestion(
                    id: "contract_2", 
                    question: "对方主要违反了哪项义务？",
                    options: ["延迟履行", "质量不符", "完全不履行", "部分履行"]
                ),
                IAQuestion(
                    id: "contract_3",
                    question: "您希望通过什么方式解决？",
                    options: ["要求履行", "解除合同", "赔偿损失", "协商解决"]
                )
            ]
        case .laborDispute:
            questions = [
                IAQuestion(
                    id: "labor_1",
                    question: "您与用人单位的争议主要涉及什么？",
                    options: ["工资待遇", "工作时间", "解除合同", "工伤赔偿"]
                ),
                IAQuestion(
                    id: "labor_2",
                    question: "您与用人单位是否签订了劳动合同？",
                    options: ["已签订书面合同", "口头约定", "没有签订", "不确定"]
                ),
                IAQuestion(
                    id: "labor_3",
                    question: "争议发生多长时间了？",
                    options: ["1个月内", "1-3个月", "3-6个月", "6个月以上"]
                )
            ]
        case .divorceDispute:
            questions = [
                IAQuestion(
                    id: "divorce_1",
                    question: "您希望通过什么方式离婚？",
                    options: ["协议离婚", "诉讼离婚", "还在考虑", "寻求调解"]
                ),
                IAQuestion(
                    id: "divorce_2",
                    question: "主要争议是什么？",
                    options: ["财产分割", "子女抚养", "债务承担", "无争议"]
                ),
                IAQuestion(
                    id: "divorce_3",
                    question: "是否涉及房产争议？",
                    options: ["有房产争议", "无房产", "房产已协商一致", "不确定"]
                )
            ]
        default:
            questions = [
                IAQuestion(
                    id: "general_1", 
                    question: "请问您希望通过法律途径达到什么目标？",
                    options: ["维护权益", "获得赔偿", "解决争议", "寻求建议"]
                ),
                IAQuestion(
                    id: "general_2",
                    question: "您认为这个问题的紧急程度如何？",
                    options: ["非常紧急", "比较紧急", "一般", "不紧急"]
                ),
                IAQuestion(
                    id: "general_3",
                    question: "您之前是否咨询过律师？",
                    options: ["已咨询过", "准备咨询", "没有咨询", "不需要咨询"]
                )
            ]
        }
        
        iaQuestions = questions
        currentQuestionIndex = 0
    }
    
    func selectAnswer(_ answer: String, for question: IAQuestion) {
        questionAnswers[question.id] = answer
    }
    
    func isAnswerSelected(_ answer: String, for question: IAQuestion) -> Bool {
        return questionAnswers[question.id] == answer
    }
    
    // MARK: - Agent分析
    
    func startAgentAnalysis() {
        // 模拟专业分析过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.performAgentAnalysis()
        }
    }
    
    private func performAgentAnalysis() {
        // 基于用户输入进行分析
        let analysis = analyzeCase()
        
        DispatchQueue.main.async {
            self.agentAnalysisResult = analysis
            self.isAnalyzing = false
            // 分析完成后自动进入下一步（流程生成）
            withAnimation {
                self.currentStep = 5
            }
        }
    }
    
    private func analyzeCase() -> AgentAnalysisResult {
        // 根据案件类型和用户回答进行分析
        let strengthLevel: CaseStrengthLevel
        let confidence: Double
        var recommendations: [String] = []
        var risks: [String] = []
        
        // 根据案件类型和回答分析强度
        switch selectedCaseType {
        case .contractDispute:
            strengthLevel = .moderate
            confidence = 0.75
            recommendations = [
                "收集并整理所有相关合同文件",
                "保存与对方的所有沟通记录",
                "计算并评估实际损失金额",
                "考虑先通过协商方式解决争议"
            ]
            risks = [
                "合同条款可能存在模糊之处",
                "举证责任可能较重",
                "诉讼周期可能较长"
            ]
        case .laborDispute:
            strengthLevel = .strong
            confidence = 0.80
            recommendations = [
                "收集劳动关系证明材料",
                "整理工资发放记录",
                "申请劳动仲裁",
                "寻求工会或劳动监察部门支持"
            ]
            risks = [
                "需要证明劳动关系的存在",
                "可能面临用人单位的反驳",
                "仲裁时效需要注意"
            ]
        case .divorceDispute:
            strengthLevel = .moderate
            confidence = 0.70
            recommendations = [
                "整理夫妻共同财产清单",
                "收集子女抚养相关证据",
                "尝试通过调解解决争议",
                "咨询专业婚姻家庭律师"
            ]
            risks = [
                "财产分割可能存在争议",
                "子女抚养权归属需要综合考虑",
                "情感因素可能影响理性判断"
            ]
        default:
            strengthLevel = .moderate
            confidence = 0.65
            recommendations = [
                "详细梳理争议的事实和证据",
                "明确自己的合法权益和诉求",
                "选择适当的解决途径",
                "必要时寻求专业法律援助"
            ]
            risks = [
                "案件情况需要进一步分析",
                "可能需要补充更多证据",
                "解决方案需要根据具体情况调整"
            ]
        }
        
        return AgentAnalysisResult(
            strengthLevel: strengthLevel,
            confidence: confidence,
            recommendations: recommendations,
            risks: risks
        )
    }
    
    // MARK: - 流程生成
    
    func generateWorkflow() {
        // 模拟流程生成过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.createWorkflowSteps()
        }
    }
    
    private func createWorkflowSteps() {
        let steps: [WorkflowStep]
        
        switch selectedCaseType {
        case .contractDispute:
            steps = [
                WorkflowStep(
                    id: "1",
                    title: "合同分析",
                    description: "详细分析合同条款，识别争议焦点和法律依据",
                    status: .pending,
                    date: nil,
                    estimatedDays: 2
                ),
                WorkflowStep(
                    id: "2",
                    title: "证据收集",
                    description: "收集合同履行相关的所有证据材料",
                    status: .pending,
                    date: nil,
                    estimatedDays: 5
                ),
                WorkflowStep(
                    id: "3",
                    title: "损失评估",
                    description: "评估违约造成的实际损失和可能的赔偿金额",
                    status: .pending,
                    date: nil,
                    estimatedDays: 3
                ),
                WorkflowStep(
                    id: "4",
                    title: "协商谈判",
                    description: "与对方进行协商，寻求庭外和解的可能",
                    status: .pending,
                    date: nil,
                    estimatedDays: 7
                ),
                WorkflowStep(
                    id: "5",
                    title: "诉讼准备",
                    description: "如协商无果，准备诉讼相关材料",
                    status: .pending,
                    date: nil,
                    estimatedDays: 10
                ),
                WorkflowStep(
                    id: "6",
                    title: "案件结案",
                    description: "通过判决或和解完成案件",
                    status: .pending,
                    date: nil,
                    estimatedDays: 45
                )
            ]
        case .laborDispute:
            steps = [
                WorkflowStep(
                    id: "1",
                    title: "劳动关系认定",
                    description: "确认与用人单位的劳动关系",
                    status: .pending,
                    date: nil,
                    estimatedDays: 3
                ),
                WorkflowStep(
                    id: "2",
                    title: "证据材料整理",
                    description: "收集工资条、考勤记录等相关证据",
                    status: .pending,
                    date: nil,
                    estimatedDays: 5
                ),
                WorkflowStep(
                    id: "3",
                    title: "申请劳动仲裁",
                    description: "向劳动仲裁委员会提交仲裁申请",
                    status: .pending,
                    date: nil,
                    estimatedDays: 2
                ),
                WorkflowStep(
                    id: "4",
                    title: "仲裁审理",
                    description: "参加仲裁庭审理程序",
                    status: .pending,
                    date: nil,
                    estimatedDays: 30
                ),
                WorkflowStep(
                    id: "5",
                    title: "执行仲裁裁决",
                    description: "如需要，申请法院强制执行",
                    status: .pending,
                    date: nil,
                    estimatedDays: 20
                )
            ]
        default:
            steps = [
                WorkflowStep(
                    id: "1",
                    title: "案件分析",
                    description: "全面分析案件性质和法律关系",
                    status: .pending,
                    date: nil,
                    estimatedDays: 3
                ),
                WorkflowStep(
                    id: "2",
                    title: "证据收集",
                    description: "收集和整理所有相关证据材料",
                    status: .pending,
                    date: nil,
                    estimatedDays: 7
                ),
                WorkflowStep(
                    id: "3",
                    title: "法律研究",
                    description: "研究适用的法律条文和相关判例",
                    status: .pending,
                    date: nil,
                    estimatedDays: 5
                ),
                WorkflowStep(
                    id: "4",
                    title: "策略制定",
                    description: "制定最适合的解决策略",
                    status: .pending,
                    date: nil,
                    estimatedDays: 2
                ),
                WorkflowStep(
                    id: "5",
                    title: "执行实施",
                    description: "按照策略执行相关法律程序",
                    status: .pending,
                    date: nil,
                    estimatedDays: 30
                )
            ]
        }
        
        DispatchQueue.main.async {
            self.generatedWorkflow = steps
            self.isGeneratingWorkflow = false
        }
    }
    
    // MARK: - 案件创建
    
    func createCaseAndStart() {
        // 创建新案件
        let newCase = Case(
            id: UUID().uuidString,
            title: caseTitle,
            description: caseDescription,
            createdAt: Date(),
            lastUpdatedAt: Date(),
            caseType: selectedCaseType,
            status: .active,
            messages: []
        )
        
        // 完成向导
        onComplete(newCase)
        dismiss()
    }
    
    // MARK: - 文档处理
    
    func generateDescriptionFromDocuments() {
        // 模拟从文档生成描述的过程
        guard !uploadedDocuments.isEmpty else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // 这里应该调用实际的文档分析API
            let generatedDescription = self.simulateDocumentAnalysis()
            if self.caseDescription.isEmpty {
                self.caseDescription = generatedDescription
            }
        }
    }
    
    private func simulateDocumentAnalysis() -> String {
        return """
        基于您上传的文档，IA识别出以下关键信息：
        
        • 争议性质：\(selectedCaseType.rawValue)
        • 涉及金额：需要进一步确认
        • 关键时间节点：\(DateFormatter().string(from: Date()))
        • 主要争议点：待详细分析
        
        请您补充更多详细信息以便IA提供更准确的分析。
        """
    }
}

// MARK: - IAQuestion 已在 CommonComponents_backup.swift 中定义，这里不再重复定义