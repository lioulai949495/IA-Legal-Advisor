import SwiftUI
import Combine

/// 案件管理相关的视图模型
@MainActor
class CaseViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var cases: [Case] = []
    @Published var selectedCase: Case?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 新建案件
    @Published var isShowingNewCaseWizard = false
    @Published var newCaseTitle = ""
    @Published var newCaseDescription = ""
    @Published var selectedCaseType: CaseType = .contractDispute
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Dependencies
    private let apiService: APIService
    
    // MARK: - Initialization
    init(apiService: APIService = .shared) {
        self.apiService = apiService
        loadSampleCases()
    }
    
    // MARK: - Public Methods
    
    /// 加载用户案件列表
    func loadCases() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let serverCases = try await apiService.getCases()
                await MainActor.run {
                    self.isLoading = false
                    // 将服务端数据转换为前端 Case 模型（最小映射）
                    self.cases = serverCases.map { resp in
                        Case(
                            id: resp.id,
                            title: resp.title,
                            description: resp.description,
                            createdAt: ISO8601DateFormatter().date(from: resp.created_at) ?? Date(),
                            lastUpdatedAt: ISO8601DateFormatter().date(from: resp.updated_at) ?? Date(),
                            caseType: CaseType(rawValue: resp.case_type) ?? .contractDispute,
                            status: CaseStatus(rawValue: resp.status) ?? .active,
                            messages: []
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "获取案件失败：\(error.localizedDescription)"
                }
            }
        }
    }
    
    /// 创建新案件
    func createCase() {
        guard !newCaseTitle.isEmpty else {
            errorMessage = "请输入案件标题"
            return
        }
        
        isLoading = true
        errorMessage = nil
        let title = newCaseTitle
        let desc = newCaseDescription
        let type = selectedCaseType.rawValue
        
        Task {
            do {
                let created = try await apiService.createCase(title: title, description: desc, caseType: type)
                await MainActor.run {
                    self.isLoading = false
                    let newItem = Case(
                        id: created.id,
                        title: created.title,
                        description: created.description,
                        createdAt: ISO8601DateFormatter().date(from: created.created_at) ?? Date(),
                        lastUpdatedAt: ISO8601DateFormatter().date(from: created.updated_at) ?? Date(),
                        caseType: CaseType(rawValue: created.case_type) ?? .contractDispute,
                        status: CaseStatus(rawValue: created.status) ?? .active,
                        messages: []
                    )
                    self.cases.insert(newItem, at: 0)
                    self.clearNewCaseForm()
                    self.isShowingNewCaseWizard = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "创建案件失败：\(error.localizedDescription)"
                }
            }
        }
    }
    
    /// 更新案件状态
    func updateCaseStatus(_ caseId: String, status: CaseStatus) {
        guard let index = cases.firstIndex(where: { $0.id == caseId }) else { return }
        
        cases[index].status = status
        cases[index].lastUpdatedAt = Date()
        
        // 如果是当前选中的案件，也更新它
        if selectedCase?.id == caseId {
            selectedCase?.status = status
            selectedCase?.lastUpdatedAt = Date()
        }
    }
    
    /// 删除案件
    func deleteCase(_ caseId: String) {
        cases.removeAll { $0.id == caseId }
        
        if selectedCase?.id == caseId {
            selectedCase = nil
        }
    }
    
    /// 选择案件
    func selectCase(_ caseItem: Case) {
        selectedCase = caseItem
    }
    
    /// 获取特定状态的案件
    func casesForStatus(_ status: CaseStatus) -> [Case] {
        return cases.filter { $0.status == status }
    }
    
    /// 搜索案件
    func searchCases(keyword: String) -> [Case] {
        guard !keyword.isEmpty else { return cases }
        
        return cases.filter { caseItem in
            caseItem.title.localizedCaseInsensitiveContains(keyword) ||
            caseItem.description.localizedCaseInsensitiveContains(keyword) ||
            caseItem.caseType.rawValue.localizedCaseInsensitiveContains(keyword)
        }
    }
    
    // MARK: - Private Methods
    
    /// 清空新建案件表单
    private func clearNewCaseForm() {
        newCaseTitle = ""
        newCaseDescription = ""
        selectedCaseType = .contractDispute
    }
    
    /// 加载示例案件数据
    private func loadSampleCases() {
        // 启动时尝试从后端拉取；失败则保持空列表
        loadCases()
    }
}