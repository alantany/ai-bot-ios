import Foundation
import Combine

@MainActor
final class NewsDetailViewModel: ObservableObject {
    // MARK: - State
    struct State {
        var news: News
        var isSpeaking = false
    }
    
    // MARK: - Properties
    @Published private(set) var state: State
    @Published var isLoading = false
    @Published var error: Error?
    
    private let networkService: NetworkService
    
    // MARK: - Initialization
    init(news: News,
         networkService: NetworkService = .shared) {
        self.state = State(news: news)
        self.networkService = networkService
    }
}

// MARK: - Preview Helper
extension NewsDetailViewModel {
    static var preview: NewsDetailViewModel {
        NewsDetailViewModel(news: .preview)
    }
} 