import Foundation
import Combine

protocol ViewModelProtocol: ObservableObject {
    associatedtype State
    
    var state: State { get }
    var error: Error? { get set }
    var isLoading: Bool { get set }
}

protocol ViewModelStateProtocol {
    var isLoading: Bool { get set }
    var error: Error? { get set }
} 