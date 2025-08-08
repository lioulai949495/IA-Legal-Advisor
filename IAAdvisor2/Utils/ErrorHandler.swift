import SwiftUI

// MARK: - 应用错误类型
enum AppError: LocalizedError, Identifiable {
    case networkError(String)
    case validationError(String)
    case authenticationError(String)
    case dataError(String)
    case unknownError
    
    var id: String {
        switch self {
        case .networkError(let message): return "network_\(message)"
        case .validationError(let message): return "validation_\(message)"
        case .authenticationError(let message): return "auth_\(message)"
        case .dataError(let message): return "data_\(message)"
        case .unknownError: return "unknown"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "网络错误：\(message)"
        case .validationError(let message):
            return "输入错误：\(message)"
        case .authenticationError(let message):
            return "认证错误：\(message)"
        case .dataError(let message):
            return "数据错误：\(message)"
        case .unknownError:
            return "未知错误，请稍后重试"
        }
    }
    
    var icon: String {
        switch self {
        case .networkError: return "wifi.exclamationmark"
        case .validationError: return "exclamationmark.triangle"
        case .authenticationError: return "person.badge.minus"
        case .dataError: return "externaldrive.badge.exclamationmark"
        case .unknownError: return "questionmark.circle"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .networkError: return .warning
        case .validationError: return .info
        case .authenticationError: return .error
        case .dataError: return .error
        case .unknownError: return .error
        }
    }
}

// MARK: - 错误严重程度
enum ErrorSeverity {
    case info
    case warning
    case error
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}

// MARK: - 错误处理管理器
@MainActor
class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var showError = false
    
    static let shared = ErrorHandler()
    
    private init() {}
    
    /// 处理错误
    func handle(_ error: Error) {
        let appError: AppError
        
        if let localError = error as? AppError {
            appError = localError
        } else {
            // 将系统错误转换为应用错误
            appError = mapSystemError(error)
        }
        
        currentError = appError
        showError = true
        
        // 记录错误日志
        logError(appError)
    }
    
    /// 清除错误
    func clearError() {
        currentError = nil
        showError = false
    }
    
    /// 显示错误消息
    func showError(_ error: AppError) {
        currentError = error
        showError = true
    }
    
    // MARK: - Private Methods
    
    /// 将系统错误映射为应用错误
    private func mapSystemError(_ error: Error) -> AppError {
        switch error {
        case let urlError as URLError:
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkError("网络连接断开")
            case .timedOut:
                return .networkError("请求超时")
            case .cannotConnectToHost:
                return .networkError("无法连接到服务器")
            default:
                return .networkError(urlError.localizedDescription)
            }
        case let decodingError as DecodingError:
            return .dataError("数据解析失败")
        default:
            return .unknownError
        }
    }
    
    /// 记录错误日志
    private func logError(_ error: AppError) {
        #if DEBUG
        print("🚨 Error: \(error.errorDescription ?? "Unknown error")")
        #endif
        
        // 在生产环境中，这里可以发送错误到日志服务
        // Analytics.shared.logError(error)
    }
}

// MARK: - 错误显示组件
struct ErrorAlertModifier: ViewModifier {
    @ObservedObject var errorHandler = ErrorHandler.shared
    
    func body(content: Content) -> some View {
        content
            .alert(item: Binding<AppError?>(
                get: { errorHandler.currentError },
                set: { _ in errorHandler.clearError() }
            )) { error in
                Alert(
                    title: Text("提示"),
                    message: Text(error.errorDescription ?? ""),
                    dismissButton: .default(Text("确定")) {
                        errorHandler.clearError()
                    }
                )
            }
    }
}

// MARK: - 错误横幅组件
struct ErrorBanner: View {
    let error: AppError
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: error.icon)
                .foregroundColor(error.severity.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("错误")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(error.errorDescription ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(error.severity.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(error.severity.color.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

// MARK: - View Extensions
extension View {
    /// 添加错误处理
    func withErrorHandling() -> some View {
        self.modifier(ErrorAlertModifier())
    }
    
    /// 显示错误横幅
    func errorBanner(_ error: AppError?, onDismiss: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            if let error = error {
                ErrorBanner(error: error, onDismiss: onDismiss)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: error.id)
            }
            
            self
        }
    }
}