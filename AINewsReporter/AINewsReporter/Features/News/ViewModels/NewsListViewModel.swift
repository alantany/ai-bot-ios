import Foundation
import Combine

@MainActor
final class NewsListViewModel: ObservableObject {
    @Published private(set) var news: [News] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let networkService: NetworkService
    
    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }
    
    func fetchNews() async {
        isLoading = true
        error = nil
        
        do {
            // 如果网络服务还没有初始化，先初始化
            if !networkService.isReady {
                try await networkService.initialize()
            }
            
            // 获取新闻列表
            let response: SinaNewsResponse = try await networkService.request(.sinaNews(category: "2515", num: 20))
            
            // 将新闻数据转换为News模型
            let newsItems = response.result.data.map { item in
                News(from: item)
            }
            self.news = newsItems
            
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
} 