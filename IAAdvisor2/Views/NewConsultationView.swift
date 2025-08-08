import SwiftUI

struct NewConsultationView: View {
    @EnvironmentObject var viewModel: AppViewModel
    // 从 AppViewModel 获取当前用户信息
    @State private var newMessage = ""
    @State private var showingUpgrade = false
    @State private var showingShare = false
    
    var body: some View {
        VStack(spacing: 0) {
                // 顶部状态栏
                consultationStatusBar
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // 对话区域
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // 欢迎消息
                            if viewModel.aiChatMessages.isEmpty {
                                welcomeMessage
                            }
                            
                            ForEach(viewModel.aiChatMessages) { message in
                                ConsultationMessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel.isLoading {
                                LoadingIndicator()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.aiChatMessages.count) { _ in
                        if let lastMessage = viewModel.aiChatMessages.last {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // 底部输入区域
                messageInputArea
            }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .onTapGesture {
            hideKeyboard()
        }
        .sheet(isPresented: $showingUpgrade) {
            MembershipUpgradeView()
                .environmentObject(AppViewModel())
        }
        .sheet(isPresented: $showingShare) {
            if let user = viewModel.currentUser {
                // ShareToEarnView 需要重新设计或移除
                Text("分享功能开发中")
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            loadInitialData()
        }
    }
    
    // MARK: - 咨询状态栏
    private var consultationStatusBar: some View {
        VStack(spacing: 8) {
            HStack {
                // 用户等级
                if let user = viewModel.currentUser {
                    MembershipBadge(membershipLevel: user.membershipLevel)
                } else {
                    Text("未登录")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                // 剩余次数显示
                if let user = viewModel.currentUser {
                    ConsultationLimitView(user: user)
                } else {
                    Text("未登录")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                }
            }
            
            // 提示信息
            if let user = viewModel.currentUser,
               user.membershipLevel == .basic && (user.dailyConsultationLimit - user.dailyConsultationsUsed) <= 1 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("免费次数即将用完，升级会员享受更多咨询")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Button("升级") {
                        showingUpgrade = true
                    }
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accentColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(8)
            }
        }
        .padding()
    }
    
    // MARK: - 欢迎消息
    private var welcomeMessage: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(AppTheme.accentColor)
                
                Text("IA法律顾问")
                    .font(.headline.bold())
                    .foregroundColor(.white)
            }
            
            Text("您好！我是您的专属法律顾问，可以为您解答各类法律问题。请详细描述您遇到的法律问题，我会为您提供专业的法律建议。")
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
            
            // 常见问题快捷入口
            VStack(alignment: .leading, spacing: 8) {
                Text("常见问题：")
                    .font(.subheadline.bold())
                    .foregroundColor(.white.opacity(0.8))
                
                ForEach(commonQuestions, id: \.self) { question in
                    Button(question) {
                        sendQuickQuestion(question)
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
                }
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private let commonQuestions = [
        "劳动合同违约怎么办？",
        "房屋租赁纠纷如何处理？",
        "交通事故责任如何认定？",
        "网购商品质量问题维权",
        "离婚财产如何分割？"
    ]
    
    // MARK: - 消息输入区域
    private var messageInputArea: some View {
        HStack(spacing: 12) {
            TextField("请详细描述您的法律问题...", text: $newMessage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    if canSendMessage() && !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        sendMessage()
                    } else {
                        hideKeyboard()
                    }
                }
            
            Button("发送") {
                sendMessage()
            }
            .primaryButtonStyle()
            .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !canSendMessage())
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - 方法
    private func loadInitialData() {
        // 加载用户数据和历史消息
    }
    
    private func canSendMessage() -> Bool {
        return viewModel.canMakeConsultation()
    }
    
    private func sendMessage() {
        let messageText = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty && canSendMessage() else { return }
        
        // 使用 viewModel 的 sendMessageToAI 方法
        viewModel.sendMessageToAI(content: messageText)
        newMessage = ""
    }
    
    private func sendQuickQuestion(_ question: String) {
        guard canSendMessage() else {
            // 显示升级提示
            viewModel.showMembershipUpgrade()
            return
        }
        
        guard canSendMessage() else {
            viewModel.showMembershipUpgrade()
            return
        }
        newMessage = question
        sendMessage()
    }
    
    // 删除此方法，由 viewModel 处理
    
    // 删除旧的生成方法
}

// MARK: - 子组件

struct MembershipBadge: View {
    let membershipLevel: MembershipLevel
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: membershipLevel == .basic ? "person.circle" : "crown.fill")
                .foregroundColor(membershipLevel == .basic ? .white.opacity(0.7) : .yellow)
            
            Text(membershipLevel.rawValue)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(membershipLevel == .basic ? Color.white.opacity(0.2) : Color.yellow.opacity(0.3))
        )
    }
}

struct ConsultationLimitView: View {
    let user: User
    
    var body: some View {
        let remaining = user.dailyConsultationLimit - user.dailyConsultationsUsed
        
        HStack(spacing: 6) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .foregroundColor(remaining > 0 ? .green : .red)
            
            if user.membershipLevel == .professional || user.membershipLevel == .enterprise {
                Text("无限制咨询")
                    .font(.caption.bold())
                    .foregroundColor(.green)
            } else {
                Text("\(remaining)次咨询")
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(remaining > 0 ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
        )
    }
}

struct ConsultationMessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromAI {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(AppTheme.accentColor)
                        Text("IA法律顾问")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text(message.formattedDate)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)
                        .textSelection(.enabled) // 允许复制文本
                }
                
                Spacer(minLength: 50)
            } else {
                Spacer(minLength: 50)
                
                VStack(alignment: .trailing, spacing: 8) {
                    HStack {
                        Text(message.formattedDate)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                        Text("我")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.8))
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .background(AppTheme.accentColor.opacity(0.3))
                        .cornerRadius(12)
                }
            }
        }
    }
}

