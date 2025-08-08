import SwiftUI
import StoreKit

struct EnhancedPaymentView: View {
    @StateObject private var paymentService = PaymentService.shared
    @Environment(\.dismiss) private var dismiss
    
    let paymentItem: PaymentItem
    @State private var selectedPaymentMethod: PaymentMethod = .applePay
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 商品信息
                        productInfoSection
                        
                        // 支付方式选择
                        paymentMethodSelector
                        
                        // 支付详情
                        paymentDetailsSection
                        
                        // 支付按钮
                        paymentButtonSection
                        
                        // 服务条款
                        termsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("确认支付")
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
        .alert("支付结果", isPresented: .constant(paymentService.purchaseResult != nil || paymentService.errorMessage != nil)) {
            Button("确定") {
                if paymentService.purchaseResult != nil {
                    dismiss()
                }
                paymentService.purchaseResult = nil
                paymentService.errorMessage = nil
            }
        } message: {
            if let error = paymentService.errorMessage {
                Text(error)
            } else if let result = paymentService.purchaseResult {
                switch result {
                case .success:
                    Text("支付成功！")
                case .cancelled:
                    Text("支付已取消")
                case .pending:
                    Text("支付处理中，请稍候...")
                }
            }
        }
        .disabled(paymentService.isLoading)
        .overlay {
            if paymentService.isLoading {
                PaymentLoadingOverlay()
            }
        }
    }
    
    // MARK: - 视图组件
    
    private var productInfoSection: some View {
        VStack(spacing: 16) {
            // 商品图标
            Image(systemName: paymentItem.iconName)
                .font(.system(size: 60))
                .foregroundColor(paymentItem.accentColor)
                .frame(width: 100, height: 100)
                .background(
                    Circle()
                        .fill(paymentItem.accentColor.opacity(0.1))
                )
            
            // 商品信息
            VStack(spacing: 8) {
                Text(paymentItem.title)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(paymentItem.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                // 价格
                HStack {
                    if let originalPrice = paymentItem.originalPrice {
                        Text(String(format: "¥%.2f", originalPrice))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                            .strikethrough()
                    }
                    
                    Text(String(format: "¥%.2f", paymentItem.price))
                        .font(.title.bold())
                        .foregroundColor(paymentItem.accentColor)
                }
                
                // 特色功能列表
                if !paymentItem.features.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(paymentItem.features, id: \.self) { feature in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                
                                Text(feature)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private var paymentMethodSelector: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("选择支付方式")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    EnhancedPaymentMethodRow(
                        method: method,
                        isSelected: selectedPaymentMethod == method,
                        onSelect: {
                            selectedPaymentMethod = method
                        }
                    )
                }
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private var paymentDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("支付详情")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                PaymentDetailRow(title: "商品价格", value: String(format: "¥%.2f", paymentItem.price))
                
                if selectedPaymentMethod != .applePay {
                    PaymentDetailRow(title: "手续费", value: "¥0.00", note: "限时免费")
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                PaymentDetailRow(
                    title: "总计",
                    value: String(format: "¥%.2f", paymentItem.price),
                    isTotal: true
                )
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private var paymentButtonSection: some View {
        VStack(spacing: 16) {
            Button {
                Task {
                    await handlePayment()
                }
            } label: {
                HStack {
                    Image(systemName: selectedPaymentMethod.iconName)
                        .font(.title3)
                    
                    Text("\(selectedPaymentMethod.displayName)支付")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(paymentItem.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(paymentService.isLoading)
            
            // 安全提示
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("支付信息已加密保护")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("点击支付即表示同意")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            HStack(spacing: 4) {
                Button("《用户协议》") {
                    // 打开用户协议
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Text("和")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Button("《隐私政策》") {
                    // 打开隐私政策
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - 支付处理
    
    private func handlePayment() async {
        switch selectedPaymentMethod {
        case .applePay:
            await handleApplePayment()
        case .wechat:
            await handleWeChatPayment()
        case .alipay:
            await handleAlipayPayment()
        }
    }
    
    private func handleApplePayment() async {
        // 查找对应的App Store产品
        guard let product = paymentService.availableProducts.first(where: { product in
            getProductIDForPaymentItem(paymentItem) == product.id
        }) else {
            paymentService.errorMessage = "商品信息加载失败"
            return
        }
        
        do {
            try await paymentService.purchase(product)
        } catch {
            // 错误已在PaymentService中处理
        }
    }
    
    private func handleWeChatPayment() async {
        do {
            try await paymentService.payWithWeChat(
                amount: Decimal(paymentItem.price),
                productType: paymentItem.type.rawValue
            )
        } catch {
            // 错误已在PaymentService中处理
        }
    }
    
    private func handleAlipayPayment() async {
        do {
            try await paymentService.payWithAlipay(
                amount: Decimal(paymentItem.price),
                productType: paymentItem.type.rawValue
            )
        } catch {
            // 错误已在PaymentService中处理
        }
    }
    
    // MARK: - 辅助方法
    
    private func getProductIDForPaymentItem(_ item: PaymentItem) -> String {
        switch item.type {
        case .basicMembership:
            return PaymentService.ProductID.basicMembership
        case .premiumMembership:
            return PaymentService.ProductID.premiumMembership
        case .consultationPack:
            return PaymentService.ProductID.consultationPack
        case .caseSlot:
            return PaymentService.ProductID.caseSlot
        }
    }
}

// MARK: - 支付方式行

struct EnhancedPaymentMethodRow: View {
    let method: PaymentMethod
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: method.iconName)
                    .font(.title3)
                    .foregroundColor(method.accentColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(method.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text(method.subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .white.opacity(0.5))
                    .font(.title3)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 支付详情行

struct PaymentDetailRow: View {
    let title: String
    let value: String
    let note: String?
    let isTotal: Bool
    
    init(title: String, value: String, note: String? = nil, isTotal: Bool = false) {
        self.title = title
        self.value = value
        self.note = note
        self.isTotal = isTotal
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(isTotal ? .subheadline.bold() : .subheadline)
                .foregroundColor(.white.opacity(isTotal ? 1.0 : 0.8))
            
            if let note = note {
                Text(note)
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.green.opacity(0.2)))
            }
            
            Spacer()
            
            Text(value)
                .font(isTotal ? .subheadline.bold() : .subheadline)
                .foregroundColor(isTotal ? AppTheme.accentColor : .white)
        }
    }
}

// MARK: - 加载覆盖层

struct PaymentLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("支付处理中...")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text("请勿关闭应用")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.7))
            )
        }
    }
}

// MARK: - 支持类型

enum PaymentMethod: CaseIterable {
    case applePay
    case wechat
    case alipay
    
    var displayName: String {
        switch self {
        case .applePay: return "Apple Pay"
        case .wechat: return "微信支付"
        case .alipay: return "支付宝"
        }
    }
    
    var subtitle: String {
        switch self {
        case .applePay: return "快速安全的Apple支付"
        case .wechat: return "使用微信钱包支付"
        case .alipay: return "使用支付宝钱包支付"
        }
    }
    
    var iconName: String {
        switch self {
        case .applePay: return "apple.logo"
        case .wechat: return "message.fill"
        case .alipay: return "creditcard.fill"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .applePay: return .primary
        case .wechat: return .green
        case .alipay: return .blue
        }
    }
}

struct PaymentItem {
    let id: String
    let title: String
    let description: String
    let price: Double
    let originalPrice: Double?
    let type: PaymentItemType
    let features: [String]
    let iconName: String
    let accentColor: Color
    
    enum PaymentItemType: String {
        case basicMembership = "basic_membership"
        case premiumMembership = "premium_membership"
        case consultationPack = "consultation_pack"
        case caseSlot = "case_slot"
    }
}

#Preview {
    EnhancedPaymentView(
        paymentItem: PaymentItem(
            id: "premium",
            title: "专业会员",
            description: "享受无限制的AI法律咨询和案件管理服务",
            price: 99.9,
            originalPrice: 199.9,
            type: .premiumMembership,
            features: [
                "无限AI法律咨询",
                "无限案件创建",
                "专业文档生成",
                "优先客服支持"
            ],
            iconName: "crown.fill",
            accentColor: .orange
        )
    )
}