import SwiftUI

/// 诉前保全详情视图
struct PreTrialPreservationView: View {
    let step: EnhancedWorkflowStep
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedAssetType: PreTrialPreservation.AssetType = .bankAccount
    @State private var estimatedValue: String = ""
    @State private var showingCalculator = false
    @State private var showingProcedureDetail = false
    @State private var selectedProcedure: PreservationProcedure?
    
    // 模拟保全配置
    private let preservationConfig = PreTrialPreservation(
        targetAssets: [.bankAccount, .realEstate, .vehicles],
        estimatedValue: 500000,
        securityDeposit: 150000,
        validityPeriod: 365,
        applicationFee: 2000,
        procedures: [
            PreservationProcedure(
                id: "evaluation",
                title: "财产评估",
                description: "评估需要保全的财产价值",
                requiredDocuments: ["财产证明", "评估报告"],
                estimatedDays: 2,
                cost: 5000
            ),
            PreservationProcedure(
                id: "application",
                title: "提交申请",
                description: "向法院提交保全申请书",
                requiredDocuments: ["保全申请书", "担保函"],
                estimatedDays: 1,
                cost: 2000
            ),
            PreservationProcedure(
                id: "execution",
                title: "执行保全",
                description: "法院执行保全措施",
                requiredDocuments: [],
                estimatedDays: 3,
                cost: 0
            )
        ]
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 保全概述
                    preservationOverview
                    
                    // 保全类型选择
                    assetTypeSelection
                    
                    // 费用计算器
                    costCalculator
                    
                    // 保全流程
                    preservationProcedures
                    
                    // 法律风险提示
                    riskWarnings
                    
                    // 操作按钮
                    actionButtons
                }
                .padding()
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("诉前财产保全")
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
        .sheet(isPresented: $showingCalculator) {
            PreservationCalculatorDetailView()
        }
        .sheet(isPresented: $showingProcedureDetail) {
            if let procedure = selectedProcedure {
                PreservationProcedureDetailView(procedure: procedure)
            }
        }
    }
    
    // MARK: - 视图组件
    
    private var preservationOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("诉前财产保全")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("防止对方转移财产，保护您的合法权益")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // 关键信息
            VStack(spacing: 12) {
                PreservationInfoRow(title: "申请期限", value: "起诉前申请", icon: "clock", color: .blue)
                PreservationInfoRow(title: "执行期限", value: "申请后15日内起诉", icon: "calendar", color: .red)
                PreservationInfoRow(title: "有效期", value: "\(preservationConfig.validityPeriod)天", icon: "timer", color: .green)
                PreservationInfoRow(title: "担保金额", value: "保全标的30%左右", icon: "creditcard", color: .orange)
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private var assetTypeSelection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("保全财产类型")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(PreTrialPreservation.AssetType.allCases, id: \.self) { assetType in
                    AssetTypeCard(
                        assetType: assetType,
                        isSelected: selectedAssetType == assetType,
                        onSelect: {
                            selectedAssetType = assetType
                        }
                    )
                }
            }
            
            // 选中类型的详细说明
            AssetTypeDetailView(assetType: selectedAssetType)
        }
    }
    
    private var costCalculator: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("费用计算")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("详细计算器") {
                    showingCalculator = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("保全标的价值")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    TextField("请输入金额", text: $estimatedValue)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 150)
                }
                
                if let value = Double(estimatedValue), value > 0 {
                    CostBreakdownView(preservationValue: value)
                }
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private var preservationProcedures: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("保全流程")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(preservationConfig.procedures.indices, id: \.self) { index in
                    let procedure = preservationConfig.procedures[index]
                    let isLast = index == preservationConfig.procedures.count - 1
                    
                    VStack(spacing: 0) {
                        Button {
                            selectedProcedure = procedure
                            showingProcedureDetail = true
                        } label: {
                            ProcedureStepView(
                                procedure: procedure,
                                stepNumber: index + 1
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if !isLast {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 2, height: 20)
                                .offset(x: -120)
                        }
                    }
                }
            }
        }
    }
    
    private var riskWarnings: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                Text("风险提示")
                    .font(.title3.bold())
                    .foregroundColor(.red)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                RiskWarningItem(
                    icon: "dollarsign.circle",
                    title: "错误保全责任",
                    description: "如保全申请有误，需赔偿对方因保全造成的损失",
                    severity: .critical
                )
                
                RiskWarningItem(
                    icon: "clock.badge.exclamationmark",
                    title: "起诉期限要求",
                    description: "保全后15日内必须起诉，否则保全措施失效",
                    severity: .critical
                )
                
                RiskWarningItem(
                    icon: "creditcard.trianglebadge.exclamationmark",
                    title: "担保风险",
                    description: "需要提供相应担保，担保不足可能影响保全效果",
                    severity: .warning
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button("申请诉前保全") {
                // 处理申请逻辑
                dismiss()
            }
            .buttonStyle(WorkflowPrimaryButtonStyle())
            
            Button("暂不申请") {
                dismiss()
            }
            .buttonStyle(WorkflowSecondaryButtonStyle())
        }
    }
}

