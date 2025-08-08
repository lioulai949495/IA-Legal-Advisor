//
//  IAAdvisor2App.swift
//  IAAdvisor2
//
//  Created by Snake on 2025/7/21.
//

import SwiftUI

@main
struct IAAdvisor2App: App {
    @StateObject private var viewModelContainer = ViewModelContainer()
    
    init() {
        // 键盘相关配置
        setupKeyboard()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModelContainer.appViewModel)
                .environmentObject(viewModelContainer)
                .onAppear {
                    // 清理任何可能阻止键盘的状态
                    clearKeyboardBlockers()
                }
        }
    }
    
    private func setupKeyboard() {
        // 确保应用程序支持键盘输入
        UIApplication.shared.isIdleTimerDisabled = false
        
        // 设置文本输入相关配置
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func clearKeyboardBlockers() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 清理可能的第一响应者冲突
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            
            // 强制重置输入视图状态
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.endEditing(true)
            }
        }
    }
}
