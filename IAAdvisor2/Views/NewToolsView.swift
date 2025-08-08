import SwiftUI

struct NewToolsView: View {
    @State private var selectedCategory: ToolCategory = .all
    @State private var searchText = ""
    @State private var showingLawyerService = false
    @State private var selectedForm: LegalForm?
    @State private var selectedProcedure: CourtProcedure?
    
    enum ToolCategory: String, CaseIterable {
        case all = "全部"
        case forms = "表单文书"
        case procedures = "法院流程"
        case lawyer = "人工律师"
        case calculator = "费用计算"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .forms: return "doc.text"
            case .procedures: return "list.number"
            case .lawyer: return "person.crop.circle.badge.checkmark"
            case .calculator: return "calculator"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
                // 搜索栏
                searchSection
                
                // 分类选择
                categorySection
                
                // 内容区域
                ScrollView {
                    LazyVStack(spacing: 20) {
                        switch selectedCategory {
                        case .all:
                            allToolsSection
                        case .forms:
                            formsSection
                        case .procedures:
                            proceduresSection
                        case .lawyer:
                            lawyerSection
                        case .calculator:
                            calculatorSection
                        }
                    }
                    .padding()
                }
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .onTapGesture {
                hideKeyboard()
            }
        .sheet(item: $selectedForm) { form in
            FormDetailView(form: form)
        }
        .sheet(item: $selectedProcedure) { procedure in
            ProcedureDetailView(procedure: procedure)
        }
        .sheet(isPresented: $showingLawyerService) {
            LawyerServiceView()
        }
    }
    
    // MARK: - 搜索栏
    private var searchSection: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("搜索表单、流程...", text: $searchText)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .liquidGlass()
        }
        .padding()
    }
    
    // MARK: - 分类选择
    private var categorySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(ToolCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - 全部工具
    private var allToolsSection: some View {
        VStack(spacing: 20) {
            // 快速入口
            quickAccessGrid
            
            // 热门表单
            popularFormsSection
            
            // 常用流程
            commonProceduresSection
        }
    }
    
    private var quickAccessGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
            ToolCard(
                icon: "doc.badge.plus",
                title: "表单下载",
                subtitle: "诉讼文书模板",
                color: .blue
            ) {
                selectedCategory = .forms
            }
            
            ToolCard(
                icon: "list.clipboard",
                title: "流程指南",
                subtitle: "法院办事流程",
                color: .green
            ) {
                selectedCategory = .procedures
            }
            
            ToolCard(
                icon: "person.2.badge.gearshape",
                title: "人工律师",
                subtitle: "专业律师咨询",
                color: .purple
            ) {
                showingLawyerService = true
            }
            
            ToolCard(
                icon: "yensign.circle",
                title: "费用计算",
                subtitle: "诉讼费用估算",
                color: .orange
            ) {
                selectedCategory = .calculator
            }
        }
    }
    
    // MARK: - 表单文书
    private var formsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionHeader(title: "表单文书", subtitle: "专业法律文书模板")
            
            LazyVStack(spacing: 12) {
                ForEach(NewSampleData.legalForms) { form in
                    FormCard(form: form) {
                        selectedForm = form
                    }
                }
            }
        }
    }
    
    private var popularFormsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionHeader(title: "热门表单", subtitle: "最常用的法律文书")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(NewSampleData.legalForms.prefix(3)) { form in
                        CompactFormCard(form: form) {
                            selectedForm = form
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 法院流程
    private var proceduresSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionHeader(title: "法院流程", subtitle: "详细办事指南")
            
            LazyVStack(spacing: 12) {
                ForEach(NewSampleData.courtProcedures) { procedure in
                    ProcedureCard(procedure: procedure) {
                        selectedProcedure = procedure
                    }
                }
            }
        }
    }
    
    private var commonProceduresSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionHeader(title: "常用流程", subtitle: "热门办事指南")
            
            LazyVStack(spacing: 8) {
                ForEach(NewSampleData.courtProcedures.prefix(3)) { procedure in
                    CompactProcedureCard(procedure: procedure) {
                        selectedProcedure = procedure
                    }
                }
            }
        }
    }
    
    // MARK: - 人工律师
    private var lawyerSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionHeader(title: "人工律师", subtitle: "专业律师在线服务")
            
            LazyVStack(spacing: 12) {
                LawyerServiceCard {
                    showingLawyerService = true
                }
                
                LawyerAdvantagesCard()
            }
        }
    }
    
    // MARK: - 费用计算器
    private var calculatorSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionHeader(title: "费用计算", subtitle: "准确估算各项费用")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                CalculatorCard(
                    title: "诉讼费计算",
                    description: "根据争议金额计算法院收费",
                    icon: "building.columns.fill"
                )
                
                CalculatorCard(
                    title: "律师费估算",
                    description: "根据案件类型估算律师费用",
                    icon: "person.fill.badge.plus"
                )
                
                CalculatorCard(
                    title: "仲裁费计算",
                    description: "劳动仲裁相关费用计算",
                    icon: "scale.3d"
                )
                
                CalculatorCard(
                    title: "公证费查询",
                    description: "各类公证服务费用标准",
                    icon: "checkmark.seal.fill"
                )
            }
        }
    }
}

