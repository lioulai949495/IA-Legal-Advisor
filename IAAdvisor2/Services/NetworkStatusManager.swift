import Foundation
import Network
import SwiftUI

@MainActor
class NetworkStatusManager: ObservableObject {
    static let shared = NetworkStatusManager()
    
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    @Published var serverStatus: ServerStatus = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    enum ServerStatus {
        case online
        case offline
        case coldStart
        case unknown
    }
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.updateConnectionType(path: path)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func updateConnectionType(path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
    }
    
    /// 检查服务器状态
    func checkServerStatus() async {
        guard isConnected else {
            await MainActor.run {
                serverStatus = .offline
            }
            return
        }
        
        do {
            let startTime = Date()
            await APIService.shared.warmupServer()
            let duration = Date().timeIntervalSince(startTime)
            
            await MainActor.run {
                if duration > 30.0 {
                    serverStatus = .coldStart
                } else {
                    serverStatus = .online
                }
            }
        } catch {
            await MainActor.run {
                serverStatus = .offline
            }
        }
    }
    
    var statusDescription: String {
        switch (isConnected, serverStatus) {
        case (false, _):
            return "网络连接不可用"
        case (true, .online):
            return "服务正常"
        case (true, .offline):
            return "服务器离线"
        case (true, .coldStart):
            return "服务器启动中，请稍候..."
        case (true, .unknown):
            return "检查服务器状态中..."
        }
    }
    
    var statusColor: Color {
        switch (isConnected, serverStatus) {
        case (false, _):
            return .red
        case (true, .online):
            return .green
        case (true, .offline):
            return .red
        case (true, .coldStart):
            return .orange
        case (true, .unknown):
            return .gray
        }
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - 网络状态视图组件

struct NetworkStatusBanner: View {
    @StateObject private var networkManager = NetworkStatusManager.shared
    @State private var showBanner = false
    
    var body: some View {
        Group {
            if showBanner && (!networkManager.isConnected || networkManager.serverStatus == .offline || networkManager.serverStatus == .coldStart) {
                HStack {
                    Image(systemName: getStatusIcon())
                        .foregroundColor(networkManager.statusColor)
                    
                    Text(networkManager.statusDescription)
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if networkManager.serverStatus == .coldStart {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    
                    Button("关闭") {
                        withAnimation {
                            showBanner = false
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(networkManager.statusColor.opacity(0.9))
                .transition(.move(edge: .top))
            }
        }
        .onReceive(networkManager.$isConnected) { _ in
            updateBannerVisibility()
        }
        .onReceive(networkManager.$serverStatus) { _ in
            updateBannerVisibility()
        }
        .task {
            await networkManager.checkServerStatus()
        }
    }
    
    private func getStatusIcon() -> String {
        switch (networkManager.isConnected, networkManager.serverStatus) {
        case (false, _):
            return "wifi.slash"
        case (true, .offline):
            return "server.rack"
        case (true, .coldStart):
            return "arrow.clockwise"
        case (true, .online):
            return "checkmark.circle"
        case (true, .unknown):
            return "questionmark.circle"
        }
    }
    
    private func updateBannerVisibility() {
        let shouldShow = !networkManager.isConnected || 
                        networkManager.serverStatus == .offline || 
                        networkManager.serverStatus == .coldStart
        
        if shouldShow != showBanner {
            withAnimation {
                showBanner = shouldShow
            }
        }
    }
}

// MARK: - SwiftUI Environment
struct NetworkStatusEnvironment: ViewModifier {
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            NetworkStatusBanner()
            content
        }
        .environmentObject(NetworkStatusManager.shared)
    }
}

extension View {
    func networkStatusEnvironment() -> some View {
        modifier(NetworkStatusEnvironment())
    }
}