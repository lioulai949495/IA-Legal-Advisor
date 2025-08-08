import Foundation
import Combine
import SwiftUI

/// 文档生成服务
@MainActor
class DocumentGenerationService: ObservableObject, TemplateManager {
    @MainActor static let shared = DocumentGenerationService()
    
    // MARK: - Published Properties
    @Published var availableTemplates: [EnhancedDocumentTemplate] = []
    @Published var generatedDocuments: [GeneratedDocument] = []
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    @Published var currentGenerationId: String?
    
    // MARK: - Private Properties
    private let agentService: AgentService
    private let apiService: APIService
    private var templateCache: [String: EnhancedDocumentTemplate] = [:]
    private var generationQueue = OperationQueue()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private let maxConcurrentGenerations = 3
    private let templateCacheExpiry: TimeInterval = 3600 // 1小时
    
    // MARK: - Initialization
    private init(
        agentService: AgentService = .shared,
        apiService: APIService = .shared
    ) {
        self.agentService = agentService
        self.apiService = apiService
        
        setupGenerationQueue()
        loadDefaultTemplates()
        subscribeToServices()
    }
    
    // MARK: - TemplateManager Protocol Implementation
    
    func getTemplate(id: String) async throws -> EnhancedDocumentTemplate? {
        // 首先从缓存查找
        if let cachedTemplate = templateCache[id] {
            return cachedTemplate
        }
        
        // 从可用模板中查找
        if let template = availableTemplates.first(where: { $0.id == id }) {
            templateCache[id] = template
            return template
        }
        
        // 如果没有找到，可能需要从远程加载
        return try await loadTemplateFromRemote(id: id)
    }
    
    func getTemplatesForCaseType(_ caseType: CaseType) async throws -> [EnhancedDocumentTemplate] {
        return availableTemplates.filter { $0.isApplicableFor(caseType) }
    }
    
    func createTemplate(_ template: EnhancedDocumentTemplate) async throws -> String {
        // 验证模板
        let validationResult = try await validateTemplate(template)
        guard validationResult.isValid else {
            throw DocumentGenerationError.templateValidationFailed(validationResult.errors.map { $0.message }.joined(separator: ", "))
        }
        
        // 添加到可用模板列表
        availableTemplates.append(template)
        templateCache[template.id] = template
        
        // 持久化存储
        try await saveTemplateToStorage(template)
        
        return template.id
    }
    
    func updateTemplate(_ template: EnhancedDocumentTemplate) async throws {
        // 验证模板
        let validationResult = try await validateTemplate(template)
        guard validationResult.isValid else {
            throw DocumentGenerationError.templateValidationFailed(validationResult.errors.map { $0.message }.joined(separator: ", "))
        }
        
        // 更新模板
        if let index = availableTemplates.firstIndex(where: { $0.id == template.id }) {
            var updatedTemplate = template
            updatedTemplate.updatedAt = Date()
            
            availableTemplates[index] = updatedTemplate
            templateCache[template.id] = updatedTemplate
            
            // 持久化更新
            try await saveTemplateToStorage(updatedTemplate)
        } else {
            throw DocumentGenerationError.templateNotFound(template.id)
        }
    }
    
    func deleteTemplate(id: String) async throws {
        // 从列表中移除
        availableTemplates.removeAll { $0.id == id }
        templateCache.removeValue(forKey: id)
        
        // 从存储中删除
        try await deleteTemplateFromStorage(id: id)
    }
    
    func validateTemplate(_ template: EnhancedDocumentTemplate) async throws -> ValidationResult {
        var errors: [ValidationResult.ValidationError] = []
        var warnings: [ValidationResult.ValidationWarning] = []
        var suggestions: [ValidationResult.ValidationSuggestion] = []
        
        // 验证基本信息
        if template.name.isEmpty {
            errors.append(ValidationResult.ValidationError(
                id: UUID().uuidString,
                field: "name",
                message: "模板名称不能为空",
                code: "EMPTY_NAME"
            ))
        }
        
        // 验证模板内容
        if template.content.templateBody.isEmpty {
            errors.append(ValidationResult.ValidationError(
                id: UUID().uuidString,
                field: "content",
                message: "模板内容不能为空",
                code: "EMPTY_CONTENT"
            ))
        }
        
        // 验证填写字段
        for field in template.fillableFields {
            let fieldValidation = validateField(field)
            errors.append(contentsOf: fieldValidation)
        }
        
        // 验证验证规则
        for rule in template.validationRules {
            if rule.errorMessage.isEmpty {
                warnings.append(ValidationResult.ValidationWarning(
                    id: UUID().uuidString,
                    field: "validationRules",
                    message: "验证规则缺少错误消息",
                    code: "MISSING_ERROR_MESSAGE"
                ))
            }
        }
        
        // 生成改进建议
        if template.fillableFields.count > 20 {
            suggestions.append(ValidationResult.ValidationSuggestion(
                id: UUID().uuidString,
                field: "fillableFields",
                message: "字段数量较多，可能影响用户体验",
                improvement: "考虑分组或分页显示字段"
            ))
        }
        
        if template.complexityScore() == .veryComplex {
            suggestions.append(ValidationResult.ValidationSuggestion(
                id: UUID().uuidString,
                field: "complexity",
                message: "模板复杂度很高",
                improvement: "考虑简化模板或提供更好的用户指导"
            ))
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            suggestions: suggestions
        )
    }
    
