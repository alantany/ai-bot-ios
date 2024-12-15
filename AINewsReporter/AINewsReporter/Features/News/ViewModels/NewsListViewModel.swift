import Foundation
import Combine

@MainActor
final class NewsListViewModel: ObservableObject {
    // 新闻分类
    enum NewsCategory: String, CaseIterable {
        case domestic = "2510"   // 国内新闻
        case international = "2511"  // 国际新闻
        case life = "2669"      // 生活新闻
        case tech = "2515"      // 科技新闻
        
        var title: String {
            switch self {
            case .domestic: return "国内"
            case .international: return "国际"
            case .life: return "生活"
            case .tech: return "科技"
            }
        }
    }
    
    // 缓存所有分类的新闻
    private var newsCache: [NewsCategory: [News]] = [:]
    @Published private(set) var news: [News] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var currentCategory: NewsCategory = .domestic
    
    private let networkService: NetworkService
    
    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }
    
    // 预加载所有分类的新闻
    func preloadAllNews() async {
        // 初始化网络服务
        if !networkService.isReady {
            do {
                try await networkService.initialize()
            } catch {
                self.error = error
                return
            }
        }
        
        // 并发加载所有分类的新闻
        await withTaskGroup(of: (NewsCategory, [News]).self) { group in
            for category in NewsCategory.allCases {
                group.addTask {
                    do {
                        let response: SinaNewsResponse = try await self.networkService.request(.sinaNews(category: category.rawValue, num: 20))
                        let newsItems = response.result.data.map { News(from: $0) }
                        return (category, newsItems)
                    } catch {
                        return (category, [])
                    }
                }
            }
            
            // 收集结果
            for await (category, items) in group {
                if !items.isEmpty {
                    newsCache[category] = items
                }
            }
        }
        
        // 设置初始分类的新闻
        if let initialNews = newsCache[currentCategory] {
            news = initialNews
        }
    }
    
    // 切换分类
    func switchCategory(_ category: NewsCategory) {
        currentCategory = category
        if let cachedNews = newsCache[category] {
            news = cachedNews
        }
        
        // 在后台刷新该分类的新闻
        Task {
            await refreshCurrentCategory()
        }
    }
    
    // 刷新当前分类的新闻
    func refreshCurrentCategory() async {
        do {
            if !networkService.isReady {
                try await networkService.initialize()
            }
            
            let response: SinaNewsResponse = try await networkService.request(.sinaNews(category: currentCategory.rawValue, num: 20))
            let newsItems = response.result.data.map { News(from: $0) }
            
            // 更新缓存和当前显示
            newsCache[currentCategory] = newsItems
            await MainActor.run {
                news = newsItems
            }
        } catch {
            self.error = error
        }
    }
    
    // 获取指定分类的新闻（不刷新UI）
    func getNews(for category: NewsCategory) -> [News] {
        return newsCache[category] ?? []
    }
} 