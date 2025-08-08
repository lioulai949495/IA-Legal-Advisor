
import Foundation

class APIService {
    nonisolated static let shared = APIService()
    
    private var baseURL: URL { 
        URL(string: EnvironmentConfig.apiBaseURL)! 
    }
    private var authToken: String?
    
    // 请求配置 - 使用环境配置
    private var requestTimeout: TimeInterval { EnvironmentConfig.apiTimeout }
    private var maxRetryCount: Int { EnvironmentConfig.maxRetryCount }
    private let retryDelay: TimeInterval = 1.0

    private init() {
        // 从 UserDefaults 加载保存的 token
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            self.authToken = token
            Logger.shared.debug("从存储加载token: \(token.prefix(20))...")
        } else {
            Logger.shared.debug("未找到存储的token")
        }
        
        // 配置URLSession
        configureURLSession()
    }
    
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = requestTimeout * 2
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.httpMaximumConnectionsPerHost = 4
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        return URLSession(configuration: config)
    }()
    
    private lazy var longTimeoutSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = EnvironmentConfig.longApiTimeout
        config.timeoutIntervalForResource = EnvironmentConfig.longApiTimeout * 2
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.httpMaximumConnectionsPerHost = 4
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        return URLSession(configuration: config)
    }()
    
    private func configureURLSession() {
        // 已通过lazy var实现
    }
    
    func makeRequest(endpoint: String, method: String = "GET", body: Data? = nil, requiresAuth: Bool = false) async throws -> (Data, HTTPURLResponse) {
        return try await makeRequestWithRetry(endpoint: endpoint, method: method, body: body, requiresAuth: requiresAuth)
    }
    
    private func makeRequestWithRetry(endpoint: String, method: String = "GET", body: Data? = nil, requiresAuth: Bool = false, retryCount: Int = 0) async throws -> (Data, HTTPURLResponse) {
        do {
            return try await performRequest(endpoint: endpoint, method: method, body: body, requiresAuth: requiresAuth)
        } catch {
            // 判断是否需要重试
            if shouldRetry(error: error, retryCount: retryCount) {
                print("API调试: 请求失败，准备重试 (\(retryCount + 1)/\(maxRetryCount)): \(error)")
                
                // 指数退避策略
                let delay = retryDelay * pow(2.0, Double(retryCount))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                return try await makeRequestWithRetry(
                    endpoint: endpoint,
                    method: method,
                    body: body,
                    requiresAuth: requiresAuth,
                    retryCount: retryCount + 1
                )
            }
            throw error
        }
    }
    
    private func performRequest(endpoint: String, method: String = "GET", body: Data? = nil, requiresAuth: Bool = false) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        
        var urlRequest = createURLRequest(url: url, method: method, body: body, requiresAuth: requiresAuth)
        
        print("API调试: 发送请求到 \(url)")
        print("API调试: 请求方法: \(method)")
        if let headers = urlRequest.allHTTPHeaderFields, !headers.isEmpty {
            print("API调试: 请求头: \(headers)")
        }
        
        let startTime = Date()
        let (data, response): (Data, URLResponse)
        
        // 检查是否需要使用长超时（针对可能的冷启动）
        let isLoginRelated = endpoint.contains("send-code") || endpoint.contains("login")
        let session = isLoginRelated ? longTimeoutSession : urlSession
        
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            print("API调试: 请求失败 (耗时: \(String(format: "%.2f", duration))s): \(error)")
            
            if let urlError = error as? URLError {
                // 更详细的错误信息
                switch urlError.code {
                case .timedOut:
                    print("API调试: 请求超时，可能是服务器冷启动导致")
                case .cannotConnectToHost:
                    print("API调试: 无法连接到服务器")
                case .networkConnectionLost:
                    print("API调试: 网络连接丢失")
                case .notConnectedToInternet:
                    print("API调试: 设备未连接到网络")
                default:
                    print("API调试: 其他网络错误: \(urlError.localizedDescription)")
                }
                throw detectColdStart(error: error, duration: duration)
            } else {
                throw detectColdStart(error: error, duration: duration)
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("API调试: 无效的HTTP响应")
            throw APIError.invalidResponse
        }
        
        print("API调试: 响应状态码 \(httpResponse.statusCode) (耗时: \(String(format: "%.2f", duration))s)")
        
        // 处理不同的HTTP状态码
        switch httpResponse.statusCode {
        case 200...299:
            print("API调试: 请求成功，数据长度: \(data.count)")
            if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                print("API调试: 响应内容预览: \(responseString.prefix(200))...")
            }
            return (data, httpResponse)
            
        case 401:
            print("API调试: 认证失败，清除本地token")
            clearAuthToken()
            throw APIError.unauthorized
            
        case 429:
            print("API调试: 请求限制，稍后重试")
            throw APIError.rateLimited
            
        case 500...599:
            print("API调试: 服务器错误 \(httpResponse.statusCode)")
            throw APIError.serverError(message: "服务器内部错误")
            
        default:
            print("API调试: HTTP错误 \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("API调试: 错误响应: \(responseString)")
            }
            
            do {
                let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                throw APIError.serverError(message: errorResponse.detail)
            } catch {
                throw APIError.serverError(message: "HTTP \(httpResponse.statusCode)")
            }
        }
    }
    
    private func createURLRequest(url: URL, method: String, body: Data?, requiresAuth: Bool) -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("IA-Legal-Advisor-iOS/\(AppConstants.App.currentVersion)", forHTTPHeaderField: "User-Agent")
        urlRequest.timeoutInterval = requestTimeout
        
        if requiresAuth {
            if let storedToken = UserDefaults.standard.string(forKey: "auth_token") {
                print("API调试: 使用存储的token")
                self.authToken = storedToken
                urlRequest.setValue("Bearer \(storedToken)", forHTTPHeaderField: "Authorization")
            } else if let token = authToken {
                print("API调试: 使用内存中的token")
                urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                print("API调试: 未找到认证token")
            }
        }
        
        if let body = body {
            urlRequest.httpBody = body
            urlRequest.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        }
        
        return urlRequest
    }
    
    private func shouldRetry(error: Error, retryCount: Int) -> Bool {
        guard retryCount < maxRetryCount else { return false }
        
        switch error {
        case APIError.unauthorized:
            return false // 认证错误不重试
        case APIError.rateLimited:
            return true  // 限流错误重试
        case APIError.serverColdStart:
            return true  // 服务器冷启动重试
        case APIError.requestFailed(let urlError as URLError):
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                return true
            default:
                return false
            }
        case APIError.serverError:
            return true  // 服务器错误重试
        default:
            return false
        }
    }
    
    private func detectColdStart(error: Error, duration: TimeInterval) -> APIError {
        if let urlError = error as? URLError, urlError.code == .timedOut, duration > 45.0 {
            // 如果超时且耗时超过45秒，很可能是冷启动
            return APIError.serverColdStart
        }
        
        if let urlError = error as? URLError {
            return APIError.requestFailed(urlError)
        }
        
        return APIError.requestFailed(error)
    }
    
    private func clearAuthToken() {
        authToken = nil
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
    
    // MARK: - 服务器预热
    
    /// 预热服务器（适用于Render免费服务的冷启动）
    func warmupServer() async {
        print("API调试: 开始预热服务器...")
        do {
            let startTime = Date()
            let url = baseURL.appendingPathComponent("health")
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = EnvironmentConfig.longApiTimeout
            
            let (_, response) = try await urlSession.data(for: request)
            let duration = Date().timeIntervalSince(startTime)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("API调试: 服务器预热成功 (耗时: \(String(format: "%.2f", duration))s) - 状态码: \(httpResponse.statusCode)")
            }
        } catch {
            print("API调试: 服务器预热失败: \(error)")
        }
    }
    
    func sendCode(phone: String) async throws {
        // 先预热服务器
        await warmupServer()
        
        let request = PhoneRequest(phone_number: phone)
        let body = try JSONEncoder().encode(request)
        let (_, _) = try await makeRequest(endpoint: "/send-code", method: "POST", body: body)
    }

    func login(phone: String, code: String) async throws -> AuthResponse {
        let request = LoginRequest(phone_number: phone, code: code)
        let body = try JSONEncoder().encode(request)
        let (data, _) = try await makeRequest(endpoint: "/login", method: "POST", body: body)
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        self.authToken = authResponse.access_token
        print("API调试: 登录成功，设置内存token: \(authResponse.access_token.prefix(20))...")
        // 保存纯token到UserDefaults
        UserDefaults.standard.set(authResponse.access_token, forKey: "auth_token")
        print("API调试: token已保存到UserDefaults")
        return authResponse
    }
    
    func startChat() async throws {
        // 提供空的JSON对象作为请求体
        let emptyBody = try JSONEncoder().encode([:] as [String: String])
        let (_, _) = try await makeRequest(endpoint: "/start-chat", method: "POST", body: emptyBody, requiresAuth: true)
    }
    
    func getRoles() async throws -> [String] {
        // 提供空的JSON对象作为请求体
        let emptyBody = try JSONEncoder().encode([:] as [String: String])
        let (data, _) = try await makeRequest(endpoint: "/get-roles", method: "POST", body: emptyBody, requiresAuth: true)
        return try JSONDecoder().decode([String].self, from: data)
    }
    
    func getSubtypes() async throws -> [String] {
        // 提供空的JSON对象作为请求体
        let emptyBody = try JSONEncoder().encode([:] as [String: String])
        let (data, _) = try await makeRequest(endpoint: "/get-subtypes", method: "POST", body: emptyBody, requiresAuth: true)
        return try JSONDecoder().decode([String].self, from: data)
    }
    
    func sendChatMessage(category: String, message: String, role: String? = nil, subtype: String? = nil) async throws -> ChatResponse {
        let request = ChatRequest(category: category, role: role, subtype: subtype, message: message)
        let body = try JSONEncoder().encode(request)
        let (data, _) = try await makeRequest(endpoint: "/chat", method: "POST", body: body, requiresAuth: true)
        
        do {
            return try JSONDecoder().decode(ChatResponse.self, from: data)
        } catch {
            print("API调试: JSON解码失败 - \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("API调试: 原始响应数据: \(responseString)")
            }
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - 多种登录方式API
    
    /// Apple ID 登录
    func loginWithApple(identityToken: String, userIdentifier: String, email: String?, fullName: String?) async throws -> AuthResponse {
        let request = AppleLoginRequest(
            identity_token: identityToken,
            user_identifier: userIdentifier,
            email: email,
            full_name: fullName
        )
        let body = try JSONEncoder().encode(request)
        let (data, _) = try await makeRequest(endpoint: "/auth/apple", method: "POST", body: body)
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        self.authToken = authResponse.access_token
        UserDefaults.standard.set(authResponse.access_token, forKey: "auth_token")
        return authResponse
    }
    
    /// 邮箱登录
    func loginWithEmail(email: String, password: String) async throws -> AuthResponse {
        let request = EmailLoginRequest(email: email, password: password)
        let body = try JSONEncoder().encode(request)
        let (data, _) = try await makeRequest(endpoint: "/auth/email/login", method: "POST", body: body)
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        self.authToken = authResponse.access_token
        UserDefaults.standard.set(authResponse.access_token, forKey: "auth_token")
        return authResponse
    }
    
    /// 邮箱注册
    func registerWithEmail(email: String, password: String, username: String) async throws -> AuthResponse {
        let request = EmailRegisterRequest(email: email, password: password, username: username)
        let body = try JSONEncoder().encode(request)
        let (data, _) = try await makeRequest(endpoint: "/auth/email/register", method: "POST", body: body)
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        self.authToken = authResponse.access_token
        UserDefaults.standard.set(authResponse.access_token, forKey: "auth_token")
        return authResponse
    }
    
    /// 微信登录
    func loginWithWeChat(code: String) async throws -> AuthResponse {
        let request = WeChatLoginRequest(code: code)
        let body = try JSONEncoder().encode(request)
        let (data, _) = try await makeRequest(endpoint: "/auth/wechat", method: "POST", body: body)
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        self.authToken = authResponse.access_token
        UserDefaults.standard.set(authResponse.access_token, forKey: "auth_token")
        return authResponse
    }
    
    /// 支付宝登录
    func loginWithAlipay(authCode: String) async throws -> AuthResponse {
        let request = AlipayLoginRequest(auth_code: authCode)
        let body = try JSONEncoder().encode(request)
        let (data, _) = try await makeRequest(endpoint: "/auth/alipay", method: "POST", body: body)
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        self.authToken = authResponse.access_token
        UserDefaults.standard.set(authResponse.access_token, forKey: "auth_token")
        return authResponse
    }
    
    func logout() {
        print("API调试: 清除token")
        authToken = nil
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
    
    // MARK: - 案件管理API
    
    /// 创建新案件
    func createCase(title: String, description: String, caseType: String) async throws -> CaseResponse {
        let request = CreateCaseRequest(
            title: title,
            description: description,
            case_type: caseType
        )
        let body = try JSONEncoder().encode(request)
        let (data, _) = try await makeRequest(endpoint: "/cases", method: "POST", body: body, requiresAuth: true)
        return try JSONDecoder().decode(CaseResponse.self, from: data)
    }
    
    /// 获取用户案件列表
    func getCases() async throws -> [CaseResponse] {
        let (data, _) = try await makeRequest(endpoint: "/cases", method: "GET", requiresAuth: true)
        return try JSONDecoder().decode([CaseResponse].self, from: data)
    }
    
    /// 获取单个案件详情
    func getCase(id: String) async throws -> CaseResponse {
        let (data, _) = try await makeRequest(endpoint: "/cases/\(id)", method: "GET", requiresAuth: true)
        return try JSONDecoder().decode(CaseResponse.self, from: data)
    }
    
    /// 更新案件
    func updateCase(id: String, title: String?, description: String?) async throws -> CaseResponse {
        let request = UpdateCaseRequest(title: title, description: description)
        let body = try JSONEncoder().encode(request)
        let (data, _) = try await makeRequest(endpoint: "/cases/\(id)", method: "PUT", body: body, requiresAuth: true)
        return try JSONDecoder().decode(CaseResponse.self, from: data)
    }
    
    /// 删除案件
    func deleteCase(id: String) async throws {
        let (_, _) = try await makeRequest(endpoint: "/cases/\(id)", method: "DELETE", requiresAuth: true)
    }
    
    // MARK: - 文档管理API
    
    /// 上传文档
    func uploadDocument(caseId: String, data: Data, fileName: String, mimeType: String) async throws -> DocumentResponse {
        // 创建multipart/form-data请求
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        
        // 添加case_id字段
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"case_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(caseId)\r\n".data(using: .utf8)!)
        
        // 添加文件
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // 创建请求
        guard let url = URL(string: "/documents", relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError(message: "Upload failed with status \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode(DocumentResponse.self, from: responseData)
    }
    
    /// 获取文档列表
    func getDocuments(caseId: String? = nil) async throws -> [DocumentResponse] {
        let endpoint = caseId != nil ? "/documents?case_id=\(caseId!)" : "/documents"
        let (data, _) = try await makeRequest(endpoint: endpoint, method: "GET", requiresAuth: true)
        return try JSONDecoder().decode([DocumentResponse].self, from: data)
    }
    
    /// 删除文档
    func deleteDocument(id: String) async throws {
        let (_, _) = try await makeRequest(endpoint: "/documents/\(id)", method: "DELETE", requiresAuth: true)
    }
    
    // MARK: - 用户信息API
    
    /// 获取用户信息
    func getUserProfile() async throws -> UserProfileResponse {
        let (data, _) = try await makeRequest(endpoint: "/profile", method: "GET", requiresAuth: true)
        return try JSONDecoder().decode(UserProfileResponse.self, from: data)
    }
    
    /// 更新用户信息
    func updateUserProfile(username: String?, email: String?) async throws -> UserProfileResponse {
        let request = UpdateProfileRequest(username: username, email: email)
        let body = try JSONEncoder().encode(request)
        let (data, _) = try await makeRequest(endpoint: "/profile", method: "PUT", body: body, requiresAuth: true)
        return try JSONDecoder().decode(UserProfileResponse.self, from: data)
    }
    
    // MARK: - AI分析API
    
    /// 案件分析请求
    func analyzeCaseWithAI(caseId: String, analysisType: String) async throws -> AIAnalysisResponse {
        let request = AIAnalysisRequest(case_id: caseId, analysis_type: analysisType)
        let body = try JSONEncoder().encode(request)
        let (data, _) = try await makeRequest(endpoint: "/ai/analyze", method: "POST", body: body, requiresAuth: true)
        return try JSONDecoder().decode(AIAnalysisResponse.self, from: data)
    }
    
    /// 生成法律文档
    func generateLegalDocument(caseId: String, documentType: String, template: String? = nil) async throws -> GeneratedDocumentResponse {
        let request = DocumentGenerationRequest(
            case_id: caseId, 
            document_type: documentType,
            template: template
        )
        let body = try JSONEncoder().encode(request)
        let (data, _) = try await makeRequest(endpoint: "/ai/generate-document", method: "POST", body: body, requiresAuth: true)
        return try JSONDecoder().decode(GeneratedDocumentResponse.self, from: data)
    }
}