    func generateDocument(templateId: String, fieldValues: [String: Any]) async throws -> GeneratedDocument {
        guard let template = try await getTemplate(id: templateId) else {
            throw DocumentGenerationError.templateNotFound(templateId)
        }
        
        let generationId = UUID().uuidString
        currentGenerationId = generationId
        isGenerating = true
        generationProgress = 0.0
        
        defer {
            isGenerating = false
            generationProgress = 0.0
            currentGenerationId = nil
        }
        
        do {
            // 验证字段值
            let validationResult = try await validateFieldValues(template: template, fieldValues: fieldValues)
            if !validationResult.isValid {
                throw DocumentGenerationError.fieldValidationFailed(validationResult.errors.map { $0.message }.joined(separator: ", "))
            }
            
            generationProgress = 0.2
            
            // 预处理字段值
            let processedValues = try preprocessFieldValues(template: template, fieldValues: fieldValues)
            
            generationProgress = 0.4
            
            // 生成文档内容
            let documentContent = try await generateDocumentContent(template: template, fieldValues: processedValues)
            
            generationProgress = 0.6
            
            // 应用格式化
            let formattedContent = try applyFormatting(content: documentContent, template: template)
            
            generationProgress = 0.8
            
            // 后处理
            let finalContent = try await postProcessDocument(
                content: formattedContent,
                template: template,
                generationId: generationId
            )
            
            generationProgress = 1.0
            
            // 创建生成文档对象
            let generatedDoc = GeneratedDocument(
                id: generationId,
                templateId: templateId,
                content: finalContent,
                format: template.generationSettings.outputFormat,
                metadata: GeneratedDocumentMetadata(
                    templateVersion: template.version,
                    fieldValues: fieldValues.mapValues { String(describing: $0) },
                    generationSettings: template.generationSettings,
                    fileSize: Int64(finalContent.count),
                    pageCount: estimatePageCount(content: finalContent),
                    checksum: calculateChecksum(data: finalContent)
                ),
                generatedAt: Date(),
                downloadURL: nil,
                isTemporary: true,
                expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date())
            )
            
            // 保存到生成文档列表
            generatedDocuments.append(generatedDoc)
            
            // 异步保存到存储
            Task {
                try? await saveGeneratedDocument(generatedDoc)
            }
            
            return generatedDoc
            
        } catch {
            throw DocumentGenerationError.generationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Public Methods
    
    /// 使用AI代理生成智能文档
    func generateIntelligentDocument(
        caseType: CaseType,
        documentType: DocumentTemplateCategory,
        userInput: [String: Any],
        customInstructions: String? = nil
    ) async throws -> GeneratedDocument {
        
        let generationId = UUID().uuidString
        currentGenerationId = generationId
        isGenerating = true
        generationProgress = 0.0
        
        defer {
            isGenerating = false
            generationProgress = 0.0
            currentGenerationId = nil
        }
        
        // 构建AI生成请求
        let content = buildAIGenerationContent(
            caseType: caseType,
            documentType: documentType,
            userInput: userInput,
            customInstructions: customInstructions
        )
        
        let request = AgentRequest(
            id: generationId,
            agentType: .documentGenerator,
            caseType: caseType,
            content: content,
            context: buildDocumentGenerationContext(userInput: userInput),
            priority: .normal,
            createdAt: Date()
        )
        
        generationProgress = 0.2
        
        // 发送到文档生成AI代理
        let response = try await agentService.sendRequest(request)
        
        generationProgress = 0.6
        
        // 处理AI响应
        let documentContent = try processAIGeneratedContent(response: response, documentType: documentType)
        
        generationProgress = 0.8
        
        // 创建生成文档
        let generatedDoc = GeneratedDocument(
            id: generationId,
            templateId: "ai_generated",
            content: documentContent,
            format: .pdf,
            metadata: GeneratedDocumentMetadata(
                templateVersion: "1.0",
                fieldValues: userInput.mapValues { String(describing: $0) },
                generationSettings: getDefaultGenerationSettings(),
                fileSize: Int64(documentContent.count),
                pageCount: estimatePageCount(content: documentContent),
                checksum: calculateChecksum(data: documentContent)
            ),
            generatedAt: Date(),
            downloadURL: nil,
            isTemporary: true,
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )
        
        generationProgress = 1.0
        
        generatedDocuments.append(generatedDoc)
        
        return generatedDoc
    }
    
    /// 批量生成文档
    func batchGenerateDocuments(
        requests: [DocumentGenerationRequest]
    ) async throws -> [GeneratedDocument] {
        
        var results: [GeneratedDocument] = []
        
        for (index, request) in requests.enumerated() {
            do {
                // Map DocumentGenerationRequest properties to the expected format
                let templateId = request.template ?? request.document_type
                let fieldValues: [String: Any] = [
                    "case_id": request.case_id,
                    "document_type": request.document_type
                ]
                
                let document = try await generateDocument(
                    templateId: templateId,
                    fieldValues: fieldValues
                )
                results.append(document)
                
                // 更新批量进度
                let progress = Double(index + 1) / Double(requests.count)
                await updateBatchProgress(progress)
                
            } catch {
                // 记录错误，但继续处理其他请求
                print("批量生成文档失败: \(request.template ?? request.document_type) - \(error)")
            }
        }
        
        return results
    }
    
    /// 获取文档预览
    func getDocumentPreview(
        templateId: String,
        fieldValues: [String: Any],
        previewOptions: PreviewOptions = PreviewOptions()
    ) async throws -> DocumentPreview {
        
        guard let template = try await getTemplate(id: templateId) else {
            throw DocumentGenerationError.templateNotFound(templateId)
        }
        
        // 生成预览内容
        let previewContent = try await generatePreviewContent(
            template: template,
            fieldValues: fieldValues,
            options: previewOptions
        )
        
        return DocumentPreview(
            id: UUID().uuidString,
            templateId: templateId,
            previewContent: previewContent,
            pageCount: estimatePageCount(content: previewContent),
            generatedAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .minute, value: 30, to: Date())
        )
    }
    
