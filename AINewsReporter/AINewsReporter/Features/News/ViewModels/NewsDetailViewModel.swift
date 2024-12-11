import Foundation
import Combine

@MainActor
final class NewsDetailViewModel: ViewModelProtocol {
    // MARK: - State
    struct State {
        let news: News
        var aiResponse: AIResponse?
        var isGeneratingAISummary = false
        var isSpeaking = false
        var speechProgress: Double = 0
        var isBookmarked = false
    }
    
    // MARK: - Properties
    @Published private(set) var state: State
    @Published var isLoading = false
    @Published var error: Error?
    
    private let networkService: NetworkService
    private let storageService: StorageService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(news: News,
         networkService: NetworkService = .shared,
         storageService: StorageService = .shared) {
        self.state = State(news: news)
        self.networkService = networkService
        self.storageService = storageService
    }
    
    static func create(news: News) async -> NewsDetailViewModel {
        let viewModel = NewsDetailViewModel(news: news)
        await viewModel.initialize()
        return viewModel
    }
    
    private func initialize() async {
        // 检查是否已收藏
        if let bookmarks = try? await storageService.getValue(forKey: "bookmarked_news", type: Set<String>.self) {
            state.isBookmarked = bookmarks.contains(state.news.id)
        }
        
        // 检查是否有缓存的AI摘要
        let cacheKey = "ai_summary_\(state.news.id)"
        if let cachedData = try? await storageService.getCachedData(forKey: cacheKey),
           let aiResponse = try? JSONDecoder().decode(AIResponse.self, from: cachedData) {
            state.aiResponse = aiResponse
        }
    }
    
    // MARK: - Public Methods
    func generateAISummary() async {
        guard state.aiResponse == nil, !state.isGeneratingAISummary else { return }
        
        state.isGeneratingAISummary = true
        
        do {
            let endpoint = Endpoint.getAISummary(text: state.news.content)
            let aiResponse: AIResponse = try await networkService.request(endpoint)
            
            // 更新状态
            state.aiResponse = aiResponse
            state.news.aiSummary = aiResponse.summary
            
            // 缓存AI摘要
            let cacheKey = "ai_summary_\(state.news.id)"
            let responseData = try JSONEncoder().encode(aiResponse)
            try await storageService.cacheData(responseData, forKey: cacheKey)
            
        } catch {
            handleError(error)
        }
        
        state.isGeneratingAISummary = false
    }
    
    func toggleBookmark() async {
        do {
            // 获取当前收藏列表
            var bookmarks = (try? await storageService.getValue(forKey: "bookmarked_news", type: Set<String>.self)) ?? Set<String>()
            
            if state.isBookmarked {
                bookmarks.remove(state.news.id)
            } else {
                bookmarks.insert(state.news.id)
            }
            
            // 保存更新后的收藏列表
            try await storageService.setValue(bookmarks, forKey: "bookmarked_news")
            
            // 更新状态
            state.isBookmarked.toggle()
            
        } catch {
            handleError(error)
        }
    }
    
    func startSpeaking() async {
        guard !state.isSpeaking else { return }
        
        do {
            state.isSpeaking = true
            state.speechProgress = 0
            
            let text = state.aiResponse?.summary ?? state.news.summary ?? state.news.content
            let endpoint = Endpoint.textToSpeech(text: text)
            
            // 获取语音数据
            let audioData = try await networkService.requestData(endpoint)
            
            // TODO: 实现语音播放功能
            // 1. 使用 AVFoundation 播放音频
            // 2. 更新播放进度
            // 3. 处理播放完成
            
        } catch {
            handleError(error)
            state.isSpeaking = false
            state.speechProgress = 0
        }
    }
    
    func stopSpeaking() {
        guard state.isSpeaking else { return }
        
        // TODO: 停止语音播放
        state.isSpeaking = false
        state.speechProgress = 0
    }
    
    func share() {
        // TODO: 实现分享功能
        // 1. 创建分享内容
        // 2. 调用系统分享
    }
}

// MARK: - Preview Helper
extension NewsDetailViewModel {
    static var preview: NewsDetailViewModel {
        let viewModel = NewsDetailViewModel(news: .preview)
        viewModel.state.aiResponse = AIResponse(
            summary: "这是一个AI生成的新闻摘要示例。",
            keywords: ["iPhone", "苹果", "芯片"],
            sentiment: .positive
        )
        return viewModel
    }
} 