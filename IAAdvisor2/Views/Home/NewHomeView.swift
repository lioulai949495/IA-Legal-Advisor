import SwiftUI

struct NewHomeView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var searchText = ""
    @State private var selectedNewsType: LegalNewsType = .hotNews
    @State private var showingSearch = false
    @State private var selectedNews: LegalNews?
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 搜索栏
                searchSection
                
                // 快速入口
                quickAccessSection
                
                // 法律热点
                newsSection
                
                // 案例库推荐
                caseLibrarySection
                
                // 法规速查
                regulationSection
            }
            .padding(.horizontal)
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .onTapGesture {
            hideKeyboard()
        }
        .sheet(item: $selectedNews) { news in
            NewsDetailView(news: news)
        }
        .sheet(isPresented: $showingSearch) {
            SearchView()
        }
        .alert("操作反馈", isPresented: $showAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - 搜索栏
    private var searchSection: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("搜索法律法规、案例...", text: $searchText)
                    .onTapGesture {
                        showingSearch = true
                    }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .liquidGlass()
        }
    }
    
    // MARK: - 快速入口
    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("快速服务")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                QuickAccessCard(
                    icon: "questionmark.circle.fill",
                    title: "AI法律咨询",
                    subtitle: "即时解答法律问题",
                    color: .blue
                ) {
                    print("点击AI法律咨询，切换到tab 2")
                    viewModel.selectedTab = 2
                    alertMessage = "已跳转到咨询页面"
                    showAlert = true
                }
                
                QuickAccessCard(
                    icon: "folder.fill",
                    title: "新建案件",
                    subtitle: "智能案件分析",
                    color: .green
                ) {
                    print("点击新建案件，切换到tab 1")
                    viewModel.selectedTab = 1
                    alertMessage = "已跳转到案件页面"
                    showAlert = true
                }
                
                QuickAccessCard(
                    icon: "doc.text.fill",
                    title: "表单工具",
                    subtitle: "法律文书下载",
                    color: .orange
                ) {
                    alertMessage = "表单工具功能正在开发中"
                    showAlert = true
                }
                
                QuickAccessCard(
                    icon: "person.crop.circle.badge.checkmark",
                    title: "人工律师",
                    subtitle: "专业律师咨询",
                    color: .purple
                ) {
                    alertMessage = "人工律师服务正在开发中"
                    showAlert = true
                }
            }
        }
    }
    
    // MARK: - 法律热点
    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("法律热点")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("更多") {
                    alertMessage = "更多法律热点功能正在开发中"
                    showAlert = true
                }
                .foregroundColor(AppTheme.accentColor)
            }
            
            // 分类选择
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(LegalNewsType.allCases, id: \.self) { type in
                        NewsTypeChip(
                            type: type,
                            isSelected: selectedNewsType == type
                        ) {
                            selectedNewsType = type
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // 新闻列表
            LazyVStack(spacing: 12) {
                ForEach(NewSampleData.legalNews.filter { $0.type == selectedNewsType }) { news in
                    NewsCard(news: news) {
                        selectedNews = news
                    }
                }
            }
        }
    }
    
    // MARK: - 案例库
    private var caseLibrarySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("相似案例")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("案例库") {
                    alertMessage = "案例库功能正在开发中"
                    showAlert = true
                }
                .foregroundColor(AppTheme.accentColor)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(0..<3) { index in
                        Button {
                            alertMessage = "案例详情查看功能正在开发中"
                            showAlert = true
                        } label: {
                            CaseCard(
                                title: "劳动合同纠纷案例",
                                summary: "员工因公司违法解除劳动合同，申请仲裁获得赔偿...",
                                similarity: 0.85,
                                caseType: .laborDispute
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 法规速查
    private var regulationSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("法规速查")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("法规库") {
                    alertMessage = "法规库功能正在开发中"
                    showAlert = true
                }
                .foregroundColor(AppTheme.accentColor)
            }
            
            VStack(spacing: 10) {
                Button {
                    alertMessage = "劳动法详情查看功能正在开发中"
                    showAlert = true
                } label: {
                    RegulationQuickItem(title: "劳动法", category: "劳动人事", updateDate: "2024年修订")
                }
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    alertMessage = "民法典详情查看功能正在开发中"
                    showAlert = true
                } label: {
                    RegulationQuickItem(title: "民法典", category: "民事法律", updateDate: "2021年实施")
                }
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    alertMessage = "消费者权益保护法详情查看功能正在开发中"
                    showAlert = true
                } label: {
                    RegulationQuickItem(title: "消费者权益保护法", category: "消费权益", updateDate: "2023年修订")
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - 子组件

struct QuickAccessCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .liquidGlass()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NewsTypeChip: View {
    let type: LegalNewsType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.caption)
                Text(type.rawValue)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? type.color : Color.white.opacity(0.1))
            )
            .foregroundColor(isSelected ? .white : .white.opacity(0.8))
        }
    }
}

