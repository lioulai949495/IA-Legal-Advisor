import SwiftUI

struct CaseDocumentListView: View {
    let caseId: String
    let caseName: String
    
    @StateObject private var documentService = CaseDocumentService.shared
    @State private var searchText = ""
    @State private var selectedCategory: CaseDocumentCategory? = nil
    @State private var selectedSortOption: DocumentSortOption = .dateUpdated
    @State private var showingUploadSheet = false
    @State private var showingFilterSheet = false
    @State private var showingDocumentDetail: CaseDocument?
    
    private var filteredDocuments: [CaseDocument] {
        let filter = DocumentFilter(
            category: selectedCategory,
            searchText: searchText
        )
        return documentService.searchDocuments(
            in: caseId,
            filter: filter,
            sortBy: selectedSortOption
        )
    }
    
    private var documentStats: CaseDocumentStats {
        documentService.getDocumentStats(for: caseId)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 统计信息卡片
                statsCardView
                    .padding(.horizontal)
                    .padding(.top)
                
                // 分类过滤器
                categoryFilterView
                    .padding(.horizontal)
                
                // 文档列表
                if filteredDocuments.isEmpty {
                    emptyStateView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    documentsListView
                }
                
                Spacer()
            }
            .navigationTitle("案件文书")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "搜索文档名称、内容或标签...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // 筛选按钮
                        Button {
                            showingFilterSheet = true
                        } label: {
                            Image(systemName: "line.horizontal.3.decrease.circle")
                                .foregroundColor(AppTheme.accentColor)
                        }
                        
                        // 上传按钮
                        Button {
                            showingUploadSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(AppTheme.accentColor)
                        }
                    }
                }
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
        }
        .sheet(isPresented: $showingUploadSheet) {
            DocumentUploadSheet(caseId: caseId)
        }
        .sheet(isPresented: $showingFilterSheet) {
            DocumentFilterSheet(
                selectedCategory: $selectedCategory,
                selectedSortOption: $selectedSortOption
            )
        }
        .sheet(item: $showingDocumentDetail) { document in
            DocumentDetailView(document: document, caseId: caseId)
        }
    }
    
    // MARK: - 统计卡片
    private var statsCardView: some View {
        HStack(spacing: 20) {
            StatItemView(
                title: "总文档",
                value: "\(documentStats.totalCount)",
                icon: "doc.fill",
                color: .blue
            )
            
            StatItemView(
                title: "上传文件",
                value: "\(documentStats.uploadedCount)",
                icon: "arrow.up.doc",
                color: .green
            )
            
            StatItemView(
                title: "生成文书",
                value: "\(documentStats.generatedCount)",
                icon: "doc.richtext",
                color: .orange
            )
            
            StatItemView(
                title: "总大小",
                value: ByteCountFormatter.string(fromByteCount: documentStats.totalSize, countStyle: .file),
                icon: "archivebox",
                color: .purple
            )
        }
        .padding()
        .liquidGlass()
    }
    
    // MARK: - 分类过滤器
    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                DocumentCategoryChip(
                    title: "全部",
                    count: documentStats.totalCount,
                    isSelected: selectedCategory == nil,
                    color: .gray
                ) {
                    selectedCategory = nil
                }
                
                DocumentCategoryChip(
                    title: CaseDocumentCategory.uploaded.rawValue,
                    count: documentStats.uploadedCount,
                    isSelected: selectedCategory == .uploaded,
                    color: CaseDocumentCategory.uploaded.color
                ) {
                    selectedCategory = .uploaded
                }
                
                DocumentCategoryChip(
                    title: CaseDocumentCategory.generated.rawValue,
                    count: documentStats.generatedCount,
                    isSelected: selectedCategory == .generated,
                    color: CaseDocumentCategory.generated.color
                ) {
                    selectedCategory = .generated
                }
                
                DocumentCategoryChip(
                    title: CaseDocumentCategory.analysis.rawValue,
                    count: documentStats.analysisCount,
                    isSelected: selectedCategory == .analysis,
                    color: CaseDocumentCategory.analysis.color
                ) {
                    selectedCategory = .analysis
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - 文档列表
    private var documentsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredDocuments) { document in
                    DocumentRowView(
                        document: document,
                        onTap: {
                            showingDocumentDetail = document
                        },
                        onDownload: {
                            Task {
                                await documentService.downloadDocument(document.id, from: caseId)
                            }
                        },
                        onShare: {
                            shareDocument(document)
                        },
                        onDelete: {
                            deleteDocument(document)
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("暂无文档")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("点击右上角的"+"按钮上传文档\n或者通过AI生成法律文书")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button("上传文档") {
                showingUploadSheet = true
            }
            .primaryButtonStyle()
            .frame(maxWidth: 200)
        }
        .padding()
    }
    
    // MARK: - 操作方法
    private func shareDocument(_ document: CaseDocument) {
        let result = documentService.shareDocument(document.id, from: caseId)
        // TODO: 实现实际的分享功能
        print("Share document: \(result.message)")
    }
    
    private func deleteDocument(_ document: CaseDocument) {
        let result = documentService.deleteDocument(document.id, from: caseId)
        if !result.success, let error = result.error {
            print("Delete failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - 统计项视图
struct StatItemView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline.bold())
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 文档分类芯片
struct DocumentCategoryChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.bold())
                
                Text("\(count)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color.white.opacity(0.1))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 文档行视图
struct DocumentRowView: View {
    let document: CaseDocument
    let onTap: () -> Void
    let onDownload: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void
    
    @State private var showingActionSheet = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 文档图标
                Image(systemName: document.fileIcon)
                    .font(.title2)
                    .foregroundColor(document.type.color)
                    .frame(width: 40, height: 40)
                    .background(document.type.color.opacity(0.1))
                    .cornerRadius(8)
                
                // 文档信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(document.type.rawValue)
                        .font(.caption)
                        .foregroundColor(document.type.color)
                    
                    HStack {
                        Text(document.formattedFileSize)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Text(document.createdBy.rawValue)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.4))
                        
                        Text(RelativeDateTimeFormatter().localizedString(for: document.createdAt, relativeTo: Date()))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // 操作按钮
                Button {
                    showingActionSheet = true
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white.opacity(0.7))
                        .padding(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .liquidGlass()
        }
        .buttonStyle(PlainButtonStyle())
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text(document.name),
                buttons: [
                    .default(Text("下载")) { onDownload() },
                    .default(Text("分享")) { onShare() },
                    .destructive(Text("删除")) { onDelete() },
                    .cancel()
                ]
            )
        }
    }
}

// MARK: - 预览
#Preview {
    CaseDocumentListView(caseId: "case123", caseName: "劳动合同纠纷")
        .environmentObject(AppViewModel())
}