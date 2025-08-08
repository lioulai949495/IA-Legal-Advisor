import Foundation

/// Agent 系统使用示例
/// 这个文件展示了如何使用 AI Agent 系统
class AgentExampleUsage {
    
    private let agentService = AgentService.shared
    
    /// 示例：使用法律咨询助手
    func exampleLegalConsultation() async throws {
        let request = AgentRequest(
            id: UUID().uuidString,
            agentType: .legalConsultant,
            caseType: .contractDispute,
            content: "我与公司签订的劳动合同中有一些条款不太理解，想咨询一下相关的法律问题。",
            context: nil,
            priority: .normal,
            createdAt: Date()
        )
        
        let response = try await agentService.sendRequest(request)
        print("法律咨询回复：\(response.content)")
    }
    
    /// 示例：使用案件分析师
    func exampleCaseAnalysis() async throws {
        // 创建案件详情
        let caseDetails = CaseDetails(
            id: "case-001",
            title: "劳动合同纠纷案件",
            description: "公司未按时支付工资并强制加班",
            caseType: .laborDispute,
            status: .active,
            documents: ["劳动合同.pdf", "工资条.jpg"],
            timeline: [
                CaseEvent(
                    id: "event1",
                    date: Date().addingTimeInterval(-86400 * 30),
                    description: "签订劳动合同",
                    importance: .medium
                )
            ],
            involvedParties: [
                Party(
                    id: "party1",
                    name: "张某",
                    role: .plaintiff,
                    contactInfo: "138****8888"
                )
            ],
            createdAt: Date().addingTimeInterval(-86400 * 45),
            lastUpdatedAt: Date().addingTimeInterval(-86400 * 2)
        )
        
        let context = AgentContext(
            caseId: "case1",
            userId: "user1",
            previousMessages: nil,
            caseDetails: caseDetails,
            userPreferences: nil
        )
        
        let request = AgentRequest(
            id: UUID().uuidString,
            agentType: .caseAnalyst,
            caseType: .laborDispute,
            content: "请分析这个劳动争议案件的强度和胜诉概率",
            context: context,
            priority: .high,
            createdAt: Date()
        )
        
        let response = try await agentService.sendRequest(request)
        print("案件分析结果：\(response.content)")
    }
    
    /// 示例：使用文档生成器
    func exampleDocumentGeneration() async throws {
        let request = AgentRequest(
            id: UUID().uuidString,
            agentType: .documentGenerator,
            caseType: .contractDispute,
            content: "请帮我生成一份针对合同纠纷的律师函",
            context: nil,
            priority: .normal,
            createdAt: Date()
        )
        
        let response = try await agentService.sendRequest(request)
        print("生成的文档：\(response.content)")
        
        // 检查附件中的文档
        if let attachments = response.attachments {
            for attachment in attachments {
                if attachment.type == .document {
                    print("文档附件：\(attachment.name)")
                }
            }
        }
    }
    
    /// 示例：使用风险评估师
    func exampleRiskAssessment() async throws {
        let request = AgentRequest(
            id: UUID().uuidString,
            agentType: .riskAssessor,
            caseType: .contractDispute,
            content: "请评估这个合同纠纷案件的各类风险",
            context: nil,
            priority: .high,
            createdAt: Date()
        )
        
        let response = try await agentService.sendRequest(request)
        print("风险评估报告：\(response.content)")
        
        // 检查风险缓解建议
        if let recommendations = response.recommendations {
            print("风险缓解建议：")
            for recommendation in recommendations {
                print("- \(recommendation.title): \(recommendation.description)")
            }
        }
    }
    
    /// 示例：自动选择最佳 Agent
    func exampleAutomaticAgentSelection() async throws {
        let response = try await agentService.sendRequestToBestAgent(
            caseType: .divorceDispute,
            content: "我想了解离婚财产分割的相关法律规定",
            context: nil,
            priority: .normal
        )
        
        print("自动选择的 Agent 回复：\(response.content)")
    }
    
    /// 示例：获取 Agent 性能指标
    func exampleAgentMetrics() async {
        let summary = await agentService.getAllMetricsSummary()
        
        print("Agent 系统概览：")
        print("- 总代理数：\(summary.totalAgents)")
        print("- 活跃代理数：\(summary.activeAgents)")
        print("- 总请求数：\(summary.totalRequests)")
        print("- 成功率：\(String(format: "%.1f", summary.successRate * 100))%")
        print("- 平均响应时间：\(String(format: "%.2f", summary.averageResponseTime))秒")
        print("- 平均置信度：\(String(format: "%.1f", summary.averageConfidence * 100))%")
    }
    
    /// 运行所有示例
    func runAllExamples() async {
        print("🤖 AI Agent 系统使用示例")
        print(String(repeating: "=", count: 50))
        
        do {
            print("\n📋 1. 法律咨询示例")
            try await exampleLegalConsultation()
            
            print("\n📊 2. 案件分析示例")  
            try await exampleCaseAnalysis()
            
            print("\n📝 3. 文档生成示例")
            try await exampleDocumentGeneration()
            
            print("\n⚠️ 4. 风险评估示例")
            try await exampleRiskAssessment()
            
            print("\n🎯 5. 自动选择 Agent 示例")
            try await exampleAutomaticAgentSelection()
            
            print("\n📈 6. Agent 性能指标")
            await exampleAgentMetrics()
            
        } catch {
            print("❌ 示例执行出错：\(error)")
        }
    }
}