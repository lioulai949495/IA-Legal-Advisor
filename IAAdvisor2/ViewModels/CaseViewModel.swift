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
        
        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isLoading = false
            self?.loadSampleCases()
        }
    }
    
    /// 创建新案件
    func createCase() {
        guard !newCaseTitle.isEmpty else {
            errorMessage = "请输入案件标题"
            return
        }
        
        // 案件类型总是有值，因为使用了默认值
        
        isLoading = true
        
        let newCase = Case(
            id: UUID().uuidString,
            title: newCaseTitle,
            description: newCaseDescription,
            createdAt: Date(),
            lastUpdatedAt: Date(),
            caseType: selectedCaseType,
            status: CaseStatus.active,
            messages: []
        )
        
        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isLoading = false
            self?.cases.insert(newCase, at: 0)
            self?.clearNewCaseForm()
            self?.isShowingNewCaseWizard = false
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
        cases = [
            Case(
                id: "1",
                title: "劳动合同纠纷",
                description: "公司未支付加班费，需要法律咨询",
                createdAt: Date().addingTimeInterval(-AppConstants.Time.oneDay * 2),
                lastUpdatedAt: Date().addingTimeInterval(-AppConstants.Time.oneDay),
                caseType: .laborDispute,
                status: .active,
                messages: []
            ),
            Case(
                id: "2",
                title: "房屋租赁纠纷",
                description: "房东提前解除合同，要求赔偿",
                createdAt: Date().addingTimeInterval(-AppConstants.Time.oneDay * 3),
                lastUpdatedAt: Date().addingTimeInterval(-AppConstants.Time.oneDay * 2),
                caseType: .propertyDispute,
                status: .active,
                messages: []
            ),
            Case(
                id: "3",
                title: "交通事故理赔",
                description: "交通事故责任认定和保险理赔问题",
                createdAt: Date().addingTimeInterval(-AppConstants.Time.oneWeek),
                lastUpdatedAt: Date().addingTimeInterval(-AppConstants.Time.oneDay * 3),
                caseType: .propertyDispute,
                status: .completed,
                messages: []
            )
        ]
    }
}