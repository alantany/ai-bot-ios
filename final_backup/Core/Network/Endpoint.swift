import Foundation

struct Endpoint {
    let path: String
    var queryItems: [URLQueryItem]?
    var method: HTTPMethod = .get
    var body: Data?
    
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