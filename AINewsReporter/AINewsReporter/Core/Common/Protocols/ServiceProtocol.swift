import Foundation

protocol ServiceProtocol {
    nonisolated var isReady: Bool { get }
    func initialize() async throws
} 