import SwiftUI

// --- 数据模型 ---
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
}

struct ChatOption: Identifiable, Hashable {
    let id = UUID()
    let text: String
}

// 对话状态枚举
enum ChatState {
    case initial, selectingRole, selectingSubtype, finalAnalysis, showingReport
}

// --- 聊天主视图 ---
struct ChatView: View {
    @Binding var authToken: String
    
    // --- 状态变量 ---
    @State private var messages: [ChatMessage] = []
    @State private var options: [ChatOption] = []
    @State private var isLoading: Bool = false
    @State private var currentState: ChatState = .initial
    @State private var finalReport: AnalysisReport?
    
    // 存储用户选择的上下文
    @State private var selectedCategory: String = ""
    @State private var selectedRole: String = ""
    @State private var selectedSubtype: String = ""
    @State private var userFinalMessage: String = ""

    var body: some View {
        VStack {
            // 聊天消息列表
            ScrollViewReader { scrollView in
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(messages) { message in
                            MessageView(message: message)
                                .id(message.id)
                        }
                        // 显示最终分析报告
                        if let report = finalReport {
                            AnalysisReportView(report: report)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    // 自动滚动到底部
                    if let lastMessage = messages.last {
                        withAnimation {
                            scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // 选项按钮 / 最终输入框
            if !options.isEmpty {
                OptionsView(options: $options, onSelect: handleOptionSelection)
            } else if currentState == .finalAnalysis {
                FinalInputView(userFinalMessage: $userFinalMessage, onSend: getFinalAnalysisReport)
            }
            
            if isLoading {
                ProgressView().padding()
            }
        }
        .navigationTitle("AI法律顾问")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: startNewChat)
    }
    
    // --- 核心逻辑 ---
    
    func handleResponse(_ response: ApiResponse) {
        if let responseText = response.response {
            messages.append(ChatMessage(text: responseText, isFromUser: false))
        }
        if let optionStrings = response.options {
            self.options = optionStrings.map { ChatOption(text: $0) }
        }
        if let report = response.analysis_report {
            self.finalReport = report
            self.currentState = .showingReport
        }
    }
    
    func handleError(_ error: NetworkError) {
        let errorMessage = "发生错误: \(error.localizedDescription)"
        messages.append(ChatMessage(text: errorMessage, isFromUser: false))
    }
    
    func startNewChat() {
        isLoading = true
        startChat(token: authToken) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    handleResponse(response)
                    currentState = .selectingRole
                case .failure(let error):
                    handleError(error)
                }
            }
        }
    }
    
    func handleOptionSelection(option: ChatOption) {
        messages.append(ChatMessage(text: option.text, isFromUser: true))
        self.options = [] // 清空选项
        isLoading = true
        
        switch currentState {
        case .selectingRole:
            selectedCategory = option.text
            getRoles(category: selectedCategory, token: authToken) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case .success(let response): 
                        handleResponse(response)
                        currentState = .selectingSubtype
                    case .failure(let error): handleError(error)
                    }
                }
            }
        case .selectingSubtype:
            selectedRole = option.text
            getSubtypes(category: selectedCategory, role: selectedRole, token: authToken) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case .success(let response): 
                        handleResponse(response)
                        currentState = .finalAnalysis
                    case .failure(let error): handleError(error)
                    }
                }
            }
        case .finalAnalysis:
            selectedSubtype = option.text
            messages.append(ChatMessage(text: "请在下方输入框中，详细描述您的情况，然后点击发送。", isFromUser: false))
        default:
            break
        }
    }
    
    func getFinalAnalysisReport() {
        messages.append(ChatMessage(text: userFinalMessage, isFromUser: true))
        let messageToSend = userFinalMessage
        self.userFinalMessage = ""
        isLoading = true
        
        getFinalAnalysis(category: selectedCategory, role: selectedRole, subtype: selectedSubtype, message: messageToSend, token: authToken) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response): handleResponse(response)
                case .failure(let error): handleError(error)
                }
            }
        }
    }
}

// --- 子视图 ---

struct MessageView: View {
    let message: ChatMessage
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                Text(message.text)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            } else {
                Text(message.text)
                    .padding(12)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(15)
                Spacer()
            }
        }
    }
}

struct OptionsView: View {
    @Binding var options: [ChatOption]
    let onSelect: (ChatOption) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(options) {
                    option in
                    Button(action: { onSelect(option) }) {
                        Text(option.text)
                            .padding()
                            .background(Color.green.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                    }
                }
            }
            .padding()
        }
        .frame(height: 80)
    }
}

struct FinalInputView: View {
    @Binding var userFinalMessage: String
    let onSend: () -> Void
    
    var body: some View {
        HStack {
            TextField("详细描述您的情况...", text: $userFinalMessage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.leading)
            
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.largeTitle)
            }
            .padding(.trailing)
        }
        .padding(.vertical, 5)
    }
}

struct AnalysisReportView: View {
    let report: AnalysisReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("AI分析报告")
                .font(.headline).bold()
            
            ReportSection(title: "适用法规", content: report.applicable_laws)
            ReportSection(title: "胜诉率分析 (仅供参考)", content: "\(report.success_rate_analysis.rate)% - \(report.success_rate_analysis.reason)")
            ReportSection(title: "行动建议", content: report.action_suggestion)
            ReportSection(title: "后续步骤", content: "\(report.next_steps.process_guidance)\n所需文书: \(report.next_steps.document_templates)")
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ReportSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline).bold()
                .foregroundColor(.secondary)
            Text(content)
                .font(.body)
        }
    }
}
