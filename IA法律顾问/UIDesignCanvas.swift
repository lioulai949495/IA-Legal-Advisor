import SwiftUI

// --- 1. 主题定义 (Theme Definition) ---
// 我们将在这里定义App的颜色和字体规范，灵感来源于Dribbble的设计。
struct AppTheme {
    // MARK: - Colors
    static let background = Color(red: 0.96, green: 0.96, blue: 0.98) // 柔和的浅灰色背景
    static let primaryBlue = Color(red: 0.25, green: 0.45, blue: 1.0) // 鲜艳的蓝色主色调
    static let textPrimary = Color(red: 0.1, green: 0.1, blue: 0.15) // 深炭灰文本
    static let textSecondary = Color.gray // 次要文本
    static let cardBackground = Color.white // 卡片背景
    
    // MARK: - Fonts
    // (暂时使用系统默认字体，可以根据需要具体指定)
}

// --- 2. UI组件设计画板 (Design Canvas) ---
// 在这里设计和预览我们的UI组件
struct UIDesignCanvas: View {
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea() // 应用全局背景色
            
            ScrollView {
                VStack(spacing: 30) {
                    Text("UI Design Canvas")
                        .font(.largeTitle).bold()
                        .foregroundColor(AppTheme.textPrimary)
                    
                    // --- 按钮预览 ---
                    VStack {
                        Text("Button Styles").font(.headline)
                        Button("Primary Action") { /* action */ }
                            .buttonStyle(PrimaryButtonStyle())
                        Button("Secondary Action") { /* action */ }
                            .padding(.top, 10)
                    }
                    
                    // --- 卡片预览 ---
                    VStack {
                        Text("Card Style").font(.headline)
                        VStack(alignment: .leading) {
                            Image(systemName: "star.fill")
                                .foregroundColor(AppTheme.primaryBlue)
                            Text("This is a Card")
                                .font(.title2).bold()
                            Text("It contains some content and has a nice shadow.")
                                .font(.body)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .modifier(CardModifier())
                    }
                    
                    // --- 输入框预览 ---
                     VStack {
                        Text("Text Field Style").font(.headline)
                        TextField("Enter your phone number...", text: .constant(""))
                            .modifier(CustomTextFieldModifier())
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

// --- 3. 自定义样式和修改器 (Custom Styles & Modifiers) ---

// 主要按钮样式 (胶囊形状)
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .background(AppTheme.primaryBlue)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// 卡片样式修改器
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(AppTheme.cardBackground)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// 输入框样式修改器
struct CustomTextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppTheme.cardBackground) // 使用卡片背景色，使其有深度感
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}


// --- 4. 预览 (Preview) ---
struct UIDesignCanvas_Previews: PreviewProvider {
    static var previews: some View {
        UIDesignCanvas()
    }
}
