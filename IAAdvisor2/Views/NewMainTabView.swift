import SwiftUI

struct NewMainTabView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 首页
            NewHomeView()
                .tabItem {
                    Label("首页", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)
            
            // 案件
            CaseView()
                .tabItem {
                    Label("案件", systemImage: selectedTab == 1 ? "folder.fill" : "folder")
                }
                .tag(1)
            
            // 咨询
            NewConsultationView()
                .tabItem {
                    Label("咨询", systemImage: selectedTab == 2 ? "brain.head.profile.fill" : "brain.head.profile")
                }
                .tag(2)
            
            // 工具
            NewToolsView()
                .tabItem {
                    Label("工具", systemImage: selectedTab == 3 ? "wrench.and.screwdriver.fill" : "wrench.and.screwdriver")
                }
                .tag(3)
            
            // 我的
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: selectedTab == 4 ? "person.fill" : "person")
                }
                .tag(4)
        }
        .accentColor(AppTheme.accentColor)
        .padding(.bottom, 10) // 向下移动TabBar
        .onAppear {
            setupTabBarAppearance()
        }
        .sheet(isPresented: $viewModel.showingMembershipUpgrade) {
            MembershipUpgradeView()
                .environmentObject(viewModel)
        }
    }
    
    private func setupTabBarAppearance() {
        // 立即应用外观设置，不使用异步
        let appearance = UITabBarAppearance()
        
        // 设置毛玻璃背景 - 类似liquidGlass效果
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        // 未选中状态
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.7)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.7),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // 选中状态
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppTheme.accentColor)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.accentColor),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        // 添加顶部分割线
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.3)
        appearance.shadowImage = UIImage()
        
        // 强制应用外观设置
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isTranslucent = true
        UITabBar.appearance().backgroundColor = UIColor.black.withAlphaComponent(0.4)
        UITabBar.appearance().barTintColor = UIColor.black.withAlphaComponent(0.4)
        
        // 强制更新现有TabBar
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.view.setNeedsLayout()
            }
        }
    }
}

// MARK: - 详情页面组件

struct FormDetailView: View {
    let form: LegalForm
    @Environment(\.dismiss) private var dismiss
    @State private var showingDownload = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 表单信息
                    FormInfoSection(form: form)
                    
                    // 填写说明
                    InstructionSection(form: form)
                    
                    // 必填字段
                    RequiredFieldsSection(form: form)
                    
                    // 下载按钮
                    DownloadSection(form: form) {
                        showingDownload = true
                    }
                }
                .padding()
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle(form.title)
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
        .alert("下载成功", isPresented: $showingDownload) {
            Button("确定") { }
        } message: {
            Text("表单已保存到文件中，您可以在文件应用中找到它。")
        }
    }
}

struct FormInfoSection: View {
    let form: LegalForm
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(form.title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text(form.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            
            Text(form.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .padding()
        .liquidGlass()
    }
}

struct InstructionSection: View {
    let form: LegalForm
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("填写说明")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            Text(form.instructions)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)
        }
        .padding()
        .liquidGlass()
    }
}

struct RequiredFieldsSection: View {
    let form: LegalForm
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("必填字段")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(form.requiredFields, id: \.self) { field in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text(field)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .liquidGlass()
    }
}

struct DownloadSection: View {
    let form: LegalForm
    let onDownload: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Button("下载空白表单") {
                onDownload()
            }
            .primaryButtonStyle()
            
            if form.sampleUrl != nil {
                Button("查看填写样本") {
                    onDownload()
                }
                .secondaryButtonStyle()
            }
        }
    }
}

struct ProcedureDetailView: View {
    let procedure: CourtProcedure
    @Environment(\.dismiss) private var dismiss
    @State private var completedSteps: Set<String> = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 流程概览
                    ProcedureOverviewSection(procedure: procedure)
                    
                    // 步骤详情
                    ProcedureStepsSection(
                        procedure: procedure,
                        completedSteps: $completedSteps
                    )
                    
                    // 所需材料
                    RequiredDocumentsSection(procedure: procedure)
                    
                    // 费用信息
                    FeesSection(procedure: procedure)
                }
                .padding()
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle(procedure.title)
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

struct ProcedureOverviewSection: View {
    let procedure: CourtProcedure
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.number")
                    .font(.title)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(procedure.title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text(procedure.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.3))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(procedure.steps.count)")
                        .font(.title2.bold())
                        .foregroundColor(AppTheme.accentColor)
                    Text("个步骤")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                VStack(spacing: 4) {
                    Text(procedure.estimatedTime)
                        .font(.title3.bold())
                        .foregroundColor(AppTheme.accentColor)
                    Text("预计时间")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
        }
        .padding()
        .liquidGlass()
    }
}

struct ProcedureStepsSection: View {
    let procedure: CourtProcedure
    @Binding var completedSteps: Set<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("详细步骤")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(procedure.steps) { step in
                    ProcedureStepCard(
                        step: step,
                        isCompleted: completedSteps.contains(step.id)
                    ) {
                        if completedSteps.contains(step.id) {
                            completedSteps.remove(step.id)
                        } else {
                            completedSteps.insert(step.id)
                        }
                    }
                }
            }
        }
    }
}

struct ProcedureStepCard: View {
    let step: ProcedureStep
    let isCompleted: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: onToggle) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isCompleted ? .green : .white.opacity(0.5))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("步骤 \(step.stepNumber)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(step.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .strikethrough(isCompleted)
                }
                
                Spacer()
            }
            
            Text(step.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(2)
            
            if !step.tips.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("温馨提示:")
                        .font(.caption.bold())
                        .foregroundColor(.yellow)
                    
                    ForEach(step.tips, id: \.self) { tip in
                        HStack(alignment: .top) {
                            Text("•")
                                .foregroundColor(.yellow)
                            Text(tip)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCompleted ? Color.green.opacity(0.1) : Color.white.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCompleted ? Color.green : Color.clear, lineWidth: 1)
        )
    }
}

struct RequiredDocumentsSection: View {
    let procedure: CourtProcedure
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("所需材料")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(procedure.requiredDocuments, id: \.self) { document in
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundColor(.blue)
                        
                        Text(document)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .liquidGlass()
    }
}

struct FeesSection: View {
    let procedure: CourtProcedure
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("费用说明")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            HStack {
                Image(systemName: "yensign.circle.fill")
                    .foregroundColor(.orange)
                
                Text(procedure.fees)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
        }
        .padding()
        .liquidGlass()
    }
}

// MARK: - 测试入口

struct NewAppTestView: View {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some View {
        Group {
            if viewModel.appState == .authenticated {
                NewMainTabView()
                    .environmentObject(viewModel)
            } else {
                LoginView()
                    .environmentObject(viewModel)
            }
        }
    }
}

#Preview {
    NewAppTestView()
}