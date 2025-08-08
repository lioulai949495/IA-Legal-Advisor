import Foundation
import SwiftUI

/// 案件流程服务
@MainActor
class CaseWorkflowService: ObservableObject {
    @Published var currentWorkflow: [EnhancedWorkflowStep] = []
    @Published var selectedStep: EnhancedWorkflowStep?
    @Published var isLoading = false
    
    /// 生成标准案件流程
    func generateWorkflow(for caseType: CaseType) -> [EnhancedWorkflowStep] {
        switch caseType {
        case .contractDispute, .tradingDispute, .propertyDispute, .laborDispute:
            return generateCivilLitigationWorkflow(caseType: caseType)
        case .divorceDispute:
            return generateDivorceWorkflow()
        case .debtDispute:
            return generateDebtRecoveryWorkflow()
        default:
            return generateGeneralWorkflow(caseType: caseType)
        }
    }
    
    /// 生成民事诉讼标准流程
    private func generateCivilLitigationWorkflow(caseType: CaseType) -> [EnhancedWorkflowStep] {
        return [
            // 步骤1：案件分析结果
            createAnalysisStep(for: caseType),
            
            // 步骤2：向法院提起诉讼
            createLitigationStep(for: caseType),
            
            // 步骤3：准备证据及答辩文书
            createEvidencePreparationStep(for: caseType),
            
            // 步骤4：上传判决书进一步分析
            createJudgmentAnalysisStep()
        ]
    }
    
    /// 创建案件分析步骤
    private func createAnalysisStep(for caseType: CaseType) -> EnhancedWorkflowStep {
        return EnhancedWorkflowStep(
            id: "analysis-1",
            title: "案件分析结果",
            description: "基于您提供的信息，AI已完成初步分析，为您制定专业的诉讼策略。",
            status: .completed,
            date: Date(),
            estimatedDays: 0,
            stepType: .analysis,
            actionGuide: ActionGuide(
                title: "查看分析结果",
                steps: [
                    ActionStep(
                        id: "analysis-review",
                        title: "审阅AI分析报告",
                        description: "仔细阅读分析报告，了解案件强度、胜诉概率和风险评估",
                        order: 1,
                        isRequired: true,
                        estimatedMinutes: 15,
                        relatedDocuments: [],
                        signatureRequired: false,
                        sealRequired: false,
                        signatureInstructions: nil
                    ),
                    ActionStep(
                        id: "strategy-confirm",
                        title: "确认诉讼策略",
                        description: "根据分析结果确认是否继续诉讼程序",
                        order: 2,
                        isRequired: true,
                        estimatedMinutes: 10,
                        relatedDocuments: [],
                        signatureRequired: false,
                        sealRequired: false,
                        signatureInstructions: nil
                    )
                ],
                tips: [
                    "请仔细阅读风险提示，充分了解诉讼的时间成本和经济成本",
                    "如对分析结果有疑问，可咨询专业律师获得第二意见",
                    "建议保存分析报告作为后续参考"
                ],
                warnings: [
                    "诉讼存在败诉风险，请谨慎评估",
                    "诉讼费用可能超过预期，请做好资金准备"
                ],
                estimatedTime: "30分钟",
                difficulty: .easy
            ),
            requiredDocuments: [],
            legalNotices: [
                LegalNotice(
                    id: "analysis-notice-1",
                    title: "诉讼风险提示",
                    content: "根据《民事诉讼法》相关规定，诉讼当事人应当承担相应的诉讼风险，包括但不限于败诉风险、诉讼费用风险等。",
                    noticeType: .responsibility,
                    severity: .warning,
                    relatedLaws: ["《民事诉讼法》第13条"],
                    consequences: "如败诉，可能需要承担对方的诉讼费用"
                )
            ]
        )
    }
    
