import SwiftUI

struct PaymentTermsView: View {
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
                            Text("支付服务条款")
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                                
                            Text("最后更新时间：2024年7月31日")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // 正文内容
                        VStack(alignment: .leading, spacing: 24) {
                            paymentSection(
                                title: "1. 服务范围",
                                content: """
                                本支付条款适用于以下付费服务：
                                
                                • 会员服务：标准版、专业版、企业版会员
                                • 单次服务：案件分析、文书生成、专家咨询
                                • 增值服务：额外咨询次数、案件创建名额
                                • 专家服务：一对一律师咨询、法律培训
                                
                                所有付费服务均通过Apple App Store支付系统处理。
                                """
                            )
                            
                            paymentSection(
                                title: "2. 价格政策",
                                content: """
                                • 标准版会员：¥29/月，提供基础专业服务
                                • 专业版会员：¥99/月，提供全功能无限制服务
                                • 企业版会员：¥299/月，提供团队协作和定制服务
                                • 单次案件分析：¥19.9/次
                                • 专家律师咨询：¥199.9/小时
                                
                                价格可能根据市场情况调整，会提前30天通知用户。
                                """
                            )
                            
                            paymentSection(
                                title: "3. 支付方式",
                                content: """
                                支持的支付方式：
                                
                                • Apple Pay（推荐）
                                • 信用卡/借记卡
                                • 支付宝（即将支持）
                                • 微信支付（即将支持）
                                
                                所有支付均采用SSL加密技术，确保交易安全。
                                支付过程遵循Apple App Store的安全标准。
                                """
                            )
                            
                            paymentSection(
                                title: "4. 会员服务",
                                content: """
                                会员服务说明：
                                
                                • 自动续费：订阅会在到期前24小时自动续费
                                • 管理订阅：可在iOS设置-Apple ID-订阅中管理
                                • 服务生效：支付成功后立即生效
                                • 服务期限：按月计算，不足一个月按比例计算
                                
                                取消订阅不影响当前计费周期的服务使用。
                                """
                            )
                            
                            paymentSection(
                                title: "5. 退款政策",
                                content: """
                                我们提供以下退款保障：
                                
                                • 7天无理由退款：首次购买后7天内可申请全额退款
                                • 服务故障退款：因技术问题无法使用时可申请退款
                                • 重复付款退款：系统错误导致的重复扣费可申请退款
                                • 未成年消费退款：未成年人未经监护人同意的消费可申请退款
                                
                                退款申请请联系Apple客服或我们的客服团队。
                                """
                            )
                            
                            paymentSection(
                                title: "6. 发票服务",
                                content: """
                                发票相关说明：
                                
                                • 电子发票：所有付费服务可开具电子发票
                                • 申请方式：通过应用内客服申请或发送邮件
                                • 发票内容：软件服务费、技术服务费
                                • 发票类型：增值税普通发票或专用发票
                                • 处理时间：申请后3-5个工作日内开具
                                
                                请保留好支付凭证以便申请发票。
                                """
                            )
                            
                            paymentSection(
                                title: "7. 争议处理",
                                content: """
                                支付争议解决流程：
                                
                                • 第一步：联系我们的客服团队
                                • 第二步：提供相关支付凭证和问题描述
                                • 第三步：我们在2个工作日内调查并回复
                                • 第四步：如不满意可向Apple客服申诉
                                • 第五步：最终通过法律途径解决
                                
                                我们承诺公平、及时处理所有支付争议。
                                """
                            )
                            
                            paymentSection(
                                title: "8. 安全保障",
                                content: """
                                我们采取以下措施保障支付安全：
                                
                                • PCI DSS认证：符合支付卡行业数据安全标准
                                • SSL加密：所有支付数据加密传输
                                • 风险监控：实时监控异常支付行为
                                • 安全审计：定期进行安全检查和更新
                                • 隐私保护：不存储完整的支付卡信息
                                
                                如发现可疑交易，请立即联系我们。
                                """
                            )
                            
                            paymentSection(
                                title: "9. 服务变更",
                                content: """
                                服务变更相关条款：
                                
                                • 价格调整：提前30天通知，现有用户享受过渡期优惠
                                • 功能升级：免费为用户升级新功能
                                • 服务停止：提前90天通知，协助用户数据迁移
                                • 条款修改：重大修改会通过邮件和应用内通知
                                
                                继续使用服务视为同意变更后的条款。
                                """
                            )
                            
                            paymentSection(
                                title: "10. 联系我们",
                                content: """
                                支付相关问题请联系：
                                
                                • 客服邮箱：billing@ialegaladvisor.com
                                • 退款申请：refund@ialegaladvisor.com
                                • 发票申请：invoice@ialegaladvisor.com
                                • 客服电话：400-123-4567
                                • 服务时间：工作日 9:00-18:00
                                
                                我们承诺在24小时内回复支付相关问题。
                                """
                            )
                            
                            // 重要提醒
                            VStack(spacing: 16) {
                                Text("重要提醒")
                                    .font(.headline.bold())
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("• 所有付费服务均不可转让给他人")
                                    Text("• 退款申请需在规定时间内提出")
                                    Text("• 虚假申请退款可能导致账户被封")
                                    Text("• 保留支付凭证以备查询")
                                }
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.green.opacity(0.2))
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
    
    private func paymentSection(title: String, content: String) -> some View {
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
    PaymentTermsView()
}