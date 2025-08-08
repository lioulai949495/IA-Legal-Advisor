import SwiftUI

struct AIChatView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var messageText = ""
    @State private var isFirstAppear = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                // 内容
                VStack(spacing: 0) {
                    // 聊天内容区域
                    ScrollView {
                        ScrollViewReader { proxy in
                            VStack(spacing: 0) {
                                // 欢迎信息
                                if viewModel.aiChatMessages.isEmpty {
                                    welcomeView
                                        .padding(.top, 5)
                                        .id("welcome")
                                }
                                
                                // 消息列表
                                LazyVStack(spacing: 16) {
                                    ForEach(viewModel.aiChatMessages) { message in
                                        MessageBubbleView(message: message)
                                            .id(message.id)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 20)
                                
                                // 底部填充，确保最后一条消息可以完全滚动到可见区域
                                Color.clear.frame(height: 80)
                            }
                            .onChange(of: viewModel.aiChatMessages.count) { _ in
                                if let lastMessageId = viewModel.aiChatMessages.last?.id {
                                    withAnimation {
                                        proxy.scrollTo(lastMessageId, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 10)
                    .padding(.top, geometry.safeAreaInsets.top + 44) // 为状态栏和导航栏预留空间
                    
                    // 输入区域 - 简化设计确保显示
                    HStack(alignment: .bottom) {
                        // 语音输入按钮
                        Button(action: {}) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.accentColor)
                        }
                        .padding(8)
                        
                        // 文本输入框
                        ZStack(alignment: .leading) {
                            if messageText.isEmpty {
                                Text("询问任何法律问题...")
                                    .foregroundColor(.gray)
                                    .padding(.leading, 5)
                                    .padding(.top, 8)
                            }
                            
                            TextEditor(text: $messageText)
                                .padding(5)
                                .background(Color.clear)
                                .frame(minHeight: 40, maxHeight: 120)
                                .foregroundColor(Color(.label))
                                .background(Color.clear)
                                .hideTextEditorBackground()
                        }
                        .liquidGlass(opacity: 0.6, cornerRadius: 18)
                        
                        // 发送按钮
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(messageText.isEmpty ? .gray : AppTheme.accentColor)
                        }
                        .disabled(messageText.isEmpty || viewModel.isLoading)
                        .padding(.horizontal, 8)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.2))
                    .background(Material.ultraThinMaterial)
                    .padding(.bottom, 0)
                }
                
                // 加载指示器
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
                
                // 顶部导航栏 - 简单设计
                VStack(spacing: 0) {
                    // 系统状态栏占位
                    Color.clear
                        .frame(height: geometry.safeAreaInsets.top)
                    
                    // 导航栏内容
                    ZStack {
                        // 简单背景
                        Color.black.opacity(0.3)
                        
                        HStack {
                            Spacer()
                            
                            // 标题
                            Text("AI法律咨询")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // 菜单按钮
                            Menu {
                                Button(action: clearChat) {
                                    Label("清空对话", systemImage: "trash")
                                }
                                
                                Button(action: {}) {
                                    Label("创建案件", systemImage: "folder.badge.plus")
                                }
                                
                                Button(action: {}) {
                                    Label("保存记录", systemImage: "square.and.arrow.down")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                            .padding(.trailing, 16)
                        }
                    }
                    .frame(height: 44)
                    
                    Spacer()
                }
                .background(Color.black.opacity(0.2))
            }
        }
        .onAppear {
            if isFirstAppear && viewModel.aiChatMessages.isEmpty {
                // 添加AI欢迎消息
                isFirstAppear = false
                
                // 确保创建的欢迎消息是AI消息，并且有正确的时间戳
                let welcomeMessage = Message(
                    id: UUID().uuidString,
                    content: "您好，我是IA法律顾问。您可以向我咨询任何法律问题，我会尽力为您提供专业解答和建议。",
                    createdAt: Date(),
                    isFromAI: true,
                    attachments: nil,
                    documentLinks: nil
                )
                
                // 添加到消息列表
                viewModel.aiChatMessages.append(welcomeMessage)
                
                // 短暂延迟确保UI更新
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let lastMessageId = viewModel.aiChatMessages.last?.id {
                        // 滚动到最新消息
                    }
                }
            }
        }
    }
    
    // 欢迎视图
    private var welcomeView: some View {
        VStack(spacing: 20) {
            // Logo和标题
            VStack(spacing: 12) {
                Image(systemName: "scale.3d")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        Circle()
                            .fill(AppTheme.secondaryColor.opacity(0.2))
                            .frame(width: 120, height: 120)
                    )
                    .background(Material.ultraThinMaterial)
                
                Text("IA法律顾问")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text("您的私人法律智能助手")
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // 问题推荐
            VStack(spacing: 15) {
                Text("您可以询问:")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(suggestedQuestions, id: \.self) { question in
                    Button(action: { askSuggestedQuestion(question) }) {
                        Text(question)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.secondaryColor.opacity(0.3))
                            )
                            .background(Material.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            }
            .padding()
            .liquidGlass(opacity: 0.5)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
    
    // 发送消息
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        viewModel.sendMessageToAI(content: messageText)
        messageText = ""
    }
    
    // 清空对话
    private func clearChat() {
        viewModel.aiChatMessages = []
        isFirstAppear = true
        
        // 添加新的欢迎消息
        let welcomeMessage = Message(
            id: UUID().uuidString,
            content: "对话已清空。您可以继续向我咨询任何法律问题。",
            createdAt: Date(),
            isFromAI: true,
            attachments: nil,
            documentLinks: nil
        )
        viewModel.aiChatMessages.append(welcomeMessage)
    }
    
    // 询问建议问题
    private func askSuggestedQuestion(_ question: String) {
        messageText = question
        sendMessage()
    }
    
    // 建议问题列表
    private var suggestedQuestions: [String] = [
        "我被欠薪了，该如何维权？",
        "如何办理房产过户手续？",
        "交通事故责任如何划分？",
        "婚姻财产分割的法律规定是什么？",
        "企业知识产权保护有哪些途径？"
    ]
}

#Preview {
    AIChatView()
        .environmentObject(AppViewModel())
} 