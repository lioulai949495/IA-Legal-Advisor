import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                
                // 用户消息气泡
                Text(message.text)
                    .padding(16)
                    .background(Color(hex: "4366EE"))
                    .foregroundColor(.white)
                    .cornerRadius(20, corners: [.topLeft, .topRight, .bottomLeft])
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    .padding(.leading, 60)
            } else {
                // AI助手气泡
                HStack(alignment: .top, spacing: 8) {
                    // AI头像
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "3A4CDA"), Color(hex: "6286FF")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                    
                    // AI消息内容
                    Text(message.text)
                        .padding(16)
                        .background(Color(hex: "1A1C2D"))
                        .foregroundColor(.white)
                        .cornerRadius(20, corners: [.topRight, .bottomLeft, .bottomRight])
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
                .padding(.trailing, 60)
                
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

// 颜色十六进制扩展
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
            (a, r, g, b) = (1, 1, 1, 0)
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

// 圆角自定义
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// 预览
struct ChatBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ChatBubbleView(message: ChatMessage(text: "您好，我是AI法律顾问，有什么可以帮您的吗？", isFromUser: false))
            ChatBubbleView(message: ChatMessage(text: "我想咨询一个房屋租赁合同的问题", isFromUser: true))
            ChatBubbleView(message: ChatMessage(text: "好的，请告诉我您的具体问题，我将为您提供专业的法律建议。", isFromUser: false))
        }
        .padding()
        .background(Color(hex: "0D0E19"))
        .previewLayout(.sizeThatFits)
    }
} 