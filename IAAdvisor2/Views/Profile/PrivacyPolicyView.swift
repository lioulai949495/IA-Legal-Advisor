import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 标题
                        VStack(alignment: .leading, spacing: 12) {
                            Text("隐私政策")
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                            
                            Text("最后更新时间：2024年7月31日")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // 正文内容
                        VStack(alignment: .leading, spacing: 24) {
                            privacySection(
                                title: "1. 信息收集",
                                content: """
                                我们收集以下类型的信息：
                                
                                • 账户信息：手机号码、邮箱地址等注册信息
                                • 使用数据：您使用应用的功能记录、咨询内容
                                • 设备信息：设备型号、操作系统版本、应用版本
                                • 日志信息：应用崩溃报告、性能数据
                                
                                所有信息收集均遵循最小化原则，仅收集提供服务所必需的信息。
                                """
                            )
                            
                            privacySection(
                                title: "2. 信息使用",
                                content: """
                                我们使用收集的信息用于：
                                
                                • 提供法律咨询和案件分析服务
                                • 改进产品功能和用户体验
                                • 发送服务通知和产品更新
                                • 确保应用安全和防止欺诈
                                • 遵守法律法规要求
                                
                                我们不会将您的个人信息用于其他商业目的。
                                """
                            )
                            
                            privacySection(
                                title: "3. 信息共享",
                                content: """
                                我们严格保护您的隐私，不会向第三方出售、交易或转让您的个人信息，除非：
                                
                                • 获得您的明确同意
                                • 法律法规要求或政府部门要求
                                • 为保护公司或用户的合法权益
                                • 为提供服务而必须的第三方服务商（如支付平台）
                                
                                与第三方共享时，我们会确保其遵守相同的隐私保护标准。
                                """
                            )
                            
                            privacySection(
                                title: "4. 数据安全",
                                content: """
                                我们采取以下措施保护您的信息安全：
                                
                                • 数据传输加密（TLS/SSL）
                                • 数据存储加密
                                • 访问权限控制
                                • 定期安全审计
                                • 员工隐私培训
                                
                                尽管我们努力保护您的信息，但无法保证绝对安全。
                                """
                            )
                            
                            privacySection(
                                title: "5. 数据存储",
                                content: """
                                • 数据存储位置：中国境内的安全服务器
                                • 存储期限：账户注销后30天内删除
                                • 备份策略：定期备份以防数据丢失
                                • 跨境传输：如需跨境，将遵循相关法律法规
                                """
                            )
                            
                            privacySection(
                                title: "6. 您的权利",
                                content: """
                                您对个人信息享有以下权利：
                                
                                • 访问权：查看我们持有的您的信息
                                • 更正权：要求更正不准确的信息
                                • 删除权：要求删除您的个人信息
                                • 限制处理权：限制我们处理您的信息
                                • 数据迁移权：要求将数据转移给其他服务商
                                
                                如需行使上述权利，请联系我们的客服。
                                """
                            )
                            
                            privacySection(
                                title: "7. Cookie和追踪技术",
                                content: """
                                我们可能使用以下技术：
                                
                                • 必要Cookie：维持应用基本功能
                                • 分析Cookie：了解用户使用习惯
                                • 推送标识符：发送通知消息
                                
                                您可以在设备设置中管理这些权限。
                                """
                            )
                            
                            privacySection(
                                title: "8. 未成年人保护",
                                content: """
                                我们不会主动收集未满18周岁未成年人的个人信息。如发现无意中收集了未成年人信息，我们将立即删除。
                                
                                如果您是未成年人的监护人，发现我们收集了该未成年人的信息，请联系我们。
                                """
                            )
                            
                            privacySection(
                                title: "9. 政策更新",
                                content: """
                                我们可能会定期更新本隐私政策。重大变更时，我们会通过应用内通知、邮件等方式告知您。
                                
                                继续使用我们的服务即表示您同意更新后的隐私政策。
                                """
                            )
                            
                            privacySection(
                                title: "10. 联系我们",
                                content: """
                                如果您对本隐私政策有任何疑问或建议，请通过以下方式联系我们：
                                
                                • 邮箱：privacy@ialegaladvisor.com
                                • 电话：400-123-4567
                                • 地址：中国北京市朝阳区XX路XX号
                                
                                我们将在收到您的意见后15个工作日内回复。
                                """
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.bold())
                .foregroundColor(AppTheme.accentColor)
            
            Text(content)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

#Preview {
    PrivacyPolicyView()
}