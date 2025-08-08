# IA法律顾问 生产环境部署配置

## 环境配置概览

### 开发环境 (Development)
- **API Base URL**: https://ia-legal-advisor.onrender.com
- **网络安全**: 允许HTTP (ATS例外)
- **日志级别**: 详细调试日志
- **缓存策略**: 短期缓存 (5分钟)

### 生产环境 (Production)
- **API Base URL**: https://api.ialegaladvisor.com
- **网络安全**: 强制HTTPS，移除ATS例外
- **日志级别**: 错误和警告级别
- **缓存策略**: 优化缓存 (30分钟)

## iOS应用构建配置

### 1. Xcode Build Configuration

#### Debug Configuration (开发环境)
```swift
// Constants.swift - Debug配置
#if DEBUG
struct APIConstants {
    static let baseURL = "https://ia-legal-advisor.onrender.com"
    static let logLevel = LogLevel.debug
    static let enableAnalytics = false
    static let enableCrashReporting = false
}
#endif
```

#### Release Configuration (生产环境)
```swift
// Constants.swift - Release配置
#if RELEASE
struct APIConstants {
    static let baseURL = "https://api.ialegaladvisor.com"
    static let logLevel = LogLevel.error
    static let enableAnalytics = true
    static let enableCrashReporting = true
}
#endif
```

### 2. Info.plist 生产环境配置

#### 网络安全 (生产环境)
```xml
<!-- 生产环境 Info.plist - 移除ATS例外 -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSRequiresCertificateTransparency</key>
    <true/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>api.ialegaladvisor.com</key>
        <dict>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
        </dict>
    </dict>
</dict>
```

#### 应用权限配置
```xml
<!-- 必要权限配置 -->
<key>NSCameraUsageDescription</key>
<string>用于扫描法律文件和证据材料</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>用于上传相关图片和文档</string>

<key>NSContactsUsageDescription</key>
<string>用于选择紧急联系人</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>用于提供本地化法律服务</string>
```

### 3. 构建脚本配置

#### Archive Build Script
```bash
#!/bin/bash
# archive-build.sh

set -e

echo "🚀 开始构建生产版本..."

# 清理构建目录
xcodebuild clean -project IAAdvisor2.xcodeproj -scheme IAAdvisor2

# 归档构建
xcodebuild archive \
    -project IAAdvisor2.xcodeproj \
    -scheme IAAdvisor2 \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "./build/IAAdvisor2.xcarchive" \
    -allowProvisioningUpdates

echo "✅ 归档构建完成"

# 导出IPA
xcodebuild -exportArchive \
    -archivePath "./build/IAAdvisor2.xcarchive" \
    -exportPath "./build/" \
    -exportOptionsPlist "./ExportOptions.plist"

echo "✅ IPA导出完成"
echo "📦 构建产物位置: ./build/IA法律顾问.ipa"
```

#### ExportOptions.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>manageAppVersionAndBuildNumber</key>
    <true/>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
```

## 环境变量管理

### 1. 配置文件结构
```
Config/
├── Development.xcconfig
├── Production.xcconfig
└── Shared.xcconfig
```

#### Shared.xcconfig
```bash
// 共享配置
PRODUCT_NAME = IA法律顾问
PRODUCT_BUNDLE_IDENTIFIER = com.ialegaladvisor.app
MARKETING_VERSION = 1.0.0
CURRENT_PROJECT_VERSION = 1
IPHONEOS_DEPLOYMENT_TARGET = 15.0
SWIFT_VERSION = 5.0
```

#### Development.xcconfig
```bash
#include "Shared.xcconfig"

// 开发环境配置
CONFIGURATION_BUILD_DIR = $(BUILD_DIR)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)
GCC_PREPROCESSOR_DEFINITIONS = DEBUG=1 DEVELOPMENT=1
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG DEVELOPMENT
OTHER_SWIFT_FLAGS = -DDEBUG -DDEVELOPMENT
```

#### Production.xcconfig
```bash
#include "Shared.xcconfig"

// 生产环境配置  
CONFIGURATION_BUILD_DIR = $(BUILD_DIR)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)
GCC_PREPROCESSOR_DEFINITIONS = RELEASE=1 PRODUCTION=1
SWIFT_ACTIVE_COMPILATION_CONDITIONS = RELEASE PRODUCTION
OTHER_SWIFT_FLAGS = -DRELEASE -DPRODUCTION
SWIFT_OPTIMIZATION_LEVEL = -O
```

### 2. 代码中的环境判断
```swift
// EnvironmentConfig.swift
import Foundation

struct EnvironmentConfig {
    
    static var isProduction: Bool {
        #if PRODUCTION
        return true
        #else
        return false
        #endif
    }
    
    static var apiBaseURL: String {
        #if PRODUCTION
        return "https://api.ialegaladvisor.com"
        #else
        return "https://ia-legal-advisor.onrender.com"
        #endif
    }
    
