import SwiftUI

struct SplashScreen: View {
    @State private var size = 0.7
    @State private var opacity = 0.4
    @State private var logoRotation = 0.0
    @State private var dotsOpacity = 0.0
    @State private var textOffset = 50.0
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 法律图标组合
                ZStack {
                    // 背景圆形
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.8),
                                    Color.purple.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    // 法律天平图标
                    Image(systemName: "scalemass.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(logoRotation))
                    
                    // AI元素 - 小圆点装饰
                    VStack {
                        HStack {
                            Circle()
                                .fill(Color.cyan)
                                .frame(width: 8, height: 8)
                            Spacer()
                            Circle()
                                .fill(Color.cyan.opacity(0.7))
                                .frame(width: 6, height: 6)
                        }
                        .frame(width: 100)
                        
                        Spacer()
                        
                        HStack {
                            Circle()
                                .fill(Color.cyan.opacity(0.5))
                                .frame(width: 4, height: 4)
                            Spacer()
                            Circle()
                                .fill(Color.cyan)
                                .frame(width: 7, height: 7)
                        }
                        .frame(width: 100)
                    }
                    .frame(height: 100)
                    .opacity(dotsOpacity)
                }
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 12) {
                    // 应用名称
                    Text("IA法律顾问")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // 应用标语
                    Text("智能法律服务新时代")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                    
                    // 版本信息
                    Text("v\(AppConstants.App.currentVersion)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 8)
                }
                .offset(y: textOffset)
            }
            .scaleEffect(size)
            .opacity(opacity)
            .onAppear {
                // 分阶段启动动画
                // 第一阶段：基础缩放和透明度（0-0.8秒）
                withAnimation(.easeOut(duration: 0.8)) {
                    self.size = 1.0
                    self.opacity = 1.0
                }
                
                // 第二阶段：logo旋转（0.3-1.0秒）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                        self.logoRotation = 360.0
                    }
                }
                
                // 第三阶段：AI圆点显示（0.6-1.2秒）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        self.dotsOpacity = 1.0
                    }
                }
                
                // 第四阶段：文字上滑（0.8-1.4秒）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                        self.textOffset = 0.0
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreen()
} 