import SwiftUI

struct MembershipUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedLevel: MembershipLevel = .standard
    @State private var showingPayment = false
    @State private var isProcessingPayment = false
    @State private var showingPurchaseServices = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 头部标题
                        headerSection
                        
                        // 当前会员状态
                        currentMembershipCard
                        
                        // 升级选项
                        membershipOptions
                        
                        // 升级按钮
                        upgradeButton
                        
                        // 单次付费服务
                        paidServicesSection
                    }
                    .padding()
                }
            }
            .navigationTitle("会员升级")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingPurchaseServices = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "cart.fill")
                            Text("单独购买")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingPayment) {
            MembershipPaymentView(
                title: selectedLevel.rawValue,
                description: "升级到\(selectedLevel.rawValue)，享受更多专业服务",
                price: selectedLevel.price,
                onPaymentSuccess: {
                    handlePaymentSuccess()
                }
            )
        }
        .sheet(isPresented: $showingPurchaseServices) {
            PurchaseServicesView()
                .environmentObject(viewModel)
        }
    }
    
    // MARK: - 头部标题
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            
            Text("升级会员")
                .font(.title.bold())
                .foregroundColor(.white)
            
            Text("解锁更多专业功能，获得更好的法律服务体验")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - 当前会员状态卡片
    private var currentMembershipCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: viewModel.currentUser?.membershipLevel.icon ?? "person.circle")
                    .font(.title2)
                    .foregroundColor(viewModel.currentUser?.membershipLevel.color ?? .gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("当前会员")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(viewModel.currentUser?.membershipLevel.rawValue ?? "免费版")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                if let expiry = viewModel.currentUser?.membershipExpiry {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("到期时间")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(formatDate(expiry))
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }
                }
            }
            
            // 使用统计
            usageStatsView
        }
        .padding()
        .liquidGlass()
    }
    
    // MARK: - 使用统计
    private var usageStatsView: some View {
        HStack(spacing: 20) {
            StatView(
                title: "今日咨询",
                current: viewModel.currentUser?.dailyConsultationsUsed ?? 0,
                limit: viewModel.currentUser?.dailyConsultationLimit ?? 3
            )
            
            Divider()
                .frame(height: 30)
                .background(Color.white.opacity(0.3))
            
            StatView(
                title: "案件数量",
                current: viewModel.cases.count,
                limit: viewModel.currentUser?.caseLimit ?? 2
            )
        }
    }
    
    // MARK: - 会员选项
    private var membershipOptions: some View {
        VStack(spacing: 16) {
            Text("选择升级方案")
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(MembershipLevel.allCases.filter { $0 != .basic }, id: \.self) { level in
                MembershipOptionCard(
                    level: level,
                    isSelected: selectedLevel == level,
                    onSelect: { selectedLevel = level }
                )
            }
        }
    }
    
    // MARK: - 升级按钮
    private var upgradeButton: some View {
        Button {
            showingPayment = true
        } label: {
            HStack {
                if isProcessingPayment {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                }
                
                Text(isProcessingPayment ? "处理中..." : "立即升级到\(selectedLevel.rawValue)")
                    .font(.headline.bold())
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(isProcessingPayment)
    }
    
    // MARK: - 单次付费服务
    private var paidServicesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("单次付费服务")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    showingPurchaseServices = true
                } label: {
                    HStack(spacing: 4) {
                        Text("查看全部")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            
            Text("根据实际需求，灵活购买所需服务")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // 显示热门服务
                ForEach(PaidService.availableServices.prefix(4)) { service in
                    PaidServiceCard(
                        title: service.name,
                        price: service.price,
                        icon: getServiceIcon(service.type)
                    ) {
                        showingPurchaseServices = true
                    }
                }
            }
        }
    }
    
    private func getServiceIcon(_ type: PaidService.ServiceType) -> String {
        switch type {
        case .extraConsultations: return "message.badge.fill"
        case .caseSlot: return "folder.badge.plus"
        case .analysis: return "chart.bar.xaxis"
        case .document: return "doc.text"
        case .consultation: return "person.badge.shield.checkmark"
        case .riskAssessment: return "exclamationmark.triangle"
        }
    }
    
    // MARK: - 私有方法
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
    
    private func handlePaymentSuccess() {
        isProcessingPayment = true
        
        // 模拟升级处理
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // 更新用户会员等级
            viewModel.currentUser?.membershipLevel = selectedLevel
            viewModel.currentUser?.membershipExpiry = Calendar.current.date(byAdding: .month, value: 1, to: Date())
            
            isProcessingPayment = false
            dismiss()
        }
    }
}

// MARK: - 统计视图
struct StatView: View {
    let title: String
    let current: Int
    let limit: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            HStack(alignment: .bottom, spacing: 2) {
                Text("\(current)")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                if limit > 0 {
                    Text("/\(limit)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                } else {
                    Text("/∞")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // 进度条
            if limit > 0 {
                ProgressView(value: Double(current), total: Double(limit))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 0.5)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 会员选项卡片
struct MembershipOptionCard: View {
    let level: MembershipLevel
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: level.icon)
                            .font(.title2)
                            .foregroundColor(level.color)
                        
                        Text(level.rawValue)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        if level.price > 0 {
                            Text("¥\(level.price, specifier: "%.1f")")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text("/月")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        } else {
                            Text("免费")
                                .font(.title3.bold())
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // 功能列表
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(level.features.prefix(4), id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Text(feature)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                        }
                    }
                    
                    if level.features.count > 4 {
                        Text("还有\(level.features.count - 4)项功能...")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? level.color.opacity(0.2) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? level.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 单次付费服务卡片
struct PaidServiceCard: View {
    let title: String
    let price: Double
    let icon: String
    let action: () -> Void
    
    init(title: String, price: Double, icon: String, action: @escaping () -> Void = {}) {
        self.title = title
        self.price = price
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("¥\(price, specifier: "%.1f")")
                    .font(.title3.bold())
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .liquidGlass()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MembershipUpgradeView()
        .environmentObject(AppViewModel())
}