    static var logLevel: LogLevel {
        #if PRODUCTION
        return .error
        #else
        return .debug
        #endif
    }
}

enum LogLevel {
    case debug, info, warning, error
}
```

## 签名和证书配置

### 1. 开发证书配置
```bash
# 开发证书信息
DEVELOPMENT_TEAM = YOUR_TEAM_ID
CODE_SIGN_IDENTITY = "iPhone Developer"
PROVISIONING_PROFILE_SPECIFIER = "IA Legal Advisor Development"
```

### 2. 生产证书配置
```bash
# 生产证书信息
DEVELOPMENT_TEAM = YOUR_TEAM_ID
CODE_SIGN_IDENTITY = "iPhone Distribution"
PROVISIONING_PROFILE_SPECIFIER = "IA Legal Advisor Distribution"
```

### 3. 自动签名配置
```xml
<!-- 在项目设置中启用 -->
<key>CODE_SIGN_STYLE</key>
<string>Automatic</string>
<key>DEVELOPMENT_TEAM</key>
<string>YOUR_TEAM_ID</string>
```

## 分析和监控配置

### 1. Firebase配置
```swift
// AppDelegate.swift
import Firebase
import FirebaseAnalytics
import FirebaseCrashlytics

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    #if PRODUCTION
    // 生产环境配置
    if let path = Bundle.main.path(forResource: "GoogleService-Info-Prod", ofType: "plist"),
       let options = FirebaseOptions(contentsOfFile: path) {
        FirebaseApp.configure(options: options)
    }
    #else
    // 开发环境配置
    if let path = Bundle.main.path(forResource: "GoogleService-Info-Dev", ofType: "plist"),
       let options = FirebaseOptions(contentsOfFile: path) {
        FirebaseApp.configure(options: options)
    }
    #endif
    
    return true
}
```

### 2. 崩溃报告配置
```swift
// CrashReporting.swift
import FirebaseCrashlytics

class CrashReporting {
    static func setup() {
        #if PRODUCTION
        Crashlytics.crashlytics().setUserID(getCurrentUserID())
        Crashlytics.crashlytics().setCustomValue(EnvironmentConfig.apiBaseURL, forKey: "api_base_url")
        #endif
    }
    
    static func recordError(_ error: Error) {
        #if PRODUCTION
        Crashlytics.crashlytics().record(error: error)
        #else
        print("Development Error: \(error)")
        #endif
    }
}
```

## 质量保证配置

### 1. 单元测试配置
```swift
// Test Configuration
class APIServiceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // 使用测试环境配置
        APIService.shared.setTestEnvironment()
    }
    
    func testAPIEndpoints() {
        // 测试所有API端点
    }
}
```

### 2. UI测试配置
```swift
// UI Test Configuration
class IAAdvisor2UITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
}
```

## 部署检查清单

### Pre-deployment 检查
- [ ] 确认Bundle ID正确
- [ ] 验证版本号递增
- [ ] 检查证书和描述文件
- [ ] 确认API端点为生产环境
- [ ] 移除调试代码和日志
- [ ] 验证所有权限说明
- [ ] 检查应用图标和启动画面
- [ ] 运行完整测试套件

### Post-deployment 检查
- [ ] 确认App Store Connect上传成功
- [ ] 验证TestFlight分发
- [ ] 检查崩溃报告配置
- [ ] 确认分析数据收集
- [ ] 监控API请求成功率
- [ ] 检查用户反馈

## 持续集成配置

### GitHub Actions 工作流
```yaml
# .github/workflows/ios-deploy.yml
name: iOS Deployment

on:
  push:
    tags:
      - 'v*'

jobs:
  build-and-deploy:
    runs-on: macos-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v3
    
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.0'
    
    - name: Build Archive
      run: |
        xcodebuild archive \
          -project IAAdvisor2.xcodeproj \
          -scheme IAAdvisor2 \
          -configuration Release \
          -destination "generic/platform=iOS" \
          -archivePath "./build/IAAdvisor2.xcarchive"
    
    - name: Export IPA
      run: |
        xcodebuild -exportArchive \
          -archivePath "./build/IAAdvisor2.xcarchive" \
          -exportPath "./build/" \
          -exportOptionsPlist "./ExportOptions.plist"
    
    - name: Upload to App Store Connect
      run: |
        xcrun altool --upload-app \
          --type ios \
          --file "./build/IA法律顾问.ipa" \
          --username "${{ secrets.APPLE_ID }}" \
          --password "${{ secrets.APP_SPECIFIC_PASSWORD }}"
```

## 总结

生产环境部署配置涵盖了从代码构建到应用商店发布的完整流程。关键要点：

1. **环境隔离**: 开发和生产环境完全分离
2. **安全配置**: 生产环境启用所有安全特性
3. **自动化构建**: 使用脚本和CI/CD减少人为错误
4. **质量保证**: 完整的测试和验证流程
5. **监控配置**: 生产环境监控和错误追踪

这套配置确保了应用能够安全、稳定地部署到生产环境。