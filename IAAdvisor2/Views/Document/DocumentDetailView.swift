import SwiftUI
import QuickLook

struct DocumentDetailView: View {
    let document: CaseDocument
    let caseId: String
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var documentService = CaseDocumentService.shared
    
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    @State private var shareItems: [Any] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 文档基本信息
                    documentInfoSection
                    
                    // 文档内容预览
                    documentContentSection
                    
                    // 文档元数据
                    documentMetadataSection
                    
                    // 标签
                    if !document.tags.isEmpty {
                        documentTagsSection
                    }
                    
                    // 操作按钮
                    actionButtonsSection
                }
                .padding()
            }
            .navigationTitle(document.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            downloadDocument()
                        } label: {
                            Label("下载", systemImage: "arrow.down.circle")
                        }
                        
                        Button {
                            shareDocument()
                        } label: {
                            Label("分享", systemImage: "square.and.arrow.up")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                    }
                }
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
        }
        .alert("删除文档", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteDocument()
            }
        } message: {
            Text("确定要删除文档\"\(document.name)\"吗？此操作无法撤销。")
        }
        .sheet(isPresented: $showingShareSheet) {
            if #available(iOS 16.0, *) {
                ShareSheet(items: shareItems)
            } else {
                // iOS 15兼容性处理
                Text("分享功能需要 iOS 16+")
            }
        }
    }
    
    // MARK: - 文档基本信息
    private var documentInfoSection: some View {
        VStack(spacing: 16) {
            // 文档图标和类型
            HStack(spacing: 16) {
                Image(systemName: document.fileIcon)
                    .font(.system(size: 50))
                    .foregroundColor(document.type.color)
                    .frame(width: 80, height: 80)
                    .background(document.type.color.opacity(0.1))
                    .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(document.name)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .lineLimit(3)
                    
                    Text(document.type.rawValue)
                        .font(.subheadline)
                        .foregroundColor(document.type.color)
                    
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(.white.opacity(0.6))
                        Text(document.createdBy.rawValue)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
            }
            
            // 描述
            if let description = document.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("描述")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .liquidGlass()
    }
    
    // MARK: - 文档内容预览
    private var documentContentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("内容预览")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            if document.isTextType, let content = document.content {
                // 文本内容预览
                ScrollView {
                    Text(content)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(12)
                }
                .frame(maxHeight: 300)
            } else if document.isImageType {
                // 图片预览
                AsyncImage(url: document.filePath != nil ? URL(fileURLWithPath: document.filePath!) : nil) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(12)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            ProgressView()
                                .tint(.white)
                        )
                }
                .frame(maxHeight: 400)
            } else {
                // 其他类型文件
                HStack {
                    Image(systemName: document.fileIcon)
                        .font(.title)
                        .foregroundColor(document.type.color)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("无法预览此文件类型")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        
                        Text("点击下载后在对应应用中打开")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .liquidGlass()
    }
    
    // MARK: - 文档元数据
    private var documentMetadataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("文档信息")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                MetadataRow(title: "文件大小", value: document.formattedFileSize, icon: "archivebox")
                MetadataRow(title: "创建时间", value: formatDate(document.createdAt), icon: "calendar.badge.plus")
                MetadataRow(title: "更新时间", value: formatDate(document.updatedAt), icon: "calendar.badge.clock")
                
                if let fileExtension = document.fileExtension {
                    MetadataRow(title: "文件格式", value: fileExtension.uppercased(), icon: "doc.badge.gearshape")
                }
                
                MetadataRow(title: "版本", value: "v\(document.version)", icon: "number.circle")
                MetadataRow(title: "状态", value: document.isDownloaded ? "已下载" : "云端存储", icon: document.isDownloaded ? "checkmark.circle.fill" : "icloud")
            }
        }
        .padding()
        .liquidGlass()
    }
    
    // MARK: - 标签
    private var documentTagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("标签")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            if #available(iOS 16.0, *) {
                FlowLayout(alignment: .leading, spacing: 8) {
                    ForEach(document.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.accentColor.opacity(0.3))
                            .cornerRadius(16)
                    }
                }
            } else {
                // iOS 15兼容性 - 使用简单的垂直排列
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(stride(from: 0, to: document.tags.count, by: 3)), id: \.self) { startIndex in
                        HStack(spacing: 8) {
                            ForEach(startIndex..<min(startIndex + 3, document.tags.count), id: \.self) { index in
                                Text(document.tags[index])
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.accentColor.opacity(0.3))
                                    .cornerRadius(16)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding()
        .liquidGlass()
    }
    
    // MARK: - 操作按钮
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // 下载按钮
            Button {
                downloadDocument()
            } label: {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("下载文档")
                        .font(.headline.bold())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.accentGradient)
                .cornerRadius(12)
            }
            
            // 分享按钮
            Button {
                shareDocument()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("分享文档")
                        .font(.headline.bold())
                }
                .foregroundColor(AppTheme.accentColor)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.accentColor, lineWidth: 2)
                )
            }
        }
    }
    
    // MARK: - 操作方法
    private func downloadDocument() {
        Task {
            let result = await documentService.downloadDocument(document.id, from: caseId)
            // 处理下载结果
            print("Download result: \(result.message)")
        }
    }
    
    private func shareDocument() {
        // 准备分享内容
        var items: [Any] = []
        
        // 添加文档名称和描述
        var shareText = document.name
        if let description = document.description, !description.isEmpty {
            shareText += "\n\n\(description)"
        }
        items.append(shareText)
        
        // 如果是文本文档，添加内容
        if let content = document.content {
            items.append(content)
        }
        
        // 如果有本地文件，添加文件URL
        if let filePath = document.filePath {
            let fileURL = URL(fileURLWithPath: filePath)
            items.append(fileURL)
        }
        
        shareItems = items
        showingShareSheet = true
    }
    
    private func deleteDocument() {
        let result = documentService.deleteDocument(document.id, from: caseId)
        if result.success {
            dismiss()
        }
    }
    
    // MARK: - 辅助方法
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 元数据行
struct MetadataRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(AppTheme.accentColor)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

// MARK: - 流式布局
@available(iOS 16.0, *)
struct FlowLayout: Layout {
    var alignment: Alignment = .center
    var spacing: CGFloat = 10
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            alignment: alignment,
            spacing: spacing
        )
        return result.bounds
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            alignment: alignment,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                    y: bounds.minY + result.frames[index].minY),
                         proposal: ProposedViewSize(result.frames[index].size))
        }
    }
    
    @available(iOS 16.0, *)
    struct FlowResult {
        var bounds = CGSize.zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, alignment: Alignment, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let subviewSize = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
                
                if currentX + subviewSize.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: subviewSize.width, height: subviewSize.height))
                
                currentX += subviewSize.width + spacing
                lineHeight = max(lineHeight, subviewSize.height)
            }
            
            bounds = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - 分享表单
@available(iOS 16.0, *)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    DocumentDetailView(
        document: CaseDocument(
            caseId: "case123",
            name: "劳动合同.pdf",
            type: .contract,
            fileExtension: "pdf",
            content: "这是一份劳动合同的内容...",
            fileSize: 1024000,
            tags: ["重要", "合同", "证据"],
            description: "与公司签订的劳动合同，包含工资、工作时间等重要条款。"
        ),
        caseId: "case123"
    )
}