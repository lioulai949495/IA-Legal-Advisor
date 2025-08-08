import SwiftUI
import Combine

/// 聊天相关的视图模型，集成后端API
@MainActor
class ChatViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var messages: [Message] = []
    @Published var currentMessage = ""
    @Published var isLoading = false
    @Published var isTyping = false
    @Published var errorMessage: String?
    
    // Chat configuration
    @Published var selectedCategory = "法律咨询"
    @Published var selectedRole: String?
    @Published var selectedSubtype: String?
    @Published var availableRoles: [String] = []
    @Published var availableSubtypes: [String] = []
    
    // 免费咨询限制
    @Published var remainingFreeChats = BusinessConstants.freeChatLimit
    @Published var showPaymentPrompt = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Dependencies
    private let apiService: APIService
    
    // MARK: - Initialization
    init(apiService: APIService = .shared) {
        self.apiService = apiService
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    /// 发送消息
    func sendMessage() {
        guard !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // 检查免费次数
        if remainingFreeChats <= 0 {
            showPaymentPrompt = true
            return
        }
        
        let userMessage = Message(
            id: UUID().uuidString,
            content: currentMessage,
            createdAt: Date(),
            isFromAI: false,
            attachments: nil,
            documentLinks: nil
        )
        
        messages.append(userMessage)
        let messageToSend = currentMessage
        currentMessage = ""
        
        // 开始加载状态
        isLoading = true
        isTyping = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await apiService.sendChatMessage(
                    category: selectedCategory,
                    role: selectedRole ?? "默认角色",
                    subtype: selectedSubtype ?? "默认子类型",
                    message: messageToSend
                )
                
                await MainActor.run {
                    self.isLoading = false
                    self.isTyping = false
                    
                    // 添加AI回复
                    let aiMessage = Message(
                        id: UUID().uuidString,
                        content: "📚 适用法条:\n\(response.analysis_report.applicable_laws)\n\n📈 胜诉率：\(response.analysis_report.success_rate_analysis.rate)%\n原因：\(response.analysis_report.success_rate_analysis.reason)\n\n🧭 建议：\n\(response.analysis_report.action_suggestion)\n\n📝 下一步：\n\(response.analysis_report.next_steps.process_guidance)\n\n📄 所需文书：\n\(response.analysis_report.next_steps.document_templates)",
                        createdAt: Date(),
                        isFromAI: true,
                        attachments: nil,
                        documentLinks: nil
                    )
                    self.messages.append(aiMessage)
                    
                    // 减少免费次数
                    self.remainingFreeChats -= 1
                    self.saveFreeChatsCount()
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.isTyping = false
                    self.handleError(error)
                }
            }
        }
    }
    
    /// 开始新的聊天会话
    func startNewChat() {
        Task {
            do {
                _ = try await apiService.startChat()
                await MainActor.run {
                    self.messages.removeAll()
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.handleError(error)
                }
            }
        }
    }
    
    /// 加载角色列表
    func loadRoles() {
        Task {
            do {
                let rolesResponse = try await apiService.getRoles(category: selectedCategory)
                await MainActor.run {
                    self.availableRoles = rolesResponse.options
                }
            } catch {
                await MainActor.run {
                    self.handleError(error)
                }
            }
        }
    }
    
    /// 加载子类型列表
    func loadSubtypes() {
        Task {
            do {
                let subtypesResponse = try await apiService.getSubtypes(category: selectedCategory, role: selectedRole ?? "默认角色")
                await MainActor.run {
                    self.availableSubtypes = subtypesResponse.options
                }
            } catch {
                await MainActor.run {
                    self.handleError(error)
                }
            }
        }
    }
    
    /// 重试发送消息
    func retryLastMessage() {
        guard let lastUserMessage = messages.last(where: { $0.isFromUser }) else { return }
        currentMessage = lastUserMessage.content
        sendMessage()
    }
    
    /// 清空聊天记录
    func clearMessages() {
        messages.removeAll()
        errorMessage = nil
    }
    
    /// 购买更多聊天次数
    func purchaseMoreChats() {
        // 这里可以集成支付功能
        remainingFreeChats += BusinessConstants.shareRewardCount
        saveFreeChatsCount()
        showPaymentPrompt = false
    }
    
    /// 通过分享获得免费次数
    func shareForFreeChats() {
        remainingFreeChats += BusinessConstants.shareRewardCount
        saveFreeChatsCount()
        showPaymentPrompt = false
    }
    
    // MARK: - Private Methods
    
    /// 加载初始数据
    private func loadInitialData() {
        loadFreeChatsCount()
        loadRoles()
        loadSubtypes()
    }
    
    /// 处理API错误
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            switch apiError {
            case .invalidURL:
                errorMessage = "网络配置错误"
            case .requestFailed(let underlyingError):
                errorMessage = "网络请求失败：\(underlyingError.localizedDescription)"
            case .invalidResponse:
                errorMessage = "服务器响应无效"
            case .decodingError(let underlyingError):
                errorMessage = "数据解析失败：\(underlyingError.localizedDescription)"
            case .unauthorized:
                errorMessage = "认证失败，请重新登录"
            case .rateLimited:
                errorMessage = "请求过于频繁，请稍后重试"
            case .serverError(let message):
                errorMessage = message
            case .networkUnavailable:
                errorMessage = "网络不可用，请检查网络连接"
            case .timeout:
                errorMessage = "请求超时，请稍后重试"
            case .serverColdStart:
                errorMessage = "服务器正在启动，请稍候重试。首次启动可能需要1-2分钟。"
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
    
    /// 保存免费聊天次数
    private func saveFreeChatsCount() {
        UserDefaults.standard.set(remainingFreeChats, forKey: "remaining_free_chats")
    }
    
    /// 加载免费聊天次数
    private func loadFreeChatsCount() {
        remainingFreeChats = UserDefaults.standard.integer(forKey: "remaining_free_chats")
        if remainingFreeChats == 0 {
            remainingFreeChats = BusinessConstants.freeChatLimit
        }
    }
    
    // MARK: - Helper Methods
    
    /// 获取聊天配置描述
    var chatConfigDescription: String {
        var components: [String] = [selectedCategory]
        if let role = selectedRole { components.append(role) }
        if let subtype = selectedSubtype { components.append(subtype) }
        return components.joined(separator: " - ")
    }
    
    /// 是否可以发送消息
    var canSendMessage: Bool {
        return !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
               !isLoading && 
               (remainingFreeChats > 0 || !showPaymentPrompt)
    }
    
    // MARK: - Cleanup
    deinit {
        cancellables.removeAll()
    }
}