    /// 创建诉讼步骤
    private func createLitigationStep(for caseType: CaseType) -> EnhancedWorkflowStep {
        let litigationDocuments = createLitigationDocuments(for: caseType)
        
        return EnhancedWorkflowStep(
            id: "litigation-2",
            title: "向法院提起诉讼",
            description: "准备起诉状和相关材料，向有管辖权的法院提起诉讼。可选择诉前保全对方账户。",
            status: .pending,
            date: nil,
            estimatedDays: 7,
            stepType: .litigation,
            actionGuide: ActionGuide(
                title: "诉讼提起指南",
                steps: [
                    ActionStep(
                        id: "court-selection",
                        title: "确定管辖法院",
                        description: "根据案件性质和争议金额确定有管辖权的人民法院",
                        order: 1,
                        isRequired: true,
                        estimatedMinutes: 30,
                        relatedDocuments: ["jurisdiction-guide"],
                        signatureRequired: false,
                        sealRequired: false,
                        signatureInstructions: nil
                    ),
                    ActionStep(
                        id: "complaint-preparation",
                        title: "准备起诉状",
                        description: "下载起诉状模板，按要求填写完整信息",
                        order: 2,
                        isRequired: true,
                        estimatedMinutes: 120,
                        relatedDocuments: ["complaint-template"],
                        signatureRequired: true,
                        sealRequired: false,
                        signatureInstructions: "在起诉状末尾'起诉人'处签署姓名和日期"
                    ),
                    ActionStep(
                        id: "evidence-list",
                        title: "制作证据清单",
                        description: "列出所有支持诉讼请求的证据材料",
                        order: 3,
                        isRequired: true,
                        estimatedMinutes: 60,
                        relatedDocuments: ["evidence-list-template"],
                        signatureRequired: true,
                        sealRequired: false,
                        signatureInstructions: "在证据清单末尾签名确认"
                    ),
                    ActionStep(
                        id: "court-submission",
                        title: "向法院提交材料",
                        description: "携带所有材料到法院立案庭提交",
                        order: 4,
                        isRequired: true,
                        estimatedMinutes: 60,
                        relatedDocuments: ["submission-checklist"],
                        signatureRequired: false,
                        sealRequired: false,
                        signatureInstructions: nil
                    ),
                    ActionStep(
                        id: "fee-payment",
                        title: "缴纳诉讼费",
                        description: "根据法院通知缴纳案件受理费",
                        order: 5,
                        isRequired: true,
                        estimatedMinutes: 30,
                        relatedDocuments: ["fee-calculation"],
                        signatureRequired: false,
                        sealRequired: false,
                        signatureInstructions: nil
                    )
                ],
                tips: [
                    "起诉状应当使用A4纸打印，字体为宋体小四号",
                    "证据材料需要提供原件和复印件",
                    "建议提前电话咨询法院立案时间和要求",
                    "保留好缴费凭证和立案回执"
                ],
                warnings: [
                    "起诉状内容必须真实，虚假起诉承担法律责任",
                    "逾期不缴纳诉讼费将被视为撤回起诉"
                ],
                estimatedTime: "1-2工作日",
                difficulty: .medium
            ),
            requiredDocuments: litigationDocuments,
            legalNotices: [
                LegalNotice(
                    id: "litigation-notice-1",
                    title: "诉讼费用承担",
                    content: "根据《诉讼费用交纳办法》规定，案件受理费由败诉方承担，胜诉方垫付。",
                    noticeType: .cost,
                    severity: .info,
                    relatedLaws: ["《诉讼费用交纳办法》第29条"],
                    consequences: "胜诉后可向败诉方追讨诉讼费用"
                ),
                LegalNotice(
                    id: "litigation-notice-2",
                    title: "举证责任",
                    content: "当事人对自己提出的诉讼请求所依据的事实有责任提供证据加以证明。",
                    noticeType: .obligation,
                    severity: .critical,
                    relatedLaws: ["《民事诉讼法》第64条"],
                    consequences: "举证不能将承担败诉后果"
                )
            ],
            allowsCustomSubsteps: true
        )
    }
    
