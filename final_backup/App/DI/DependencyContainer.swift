import Foundation

final class DependencyContainer {
    static let shared = DependencyContainer()
    
    // Services
    private(set) lazy var networkService: NetworkService = {
        NetworkService(baseURL: AppConfig.baseURL)
    }()
    
    private(set) lazy var storageService: StorageService = {
        StorageService()
    }()
    
    // ViewModels
    func makeNewsListViewModel() -> NewsListViewModel {
        NewsListViewModel(networkService: networkService, storageService: storageService)
    }
    
    func makeSpeechViewModel() -> SpeechViewModel {
        SpeechViewModel()
    }
    
    // Coordinators
    func makeMainCoordinator(navigationController: UINavigationController) -> MainCoordinator {
        MainCoordinator(navigationController: navigationController, container: self)
    }
    
    private init() {}
} 