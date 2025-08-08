import Foundation
import SwiftUI

/// 网络测试辅助工具
@MainActor
class NetworkTestHelper: ObservableObject {
    @Published var testResults: [TestResult] = []
    @Published var isRunningTests = false
    
    struct TestResult: Identifiable {
        let id = UUID()
        let testName: String
        let success: Bool
        let message: String
        let duration: TimeInterval
        let timestamp: Date
    }
    
    /// 运行全套网络测试
    func runNetworkTests() async {
        guard !isRunningTests else { return }
        
        isRunningTests = true
        testResults = []
        
        // 测试1：基础连通性
        await testBasicConnectivity()
        
        // 测试2：服务器预热
        await testServerWarmup()
        
        // 测试3：发送验证码API
        await testSendCodeAPI()
        
        // 测试4：登录API（使用测试数据）
        await testLoginAPI()
        
        isRunningTests = false
    }
    
    private func testBasicConnectivity() async {
        let testName = "基础网络连通性"
        let startTime = Date()
        
        do {
            let url = URL(string: "https://ia-legal-advisor.onrender.com")!
            let (_, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                let duration = Date().timeIntervalSince(startTime)
                let success = httpResponse.statusCode < 500
                let message = success ? 
                    "连接成功，状态码: \(httpResponse.statusCode)" : 
                    "服务器错误，状态码: \(httpResponse.statusCode)"
                
                testResults.append(TestResult(
                    testName: testName,
                    success: success,
                    message: message,
                    duration: duration,
                    timestamp: Date()
                ))
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            testResults.append(TestResult(
                testName: testName,
                success: false,
                message: "连接失败: \(error.localizedDescription)",
                duration: duration,
                timestamp: Date()
            ))
        }
    }
    
    private func testServerWarmup() async {
        let testName = "服务器预热测试"
        let startTime = Date()
        
        await APIService.shared.warmupServer()
        let duration = Date().timeIntervalSince(startTime)
        
        let success = duration < 60.0 // 如果预热超过60秒认为有问题
        let message = success ? 
            "预热成功，耗时: \(String(format: "%.2f", duration))秒" :
            "预热缓慢，耗时: \(String(format: "%.2f", duration))秒 (可能需要冷启动)"
        
        testResults.append(TestResult(
            testName: testName,
            success: success,
            message: message,
            duration: duration,
            timestamp: Date()
        ))
    }
    
    private func testSendCodeAPI() async {
        let testName = "发送验证码API"
        let startTime = Date()
        
        do {
            // 使用测试手机号
            try await APIService.shared.sendCode(phone: "13800138000")
            let duration = Date().timeIntervalSince(startTime)
            
            testResults.append(TestResult(
                testName: testName,
                success: true,
                message: "API调用成功，耗时: \(String(format: "%.2f", duration))秒",
                duration: duration,
                timestamp: Date()
            ))
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            let message: String
            
            if let apiError = error as? APIError {
                switch apiError {
                case .serverColdStart:
                    message = "服务器冷启动检测到，耗时: \(String(format: "%.2f", duration))秒"
                case .timeout:
                    message = "请求超时，耗时: \(String(format: "%.2f", duration))秒"
                default:
                    message = "API错误: \(apiError.localizedDescription)"
                }
            } else {
                message = "未知错误: \(error.localizedDescription)"
            }
            
            testResults.append(TestResult(
                testName: testName,
                success: false,
                message: message,
                duration: duration,
                timestamp: Date()
            ))
        }
    }
    
    private func testLoginAPI() async {
        let testName = "登录API测试"
        let startTime = Date()
        
        do {
            // 使用测试数据（这会失败，但可以测试API响应）
            let _ = try await APIService.shared.login(phone: "13800138000", code: "123456")
            let duration = Date().timeIntervalSince(startTime)
            
            testResults.append(TestResult(
                testName: testName,
                success: true,
                message: "意外成功（测试数据）",
                duration: duration,
                timestamp: Date()
            ))
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            let message: String
            
            if let apiError = error as? APIError {
                switch apiError {
                case .unauthorized:
                    message = "正常响应：验证码错误（API正常工作）"
                case .serverColdStart:
                    message = "服务器冷启动，耗时: \(String(format: "%.2f", duration))秒"
                case .timeout:
                    message = "登录API超时，耗时: \(String(format: "%.2f", duration))秒"
                default:
                    message = "API错误: \(apiError.localizedDescription)"
                }
            } else {
                message = "网络错误: \(error.localizedDescription)"
            }
            
            // 对于401错误（验证码错误），这实际上是成功的，因为说明API正常响应
            let success = message.contains("验证码错误")
            
            testResults.append(TestResult(
                testName: testName,
                success: success,
                message: message,
                duration: duration,
                timestamp: Date()
            ))
        }
    }
    
    /// 生成测试报告
    func generateTestReport() -> String {
        let successCount = testResults.filter { $0.success }.count
        let totalTests = testResults.count
        let averageDuration = testResults.reduce(0.0) { $0 + $1.duration } / Double(totalTests)
        
        var report = """
        网络测试报告
        ================
        
        总体结果: \(successCount)/\(totalTests) 项测试通过
        平均响应时间: \(String(format: "%.2f", averageDuration))秒
        测试时间: \(DateFormatter.reportFormatter.string(from: Date()))
        
        详细结果:
        
        """
        
        for result in testResults {
            let status = result.success ? "✅" : "❌"
            report += """
            \(status) \(result.testName)
               结果: \(result.message)
               耗时: \(String(format: "%.2f", result.duration))秒
               时间: \(DateFormatter.reportFormatter.string(from: result.timestamp))
            
            """
        }
        
        report += """
        
        建议:
        """
        
        if testResults.allSatisfy({ $0.success }) {
            report += "✅ 所有测试通过，网络连接正常"
        } else {
            let slowTests = testResults.filter { $0.duration > 30.0 }
            if !slowTests.isEmpty {
                report += "⚠️  检测到慢响应，可能是服务器冷启动造成"
            }
            
            let failedTests = testResults.filter { !$0.success }
            if !failedTests.isEmpty {
                report += "\n❌ 部分测试失败，请检查网络连接或联系技术支持"
            }
        }
        
        return report
    }
}

// MARK: - 测试界面视图

struct NetworkTestView: View {
    @StateObject private var testHelper = NetworkTestHelper()
    @State private var showReport = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 测试状态
                    if testHelper.isRunningTests {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("正在运行网络测试...")
                                .font(.headline)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // 测试结果
                    if !testHelper.testResults.isEmpty {
                        LazyVStack(spacing: 12) {
                            ForEach(testHelper.testResults) { result in
                                TestResultCard(result: result)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("网络测试")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("开始测试") {
                        Task {
                            await testHelper.runNetworkTests()
                        }
                    }
                    .disabled(testHelper.isRunningTests)
                    
                    if !testHelper.testResults.isEmpty {
                        Button("查看报告") {
                            showReport = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showReport) {
                TestReportView(report: testHelper.generateTestReport())
            }
        }
    }
}

struct TestResultCard: View {
    let result: NetworkTestHelper.TestResult
    
    var body: some View {
        HStack {
            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.success ? .green : .red)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.testName)
                    .font(.headline)
                
                Text(result.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("耗时: \(String(format: "%.2f", result.duration))秒")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(result.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TestReportView: View {
    let report: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(report)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            .navigationTitle("测试报告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - DateFormatter 扩展

private extension DateFormatter {
    static let reportFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}

#Preview {
    NetworkTestView()
}