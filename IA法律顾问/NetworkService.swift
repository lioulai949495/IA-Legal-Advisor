import Foundation

// 定义后端服务的根URL
let baseURL = "https://ia-legal-advisor.onrender.com"

// 定义API的返回数据结构
struct ApiResponse: Decodable {
    let response: String?
    let options: [String]?
    let analysis_report: AnalysisReport?
    let error: String?
}

struct AnalysisReport: Decodable {
    let applicable_laws: String
    let success_rate_analysis: SuccessRate
    let action_suggestion: String
    let next_steps: NextSteps
}

struct SuccessRate: Decodable {
    let rate: Int
    let reason: String
}

struct NextSteps: Decodable {
    let process_guidance: String
    let document_templates: String
}


// 定义网络请求的错误类型
enum NetworkError: Error {
    case badURL
    case requestFailed(Error?)
    case decodingError
    case serverError(String)
}

// 定义用于发送验证码的函数
func sendCode(phoneNumber: String, completion: @escaping (Result<String, NetworkError>) -> Void) {
    // ... (此函数不变)
}

// 定义用于登录的函数
func login(phoneNumber: String, code: String, completion: @escaping (Result<String, NetworkError>) -> Void) {
    // ... (此函数不变)
}

// --- 聊天流程API ---

// 通用的网络请求函数
private func makeChatRequest(endpoint: String, body: [String: String], token: String, completion: @escaping (Result<ApiResponse, NetworkError>) -> Void) {
    guard let url = URL(string: "\(baseURL)\(endpoint)") else {
        completion(.failure(.badURL))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue(token, forHTTPHeaderField: "X-Token")
    
    request.httpBody = try? JSONEncoder().encode(body)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            completion(.failure(.requestFailed(error)))
            return
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(ApiResponse.self, from: data)
            if let serverError = decodedResponse.error {
                completion(.failure(.serverError(serverError)))
            } else {
                completion(.success(decodedResponse))
            }
        } catch {
            completion(.failure(.decodingError))
        }
    }.resume()
}

// 调用 /start-chat
func startChat(token: String, completion: @escaping (Result<ApiResponse, NetworkError>) -> Void) {
    makeChatRequest(endpoint: "/start-chat", body: [:], token: token, completion: completion)
}

// 调用 /get-roles
func getRoles(category: String, token: String, completion: @escaping (Result<ApiResponse, NetworkError>) -> Void) {
    makeChatRequest(endpoint: "/get-roles", body: ["category": category], token: token, completion: completion)
}

// 调用 /get-subtypes
func getSubtypes(category: String, role: String, token: String, completion: @escaping (Result<ApiResponse, NetworkError>) -> Void) {
    makeChatRequest(endpoint: "/get-subtypes", body: ["category": category, "role": role], token: token, completion: completion)
}

// 调用 /chat (最终分析)
func getFinalAnalysis(category: String, role: String, subtype: String, message: String, token: String, completion: @escaping (Result<ApiResponse, NetworkError>) -> Void) {
    let body = [
        "category": category,
        "role": role,
        "subtype": subtype,
        "message": message
    ]
    makeChatRequest(endpoint: "/chat", body: body, token: token, completion: completion)
}
