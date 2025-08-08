import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            VStack {
                Text("创建新账户")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("用户名")
                            .font(.headline)
                            .foregroundColor(.white)
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(AppTheme.accentColor)
                            TextField("", text: $username)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .liquidGlass()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("邮箱")
                            .font(.headline)
                            .foregroundColor(.white)
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(AppTheme.accentColor)
                            TextField("", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .liquidGlass()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("密码")
                            .font(.headline)
                            .foregroundColor(.white)
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(AppTheme.accentColor)
                            SecureField("", text: $password)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .liquidGlass()
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: register) {
                        Text("注册")
                    }
                    .primaryButtonStyle()
                    .disabled(viewModel.isLoading || email.isEmpty || password.isEmpty || username.isEmpty)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
            }
            
            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView().scaleEffect(1.5).tint(.white)
            }
        }
    }
    
    private func register() {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else { return }
        viewModel.register(username: username, email: email, password: password)
    }
}

#Preview {
    NavigationView {
        RegisterView()
            .environmentObject(AppViewModel())
    }
}
