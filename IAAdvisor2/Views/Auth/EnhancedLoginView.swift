import SwiftUI
import AuthenticationServices

struct EnhancedLoginView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var selectedLoginMethod: LoginMethod = .phone
    @State private var showingEmailLogin = false
    @State private var showingPhoneLogin = false
    
    // 手机登录状态
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var showingCodeInput = false
    
    // 邮箱登录状态
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegister = false
    @State private var username = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 40) {
                    // 应用Logo和标题
                    appHeader
                    
                    // 登录方式选择
                    loginMethodSelector
                    
                    // 主要登录区域
                    mainLoginArea
                    
                    // 其他登录方式
                    alternativeLoginMethods
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
            }
        }
        .alert("登录失败", isPresented: .constant(authService.errorMessage != nil)) {
            Button("确定") {
                authService.errorMessage = nil
            }
        } message: {
            if let error = authService.errorMessage {
                Text(error)
            }
        }
        .disabled(authService.isLoading)
        .overlay {
            if authService.isLoading {
                LoadingOverlay()
            }
        }
    }
    
    // MARK: - 视图组件
    
    private var appHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "scale.3d")
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(.white)
                .modifier(ConditionalSymbolEffect())
            
            Text("IA法律顾问")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            
            Text("智能法律服务平台")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private var loginMethodSelector: some View {
        HStack(spacing: 0) {
            ForEach(LoginMethod.allCases, id: \.self) { method in
                Button {
                    selectedLoginMethod = method
                } label: {
                    Text(method.displayName)
                        .font(.subheadline.weight(selectedLoginMethod == method ? .semibold : .medium))
                        .foregroundColor(selectedLoginMethod == method ? AppTheme.accentColor : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedLoginMethod == method ? Color.white.opacity(0.15) : Color.clear)
                        )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.08))
        )
    }
    
    private var mainLoginArea: some View {
        VStack(spacing: 20) {
            switch selectedLoginMethod {
            case .phone:
                phoneLoginView
            case .email:
                emailLoginView
            case .apple:
                appleLoginView
            }
        }
        .padding()
        .liquidGlass()
    }
    
    // MARK: - 登录方式视图
    
    private var phoneLoginView: some View {
        VStack(spacing: 20) {
            Text("手机验证码登录")
                .font(.headline)
                .foregroundColor(.white)
            
            if !showingCodeInput {
                // 手机号输入
                VStack(spacing: 16) {
                    CustomTextField(
                        placeholder: "请输入手机号",
                        text: $phoneNumber,
                        keyboardType: .phonePad,
                        icon: "phone.fill"
                    )
                    
                    Button("发送验证码") {
                        Task {
                            do {
                                try await authService.sendPhoneVerificationCode(phoneNumber)
                                showingCodeInput = true
                            } catch {
                                // 错误已在AuthService中处理
                            }
                        }
                    }
                    .primaryButtonStyle()
                    .disabled(phoneNumber.count < 11)
                }
            } else {
                // 验证码输入
                VStack(spacing: 16) {
                    Text("验证码已发送至 \(phoneNumber)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    CustomTextField(
                        placeholder: "请输入验证码",
                        text: $verificationCode,
                        keyboardType: .numberPad,
                        icon: "number.circle.fill"
                    )
                    
                    Button("登录") {
                        Task {
                            do {
                                try await authService.loginWithPhone(phoneNumber, code: verificationCode)
                            } catch {
                                // 错误已在AuthService中处理
                            }
                        }
                    }
                    .primaryButtonStyle()
                    .disabled(verificationCode.count < 4)
                    
                    Button("重新发送验证码") {
                        showingCodeInput = false
                        verificationCode = ""
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    private var emailLoginView: some View {
        VStack(spacing: 20) {
            Text(showingRegister ? "邮箱注册" : "邮箱登录")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                if showingRegister {
                    CustomTextField(
                        placeholder: "用户名",
                        text: $username,
                        icon: "person.fill"
                    )
                }
                
                CustomTextField(
                    placeholder: "邮箱地址",
                    text: $email,
                    keyboardType: .emailAddress,
                    icon: "envelope.fill"
                )
                
                CustomSecureField(
                    placeholder: "密码",
                    text: $password,
                    icon: "lock.fill"
                )
                
                if showingRegister {
                    CustomSecureField(
                        placeholder: "确认密码",
                        text: $confirmPassword,
                        icon: "lock.fill"
                    )
                }
                
                Button(showingRegister ? "注册" : "登录") {
                    Task {
                        do {
                            if showingRegister {
                                try await authService.registerWithEmail(email, password: password, username: username)
                            } else {
                                try await authService.loginWithEmail(email, password: password)
                            }
                        } catch {
                            // 错误已在AuthService中处理
                        }
                    }
                }
                .primaryButtonStyle()
                .disabled(!isEmailFormValid)
                
                Button(showingRegister ? "已有账号？去登录" : "没有账号？去注册") {
                    showingRegister.toggle()
                    password = ""
                    confirmPassword = ""
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private var appleLoginView: some View {
        VStack(spacing: 20) {
            Text("Apple ID 登录")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("使用您的Apple ID快速安全登录")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            SignInWithAppleButton { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                Task {
                    do {
                        try await authService.signInWithApple()
                    } catch {
                        // 错误已在AuthService中处理
                    }
                }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .cornerRadius(8)
        }
    }
    
    private var alternativeLoginMethods: some View {
        VStack(spacing: 16) {
            Text("其他登录方式")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            HStack(spacing: 20) {
                // 微信登录按钮
                Button {
                    Task {
                        do {
                            try await authService.loginWithWeChat()
                        } catch {
                            // 暂未实现，显示提示
                            authService.errorMessage = "微信登录功能即将上线"
                        }
                    }
                } label: {
                    socialLoginButton(
                        icon: "message.fill",
                        title: "微信",
                        color: .green
                    )
                }
                
                // 支付宝登录按钮
                Button {
                    Task {
                        do {
                            try await authService.loginWithAlipay()
                        } catch {
                            // 暂未实现，显示提示
                            authService.errorMessage = "支付宝登录功能即将上线"
                        }
                    }
                } label: {
                    socialLoginButton(
                        icon: "creditcard.fill",
                        title: "支付宝",
                        color: .blue
                    )
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private var isEmailFormValid: Bool {
        if showingRegister {
            return !email.isEmpty && 
                   !password.isEmpty && 
                   !username.isEmpty &&
                   password == confirmPassword &&
                   email.contains("@")
        } else {
            return !email.isEmpty && 
                   !password.isEmpty &&
                   email.contains("@")
        }
    }
    
    private func socialLoginButton(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(color.opacity(0.3))
                )
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - 登录方式枚举

enum LoginMethod: CaseIterable {
    case phone
    case email
    case apple
    
    var displayName: String {
        switch self {
        case .phone: return "手机"
        case .email: return "邮箱"
        case .apple: return "Apple ID"
        }
    }
}

// MARK: - 自定义文本框组件

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let icon: String
    
    init(placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default, icon: String) {
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.icon = icon
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CustomSecureField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            SecureField(placeholder, text: $text)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - 加载覆盖层

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("登录中...")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.7))
            )
        }
    }
}

// MARK: - View Extensions

struct ConditionalSymbolEffect: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.symbolEffect(.pulse)
        } else {
            content.pulse() // Use our custom pulse effect from Theme.swift
        }
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    EnhancedLoginView()
}