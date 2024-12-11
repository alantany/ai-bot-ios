import SwiftUI

final class AppCoordinator: Coordinator {
    var navigationController: UINavigationController
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private let container: DependencyContainer
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.container = .shared
    }
    
    func start() {
        let mainCoordinator = container.makeMainCoordinator(navigationController: navigationController)
        mainCoordinator.parentCoordinator = self
        addChild(mainCoordinator)
        mainCoordinator.start()
    }
} 