    /// 创建证据准备步骤
    private func createEvidencePreparationStep(for caseType: CaseType) -> EnhancedWorkflowStep {
        let evidenceDocuments = createEvidenceDocuments(for: caseType)
        
        return EnhancedWorkflowStep(
            id: "evidence-3",
            title: "准备证据及答辩文书",
            description: "收集整理证据材料，通过AI分析生成答辩文书。建议对重要证据进行公证。",
            status: .pending,
            date: nil,
            estimatedDays: 14,
            stepType: .evidencePreparation,
            actionGuide: ActionGuide(
                title: "证据准备指南",
                steps: [
                    ActionStep(
                        id: "evidence-collection",
                        title: "收集证据材料",
                        description: "按照证据清单收集所有相关证据",
                        order: 1,
                        isRequired: true,
                        estimatedMinutes: 180,
                        relatedDocuments: ["evidence-checklist"],
                        signatureRequired: false,
                        sealRequired: false,
                        signatureInstructions: nil
                    ),
                    ActionStep(
                        id: "evidence-upload",
                        title: "上传证据进行AI分析",
                        description: "将证据材料上传至系统进行AI智能分析",
                        order: 2,
                        isRequired: true,
                        estimatedMinutes: 60,
                        relatedDocuments: [],
                        signatureRequired: false,
                        sealRequired: false,
                        signatureInstructions: nil
                    ),
                    ActionStep(
                        id: "defense-generation",
                        title: "生成答辩文书",
                        description: "基于AI分析结果自动生成专业答辩文书",
                        order: 3,
                        isRequired: true,
                        estimatedMinutes: 30,
                        relatedDocuments: ["defense-template"],
                        signatureRequired: true,
                        sealRequired: false,
                        signatureInstructions: "在答辩状末尾签名并写明日期"
                    ),
                    ActionStep(
                        id: "notarization-consider",
                        title: "考虑证据公证",
                        description: "对关键证据材料进行公证以增强证明力",
                        order: 4,
                        isRequired: false,
                        estimatedMinutes: 240,
                        relatedDocuments: ["notarization-guide"],
                        signatureRequired: true,
                        sealRequired: false,
                        signatureInstructions: "在公证申请书上签名"
                    )
                ],
                tips: [
                    "证据材料应当真实、完整，避免伪造或篡改",
                    "电子证据建议进行公证或第三方存证",
                    "重要证据建议多份备份保存",
                    "公证虽非必需但可大幅提升证据效力"
                ],
                warnings: [
                    "提供虚假证据将承担法律责任",
                    "证据材料一旦提交难以撤回或修改"
                ],
                estimatedTime: "1-2周",
                difficulty: .medium
            ),
            requiredDocuments: evidenceDocuments,
            legalNotices: [
                LegalNotice(
                    id: "evidence-notice-1",
                    title: "证据真实性要求",
                    content: "当事人应当提供真实证据，不得伪造、篡改证据。",
                    noticeType: .obligation,
                    severity: .critical,
                    relatedLaws: ["《民事诉讼法》第65条"],
                    consequences: "提供虚假证据将被法院训诫、罚款，构成犯罪的追究刑事责任"
                ),
                LegalNotice(
                    id: "evidence-notice-2",
                    title: "公证费用说明",
                    content: "公证费用根据公证事项的性质、复杂程度等因素确定，一般在200-2000元不等。",
                    noticeType: .cost,
                    severity: .info,
                    relatedLaws: ["《公证法》", "《公证收费标准》"],
                    consequences: "公证费用由申请人承担"
                )
            ]
        )
    }
    
    /// 创建判决书分析步骤
    private func createJudgmentAnalysisStep() -> EnhancedWorkflowStep {
        return EnhancedWorkflowStep(
            id: "judgment-4",
            title: "上传判决书进一步分析",
            description: "上传一审判决书，AI将分析判决结果并建议后续行动方案。",
            status: .pending,
            date: nil,
            estimatedDays: 1,
            stepType: .judgmentAnalysis,
            actionGuide: ActionGuide(
                title: "判决书分析指南",
                steps: [
                    ActionStep(
                        id: "judgment-upload",
                        title: "上传判决书",
                        description: "将一审判决书完整上传至系统",
                        order: 1,
                        isRequired: true,
                        estimatedMinutes: 10,
                        relatedDocuments: [],
                        signatureRequired: false,
                        sealRequired: false,
                        signatureInstructions: nil
                    ),
                    ActionStep(
                        id: "ai-analysis",
                        title: "获取AI分析",
                        description: "系统将自动分析判决书内容并生成分析报告",
                        order: 2,
                        isRequired: true,
                        estimatedMinutes: 5,
                        relatedDocuments: [],
                        signatureRequired: false,
                        sealRequired: false,
                        signatureInstructions: nil
                    ),
                    ActionStep(
                        id: "next-step-decision",
                        title: "决定后续行动",
                        description: "根据分析结果选择二审、执行、再审或结案",
                        order: 3,
                        isRequired: true,
                        estimatedMinutes: 30,
                        relatedDocuments: [],
                        signatureRequired: false,
                        sealRequired: false,
                        signatureInstructions: nil
                    )
                ],
                tips: [
                    "请确保上传的判决书清晰完整",
                    "AI分析报告将帮助您了解判决的优劣势",
                    "建议在上诉期限内尽快做出决定"
                ],
                warnings: [
                    "二审上诉期限为判决书送达之日起15日内",
                    "逾期将无法提起上诉"
                ],
                estimatedTime: "1小时",
                difficulty: .easy
            ),
            requiredDocuments: [
                RequiredDocument(
                    id: "judgment-doc",
                    name: "一审判决书",
                    description: "完整的一审民事判决书",
                    isRequired: true,
                    template: nil,
                    sampleDocument: nil,
                    submissionDeadline: nil,
                    submissionMethod: .online
                )
            ],
            legalNotices: [
                LegalNotice(
                    id: "judgment-notice-1",
                    title: "上诉期限",
                    content: "不服一审判决的，可在判决书送达之日起15日内向上一级法院提起上诉。",
                    noticeType: .deadline,
                    severity: .critical,
                    relatedLaws: ["《民事诉讼法》第164条"],
                    consequences: "逾期上诉将丧失二审机会"
                )
            ],
            allowsCustomSubsteps: true
        )
    }
    