    /// 合并多个文档
    func mergeDocuments(
        documentIds: [String],
        mergeOptions: DocumentMergeOptions = DocumentMergeOptions()
    ) async throws -> GeneratedDocument {
        
        let documentsToMerge = generatedDocuments.filter { documentIds.contains($0.id) }
        
        guard documentsToMerge.count == documentIds.count else {
            throw DocumentGenerationError.documentsNotFound
        }
        
        // 执行文档合并
        let mergedContent = try await performDocumentMerge(
            documents: documentsToMerge,
            options: mergeOptions
        )
        
        let mergedDocument = GeneratedDocument(
            id: UUID().uuidString,
            templateId: "merged_document",
            content: mergedContent,
            format: .pdf,
            metadata: GeneratedDocumentMetadata(
                templateVersion: "1.0",
                fieldValues: [:],
                generationSettings: getDefaultGenerationSettings(),
                fileSize: Int64(mergedContent.count),
                pageCount: documentsToMerge.reduce(0) { $0 + ($1.metadata.pageCount ?? 1) },
                checksum: calculateChecksum(data: mergedContent)
            ),
            generatedAt: Date(),
            downloadURL: nil,
            isTemporary: true,
            expiresAt: Calendar.current.date(byAdding: .day, value: 3, to: Date())
        )
        
        generatedDocuments.append(mergedDocument)
        return mergedDocument
    }
    
    /// 转换文档格式
    func convertDocument(
        documentId: String,
        targetFormat: DocumentGenerationSettings.OutputFormat
    ) async throws -> GeneratedDocument {
        
        guard let sourceDocument = generatedDocuments.first(where: { $0.id == documentId }) else {
            throw DocumentGenerationError.documentNotFound(documentId)
        }
        
        let convertedContent = try await performFormatConversion(
            content: sourceDocument.content,
            fromFormat: sourceDocument.format,
            toFormat: targetFormat
        )
        
        // Create new metadata with updated properties since GeneratedDocumentMetadata has immutable properties
        var updatedGenerationSettings = sourceDocument.metadata.generationSettings
        updatedGenerationSettings.outputFormat = targetFormat
        
        let convertedMetadata = GeneratedDocumentMetadata(
            templateVersion: sourceDocument.metadata.templateVersion,
            fieldValues: sourceDocument.metadata.fieldValues,
            generationSettings: updatedGenerationSettings,
            fileSize: Int64(convertedContent.count),
            pageCount: sourceDocument.metadata.pageCount,
            checksum: calculateChecksum(data: convertedContent)
        )
        
        let convertedDocument = GeneratedDocument(
            id: UUID().uuidString,
            templateId: sourceDocument.templateId,
            content: convertedContent,
            format: targetFormat,
            metadata: convertedMetadata,
            generatedAt: Date(),
            downloadURL: nil,
            isTemporary: true,
            expiresAt: Calendar.current.date(byAdding: .day, value: 3, to: Date())
        )
        
        generatedDocuments.append(convertedDocument)
        return convertedDocument
    }
    
    // MARK: - Private Methods
    
    private func setupGenerationQueue() {
        generationQueue.maxConcurrentOperationCount = maxConcurrentGenerations
        generationQueue.qualityOfService = .userInitiated
    }
    
    private func loadDefaultTemplates() {
        // 加载默认模板
        Task {
            await loadBuiltInTemplates()
        }
    }
    
