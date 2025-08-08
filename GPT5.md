# GPT5 开发日志

- 项目：IAAdvisor2（iOS SwiftUI）+ FastAPI 后端
- 目标：不改UI/功能设计前提下完成上线所需的后端与集成，尽快上架并产生收入
- 约束：用户不具备开发能力，无资金；我主导开发，用户按指令执行外部操作

## 团队与职责
- 项目经理（PM）：统筹进度、里程碑、风险
- 全栈开发：端到端实现/联调，保证契约一致
- 后端开发：API、模型、鉴权、部署、监控
- UI 开发：保持现有 UI，不改视觉，仅修复兼容问题
- 市场分析：定价、转化漏斗与打点指标建议
- 代码审查：契约一致性、可维护性与测试
- 法务顾问：合规、隐私条款与用户协议校验
- 行为指挥：指导用户进行 Render/GitHub/TestFlight 等操作

## 关键决策
- 鉴权：Bearer Token（后端开发期为 fake-token-for-<phone>），后续 JWT
- AI：现用免费模型（Gemini 轨迹），统一结构化输出 `analysis_report`
- 后端：Render 免费服务；Neon Postgres；增加 `/health` 预热
- 客户端：SwiftUI + MVVM；接口契约统一到 `OptionsResponse` 与 `AnalysisReportResponse`
- 记忆：不改变现有 UI/功能结构，仅补齐功能

## 已完成
- Render/Neon 配置与部署；/health 可用
- 登录：短信模拟 + 开发期通用验证码 000000；修复误登录
- iOS：修复编译错误；统一接口调用与解析；修复多个 Agent 的契约

## 待办（近期）
- 后端最小数据：用户资料、案件、消息（/profile, /cases, /documents 只做最小化）
- 鉴权收紧与限流；基础监控
- 端到端用例：引导式对话至报告
- TestFlight 构建与元数据

## 变更记录
- 2025-08-08：修复 iOS 多处编译错误，统一 `AnalysisReportResponse`；登录逻辑收紧；后端允许 000000 测试码 