    /// 创建诉讼相关文档
    private func createLitigationDocuments(for caseType: CaseType) -> [RequiredDocument] {
        let caseTypeName = getCaseTypeName(caseType)
        
        return [
            RequiredDocument(
                id: "complaint-template",
                name: "起诉状模板",
                description: "\(caseTypeName)起诉状标准模板",
                isRequired: true,
                template: DocumentTemplate(
                    id: "complaint-template-\(caseType.rawValue)",
                    name: "\(caseTypeName)起诉状",
                    downloadUrl: "/templates/complaint_\(caseType.rawValue).pdf",
                    fillableFields: createComplaintFields(),
                    instructions: "请按要求填写所有必填项，在指定位置签名",
                    fileFormat: "PDF"
                ),
                sampleDocument: SampleDocument(
                    id: "complaint-sample",
                    name: "起诉状填写样表",
                    previewUrl: "/samples/complaint_sample.pdf",
                    downloadUrl: "/samples/complaint_sample.pdf",
                    description: "标准的起诉状填写示例",
                    annotations: [
                        DocumentAnnotation(
                            id: "signature-area",
                            x: 0.7, y: 0.85, width: 0.2, height: 0.05,
                            content: "在此处签名并写明日期",
                            annotationType: .signature
                        )
                    ]
                ),
                submissionDeadline: nil,
                submissionMethod: .offline
            ),
            RequiredDocument(
                id: "evidence-list",
                name: "证据清单",
                description: "所有证据材料的详细清单",
                isRequired: true,
                template: DocumentTemplate(
                    id: "evidence-list-template",
                    name: "证据清单模板",
                    downloadUrl: "/templates/evidence_list.pdf",
                    fillableFields: createEvidenceListFields(),
                    instructions: "按序号列出所有证据，注明证据类型和证明目的",
                    fileFormat: "PDF"
                ),
                sampleDocument: nil,
                submissionDeadline: nil,
                submissionMethod: .offline
            ),
            RequiredDocument(
                id: "id-copy",
                name: "身份证复印件",
                description: "起诉人身份证正反面复印件",
                isRequired: true,
                template: nil,
                sampleDocument: nil,
                submissionDeadline: nil,
                submissionMethod: .offline
            )
        ]
    }
    
    /// 创建证据相关文档
    private func createEvidenceDocuments(for caseType: CaseType) -> [RequiredDocument] {
        return [
            RequiredDocument(
                id: "evidence-checklist",
                name: "证据收集清单",
                description: "详细的证据收集指南",
                isRequired: true,
                template: nil,
                sampleDocument: SampleDocument(
                    id: "evidence-guide",
                    name: "证据收集指南",
                    previewUrl: "/guides/evidence_collection.pdf",
                    downloadUrl: "/guides/evidence_collection.pdf",
                    description: "如何有效收集和整理证据材料",
                    annotations: []
                ),
                submissionDeadline: nil,
                submissionMethod: .both
            ),
            RequiredDocument(
                id: "notarization-application",
                name: "公证申请书",
                description: "证据公证申请表格",
                isRequired: false,
                template: DocumentTemplate(
                    id: "notarization-template",
                    name: "公证申请书模板",
                    downloadUrl: "/templates/notarization_application.pdf",
                    fillableFields: createNotarizationFields(),
                    instructions: "填写公证事项，在申请人处签名",
                    fileFormat: "PDF"
                ),
                sampleDocument: nil,
                submissionDeadline: nil,
                submissionMethod: .offline
            )
        ]
    }
    
    /// 创建起诉状填写字段
    private func createComplaintFields() -> [FillableField] {
        return [
            FillableField(id: "plaintiff-name", fieldName: "原告姓名", fieldType: .text, isRequired: true, placeholder: "请输入完整姓名", validationRules: ["非空"], signatureField: false, sealField: false),
            FillableField(id: "defendant-name", fieldName: "被告姓名", fieldType: .text, isRequired: true, placeholder: "请输入被告完整姓名", validationRules: ["非空"], signatureField: false, sealField: false),
            FillableField(id: "claim-amount", fieldName: "诉讼请求金额", fieldType: .number, isRequired: true, placeholder: "请输入金额", validationRules: ["大于0"], signatureField: false, sealField: false),
            FillableField(id: "plaintiff-signature", fieldName: "原告签名", fieldType: .signature, isRequired: true, placeholder: "", validationRules: [], signatureField: true, sealField: false)
        ]
    }
    
