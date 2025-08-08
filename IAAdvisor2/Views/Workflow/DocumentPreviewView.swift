import SwiftUI
import PDFKit

/// 文档预览视图
struct DocumentPreviewView: View {
    let document: RequiredDocument
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDownloadConfirmation = false
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 文档信息头部
                documentHeader
                
                // 预览内容
                previewContent
                
                // 底部操作栏
                actionBar
            }
            .background(Color.black.ignoresSafeArea())
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
                        if document.template != nil {
                            Button("下载模板") {
                                downloadTemplate()
                            }
                        }
                        
                        if document.sampleDocument != nil {
                            Button("保存样表") {
                                saveSample()
                            }
                        }
                        
                        Button("分享文档") {
                            shareDocument()
                        }
                        
                        Button("打印文档") {
                            printDocument()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .confirmationDialog("下载确认", isPresented: $showingDownloadConfirmation) {
            Button("下载模板") {
                startDownload()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("是否下载 \(document.name) 到本地？")
        }
    }
    
    // MARK: - 视图组件
    
    private var documentHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: documentIcon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(document.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                if document.isRequired {
                    Text("必需")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.red.opacity(0.3)))
                }
            }
            
            if let deadline = document.submissionDeadline {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    
                    Text("截止时间: \(DateFormatter.shortDateTime.string(from: deadline))")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            HStack {
                Image(systemName: "arrow.up.doc.fill")
                    .foregroundColor(.green)
                
                Text("提交方式: \(document.submissionMethod.rawValue)")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
    
    private var previewContent: some View {
        ZStack {
            if let sampleDoc = document.sampleDocument {
                // 显示样表预览
                SampleDocumentPreview(sampleDocument: sampleDoc)
            } else if let template = document.template {
                // 显示模板信息
                TemplateInfoView(template: template)
            } else {
                // 无预览内容
                NoPreviewView()
            }
            
            // 下载进度覆盖层
            if isDownloading {
                DownloadProgressOverlay(progress: downloadProgress)
            }
        }
    }
    
    private var actionBar: some View {
        VStack(spacing: 12) {
            if isDownloading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    
                    Text("下载中... \(Int(downloadProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding()
            } else {
                HStack(spacing: 16) {
                    if document.template != nil {
                        Button("下载模板") {
                            showingDownloadConfirmation = true
                        }
                        .buttonStyle(PrimaryDocumentButtonStyle())
                    }
                    
                    if document.sampleDocument != nil {
                        Button("查看示例") {
                            // 处理查看示例
                        }
                        .buttonStyle(SecondaryDocumentButtonStyle())
                    }
                    
                    Button("使用指南") {
                        // 显示使用指南
                    }
                    .buttonStyle(SecondaryDocumentButtonStyle())
                }
                .padding()
            }
        }
        .background(Color.black.opacity(0.5))
    }
    
    // MARK: - 辅助属性
    
    private var documentIcon: String {
        if document.template != nil {
            return "doc.badge.gearshape"
        } else if document.sampleDocument != nil {
            return "doc.text.magnifyingglass"
        } else {
            return "doc"
        }
    }
    
    // MARK: - 操作方法
    
    private func downloadTemplate() {
        showingDownloadConfirmation = true
    }
    
    private func saveSample() {
        // 处理保存样表
    }
    
    private func shareDocument() {
        // 处理文档分享
    }
    
    private func printDocument() {
        // 处理文档打印
    }
    
    private func startDownload() {
        isDownloading = true
        downloadProgress = 0
        
        // 模拟下载过程
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            downloadProgress += 0.05
            
            if downloadProgress >= 1.0 {
                timer.invalidate()
                isDownloading = false
                downloadProgress = 0
            }
        }
    }
}

// MARK: - 预览内容视图

struct SampleDocumentPreview: View {
    let sampleDocument: SampleDocument
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 文档描述
                VStack(alignment: .leading, spacing: 8) {
                    Text("文档说明")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(sampleDocument.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )
                
                // 标注说明
                if !sampleDocument.annotations.isEmpty {
                    AnnotationsView(annotations: sampleDocument.annotations)
                }
                
                // 模拟PDF预览区域
                MockDocumentPreview(documentName: sampleDocument.name)
            }
            .padding()
        }
    }
}

