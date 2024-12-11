import Foundation
import Combine

class NewsListViewModel: ObservableObject {
    @Published private(set) var news: [News] = []
    @Published private(set) var selectedCategory: NewsCategory = .domestic
    @Published var error: Error?
    @Published var isLoading = false
    
    private let networkService: NetworkService
    private let storageService: StorageService
    private var cancellables = Set<AnyCancellable>()
    
    init(networkService: NetworkService, storageService: StorageService) {
        self.networkService = networkService
        self.storageService = storageService
    }
    
    @MainActor
    func fetchNews() async {
        isLoading = true
        error = nil
        
        do {
            // 先从本地加载
            let localNews = try await storageService.fetchNews(category: selectedCategory)
            news = localNews
            
            // 再从网络更新
            let endpoint = Endpoint(
                path: AppConfig.API.newsPath,
                queryItems: [URLQueryItem(name: "category", value: selectedCategory.rawValue)]
            )
            
            let remoteNews: [News] = try await networkService.fetch(endpoint)
            try await storageService.saveNews(remoteNews)
            news = remoteNews
            
            // 清理旧缓存
            try await storageService.clearOldCache()
            
        } catch {
            self.error = error
            Logger.error("获取新闻失败", error: error, log: .network)
        }
        
        isLoading = false
    }
    
    func selectCategory(_ category: NewsCategory) {
        guard category != selectedCategory else { return }
        selectedCategory = category
        Task {
            await fetchNews()
        }
    }
    
    func markAsRead(_ newsId: String) {
        Task {
            try? await storageService.markAsRead(newsId)
        }
    }
    
    func retry() {
        Task {
            await fetchNews()
        }
    }
} 