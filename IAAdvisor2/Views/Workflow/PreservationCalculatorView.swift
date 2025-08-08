import SwiftUI

/// 保全计算器视图
struct PreservationCalculatorView: View {
    @State private var preservationValue: String = ""
    @State private var securityRatio: Double = 0.3
    @State private var showingDetailCalculator = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("保全费用估算")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                // 保全标的输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("保全标的价值（元）")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    TextField("请输入金额", text: $preservationValue)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // 担保比例调节
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("担保比例")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(Int(securityRatio * 100))%")
                            .font(.subheadline.bold())
                            .foregroundColor(AppTheme.accentColor)
                    }
                    
                    Slider(value: $securityRatio, in: 0.2...0.5, step: 0.05)
                        .accentColor(AppTheme.accentColor)
                    
                    HStack {
                        Text("20%")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Text("50%")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                // 费用预览
                if let value = Double(preservationValue), value > 0 {
                    quickCostPreview(preservationValue: value)
                }
                
                // 详细计算按钮
                Button("详细费用计算") {
                    showingDetailCalculator = true
                }
                .buttonStyle(WorkflowSecondaryButtonStyle())
            }
        }
        .padding()
        .liquidGlass()
        .sheet(isPresented: $showingDetailCalculator) {
            PreservationCalculatorDetailView()
        }
    }
    
    private func quickCostPreview(preservationValue: Double) -> some View {
        let securityDeposit = preservationValue * securityRatio
        let applicationFee = calculateApplicationFee(preservationValue)
        let totalCost = securityDeposit + applicationFee
        
        return VStack(spacing: 8) {
            Text("费用预览")
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 4) {
                QuickCostRow(title: "保全标的", amount: preservationValue, highlight: false)
                QuickCostRow(title: "担保金额", amount: securityDeposit, highlight: false)
                QuickCostRow(title: "申请费", amount: applicationFee, highlight: false)
                
                Divider().background(Color.white.opacity(0.3))
                
                QuickCostRow(title: "预计总费用", amount: totalCost, highlight: true)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
    
    private func calculateApplicationFee(_ value: Double) -> Double {
        let fee = value * 0.005
        return min(max(fee, 500), 5000)
    }
}

struct QuickCostRow: View {
    let title: String
    let amount: Double
    let highlight: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(highlight ? .subheadline.bold() : .caption)
                .foregroundColor(highlight ? .white : .white.opacity(0.8))
            
            Spacer()
            
            Text("¥\(formatAmount(amount))")
                .font(highlight ? .subheadline.bold() : .caption)
                .foregroundColor(highlight ? AppTheme.accentColor : .white)
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        if amount >= 10000 {
            return String(format: "%.1f万", amount / 10000)
        } else {
            return "\(Int(amount))"
        }
    }
}

#Preview {
    PreservationCalculatorView()
}