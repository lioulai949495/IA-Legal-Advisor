import SwiftUI

// 兼容iOS 15的TextEditor背景修饰符
struct TextEditorBackgroundModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}

// 兼容iOS 15的Form背景修饰符
struct FormBackgroundModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .scrollContentBackground(.hidden)
        } else {
            content
                .onAppear {
                    UITableView.appearance().backgroundColor = .clear
                }
                .onDisappear {
                    UITableView.appearance().backgroundColor = .systemGroupedBackground
                }
        }
    }
}

// 扩展View以便更方便地应用这些修饰符
extension View {
    // 适用于TextEditor的背景透明
    func hideTextEditorBackground() -> some View {
        self.modifier(TextEditorBackgroundModifier())
    }
    
    // 适用于Form的背景透明
    func hideFormBackground() -> some View {
        self.modifier(FormBackgroundModifier())
    }
} 