struct TemplateInfoView: View {
    let template: DocumentTemplate
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 模板信息
                VStack(alignment: .leading, spacing: 12) {
                    Text("模板信息")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        DocumentInfoRow(title: "文件格式", value: template.fileFormat)
                        DocumentInfoRow(title: "可填字段", value: "\(template.fillableFields.count)个")
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )
                
                // 填写指南
                VStack(alignment: .leading, spacing: 12) {
                    Text("填写指南")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(template.instructions)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                )
                
                // 可填字段列表
                if !template.fillableFields.isEmpty {
                    FillableFieldsView(fields: template.fillableFields)
                }
            }
            .padding()
        }
    }
}

struct NoPreviewView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("暂无预览")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("此文档暂时无法预览，您可以下载后查看")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 辅助视图组件

struct AnnotationsView: View {
    let annotations: [DocumentAnnotation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("重要标注")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(annotations, id: \.id) { annotation in
                    AnnotationItem(annotation: annotation)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

struct AnnotationItem: View {
    let annotation: DocumentAnnotation
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: annotationIcon)
                .foregroundColor(annotationColor)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(annotation.annotationType.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                
                Text(annotation.content)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    private var annotationIcon: String {
        switch annotation.annotationType {
        case .signature: return "signature"
        case .seal: return "hand.thumbsup.fill"
        case .fillText: return "pencil"
        case .attention: return "exclamationmark.triangle.fill"
        }
    }
    
    private var annotationColor: Color {
        switch annotation.annotationType {
        case .signature: return .blue
        case .seal: return .purple
        case .fillText: return .green
        case .attention: return .orange
        }
    }
}

struct MockDocumentPreview: View {
    let documentName: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text("文档预览")
                .font(.headline)
                .foregroundColor(.white)
            
            // 模拟文档页面
            VStack(spacing: 1) {
                ForEach(0..<3, id: \.self) { pageIndex in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 12) {
                                Text(documentName)
                                    .font(.headline)
                                    .foregroundColor(.black)
                                
                                Text("第 \(pageIndex + 1) 页")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                // 模拟文档内容线条
                                VStack(spacing: 4) {
                                    ForEach(0..<6, id: \.self) { _ in
                                        RoundedRectangle(cornerRadius: 1)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(height: 2)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
                }
            }
            .padding()
        }
    }
}

struct FillableFieldsView: View {
    let fields: [FillableField]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("需要填写的字段")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(fields, id: \.id) { field in
                    FillableFieldItem(field: field)
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

struct FillableFieldItem: View {
    let field: FillableField
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(field.fieldName)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    if field.isRequired {
                        Text("必填")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.red.opacity(0.3)))
                    }
                    
                    Spacer()
                    
                    Text(field.fieldType.rawValue)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.blue.opacity(0.2)))
                }
                
                Text(field.placeholder)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                if field.signatureField || field.sealField {
                    HStack(spacing: 8) {
                        if field.signatureField {
                            HStack(spacing: 4) {
                                Image(systemName: "signature")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text("需要签字")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        if field.sealField {
                            HStack(spacing: 4) {
                                Image(systemName: "hand.thumbsup.fill")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                                Text("需要盖章")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                        }
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

struct DocumentInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
    }
}

struct DownloadProgressOverlay: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(2.0)
                    .tint(.white)
                
                Text("下载中...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .tint(AppTheme.accentColor)
                        .frame(width: 200)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
}

// MARK: - 按钮样式

struct PrimaryDocumentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppTheme.accentColor.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryDocumentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white.opacity(configuration.isPressed ? 0.15 : 0.1))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    DocumentPreviewView(
        document: RequiredDocument(
            id: "1",
            name: "起诉状模板",
            description: "民事起诉状标准模板",
            isRequired: true,
            template: DocumentTemplate(
                id: "1",
                name: "起诉状模板",
                downloadUrl: nil,
                fillableFields: [
                    FillableField(
                        id: "1",
                        fieldName: "原告姓名",
                        fieldType: .text,
                        isRequired: true,
                        placeholder: "请输入原告姓名",
                        validationRules: [],
                        signatureField: false,
                        sealField: false
                    )
                ],
                instructions: "请按照模板填写相关信息",
                fileFormat: "PDF"
            ),
            sampleDocument: nil,
            submissionDeadline: nil,
            submissionMethod: .online
        )
    )
}