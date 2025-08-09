import SwiftUI

/// 文档生成视图
struct DocumentGenerationView: View {
    let caseId: String
    
    @StateObject private var documentService = CaseDocumentService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDocumentType: CaseDocumentType = CaseDocumentType.complaint
    @State private var documentName = ""
    @State private var documentDescription = ""
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var isGenerating = false
    @State private var generationProgress: Double = 0.0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var generatedContent = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if isGenerating {
                        generationProgressView
                    } else {
                        documentTypeSelectionView
                        documentInfoInputView
                        tagsInputView
                        generateButtonView
                    }
                }
                .padding()
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("生成文档")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.white)
                }
                if !isGenerating {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("生成") { generateDocument() }
                            .foregroundColor(.white)
                            .disabled(documentName.isEmpty)
                    }
                }
            }
        }
        .alert("生成结果", isPresented: $showingAlert) {
            Button("确定") { if !alertMessage.contains("失败") { dismiss() } }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - 子视图组件
    private var generationProgressView: some View {
        VStack(spacing: 24) {
            Text("AI正在生成文档...")
                .font(.headline)
                .foregroundColor(.white)
            ProgressView(value: generationProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor))
                .scaleEffect(1.2)
            Text("\(Int(generationProgress * 100))%")
                .font(.title2.bold())
                .foregroundColor(AppTheme.accentColor)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
        .liquidGlass()
    }
    
    private var documentTypeSelectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("文档类型")
                .font(.headline)
                .foregroundColor(.white)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(CaseDocumentType.allCases.filter { $0.category == .generated }, id: \.self) { type in
                    DocumentTypeCard(type: type, isSelected: selectedDocumentType == type) {
                        selectedDocumentType = type
                        if documentName.isEmpty { documentName = type.defaultName }
                    }
                }
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private var documentInfoInputView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("文档信息")
                .font(.headline)
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 12) {
                Text("文档名称")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                TextField("请输入文档名称", text: $documentName)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("描述 (可选)")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                if #available(iOS 16.0, *) {
                    TextField("请输入文档描述", text: $documentDescription, axis: .vertical)
                        .textFieldStyle(CustomTextFieldStyle())
                        .lineLimit(3...6)
                } else {
                    TextField("请输入文档描述", text: $documentDescription)
                        .textFieldStyle(CustomTextFieldStyle())
                        .lineLimit(6)
                }
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private var tagsInputView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("标签")
                .font(.headline)
                .foregroundColor(.white)
            HStack {
                TextField("添加标签", text: $newTag)
                    .textFieldStyle(CustomTextFieldStyle())
                Button("添加") {
                    if !newTag.isEmpty && !tags.contains(newTag) {
                        tags.append(newTag)
                        newTag = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newTag.isEmpty)
            }
            if !tags.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        HStack {
                            Text(tag).font(.caption).foregroundColor(.white)
                            Button { tags.removeAll { $0 == tag } } label: {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.accentColor.opacity(0.3))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private var generateButtonView: some View {
        Button { generateDocument() } label: {
            HStack {
                Image(systemName: "doc.badge.plus").font(.title3)
                Text("生成文档").font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.accentColor)
            .cornerRadius(12)
        }
        .disabled(documentName.isEmpty || isGenerating)
        .padding(.horizontal)
    }
    
    // MARK: - 方法
    private func generateDocument() {
        isGenerating = true
        generationProgress = 0.0
        Task {
            await simulateGeneration()
            let result = documentService.createGeneratedDocument(
                for: caseId,
                name: documentName,
                type: selectedDocumentType,
                content: generateDocumentContent(),
                description: documentDescription.isEmpty ? nil : documentDescription,
                tags: tags
            )
            await MainActor.run {
                isGenerating = false
                alertMessage = result.success ? "文档生成成功！" : "文档生成失败：\(result.error?.localizedDescription ?? "未知错误")"
                showingAlert = true
            }
        }
    }
    
    private func simulateGeneration() async {
        for i in 1...10 {
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run { generationProgress = Double(i) / 10.0 }
        }
    }
    
    private func generateDocumentContent() -> String {
        switch selectedDocumentType {
        case .complaint:
            return """
            民事起诉状
            
            原告：[当事人信息]
            被告：[当事人信息]
            
            诉讼请求：
            1. 请求人民法院判决...
            2. 诉讼费用由被告承担
            
            事实和理由：
            [案件事实描述]
            
            此致
            [法院名称]
            
            起诉人：[签名]
            日期：\(Date().formatted(.dateTime.year().month().day()))
            """
        case .response:
            return """
            民事答辩状
            
            答辩人：[当事人信息]
            
            针对原告的起诉，答辩人提出如下答辩意见：
            
            一、事实部分
            [对原告主张事实的回应]
            
            二、法律分析
            [法律依据和分析]
            
            三、答辩请求
            请求人民法院驳回原告的诉讼请求。
            
            此致
            [法院名称]
            
            答辩人：[签名]
            日期：\(Date().formatted(.dateTime.year().month().day()))
            """
        default:
            return """
            \(selectedDocumentType.rawValue)
            
            文档名称：\(documentName)
            生成时间：\(Date().formatted(.dateTime.year().month().day()))
            \(documentDescription.isEmpty ? "" : "\n描述：\(documentDescription)")
            
            [文档内容将根据具体类型生成]
            """
        }
    }
}

// MARK: - 支持组件
struct DocumentTypeCard: View {
    let type: CaseDocumentType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : type.color)
                Text(type.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? type.color : type.color.opacity(0.3))
            )
        }
        .buttonStyle(.plain)
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.white)
    }
}

#Preview {
    DocumentGenerationView(caseId: "sample-case-id")
} 