    /// 创建证据清单字段
    private func createEvidenceListFields() -> [FillableField] {
        return [
            FillableField(id: "evidence-1", fieldName: "证据1", fieldType: .text, isRequired: true, placeholder: "证据名称", validationRules: [], signatureField: false, sealField: false),
            FillableField(id: "evidence-type-1", fieldName: "证据类型1", fieldType: .text, isRequired: true, placeholder: "书证/物证/视听资料等", validationRules: [], signatureField: false, sealField: false),
            FillableField(id: "evidence-purpose-1", fieldName: "证明目的1", fieldType: .text, isRequired: true, placeholder: "证明事实", validationRules: [], signatureField: false, sealField: false)
        ]
    }
    
    /// 创建公证申请字段
    private func createNotarizationFields() -> [FillableField] {
        return [
            FillableField(id: "applicant-name", fieldName: "申请人", fieldType: .text, isRequired: true, placeholder: "姓名", validationRules: ["非空"], signatureField: false, sealField: false),
            FillableField(id: "notarization-item", fieldName: "公证事项", fieldType: .text, isRequired: true, placeholder: "请填写公证内容", validationRules: ["非空"], signatureField: false, sealField: false),
            FillableField(id: "applicant-signature", fieldName: "申请人签名", fieldType: .signature, isRequired: true, placeholder: "", validationRules: [], signatureField: true, sealField: false)
        ]
    }
    
    /// 获取案件类型中文名称
    private func getCaseTypeName(_ caseType: CaseType) -> String {
        return caseType.rawValue
    }
    
    /// 添加自定义步骤
    func addCustomStep(after stepId: String, stepType: CaseWorkflowStepType) {
        guard let index = currentWorkflow.firstIndex(where: { $0.id == stepId }) else { return }
        
        let customStep = createCustomStep(stepType: stepType, order: index + 1)
        currentWorkflow.insert(customStep, at: index + 1)
    }
    
    /// 创建自定义步骤
    private func createCustomStep(stepType: CaseWorkflowStepType, order: Int) -> EnhancedWorkflowStep {
        switch stepType {
        case .secondTrial:
            return createSecondTrialStep(order: order)
        case .execution:
            return createExecutionStep(order: order)
        case .retrial:
            return createRetrialStep(order: order)
        case .caseClose:
            return createCaseCloseStep(order: order)
        default:
            return createGenericCustomStep(stepType: stepType, order: order)
        }
    }
    
    /// 创建二审步骤
    private func createSecondTrialStep(order: Int) -> EnhancedWorkflowStep {
        return EnhancedWorkflowStep(
            id: "second-trial-\(order)",
            title: "二审程序",
            description: "不服一审判决，向上级法院提起上诉。",
            status: .pending,
            date: nil,
            estimatedDays: 90,
            stepType: .secondTrial,
            actionGuide: ActionGuide(
                title: "二审上诉指南",
                steps: [
                    ActionStep(
                        id: "appeal-preparation",
                        title: "准备上诉状",
                        description: "起草上诉状，说明上诉理由和请求",
                        order: 1,
                        isRequired: true,
                        estimatedMinutes: 120,
                        relatedDocuments: ["appeal-template"],
                        signatureRequired: true,
                        sealRequired: false,
                        signatureInstructions: "在上诉状末尾签名并注明日期"
                    ),
                    ActionStep(
                        id: "appeal-submission",
                        title: "提交上诉材料",
                        description: "在上诉期限内向一审法院或二审法院提交上诉状",
                        order: 2,
                        isRequired: true,
                        estimatedMinutes: 60,
                        relatedDocuments: ["appeal-checklist"],
                        signatureRequired: false,
                        sealRequired: false,
                        signatureInstructions: nil
                    )
                ],
                tips: [
                    "上诉期限为一审判决送达之日起15日内",
                    "上诉状应当说明具体的上诉理由",
                    "二审一般不开庭审理，主要进行书面审理"
                ],
                warnings: [
                    "逾期上诉将无法获得二审机会",
                    "恶意上诉可能被法院驳回并承担费用"
                ],
                estimatedTime: "3-6个月",
                difficulty: .hard
            ),
            requiredDocuments: createSecondTrialDocuments(),
            legalNotices: [
                LegalNotice(
                    id: "second-trial-notice",
                    title: "二审审理程序",
                    content: "二审法院对上诉案件，应当组成合议庭，开庭审理。经过阅卷、调查和询问当事人，对没有提出新的事实、证据或者理由，合议庭认为不需要开庭审理的，可以不开庭审理。",
                    noticeType: .procedure,
                    severity: .info,
                    relatedLaws: ["《民事诉讼法》第169条"],
                    consequences: "二审判决为终审判决，一般不可再上诉"
                )
            ],
            isCustomStep: true
        )
    }
    