struct LoadingIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "brain.head.profile")
                .foregroundColor(AppTheme.accentColor)
            
            Text("IA正在思考中...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            ProgressView()
                .scaleEffect(0.7)
                .tint(.white)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}


struct PlanCard: View {
    let plan: PaymentPlan
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.name)
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        
                        if plan.isPopular {
                            Text("推荐")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange)
                                .cornerRadius(8)
                        }
                    }
                    
                    Text("¥\(plan.price, specifier: "%.1f")")
                        .font(.title.bold())
                        .foregroundColor(AppTheme.accentColor)
                }
                
                Spacer()
                
                Text("\(plan.duration)天")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(plan.features, id: \.self) { feature in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(feature)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                }
            }
            
            Button("立即购买") {
                onPurchase()
            }
            .primaryButtonStyle()
        }
        .padding()
        .liquidGlass()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(plan.isPopular ? Color.orange : Color.clear, lineWidth: 2)
        )
    }
}

struct FeatureComparisonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("功能对比")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ComparisonRow(
                    feature: "AI法律咨询",
                    free: "每日5次",
                    premium: "无限制"
                )
                
                ComparisonRow(
                    feature: "案件分析",
                    free: "基础分析",
                    premium: "详细报告"
                )
                
                ComparisonRow(
                    feature: "人工律师",
                    free: "❌",
                    premium: "✅"
                )
                
                ComparisonRow(
                    feature: "优先客服",
                    free: "❌",
                    premium: "✅"
                )
            }
        }
        .padding()
        .liquidGlass()
    }
}

struct ComparisonRow: View {
    let feature: String
    let free: String
    let premium: String
    
    var body: some View {
        HStack {
            Text(feature)
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(free)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 60)
            
            Text(premium)
                .font(.caption.bold())
                .foregroundColor(.green)
                .frame(width: 60)
        }
    }
}

// MARK: - 分享获取免费次数视图
struct ShareToEarnView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 标题
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("分享获得免费次数")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text("每成功邀请1位朋友注册，即可获得3次免费咨询机会")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                // 分享按钮
                VStack(spacing: 16) {
                    ShareButton(
                        icon: "message.fill",
                        title: "微信分享",
                        subtitle: "分享给微信好友",
                        color: .green
                    ) {
                        shareToWeChat()
                    }
                    
                    ShareButton(
                        icon: "bubble.left.and.bubble.right.fill",
                        title: "朋友圈分享",
                        subtitle: "分享到朋友圈",
                        color: .blue
                    ) {
                        shareToMoments()
                    }
                    
                    ShareButton(
                        icon: "square.and.arrow.up",
                        title: "其他方式",
                        subtitle: "复制链接分享",
                        color: .purple
                    ) {
                        copyShareLink()
                    }
                }
                
                Spacer()
                
                // 分享记录
                VStack(alignment: .leading, spacing: 12) {
                    Text("我的邀请记录")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    
                    Text("已邀请：0人 | 获得免费次数：0次")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .liquidGlass()
            }
            .padding()
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("分享获取免费次数")
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
    
    private func shareToWeChat() {
        // 分享到微信
    }
    
    private func shareToMoments() {
        // 分享到朋友圈
    }
    
    private func copyShareLink() {
        // 复制分享链接
        UIPasteboard.general.string = "https://example.com/invite/123456"
    }
}

struct ShareButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .liquidGlass()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NewConsultationView()
        .environmentObject(AppViewModel())
}