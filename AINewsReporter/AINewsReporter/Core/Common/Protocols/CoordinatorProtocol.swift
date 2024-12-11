import Foundation
import SwiftUI

protocol CoordinatorProtocol: ObservableObject {
    associatedtype Route
    
    var navigationPath: NavigationPath { get set }
    
    func navigate(to route: Route)
    func pop()
    func popToRoot()
} 