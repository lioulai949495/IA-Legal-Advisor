import Foundation

// 定义后端服务的根URL
let baseURL = "https://ia-legal-advisor.onrender.com"

// 定义网络请求的错误类型
enum NetworkError: Error {
    case badURL
    case requestFailed
    case decodingError
    case serverError(String)
}

// 定义用于发送验证码的函数
func sendCode(phoneNumber: String, completion: @escaping (Result<String, NetworkError>) -> Void) {
    guard let url = URL(string: "\(baseURL)/send-code") else {
        completion(.failure(.badURL))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = ["phone_number": phoneNumber]
    request.httpBody = try? JSONEncoder().encode(body)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            completion(.failure(.requestFailed))
            return
        }
        
        // 将返回的JSON数据解析为字典
        if let result = try? JSONDecoder().decode([String: String].self, from: data) {
            if let message = result["message"] {
                completion(.success(message))
            } else if let detail = result["detail"] {
                completion(.failure(.serverError(detail)))
            }
        } else {
            completion(.failure(.decodingError))
        }
    }.resume()
}

// 定义用于登录的函数
func login(phoneNumber: String, code: String, completion: @escaping (Result<String, NetworkError>) -> Void) {
    guard let url = URL(string: "\(baseURL)/login") else {
        completion(.failure(.badURL))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = ["phone_number": phoneNumber, "code": code]
    request.httpBody = try? JSONEncoder().encode(body)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            completion(.failure(.requestFailed))
            return
        }
        
        // 解析登录成功返回的Token
        if let result = try? JSONDecoder().decode([String: String].self, from: data) {
            if let accessToken = result["access_token"] {
                completion(.success(accessToken))
            } else if let detail = result["detail"] {
                completion(.failure(.serverError(detail)))
            }
        } else {
            completion(.failure(.decodingError))
        }
    }.resume()
}