// MARK: - 子组件

struct CategoryChip: View {
    let category: NewToolsView.ToolCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AppTheme.accentColor : Color.white.opacity(0.1))
            )
            .foregroundColor(.white)
        }
    }
}

struct ToolCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .liquidGlass()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline.bold())
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

struct FormCard: View {
    let form: LegalForm
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack {
                    Image(systemName: "doc.text.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(form.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(form.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                    
                    HStack {
                        Text(form.category)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.3))
                            .cornerRadius(4)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle")
                            Text("下载")
                        }
                        .font(.caption)
                        .foregroundColor(AppTheme.accentColor)
                    }
                }
                
                Spacer()
            }
            .padding()
            .liquidGlass()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CompactFormCard: View {
    let form: LegalForm
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(form.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(form.category)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(width: 120, alignment: .leading)
            .padding()
            .liquidGlass()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProcedureCard: View {
    let procedure: CourtProcedure
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack {
                    Image(systemName: "list.number")
                        .font(.title2)
                        .foregroundColor(.green)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(procedure.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    HStack {
                        Label("预计时间", systemImage: "clock")
                        Text(procedure.estimatedTime)
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    
                    HStack {
                        Label("费用", systemImage: "yensign.circle")
                        Text(procedure.fees)
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(procedure.steps.count)个步骤")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.3))
                        .cornerRadius(4)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .liquidGlass()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CompactProcedureCard: View {
    let procedure: CourtProcedure
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "list.number")
                    .font(.title3)
                    .foregroundColor(.green)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(procedure.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text("\(procedure.steps.count)个步骤 • \(procedure.estimatedTime)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .liquidGlass()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LawyerServiceCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "person.2.badge.gearshape")
                        .font(.title)
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("专业律师咨询")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        
                        Text("资深律师一对一服务")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("50+")
                            .font(.title2.bold())
                            .foregroundColor(AppTheme.accentColor)
                        Text("专业律师")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    VStack(spacing: 4) {
                        Text("24h")
                            .font(.title2.bold())
                            .foregroundColor(AppTheme.accentColor)
                        Text("在线服务")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    VStack(spacing: 4) {
                        Text("99%")
                            .font(.title2.bold())
                            .foregroundColor(AppTheme.accentColor)
                        Text("满意度")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                
                Text("立即咨询")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.accentColor)
                    .cornerRadius(8)
            }
            .padding()
            .liquidGlass()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LawyerAdvantagesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("人工律师优势")
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                AdvantageRow(
                    icon: "checkmark.circle.fill",
                    title: "专业资质",
                    description: "执业律师，法律专业背景"
                )
                
                AdvantageRow(
                    icon: "clock.fill",
                    title: "及时响应",
                    description: "1-24小时内回复咨询"
                )
                
                AdvantageRow(
                    icon: "doc.text.fill",
                    title: "书面意见",
                    description: "提供详细的法律分析报告"
                )
                
                AdvantageRow(
                    icon: "phone.fill",
                    title: "电话咨询",
                    description: "支持电话和邮件沟通"
                )
            }
        }
        .padding()
        .liquidGlass()
    }
}

struct AdvantageRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
    }
}

struct CalculatorCard: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.orange)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .liquidGlass()
    }
}

// MARK: - LawyerServiceView
struct LawyerServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 图标和标题
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.shield.checkmark")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.accentColor)
                    
                    VStack(spacing: 8) {
                        Text("人工律师服务")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text("专业律师一对一咨询服务")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // 服务介绍
                VStack(alignment: .leading, spacing: 16) {
                    Text("服务内容")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        LawyerServiceFeature(
                            icon: "phone",
                            title: "电话咨询",
                            description: "专业律师电话答疑，解答法律问题"
                        )
                        
                        LawyerServiceFeature(
                            icon: "video",
                            title: "视频咨询",
                            description: "面对面视频咨询，更直观的交流"
                        )
                        
                        LawyerServiceFeature(
                            icon: "doc.text",
                            title: "文书审查",
                            description: "专业律师审查法律文书，提供修改建议"
                        )
                        
                        LawyerServiceFeature(
                            icon: "scale.3d",
                            title: "案件代理",
                            description: "全程法律服务，专业案件代理"
                        )
                    }
                }
                
                Spacer()
                
                // 联系按钮
                Button {
                    // 联系律师的逻辑
                } label: {
                    Text("联系专业律师")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accentColor)
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("人工律师服务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
        }
    }
}

struct LawyerServiceFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppTheme.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

#Preview {
    NewToolsView()
}