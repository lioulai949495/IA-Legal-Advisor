import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            // 主页 - 法律热点/新闻
            NewHomeView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(0)
            
            // 案件管理
            CaseView()
                .tabItem {
                    Label("案件", systemImage: "folder.fill")
                }
                .tag(1)
            
            // AI咨询
            AIChatView()
                .tabItem {
                    Label("咨询", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(2)
            
            // 个人中心
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(3)
        }
        .onAppear {
            // 配置TabBar外观
            configureTabBarAppearance()
            
            // 配置导航栏外观
            configureNavigationBarAppearance()
        }
    }
    
    // 配置TabBar外观
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        // 自定义选中和未选中状态
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.gray
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(AppTheme.accentColor)
        ]
        
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        appearance.stackedLayoutAppearance.normal.iconColor = .gray
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppTheme.accentColor)
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    // 配置导航栏外观
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(AppTheme.backgroundColor).withAlphaComponent(0.8)
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        // 使用更小的标题字体
        let titleTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold)
        ]
        appearance.titleTextAttributes = titleTextAttributes
        
        // 设置为紧凑模式
        appearance.buttonAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -5)
        appearance.buttonAppearance.normal.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 14)]
        appearance.doneButtonAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -5)
        
        // 去掉底部阴影线
        appearance.shadowColor = nil
        appearance.shadowImage = nil
        
        // 应用到所有导航栏
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // 设置按钮颜色
        UINavigationBar.appearance().tintColor = UIColor.white
        
        // 直接设置导航栏高度
        UINavigationBar.appearance().isTranslucent = true
        
        // iOS 15+ 特定设置
        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().compactScrollEdgeAppearance = appearance
            // 设置导航栏高度缩减的直接方法
            customizeNavigationBarHeight()
        }
    }
    
    // iOS 15+ 直接减少导航栏高度
    @available(iOS 15.0, *)
    private func customizeNavigationBarHeight() {
        let navBarAppearance = UINavigationBar.appearance()
        navBarAppearance.compactAppearance = navBarAppearance.standardAppearance
        
        // 尝试通过运行时修改来减少导航栏高度
        DispatchQueue.main.async {
            // 使用新的SceneAPI而不是废弃的windows
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let keyWindow = windowScene.windows.first {
                keyWindow.subviews.forEach { view in
                    if let navBar = findNavigationBar(in: view) {
                        // 通过约束更改高度
                        navBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
                    }
                }
            }
        }
    }
    
    private func findNavigationBar(in view: UIView) -> UINavigationBar? {
        if let navBar = view as? UINavigationBar {
            return navBar
        }
        
        for subview in view.subviews {
            if let navBar = findNavigationBar(in: subview) {
                return navBar
            }
        }
        
        return nil
    }
}

// 扩展UINavigationBar，设置导航样式
extension UINavigationBar {
    static func setNavigationBarType() {
        // 在iPhone上使用StackNavigationViewStyle，在iPad上使用DoubleColumnNavigationViewStyle
        if UIDevice.current.userInterfaceIdiom == .phone {
            if #available(iOS 16.0, *) {
                // iOS 16+: NavigationViewStyle已废弃，但现在我们使用NavigationView，所以暂时保留这种方式
            } else {
                UINavigationBar.appearance().prefersLargeTitles = false
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppViewModel())
} 