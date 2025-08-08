import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @StateObject private var documentService = CaseDocumentService.shared
    @State private var showingSettingsSheet = false
    @State private var showingAboutSheet = false
    @State private var showingPrivacyPolicy = false
    @State private var showingUserAgreement = false
    @State private var showingAllDocuments = false
    
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
                        VStack(spacing: 24) {
                            // 头像和基本信息
                            profileHeaderView
                            
                            // 数据统计
                            statisticsView
                            
                            // 菜单选项
                            menuOptionsView
                        }
                        .padding()
                    }
                    .padding(.top, geometry.safeAreaInsets.top - AppConstants.UI.smallPadding) // 进一步减少顶部空间
                }
                .sheet(isPresented: $showingSettingsSheet) {
                    SettingsView(isPresented: $showingSettingsSheet)
                        .environmentObject(viewModel)
                }
                .sheet(isPresented: $showingAboutSheet) {
                    AboutView(isPresented: $showingAboutSheet)
                }
                .sheet(isPresented: $viewModel.showingMembershipUpgrade) {
                    MembershipUpgradeView()
                        .environmentObject(viewModel)
                }
                .sheet(isPresented: $showingPrivacyPolicy) {
                    PrivacyPolicyView()
                }
                .sheet(isPresented: $showingUserAgreement) {
                    UserAgreementView()
                }
                .sheet(isPresented: $showingAllDocuments) {
                    AllCaseDocumentsView()
                        .environmentObject(viewModel)
                }
                
                // 顶部导航栏 - 简单设计
                VStack(spacing: 0) {
                    // 系统状态栏占位
                    Color.clear
                        .frame(height: geometry.safeAreaInsets.top)
                    
                    // 导航栏内容
                    HStack {
                        Spacer()
                        
                        // 标题
                        Text("个人中心")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: { showingSettingsSheet = true }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        .padding(.trailing, 16)
                    }
                    .frame(height: 30)
                    .padding(.top, -40)
                    
                    Spacer()
                }
                .background(Color.clear)
            }
        }
    }
    
    // 个人资料头部
    private var profileHeaderView: some View {
        VStack(spacing: 16) {
            // 头像和用户信息
            HStack(spacing: 20) {
                // 头像
                ZStack {
                    Circle()
                        .fill(AppTheme.accentColor.opacity(0.3))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 35))
                        .foregroundColor(.white)
                }
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
                
                // 用户信息
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.currentUser?.username ?? "微信登录用户")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                            .font(.caption)
                            .foregroundColor(AppTheme.accentColor)
                        
                        Text(maskPhoneNumber(viewModel.currentUser?.phoneNumber ?? "135****8888"))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // 会员状态
                    Button {
                        viewModel.showMembershipUpgrade()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.currentUser?.membershipLevel.icon ?? "person.circle")
                                .font(.caption)
                                .foregroundColor(viewModel.currentUser?.membershipLevel.color ?? .gray)
                            
                            Text(viewModel.currentUser?.membershipLevel.rawValue ?? "免费版")
                                .font(.caption.bold())
                                .foregroundColor(viewModel.currentUser?.membershipLevel.color ?? .gray)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                }
                
                Spacer()
                
                // 编辑按钮
                Button(action: {}) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.2))
                        )
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .liquidGlass()
    }
    
    // 数据统计卡片
    private var statisticsView: some View {
        let allStats = documentService.getAllDocumentsStats()
        let totalDocuments = allStats.values.reduce(0) { $0 + $1.totalCount }
        let totalGenerated = allStats.values.reduce(0) { $0 + $1.generatedCount }
        
        return VStack(spacing: 16) {
            // 主要统计
            HStack(spacing: 15) {
                statisticCard(title: "案件数", value: "\(viewModel.cases.count)", icon: "folder.fill", color: .blue)
                statisticCard(title: "活跃天数", value: "12", icon: "calendar.circle.fill", color: .green)
                statisticCard(title: "总文书", value: "\(totalDocuments)", icon: "doc.text.fill", color: .orange)
            }
            
            // 文书详细统计（可点击查看详情）
            if totalDocuments > 0 {
                Button {
                    showingAllDocuments = true
                } label: {
                    documentSummaryCard(allStats: allStats)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // 单个统计卡片
    private func statisticCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            // 图标
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            // 数值
            Text(value)
                .font(.title.bold())
                .foregroundColor(.white)
            
            // 标题
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .liquidGlass(cornerRadius: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
    
    // 菜单选项列表
    private var menuOptionsView: some View {
        VStack(spacing: 8) {
            ForEach(MenuItem.allCases, id: \.self) { item in
                menuRow(title: item.title, icon: item.icon, iconColor: item.iconColor) {
                    handleMenuAction(item)
                }
            }
        }
        .liquidGlass()
    }
    
    // 单行菜单
    private func menuRow(title: String, icon: String, iconColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 图标背景
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                }
                
                // 标题
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)
                
                Spacer()
                
                // 箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            Color.white.opacity(0.15)
                .cornerRadius(12)
        )
    }
    
    // 处理菜单选项点击
    private func handleMenuAction(_ item: MenuItem) {
        switch item {
        case .membershipUpgrade:
            viewModel.showMembershipUpgrade()
        case .history:
            // 浏览历史记录
            break
        case .documents:
            // 我的文书
            break
        case .favorites:
            // 收藏内容
            break
        case .privacy:
            showingPrivacyPolicy = true
        case .userAgreement:
            showingUserAgreement = true
        case .feedback:
            // 意见反馈
            break
        case .about:
            showingAboutSheet = true
        case .logout:
            viewModel.logout()
        }
    }
    
    // 隐藏部分手机号
    private func maskPhoneNumber(_ phoneNumber: String) -> String {
        if phoneNumber.count == 11 {
            let prefix = phoneNumber.prefix(3)
            let suffix = phoneNumber.suffix(4)
            return "\(prefix)****\(suffix)"
        }
        return phoneNumber
    }
    
    // MARK: - 文书汇总卡片
    private func documentSummaryCard(allStats: [String: CaseDocumentStats]) -> some View {
        let totalUploaded = allStats.values.reduce(0) { $0 + $1.uploadedCount }
        let totalGenerated = allStats.values.reduce(0) { $0 + $1.generatedCount }
        let totalAnalysis = allStats.values.reduce(0) { $0 + $1.analysisCount }
        let totalSize = allStats.values.reduce(0) { $0 + $1.totalSize }
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.on.doc.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.accentColor)
                
                Text("案件文书总览")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // 分类统计
            HStack(spacing: 20) {
                DocumentStatMini(title: "上传", count: totalUploaded, color: .blue)
                DocumentStatMini(title: "生成", count: totalGenerated, color: .green)
                DocumentStatMini(title: "分析", count: totalAnalysis, color: .orange)
            }
            
            // 存储信息
            if totalSize > 0 {
                HStack {
                    Text("总存储：\(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text("跨 \(allStats.count) 个案件")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding()
        .liquidGlass()
    }
}

// 菜单选项
enum MenuItem: CaseIterable {
    case membershipUpgrade, history, documents, favorites, privacy, userAgreement, feedback, about, logout
    
    var title: String {
        switch self {
        case .membershipUpgrade: return "会员升级"
        case .history: return "历史记录"
        case .documents: return "我的文书"
        case .favorites: return "我的收藏"
        case .privacy: return "隐私政策"
        case .userAgreement: return "用户协议"
        case .feedback: return "意见反馈"
        case .about: return "关于我们"
        case .logout: return "退出登录"
        }
    }
    
    var icon: String {
        switch self {
        case .membershipUpgrade: return "crown.fill"
        case .history: return "clock.fill"
        case .documents: return "doc.text.fill"
        case .favorites: return "star.fill"
        case .privacy: return "lock.shield.fill"
        case .userAgreement: return "doc.plaintext.fill"
        case .feedback: return "bubble.left.and.bubble.right.fill"
        case .about: return "info.circle.fill"
        case .logout: return "rectangle.portrait.and.arrow.right.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .membershipUpgrade: return .yellow
        case .history: return .purple
        case .documents: return .blue
        case .favorites: return .yellow
        case .privacy: return .green
        case .userAgreement: return .blue
        case .feedback: return .green
        case .about: return .cyan
        case .logout: return .red
        }
    }
}

// 设置页面
struct SettingsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var viewModel: AppViewModel
    
    @State private var enableNotifications = true
    @State private var darkMode = true
    @State private var fontSize = 1
    
    var body: some View {
        NavigationView {
            List {
                // 头部
                Text("设置")
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Material.ultraThinMaterial)
                
                // 通知设置
                Section(header: Text("通知设置")) {
                    Toggle("接收消息提醒", isOn: $enableNotifications)
                }
                
                // 外观设置
                Section(header: Text("外观设置")) {
                    Toggle("深色模式", isOn: $darkMode)
                    
                    VStack(alignment: .leading) {
                        Text("文字大小")
                        Picker("文字大小", selection: $fontSize) {
                            Text("小").tag(0)
                            Text("中").tag(1)
                            Text("大").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                // 隐私与安全
                Section(header: Text("隐私与安全")) {
                    Button(action: {}) {
                        Text("清除缓存")
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {}) {
                        Text("修改密码")
                            .foregroundColor(.primary)
                    }
                }
                
                // 关于
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: {}) {
                        Text("用户协议")
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {}) {
                        Text("隐私政策")
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// 关于页面
struct AboutView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo
                        Image(systemName: "scale.3d")
                            .font(.system(size: 70))
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                Circle()
                                    .fill(AppTheme.secondaryColor.opacity(0.2))
                                    .frame(width: 120, height: 120)
                            )
                            .background(Material.ultraThinMaterial)
                        
                        Text("IA法律顾问")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        
                        Text("版本 \(AppConstants.App.versionWithBuild)")
                            .foregroundColor(.white.opacity(0.8))
                        
                        // 应用描述
                        VStack(alignment: .leading, spacing: 15) {
                            Text("应用介绍")
                                .font(.headline)
                                .foregroundColor(AppTheme.accentColor)
                            
                            Text("IA法律顾问是一款以AI为核心的法律服务应用，旨在为用户提供便捷、专业的法律咨询和文书生成服务。我们结合先进的人工智能技术和专业法律知识库，为用户解答法律疑问，提供案件分析和法律文书生成等功能。")
                                .foregroundColor(.white.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .liquidGlass()
                        
                        // 团队信息
                        VStack(alignment: .center, spacing: 15) {
                            Text("联系我们")
                                .font(.headline)
                                .foregroundColor(AppTheme.accentColor)
                            
                            VStack {
                                contactRow(icon: "envelope", text: "support@iaadvisor.com")
                                contactRow(icon: "phone", text: "400-888-8888")
                                contactRow(icon: "globe", text: "www.iaadvisor.com")
                            }
                        }
                        .padding()
                        .liquidGlass()
                    }
                    .padding()
                }
            }
            .navigationTitle("关于我们")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func contactRow(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 20)
            
            Text(text)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.vertical, 5)
    }
}

// MARK: - 迷你文书统计
struct DocumentStatMini: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title3.bold())
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppViewModel())
} 