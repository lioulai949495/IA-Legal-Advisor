import Foundation
import AuthenticationServices
import Combine
import UIKit

@MainActor
class AuthenticationService: ObservableObject {
    @MainActor static let shared = AuthenticationService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService: APIService
    private var cancellables = Set<AnyCancellable>()
    
    private init(apiService: APIService = .shared) {
        self.apiService = apiService
        checkExistingAuth()
    }
    
    // MARK: - 认证状态检查
    
    private func checkExistingAuth() {
        if let token = UserDefaults.standard.string(forKey: "auth_token"),
           !token.isEmpty {
            // 验证token有效性
            Task {
                do {
                    let profile = try await apiService.getUserProfile()
                    self.currentUser = convertToUser(from: profile)
                    self.isAuthenticated = true
                } catch {
                    // Token无效，清除
                    clearAuthData()
                }
            }
        }
    }
    
    // MARK: - 手机验证码登录 (现有)
    
    func sendPhoneVerificationCode(_ phone: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await apiService.sendCode(phone: phone)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func loginWithPhone(_ phone: String, code: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let authResponse = try await apiService.login(phone: phone, code: code)
            await handleSuccessfulAuth(token: authResponse.access_token)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Apple ID 登录
    
    func signInWithApple() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            
            let delegate = AppleSignInDelegate { result in
                switch result {
                case .success(let credential):
                    Task { @MainActor in
                        do {
                            try await self.handleAppleSignIn(credential: credential)
                            continuation.resume()
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            authorizationController.delegate = delegate
            authorizationController.presentationContextProvider = delegate
            authorizationController.performRequests()
        }
    }
    
    private func handleAppleSignIn(credential: ASAuthorizationAppleIDCredential) async throws {
        isLoading = true
        
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthenticationError.invalidAppleCredentials
        }
        
        do {
            // 发送Apple ID token到后端验证
            let fullNameString = credential.fullName.map { name in
                let formatter = PersonNameComponentsFormatter()
                formatter.style = .long
                return formatter.string(from: name)
            }
            
            let authResponse = try await apiService.loginWithApple(
                identityToken: tokenString,
                userIdentifier: credential.user,
                email: credential.email,
                fullName: fullNameString
            )
            
            await handleSuccessfulAuth(token: authResponse.access_token)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - 邮箱登录
    
    func loginWithEmail(_ email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let authResponse = try await apiService.loginWithEmail(email: email, password: password)
            await handleSuccessfulAuth(token: authResponse.access_token)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func registerWithEmail(_ email: String, password: String, username: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let authResponse = try await apiService.registerWithEmail(
                email: email, 
                password: password, 
                username: username
            )
            await handleSuccessfulAuth(token: authResponse.access_token)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - 第三方登录预留接口
    
    func loginWithWeChat() async throws {
        // TODO: 集成微信SDK
        throw AuthenticationError.notImplemented("微信登录")
    }
    
    func loginWithAlipay() async throws {
        // TODO: 集成支付宝SDK  
        throw AuthenticationError.notImplemented("支付宝登录")
    }
    
    // MARK: - 认证成功处理
    
    private func handleSuccessfulAuth(token: String) async {
        // 保存token
        UserDefaults.standard.set(token, forKey: "auth_token")
        
        // 获取用户信息
        do {
            let profile = try await apiService.getUserProfile()
            self.currentUser = convertToUser(from: profile)
            self.isAuthenticated = true
        } catch {
            print("获取用户信息失败: \(error)")
            // 即使获取用户信息失败，也认为登录成功
            self.isAuthenticated = true
        }
    }
    
    // MARK: - 登出
    
    func logout() {
        clearAuthData()
        apiService.logout()
    }
    
    private func clearAuthData() {
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
    
    // MARK: - 辅助方法
    
    private func convertToUser(from profile: UserProfileResponse) -> User {
        return User(
            id: profile.id,
            email: profile.email ?? "",
            username: profile.username,
            phoneNumber: profile.phone_number,
            avatarUrl: nil,
            membershipLevel: MembershipLevel(rawValue: profile.membership_level ?? "basic") ?? .basic,
            membershipExpiry: parseDate(from: profile.membership_expiry),
            dailyConsultationsUsed: 0,
            extraCaseSlots: 0
        )
    }
    
    private func parseDate(from string: String?) -> Date? {
        guard let string = string else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)
    }
}

// MARK: - Apple Sign In Delegate

private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<ASAuthorizationAppleIDCredential, Error>) -> Void
    
    init(completion: @escaping (Result<ASAuthorizationAppleIDCredential, Error>) -> Void) {
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            completion(.success(appleIDCredential))
        } else {
            completion(.failure(AuthenticationError.invalidAppleCredentials))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if #available(iOS 15.0, *) {
            return UIApplication.shared.connectedScenes
                .first { $0.activationState == .foregroundActive }
                .flatMap { $0 as? UIWindowScene }?
                .windows
                .first { $0.isKeyWindow } ?? UIWindow()
        } else {
            return UIApplication.shared.connectedScenes
                .first { $0.activationState == .foregroundActive }
                .flatMap { $0 as? UIWindowScene }?
                .windows
                .first { $0.isKeyWindow } ?? UIWindow()
        }
    }
}

// MARK: - 认证错误

enum AuthenticationError: LocalizedError {
    case invalidAppleCredentials
    case notImplemented(String)
    case tokenExpired
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidAppleCredentials:
            return "Apple ID 认证信息无效"
        case .notImplemented(let feature):
            return "\(feature)功能暂未实现"
        case .tokenExpired:
            return "登录已过期，请重新登录"
        case .networkError:
            return "网络连接错误"
        }
    }
}