// MARK: - 辅助视图组件

struct PreservationInfoRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
    }
}

struct AssetTypeCard: View {
    let assetType: PreTrialPreservation.AssetType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Image(systemName: assetType.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? AppTheme.accentColor : .white.opacity(0.7))
                
                Text(assetType.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(isSelected ? AppTheme.accentColor : .white.opacity(0.8))
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.accentColor : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct AssetTypeDetailView: View {
    let assetType: PreTrialPreservation.AssetType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(assetType.rawValue)保全说明")
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            Text(getAssetDescription())
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            Text("所需材料: \(getRequiredDocuments())")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func getAssetDescription() -> String {
        switch assetType {
        case .bankAccount:
            return "冻结对方银行账户，防止资金转移。需要提供账户信息或线索。"
        case .realEstate:
            return "查封对方房产，禁止转让或抵押。需要提供房产证明或产权信息。"
        case .vehicles:
            return "查封对方车辆，禁止过户。需要提供车辆登记信息。"
        case .stocks:
            return "冻结对方股权或股票，禁止转让。需要提供股权证明。"
        case .other:
            return "根据具体财产类型确定保全措施。"
        }
    }
    
    private func getRequiredDocuments() -> String {
        switch assetType {
        case .bankAccount:
            return "银行流水、账户信息"
        case .realEstate:
            return "房产证、产权证明"
        case .vehicles:
            return "行驶证、登记证书"
        case .stocks:
            return "股权证书、持股证明"
        case .other:
            return "相关财产证明"
        }
    }
}

struct CostBreakdownView: View {
    let preservationValue: Double
    
    private var securityDeposit: Double {
        preservationValue * 0.3 // 30%担保
    }
    
    private var applicationFee: Double {
        min(max(preservationValue * 0.005, 500), 5000) // 0.5%, 最低500最高5000
    }
    
    private var totalCost: Double {
        securityDeposit + applicationFee
    }
    
    var body: some View {
        VStack(spacing: 8) {
            CostRow(title: "保全标的", amount: preservationValue, isTotal: false)
            CostRow(title: "担保金额", amount: securityDeposit, isTotal: false)
            CostRow(title: "申请费", amount: applicationFee, isTotal: false)
            
            Divider().background(Color.white.opacity(0.3))
            
            CostRow(title: "预计总费用", amount: totalCost, isTotal: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

struct CostRow: View {
    let title: String
    let amount: Double
    let isTotal: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(isTotal ? .subheadline.bold() : .caption)
                .foregroundColor(isTotal ? .white : .white.opacity(0.8))
            
            Spacer()
            
            Text("¥\(Int(amount))")
                .font(isTotal ? .subheadline.bold() : .caption)
                .foregroundColor(isTotal ? AppTheme.accentColor : .white)
        }
    }
}

struct ProcedureStepView: View {
    let procedure: PreservationProcedure
    let stepNumber: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 步骤编号
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                Text("\(stepNumber)")
                    .font(.headline.bold())
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(procedure.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(procedure.estimatedDays)天")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.blue.opacity(0.3)))
                        .foregroundColor(.blue)
                    
                    if procedure.cost > 0 {
                        Text("¥\(Int(procedure.cost))")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.green.opacity(0.3)))
                            .foregroundColor(.green)
                    }
                }
                
                Text(procedure.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                if !procedure.requiredDocuments.isEmpty {
                    HStack {
                        Image(systemName: "doc.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("需要: \(procedure.requiredDocuments.joined(separator: "、"))")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

struct RiskWarningItem: View {
    let icon: String
    let title: String
    let description: String
    let severity: LegalNotice.NoticeSeverity
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(severity.color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

// MARK: - 保全计算器详情视图

struct PreservationCalculatorDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var preservationValue: String = ""
    @State private var securityRatio: Double = 0.3
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("保全费用计算器")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("保全标的价值")
                                .foregroundColor(.white)
                            
                            TextField("请输入金额", text: $preservationValue)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("担保比例: \(Int(securityRatio * 100))%")
                                .foregroundColor(.white.opacity(0.8))
                            
                            Slider(value: $securityRatio, in: 0.2...0.5, step: 0.05)
                                .accentColor(AppTheme.accentColor)
                        }
                        
                        if let value = Double(preservationValue), value > 0 {
                            DetailedCostBreakdownView(
                                preservationValue: value,
                                securityRatio: securityRatio
                            )
                        }
                    }
                    .padding()
                    .liquidGlass()
                    
                    // 费用说明
                    PreservationFeeExplanationView()
                }
                .padding()
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("费用计算")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct DetailedCostBreakdownView: View {
    let preservationValue: Double
    let securityRatio: Double
    
    var body: some View {
        VStack(spacing: 16) {
            Text("费用明细")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                DetailedCostRow(title: "保全标的", amount: preservationValue, description: "需要保全的财产价值")
                DetailedCostRow(title: "担保金额", amount: preservationValue * securityRatio, description: "向法院提供的担保")
                DetailedCostRow(title: "申请费", amount: calculateApplicationFee(), description: "法院收取的申请费")
                DetailedCostRow(title: "律师费", amount: calculateLawyerFee(), description: "律师代理费用（可选）")
                DetailedCostRow(title: "其他费用", amount: 1000, description: "公证、评估等费用")
                
                Divider().background(Color.white.opacity(0.3))
                
                DetailedCostRow(
                    title: "总计费用",
                    amount: preservationValue * securityRatio + calculateApplicationFee() + calculateLawyerFee() + 1000,
                    description: "所有费用合计",
                    isTotal: true
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }
    
    private func calculateApplicationFee() -> Double {
        let fee = preservationValue * 0.005
        return min(max(fee, 500), 5000)
    }
    
    private func calculateLawyerFee() -> Double {
        let fee = preservationValue * 0.02
        return min(max(fee, 2000), 20000)
    }
}

struct DetailedCostRow: View {
    let title: String
    let amount: Double
    let description: String
    let isTotal: Bool
    
    init(title: String, amount: Double, description: String, isTotal: Bool = false) {
        self.title = title
        self.amount = amount
        self.description = description
        self.isTotal = isTotal
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(isTotal ? .subheadline.bold() : .subheadline)
                    .foregroundColor(isTotal ? .white : .white.opacity(0.9))
                
                Spacer()
                
                Text("¥\(Int(amount))")
                    .font(isTotal ? .headline.bold() : .subheadline)
                    .foregroundColor(isTotal ? AppTheme.accentColor : .white)
            }
            
            HStack {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
            }
        }
    }
}

struct PreservationFeeExplanationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("费用说明")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                FeeExplanationItem(
                    title: "担保金额",
                    explanation: "根据《民事诉讼法》规定，申请人需要提供担保。担保金额一般为保全标的的20%-50%。"
                )
                
                FeeExplanationItem(
                    title: "申请费",
                    explanation: "法院收取的财产保全申请费，按保全金额的0.5%收取，最低500元，最高5000元。"
                )
                
                FeeExplanationItem(
                    title: "律师费",
                    explanation: "委托律师代理的费用，根据案件复杂程度和保全标的确定，一般为保全金额的1%-3%。"
                )
                
                FeeExplanationItem(
                    title: "其他费用",
                    explanation: "包括财产评估费、公证费、送达费等，根据实际发生的费用收取。"
                )
            }
        }
        .padding()
        .liquidGlass()
    }
}

struct FeeExplanationItem: View {
    let title: String
    let explanation: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            Text(explanation)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - 保全程序详情视图

struct PreservationProcedureDetailView: View {
    let procedure: PreservationProcedure
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 程序概述
                    VStack(alignment: .leading, spacing: 12) {
                        Text(procedure.title)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text(procedure.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack {
                            InfoBadge(title: "预计时间", value: "\(procedure.estimatedDays)天", color: .blue)
                            
                            if procedure.cost > 0 {
                                InfoBadge(title: "费用", value: "¥\(Int(procedure.cost))", color: .green)
                            }
                        }
                    }
                    .padding()
                    .liquidGlass()
                    
                    // 所需文档
                    if !procedure.requiredDocuments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("所需文档")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            
                            ForEach(procedure.requiredDocuments.indices, id: \.self) { index in
                                HStack {
                                    Image(systemName: "doc.fill")
                                        .foregroundColor(.blue)
                                    
                                    Text(procedure.requiredDocuments[index])
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.05))
                                )
                            }
                        }
                    }
                    
