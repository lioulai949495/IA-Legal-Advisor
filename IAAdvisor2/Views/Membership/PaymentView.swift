import SwiftUI

struct MembershipPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    
    let title: String
    let description: String
    let price: Double
    let onPaymentSuccess: () -> Void
    
    @State private var selectedPaymentMethod: MembershipPaymentMethod = .alipay
    @State private var isProcessing = false
    @State private var showingSuccess = false
    @State private var agreeToTerms = false
    @State private var showingUnavailableAlert = false
    @State private var unavailablePaymentMethod = ""
    @State private var showingUserAgreement = false
    @State private var showingPrivacyPolicy = false
    @State private var showingPaymentTerms = false
    
    enum MembershipPaymentMethod: String, CaseIterable {
        case alipay = "支付宝"
        case wechat = "微信支付"
        case applepay = "Apple Pay"
        
        var icon: String {
            switch self {
            case .alipay: return "a.circle.fill"
            case .wechat: return "w.circle.fill"
            case .applepay: return "apple.logo"
            }
        }
        
        var color: Color {
            switch self {
            case .alipay: return .blue
            case .wechat: return .green
            case .applepay: return .black
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 订单信息
                        orderInfoSection
                        
                        // 支付方式选择
                        paymentMethodSection
                        
                        // 协议确认
                        termsSection
                        
                        // 支付按钮
                        paymentButton
                        
                        // 安全提示
                        securityNotice
                    }
                    .padding()
                }
            }
            .navigationTitle("支付订单")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .overlay {
            if showingSuccess {
                PaymentSuccessOverlay {
                    showingSuccess = false
                    onPaymentSuccess()
                    dismiss()
                }
            }
        }
        .alert("\(unavailablePaymentMethod)暂不支持", isPresented: $showingUnavailableAlert) {
            Button("选择Apple Pay") {
                selectedPaymentMethod = .applepay
            }
            Button("好的", role: .cancel) { }
        } message: {
            Text("该支付方式正在开发中，请选择Apple Pay进行支付，或联系客服获取其他支付方式。")
        }
        .sheet(isPresented: $showingUserAgreement) {
            UserAgreementView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingPaymentTerms) {
            PaymentTermsView()
        }
    }
    
    // MARK: - 订单信息
    private var orderInfoSection: some View {
        VStack(spacing: 16) {
            // 服务图标
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text(description)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            // 价格显示
            HStack {
                Text("订单金额")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(alignment: .bottom, spacing: 2) {
                    Text("¥")
                        .font(.title3)
                        .foregroundColor(.green)
                    
                    Text("\(price, specifier: "%.1f")")
                        .font(.largeTitle.bold())
                        .foregroundColor(.green)
                }
            }
            .padding()
            .liquidGlass()
        }
    }
    
    // MARK: - 支付方式选择
    private var paymentMethodSection: some View {
        VStack(spacing: 16) {
            Text("选择支付方式")
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(MembershipPaymentMethod.allCases, id: \.self) { method in
                    PaymentMethodRow(
                        method: method,
                        isSelected: selectedPaymentMethod == method,
                        onSelect: { selectedPaymentMethod = method }
                    )
                }
            }
        }
    }
    
    // MARK: - 协议确认
    private var termsSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                agreeToTerms.toggle()
            } label: {
                Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(agreeToTerms ? .blue : .white.opacity(0.6))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("我已阅读并同意以下协议")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                HStack(spacing: 16) {
                    Button("《用户协议》") {
                        showingUserAgreement = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    
                    Button("《隐私政策》") {
                        showingPrivacyPolicy = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    
                    Button("《支付条款》") {
                        showingPaymentTerms = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding()
        .liquidGlass()
    }
    
    // MARK: - 支付按钮
    private var paymentButton: some View {
        Button {
            processPayment()
        } label: {
            HStack {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: selectedPaymentMethod.icon)
                }
                
                Text(isProcessing ? "支付处理中..." : "确认支付 ¥\(price, specifier: "%.1f")")
                    .font(.headline.bold())
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                agreeToTerms && !isProcessing ?
                LinearGradient(
                    gradient: Gradient(colors: [selectedPaymentMethod.color, selectedPaymentMethod.color.opacity(0.7)]),
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    gradient: Gradient(colors: [.gray, .gray]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(!agreeToTerms || isProcessing)
    }
    
    // MARK: - 安全提示
    private var securityNotice: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "shield.checkerboard")
                    .foregroundColor(.green)
                
                Text("安全支付保障")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("支付信息加密传输，保障资金安全")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("支持7天无理由退款，购买无忧")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("24小时客服支持，随时为您服务")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding()
        .liquidGlass()
    }
    
    // MARK: - 私有方法
    private func processPayment() {
        isProcessing = true
        
        switch selectedPaymentMethod {
        case .applepay:
            // Apple Pay 支付 - 模拟成功
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isProcessing = false
                showingSuccess = true
                // 调用成功回调
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    onPaymentSuccess()
                    dismiss()
                }
            }
            
        case .alipay:
            // 支付宝 - 显示暂不支持提示
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isProcessing = false
                unavailablePaymentMethod = "支付宝"
                showingUnavailableAlert = true
            }
            
        case .wechat:
            // 微信支付 - 显示暂不支持提示
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isProcessing = false
                unavailablePaymentMethod = "微信支付"
                showingUnavailableAlert = true
            }
        }
    }
    
    private func showPaymentUnavailableAlert(method: String) {
        let alert = UIAlertController(
            title: "\(method)暂不支持",
            message: "该支付方式正在开发中，请选择Apple Pay进行支付，或联系客服获取其他支付方式。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        alert.addAction(UIAlertAction(title: "选择Apple Pay", style: .default) { _ in
            selectedPaymentMethod = .applepay
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

// MARK: - 支付方式行
struct PaymentMethodRow: View {
    let method: MembershipPaymentView.MembershipPaymentMethod
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: method.icon)
                    .font(.title2)
                    .foregroundColor(method.color)
                    .frame(width: 30)
                
                Text(method.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.6))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? method.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 支付成功覆盖层
struct PaymentSuccessOverlay: View {
    let onDismiss: () -> Void
    @State private var showCheckmark = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // 成功动画图标
                ZStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 100, height: 100)
                    
                    if showCheckmark {
                        Image(systemName: "checkmark")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showCheckmark = true
                    }
                }
                
                VStack(spacing: 12) {
                    Text("支付成功！")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text("恭喜您成功升级会员，现在可以享受更多专业服务")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button("确定") {
                    onDismiss()
                }
                .font(.headline.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .background(.blue)
                .cornerRadius(25)
            }
            .padding()
        }
        .transition(.opacity)
    }
}

#Preview {
    MembershipPaymentView(
        title: "专业版会员",
        description: "升级到专业版，享受无限次AI咨询和专业法律服务",
        price: 99.9,
        onPaymentSuccess: {}
    )
}