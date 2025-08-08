import SwiftUI

/// 公证信息视图
struct NotarizationInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedNotarizationType: NotarizationType?
    @State private var selectedNotaryOffice: NotaryOffice?
    @State private var showingAppointment = false
    
    // 模拟公证信息
    private let notarizationInfo = NotarizationInfo(
        notaryOffices: [
            NotaryOffice(
                id: "1",
                name: "市第一公证处",
                address: "市中心区法院路123号",
                phone: "0755-12345678",
                workingHours: "周一至周五 9:00-17:00",
                appointmentUrl: "https://notary1.example.com",
                rating: 4.8,
                distance: 2.5
            ),
            NotaryOffice(
                id: "2",
                name: "市第二公证处",
                address: "高新区科技大道456号",
                phone: "0755-87654321",
                workingHours: "周一至周六 8:30-17:30",
                appointmentUrl: "https://notary2.example.com",
                rating: 4.6,
                distance: 3.8
            ),
            NotaryOffice(
                id: "3",
                name: "市第三公证处",
                address: "南山区深南大道789号",
                phone: "0755-11223344",
                workingHours: "周一至周五 9:00-18:00",
                appointmentUrl: nil,
                rating: 4.5,
                distance: 5.2
            )
        ],
        notarizationTypes: [
            NotarizationType(
                id: "1",
                name: "合同公证",
                description: "对签署的合同进行公证，确认合同真实性",
                baseFee: 200,
                additionalFees: [
                    NotarizationType.FeeItem(description: "复印费", amount: 2, unit: "/页"),
                    NotarizationType.FeeItem(description: "翻译费", amount: 50, unit: "/页")
                ]
            ),
            NotarizationType(
                id: "2",
                name: "文书公证",
                description: "对各类文书、证明材料进行公证",
                baseFee: 150,
                additionalFees: [
                    NotarizationType.FeeItem(description: "副本费", amount: 10, unit: "/份")
                ]
            ),
            NotarizationType(
                id: "3",
                name: "电子证据公证",
                description: "对网页、聊天记录等电子证据进行保全公证",
                baseFee: 500,
                additionalFees: [
                    NotarizationType.FeeItem(description: "存储费", amount: 100, unit: "/年"),
                    NotarizationType.FeeItem(description: "光盘刻录费", amount: 50, unit: "/张")
                ]
            )
        ],
        estimatedCost: CostRange(min: 150, max: 800),
        requiredDocuments: ["身份证", "相关证明材料", "委托书（如需代理）"],
        processingTime: "1-5个工作日",
        appointmentRequired: true
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 公证概述
                    notarizationOverview
                    
                    // 公证类型
                    notarizationTypesSection
                    
                    // 推荐公证处
                    notaryOfficesSection
                    
                    // 办理指南
                    processingGuide
                    
                    // 费用说明
                    costExplanation
                }
                .padding()
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("公证信息")
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
        .sheet(isPresented: $showingAppointment) {
            if let office = selectedNotaryOffice {
                NotaryAppointmentView(office: office)
            }
        }
    }
    
    // MARK: - 视图组件
    
    private var notarizationOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("证据公证服务")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("提升证据法律效力，增强诉讼胜算")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            VStack(spacing: 12) {
                NotarizationBenefit(
                    icon: "shield.checkered",
                    title: "法律保护",
                    description: "公证书具有较强的证明力，受法律特殊保护"
                )
                
                NotarizationBenefit(
                    icon: "speedometer",
                    title: "提升效率",
                    description: "减少法庭质证环节，加快审理进程"
                )
                
                NotarizationBenefit(
                    icon: "person.badge.shield.checkmark",
                    title: "专业认证",
                    description: "经过专业公证员审查，确保程序合法"
                )
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private var notarizationTypesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("公证类型")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(notarizationInfo.notarizationTypes, id: \.id) { type in
                    NotarizationTypeDetailCard(
                        type: type,
                        isSelected: selectedNotarizationType?.id == type.id,
                        onSelect: {
                            selectedNotarizationType = type
                        }
                    )
                }
            }
        }
    }
    
    private var notaryOfficesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("推荐公证处")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(notarizationInfo.notaryOffices, id: \.id) { office in
                    NotaryOfficeDetailCard(
                        office: office,
                        onAppointment: {
                            selectedNotaryOffice = office
                            showingAppointment = true
                        }
                    )
                }
            }
        }
    }
    
    private var processingGuide: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("办理指南")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ProcessingStep(
                    step: 1,
                    title: "预约咨询",
                    description: "电话或在线预约，咨询具体要求"
                )
                
                ProcessingStep(
                    step: 2,
                    title: "准备材料",
                    description: "按要求准备相关证明材料"
                )
                
                ProcessingStep(
                    step: 3,
                    title: "现场办理",
                    description: "携带材料到公证处现场办理"
                )
                
                ProcessingStep(
                    step: 4,
                    title: "审核出证",
                    description: "公证员审核后出具公证书"
                )
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private var costExplanation: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("费用说明")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                CostExplanationItem(
                    title: "基础收费",
                    description: "根据公证事项类型收取基本费用，一般在100-500元之间"
                )
                
                CostExplanationItem(
                    title: "附加费用",
                    description: "包括复印费、翻译费、邮寄费等，按实际发生收取"
                )
                
                CostExplanationItem(
                    title: "优惠政策",
                    description: "部分公证处对批量公证、特殊群体提供优惠政策"
                )
                
                HStack {
                    Text("预估费用范围: ")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(notarizationInfo.estimatedCost.formattedRange)
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.accentColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    
                    Text("温馨提示")
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)
                }
                
                Text("具体费用以公证处收费标准为准。建议提前电话咨询确认所需材料和费用。部分电子证据公证可能需要额外的技术服务费。")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
            )
        }
        .padding()
        .liquidGlass()
    }
}

