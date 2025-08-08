# AI Agent 系统使用指南

## 概述

此 AI Agent 系统为 IAAdvisor2 法律咨询应用提供了智能化的法律服务。系统包含 6 种专业 Agent，可以处理各类法律问题和任务。

## 系统架构

```
AgentService (管理层)
    ├── LegalConsultantAgent (法律咨询师)
    ├── CaseAnalystAgent (案件分析师)
    ├── DocumentGeneratorAgent (文档生成器)
    ├── RiskAssessorAgent (风险评估师)
    ├── ContractReviewerAgent (合同审查师)
    └── LitigationAdvisorAgent (诉讼顾问)
```

## Agent 类型说明

### 🔍 法律咨询师 (LegalConsultantAgent)
- **功能**：回答各类法律问题，提供专业法律建议
- **适用场景**：一般法律咨询、法规解释、权利义务说明
- **示例**：合同条款解释、法律程序咨询

### 📊 案件分析师 (CaseAnalystAgent) 
- **功能**：分析案件强度、识别法律问题、制定策略
- **适用场景**：案件评估、胜诉概率分析、法律策略制定
- **示例**：劳动争议案件强度评估、合同纠纷策略建议

### 📝 文档生成器 (DocumentGeneratorAgent)
- **功能**：生成各类法律文书和合同
- **支持文档**：起诉书、答辩书、合同、律师函、申请书等
- **示例**：劳动合同生成、律师函起草

### ⚠️ 风险评估师 (RiskAssessorAgent)
- **功能**：识别法律风险、制定缓解策略
- **风险类型**：法律、财务、操作、声誉、监管风险
- **示例**：合同签署风险评估、诉讼风险分析

### 📋 合同审查师 (ContractReviewerAgent)
- **功能**：审查合同条款、识别风险条款、提供修改建议
- **审查范围**：条款合理性、合规性、风险识别
- **示例**：劳动合同审查、商务合同条款分析

### ⚖️ 诉讼顾问 (LitigationAdvisorAgent)
- **功能**：诉讼策略制定、程序指导、胜诉概率分析
- **服务内容**：诉讼规划、庭审准备、成本效益分析
- **示例**：民事诉讼策略、证据收集计划

## 快速开始

### 1. 基本使用

```swift
import Foundation

// 获取 Agent 服务
let agentService = AgentService.shared

// 创建请求
let request = AgentRequest(
    id: UUID().uuidString,
    agentType: .legalConsultant,
    caseType: .contractDispute,
    content: "我的合同有什么风险？",
    context: nil,
    priority: .normal,
    createdAt: Date()
)

// 发送请求
let response = try await agentService.sendRequest(request)
print("AI 回复：\(response.content)")
```

### 2. 自动选择 Agent

```swift
// 系统自动选择最适合的 Agent
let response = try await agentService.sendRequestToBestAgent(
    caseType: .laborDispute,
    content: "公司拖欠工资，我该怎么办？",
    context: nil
)
```

### 3. 带上下文的复杂请求

```swift
// 创建案件详情
let caseDetails = CaseDetails(
    title: "劳动合同纠纷",
    description: "公司违反劳动合同条款",
    caseType: .laborDispute,
    documents: ["劳动合同.pdf"],
    timeline: [...],
    involvedParties: [...]
)

// 创建上下文
let context = AgentContext(
    caseId: "case123",
    userId: "user456", 
    previousMessages: nil,
    caseDetails: caseDetails,
    userPreferences: nil
)

// 发送带上下文的请求
let request = AgentRequest(
    id: UUID().uuidString,
    agentType: .caseAnalyst,
    caseType: .laborDispute,
    content: "请分析这个案件的胜诉概率",
    context: context,
    priority: .high,
    createdAt: Date()
)
```

## 响应结构

每个 Agent 的响应都包含以下信息：

```swift
struct AgentResponse {
    let content: String              // 主要回复内容
    let confidence: Double           // 置信度 (0-1)
    let recommendations: [Recommendation]?  // 具体建议
    let attachments: [AgentAttachment]?     // 相关附件
    let followUpQuestions: [String]?        // 后续问题
    let processingTime: TimeInterval        // 处理时间
}
```

## 系统监控

### 获取性能指标

```swift
let summary = await agentService.getAllMetricsSummary()
print("成功率：\(summary.successRate)")
print("平均响应时间：\(summary.averageResponseTime)")
```

### 健康检查

```swift
// 检查特定 Agent 的健康状态
if let health = agentService.agentHealth["legal-consultant-001"] {
    print("Agent 状态：\(health.status)")
}
```

## 最佳实践

### 1. 选择合适的 Agent
- **一般咨询** → LegalConsultantAgent
- **案件评估** → CaseAnalystAgent  
- **文档需求** → DocumentGeneratorAgent
- **风险关注** → RiskAssessorAgent
- **合同相关** → ContractReviewerAgent
- **诉讼准备** → LitigationAdvisorAgent

### 2. 提供详细上下文
- 尽量提供完整的案件信息
- 包含相关文档和时间线
- 说明用户的具体需求和偏好

### 3. 处理响应
- 检查置信度，低置信度时建议寻求人工帮助
- 利用推荐建议制定行动计划
- 使用后续问题深入了解问题

### 4. 错误处理

```swift
do {
    let response = try await agentService.sendRequest(request)
    // 处理成功响应
} catch AgentServiceError.agentNotFound(let type) {
    print("未找到 \(type) 类型的代理")
} catch AgentServiceError.requestFailed(let error) {
    print("请求失败：\(error)")
} catch {
    print("其他错误：\(error)")
}
```

## 扩展开发

### 添加新的 Agent 类型

1. 在 `AgentType` 枚举中添加新类型
2. 创建实现 `AIAgent` 协议的新类
3. 在 `AgentService` 中注册新 Agent
4. 更新相关的业务逻辑

### 自定义 Agent 行为

可以通过 `AgentConfiguration` 自定义 Agent 的行为：

```swift
let config = AgentConfiguration(
    agentId: "custom-agent",
    maxConcurrentRequests: 5,
    responseTimeoutSeconds: 30,
    confidenceThreshold: 0.8,
    enabledFeatures: [.caseAnalysis, .riskAssessment],
    customPrompts: ["greeting": "您好，我是专业法律顾问"]
)
```

## 注意事项

1. **数据安全**：所有敏感信息都经过加密处理
2. **响应时间**：复杂请求可能需要更长处理时间
3. **置信度**：建议对低置信度响应进行人工审核
4. **更新频率**：定期更新 Agent 的知识库和模型

## 联系支持

如有技术问题或需要帮助，请联系开发团队。

---

*此文档随系统更新而更新，请关注最新版本。*