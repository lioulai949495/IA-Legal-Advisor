import Foundation
import Network
import Combine

@MainActor
class NetworkMonitor: ObservableObject {
    @MainActor static let shared = NetworkMonitor()
    
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    @Published var isExpensive = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
        
        var description: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "蜂窝网络"
            case .ethernet: return "以太网"
            case .unknown: return "未知"
            }
        }
    }
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateConnectionStatus(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func updateConnectionStatus(_ path: NWPath) {
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
        
        print("网络状态更新: 连接=\(isConnected), 类型=\(connectionType.description), 计费=\(isExpensive)")
    }
    
    func checkConnectivity() async -> Bool {
        return await withCheckedContinuation { continuation in
            let testMonitor = NWPathMonitor()
            testMonitor.pathUpdateHandler = { path in
                testMonitor.cancel()
                continuation.resume(returning: path.status == .satisfied)
            }
            testMonitor.start(queue: DispatchQueue.global())
        }
    }
}

// MARK: - Network-aware API Service Extension
extension APIService {
    private var networkMonitor: NetworkMonitor {
        NetworkMonitor.shared
    }
    
    @MainActor
    func checkNetworkBeforeRequest() throws {
        guard networkMonitor.isConnected else {
            throw APIError.networkUnavailable
        }
    }
    
    @MainActor
    var shouldUseCache: Bool {
        return !networkMonitor.isConnected || networkMonitor.isExpensive
    }
}