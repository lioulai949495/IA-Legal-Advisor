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
    @State private var isLoading: Bool = false
    
    @State private var isLoggedIn: Bool = false
    @State private var authToken: String = ""

    var body: some View {
        NavigationView { // 使用NavigationView来实现页面跳转
            if isLoggedIn {
                ChatView(authToken: $authToken)
            } else {
                loginView
            }
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
        .navigationTitle("") // 隐藏登录页的标题
        .navigationBarHidden(true)
    }
    
    // ... (sendCodeAction 和 loginAction 函数保持不变)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
