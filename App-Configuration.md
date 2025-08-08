# IA法律顾问 应用配置总结

## 应用基本信息

### Bundle信息
- **Bundle ID**: `com.ialegaladvisor.app`
- **应用名称**: IA法律顾问
- **版本号**: 1.0.0
- **构建号**: 1
- **开发区域**: zh_CN (中国简体)
- **应用分类**: 商务类应用

### 支持的iOS版本
- **最低支持版本**: iOS 15.0
- **目标版本**: iOS 17.0+

### 设备支持
- **iPhone**: ✅ 支持所有现代iPhone设备
- **iPad**: ✅ 兼容iPad，支持横竖屏
- **方向支持**: 
  - iPhone: 仅竖屏
  - iPad: 支持所有方向

## 网络权限配置

### App Transport Security (ATS)
- **任意加载**: 允许 (开发阶段)
- **异常域名**: ia-legal-advisor.onrender.com
- **HTTPS要求**: 生产环境强制HTTPS
- **TLS版本**: 最低TLSv1.2

## 应用图标

### 配置状态
- ✅ 启动画面设计完成
- ✅ 图标配置文件已设置
- ⏳ 需要制作PNG图标文件

### 需要的图标尺寸
- 20x20@2x (40x40) - 通知图标
- 20x20@3x (60x60) - 通知图标
- 29x29@2x (58x58) - 设置图标
- 29x29@3x (87x87) - 设置图标  
- 40x40@2x (80x80) - Spotlight
- 40x40@3x (120x120) - Spotlight
- 60x60@2x (120x120) - 主屏幕图标
- 60x60@3x (180x180) - 主屏幕图标
- 1024x1024 - App Store

## 启动画面

### 设计特点
- 法律天平主图标
- 蓝紫渐变背景
- AI元素装饰
- 分阶段动画效果
- 自动过渡到登录/主界面

### 动画时序
1. 基础缩放透明度 (0-0.8s)
2. Logo旋转效果 (0.3-1.0s)
3. AI圆点显示 (0.6-1.2s)
4. 文字上滑 (0.8-1.4s)
5. 状态切换 (2.5s)

## 版本管理

### 常量配置
```swift
struct AppConstants.App {
    static let name = "IA法律顾问"
    static let version = "1.0.0"
    static let buildNumber = "1" 
    static let company = "IA Legal Advisor Team"
    // ... 其他配置
}
```

### 版本显示位置
- ✅ 启动画面
- ✅ 关于页面
- ✅ 从Bundle自动获取

## 隐私和权限

### 当前权限
- 网络访问权限 ✅
- HTTP例外域名 ✅

### 待添加权限 (按需)
- 相机权限 (文档扫描)
- 相册权限 (图片上传)
- 推送通知权限

## 应用商店信息

### 基本信息
- **类别**: 商务
- **版权**: Copyright © 2024 IA法律顾问. All rights reserved.
- **支持邮箱**: support@ialegaladvisor.com
- **隐私政策**: https://ialegaladvisor.com/privacy
- **服务条款**: https://ialegaladvisor.com/terms

### 待完成任务
- [ ] 制作实际PNG图标文件
- [ ] 创建应用截图和预览视频
- [ ] 编写应用描述和关键词
- [ ] 设置应用定价和内购项目
- [ ] 完善隐私政策页面

## 构建配置

### 开发环境
- Xcode 15.0+
- Swift 5.9+
- iOS Deployment Target: 15.0

### 生产发布清单
1. ✅ Bundle ID配置
2. ✅ 版本信息设置
3. ✅ 应用图标配置
4. ✅ 启动画面优化
5. ⏳ 代码签名证书
6. ⏳ Provisioning Profile
7. ⏳ Archive构建测试

## 注意事项

1. **Bundle ID**: 确保在Apple Developer账号中注册
2. **版本控制**: 每次发布需递增版本号
3. **图标制作**: 遵循Apple设计规范
4. **网络安全**: 生产环境移除ATS例外
5. **隐私合规**: 完善隐私政策和用户协议