    private func subscribeToServices() {
        // 订阅相关服务的状态变化
        agentService.$completedResponses
            .sink { [weak self] responses in
                Task { @MainActor in
                    await self?.handleAgentResponses(responses)
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadBuiltInTemplates() async {
        // 创建内置模板
        let complaintTemplate = createComplaintTemplate()
        let evidenceListTemplate = createEvidenceListTemplate()
        let defenseResponseTemplate = createDefenseResponseTemplate()
        
        availableTemplates = [
            complaintTemplate,
            evidenceListTemplate,
            defenseResponseTemplate
        ]
        
        // 更新模板缓存
        for template in availableTemplates {
            templateCache[template.id] = template
        }
    }
    
    private func createComplaintTemplate() -> EnhancedDocumentTemplate {
        let fillableFields = [
            EnhancedFillableField(
                id: "plaintiff_name",
                fieldName: "plaintiff_name",
                displayName: "原告姓名",
                fieldType: .text,
                isRequired: true,
                placeholder: "请输入原告完整姓名",
                helpText: "请确保姓名与身份证完全一致",
                defaultValue: nil,
                validationRules: [
                    ValidationRule(
                        id: "plaintiff_name_required",
                        ruleType: .required,
                        parameter: nil,
                        errorMessage: "原告姓名为必填项",
                        severity: .error
                    ),
                    ValidationRule(
                        id: "plaintiff_name_length",
                        ruleType: .maxLength,
                        parameter: "50",
                        errorMessage: "姓名长度不能超过50个字符",
                        severity: .error
                    )
                ],
                options: nil,
                formatting: FieldFormatting(
                    mask: nil,
                    pattern: nil,
                    prefix: nil,
                    suffix: nil,
                    uppercase: false,
                    lowercase: false,
                    trim: true
                ),
                positioning: FieldPosition(
                    x: 0.2, y: 0.15, width: 0.6, height: 0.05,
                    page: 1, section: "header", order: 1
                ),
                behavior: FieldBehavior(
                    readOnly: false,
                    hidden: false,
                    autoFocus: true,
                    clearOnEdit: false,
                    autoComplete: "name",
                    dependencies: [],
                    calculations: nil,
                    validationTrigger: .onBlur
                ),
                accessibility: FieldAccessibility(
                    ariaLabel: "原告姓名输入框",
                    ariaDescription: "请输入起诉方的完整姓名",
                    tabIndex: 1,
                    role: "textbox",
                    screenReaderText: "原告姓名，必填"
                )
            ),
            EnhancedFillableField(
                id: "defendant_name",
                fieldName: "defendant_name",
                displayName: "被告姓名",
                fieldType: .text,
                isRequired: true,
                placeholder: "请输入被告完整姓名",
                helpText: "请确保姓名准确无误",
                defaultValue: nil,
                validationRules: [
                    ValidationRule(
                        id: "defendant_name_required",
                        ruleType: .required,
                        parameter: nil,
                        errorMessage: "被告姓名为必填项",
                        severity: .error
                    )
                ],
                options: nil,
                formatting: FieldFormatting(
                    mask: nil,
                    pattern: nil,
                    prefix: nil,
                    suffix: nil,
                    uppercase: false,
                    lowercase: false,
                    trim: true
                ),
                positioning: FieldPosition(
                    x: 0.2, y: 0.25, width: 0.6, height: 0.05,
                    page: 1, section: "header", order: 2
                ),
                behavior: FieldBehavior(
                    readOnly: false,
                    hidden: false,
                    autoFocus: false,
                    clearOnEdit: false,
                    autoComplete: "name",
                    dependencies: [],
                    calculations: nil,
                    validationTrigger: .onBlur
                ),
                accessibility: FieldAccessibility(
                    ariaLabel: "被告姓名输入框",
                    ariaDescription: "请输入被起诉方的完整姓名",
                    tabIndex: 2,
                    role: "textbox",
                    screenReaderText: "被告姓名，必填"
                )
            )
        ]
        
        return EnhancedDocumentTemplate(
            id: "complaint_template_standard",
            name: "标准起诉状模板",
            category: .legalPleading,
            templateType: .dynamic,
            version: "1.0",
            description: "适用于民事诉讼的标准起诉状模板",
            applicableCaseTypes: [.contractDispute, .debtDispute, .propertyDispute],
            content: DocumentContent(
                templateBody: createComplaintTemplateBody(),
                sections: createComplaintSections(),
                formatting: DocumentFormatting(
                    fontFamily: "SimSun",
                    fontSize: 14,
                    lineSpacing: 1.5,
                    paragraphSpacing: 12,
                    margins: DocumentMargins(top: 72, bottom: 72, left: 90, right: 90),
                    alignment: .justified,
                    style: .legal
                ),
                layout: DocumentLayout(
                    pageSize: .a4,
                    orientation: .portrait,
                    columns: 1,
                    headerHeight: 36,
                    footerHeight: 36
                ),
                assets: []
            ),
            metadata: TemplateMetadata(
                author: "IAAdvisor2",
                organization: "智能法律助手",
                jurisdiction: "中华人民共和国",
                language: "zh-CN",
                tags: ["起诉状", "民事诉讼", "标准模板"],
                usageCount: 0,
                rating: 0.0,
                reviews: [],
                lastUsed: nil,
                isOfficial: true,
                compliance: nil
            ),
            fillableFields: fillableFields,
            validationRules: [
                ValidationRule(
                    id: "case_value_validation",
                    ruleType: .range,
                    parameter: "1-999999999",
                    errorMessage: "案件标的额必须在合理范围内",
                    severity: .warning
                )
            ],
            generationSettings: getDefaultGenerationSettings(),
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createEvidenceListTemplate() -> EnhancedDocumentTemplate {
        // 创建证据清单模板的简化实现
        return EnhancedDocumentTemplate(
            id: "evidence_list_template",
            name: "证据清单模板",
            category: .evidence,
            templateType: .dynamic,
            version: "1.0",
            description: "用于整理和提交证据的标准清单模板",
            applicableCaseTypes: CaseType.allCases,
            content: DocumentContent(
                templateBody: "证据清单模板内容...",
                sections: [],
                formatting: DocumentFormatting(
                    fontFamily: "SimSun",
                    fontSize: 12,
                    lineSpacing: 1.5,
                    paragraphSpacing: 6,
                    margins: DocumentMargins(top: 72, bottom: 72, left: 90, right: 90),
                    alignment: .left,
                    style: .legal
                ),
                layout: DocumentLayout(
                    pageSize: .a4,
                    orientation: .portrait,
                    columns: 1,
                    headerHeight: 24,
                    footerHeight: 24
                ),
                assets: []
            ),
            metadata: TemplateMetadata(
                author: "IAAdvisor2",
                organization: "智能法律助手",
                jurisdiction: "中华人民共和国",
                language: "zh-CN",
                tags: ["证据", "清单", "诉讼材料"],
                usageCount: 0,
                rating: 0.0,
                reviews: [],
                lastUsed: nil,
                isOfficial: true,
                compliance: nil
            ),
            fillableFields: [],
            validationRules: [],
            generationSettings: getDefaultGenerationSettings(),
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createDefenseResponseTemplate() -> EnhancedDocumentTemplate {
        // 创建答辩书模板的简化实现
        return EnhancedDocumentTemplate(
            id: "defense_response_template",
            name: "答辩书模板",
            category: .response,
            templateType: .dynamic,
            version: "1.0",
            description: "民事诉讼答辩书标准模板",
            applicableCaseTypes: CaseType.allCases,
            content: DocumentContent(
                templateBody: "答辩书模板内容...",
                sections: [],
                formatting: DocumentFormatting(
                    fontFamily: "SimSun",
                    fontSize: 14,
                    lineSpacing: 1.5,
                    paragraphSpacing: 12,
                    margins: DocumentMargins(top: 72, bottom: 72, left: 90, right: 90),
                    alignment: .justified,
                    style: .legal
                ),
                layout: DocumentLayout(
                    pageSize: .a4,
                    orientation: .portrait,
                    columns: 1,
                    headerHeight: 36,
                    footerHeight: 36
                ),
                assets: []
            ),
            metadata: TemplateMetadata(
                author: "IAAdvisor2",
                organization: "智能法律助手",
                jurisdiction: "中华人民共和国",
                language: "zh-CN",
                tags: ["答辩书", "民事诉讼", "应诉"],
                usageCount: 0,
                rating: 0.0,
                reviews: [],
                lastUsed: nil,
                isOfficial: true,
                compliance: nil
            ),
            fillableFields: [],
            validationRules: [],
            generationSettings: getDefaultGenerationSettings(),
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createComplaintTemplateBody() -> String {
        return """
        起    诉    状
        
        原告：{{plaintiff_name}}，性别：{{plaintiff_gender}}，{{plaintiff_birth_date}}出生，
        {{plaintiff_ethnicity}}族，住所地：{{plaintiff_address}}，
        联系电话：{{plaintiff_phone}}，身份证号码：{{plaintiff_id_number}}。
        
        被告：{{defendant_name}}，性别：{{defendant_gender}}，{{defendant_birth_date}}出生，
        {{defendant_ethnicity}}族，住所地：{{defendant_address}}，
        联系电话：{{defendant_phone}}，身份证号码：{{defendant_id_number}}。
        
        诉讼请求：
        1. {{claim_1}}
        2. {{claim_2}}
        3. 诉讼费由被告承担。
        
        事实与理由：
        {{case_facts_and_reasons}}
        
        此致
        {{court_name}}
        
                                           起诉人：{{plaintiff_name}}
                                           {{signature_date}}
        """
    }
    
    private func createComplaintSections() -> [DocumentSection] {
        return [
            DocumentSection(
                id: "header",
                title: "文书标题",
                content: "起    诉    状",
                sectionType: .title,
                order: 1,
                isRequired: true,
                conditional: nil
            ),
            DocumentSection(
                id: "parties",
                title: "当事人信息",
                content: "原告和被告基本信息",
                sectionType: .paragraph,
                order: 2,
                isRequired: true,
                conditional: nil
            ),
            DocumentSection(
                id: "claims",
                title: "诉讼请求",
                content: "具体的诉讼请求内容",
                sectionType: .list,
                order: 3,
                isRequired: true,
                conditional: nil
            ),
            DocumentSection(
                id: "facts",
                title: "事实与理由",
                content: "案件事实和法律理由",
                sectionType: .paragraph,
                order: 4,
                isRequired: true,
                conditional: nil
            ),
            DocumentSection(
                id: "signature",
                title: "签名区",
                content: "起诉人签名和日期",
                sectionType: .signature,
                order: 5,
                isRequired: true,
                conditional: nil
            )
        ]
    }
    
    private func getDefaultGenerationSettings() -> DocumentGenerationSettings {
        return DocumentGenerationSettings(
            outputFormat: .pdf,
            quality: .standard,
            watermark: nil,
            security: nil,
            metadata: GenerationMetadata(
                includeMetadata: true,
                author: "IAAdvisor2",
                title: nil,
                subject: nil,
                keywords: ["法律文书"],
                creator: "IAAdvisor2 Document Generator",
                producer: "IAAdvisor2",
                creationDate: Date(),
                modificationDate: Date(),
                customProperties: [:]
            ),
            postProcessing: PostProcessingOptions(
                autoSave: true,
                backup: true,
                versioning: false,
                notification: nil,
                integration: nil
            )
        )
    }
    
    // MARK: - Field Validation Methods
    
    private func validateField(_ field: EnhancedFillableField) -> [ValidationResult.ValidationError] {
        var errors: [ValidationResult.ValidationError] = []
        
        if field.fieldName.isEmpty {
            errors.append(ValidationResult.ValidationError(
                id: UUID().uuidString,
                field: field.id,
                message: "字段名不能为空",
                code: "EMPTY_FIELD_NAME"
            ))
        }
        
        if field.displayName.isEmpty {
            errors.append(ValidationResult.ValidationError(
                id: UUID().uuidString,
                field: field.id,
                message: "显示名称不能为空",
                code: "EMPTY_DISPLAY_NAME"
            ))
        }
        
        return errors
    }
    
    private func validateFieldValues(
        template: EnhancedDocumentTemplate,
        fieldValues: [String: Any]
    ) async throws -> ValidationResult {
        
        var errors: [ValidationResult.ValidationError] = []
        var warnings: [ValidationResult.ValidationWarning] = []
        
        for field in template.fillableFields {
            let value = fieldValues[field.fieldName] as? String
            let fieldErrors = field.validate(value: value)
            errors.append(contentsOf: fieldErrors)
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            suggestions: []
        )
    }
    
    // MARK: - Document Generation Methods
    
    private func preprocessFieldValues(
        template: EnhancedDocumentTemplate,
        fieldValues: [String: Any]
    ) throws -> [String: Any] {
        
        var processedValues = fieldValues
        
        for field in template.fillableFields {
            if let rawValue = fieldValues[field.fieldName] {
                let processedValue = applyFieldFormatting(
                    value: rawValue,
                    formatting: field.formatting
                )
                processedValues[field.fieldName] = processedValue
            }
        }
        
        return processedValues
    }
    
    private func applyFieldFormatting(value: Any, formatting: FieldFormatting) -> Any {
        guard let stringValue = value as? String else { return value }
        
        var result = stringValue
        
        if formatting.trim {
            result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if formatting.uppercase {
            result = result.uppercased()
        } else if formatting.lowercase {
            result = result.lowercased()
        }
        
        if let prefix = formatting.prefix {
            result = prefix + result
        }
        
        if let suffix = formatting.suffix {
            result = result + suffix
        }
        
        return result
    }
    
    private func generateDocumentContent(
        template: EnhancedDocumentTemplate,
        fieldValues: [String: Any]
    ) async throws -> Data {
        
        var content = template.content.templateBody
        
        // 替换字段占位符
        for (fieldName, value) in fieldValues {
            let placeholder = "{{\(fieldName)}}"
            let stringValue = String(describing: value)
            content = content.replacingOccurrences(of: placeholder, with: stringValue)
        }
        
        // 处理条件逻辑
        content = try processConditionalLogic(content: content, fieldValues: fieldValues)
        
        // 转换为指定格式
        let documentData = try await convertToFormat(
            content: content,
            format: template.generationSettings.outputFormat,
            settings: template.generationSettings
        )
        
        return documentData
    }
    
    private func processConditionalLogic(
        content: String,
        fieldValues: [String: Any]
    ) throws -> String {
        // TODO: 实现条件逻辑处理
        return content
    }
    
    private func convertToFormat(
        content: String,
        format: DocumentGenerationSettings.OutputFormat,
        settings: DocumentGenerationSettings
    ) async throws -> Data {
        
        switch format {
        case .pdf:
            return try await convertToPDF(content: content, settings: settings)
        case .docx:
            return try await convertToDocx(content: content, settings: settings)
        case .html:
            return try await convertToHTML(content: content, settings: settings)
        case .txt:
            return content.data(using: .utf8) ?? Data()
        default:
            return content.data(using: .utf8) ?? Data()
        }
    }
    
    private func convertToPDF(
        content: String,
        settings: DocumentGenerationSettings
    ) async throws -> Data {
        // TODO: 实现PDF转换
        // 这里应该使用适当的PDF生成库
        return content.data(using: .utf8) ?? Data()
    }
    
    private func convertToDocx(
        content: String,
        settings: DocumentGenerationSettings
    ) async throws -> Data {
        // TODO: 实现DOCX转换
        return content.data(using: .utf8) ?? Data()
    }
    
    private func convertToHTML(
        content: String,
        settings: DocumentGenerationSettings
    ) async throws -> Data {
        // TODO: 实现HTML转换，添加样式和格式
        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>Generated Document</title>
            <style>
                body { font-family: SimSun, serif; font-size: 14px; line-height: 1.5; }
                .title { text-align: center; font-weight: bold; font-size: 18px; }
                .signature { text-align: right; margin-top: 50px; }
            </style>
        </head>
        <body>
            \(content.replacingOccurrences(of: "\n", with: "<br>"))
        </body>
        </html>
        """
        return htmlContent.data(using: .utf8) ?? Data()
    }
    
    private func applyFormatting(
        content: Data,
        template: EnhancedDocumentTemplate
    ) throws -> Data {
        // TODO: 应用文档格式化
        return content
    }
    
    private func postProcessDocument(
        content: Data,
        template: EnhancedDocumentTemplate,
        generationId: String
    ) async throws -> Data {
        
        var processedContent = content
        
        // 应用水印
        if let watermark = template.generationSettings.watermark {
            processedContent = try await applyWatermark(content: processedContent, watermark: watermark)
        }
        
        // 应用安全设置
        if let security = template.generationSettings.security {
            processedContent = try await applySecurity(content: processedContent, security: security)
        }
        
        // 后处理操作
        if template.generationSettings.postProcessing.autoSave {
            try await saveToStorage(content: processedContent, generationId: generationId)
        }
        
        return processedContent
    }
    
    // MARK: - AI Generation Methods
    
    private func buildAIGenerationContent(
        caseType: CaseType,
        documentType: DocumentTemplateCategory,
        userInput: [String: Any],
        customInstructions: String?
    ) -> String {
        
        var content = """
        请生成一份\(documentType.rawValue)，用于\(caseType.rawValue)案件。
        
        用户提供的信息：
        """
        
        for (key, value) in userInput {
            content += "\n- \(key): \(value)"
        }
        
        if let instructions = customInstructions {
            content += "\n\n特别要求：\n\(instructions)"
        }
        
        content += """
        
        请确保生成的文档：
        1. 符合法律文书的格式要求
        2. 语言准确、逻辑清晰
        3. 包含必要的法律条文引用
        4. 结构完整、要素齐全
        """
        
        return content
    }
    
    private func buildDocumentGenerationContext(userInput: [String: Any]) -> AgentContext? {
        // TODO: 构建文档生成的上下文信息
        return nil
    }
    
    private func processAIGeneratedContent(
        response: AgentResponse,
        documentType: DocumentTemplateCategory
    ) throws -> Data {
        
        // 处理AI生成的内容
        let content = response.content
        
        // 根据文档类型进行后处理
        let processedContent = postProcessAIContent(content: content, documentType: documentType)
        
        // 转换为Data
        return processedContent.data(using: .utf8) ?? Data()
    }
    
    private func postProcessAIContent(content: String, documentType: DocumentTemplateCategory) -> String {
        // 根据文档类型进行特定的后处理
        switch documentType {
        case .legalPleading:
            return formatLegalPleading(content: content)
        case .evidence:
            return formatEvidenceList(content: content)
        case .response:
            return formatDefenseResponse(content: content)
        default:
            return content
        }
    }
    
    private func formatLegalPleading(content: String) -> String {
        // 格式化法律文书
        var formatted = content
        
        // 确保标题居中
        if !formatted.contains("起    诉    状") && formatted.contains("起诉状") {
            formatted = formatted.replacingOccurrences(of: "起诉状", with: "起    诉    状")
        }
        
        return formatted
    }
    
    private func formatEvidenceList(content: String) -> String {
        // 格式化证据清单
        return content
    }
    
    private func formatDefenseResponse(content: String) -> String {
        // 格式化答辩书
        return content
    }
    
    // MARK: - Preview and Merge Methods
    
    private func generatePreviewContent(
        template: EnhancedDocumentTemplate,
        fieldValues: [String: Any],
        options: PreviewOptions
    ) async throws -> Data {
        
        // 生成预览版本的文档内容
        var content = template.content.templateBody
        
        // 替换字段，对于空值使用占位符
        for field in template.fillableFields {
            let placeholder = "{{\(field.fieldName)}}"
            let value = fieldValues[field.fieldName] as? String ?? "[待填写]"
            content = content.replacingOccurrences(of: placeholder, with: value)
        }
        
        // 添加预览标记
        content = "【预览版本】\n\n" + content
        
        return content.data(using: .utf8) ?? Data()
    }
    
    private func performDocumentMerge(
        documents: [GeneratedDocument],
        options: DocumentMergeOptions
    ) async throws -> Data {
        
        var mergedContent = ""
        
        for (index, document) in documents.enumerated() {
            if let content = String(data: document.content, encoding: .utf8) {
                mergedContent += content
                
                // 在文档之间添加分页符（除了最后一个文档）
                if index < documents.count - 1 {
                    mergedContent += "\n\n--- 文档分隔符 ---\n\n"
                }
            }
        }
        
        return mergedContent.data(using: .utf8) ?? Data()
    }
    
    private func performFormatConversion(
        content: Data,
        fromFormat: DocumentGenerationSettings.OutputFormat,
        toFormat: DocumentGenerationSettings.OutputFormat
    ) async throws -> Data {
        
        // 如果格式相同，直接返回
        if fromFormat == toFormat {
            return content
        }
        
        // TODO: 实现格式转换逻辑
        // 这里应该根据不同的格式组合实现转换
        
        return content
    }
    
    // MARK: - Storage and Persistence Methods
    
    private func loadTemplateFromRemote(id: String) async throws -> EnhancedDocumentTemplate? {
        // TODO: 从远程服务器加载模板
        return nil
    }
    
    private func saveTemplateToStorage(_ template: EnhancedDocumentTemplate) async throws {
        // TODO: 保存模板到本地存储
    }
    
    private func deleteTemplateFromStorage(id: String) async throws {
        // TODO: 从存储中删除模板
    }
    
    private func saveGeneratedDocument(_ document: GeneratedDocument) async throws {
        // TODO: 保存生成的文档到存储
    }
    
    private func saveToStorage(content: Data, generationId: String) async throws {
        // TODO: 保存内容到存储系统
    }
    
    // MARK: - Utility Methods
    
    private func estimatePageCount(content: Data) -> Int {
        // 简单的页数估算
        let characterCount = content.count
        let averageCharactersPerPage = 2000
        return max(1, characterCount / averageCharactersPerPage)
    }
    
    private func calculateChecksum(data: Data) -> String {
        // 计算数据校验和
        let hash = data.withUnsafeBytes { bytes in
            return bytes.reduce(0) { $0 ^ $1 }
        }
        return String(hash, radix: 16)
    }
    
    private func updateBatchProgress(_ progress: Double) async {
        // TODO: 更新批量生成进度
    }
    
    // MARK: - Security and Watermark Methods
    
    private func applyWatermark(content: Data, watermark: WatermarkSettings) async throws -> Data {
        // TODO: 应用水印
        return content
    }
    
    private func applySecurity(content: Data, security: SecuritySettings) async throws -> Data {
        // TODO: 应用安全设置
        return content
    }
    
    // MARK: - Event Handlers
    
    private func handleAgentResponses(_ responses: [AgentResponse]) async {
        // 处理AI代理的响应
        for response in responses {
            if response.agentId.contains("document-generator") {
                // 处理文档生成相关的响应
                await processDocumentGenerationResponse(response)
            }
        }
    }
    
    private func processDocumentGenerationResponse(_ response: AgentResponse) async {
        // 处理文档生成响应
        // TODO: 实现响应处理逻辑
    }
}

// MARK: - Supporting Types

/// 文档生成请求
struct InternalDocumentGenerationRequest {
    let templateId: String
    let fieldValues: [String: Any]
    let customSettings: DocumentGenerationSettings?
}

/// 文档预览
struct DocumentPreview: Identifiable {
    let id: String
    let templateId: String
    let previewContent: Data
    let pageCount: Int
    let generatedAt: Date
    let expiresAt: Date?
}

/// 预览选项
struct PreviewOptions {
    var showPlaceholders: Bool = true
    var includeWatermark: Bool = true
    var quality: DocumentGenerationSettings.GenerationQuality = .draft
}

/// 文档合并选项
struct DocumentMergeOptions {
    var insertPageBreaks: Bool = true
    var includeTOC: Bool = false
    var mergeMetadata: Bool = true
}

/// 文档生成错误
enum DocumentGenerationError: LocalizedError {
    case templateNotFound(String)
    case templateValidationFailed(String)
    case fieldValidationFailed(String)
    case generationFailed(String)
    case formatConversionFailed(String)
    case documentsNotFound
    case documentNotFound(String)
    case storageError(String)
    
    var errorDescription: String? {
        switch self {
        case .templateNotFound(let id):
            return "找不到模板: \(id)"
        case .templateValidationFailed(let message):
            return "模板验证失败: \(message)"
        case .fieldValidationFailed(let message):
            return "字段验证失败: \(message)"
        case .generationFailed(let message):
            return "文档生成失败: \(message)"
        case .formatConversionFailed(let message):
            return "格式转换失败: \(message)"
        case .documentsNotFound:
            return "找不到指定的文档"
        case .documentNotFound(let id):
            return "找不到文档: \(id)"
        case .storageError(let message):
            return "存储错误: \(message)"
        }
    }
}