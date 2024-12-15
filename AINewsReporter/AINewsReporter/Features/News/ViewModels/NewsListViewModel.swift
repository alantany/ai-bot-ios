import Foundation
import Combine

@MainActor
final class NewsListViewModel: ObservableObject {
    // 新闻分类
    enum NewsCategory: CaseIterable {
        case domestic    // 国内新闻（财经、社会、娱乐）
        case international  // 国际新闻（体育）
        case life       // 生活新闻（军事）
        case tech      // 科技新闻
        
        var title: String {
            switch self {
            case .domestic: return "国内"
            case .international: return "国际"
            case .life: return "生活"
            case .tech: return "科技"
            }
        }
        
        // 获取频道ID
        var channelIds: [String] {
            switch self {
            case .domestic: return ["2509", "2512", "2517"]  // 财经、社会、娱乐
            case .international: return ["2518"]  // 体育
            case .life: return ["2513"]  // 军事
            case .tech: return ["2515"]  // 科技
            }
        }
    }
    
    // UserDefaults keys
    private enum UserDefaultsKeys {
        static let playedNewsIds = "playedNewsIds"
        static let categoryLastIndex = "categoryLastIndex"
    }
    
    // 缓存所有分类的新闻
    private var newsCache: [NewsCategory: [News]] = [:]
    @Published private(set) var news: [News] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var currentCategory: NewsCategory = .domestic
    