    /// 创建申请执行步骤
    private func createExecutionStep(order: Int) -> EnhancedWorkflowStep {
        return EnhancedWorkflowStep(
            id: "execution-\(order)",
            title: "申请执行",
            description: "判决生效后，对方未履行义务的，申请法院强制执行。",
            status: .pending,
            date: nil,
            estimatedDays: 30,
            stepType: .execution,
            actionGuide: ActionGuide(
                title: "申请执行指南",
                steps: [
                    ActionStep(
                        id: "execution-application",
                        title: "提交执行申请",
                        description: "向一审法院提交执行申请书",
                        order: 1,
                        isRequired: true,
                        estimatedMinutes: 60,
                        relatedDocuments: ["execution-application-template"],
                        signatureRequired: true,
                        sealRequired: false,
                        signatureInstructions: "在申请书末尾签名"
                    ),
                    ActionStep(
                        id: "property-investigation",
                        title: "协助财产调查",
                        description: "向法院提供被执行人的财产线索",
                        order: 2,
                        isRequired: true,
                        estimatedMinutes: 120,
                        relatedDocuments: ["property-clues"],
                        signatureRequired: false,
                        sealRequired: false,
                        signatureInstructions: nil
                    )
                ],
                tips: [
                    "执行申请应在判决生效后2年内提出",
                    "提供详细的财产线索有助于执行成功",
                    "可申请财产保全措施"
                ],
                warnings: [
                    "超过申请期限将丧失申请权",
                    "被执行人无财产可供执行的，可能执行不能"
                ],
                estimatedTime: "6个月-2年",
                difficulty: .medium
            ),
            requiredDocuments: createExecutionDocuments(),
            legalNotices: [
                LegalNotice(
                    id: "execution-notice",
                    title: "执行申请期限",
                    content: "申请执行的期间为二年。申请执行时效的中止、中断，适用法律有关诉讼时效中止、中断的规定。",
                    noticeType: .deadline,
                    severity: .warning,
                    relatedLaws: ["《民事诉讼法》第239条"],
                    consequences: "超过期限将无法申请强制执行"
                )
            ],
            isCustomStep: true
        )
    }
    
    /// 创建再审步骤
    private func createRetrialStep(order: Int) -> EnhancedWorkflowStep {
        return EnhancedWorkflowStep(
            id: "retrial-\(order)",
            title: "申请再审",
            description: "对已生效判决申请再审，需要符合法定再审事由。",
            status: .pending,
            date: nil,
            estimatedDays: 180,
            stepType: .retrial,
            actionGuide: ActionGuide(
                title: "申请再审指南",
                steps: [
                    ActionStep(
                        id: "retrial-grounds",
                        title: "确认再审事由",
                        description: "确认是否符合《民事诉讼法》规定的再审事由",
                        order: 1,
                        isRequired: true,
                        estimatedMinutes: 60,
                        relatedDocuments: ["retrial-grounds-guide"],
                        signatureRequired: false,
                        sealRequired: false,
                        signatureInstructions: nil
                    ),
                    ActionStep(
                        id: "retrial-application",
                        title: "提交再审申请",
                        description: "向上级法院提交再审申请书",
                        order: 2,
                        isRequired: true,
                        estimatedMinutes: 180,
                        relatedDocuments: ["retrial-application-template"],
                        signatureRequired: true,
                        sealRequired: false,
                        signatureInstructions: "在申请书署名处签名"
                    )
                ],
                tips: [
                    "再审申请期限为判决生效后6个月内",
                    "必须有明确的法定再审事由",
                    "再审成功率较低，需慎重考虑"
                ],
                warnings: [
                    "不符合再审条件的申请将被驳回",
                    "恶意申请再审可能承担费用"
                ],
                estimatedTime: "6个月-1年",
                difficulty: .hard
            ),
            requiredDocuments: createRetrialDocuments(),
            legalNotices: [
                LegalNotice(
                    id: "retrial-notice",
                    title: "再审事由限制",
                    content: "当事人申请再审，应当符合《民事诉讼法》第200条规定的事由。",
                    noticeType: .procedure,
                    severity: .critical,
                    relatedLaws: ["《民事诉讼法》第200条"],
                    consequences: "不符合法定事由的再审申请将被驳回"
                )
            ],
            isCustomStep: true
        )
    }
    
