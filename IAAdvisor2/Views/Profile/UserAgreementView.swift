import SwiftUI

struct UserAgreementView: View {
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
                            Text("用户服务协议")
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                                
                            Text("最后更新时间：2024年7月31日")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // 正文内容
                        VStack(alignment: .leading, spacing: 24) {
                            agreementSection(
                                title: "1. 协议范围",
                                content: """
                                本协议是您与IA法律顾问应用（以下简称"本应用"）之间的法律协议。
                                
                                使用本应用即表示您完全同意本协议的所有条款。如果您不同意本协议的任何内容，请勿使用本应用。
                                
                                本协议适用于：
                                • IA法律顾问移动应用程序
                                • 相关的在线服务和功能
                                • 未来可能推出的新功能和服务
                                """
                            )
                            
                            agreementSection(
                                title: "2. 服务说明",
                                content: """
                                本应用提供以下服务：
                                
                                • AI法律咨询：基于人工智能的法律问题解答
                                • 案件分析：专业的法律案件分析和建议
                                • 文书生成：常用法律文书的模板和生成
                                • 法律资讯：最新的法律法规和案例分享
                                • 专家咨询：付费的专业律师咨询服务
                                
                                重要提醒：本应用提供的信息仅供参考，不构成正式法律建议。
                                """
                            )
                            
                            agreementSection(
                                title: "3. 用户义务",
                                content: """
                                使用本应用时，您需要：
                                
                                • 提供真实、准确的个人信息
                                • 遵守中华人民共和国法律法规
                                • 不进行任何违法或有害活动
                                • 不传播虚假、误导性信息
                                • 尊重他人的合法权益
                                • 保护账户安全，不与他人共享
                                
                                违反上述义务可能导致账户被暂停或终止。
                                """
                            )
                            
                            agreementSection(
                                title: "4. 知识产权",
                                content: """
                                本应用的所有内容受知识产权法保护：
                                
                                • 应用程序、界面设计、商标等归本公司所有
                                • 法律条文、判例等来源于公开资料
                                • 用户生成的内容，用户保留版权
                                • AI生成的内容，根据相关法律法规处理
                                
                                未经许可，不得复制、传播或商业使用本应用内容。
                                """
                            )
                            
                            agreementSection(
                                title: "5. 免责声明",
                                content: """
                                请注意以下重要免责条款：
                                
                                • 本应用提供的信息仅供参考，不构成法律建议
                                • 我们不保证信息的完全准确性和时效性
                                • 用户应自行判断并承担使用风险
                                • 对于因使用本应用而产生的任何损失，我们不承担责任
                                • 第三方服务的问题不在我们的责任范围内
                                
                                如需正式法律建议，请咨询有资质的律师。
                                """
                            )
                            
                            agreementSection(
                                title: "6. 付费服务",
                                content: """
                                关于付费服务的条款：
                                
                                • 会员服务：提供高级功能和无限制使用
                                • 单次付费：特定服务的一次性购买
                                • 专家咨询：由专业律师提供的收费咨询
                                • 退款政策：7天无理由退款（特殊情况除外）
                                
                                所有付费均通过苹果App Store处理，遵循其相关政策。
                                """
                            )
                            
                            agreementSection(
                                title: "7. 隐私保护",
                                content: """
                                我们高度重视您的隐私：
                                
                                • 严格按照《隐私政策》处理您的信息
                                • 不会未经同意分享您的个人信息
                                • 采用加密技术保护数据传输
                                • 定期进行安全审计和更新
                                
                                详细信息请查看我们的《隐私政策》。
                                """
                            )
                            
                            agreementSection(
                                title: "8. 服务变更",
                                content: """
                                我们保留以下权利：
                                
                                • 修改、暂停或终止服务
                                • 更新应用功能和界面
                                • 调整收费标准和政策
                                • 修改本协议条款
                                
                                重大变更会提前通知用户，继续使用即表示同意变更。
                                """
                            )
                            
                            agreementSection(
                                title: "9. 争议解决",
                                content: """
                                如发生争议：
                                
                                • 首先通过友好协商解决
                                • 协商不成可申请调解
                                • 最终通过仲裁或诉讼解决
                                • 适用中华人民共和国法律
                                • 由北京市朝阳区人民法院管辖
                                
                                我们鼓励通过协商方式解决问题。
                                """
                            )
                            
                            agreementSection(
                                title: "10. 联系方式",
                                content: """
                                如需帮助或投诉，请联系我们：
                                
                                • 客服邮箱：support@ialegaladvisor.com
                                • 投诉邮箱：complaint@ialegaladvisor.com
                                • 客服电话：400-123-4567
                                • 服务时间：工作日 9:00-18:00
                                • 公司地址：中国北京市朝阳区XX路XX号
                                
                                我们承诺在2个工作日内回复您的问题。
                                """
                            )
                            
                            // 同意条款
                            VStack(spacing: 16) {
                                Text("重要提醒")
                                    .font(.headline.bold())
                                    .foregroundColor(.orange)
                                
                                Text("使用本应用即表示您已阅读、理解并同意遵守本协议的全部条款。如果您不同意本协议的任何部分，请立即停止使用本应用。")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.orange.opacity(0.2))
                                    )
                            }
                            .padding(.top)
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
    
    private func agreementSection(title: String, content: String) -> some View {
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
    UserAgreementView()
}