import SwiftUI

// MARK: - 应用常量
struct AppConstants {
    
    // MARK: - 应用信息
    struct App {
        static let name = "IA法律顾问"
        static let version = "1.0.0"
        static let buildNumber = "1"
        static let bundleIdentifier = "com.ialegaladvisor.app"
        static let company = "IA Legal Advisor Team"
        static let copyright = "Copyright © 2024 IA法律顾问. All rights reserved."
        static let appStoreURL = "https://apps.apple.com/app/id1234567890" // 待更新
        static let privacyPolicyURL = "https://ialegaladvisor.com/privacy"
        static let termsOfServiceURL = "https://ialegaladvisor.com/terms"
        static let supportEmail = "support@ialegaladvisor.com"
        static let minimumIOSVersion = "15.0"
        
        // 获取当前运行的版本信息
        static var currentVersion: String {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? version
        }
        
        static var currentBuildNumber: String {
            Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? buildNumber
        }
        
        static var versionWithBuild: String {
            return "\(currentVersion) (\(currentBuildNumber))"
        }
    }
    
    // MARK: - UI尺寸
    struct UI {
        // 导航栏
        static let navigationBarHeight: CGFloat = 44
        static let statusBarPadding: CGFloat = 20
        
        // 圆角
        static let defaultCornerRadius: CGFloat = 16
        static let smallCornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 24
        
        // 间距
        static let defaultPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        
        // 按钮
        static let buttonHeight: CGFloat = 50
        static let iconButtonSize: CGFloat = 44
        
        // 输入框
        static let textFieldHeight: CGFloat = 50
        
        // 侧边栏
        static let sidebarWidth: CGFloat = 320
    }
    
    // MARK: - 时间常量
    struct Time {
        static let oneDay: TimeInterval = 86400
        static let oneWeek: TimeInterval = 86400 * 7
        static let verificationCodeCountdown: Int = 60
        static let animationDuration: Double = 0.3
        static let bubbleUpdateInterval: Double = 1.0
    }
    
    // MARK: - 文本限制
    struct TextLimits {
        static let phoneNumberLength = 11
        static let verificationCodeLength = 6
        static let maxCaseTitleLength = 100
        static let maxCaseDescriptionLength = 1000
    }
    
    // MARK: - 网络配置
    struct Network {
        static let requestTimeout: TimeInterval = 30
        static let maxRetryCount = 3
    }
    
    // MARK: - 用户默认设置
    struct UserDefaults {
        static let hasShownOnboarding = "hasShownOnboarding"
        static let preferredLanguage = "preferredLanguage"
        static let notificationSettings = "notificationSettings"
    }
}

// MARK: - 业务常量
struct BusinessConstants {
    
    // MARK: - 案件类型
    static let caseTypes = [
        "民事纠纷", "劳动争议", "合同纠纷", "房产纠纷", 
        "婚姻家庭", "交通事故", "知识产权", "其他"
    ]
    
    // MARK: - 免费咨询次数
    static let freeChatLimit = 3
    static let shareRewardCount = 1
    
    // MARK: - 案件状态
    enum CaseStatus: String, CaseIterable {
        case pending = "待处理"
        case inProgress = "处理中"
        case completed = "已完成"
        case cancelled = "已取消"
    }
}