    /// 创建结案步骤
    private func createCaseCloseStep(order: Int) -> EnhancedWorkflowStep {
        return EnhancedWorkflowStep(
            id: "case-close-\(order)",
            title: "结案",
            description: "案件处理完毕，整理归档相关材料。",
            status: .pending,
            date: nil,
            estimatedDays: 1,
            stepType: .caseClose,
            actionGuide: ActionGuide(
                title: "结案处理指南",
                steps: [
                    ActionStep(
                        id: "document-archive",
                        title: "整理归档",
                        description: "整理所有案件相关材料进行归档保存",
                        order: 1,
                        isRequired: true,
                        estimatedMinutes: 60,
                        relatedDocuments: ["archive-checklist"],
                        signatureRequired: false,
                        sealRequired: false,
                        signatureInstructions: nil
                    ),
                    ActionStep(
                        id: "case-summary",
                        title: "案件总结",
                        description: "总结案件处理过程和结果，积累经验",
                        order: 2,
                        isRequired: false,
                        estimatedMinutes: 30,
                        relatedDocuments: [],
                        signatureRequired: false,
                        sealRequired: false,
                        signatureInstructions: nil
                    )
                ],
                tips: [
                    "重要材料建议长期保存",
                    "总结经验有助于处理类似案件"
                ],
                warnings: [],
                estimatedTime: "1-2小时",
                difficulty: .easy
            ),
            requiredDocuments: [],
            legalNotices: [],
            isCustomStep: true
        )
    }
    
    /// 创建通用自定义步骤
    private func createGenericCustomStep(stepType: CaseWorkflowStepType, order: Int) -> EnhancedWorkflowStep {
        return EnhancedWorkflowStep(
            id: "\(stepType.rawValue)-\(order)",
            title: stepType.rawValue,
            description: "用户自定义的案件处理步骤",
            status: .pending,
            date: nil,
            estimatedDays: 7,
            stepType: stepType,
            actionGuide: ActionGuide(
                title: "自定义步骤指南",
                steps: [],
                tips: [],
                warnings: [],
                estimatedTime: "待定",
                difficulty: .medium
            ),
            requiredDocuments: [],
            legalNotices: [],
            isCustomStep: true
        )
    }
    
    // MARK: - 辅助方法
    
    /// 创建二审相关文档
    private func createSecondTrialDocuments() -> [RequiredDocument] {
        return [
            RequiredDocument(
                id: "appeal-template",
                name: "上诉状模板",
                description: "二审上诉状标准模板",
                isRequired: true,
                template: DocumentTemplate(
                    id: "appeal-template",
                    name: "上诉状",
                    downloadUrl: "/templates/appeal_petition.pdf",
                    fillableFields: [],
                    instructions: "详细说明上诉理由和请求",
                    fileFormat: "PDF"
                ),
                sampleDocument: nil,
                submissionDeadline: nil,
                submissionMethod: .offline
            )
        ]
    }
    
    /// 创建执行相关文档
    private func createExecutionDocuments() -> [RequiredDocument] {
        return [
            RequiredDocument(
                id: "execution-application-template",
                name: "执行申请书模板",
                description: "强制执行申请书模板",
                isRequired: true,
                template: DocumentTemplate(
                    id: "execution-application",
                    name: "执行申请书",
                    downloadUrl: "/templates/execution_application.pdf",
                    fillableFields: [],
                    instructions: "详细说明执行请求和理由",
                    fileFormat: "PDF"
                ),
                sampleDocument: nil,
                submissionDeadline: nil,
                submissionMethod: .offline
            )
        ]
    }
    
    /// 创建再审相关文档
    private func createRetrialDocuments() -> [RequiredDocument] {
        return [
            RequiredDocument(
                id: "retrial-application-template",
                name: "再审申请书模板",
                description: "民事再审申请书模板",
                isRequired: true,
                template: DocumentTemplate(
                    id: "retrial-application",
                    name: "再审申请书",
                    downloadUrl: "/templates/retrial_application.pdf",
                    fillableFields: [],
                    instructions: "明确说明再审事由和依据",
                    fileFormat: "PDF"
                ),
                sampleDocument: nil,
                submissionDeadline: nil,
                submissionMethod: .offline
            )
        ]
    }
    
    // MARK: - 其他流程生成方法
    
    private func generateDivorceWorkflow() -> [EnhancedWorkflowStep] {
        // 离婚案件特殊流程
        return generateCivilLitigationWorkflow(caseType: .divorceDispute)
    }
    
    private func generateDebtRecoveryWorkflow() -> [EnhancedWorkflowStep] {
        // 债务纠纷特殊流程（可包含诉前保全）
        var workflow = generateCivilLitigationWorkflow(caseType: .debtDispute)
        
        // 在诉讼步骤后插入诉前保全选项
        let preservationStep = createPreTrialPreservationStep()
        workflow.insert(preservationStep, at: 2)
        
        return workflow
    }
    
    private func generateGeneralWorkflow(caseType: CaseType) -> [EnhancedWorkflowStep] {
        return generateCivilLitigationWorkflow(caseType: caseType)
    }
    
