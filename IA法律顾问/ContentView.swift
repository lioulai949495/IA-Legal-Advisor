//
//  ContentView.swift
//  IA法律顾问
//
//  Created by Snake on 2025/7/15.
//

import SwiftUI

struct ContentView: View {
    @State private var phoneNumber: String = ""
    @State private var verificationCode: String = ""
    @State private var infoMessage: String = ""
    @State private var isLoading: Bool = false // 用于显示加载状态
    
    // 登录成功后，我们将跳转到聊天界面
    @State private var isLoggedIn: Bool = false
    @State private var authToken: String = "" // 保存获取到的Token

    var body: some View {
        if isLoggedIn {
            // 如果已登录，显示聊天界面 (我们将在下一步创建)
            // Text("登录成功！Token: \(authToken)")
            ChatView(authToken: $authToken)
        } else {
            // 如果未登录，显示登录界面
            loginView
        }
    }
    
    var loginView: some View {
        VStack(spacing: 20) {
            Text("欢迎使用IA法律顾问")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)
            
            TextField("请输入手机号", text: $phoneNumber)
                .keyboardType(.phonePad)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
            
            HStack {
                TextField("请输入验证码", text: $verificationCode)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                
                Button(action: sendCodeAction) {
                    Text("发送验证码")
                }
                .padding(.horizontal)
                .frame(height: 50)
                .background(isLoading ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(isLoading)
            }
            
            Button(action: loginAction) {
                Text("登录 / 注册")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isLoading ? Color.gray : Color.green)
            .foregroundColor(.white)
            .font(.headline)
            .cornerRadius(10)
            .disabled(isLoading)
            
            if !infoMessage.isEmpty {
                Text(infoMessage)
                    .foregroundColor(infoMessage.contains("成功") ? .green : .red)
                    .padding(.top, 20)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // 发送验证码按钮的动作
    func sendCodeAction() {
        isLoading = true
        infoMessage = ""
        sendCode(phoneNumber: self.phoneNumber) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let message):
                    self.infoMessage = message
                case .failure(let error):
                    self.infoMessage = "发送失败: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // 登录按钮的动作
    func loginAction() {
        isLoading = true
        infoMessage = ""
        login(phoneNumber: self.phoneNumber, code: self.verificationCode) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let token):
                    self.infoMessage = "登录成功！"
                    self.authToken = token
                    // 延迟一秒后跳转，给用户看清提示的时间
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.isLoggedIn = true
                    }
                case .failure(let error):
                    self.infoMessage = "登录失败: \(error.localizedDescription)"
                }
            }
        }
    }
}

// 为了预览，我们还需要一个空的ChatView
struct ChatView: View {
    @Binding var authToken: String
    var body: some View {
        Text("聊天界面，Token: \(authToken)")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
