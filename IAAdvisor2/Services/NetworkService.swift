import Foundation
import Combine

// MARK: - 网络服务协议
protocol NetworkServiceProtocol {
    func sendRequest<T: Decodable>(_ request: URLRequest, responseType: T.Type) async throws -> T
    func sendAuthRequest<T: Decodable>(_ request: URLRequest, responseType: T.Type) async throws -> T
}

// MARK: - 网络服务实现
class NetworkService: NetworkServiceProtocol {
    nonisolated static let shared = NetworkService()
    
    private let session: URLSession
    private let baseURL = "https://api.example.com"
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConstants.Network.requestTimeout
        config.timeoutIntervalForResource = AppConstants.Network.requestTimeout * 2
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    /// 发送通用请求
    func sendRequest<T: Decodable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.networkError("无效的响应")
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                let errorMessage = try? parseErrorMessage(from: data)
                throw AppError.networkError(errorMessage ?? "服务器错误 (\(httpResponse.statusCode))")
            }
            
            do {
                return try JSONDecoder().decode(responseType, from: data)
            } catch {
                throw AppError.dataError("数据解析失败")
            }
            
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.networkError(error.localizedDescription)
        }
    }
    
    /// 发送需要认证的请求
    func sendAuthRequest<T: Decodable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        var authRequest = request
        
        // 添加认证头
        if let token = getAuthToken() {
            authRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw AppError.authenticationError("用户未登录")
        }
        
        return try await sendRequest(authRequest, responseType: responseType)
    }
    
    // MARK: - Request Builders
    
    /// 创建GET请求
    func createGETRequest(endpoint: String, parameters: [String: String]? = nil) -> URLRequest {
        var urlComponents = URLComponents(string: "\(baseURL)\(endpoint)")!
        
        if let parameters = parameters {
            urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return request
    }
    
    /// 创建POST请求
    func createPOSTRequest<T: Encodable>(endpoint: String, body: T) throws -> URLRequest {
        let url = URL(string: "\(baseURL)\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw AppError.dataError("请求数据编码失败")
        }
        
        return request
    }
    
    // MARK: - Private Methods
    
    /// 获取认证令牌
    private func getAuthToken() -> String? {
        // 从 Keychain 或 UserDefaults 获取令牌
        return UserDefaults.standard.string(forKey: "auth_token")
    }
    
    /// 解析错误消息
    private func parseErrorMessage(from data: Data) throws -> String {
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            return errorResponse.detail
        }
        return "未知服务器错误"
    }
}