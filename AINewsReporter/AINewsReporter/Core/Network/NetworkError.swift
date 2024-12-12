import Foundation

enum NetworkError: LocalizedError {
    case networkError(Error)
    case invalidResponse
    case invalidRequest
    case decodingError(Error)
    case unauthorized
    case serverError
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .invalidResponse:
            return "无效的响应"
        case .invalidRequest:
            return "无效的请求参数"
        case .decodingError(let error):
            return "数据解析错误: \(error.localizedDescription)"
        case .unauthorized:
            return "未授权的请求"
        case .serverError:
            return "服务器错误"
        case .httpError(let code):
            return "HTTP错误: \(code)"
        }
    }
} 