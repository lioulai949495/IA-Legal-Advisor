import SwiftUI
import Combine

@MainActor
class AppViewModel: ObservableObject {
    // 应用程序状态
    @Published var appState: AppState = .splash
    @Published var isLoading = false
    @Published var selectedTab = 0
    @Published var errorMessage: String?
    
    // 用户数据
    @Published var currentUser: User?
    
    // 会员管理
    @Published var showingMembershipUpgrade = false
    
    // 案件管理
    @Published var cases: [Case] = []
    @Published var selectedCase: Case?
    
    // 聊天AI
    @Published var aiChatMessages: [Message] = []
    
    // 主页新闻/案例
    @Published var newsItems: [NewsItem] = []
    @Published var selectedNewsCategory: NewsCategory = .latestLaws
    
    var cancellables = Set<AnyCancellable>()
    
    init() {
        print("AppViewModel初始化开始")
        
        // 清除错误信息但保留认证数据
        errorMessage = nil
        isLoading = false
        
        // 加载测试数据
        loadSampleData()
        
        // 设置消息订阅等
        setupSubscriptions()
        
        // 启动画面显示2.5秒后检查认证状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.checkAuthenticationStatus()
        }
        
        print("AppViewModel初始化完成，状态: \(appState), 错误信息: \(String(describing: errorMessage))")
    }
    
    /// 检查认证状态
    private func checkAuthenticationStatus() {
        let hasCompletedLogin = UserDefaults.standard.bool(forKey: "has_completed_login")
        if hasCompletedLogin,
           let token = UserDefaults.standard.string(forKey: "auth_token"),
           !token.isEmpty,
           token.hasPrefix("fake-token-for-") { // 只接受有效格式的token
            print("AppViewModel: 找到有效格式的token，设置为已认证状态")
            
            // 创建用户对象
            self.appState = .authenticated
            self.currentUser = User(
                id: UUID().uuidString,
                email: "user@temp.com",
                username: "用户",
                phoneNumber: nil,
                avatarUrl: nil,
                membershipLevel: .basic,
                membershipExpiry: nil,
                dailyConsultationsUsed: 0,
                extraCaseSlots: 0
            )
            self.errorMessage = nil
        } else {
            print("AppViewModel: 未找到有效token或未完成登录流程，设置为未认证状态")
            appState = .unauthenticated
            // 清除无效token
            if UserDefaults.standard.string(forKey: "auth_token") != nil && !hasCompletedLogin {
                UserDefaults.standard.removeObject(forKey: "auth_token")
                APIService.shared.logout()
            }
        }
    }
    
    private func loadSampleData() {
        // 模拟从后端加载数据
        self.cases = SampleData.cases
        self.newsItems = SampleData.newsItems
        
        // 如果有案件，默认选中第一个
        if !cases.isEmpty {
            self.selectedCase = cases.first
        }
    }
    
    private func setupSubscriptions() {
        // 暂时禁用自动状态切换，手动控制状态
        // $currentUser
        //     .map { user -> AppState in
        //         return user != nil ? .authenticated : .unauthenticated
        //     }
        //     .assign(to: &$appState)
        print("订阅设置完成（已禁用自动状态切换）")
    }
    
    // MARK: - 认证相关方法
    func sendVerificationCode(phone: String, completion: @escaping () -> Void) {
        guard !phone.isEmpty else {
            self.errorMessage = "请输入手机号"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await APIService.shared.sendCode(phone: phone)
                await MainActor.run {
                    self.isLoading = false
                    completion()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.handleLoginError(error: error)
                }
            }
        }
    }
    
    func login(phone: String, code: String) {
        guard !phone.isEmpty, !code.isEmpty else {
            self.errorMessage = "请输入手机号和验证码"
            return
        }
        
        print("开始登录流程: phone=\(phone), code=\(code)")
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("调用API登录...")
                let authResponse = try await APIService.shared.login(phone: phone, code: code)
                print("API登录成功，token长度: \(authResponse.access_token.count)")
                
                await MainActor.run {
                    self.isLoading = false
                    
                    // 创建用户对象
                    self.currentUser = User(
                        id: UUID().uuidString, 
                        email: phone + "@temp.com", 
                        username: "用户" + phone.suffix(4), 
                        phoneNumber: phone,
                        avatarUrl: nil,
                        membershipLevel: .basic,
                        membershipExpiry: nil,
                        dailyConsultationsUsed: 0,
                        extraCaseSlots: 0
                    )
                    
                    // 设置认证状态
                    self.appState = .authenticated
                    UserDefaults.standard.set(true, forKey: "has_completed_login")
                    print("登录流程完成，设置为已认证状态")
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.handleLoginError(error: error)
                }
            }
        }
    }

    func register(username: String, email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 注册功能暂时保留，但后端可能不支持
                self.errorMessage = "当前仅支持手机号验证码登录"
            } catch let apiError as APIError {
                self.errorMessage = apiError.localizedDescription
            } catch {
                self.errorMessage = "注册失败，请稍后重试。"
            }
            isLoading = false
        }
    }
    
    func logout() {
        print("AppViewModel.logout: 清除登录状态")
        DispatchQueue.main.async {
            self.currentUser = nil
            self.aiChatMessages = []
            self.appState = .unauthenticated
            self.errorMessage = nil
        }
        
        // 清除存储的 token
        UserDefaults.standard.removeObject(forKey: "auth_token")
        UserDefaults.standard.removeObject(forKey: "has_completed_login")
        APIService.shared.logout()
        print("logout完成，状态已设置为: \(appState)")
    }
    
    /// 处理登录错误
    private func handleLoginError(error: Error) {
        if let apiError = error as? APIError {
            switch apiError {
            case .serverColdStart:
                self.errorMessage = "服务器正在启动，请稍候重试。首次启动可能需要1-2分钟。"
            case .requestFailed(let urlError as URLError) where urlError.code == .timedOut:
                self.errorMessage = "请求超时，可能是网络问题或服务器繁忙，请稍后重试"
            case .unauthorized:
                self.errorMessage = "验证码错误或已过期，请重新获取"
            case .rateLimited:
                self.errorMessage = "请求过于频繁，请稍后再试"
            case .networkUnavailable:
                self.errorMessage = "网络连接不可用，请检查网络设置"
            case .serverError(let message):
                self.errorMessage = message.isEmpty ? "服务器错误，请稍后重试" : message
            default:
                self.errorMessage = apiError.localizedDescription
            }
        } else {
            self.errorMessage = "登录失败：\(error.localizedDescription)"
        }
        
        print("登录错误: \(error)")
    }
    
    // MARK: - 案件管理方法
    func createNewCase(title: String, description: String, caseType: CaseType) {
        // 检查案件创建限制
        guard canCreateCase() else {
            // 显示限制提示
            let user = currentUser
            let currentCount = cases.count
            let maxCount = user?.caseLimit ?? 0
            
            if maxCount == 0 {
                errorMessage = "免费版不支持创建案件。\n\n💎 升级标准版可创建1个案件\n💰 或单独购买案件名额¥19.9/个\n\n点击个人中心查看升级选项"
            } else {
                errorMessage = "您的案件数量已达上限（\(currentCount)/\(maxCount)）。\n\n💎 升级专业版可创建无限案件\n💰 或单独购买案件名额¥19.9/个\n\n点击个人中心查看升级选项"
            }
            
            showMembershipUpgrade()
            return
        }
        let newCase = Case(
            id: UUID().uuidString,
            title: title,
            description: description,
            createdAt: Date(),
            lastUpdatedAt: Date(),
            caseType: caseType,
            status: .active,
            messages: [
                Message(
                    id: UUID().uuidString,
                    content: "您好，我是IA法律顾问。请问您遇到了什么具体的\(caseType.rawValue)法律问题？",
                    createdAt: Date(),
                    isFromAI: true,
                    attachments: nil,
                    documentLinks: nil
                )
            ]
        )
        
        cases.insert(newCase, at: 0)
        selectedCase = newCase
    }
    
    func selectCase(_ case: Case) {
        selectedCase = `case`
    }
    
    // MARK: - 消息相关方法
    func sendMessage(content: String, to case: Case?) {
        guard var currentCase = `case` ?? selectedCase else { return }
        
        let userMessage = Message(
            id: UUID().uuidString,
            content: content,
            createdAt: Date(),
            isFromAI: false,
            attachments: nil,
            documentLinks: nil
        )
        
        // 添加用户消息
        currentCase.messages.append(userMessage)
        currentCase.lastUpdatedAt = Date()
        
        // 模拟网络请求延迟
        isLoading = true
        
        // 模拟AI回复
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            let aiReply = Message(
                id: UUID().uuidString,
                content: "我已收到您的问题，正在为您分析...\n\n根据您提供的信息，我建议您可以考虑以下解决方案...",
                createdAt: Date(),
                isFromAI: true,
                attachments: nil,
                documentLinks: nil
            )
            
            // 添加AI回复
            currentCase.messages.append(aiReply)
            
            // 更新案件
            if let index = self.cases.firstIndex(where: { $0.id == currentCase.id }) {
                self.cases[index] = currentCase
                self.selectedCase = currentCase
            }
            
            self.isLoading = false
        }
    }
    
    // AI咨询聊天（独立于案件的通用对话）
    func sendMessageToAI(content: String) {
        // 先添加用户消息
        let userMessage = Message(
            id: UUID().uuidString,
            content: content,
            createdAt: Date(),
            isFromAI: false,
            attachments: nil,
            documentLinks: nil
        )
        aiChatMessages.append(userMessage)
        
        // 先增加使用次数
        self.incrementDailyConsultations()
        
        // 检查是否超出限制，如果超出则显示升级提示而不是AI响应
        if !canMakeConsultation() {
            // 显示升级提示
            let limitMessage = Message(
                id: UUID().uuidString,
                content: "您今日的咨询次数已用完（\(currentUser?.dailyConsultationsUsed ?? 0)/\(currentUser?.dailyConsultationLimit ?? 10)）。\n\n💎 升级会员享受更多咨询次数\n💰 或单独购买10次咨询仅需¥9.9\n\n点击个人中心查看升级选项，或点击下方按钮购买额外咨询次数。",
                createdAt: Date(),
                isFromAI: true,
                attachments: nil,
                documentLinks: nil
            )
            aiChatMessages.append(limitMessage)
            showMembershipUpgrade()
            return
        }
        
        // 真实API调用
        isLoading = true
        
        Task {
            do {
                // 1. 开始聊天会话
                let categories = try await APIService.shared.startChat()
                let category = categories.options.first ?? "劳动纠纷"
                
                // 2. 获取角色
                let roles = try await APIService.shared.getRoles(category: category)
                let role = roles.options.first ?? "我是员工"
                
                // 3. 获取子类型
                let subtypes = try await APIService.shared.getSubtypes(category: category, role: role)
                let subtype = subtypes.options.first ?? "未签订劳动合同"
                
                // 4. 发送消息
                let analysis = try await APIService.shared.sendChatMessage(
                    category: category,
                    role: role,
                    subtype: subtype,
                    message: content
                )
                
                let report = analysis.analysis_report
                let pretty = """
                📚 适用法条：\n\(report.applicable_laws)\n\n📈 胜诉率：\(report.success_rate_analysis.rate)%\n原因：\(report.success_rate_analysis.reason)\n\n🧭 建议：\n\(report.action_suggestion)\n\n📝 下一步：\n\(report.next_steps.process_guidance)\n\n📄 所需文书：\n\(report.next_steps.document_templates)
                """
                
                let aiReply = Message(
                    id: UUID().uuidString,
                    content: pretty,
                    createdAt: Date(),
                    isFromAI: true,
                    attachments: nil,
                    documentLinks: nil
                )
                
                self.aiChatMessages.append(aiReply)
            } catch let apiError as APIError {
                // 如果是认证错误，自动登出用户
                if case .unauthorized = apiError {
                    self.logout()
                    return
                }
                let errorMessage = Message(
                    id: UUID().uuidString,
                    content: "抱歉，服务暂时不可用：\(apiError.localizedDescription)",
                    createdAt: Date(),
                    isFromAI: true,
                    attachments: nil,
                    documentLinks: nil
                )
                self.aiChatMessages.append(errorMessage)
            } catch {
                let errorMessage = Message(
                    id: UUID().uuidString,
                    content: "网络连接异常：\(error.localizedDescription)。请检查网络设置后重试。",
                    createdAt: Date(),
                    isFromAI: true,
                    attachments: nil,
                    documentLinks: nil
                )
                self.aiChatMessages.append(errorMessage)
            }
            
            self.isLoading = false
        }
    }
    
    // MARK: - 新闻相关方法
    func fetchNewsItems(category: NewsCategory) {
        selectedNewsCategory = category
        // 模拟从后端获取新闻
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // 模拟根据分类过滤新闻
            self.newsItems = SampleData.newsItems.filter { $0.category == category }
            self.isLoading = false
        }
    }
    
    // MARK: - 会员管理方法
    
    /// 检查是否可以进行AI咨询
    func canMakeConsultation() -> Bool {
        guard let user = currentUser else { return false }
        
        // 专业版和企业版无限制
        if user.membershipLevel == .professional || user.membershipLevel == .enterprise {
            return true
        }
        
        // 检查每日限制
        return user.dailyConsultationsUsed < user.dailyConsultationLimit
    }
    
    /// 检查是否可以创建案件
    func canCreateCase() -> Bool {
        guard let user = currentUser else { return false }
        
        // 专业版和企业版无限制
        if user.membershipLevel == .professional || user.membershipLevel == .enterprise {
            return true
        }
        
        // 检查案件数量限制
        return cases.count < user.caseLimit
    }
    
    /// 增加每日咨询使用次数
    func incrementDailyConsultations() {
        currentUser?.dailyConsultationsUsed += 1
    }
    
    /// 重置每日咨询次数（通常在每日零点调用）
    func resetDailyConsultations() {
        currentUser?.dailyConsultationsUsed = 0
    }
    
    /// 检查会员是否过期
    func checkMembershipExpiry() {
        guard let user = currentUser,
              let expiry = user.membershipExpiry else { return }
        
        if Date() > expiry {
            // 会员过期，降级到免费版
            currentUser?.membershipLevel = .basic
            currentUser?.membershipExpiry = nil
        }
    }
    
    /// 升级会员
    func upgradeMembership(to level: MembershipLevel, duration: Int = 1) {
        currentUser?.membershipLevel = level
        
        // 设置过期时间（默认1个月）
        let expiry = Calendar.current.date(byAdding: .month, value: duration, to: Date())
        currentUser?.membershipExpiry = expiry
    }
    
    /// 显示会员升级页面
    func showMembershipUpgrade() {
        showingMembershipUpgrade = true
    }
    
    /// 显示限制提示并引导升级
    func showUpgradePrompt(for feature: String) -> Bool {
        // 返回是否应该显示升级提示
        switch feature {
        case "consultation":
            return !canMakeConsultation()
        case "case":
            return !canCreateCase()
        default:
            return false
        }
    }
    
    /// 生成智能法律建议响应（临时方案，直到后端集成真正的AI）
    private func generateIntelligentResponse(for userMessage: String) -> String {
        let message = userMessage.lowercased()
        
        // 劳动法相关
        if message.contains("劳动") || message.contains("工作") || message.contains("加班") || message.contains("工资") || message.contains("辞职") {
            return """
            您提到的劳动法问题很常见。根据《中华人民共和国劳动法》，我为您分析如下：

            📋 **主要建议：**
            • 保留所有劳动合同、工资条等书面证据
            • 如涉及加班，记录加班时间和证据
            • 可向劳动监察部门投诉或申请劳动仲裁

            ⚖️ **法律依据：**
            • 《劳动法》第三条：劳动者享有平等就业权利
            • 《劳动合同法》规定了合同解除的具体条件

            💡 **下一步：**
            建议您详细描述具体情况，我可以提供更精准的法律建议。
            """
        }
        
        // 合同纠纷
        else if message.contains("合同") || message.contains("违约") || message.contains("协议") {
            return """
            关于合同纠纷，这是民事法律关系中最常见的问题。让我为您分析：

            📑 **合同分析要点：**
            • 确认合同是否有效成立
            • 分析违约责任条款
            • 评估损失赔偿范围

            🔍 **证据收集：**
            • 合同原件及所有附件
            • 履行过程中的往来记录
            • 损失的具体证明材料

            ⚖️ **解决途径：**
            1. 协商解决
            2. 调解处理  
            3. 诉讼维权

            请详细说明合同内容和纠纷具体情况，我可以提供更有针对性的建议。
            """
        }
        
        // 婚姻家庭
        else if message.contains("离婚") || message.contains("婚姻") || message.contains("抚养") || message.contains("财产") {
            return """
            婚姻家庭问题涉及人身关系和财产关系，需要谨慎处理：

            👨‍👩‍👧‍👦 **主要考虑因素：**
            • 夫妻感情是否确已破裂
            • 子女抚养权和抚养费
            • 共同财产的分割

            📋 **所需材料：**
            • 结婚证、身份证
            • 财产证明（房产、存款等）
            • 子女出生证明

            ⚖️ **法律程序：**
            • 可先尝试调解
            • 向人民法院提起离婚诉讼
            • 涉及财产分割需详细举证

            建议您说明具体情况，以便我提供更专业的指导。
            """
        }
        
        // 债务纠纷
        else if message.contains("借贷") || message.contains("欠款") || message.contains("债务") || message.contains("还款") {
            return """
            债权债务纠纷需要及时处理，避免超过诉讼时效：

            💰 **债权保护：**
            • 及时催收，保留催收记录
            • 注意诉讼时效（一般为3年）
            • 收集完整的债权凭证

            📄 **证据材料：**
            • 借条、欠条原件
            • 转账记录、银行流水
            • 聊天记录等辅助证据

            ⚖️ **维权方式：**
            1. 协商还款
            2. 申请支付令
            3. 提起民事诉讼

            请提供更多详细信息，我将为您制定具体的追债策略。
            """
        }
        
        // 默认通用回复
        else {
            return """
            感谢您的咨询。我是您的AI法律顾问，专门为您提供专业的法律建议。

            🏛️ **我的专业领域：**
            • 劳动争议（工资、加班、辞退等）
            • 合同纠纷（买卖、服务、租赁等）
            • 婚姻家庭（离婚、抚养、财产分割）
            • 债权债务（借贷、欠款追收）
            • 侵权责任（人身损害、财产损失）

            💡 **为了更好地帮助您，请详细描述：**
            • 具体发生了什么情况？
            • 涉及哪些法律关系？
            • 您希望达到什么目标？

            我会根据相关法律法规，为您提供专业、实用的解决方案。
            """
        }
    }
} 