// MARK: - 辅助视图组件

struct NotarizationTypeDetailCard: View {
    let type: NotarizationType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(type.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("¥\(Int(type.baseFee))")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.accentColor)
                }
                
                Text(type.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                if !type.additionalFees.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("附加费用:")
                            .font(.caption2.bold())
                            .foregroundColor(.white.opacity(0.6))
                        
                        ForEach(type.additionalFees.indices, id: \.self) { index in
                            let fee = type.additionalFees[index]
                            HStack {
                                Text("• \(fee.description)")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Spacer()
                                
                                Text("¥\(Int(fee.amount))\(fee.unit)")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NotaryOfficeDetailCard: View {
    let office: NotaryOffice
    let onAppointment: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(office.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text(String(format: "%.1f", office.rating))
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                OfficeInfoRow(
                    icon: "location.fill",
                    text: office.address,
                    color: .blue
                )
                
                OfficeInfoRow(
                    icon: "phone.fill",
                    text: office.phone,
                    color: .green
                )
                
                OfficeInfoRow(
                    icon: "clock.fill",
                    text: office.workingHours,
                    color: .orange
                )
                
                if let distance = office.distance {
                    OfficeInfoRow(
                        icon: "car.fill",
                        text: "距离 \(String(format: "%.1f", distance))公里",
                        color: .purple
                    )
                }
            }
            
            HStack(spacing: 12) {
                Button("电话咨询") {
                    if let url = URL(string: "tel://\(office.phone)") {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(SecondaryActionButtonStyle())
                
                if office.appointmentUrl != nil {
                    Button("在线预约") {
                        onAppointment()
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                } else {
                    Button("电话预约") {
                        if let url = URL(string: "tel://\(office.phone)") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
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

struct OfficeInfoRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct ProcessingStep: View {
    let step: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentColor.opacity(0.3))
                    .frame(width: 32, height: 32)
                
                Text("\(step)")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.accentColor)
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

struct CostExplanationItem: View {
    let title: String
    let description: String
    
    var body: some View {
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

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppTheme.accentColor.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.bold())
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(configuration.isPressed ? 0.15 : 0.1))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - 预约视图

struct NotaryAppointmentView: View {
    let office: NotaryOffice
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDate = Date()
    @State private var selectedTime = "09:00"
    @State private var applicantName = ""
    @State private var phoneNumber = ""
    @State private var notarizationType = ""
    @State private var notes = ""
    
    private let timeSlots = ["09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 公证处信息
                    appointmentHeader
                    
                    // 预约信息
                    appointmentForm
                    
                    // 提交按钮
                    submitButton
                }
                .padding()
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("在线预约")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private var appointmentHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(office.name)
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                OfficeInfoRow(icon: "location.fill", text: office.address, color: .blue)
                OfficeInfoRow(icon: "phone.fill", text: office.phone, color: .green)
                OfficeInfoRow(icon: "clock.fill", text: office.workingHours, color: .orange)
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private var appointmentForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("预约信息")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                FormField(title: "申请人姓名", text: $applicantName, placeholder: "请输入您的姓名")
                FormField(title: "联系电话", text: $phoneNumber, placeholder: "请输入联系电话")
                FormField(title: "公证类型", text: $notarizationType, placeholder: "如：合同公证、文书公证等")
                
                // 日期选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("预约日期")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    DatePicker("选择日期", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .colorScheme(.dark)
                }
                
                // 时间选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("预约时间")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                        ForEach(timeSlots, id: \.self) { time in
                            Button {
                                selectedTime = time
                            } label: {
                                Text(time)
                                    .font(.caption)
                                    .foregroundColor(selectedTime == time ? .white : .white.opacity(0.7))
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedTime == time ? AppTheme.accentColor : Color.white.opacity(0.1))
                                    )
                            }
                        }
                    }
                }
                
                // 备注
                VStack(alignment: .leading, spacing: 8) {
                    Text("备注说明")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("请说明具体需求或特殊要求")
                                .foregroundColor(Color(UIColor.placeholderText))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }
                        
                        TextEditor(text: $notes)
                            .background(Color.clear)
                    }
                    .frame(minHeight: 80, maxHeight: 120)
                    .padding(4)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private var submitButton: some View {
        VStack(spacing: 12) {
            Button("提交预约") {
                // 处理预约提交
                dismiss()
            }
            .buttonStyle(WorkflowPrimaryButtonStyle())
            .disabled(applicantName.isEmpty || phoneNumber.isEmpty || notarizationType.isEmpty)
            
            Text("提交后公证处工作人员会在1个工作日内电话确认")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }
}

struct FormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

#Preview {
    NotarizationInfoView()
}