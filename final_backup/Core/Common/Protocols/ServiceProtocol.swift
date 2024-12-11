import Foundation
import Combine

protocol ServiceProtocol {
    var session: URLSession { get }
    var baseURL: URL { get }
    
    func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func fetch<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, Error>
}

struct Endpoint {
    let path: String
    let queryItems: [URLQueryItem]?
    let method: HTTPMethod
    let body: Data?
    
    init(
        path: String,
        queryItems: [URLQueryItem]? = nil,
        method: HTTPMethod = .get,
        body: Data? = nil
    ) {
        self.path = path
        self.queryItems = queryItems
        self.method = method
        self.body = body
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
} 