    /// 创建诉前保全步骤
    private func createPreTrialPreservationStep() -> EnhancedWorkflowStep {
        return EnhancedWorkflowStep(
            id: "preservation-optional",
            title: "诉前财产保全（可选）",
            description: "为防止对方转移财产，可在起诉前申请财产保全。需要提供担保。",
            status: .pending,
            date: nil,
            estimatedDays: 3,
            stepType: .preTrialPreservation,
            actionGuide: ActionGuide(
                title: "诉前保全申请指南",
                steps: [
                    ActionStep(
                        id: "asset-evaluation",
                        title: "评估保全标的",
                        description: "确定需要保全的财产类型和价值",
                        order: 1,
                        isRequired: true,
                        estimatedMinutes: 60,
                        relatedDocuments: ["asset-evaluation-guide"],
                        signatureRequired: false,
                        sealRequired: false,
                        signatureInstructions: nil
                    ),
                    ActionStep(
                        id: "security-arrangement",
                        title: "安排担保",
                        description: "提供相应的担保金或担保函",
                        order: 2,
                        isRequired: true,
                        estimatedMinutes: 120,
                        relatedDocuments: ["security-template"],
                        signatureRequired: true,
                        sealRequired: false,
                        signatureInstructions: "在担保函上签名承诺"
                    ),
                    ActionStep(
                        id: "preservation-application",
                        title: "提交保全申请",
                        description: "向法院提交财产保全申请书",
                        order: 3,
                        isRequired: true,
                        estimatedMinutes: 90,
                        relatedDocuments: ["preservation-application"],
                        signatureRequired: true,
                        sealRequired: false,
                        signatureInstructions: "在申请书上签名确认"
                    )
                ],
                tips: [
                    "诉前保全需在起诉前申请",
                    "担保金额一般为保全标的的30%",
                    "保全措施可有效防止对方转移财产",
                    "保全有效期通常为一年"
                ],
                warnings: [
                    "保全错误需承担对方损失",
                    "必须在保全后15日内起诉，否则保全失效"
                ],
                estimatedTime: "2-3天",
                difficulty: .hard
            ),
            requiredDocuments: [
                RequiredDocument(
                    id: "preservation-application",
                    name: "财产保全申请书",
                    description: "诉前财产保全申请书模板",
                    isRequired: true,
                    template: DocumentTemplate(
                        id: "preservation-template",
                        name: "财产保全申请书",
                        downloadUrl: "/templates/preservation_application.pdf",
                        fillableFields: createPreservationFields(),
                        instructions: "详细说明保全理由和标的",
                        fileFormat: "PDF"
                    ),
                    sampleDocument: nil,
                    submissionDeadline: nil,
                    submissionMethod: .offline
                ),
                RequiredDocument(
                    id: "security-guarantee",
                    name: "担保函",
                    description: "财产保全担保函或担保金",
                    isRequired: true,
                    template: nil,
                    sampleDocument: nil,
                    submissionDeadline: nil,
                    submissionMethod: .offline
                )
            ],
            legalNotices: [
                LegalNotice(
                    id: "preservation-notice-1",
                    title: "保全担保责任",
                    content: "申请有错误的，申请人应当赔偿被申请人因保全所遭受的损失。",
                    noticeType: .responsibility,
                    severity: .critical,
                    relatedLaws: ["《民事诉讼法》第105条"],
                    consequences: "错误保全需承担经济赔偿责任"
                ),
                LegalNotice(
                    id: "preservation-notice-2",
                    title: "起诉期限要求",
                    content: "诉前保全后，申请人应当在十五日内起诉或者申请仲裁。",
                    noticeType: .deadline,
                    severity: .critical,
                    relatedLaws: ["《民事诉讼法》第103条"],
                    consequences: "逾期不起诉保全措施将被解除"
                )
            ]
        )
    }
    
    /// 创建财产保全申请字段
    private func createPreservationFields() -> [FillableField] {
        return [
            FillableField(id: "preservation-target", fieldName: "保全标的", fieldType: .text, isRequired: true, placeholder: "银行账户/房产等", validationRules: ["非空"], signatureField: false, sealField: false),
            FillableField(id: "preservation-value", fieldName: "保全价值", fieldType: .number, isRequired: true, placeholder: "金额", validationRules: ["大于0"], signatureField: false, sealField: false),
            FillableField(id: "preservation-reason", fieldName: "保全理由", fieldType: .text, isRequired: true, placeholder: "申请理由", validationRules: ["非空"], signatureField: false, sealField: false),
            FillableField(id: "applicant-signature", fieldName: "申请人签名", fieldType: .signature, isRequired: true, placeholder: "", validationRules: [], signatureField: true, sealField: false)
        ]
    }
}