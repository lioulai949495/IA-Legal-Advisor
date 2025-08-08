import SwiftUI

struct PurchaseServicesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedService: PaidService?
    @State private var showingPayment = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 头部说明
                        headerSection
                        
                        // 咨询次数服务
                        consultationServicesSection
                        
                        // 案件名额服务
                        caseServicesSection
                        
                        // 其他专业服务
                        professionalServicesSection
                    }
                    .padding()
                }
            }
            .navigationTitle("单独购买服务")
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
        .sheet(isPresented: $showingPayment) {
            if let service = selectedService {
                MembershipPaymentView(
                    title: service.name,
                    description: service.description,
                    price: service.price,
                    onPaymentSuccess: {
                        handlePurchaseSuccess(service: service)
                    }
                )
            }
        }
    }
    
    // MARK: - 头部说明
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "cart.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("按需购买")
                .font(.title.bold())
                .foregroundColor(.white)
            
            Text("根据您的实际需求，灵活购买所需服务")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - 咨询次数服务
    private var consultationServicesSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "额外咨询次数", icon: "message.fill", color: .green)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(PaidService.availableServices.filter { $0.type == .extraConsultations }) { service in
                    ServiceCard(service: service) {
                        selectedService = service
                        showingPayment = true
                    }
                }
            }
        }
    }
    
    // MARK: - 案件名额服务
    private var caseServicesSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "案件创建名额", icon: "folder.badge.plus", color: .orange)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(PaidService.availableServices.filter { $0.type == .caseSlot }) { service in
                    ServiceCard(service: service) {
                        selectedService = service
                        showingPayment = true
                    }
                }
            }
        }
    }
    
    // MARK: - 专业服务
    private var professionalServicesSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "专业服务", icon: "star.fill", color: .purple)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(PaidService.availableServices.filter { 
                    $0.type != .extraConsultations && $0.type != .caseSlot 
                }) { service in
                    ServiceCard(service: service) {
                        selectedService = service
                        showingPayment = true
                    }
                }
            }
        }
    }
    
    // MARK: - 分区标题
    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.headline.bold())
                .foregroundColor(.white)
            
            Spacer()
        }
    }
    
    // MARK: - 处理购买成功
    private func handlePurchaseSuccess(service: PaidService) {
        // 根据服务类型更新用户数据
        switch service.type {
        case .extraConsultations:
            // 重置今日咨询次数（模拟增加次数）
            if service.id == "consultation_10" {
                viewModel.currentUser?.dailyConsultationsUsed = max(0, (viewModel.currentUser?.dailyConsultationsUsed ?? 0) - 10)
            } else if service.id == "consultation_50" {
                viewModel.currentUser?.dailyConsultationsUsed = max(0, (viewModel.currentUser?.dailyConsultationsUsed ?? 0) - 50)
            }
        case .caseSlot:
            // 增加案件名额
            if service.id == "case_1" {
                viewModel.currentUser?.extraCaseSlots += 1
            } else if service.id == "case_3" {
                viewModel.currentUser?.extraCaseSlots += 3
            }
        default:
            break
        }
        
        dismiss()
    }
}

// MARK: - 服务卡片
struct ServiceCard: View {
    let service: PaidService
    let onPurchase: () -> Void
    
    var body: some View {
        Button(action: onPurchase) {
            VStack(spacing: 12) {
                // 服务图标
                Image(systemName: serviceIcon)
                    .font(.title2)
                    .foregroundColor(serviceColor)
                
                // 服务名称
                Text(service.name)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // 服务描述
                Text(service.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // 价格
                Text("¥\(service.price, specifier: "%.1f")")
                    .font(.title3.bold())
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .liquidGlass()
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(serviceColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var serviceIcon: String {
        switch service.type {
        case .extraConsultations:
            return "message.badge.fill"
        case .caseSlot:
            return "folder.badge.plus"
        case .analysis:
            return "chart.bar.xaxis"
        case .document:
            return "doc.text.fill"
        case .consultation:
            return "person.badge.shield.checkmark"
        case .riskAssessment:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var serviceColor: Color {
        switch service.type {
        case .extraConsultations:
            return .green
        case .caseSlot:
            return .orange
        case .analysis:
            return .blue
        case .document:
            return .purple
        case .consultation:
            return .red
        case .riskAssessment:
            return .yellow
        }
    }
}

#Preview {
    PurchaseServicesView()
        .environmentObject(AppViewModel())
}