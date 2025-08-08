import Foundation

// MARK: - 环境配置管理
struct EnvironmentConfig {
    
    // MARK: - 环境判断
    static var isProduction: Bool {
        #if PRODUCTION
        return true
        #else
        return false
        #endif
    }
    
    static var isDevelopment: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - API配置
    static var apiBaseURL: String {
        #if PRODUCTION
        return "https://api.ialegaladvisor.com"
        #else
        return "https://ia-legal-advisor.onrender.com"
        #endif
    }
    
    static var apiTimeout: TimeInterval {
        #if PRODUCTION
        return 30.0
        #else
        return 120.0 // 开发环境更长超时时间，适应Render免费服务冷启动
        #endif
    }
    
    static var longApiTimeout: TimeInterval {
        #if PRODUCTION
        return 60.0
        #else
        return 180.0 // 针对可能的冷启动情况的超长超时
        #endif
    }
    
    // MARK: - 日志配置
    static var logLevel: LogLevel {
        #if PRODUCTION
        return .error
        #else
        return .debug
        #endif
    }
    
    static var enableVerboseLogging: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - 功能开关
    static var enableAnalytics: Bool {
        #if PRODUCTION
        return true
        #else
        return false
        #endif
    }
    
    static var enableCrashReporting: Bool {
        #if PRODUCTION
        return true
        #else
        return false
        #endif
    }
    
    static var enablePushNotifications: Bool {
        #if PRODUCTION
        return true
        #else
        return true // 开发环境也启用以便测试
        #endif
    }
    
    // MARK: - 缓存配置
    static var cacheExpirationTime: TimeInterval {
        #if PRODUCTION
        return 1800 // 30分钟
        #else
        return 300  // 5分钟
        #endif
    }
    
    static var maxCacheSize: Int {
        #if PRODUCTION
        return 100 * 1024 * 1024 // 100MB
        #else
        return 50 * 1024 * 1024  // 50MB
        #endif
    }
    
    // MARK: - 安全配置
    static var allowHTTP: Bool {
        #if PRODUCTION
        return false
        #else
        return true // 开发环境允许HTTP
        #endif
    }
    
    static var certificatePinning: Bool {
        #if PRODUCTION
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - 性能配置
    static var maxRetryCount: Int {
        #if PRODUCTION
        return 3
        #else
        return 5 // 开发环境更多重试次数
        #endif
    }
    
    static var enableRequestCompression: Bool {
        #if PRODUCTION
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - 调试功能
    static var showDebugPanel: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var enableNetworkLogging: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

// MARK: - 日志级别枚举
enum LogLevel: Int, CaseIterable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    
    var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        }
    }
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

// MARK: - 日志管理器
class Logger {
    static let shared = Logger()
    
    private init() {}
    
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        guard level.rawValue >= EnvironmentConfig.logLevel.rawValue else { return }
        
        let fileName = (file as NSString).lastPathComponent
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        
        if EnvironmentConfig.enableVerboseLogging {
            print("\(level.emoji) [\(timestamp)] [\(level.description)] \(fileName):\(line) \(function) - \(message)")
        } else {
            print("\(level.emoji) \(message)")
        }
        
        // 生产环境发送到崩溃报告服务
        if EnvironmentConfig.isProduction && level == .error {
            // TODO: 发送到 Crashlytics 或其他服务
        }
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
}

// MARK: - DateFormatter 扩展
private extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}