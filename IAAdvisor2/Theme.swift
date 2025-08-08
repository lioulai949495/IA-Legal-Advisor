import SwiftUI

// MARK: - 颜色主题
struct AppTheme {
    // 主题颜色 - 统一使用自适应颜色
    static let primaryColor = Color(hex: "2A2D5C")
    static let secondaryColor = Color(hex: "6A78E0") 
    static let accentColor = Color(hex: "9D85F2")
    static let backgroundColor = Color(hex: "1E2140")
    
    // 渐变
    static let backgroundGradient = LinearGradient(
        colors: [primaryColor, backgroundColor],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let accentGradient = LinearGradient(
        colors: [secondaryColor, accentColor],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // 深色模式渐变
    static let darkModeGradient = LinearGradient(
        colors: [Color(hex: "121212"), Color(hex: "1E1E1E")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // 动态渐变 - 根据环境自动选择
    static func dynamicBackgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        return colorScheme == .dark ? darkModeGradient : backgroundGradient
    }
}

// MARK: - 自定义修饰符
extension View {
    // 液态玻璃效果
    func liquidGlass(opacity: Double = 0.7, cornerRadius: CGFloat = 16) -> some View {
        self
            .background(Color.white.opacity(0.2))
            .background(Material.thinMaterial)
            .opacity(opacity)
            .cornerRadius(cornerRadius)
            .shadow(color: AppTheme.accentColor.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    // 主按钮样式
    func primaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppTheme.accentGradient)
            .cornerRadius(12)
            .shadow(color: AppTheme.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
    }
    
    // 次级按钮样式
    func secondaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Material.ultraThinMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.accentColor, lineWidth: 1)
            )
    }
    
    // 卡片样式
    func cardStyle(cornerRadius: CGFloat = 16) -> some View {
        self
            .padding()
            .background(Material.ultraThinMaterial)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
    }
    
    // 脉动效果
    func pulse(interval: Double = 1.5) -> some View {
        self.modifier(PulseModifier(interval: interval))
    }
}

// 脉动效果修饰符
struct PulseModifier: ViewModifier {
    let interval: Double
    @State private var pulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(pulsing ? 1.05 : 1.0)
            .opacity(pulsing ? 1.0 : 0.9)
            .animation(.easeInOut(duration: interval).repeatForever(autoreverses: true), value: pulsing)
            .onAppear {
                pulsing = true
            }
    }
}

// MARK: - 工具扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 尺寸常量
struct AppLayout {
    static let screenPadding: CGFloat = 20
    static let itemSpacing: CGFloat = 16
    static let cardCornerRadius: CGFloat = 16
} 