import Foundation
import StoreKit
import Combine

@MainActor
class PaymentService: NSObject, ObservableObject {
    @MainActor static let shared = PaymentService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var purchaseResult: PurchaseResult?
    
    // 支付产品
    @Published var availableProducts: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    
    private let apiService: APIService
    private var cancellables = Set<AnyCancellable>()
    private var updateListenerTask: Task<Void, Error>?
    
    // 产品ID定义
    enum ProductID {
        static let basicMembership = "com.ialegaladvisor.membership.basic"
        static let premiumMembership = "com.ialegaladvisor.membership.premium" 
        static let consultationPack = "com.ialegaladvisor.consultation.10pack"
        static let caseSlot = "com.ialegaladvisor.case.slot"
        
        static let allProductIDs = [
            basicMembership,
            premiumMembership, 
            consultationPack,
            caseSlot
        ]
    }
    
    override init() {
        self.apiService = .shared
        super.init()
        
        // 开始监听交易更新
        updateListenerTask = listenForTransactions()
        
        // 加载产品
        Task {
            await loadProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        do {
            let products = try await Product.products(for: ProductID.allProductIDs)
            await MainActor.run {
                self.availableProducts = products
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "加载商品信息失败: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Apple Pay / StoreKit Purchase
    
    func purchase(_ product: Product) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            await handlePurchaseResult(result)
        } catch {
            isLoading = false
            errorMessage = "购买失败: \(error.localizedDescription)"
            throw PaymentError.purchaseFailed(error)
        }
    }
    
    private func handlePurchaseResult(_ result: Product.PurchaseResult) async {
        switch result {
        case .success(let verification):
            // 验证交易
            do {
                let transaction = try checkVerified(verification)
                
                // 发送收据到后端验证
                try await verifyPurchaseWithBackend(storeKitTransaction: transaction)
                
                // 完成交易
                await transaction.finish()
                
                await MainActor.run {
                    self.purchaseResult = .success(transaction.productID)
                    self.purchasedProductIDs.insert(transaction.productID)
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "交易验证失败: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
            
        case .userCancelled:
            await MainActor.run {
                self.purchaseResult = .cancelled
                self.isLoading = false
            }
            
        case .pending:
            await MainActor.run {
                self.purchaseResult = .pending
                self.isLoading = false
            }
            
        @unknown default:
            await MainActor.run {
                self.errorMessage = "未知的购买结果"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - 第三方支付 (微信/支付宝)
    
    func payWithWeChat(amount: Decimal, productType: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // 向后端请求微信支付订单
            let paymentOrder = try await apiService.createWeChatPayment(
                amount: amount, 
                productType: productType
            )
            
            // TODO: 调用微信支付SDK
            // 这里需要集成微信支付SDK
            try await processWeChatPayment(order: paymentOrder)
            
            await MainActor.run {
                self.purchaseResult = .success(productType)
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "微信支付失败: \(error.localizedDescription)"
                self.isLoading = false
            }
            throw error
        }
    }
    
    func payWithAlipay(amount: Decimal, productType: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // 向后端请求支付宝支付订单
            let paymentOrder = try await apiService.createAlipayPayment(
                amount: amount,
                productType: productType
            )
            
            // TODO: 调用支付宝支付SDK
            // 这里需要集成支付宝支付SDK
            try await processAlipayPayment(order: paymentOrder)
            
            await MainActor.run {
                self.purchaseResult = .success(productType)
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "支付宝支付失败: \(error.localizedDescription)"
                self.isLoading = false
            }
            throw error
        }
    }
    
    // MARK: - Transaction Verification
    
    private func verifyPurchaseWithBackend(storeKitTransaction: StoreKit.Transaction) async throws {
        // 获取收据数据
        guard let receiptData = try await getReceiptData() else {
            throw PaymentError.receiptNotFound
        }
        
        // 发送到后端验证
        try await apiService.verifyApplePurchase(
            receiptData: receiptData,
            productId: storeKitTransaction.productID,
            transactionId: String(storeKitTransaction.id)
        )
    }
    
    private func getReceiptData() async throws -> Data? {
        // iOS 16+ 使用 AppTransaction
        if #available(iOS 16.0, *) {
            do {
                let appTransaction = try await AppTransaction.shared
                return Data(appTransaction.jwsRepresentation.utf8)
            } catch {
                print("获取AppTransaction失败: \(error)")
            }
        }
        
        // 降级到老的收据方式
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            return nil
        }
        
        return receiptData
    }
    
    // MARK: - Transaction Monitoring
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    // 处理交易更新
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("交易更新验证失败: \(error)")
                }
            }
        }
    }
    
    private func updateCustomerProductStatus() async {
        var purchasedProducts: Set<String> = []
        
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try await checkVerified(result)
                purchasedProducts.insert(transaction.productID)
            } catch {
                print("权限验证失败: \(error)")
            }
        }
        
        await MainActor.run {
            self.purchasedProductIDs = purchasedProducts
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws {
        isLoading = true
        
        try await AppStore.sync()
        await updateCustomerProductStatus()
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PaymentError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    private func processWeChatPayment(order: PaymentOrder) async throws {
        // TODO: 集成微信支付SDK
        // 这里需要调用微信支付的具体实现
        throw PaymentError.notImplemented("微信支付")
    }
    
    private func processAlipayPayment(order: PaymentOrder) async throws {
        // TODO: 集成支付宝支付SDK
        // 这里需要调用支付宝支付的具体实现
        throw PaymentError.notImplemented("支付宝支付")
    }
}

// MARK: - Supporting Types

enum PurchaseResult {
    case success(String)  // 产品ID
    case cancelled
    case pending
}

enum PaymentError: LocalizedError {
    case purchaseFailed(Error)
    case failedVerification
    case receiptNotFound
    case backendVerificationFailed
    case notImplemented(String)
    
    var errorDescription: String? {
        switch self {
        case .purchaseFailed(let error):
            return "购买失败: \(error.localizedDescription)"
        case .failedVerification:
            return "交易验证失败"
        case .receiptNotFound:
            return "未找到购买凭证"
        case .backendVerificationFailed:
            return "服务器验证失败"
        case .notImplemented(let feature):
            return "\(feature)功能即将上线"
        }
    }
}

struct PaymentOrder: Codable {
    let orderId: String
    let amount: Decimal
    let productType: String
    let paymentMethod: String
    let orderInfo: String? // 用于第三方支付的订单信息
}

// MARK: - API扩展

extension APIService {
    // 微信支付相关API
    func createWeChatPayment(amount: Decimal, productType: String) async throws -> PaymentOrder {
        let request = CreatePaymentRequest(
            amount: amount,
            product_type: productType,
            payment_method: "wechat"
        )
        let body = try JSONEncoder().encode(request)
        let (data, _) = try await makeRequest(endpoint: "/payments/wechat/create", method: "POST", body: body, requiresAuth: true)
        return try JSONDecoder().decode(PaymentOrder.self, from: data)
    }
    
    // 支付宝支付相关API
    func createAlipayPayment(amount: Decimal, productType: String) async throws -> PaymentOrder {
        let request = CreatePaymentRequest(
            amount: amount,
            product_type: productType,
            payment_method: "alipay"
        )
        let body = try JSONEncoder().encode(request)
        let (data, _) = try await makeRequest(endpoint: "/payments/alipay/create", method: "POST", body: body, requiresAuth: true)
        return try JSONDecoder().decode(PaymentOrder.self, from: data)
    }
    
    // Apple内购验证API
    func verifyApplePurchase(receiptData: Data, productId: String, transactionId: String) async throws {
        let request = VerifyPurchaseRequest(
            receipt_data: receiptData.base64EncodedString(),
            product_id: productId,
            transaction_id: transactionId
        )
        let body = try JSONEncoder().encode(request)
        let (_, _) = try await makeRequest(endpoint: "/payments/apple/verify", method: "POST", body: body, requiresAuth: true)
    }
}

// MARK: - 支付相关数据模型

struct CreatePaymentRequest: Codable {
    let amount: Decimal
    let product_type: String
    let payment_method: String
}

struct VerifyPurchaseRequest: Codable {
    let receipt_data: String
    let product_id: String
    let transaction_id: String
}