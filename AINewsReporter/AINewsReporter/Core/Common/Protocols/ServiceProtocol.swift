import Foundation

protocol ServiceProtocol {
    var isReady: Bool { get }
    func initialize() async throws
} 