struct NewsCard: View {
    let news: LegalNews
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // 类型标识
                VStack {
                    Image(systemName: news.type.icon)
                        .font(.title3)
                        .foregroundColor(news.type.color)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(news.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(news.summary)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                    
                    HStack {
                        Text(news.source)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Text(news.publishDate, style: .date)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
            }
            .padding()
            .liquidGlass()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CaseCard: View {
    let title: String
    let summary: String
    let similarity: Double
    let caseType: CaseType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: caseType.icon)
                    .foregroundColor(AppTheme.accentColor)
                
                Text(caseType.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(similarity * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(.green)
            }
            
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            Text(summary)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(3)
        }
        .frame(width: 200, alignment: .leading)
        .padding()
        .liquidGlass()
    }
}

struct RegulationQuickItem: View {
    let title: String
    let category: String
    let updateDate: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                HStack {
                    Text(category)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text(updateDate)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding()
        .liquidGlass()
    }
}

// MARK: - 新闻详情页面
struct NewsDetailView: View {
    let news: LegalNews
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 标题和元信息
                    VStack(alignment: .leading, spacing: 10) {
                        Text(news.title)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        HStack {
                            Label(news.source, systemImage: "building.2.fill")
                            Spacer()
                            Label(news.publishDate.formatted(), systemImage: "calendar")
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // 摘要
                    Text(news.summary)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .padding()
                        .liquidGlass()
                    
                    // 正文
                    Text(news.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .lineSpacing(4)
                    
                    // 标签
                    if !news.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(news.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(AppTheme.accentColor.opacity(0.3))
                                        .cornerRadius(8)
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - 搜索页面
struct SearchView: View {
    @State private var searchText = ""
    @State private var searchCategory: SearchCategory = .all
    @Environment(\.dismiss) private var dismiss
    
    enum SearchCategory: String, CaseIterable {
        case all = "全部"
        case law = "法律法规"
        case case_ = "案例"
        case news = "资讯"
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 搜索栏
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("搜索法律法规、案例...", text: $searchText)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    
                    Button("搜索") {
                        // 执行搜索
                    }
                    .foregroundColor(AppTheme.accentColor)
                }
                .padding()
                
                // 分类选择
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(SearchCategory.allCases, id: \.self) { category in
                            Button(category.rawValue) {
                                searchCategory = category
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(searchCategory == category ? AppTheme.accentColor : Color.white.opacity(0.1))
                            )
                            .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 搜索结果
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(0..<10) { index in
                            SearchResultItem(
                                title: "搜索结果 \(index + 1)",
                                subtitle: "这是搜索结果的描述信息...",
                                category: "法律法规"
                            )
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("搜索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct SearchResultItem: View {
    let title: String
    let subtitle: String
    let category: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.accentColor.opacity(0.3))
                    .cornerRadius(6)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
        }
        .padding()
        .liquidGlass()
    }
}

#Preview {
    NewHomeView()
        .environmentObject(AppViewModel())
}