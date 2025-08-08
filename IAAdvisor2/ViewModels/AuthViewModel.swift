import SwiftUI
import Combine

/// 认证相关的视图模型，负责登录、注册等功能
@MainActor
class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    // 登录表单
    @Published var phoneNumber = ""
    @Published var verificationCode = ""
    @Published var showCodeInput = false
    @Published var isCodeSent = false
    @Published var countdown = 0
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var countdownTimer: Timer?
    
    // MARK: - Dependencies
    private let apiService: APIService
    
    // MARK: - Initialization
    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }
    
    // MARK: - Public Methods
    
    /// 发送验证码
    func sendVerificationCode() {
        guard !phoneNumber.isEmpty, isValidPhoneNumber(phoneNumber) else {
            errorMessage = "请输入有效的手机号"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await apiService.sendCode(phone: phoneNumber)
                await MainActor.run {
                    self.isLoading = false
                    self.showCodeInput = true
                    self.startCountdown()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.handleError(error)
                }
            }
        }
    }
    
    /// 验证验证码并登录
    func verifyCode() {
        guard !verificationCode.isEmpty, verificationCode.count == AppConstants.TextLimits.verificationCodeLength else {
            errorMessage = "请输入正确的验证码"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let authResponse = try await apiService.login(phone: phoneNumber, code: verificationCode)
                await MainActor.run {
                    self.isLoading = false
                    
                    // 保存认证信息
                    UserDefaults.standard.set(authResponse.access_token, forKey: "auth_token")
                    
                    // 创建用户对象
                    self.currentUser = User(
                        id: UUID().uuidString,
                        email: "user@example.com",
                        username: "用户",
                        phoneNumber: self.phoneNumber,
                        avatarUrl: nil
                    )
                    self.isAuthenticated = true
                    
                    // 清理表单
                    self.verificationCode = ""
                    self.countdownTimer?.invalidate()
                    self.countdownTimer = nil
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.handleError(error)
                }
            }
        }
    }
    
    /// 第三方登录
    func thirdPartyLogin(provider: String) {
        isLoading = true
        
        // 模拟第三方登录
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isLoading = false
            
            self?.currentUser = User(
                id: UUID().uuidString,
                email: "user@example.com",
                username: "\(provider)用户",
                phoneNumber: "138****8888",
                avatarUrl: nil
            )
            self?.isAuthenticated = true
        }
    }
    
    /// 退出登录
    func logout() {
        // 调用API退出
        apiService.logout()
        
        // 清理本地数据
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "auth_token")
        
        // 清理表单数据
        phoneNumber = ""
        verificationCode = ""
        showCodeInput = false
        isCodeSent = false
        
        // 清理定时器
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    // MARK: - Private Methods
    
    /// 开始倒计时
    private func startCountdown() {
        countdown = AppConstants.Time.verificationCodeCountdown
        isCodeSent = true
        
        // 取消之前的定时器
        countdownTimer?.invalidate()
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.countdown -= 1
            if self.countdown <= 0 {
                timer.invalidate()
                self.countdownTimer = nil
                self.isCodeSent = false
            }
        }
    }
    
    /// 验证手机号格式
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        let phonePattern = "^1[3-9]\\d{9}$"
        let phoneRegex = NSPredicate(format: "SELF MATCHES %@", phonePattern)
        return phoneRegex.evaluate(with: phone)
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
    
    // MARK: - Cleanup
    deinit {
        countdownTimer?.invalidate()
        cancellables.removeAll()
    }
}