import SwiftUI
import Combine

/// ViewModels容器，管理所有视图模型的生命周期和依赖
@MainActor
class ViewModelContainer: ObservableObject {
    
    // MARK: - ViewModels
    @Published var authViewModel: AuthViewModel
    @Published var chatViewModel: ChatViewModel
    @Published var caseViewModel: CaseViewModel
    @Published var appViewModel: AppViewModel
    
    // MARK: - Dependencies
    private let apiService: APIService
    
    // MARK: - Initialization
    init(apiService: APIService = .shared) {
        self.apiService = apiService
        
        // 由于我们在MainActor上下文中，可以直接初始化ViewModels
        self.authViewModel = AuthViewModel(apiService: apiService)
        self.chatViewModel = ChatViewModel(apiService: apiService)
        self.caseViewModel = CaseViewModel(apiService: apiService)
        self.appViewModel = AppViewModel()
        
        // 设置ViewModels之间的通信
        setupViewModelCommunication()
    }
    
    // MARK: - Private Methods
    
    /// 设置ViewModels之间的通信
    private func setupViewModelCommunication() {
        // 监听认证状态变化
        authViewModel.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.appViewModel.appState = .authenticated
                    self?.appViewModel.currentUser = self?.authViewModel.currentUser
                    
                    // 用户登录后，重新加载数据
                    self?.caseViewModel.loadCases()
                    self?.chatViewModel.startNewChat()
                } else {
                    self?.appViewModel.appState = .unauthenticated
                    self?.appViewModel.currentUser = nil
                    
                    // 清理用户数据
                    self?.caseViewModel.cases.removeAll()
                    self?.chatViewModel.clearMessages()
                }
            }
            .store(in: &appViewModel.cancellables)
        
        // 监听用户变化
        authViewModel.$currentUser
            .sink { [weak self] user in
                self?.appViewModel.currentUser = user
            }
            .store(in: &appViewModel.cancellables)
        
        // 监听错误状态
        Publishers.MergeMany(
            authViewModel.$errorMessage.compactMap { $0 },
            chatViewModel.$errorMessage.compactMap { $0 },
            caseViewModel.$errorMessage.compactMap { $0 }
        )
        .sink { [weak self] errorMessage in
            self?.appViewModel.errorMessage = errorMessage
        }
        .store(in: &appViewModel.cancellables)
    }
}

// MARK: - SwiftUI Environment Extension
extension View {
    /// 注入ViewModelContainer
    func environmentViewModelContainer(_ container: ViewModelContainer) -> some View {
        self.environmentObject(container)
    }
}