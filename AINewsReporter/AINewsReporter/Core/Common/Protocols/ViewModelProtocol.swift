import Foundation
import Combine

@MainActor
protocol ViewModelProtocol: ObservableObject {
    associatedtype State
    
    var state: State { get }
    var isLoading: Bool { get set }
    var error: Error? { get set }
}

extension ViewModelProtocol {
    func handleError(_ error: Error) {
        self.error = error
        self.isLoading = false
    }
    
    func startLoading() {
        self.isLoading = true
        self.error = nil
    }
    
    func stopLoading() {
        self.isLoading = false
    }
} 