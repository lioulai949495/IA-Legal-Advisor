import SwiftUI

// MARK: - 键盘辅助函数
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // 为TextEditor添加工具栏的便捷方法
    func keyboardToolbar() -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    hideKeyboard()
                }
                .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - 数据模型

struct IAQuestion {
    let id: String
    let question: String
    let options: [String]
}

struct DocumentFile: Identifiable {
    let id = UUID()
    let name: String
    let type: DocumentType
    let content: String
}

enum DocumentType {
    case pdf, image, text, word
    
    var icon: String {
        switch self {
        case .pdf: return "doc.fill"
        case .image: return "photo.fill"
        case .text: return "doc.text.fill"
        case .word: return "doc.richtext.fill"
        }
    }
    
    var displayName: String {
        switch self {
        case .pdf: return "PDF文档"
        case .image: return "图片文件"
        case .text: return "文本文档"
        case .word: return "Word文档"
        }
    }
}

// MARK: - 文档选择器

struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentsSelected: ([DocumentFile]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            let documents = urls.compactMap { url -> DocumentFile? in
                guard url.startAccessingSecurityScopedResource() else { return nil }
                defer { url.stopAccessingSecurityScopedResource() }
                
                let type: DocumentType
                let pathExtension = url.pathExtension.lowercased()
                
                switch pathExtension {
                case "pdf": type = .pdf
                case "jpg", "jpeg", "png", "heic": type = .image
                case "txt": type = .text
                case "doc", "docx": type = .word
                default: type = .text
                }
                
                return DocumentFile(
                    name: url.lastPathComponent,
                    type: type,
                    content: "文档内容"
                )
            }
            
            parent.onDocumentsSelected(documents)
        }
    }
}

// MARK: - 案件类型选择器

struct CaseTypeSelector: View {
    @Binding var selectedCategory: CaseCategory
    @Binding var selectedType: CaseType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 分类选择
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(CaseCategory.allCases, id: \.self) { category in
                            Button {
                                selectedCategory = category
                                // 自动选择该分类下的第一个类型
                                if let firstType = CaseType.allCases.first(where: { $0.category == category }) {
                                    selectedType = firstType
                                }
                            } label: {
                                Text(category.rawValue)
                                    .font(.subheadline.bold())
                                    .foregroundColor(selectedCategory == category ? .white : .white.opacity(0.7))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedCategory == category ? category.color : Color.white.opacity(0.1))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // 具体类型选择
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(CaseType.allCases.filter { $0.category == selectedCategory }, id: \.self) { caseType in
                            Button {
                                selectedType = caseType
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: caseType.icon)
                                        .foregroundColor(caseType.category.color)
                                        .font(.title2)
                                        .frame(width: 40)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(caseType.rawValue)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Text(getCaseTypeDescription(caseType))
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedType == caseType {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppTheme.accentColor)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedType == caseType ? Color.white.opacity(0.1) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedType == caseType ? AppTheme.accentColor : Color.clear, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("选择案件类型")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
        }
    }
    
    private func getCaseTypeDescription(_ caseType: CaseType) -> String {
        switch caseType {
        // 民事案件
        case .contractDispute: return "合同违约、履行争议等"
        case .laborDispute: return "工资、加班费、解除合同等"
        case .divorceDispute: return "离婚、财产分割、子女抚养等"
        case .debtDispute: return "借贷纠纷、欠款追讨等"
        case .propertyDispute: return "房产买卖、租赁争议等"
        case .personalInjury: return "交通事故、医疗事故等"
        case .intellectualProperty: return "专利、商标、著作权等"
        case .tradingDispute: return "买卖合同、商品质量等"
        case .trafficAccident: return "车辆碰撞、人身伤害等"
        case .medicalDispute: return "医疗事故、诊疗纠纷等"
        case .neighborDispute: return "噪音扰民、边界争议等"
        case .inheritanceDispute: return "遗产分配、继承权等"
        
        // 刑事案件
        case .theft: return "盗窃财物、入室盗窃等"
        case .fraud: return "诈骗钱财、合同欺诈等"
        case .assault: return "故意伤害他人身体等"
        case .drugCrime: return "毒品犯罪、吸毒贩毒等"
        case .economicCrime: return "金融诈骗、职务侵占等"
        case .cyberCrime: return "网络诈骗、黑客攻击等"
        case .trafficCrime: return "交通肇事、危险驾驶等"
        case .corruptionCrime: return "贪污受贿、渎职犯罪等"
        case .violentCrime: return "暴力犯罪、故意杀人等"
        case .criminalDefense: return "刑事辩护、取保候审等"
        case .otherCriminal: return "其他刑事犯罪案件"
        
        // 行政案件
        case .administrativeDispute: return "行政诉讼、行政复议等"
        
        // 其他
        case .other: return "其他法律问题"
        }
    }
}

// MARK: - 视觉效果扩展

extension View {
    func liquidGlass() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .background(Material.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - 消息气泡视图

struct MessageBubbleView: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .top) {
            if message.isFromAI {
                // AI头像
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(AppTheme.secondaryColor)
                    )
                
                // 消息内容
                VStack(alignment: .leading, spacing: 5) {
                    Text(message.content)
                        .padding(12)
                        .foregroundColor(.primary)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white.opacity(0.1))
                        )
                    
                    Text(message.formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                }
                .fixedSize(horizontal: false, vertical: true)
                
                Spacer(minLength: 60)
            } else {
                Spacer(minLength: 60)
                
                // 消息内容
                VStack(alignment: .trailing, spacing: 5) {
                    Text(message.content)
                        .padding(12)
                        .foregroundColor(.white)
                        .background(AppTheme.accentColor.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(message.formattedDate)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 12)
                }
                .fixedSize(horizontal: false, vertical: true)
                
                // 用户头像
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.accentColor)
            }
        }
    }
}

#Preview {
    CaseTypeSelector(
        selectedCategory: .constant(.civil),
        selectedType: .constant(.contractDispute)
    )
}