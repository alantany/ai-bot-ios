import SwiftUI

final class MainCoordinator: Coordinator {
    var navigationController: UINavigationController
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private let container: DependencyContainer
    
    init(navigationController: UINavigationController, container: DependencyContainer) {
        self.navigationController = navigationController
        self.container = container
    }
    
    func start() {
        showNewsList()
    }
    
    private func showNewsList() {
        let viewModel = container.makeNewsListViewModel()
        let newsListView = NewsListView(viewModel: viewModel)
            .environmentObject(container.makeSpeechViewModel())
        
        let hostingController = UIHostingController(rootView: newsListView)
        navigationController.setViewControllers([hostingController], animated: false)
    }
} 