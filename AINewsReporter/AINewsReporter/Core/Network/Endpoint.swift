import Foundation

enum Endpoint {
    case getNewsList(page: Int, pageSize: Int)
    case getNewsDetail(id: String)
    case getAISummary(text: String)
    case textToSpeech(text: String)
    
    var path: String {
        switch self {
        case .getNewsList:
            return "/api/news"
        case .getNewsDetail(let id):
            return "/api/news/\(id)"
        case .getAISummary:
            return "/api/ai/summary"
        case .textToSpeech:
            return "/api/tts"
        }
    }
    
    var method: String {
        switch self {
        case .getNewsList, .getNewsDetail:
            return "GET"
        case .getAISummary, .textToSpeech:
            return "POST"
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getNewsList(let page, let pageSize):
            return [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "pageSize", value: "\(pageSize)")
            ]
        default:
            return nil
        }
    }
    
    var body: Data? {
        switch self {
        case .getAISummary(let text):
            return try? JSONSerialization.data(withJSONObject: ["text": text])
        case .textToSpeech(let text):
            return try? JSONSerialization.data(withJSONObject: ["text": text])
        default:
            return nil
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let baseURL = AppConfig.shared.environment.baseURL
        
        guard var components = URLComponents(string: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        components.path += path
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = Constants.API.timeout
        
        // 添加通用头部
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        return request
    }
}

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case noData
    case unauthorized
    case serverError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .invalidResponse:
            return "无效的响应"
        case .httpError(let code):
            return "HTTP错误: \(code)"
        case .decodingError:
            return "数据解析错误"
        case .noData:
            return "没有数据"
        case .unauthorized:
            return "未授权访问"
        case .serverError:
            return "服务器错误"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        }
    }
} 