import SwiftUI
import UniformTypeIdentifiers

struct DocumentUploadSheet: View {
    let caseId: String
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var documentService = CaseDocumentService.shared
    
    @State private var selectedFiles: [URL] = []
    @State private var documentName = ""
    @State private var selectedType: CaseDocumentType = .evidence
    @State private var documentDescription = ""
    @State private var tags = ""
    @State private var showingFilePicker = false
    @State private var isUploading = false
    @State private var uploadProgress = 0.0
    @State private var showingSuccess = false
    
    private var tagArray: [String] {
        tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
    
    private var canUpload: Bool {
        !selectedFiles.isEmpty && !documentName.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 文件选择区域
                    fileSelectionArea
                    
                    // 基本信息输入
                    documentInfoSection
                    
                    // 分类选择
                    typeSelectionSection
                    
                    // 标签和描述
                    additionalInfoSection
                    
                    // 上传按钮
                    uploadButtonSection
                }
                .padding()
            }
            .navigationTitle("上传文档")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .sheet(isPresented: $showingFilePicker) {
                DocumentPicker { documents in
                    selectedFiles = documents.compactMap { doc in
                        // 将DocumentFile转换为URL（需要适配现有的DocumentPicker）
                        // 这里需要根据实际的DocumentPicker实现来调整
                        return nil
                    }
                }
            }
        }
    }
    
    // MARK: - 文件选择区域
    private var fileSelectionArea: some View {
        VStack(spacing: 16) {
            // 文件选择按钮
            Button {
                showingFilePicker = true
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: selectedFiles.isEmpty ? "plus.circle.dashed" : "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(selectedFiles.isEmpty ? AppTheme.accentColor : .green)
                    
                    Text(selectedFiles.isEmpty ? "选择文件" : "已选择 \(selectedFiles.count) 个文件")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("支持 PDF、图片、Word 等格式\n单个文件最大 50MB")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.accentColor, style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .background(Color.white.opacity(0.05))
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 已选择的文件列表
            if !selectedFiles.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(selectedFiles.enumerated()), id: \.offset) { index, fileURL in
                        HStack {
                            Image(systemName: getFileIcon(for: fileURL))
                                .foregroundColor(AppTheme.accentColor)
                            
                            Text(fileURL.lastPathComponent)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Button {
                                selectedFiles.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // MARK: - 文档信息输入
    private var documentInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("基本信息")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("文档名称")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                TextField("请输入文档名称", text: $documentName)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - 类型选择
    private var typeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("文档类型")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(CaseDocumentType.allCases.filter { $0.category == .uploaded }, id: \.self) { type in
                    DocumentTypeCard(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        selectedType = type
                    }
                }
            }
        }
    }
    
    // MARK: - 附加信息
    private var additionalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("附加信息")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("标签（用逗号分隔）")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                TextField("例如：重要,证据,合同", text: $tags)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("描述（可选）")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Group {
                    if #available(iOS 16.0, *) {
                        TextField("请输入文档描述", text: $documentDescription, axis: .vertical)
                            .lineLimit(3...6)
                    } else {
                        // iOS 15兼容性处理
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $documentDescription)
                                .frame(minHeight: 80, maxHeight: 120)
                                .background(Color.clear)
                            
                            if documentDescription.isEmpty {
                                Text("请输入文档描述")
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - 上传按钮
    private var uploadButtonSection: some View {
        VStack(spacing: 16) {
            if isUploading {
                VStack(spacing: 8) {
                    ProgressView(value: uploadProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor))
                    
                    Text("上传中... \(Int(uploadProgress * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Button {
                uploadDocuments()
            } label: {
                HStack {
                    if isUploading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.up.doc")
                    }
                    
                    Text(isUploading ? "上传中..." : "开始上传")
                        .font(.headline.bold())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canUpload ? AnyView(AppTheme.accentGradient) : AnyView(Color.gray))
                .cornerRadius(12)
            }
            .disabled(!canUpload || isUploading)
        }
    }
    
    // MARK: - 辅助方法
    private func getFileIcon(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.fill"
        case "jpg", "jpeg", "png", "heic": return "photo"
        case "doc", "docx": return "doc.richtext"
        case "txt": return "doc.text"
        default: return "doc"
        }
    }
    
    private func uploadDocuments() {
        guard canUpload else { return }
        
        isUploading = true
        uploadProgress = 0.0
        
        Task {
            var allResults: [DocumentOperationResult] = []
            let totalFiles = selectedFiles.count
            
            for (index, fileURL) in selectedFiles.enumerated() {
                let result = await documentService.uploadDocument(
                    to: caseId,
                    name: documentName.isEmpty ? fileURL.lastPathComponent : "\(documentName)_\(index + 1)",
                    type: selectedType,
                    fileURL: fileURL,
                    description: documentDescription.isEmpty ? nil : documentDescription,
                    tags: tagArray
                )
                
                allResults.append(result)
                
                await MainActor.run {
                    uploadProgress = Double(index + 1) / Double(totalFiles)
                }
            }
            
            await MainActor.run {
                isUploading = false
                
                // 检查上传结果
                let successCount = allResults.filter { $0.success }.count
                if successCount == totalFiles {
                    showingSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 文档类型卡片
struct DocumentTypeCard: View {
    let type: CaseDocumentType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : type.color)
                
                Text(type.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? type.color : Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(type.color, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DocumentUploadSheet(caseId: "case123")
}