                    // 详细步骤
                    getDetailedSteps()
                }
                .padding()
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("程序详情")
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
    
    @ViewBuilder
    private func getDetailedSteps() -> some View {
        switch procedure.id {
        case "evaluation":
            PropertyEvaluationStepsView()
        case "application":
            ApplicationSubmissionStepsView()
        case "execution":
            PreservationExecutionStepsView()
        default:
            EmptyView()
        }
    }
}

struct InfoBadge: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.caption.bold())
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - 详细步骤视图

struct PropertyEvaluationStepsView: View {
    var body: some View {
        DetailedStepsContainer(title: "财产评估步骤") {
            DetailedStepItem(
                step: 1,
                title: "收集财产信息",
                description: "收集需要保全的财产相关信息和证明材料"
            )
            
            DetailedStepItem(
                step: 2,
                title: "选择评估机构",
                description: "选择有资质的评估机构进行财产价值评估"
            )
            
            DetailedStepItem(
                step: 3,
                title: "现场评估",
                description: "配合评估师进行现场勘查和价值评估"
            )
            
            DetailedStepItem(
                step: 4,
                title: "出具评估报告",
                description: "评估机构出具正式的财产价值评估报告"
            )
        }
    }
}

struct ApplicationSubmissionStepsView: View {
    var body: some View {
        DetailedStepsContainer(title: "申请提交步骤") {
            DetailedStepItem(
                step: 1,
                title: "准备申请材料",
                description: "起草保全申请书，准备相关证明材料"
            )
            
            DetailedStepItem(
                step: 2,
                title: "提供担保",
                description: "向法院提供担保金或担保函"
            )
            
            DetailedStepItem(
                step: 3,
                title: "提交申请",
                description: "向有管辖权的法院提交保全申请"
            )
            
            DetailedStepItem(
                step: 4,
                title: "等待审查",
                description: "法院审查申请材料，决定是否准予保全"
            )
        }
    }
}

