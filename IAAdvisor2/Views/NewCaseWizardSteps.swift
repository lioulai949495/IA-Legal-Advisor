import SwiftUI

// MARK: - 新建案件流程的7个步骤视图

extension NewCaseWizard {
    
    // MARK: - 步骤1：案件名称
    var caseTitleStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // 步骤头部
                VStack(alignment: .leading, spacing: 8) {
                    Text("步骤 1/7")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("案件名称")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text("为您的案件起一个简洁明了的名称")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // 输入区域
                VStack(alignment: .leading, spacing: 16) {
                    Text("请输入案件名称")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("例如：劳动合同纠纷、房屋买卖合同争议", text: $caseTitle)
                        .padding(16)
                        .background(Color.white.opacity(0.15))
                        .background(Material.ultraThinMaterial)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .font(.body)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .onSubmit {
                            hideKeyboard()
                        }
                    
                    Text("建议包含争议的核心内容，便于后续管理")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    // MARK: - 步骤2：案件类型
    var caseTypeStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // 步骤头部
                VStack(alignment: .leading, spacing: 8) {
                    Text("步骤 2/7")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("案件类型")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text("选择最符合您情况的案件类型")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // 案件类型选择
                VStack(alignment: .leading, spacing: 16) {
                    Text("请选择案件类型")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Button {
                        showingCaseTypeSelector = true
                    } label: {
                        HStack {
                            Image(systemName: selectedCaseType.icon)
                                .foregroundColor(selectedCaseType.category.color)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedCaseType.category.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(selectedCaseType.rawValue)
                                    .font(.body.bold())
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.15))
                        .background(Material.ultraThinMaterial)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    Text("选择正确的案件类型有助于IA为您提供更精准的法律建议")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    // MARK: - 步骤3：现在让我们来了解一些基本情况
    var iaQuestionStep: some View {
        VStack(spacing: 0) {
            // 问题进度
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("步骤 3/7")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    if !iaQuestions.isEmpty {
                        Text("问题 \(currentQuestionIndex + 1)/\(iaQuestions.count)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Text("现在让我们来了解一些基本情况")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text("我们将通过几个关键问题了解您案件的具体情况")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                
                if !iaQuestions.isEmpty {
                    ProgressView(value: Double(currentQuestionIndex + 1), total: Double(iaQuestions.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor))
                }
            }
            .padding()
            
            Spacer()
            
            // 当前问题
            if !iaQuestions.isEmpty && currentQuestionIndex < iaQuestions.count {
                let currentQuestion = iaQuestions[currentQuestionIndex]
                
                VStack(spacing: 30) {
                    // 问题文本
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.accentColor)
                        
                        Text(currentQuestion.question)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // 选项
                    VStack(spacing: 12) {
                        ForEach(currentQuestion.options, id: \.self) { option in
                            Button(option) {
                                selectAnswer(option, for: currentQuestion)
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isAnswerSelected(option, for: currentQuestion) ?
                                          AppTheme.accentColor.opacity(0.3) : Color.white.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isAnswerSelected(option, for: currentQuestion) ?
                                            AppTheme.accentColor : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                // 开始了解基本情况
                VStack(spacing: 30) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundColor(AppTheme.accentColor)
                    
                    VStack(spacing: 16) {
                        Text("准备就绪")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text("我们将根据您选择的案件类型，为您准备相关的情况了解问题")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                    // 移除重复按钮，统一使用底部导航按钮进行交互
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle")
                            .font(.title2)
                            .foregroundColor(AppTheme.accentColor.opacity(0.7))
                        
                        Text("点击底部按钮开始了解基本情况")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
    }
    
    // MARK: - 步骤4：案件描述和相关文档
    var descriptionAndDocumentsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // 步骤头部
                VStack(alignment: .leading, spacing: 8) {
                    Text("步骤 4/7")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("案件描述和相关文档")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text("详细描述您的情况并上传相关证据材料")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // 案件描述
                VStack(alignment: .leading, spacing: 16) {
                    Text("详细描述")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $caseDescription)
                            .frame(minHeight: 150)
                            .padding(12)
                            .background(Color.clear)
                            .foregroundColor(.white)
                            .font(.body)
                            .keyboardToolbar()
                        
                        if caseDescription.isEmpty {
                            Text("请详细描述您遇到的法律问题，包括：\n• 事件的时间、地点、经过\n• 涉及的当事人\n• 争议的核心问题\n• 您希望达到的目标")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                                .allowsHitTesting(false)
                        }
                    }
                    .background(Color.white.opacity(0.15))
                    .background(Material.ultraThinMaterial)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // 文档上传
                VStack(alignment: .leading, spacing: 16) {
                    Text("相关文档")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Button {
                        showingDocumentPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(AppTheme.accentColor)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("上传文档或照片")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                Text("合同、证据、通信记录等")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // 已上传文档列表
                    if !uploadedDocuments.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(uploadedDocuments) { document in
                                HStack {
                                    Image(systemName: document.type.icon)
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(document.name)
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                        Text(document.type.displayName)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        uploadedDocuments.removeAll { $0.id == document.id }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.title3)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    Text("上传相关文档有助于IA更准确地分析您的案件")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    // MARK: - 步骤5：专业分析结果
    var agentAnalysisStep: some View {
        VStack(spacing: 20) {
            // 步骤头部
            VStack(alignment: .leading, spacing: 8) {
                Text("步骤 5/6")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text("专业分析")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text("专业的AI法律助手正在分析您的案件")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal)
            
            if isAnalyzing {
                // 分析中状态
                VStack(spacing: 30) {
                    // 动画效果
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 4)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(AppTheme.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isAnalyzing)
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.accentColor)
                    }
                    
                    VStack(spacing: 16) {
                        Text("专业分析正在进行...")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        VStack(spacing: 8) {
                            Text("• 案件强度评估")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                            Text("• 法律风险识别")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                            Text("• 策略建议生成")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    startAgentAnalysis()
                }
            } else if let result = agentAnalysisResult {
                // 分析结果显示
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 案件强度评估
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "chart.pie.fill")
                                    .foregroundColor(.green)
                                Text("案件强度评估")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text(result.strengthLevel.rawValue)
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(result.strengthLevel.color)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("案件强度")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("置信度: \(Int(result.confidence * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Spacer()
                            }
                        }
                        .padding()
                        .liquidGlass()
                        
                        // 主要建议
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text("主要建议")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(result.recommendations, id: \.self) { recommendation in
                                    HStack(alignment: .top) {
                                        Text("•")
                                            .foregroundColor(AppTheme.accentColor)
                                        Text(recommendation)
                                            .font(.body)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                            }
                        }
                        .padding()
                        .liquidGlass()
                        
                        // 风险提示
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("风险提示")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(result.risks, id: \.self) { risk in
                                    HStack(alignment: .top) {
                                        Text("⚠️")
                                        Text(risk)
                                            .font(.body)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                            }
                        }
                        .padding()
                        .liquidGlass()
                    }
                    .padding()
                }
            } else {
                // 准备开始分析
                VStack(spacing: 30) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundColor(AppTheme.accentColor)
                    
                    VStack(spacing: 16) {
                        Text("准备就绪")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text("专业的AI法律助手将综合分析您的案件信息，为您提供案件强度评估、风险识别和策略建议")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                    // 移除重复按钮，统一使用底部导航按钮进行交互
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle")
                            .font(.title2)
                            .foregroundColor(AppTheme.accentColor.opacity(0.7))
                        
                        Text("点击底部按钮开始分析")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
    }
    
    // MARK: - 步骤6：生成案件流程
    var workflowGenerationStep: some View {
        VStack(spacing: 20) {
            // 步骤头部
            VStack(alignment: .leading, spacing: 8) {
                Text("步骤 6/7")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text("生成案件流程")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text("基于分析结果为您定制专业的处理流程")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal)
            
            if isGeneratingWorkflow {
                // 生成中状态
                VStack(spacing: 30) {
                    // 动画效果
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 4)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(AppTheme.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isGeneratingWorkflow)
                        
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.accentColor)
                    }
                    
                    VStack(spacing: 16) {
                        Text("正在生成处理流程...")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        VStack(spacing: 8) {
                            Text("• 制定处理步骤")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                            Text("• 规划时间节点")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                            Text("• 准备所需文档")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    generateWorkflow()
                }
            } else if !generatedWorkflow.isEmpty {
                // 显示生成的流程
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 流程概览
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "list.bullet.clipboard.fill")
                                    .foregroundColor(.blue)
                                Text("处理流程概览")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                VStack {
                                    Text("\(generatedWorkflow.count)")
                                        .font(.title.bold())
                                        .foregroundColor(AppTheme.accentColor)
                                    Text("处理步骤")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                VStack {
                                    Text("约\(generatedWorkflow.map { $0.estimatedDays }.reduce(0, +))天")
                                        .font(.title.bold())
                                        .foregroundColor(.green)
                                    Text("预计时间")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                            }
                        }
                        .padding()
                        .liquidGlass()
                        
                        // 流程步骤
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "timeline.selection")
                                    .foregroundColor(.orange)
                                Text("详细步骤")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(Array(generatedWorkflow.enumerated()), id: \.element.id) { index, step in
                                    HStack(alignment: .top, spacing: 16) {
                                        // 步骤编号
                                        ZStack {
                                            Circle()
                                                .fill(AppTheme.accentColor.opacity(0.2))
                                                .frame(width: 32, height: 32)
                                            Text("\(index + 1)")
                                                .font(.headline.bold())
                                                .foregroundColor(AppTheme.accentColor)
                                        }
                                        
                                        // 步骤内容
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(step.title)
                                                .font(.subheadline.bold())
                                                .foregroundColor(.white)
                                            
                                            Text(step.description)
                                                .font(.body)
                                                .foregroundColor(.white.opacity(0.8))
                                            
                                            Text("预计时间：\(step.estimatedDays)天")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                        .liquidGlass()
                    }
                    .padding()
                }
            } else {
                // 准备生成流程
                VStack(spacing: 30) {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppTheme.accentColor)
                    
                    VStack(spacing: 16) {
                        Text("准备生成处理流程")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text("基于IA分析结果，为您定制专业的案件处理流程")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                    Text("请点击右下角按钮“生成流程”继续")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
    }
    
    // MARK: - 步骤7：开始执行流程
    var startExecutionStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // 步骤头部
                VStack(alignment: .leading, spacing: 8) {
                    Text("步骤 7/7")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("开始执行流程")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text("一切准备就绪，开始您的法律维权之路")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // 案件总览
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue)
                        Text("案件总览")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        WizardInfoRow(title: "案件名称", value: caseTitle)
                        WizardInfoRow(title: "案件类型", value: selectedCaseType.rawValue)
                        WizardInfoRow(title: "相关文档", value: "\(uploadedDocuments.count)个文件")
                        
                        if let result = agentAnalysisResult {
                            WizardInfoRow(title: "案件强度", value: result.strengthLevel.rawValue)
                        }
                        
                        WizardInfoRow(title: "处理步骤", value: "\(generatedWorkflow.count)个步骤")
                    }
                }
                .padding()
                .liquidGlass()
                
                // 下一步行动
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("即将开始")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                    }
                    
                    if let firstStep = generatedWorkflow.first {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("第一步：\(firstStep.title)")
                                .font(.title3.bold())
                                .foregroundColor(AppTheme.accentColor)
                            
                            Text(firstStep.description)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text("预计完成时间：\(firstStep.estimatedDays)天")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding()
                .liquidGlass()
                
                // 提示使用右下角主按钮
                Text("请点击右下角“创建案件”开始执行流程")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
}

// MARK: - 辅助视图组件

struct WizardInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title + "：")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
            Spacer()
        }
    }
}

// MARK: - 数据模型

struct AgentAnalysisResult {
    let strengthLevel: CaseStrengthLevel
    let confidence: Double
    let recommendations: [String]
    let risks: [String]
}

enum CaseStrengthLevel: String, CaseIterable {
    case veryWeak = "很弱"
    case weak = "较弱"
    case moderate = "中等"
    case strong = "较强"
    case veryStrong = "很强"
    
    var color: Color {
        switch self {
        case .veryWeak: return .red
        case .weak: return .orange
        case .moderate: return .yellow
        case .strong: return .green
        case .veryStrong: return .blue
        }
    }
}