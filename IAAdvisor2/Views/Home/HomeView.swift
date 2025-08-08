import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var searchText = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                // 内容
                VStack(spacing: 0) {
                    // 内容区域
                    ScrollView {
                        VStack(spacing: 16) {  // 减少默认间距
                            // 搜索栏
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.white.opacity(0.7))
                                
                                TextField("搜索法律问题、案例或资讯...", text: $searchText)
                                    .foregroundColor(.white)
                                
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .liquidGlass(opacity: 0.6)
                            
                            // 顶部热门轮播
                            featuredNewsSection
                            
                            // 新闻分类选择器
                            newsCategorySelector
                            
                            // 新闻列表
                            newsListSection
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 0) // 移除垂直内边距
                    }
                    .padding(.top, geometry.safeAreaInsets.top + 44 - 15) // 减少15pt的额外间距
                }
                
                // 加载指示器
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
                
                // 顶部导航栏 - 简单设计
                VStack(spacing: 0) {
                    // 系统状态栏占位
                    Color.clear
                        .frame(height: geometry.safeAreaInsets.top)
                    
                    // 导航栏内容
                    ZStack {
                        // 简单背景
                        Color.black.opacity(0.3)
                        
                        HStack {
                            Spacer()
                            
                            // 标题
                            Text("法律资讯")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                            .padding(.trailing, 16)
                        }
                    }
                    .frame(height: 44)
                    
                    Spacer()
                }
                .background(Color.black.opacity(0.2))
            }
        }
        .onAppear {
            viewModel.fetchNewsItems(category: .latestLaws)
        }
    }
    
    // 顶部特色新闻轮播
    private var featuredNewsSection: some View {
        TabView {
            ForEach(0..<3) { index in
                ZStack(alignment: .bottomLeading) {
                    // 图片背景（模拟）
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: ["scale.3d", "building.columns", "doc.text.fill"][index % 3])
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.3))
                                .offset(x: 50, y: -20)
                        )
                    
                    // 信息叠加层
                    VStack(alignment: .leading, spacing: 8) {
                        Text(["最新法规解读", "典型案例分析", "司法观点"][index % 3])
                            .font(.headline)
                            .foregroundColor(AppTheme.accentColor)
                        
                        Text(["《民法典》物权编新规对房产交易影响深度分析", 
                              "劳动合同纠纷典型案例：未签书面合同如何维权", 
                              "最高法观点：电商平台责任边界再明确"][index % 3])
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("查看详情 >")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 5)
                    }
                    .padding()
                    .padding(.bottom, 10)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.accentColor.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: AppTheme.accentColor.opacity(0.2), radius: 10)
            }
        }
        .frame(height: 200)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
    
    // 新闻分类选择器
    private var newsCategorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(NewsCategory.allCases, id: \.self) { category in
                    Button(action: { viewModel.fetchNewsItems(category: category) }) {
                        Text(category.rawValue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(viewModel.selectedNewsCategory == category ? 
                                          AppTheme.accentColor : Color.white.opacity(0.1))
                            )
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 5)
        }
    }
    
    // 新闻列表
    private var newsListSection: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.newsItems.isEmpty ? SampleData.newsItems : viewModel.newsItems) { item in
                NewsCardView(item: item)
            }
        }
    }
}

// 新闻卡片视图组件
struct NewsCardView: View {
    let item: NewsItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 来源和日期
            HStack {
                Text(item.source)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppTheme.accentColor.opacity(0.3))
                    )
                
                Spacer()
                
                Text(formattedDate(item.publishDate))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // 标题
            Text(item.title)
                .font(.headline)
                .lineLimit(2)
            
            // 摘要
            Text(item.summary)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // 阅读量和分享
            HStack {
                Label("\(Int.random(in: 100...9999))", systemImage: "eye.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .liquidGlass(opacity: 0.9, cornerRadius: 16)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppViewModel())
} 