struct PreservationExecutionStepsView: View {
    var body: some View {
        DetailedStepsContainer(title: "保全执行步骤") {
            DetailedStepItem(
                step: 1,
                title: "法院裁定",
                description: "法院作出准予保全的裁定书"
            )
            
            DetailedStepItem(
                step: 2,
                title: "执行保全",
                description: "法院执行局执行财产保全措施"
            )
            
            DetailedStepItem(
                step: 3,
                title: "送达裁定",
                description: "向当事人送达财产保全裁定书"
            )
            
            DetailedStepItem(
                step: 4,
                title: "监督执行",
                description: "监督保全措施的执行情况"
            )
        }
    }
}

struct DetailedStepsContainer<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                content
            }
        }
        .padding()
        .liquidGlass()
    }
}

struct DetailedStepItem: View {
    let step: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: 32, height: 32)
                
                Text("\(step)")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

#Preview {
    PreTrialPreservationView(
        step: EnhancedWorkflowStep(
            id: "preservation-test",
            title: "诉前财产保全",
            description: "测试步骤",
            status: .pending,
            date: nil,
            estimatedDays: 3,
            stepType: .preTrialPreservation,
            actionGuide: ActionGuide(title: "", steps: [], tips: [], warnings: [], estimatedTime: "", difficulty: .medium),
            requiredDocuments: [],
            legalNotices: []
        )
    )
}