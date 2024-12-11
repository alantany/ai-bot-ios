import Foundation
import Combine

@MainActor
final class NewsListViewModel: ViewModelProtocol {
    // MARK: - State
    struct State {
        var news: [News] = []
        var selectedCategory: News.Category = .general
        var currentPage: Int = 1
        var hasMorePages: Bool = true
        var searchText: String = ""
    }
    
    // MARK: - Properties
    @Published private(set) var state = State()
    @Published var isLoading = false
    @Published var error: Error?
    
    private let networkService: NetworkService
    private let storageService: StorageService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(networkService: NetworkService = .shared,
         storageService: StorageService = .shared) {
        self.networkService = networkService
        self.storageService = storageService
        
        // 加载缓存的分类选择
        if let savedCategory = try? storageService.getValue(forKey: "selectedCategory", type: News.Category.self) {
            state.selectedCategory = savedCategory
        }
        
        setupSearchDebounce()
    }
    
    // MARK: - Public Methods
    func refreshNews() async {
        state.currentPage = 1
        state.hasMorePages = true
        state.news = []
        await loadNews()
    }
    
    func loadMoreIfNeeded(currentItem: News) async {
        let thresholdIndex = state.news.index(state.news.endIndex, offsetBy: -Constants.News.preloadThreshold)
        if let itemIndex = state.news.firstIndex(where: { $0.id == currentItem.id }),
           itemIndex >= thresholdIndex,
           state.hasMorePages && !isLoading {
            await loadNews()
        }
    }
    
    func selectCategory(_ category: News.Category) async {
        guard category != state.selectedCategory else { return }
        state.selectedCategory = category
        try? storageService.setValue(category, forKey: "selectedCategory")
        await refreshNews()
    }
    
    func searchNews(_ query: String) {
        state.searchText = query
    }
    
    // MARK: - Private Methods
    private func loadNews() async {
        guard !isLoading && state.hasMorePages else { return }
        
        do {
            startLoading()
            
            let endpoint = Endpoint.getNewsList(
                page: state.currentPage,
                pageSize: Constants.News.maxNewsPerPage
            )
            
            let response: NewsResponse = try await networkService.request(endpoint)
            
            // 更新状态
            state.news.append(contentsOf: response.articles)
            state.currentPage += 1
            state.hasMorePages = response.nextPage != nil
            
            // 缓存第一页数据
            if state.currentPage == 2 {
                try await cacheFirstPageNews(response.articles)
            }
            
            stopLoading()
        } catch {
            handleError(error)
        }
    }
    
    private func cacheFirstPageNews(_ news: [News]) async throws {
        let cacheKey = "news_cache_\(state.selectedCategory.rawValue)"
        let newsData = try JSONEncoder().encode(news)
        try await storageService.cacheData(newsData, forKey: cacheKey)
    }
    
    private func setupSearchDebounce() {
        $state
            .map(\.searchText)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    await self.refreshNews()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Preview Helper
extension NewsListViewModel {
    static var preview: NewsListViewModel {
        let viewModel = NewsListViewModel()
        viewModel.state.news = News.previewList
        return viewModel
    }
} 