    private let networkService: NetworkService
    private var playedNewsIds: Set<String> {
        get {
            let array = UserDefaults.standard.array(forKey: UserDefaultsKeys.playedNewsIds) as? [String] ?? []
            return Set(array)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: UserDefaultsKeys.playedNewsIds)
        }
    }
    
    // 记录每个分类的最后播放位置
    private var categoryLastIndex: [String: Int] {
        get {
            return UserDefaults.standard.dictionary(forKey: UserDefaultsKeys.categoryLastIndex) as? [String: Int] ?? [:]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.categoryLastIndex)
        }
    }
    
    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }
    
    // 标记新闻为已播放
    func markNewsAsPlayed(_ newsId: String) async {
        var ids = playedNewsIds
        ids.insert(newsId)
        playedNewsIds = ids
        
        // 检查是否需要刷新
        await checkAndRefreshIfNeeded()
    }
    
    // 过滤已播放的新闻
    nonisolated private func filterPlayedNews(_ news: [News]) -> [News] {
        let playedIds = UserDefaults.standard.array(forKey: UserDefaultsKeys.playedNewsIds) as? [String] ?? []
        return news.filter { !playedIds.contains($0.id) }
    }
    
    // 检查是否所有新闻都已播放
    private func checkIfAllNewsPlayed() -> Bool {
        return news.allSatisfy { playedNewsIds.contains($0.id) }
    }
    
    // 预加载所有分类的新闻
    func preloadAllNews() async {
        isLoading = true
        defer { isLoading = false }
        
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
        await withTaskGroup(of: (NewsCategory, Result<[News], Error>).self) { group in
            for category in NewsCategory.allCases {
                group.addTask {
                    var allNews: [News] = []
                    var errors: [Error] = []
                    
                    // 获取该分类下所有频道的新闻
                    for channelId in category.channelIds {
                        do {
                            let response: SinaNewsResponse = try await self.networkService.request(.sinaNews(category: channelId, num: 20))
                            let news = response.result.data.map { News(from: $0) }
                            print("分类 \(category.title) 频道 \(channelId) 获取成功，新闻数量：\(news.count)")
                            allNews.append(contentsOf: news)
                        } catch {
                            print("分类 \(category.title) 频道 \(channelId) 获取失败：\(error.localizedDescription)")
                            errors.append(error)
                            continue
                        }
                    }
                    
                    if allNews.isEmpty && !errors.isEmpty {
                        return (category, .failure(errors.first ?? NSError(domain: "NewsError", code: -1, userInfo: [NSLocalizedDescriptionKey: "所有频道获取失败"])))
                    }
                    
                    // 对国内新闻进行随机排序
                    if category == .domestic {
                        allNews.shuffle()
                        print("分类 \(category.title) 新闻已打乱顺序，总数：\(allNews.count)")
                    }
                    
                    let filteredNews = self.filterPlayedNews(allNews)
                    print("分类 \(category.title) 过滤后的新闻数量：\(filteredNews.count)")
                    return (category, .success(filteredNews))
                }
            }
            
            // 收集结果
            for await (category, result) in group {
                switch result {
                case .success(let items):
                    if !items.isEmpty {
                        newsCache[category] = items
                    }
                case .failure(let error):
                    print("分类 \(category.title) 获取失败：\(error.localizedDescription)")
                }
            }
        }
        
        // 设置初始分类的新闻
        if let initialNews = newsCache[currentCategory] {
            news = initialNews
            // 恢复该分类的播放位置
            if let lastIndex = categoryLastIndex[currentCategory.title] {
                SpeechViewModel.shared.updateLastPlayedIndex(min(lastIndex, initialNews.count - 1))
            }
        }
    }
    
    // 切换分类
    func switchCategory(_ category: NewsCategory) async {
        // 停止当前播放
        SpeechViewModel.shared.stop()
        
        currentCategory = category
        if let cachedNews = newsCache[category] {
            news = cachedNews
            // 恢复该分类的播放位置
            if let lastIndex = categoryLastIndex[category.title] {
                SpeechViewModel.shared.updateLastPlayedIndex(min(lastIndex, cachedNews.count - 1))
            } else {
                SpeechViewModel.shared.updateLastPlayedIndex(0)
            }
            await checkAndRefreshIfNeeded()
        }
    }
    
    // 更新分类的播放位置
    func updateCategoryLastIndex(_ index: Int) {
        categoryLastIndex[currentCategory.title] = index
    }
    
    // 获取当前分类的上次播放位置
    func getCategoryLastIndex() -> Int? {
        return categoryLastIndex[currentCategory.title]
    }
    
    // 刷新当前分类的新闻
    func refreshCurrentCategory() async {
        do {
            if !networkService.isReady {
                try await networkService.initialize()
            }
            
            // 获取当前分类的所有频道新闻
            var allNews: [News] = []
            var errors: [Error] = []
            
            // 并发获取所有频道的新闻
            await withTaskGroup(of: (String, Result<[News], Error>).self) { group in
                for channelId in currentCategory.channelIds {
                    group.addTask {
                        do {
                            let response: SinaNewsResponse = try await self.networkService.request(.sinaNews(category: channelId, num: 20))
                            let news = response.result.data.map { News(from: $0) }
                            return (channelId, .success(news))
                        } catch {
                            return (channelId, .failure(error))
                        }
                    }
                }
                
                // 收集所有频道的新闻
                for await (channelId, result) in group {
                    switch result {
                    case .success(let newsItems):
                        print("频道 \(channelId) 获取成功，新闻数量：\(newsItems.count)")
                        allNews.append(contentsOf: newsItems)
                    case .failure(let error):
                        print("频道 \(channelId) 获取失败：\(error.localizedDescription)")
                        errors.append(error)
                    }
                }
            }
            
            // 检查是否所有频道都失败了
            if allNews.isEmpty && !errors.isEmpty {
                throw errors.first ?? NSError(domain: "NewsError", code: -1, userInfo: [NSLocalizedDescriptionKey: "所有频道获取失败"])
            }
            
            print("获取到的总新闻数量：\(allNews.count)")
            
            // 对新闻进行随机排序（仅对国内新闻）
            if currentCategory == .domestic {
                allNews.shuffle()
                print("国内新闻已打乱顺序")
            }
            
            // 过滤已播放的新闻
            let filteredNews = filterPlayedNews(allNews)
            print("过滤后的新闻数量：\(filteredNews.count)")
            
            // 更新缓存和当前显示
            newsCache[currentCategory] = filteredNews
            news = filteredNews
        } catch {
            print("刷新新闻失败：\(error.localizedDescription)")
            self.error = error
        }
    }
    
    // 获取指定分类的新闻（不刷新UI）
    func getNews(for category: NewsCategory) -> [News] {
        return newsCache[category] ?? []
    }
    
    // 检查并刷新新闻（如果全部播放完）
    func checkAndRefreshIfNeeded() async {
        if checkIfAllNewsPlayed() {
            await refreshCurrentCategory()
        }
    }
} 