# Apple Developer 账号设置指南

## 概览

为了将IA法律顾问应用发布到App Store，需要注册Apple Developer账号并完成相关配置。

## 第一步：注册Apple Developer账号

### 1.1 访问官方网站
- 打开 [Apple Developer](https://developer.apple.com)
- 点击右上角"Account"或"登录"

### 1.2 选择账号类型

#### 个人开发者账号 (Individual)
- **费用**: $99/年
- **适用于**: 个人开发者或小型项目
- **优点**: 注册快速，审核简单
- **限制**: 不支持多用户管理

#### 公司/组织账号 (Organization)
- **费用**: $99/年
- **适用于**: 公司、团队开发
- **优点**: 支持多用户，品牌认知度高
- **要求**: 需要提供公司注册文件

#### 企业账号 (Enterprise)
- **费用**: $299/年
- **适用于**: 内部分发，不上架App Store
- **不适合**: 本项目不需要

### 1.3 推荐选择
对于IA法律顾问项目，建议选择**个人开发者账号**：
- 快速开始开发和发布
- 成本较低
- 后续可升级为组织账号

## 第二步：完成注册流程

### 2.1 填写基本信息
```
必需信息：
- Apple ID (建议使用专门的开发者邮箱)
- 姓名
- 地址 (必须与付款方式匹配)
- 电话号码
```

### 2.2 验证身份
- 提供身份证明文件
- 电话验证
- 邮箱验证

### 2.3 付款
- 支付$99年费
- 支持信用卡、借记卡
- 中国用户可使用银联卡

### 2.4 等待审核
- 个人账号通常24-48小时
- 公司账号可能需要1-2周

## 第三步：下载开发工具

### 3.1 Xcode
```bash
# 从Mac App Store下载最新版Xcode
# 或从Apple Developer网站下载
```

### 3.2 命令行工具
```bash
# 安装Xcode命令行工具
xcode-select --install
```

## 第四步：配置开发环境

### 4.1 添加开发团队
1. 打开Xcode
2. 选择Preferences → Accounts
3. 点击"+"添加Apple ID
4. 登录开发者账号

### 4.2 创建App ID

#### 通过Xcode自动创建 (推荐)
1. 在项目设置中
2. 选择Signing & Capabilities
3. 勾选"Automatically manage signing"
4. 选择开发团队

#### 手动创建
1. 访问 [Apple Developer Console](https://developer.apple.com/account/)
2. 选择Certificates, Identifiers & Profiles
3. 创建新的App ID：
   ```
   Description: IA Legal Advisor
   Bundle ID: com.ialegaladvisor.app
   Capabilities: 
   - App Groups (如需要)
   - Associated Domains (如需要)
   - Push Notifications (推荐)
   ```

### 4.3 生成证书

#### 开发证书 (Development Certificate)
```bash
# Xcode会自动生成，或手动创建：
1. 打开钥匙串访问
2. 证书助理 → 从证书颁发机构请求证书
3. 上传到Developer Console
```

#### 分发证书 (Distribution Certificate)
- 用于App Store发布
- 建议让Xcode自动管理

### 4.4 创建描述文件 (Provisioning Profiles)

#### 开发描述文件
- 用于设备测试
- 包含开发证书和设备列表

#### 分发描述文件
- 用于App Store发布
- 包含分发证书

## 第五步：项目配置

### 5.1 更新项目设置
```swift
// 在项目的Build Settings中设置：
DEVELOPMENT_TEAM = "你的团队ID"
PRODUCT_BUNDLE_IDENTIFIER = "com.ialegaladvisor.app"
CODE_SIGN_STYLE = "Automatic"
```

### 5.2 添加所需权限

#### Info.plist 配置
```xml
<!-- 相机权限 -->
<key>NSCameraUsageDescription</key>
<string>用于扫描法律文件和证据材料</string>

<!-- 相册权限 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>用于上传相关图片和文档</string>

<!-- 通知权限 -->
<key>NSUserNotificationsUsageDescription</key>
<string>用于接收案件更新和重要通知</string>
```

### 5.3 配置推送通知 (可选)

#### 创建推送证书
1. Developer Console → Keys
2. 创建新的Key
3. 启用Apple Push Notifications service (APNs)
4. 下载.p8文件并妥善保存

#### 在应用中配置
```swift
// AppDelegate.swift
import UserNotifications

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // 请求通知权限
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        if granted {
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }
    
    return true
}
```

## 第六步：测试和验证

### 6.1 本地测试
```bash
# 编译项目
xcodebuild -project IAAdvisor2.xcodeproj -scheme IAAdvisor2 -configuration Debug
```

### 6.2 设备测试
1. 连接iOS设备
2. 在Developer Console添加设备UDID
3. 重新生成描述文件
4. 在设备上运行应用

### 6.3 TestFlight测试
1. 创建Archive构建
2. 上传到App Store Connect
3. 创建TestFlight版本
4. 邀请测试用户

## 第七步：常见问题解决

### 7.1 签名错误
```
错误: "No profiles for 'com.ialegaladvisor.app' were found"
解决: 确保Bundle ID正确，重新生成描述文件
```

### 7.2 证书过期
```
错误: "Certificate has expired"
解决: 在Developer Console续期或重新创建证书
```

### 7.3 设备不受信任
```
错误: "Untrusted Developer"
解决: 设置 → 通用 → VPN与设备管理 → 信任开发者
```

## 第八步：年度维护

### 8.1 账号续费
- 每年$99自动续费
- 提前收到邮件提醒
- 可在Developer Console管理

### 8.2 证书更新
- 开发证书有效期1年
- 分发证书有效期1年
- 推送证书需要定期更新

### 8.3 应用更新
- 定期发布应用更新
- 修复安全漏洞
- 适配新iOS版本

## 实际操作清单

### 立即需要完成的任务
- [ ] 注册Apple Developer账号 ($99)
- [ ] 下载并安装最新版Xcode
- [ ] 在项目中配置开发团队
- [ ] 创建App ID: com.ialegaladvisor.app
- [ ] 测试应用在真机上运行

### 发布前需要完成的任务
- [ ] 创建分发证书
- [ ] 配置生产环境描述文件
- [ ] 设置推送通知服务
- [ ] 准备应用元数据和截图
- [ ] 创建App Store Connect记录

## 联系方式和支持

### Apple开发者支持
- 技术支持：https://developer.apple.com/support/
- 论坛：https://developer.apple.com/forums/
- 文档：https://developer.apple.com/documentation/

### 紧急情况
如果遇到账号问题或技术难题：
1. 查阅官方文档
2. 搜索开发者论坛
3. 提交技术支持票据
4. 考虑咨询专业iOS开发顾问

## 总结

Apple Developer账号是iOS应用发布的必要条件。建议：
1. 优先注册个人开发者账号快速开始
2. 使用Xcode自动管理签名简化配置
3. 定期备份证书和密钥文件
4. 关注Apple的政策更新和新功能

完成账号设置后，就可以开始配置App Store Connect准备应用发布了。