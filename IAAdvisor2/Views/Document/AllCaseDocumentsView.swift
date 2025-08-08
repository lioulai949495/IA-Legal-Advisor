import SwiftUI

struct AllCaseDocumentsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @StateObject private var documentService = CaseDocumentService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedCaseId: String?
    @State private var selectedSortOption: DocumentSortOption = .dateUpdated
    @State private var showingFilterSheet = false
    @State private var showingDocumentDetail: CaseDocument?
    
    private var allStats: [String: CaseDocumentStats] {
        documentService.getAllDocumentsStats()
    }
    
    private var filteredCases: [(case: Case, stats: CaseDocumentStats)] {
        let casesWithDocs = viewModel.cases.compactMap { caseItem -> (Case, CaseDocumentStats)? in
            let stats = allStats[caseItem.id] ?? CaseDocumentStats.empty
            if stats.totalCount > 0 || searchText.isEmpty {
                return (caseItem, stats)
            }
            return nil
        }
        
        if searchText.isEmpty {
            return casesWithDocs.sorted { $0.1.totalCount > $1.1.totalCount }
        } else {
            return casesWithDocs.filter { 
                $0.0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var totalStats: (documents: Int, size: Int64, cases: Int) {
        let totalDocs = allStats.values.reduce(0) { $0 + $1.totalCount }
        let totalSize = allStats.values.reduce(0) { $0 + $1.totalSize }
        let activeCases = allStats.values.filter { $0.totalCount > 0 }.count
        return (totalDocs, totalSize, activeCases)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 总体统计卡片
                overallStatsCard
                    .padding(.horizontal)
                    .padding(.top)
                
                // 案件文书列表
                if filteredCases.isEmpty {
                    emptyStateView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    casesWithDocumentsList
                }
            }
            .navigationTitle("全部案件文书")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "搜索案件名称...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                            .foregroundColor(AppTheme.accentColor)
                    }
                }
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
        }
        .sheet(isPresented: $showingFilterSheet) {
            DocumentSortSheet(selectedSortOption: $selectedSortOption)
        }
        .sheet(item: $showingDocumentDetail) { document in
            DocumentDetailView(document: document, caseId: document.caseId)
        }
    }
    
    // MARK: - 总体统计卡片
    private var overallStatsCard: some View {
        let stats = totalStats
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.title2)
                    .foregroundColor(AppTheme.accentColor)
                
                Text("文书统计总览")
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            
            // 统计数字
            HStack(spacing: 20) {
                OverallStatItem(
                    title: "总文档",
                    value: "\(stats.documents)",
                    icon: "doc.fill",
                    color: .blue
                )
                
                OverallStatItem(
                    title: "总存储",
                    value: ByteCountFormatter.string(fromByteCount: stats.size, countStyle: .file),
                    icon: "archivebox.fill",
                    color: .green
                )
                
                OverallStatItem(
                    title: "活跃案件",
                    value: "\(stats.cases)",
                    icon: "folder.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .liquidGlass()
    }
    
    // MARK: - 案件文书列表
    private var casesWithDocumentsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredCases, id: \.case.id) { item in
                    CaseDocumentCard(
                        caseItem: item.case,
                        stats: item.stats,
                        onTap: {
                            // 导航到具体案件的文书列表
                            // 这里可以通过深层链接或状态管理来实现
                        },
                        onViewDocuments: {
                            selectedCaseId = item.case.id
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
            
            if searchText.isEmpty {
                Text("您还没有上传或生成任何法律文书\n开始创建案件并上传相关文档吧！")
            } else {
                Text("没有找到包含\"\(searchText)\"的案件")
            }
        }
        .font(.body)
        .foregroundColor(.white.opacity(0.7))
        .multilineTextAlignment(.center)
        .padding()
    }
}

// MARK: - 总体统计项
struct OverallStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline.bold())
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 案件文书卡片
struct CaseDocumentCard: View {
    let caseItem: Case
    let stats: CaseDocumentStats
    let onTap: () -> Void
    let onViewDocuments: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // 案件信息头部
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(caseItem.title)
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text(caseItem.caseType.rawValue)
                            .font(.subheadline)
                            .foregroundColor(caseItem.caseType.category.color)
                    }
                    
                    Spacer()
                    
                    // 状态标识
                    Text(caseItem.status.rawValue)
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(for: caseItem.status).opacity(0.3))
                        .cornerRadius(8)
                        .foregroundColor(statusColor(for: caseItem.status))
                }
                
                // 文书统计
                if stats.totalCount > 0 {
                    HStack(spacing: 16) {
                        DocumentStatBadge(
                            title: "上传",
                            count: stats.uploadedCount,
                            color: .blue
                        )
                        
                        DocumentStatBadge(
                            title: "生成",
                            count: stats.generatedCount,
                            color: .green
                        )
                        
                        DocumentStatBadge(
                            title: "分析",
                            count: stats.analysisCount,
                            color: .orange
                        )
                        
                        Spacer()
                        
                        // 查看文档按钮
                        Button("查看文档") {
                            onViewDocuments()
                        }
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.accentColor.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // 存储信息
                    HStack {
                        Text("总大小: \(ByteCountFormatter.string(fromByteCount: stats.totalSize, countStyle: .file))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        if let lastUpdated = stats.lastUpdated {
                            Text("更新: \(RelativeDateTimeFormatter().localizedString(for: lastUpdated, relativeTo: Date()))")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                } else {
                    Text("暂无文档")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .liquidGlass()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statusColor(for status: CaseStatus) -> Color {
        switch status {
        case .active: return .green
        case .completed: return .blue
        case .archived: return .gray
        }
    }
}

// MARK: - 文书统计徽章
struct DocumentStatBadge: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Text("\(count)")
                .font(.caption.bold())
                .foregroundColor(color)
        }
    }
}

// MARK: - 文档排序选择器
struct DocumentSortSheet: View {
    @Binding var selectedSortOption: DocumentSortOption
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ForEach(DocumentSortOption.allCases, id: \.self) { option in
                    Button {
                        selectedSortOption = option
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: option.systemImage)
                                .foregroundColor(AppTheme.accentColor)
                            
                            Text(option.rawValue)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            if selectedSortOption == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.accentColor)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("排序方式")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentColor)
                }
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
        }
    }
}

#Preview {
    AllCaseDocumentsView()
        .environmentObject(AppViewModel())
}