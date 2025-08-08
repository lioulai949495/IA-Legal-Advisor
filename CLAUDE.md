# Claude Code 项目记忆

## 项目信息
- **项目名称**: IAAdvisor2 - iOS法律咨询应用
- **项目路径**: `/Users/snake/Desktop/应用/IAAdvisor2`
- **项目类型**: iOS SwiftUI 应用
- **主要功能**: 法律咨询、案件流程指导、AI分析、多认证登录、支付集成

## 自动化工作流程

### **核心原则：所有对话行为自动通过项目经理调用其他相关角色执行**

#### **统一工作流程模式**
**所有用户请求都遵循以下自动化流程**：

1. **项目经理总控制** 
   - 自动分析用户请求类型和复杂度
   - 决定需要调用哪些专业角色
   - 协调多个角色之间的工作

2. **专业角色自动分派**
   - **代码问题** → 自动调用 `code-reviewer-fixer`
   - **功能开发** → 自动调用 `fullstack-developer` 或 `backend-developer`
   - **UI设计** → 自动调用 `ui-designer`  
   - **市场分析** → 自动调用 `market-operations-analyst`
   - **复合任务** → 自动调用多个相关角色

3. **质量保证**
   - 每个任务完成后自动调用 `code-reviewer-fixer` 进行质量检查
   - 确保所有工作符合项目标准

### 错误修复流程 - 自动调用代码审查
当遇到编译错误或代码问题时，**自动执行以下流程**：

1. **立即调用代码审查修复代理**
   - 使用 `code-reviewer-fixer` 子代理
   - 提供详细的错误信息和上下文
   - 要求系统性解决所有相关问题

2. **错误类型识别**
   - Swift编译错误 (`Command SwiftCompile failed`)
   - 类型冲突和歧义性问题
   - MainActor隔离问题  
   - 语法错误和警告
   - 依赖关系问题

3. **修复策略**
   - 保持现有架构完整性
   - 确保类型安全和线程安全
   - 维护现有API契约
   - 测试编译成功

### 功能开发流程 - 自动项目管理
对于任何功能开发或修改请求：
1. **自动调用项目经理**进行需求分析和任务分解
2. **项目经理自动调用相应专业代理**执行具体工作
3. **自动调用代码审查**确保质量和一致性

## 技术栈信息
- **开发语言**: Swift 5.7+
- **UI框架**: SwiftUI
- **架构模式**: MVVM + Service Layer
- **并发模式**: async/await + @MainActor
- **数据持久化**: Core Data
- **网络请求**: URLSession with async/await
- **支付集成**: StoreKit 2.0
- **认证系统**: Multi-provider (Apple ID, WeChat, Alipay, Email, Phone)

## 核心服务架构
- `APIService`: 网络服务和API集成
- `AuthenticationService`: 多认证提供商集成
- `PaymentService`: 支付处理和StoreKit集成
- `CoreDataService`: 数据持久化
- `CaseWorkflowService`: 案件流程管理
- `EnhancedWorkflowService`: 增强工作流编排
- `DocumentGenerationService`: 文档生成服务
- `AgentService`: AI代理协调服务

## 常见问题和解决方案

### 1. MainActor隔离问题
- **问题**: 主actor隔离的初始化器在非隔离上下文调用
- **解决**: 添加`@MainActor`注解或使用懒加载

### 2. 类型冲突问题
- **问题**: 多个文件定义相同类型名称
- **解决**: 重命名冲突类型，使用模块前缀

### 3. Swift关键字冲突
- **问题**: 使用Swift保留关键字作为标识符
- **解决**: 重命名为有效标识符（如`static` → `staticTemplate`）

### 4. StoreKit集成问题  
- **问题**: StoreKit.Transaction类型冲突
- **解决**: 明确指定命名空间或重命名自定义类型

## 项目状态
- ✅ 基础架构完成
- ✅ 多认证系统完成  
- ✅ 支付系统完成
- ✅ 法律案件流程系统完成
- ✅ 所有编译错误已修复
- ⏳ Core Data模型文件待创建
- ⏳ 第三方SDK集成待完成
- ⏳ App Store准备工作待完成

## 开发日志位置
- 主开发日志: `/Users/snake/Desktop/应用/IAAdvisor2/DEVELOPMENT_LOG.md`
- 任务追踪: 使用TodoWrite工具维护

## 重要提醒

### 🤖 **核心自动化原则**
⚠️ **所有对话行为自动通过项目经理调用其他相关角色执行**：
- **任何用户请求**都先通过项目经理(`project-manager`)进行分析和协调
- **项目经理自动决定**需要调用哪些专业角色（开发者、设计师、分析师等）
- **确保工作流程标准化**和最佳实践的执行

### ⚡ **自动化错误修复**
- 当用户报告编译错误或代码问题时，立即调用`code-reviewer-fixer`代理进行系统性修复
- 而不是尝试手动修复单个问题，这确保了全面性和一致性

### 🎯 **新增后端开发能力**
- 项目现已支持`backend-developer`角色，用于后端相关开发任务
- 可处理服务器端代码、API开发、数据库设计等后端需求