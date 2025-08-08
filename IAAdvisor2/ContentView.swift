import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        ZStack {
            switch viewModel.appState {
            case .splash:
                SplashScreen()
            case .unauthenticated:
                LoginView()
                    .environmentObject(viewModel)
                    .transition(.opacity)
            case .authenticated:
                NewMainTabView()
                    .environmentObject(viewModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: viewModel.appState)
        .networkStatusEnvironment()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
}
