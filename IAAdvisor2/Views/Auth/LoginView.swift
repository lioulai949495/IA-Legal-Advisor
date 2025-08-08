import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var showCodeInput = false
    @State private var isCodeSent = false
    @State private var countdown = 60
    @State private var countdownTimer: Timer?
    
    // 动态背景气泡效果
    @State private var bubbles: [Bubble] = []
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
                // 背景渐变
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                // 动态气泡效果
                ForEach(bubbles.indices, id: \.self) { index in
                    Circle()
                        .fill(AppTheme.secondaryColor.opacity(0.1))
                        .frame(width: bubbles[index].size, height: bubbles[index].size)
                        .position(bubbles[index].position)
                        .blur(radius: 20)
                }
                
                // 主要内容
                VStack {
                    // 标题和LOGO
                    VStack(spacing: 10) {
                        Image(systemName: "scale.3d")
                            .font(.system(size: 70))
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                Circle()
                                    .fill(AppTheme.secondaryColor.opacity(0.2))
                                    .frame(width: 120, height: 120)
                            )
                        
                        Text("IA法律顾问")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        
                        Text("您的智能法律解决方案")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 50)
                    
                    // 登录表单
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("手机号")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(AppTheme.accentColor)
                                
                                TextField("请输入手机号", text: $phoneNumber)
                                    .keyboardType(.phonePad)
                                    .foregroundColor(.white)
                                    .disabled(isCodeSent)
                                    .onSubmit {
                                        hideKeyboard()
                                    }
                            }
                            .padding()
                            .liquidGlass()
                        }
                        
                        if showCodeInput {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("验证码")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack {
                                    Image(systemName: "key.fill")
                                        .foregroundColor(AppTheme.accentColor)
                                    
                                    TextField("请输入验证码", text: $verificationCode)
                                        .keyboardType(.numberPad)
                                        .foregroundColor(.white)
                                        .onSubmit {
                                            hideKeyboard()
                                        }
                                }
                                .padding()
                                .liquidGlass()
                            }
                        }

                        if let errorMessage = viewModel.errorMessage {
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: getErrorIcon(for: errorMessage))
                                        .foregroundColor(.red)
                                    Text(errorMessage)
                                        .foregroundColor(.white)
                                        .font(.subheadline)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                }
                                
                                if errorMessage.contains("服务器正在启动") {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.orange)
                                        Text("预计需要1-2分钟...")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .background(Material.ultraThinMaterial)
                            .cornerRadius(12)
                        }
                        
                        if !showCodeInput {
                            Button(action: sendCode) {
                                Text("发送验证码")
                            }
                            .primaryButtonStyle()
                            .disabled(viewModel.isLoading || phoneNumber.isEmpty || !isValidPhoneNumber(phoneNumber))
                        } else {
                            HStack(spacing: 15) {
                                Button(action: login) {
                                    Text("登录")
                                }
                                .primaryButtonStyle()
                                .disabled(viewModel.isLoading || verificationCode.isEmpty)
                                
                                Button(action: resendCode) {
                                    Text(isCodeSent && countdown > 0 ? "\(countdown)s后重发" : "重新发送")
                                }
                                .secondaryButtonStyle()
                                .disabled(isCodeSent && countdown > 0)
                            }
                        }
                        
                        NavigationLink(destination: RegisterView()) {
                            Text("还没有账户？注册一个")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top)
                        
                        HStack(spacing: 40) {
                            thirdPartyLoginButton(icon: "bubble.left.fill", name: "微信登录", color: Color(hex: "07C160"))
                            thirdPartyLoginButton(icon: "wallet.pass.fill", name: "支付宝登录", color: Color(hex: "1677FF"))
                        }
                        .padding(.top)
                    }
                    .padding(.horizontal)
                }
                .padding()
                
                // 加载指示器
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
            .onAppear(perform: setupBubbles)
            .onReceive(timer) { _ in
                updateBubbles()
            }
            .onDisappear {
                // 清理定时器防止内存泄漏
                countdownTimer?.invalidate()
                countdownTimer = nil
            }
    }
    
    private func setupBubbles() {
        bubbles = (0..<10).map { _ in
            Bubble(
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                ),
                size: CGFloat.random(in: 50...150),
                speed: CGFloat.random(in: 0.5...1.5)
            )
        }
    }
    
    private func updateBubbles() {
        for i in bubbles.indices {
            var bubble = bubbles[i]
            bubble.position.y -= bubble.speed
            if bubble.position.y < -bubble.size {
                bubble.position.y = UIScreen.main.bounds.height + bubble.size
                bubble.position.x = CGFloat.random(in: 0...UIScreen.main.bounds.width)
            }
            bubbles[i] = bubble
        }
    }
    
    // 第三方登录按钮
    private func thirdPartyLoginButton(icon: String, name: String, color: Color) -> some View {
        Button(action: { thirdPartyLogin(provider: name) }) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(name)
                    .font(.caption)
            }
            .frame(width: 120)
        }
        .secondaryButtonStyle()
    }
    
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        let phonePattern = "^1[3-9]\\d{9}$"
        let phoneRegex = NSPredicate(format: "SELF MATCHES %@", phonePattern)
        return phoneRegex.evaluate(with: phone)
    }
    
    private func startCountdown() {
        countdown = AppConstants.Time.verificationCodeCountdown
        isCodeSent = true
        
        // 取消之前的定时器
        countdownTimer?.invalidate()
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            countdown -= 1
            if countdown <= 0 {
                timer.invalidate()
                countdownTimer = nil
                isCodeSent = false
            }
        }
    }
    
    private func sendCode() {
        guard !phoneNumber.isEmpty, isValidPhoneNumber(phoneNumber) else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        viewModel.sendVerificationCode(phone: phoneNumber) {
            showCodeInput = true
            startCountdown()
        }
    }
    
    private func resendCode() {
        sendCode()
    }
    
    // 登录
    private func login() {
        guard !phoneNumber.isEmpty, !verificationCode.isEmpty else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        viewModel.login(phone: phoneNumber, code: verificationCode)
    }
    
    // 第三方登录
    private func thirdPartyLogin(provider: String) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        viewModel.isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [self] in
            self.viewModel.currentUser = User(id: "user123", email: "test@example.com", username: "\(provider)用户")
            self.viewModel.isLoading = false
        }
    }
    
    private func getErrorIcon(for message: String) -> String {
        if message.contains("服务器正在启动") {
            return "arrow.clockwise.circle"
        } else if message.contains("网络") {
            return "wifi.exclamationmark"
        } else if message.contains("验证码") {
            return "key.slash"
        } else if message.contains("超时") {
            return "clock.badge.exclamationmark"
        } else {
            return "exclamationmark.triangle"
        }
    }
}

// 气泡模型（用于背景动效）
struct Bubble {
    var position: CGPoint
    var size: CGFloat
    var speed: CGFloat
}

#Preview {
    LoginView()
        .environmentObject(AppViewModel())
} 
