import SwiftUI

struct DocumentFilterSheet: View {
    @Binding var selectedCategory: CaseDocumentCategory?
    @Binding var selectedSortOption: DocumentSortOption
    
    @Environment(\.dismiss) private var dismiss
    @State private var tempCategory: CaseDocumentCategory?
    @State private var tempSortOption: DocumentSortOption
    
    init(selectedCategory: Binding<CaseDocumentCategory?>, selectedSortOption: Binding<DocumentSortOption>) {
        self._selectedCategory = selectedCategory
        self._selectedSortOption = selectedSortOption
        self._tempCategory = State(initialValue: selectedCategory.wrappedValue)
        self._tempSortOption = State(initialValue: selectedSortOption.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 分类筛选
                    categoryFilterSection
                    
                    // 排序选项
                    sortOptionsSection
                }
                .padding()
            }
            .navigationTitle("筛选和排序")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("应用") {
                        selectedCategory = tempCategory
                        selectedSortOption = tempSortOption
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentColor)
                    .font(.headline.bold())
                }
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
        }
    }
    
    // MARK: - 分类筛选
    private var categoryFilterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("文档分类")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                CategoryFilterOption(
                    title: "全部",
                    icon: "doc.on.doc",
                    color: .gray,
                    isSelected: tempCategory == nil
                ) {
                    tempCategory = nil
                }
                
                ForEach(CaseDocumentCategory.allCases, id: \.self) { category in
                    CategoryFilterOption(
                        title: category.rawValue,
                        icon: getCategoryIcon(category),
                        color: category.color,
                        isSelected: tempCategory == category
                    ) {
                        tempCategory = category
                    }
                }
            }
        }
    }
    
    // MARK: - 排序选项
    private var sortOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("排序方式")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(DocumentSortOption.allCases, id: \.self) { option in
                    SortOptionRow(
                        option: option,
                        isSelected: tempSortOption == option
                    ) {
                        tempSortOption = option
                    }
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    private func getCategoryIcon(_ category: CaseDocumentCategory) -> String {
        switch category {
        case .uploaded: return "arrow.up.doc"
        case .generated: return "doc.richtext"
        case .analysis: return "chart.bar.doc.horizontal"
        }
    }
}

// MARK: - 分类筛选选项
struct CategoryFilterOption: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.accentColor)
                }
            }
            .padding()
            .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 排序选项行
struct SortOptionRow: View {
    let option: DocumentSortOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: option.systemImage)
                    .font(.title2)
                    .foregroundColor(AppTheme.accentColor)
                    .frame(width: 30)
                
                Text(option.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.accentColor)
                }
            }
            .padding()
            .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DocumentFilterSheet(
        selectedCategory: .constant(nil),
        selectedSortOption: .constant(.dateUpdated)
    )
}