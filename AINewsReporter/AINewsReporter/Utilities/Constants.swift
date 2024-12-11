import Foundation

enum Constants {
    enum API {
        static let baseURL = "https://your-api-base-url.com"
        static let timeout: TimeInterval = 30
        static let maxRetries = 3
    }
    
    enum UI {
        static let cornerRadius: CGFloat = 8
        static let padding: CGFloat = 16
        static let animationDuration: TimeInterval = 0.3
    }
    
    enum Cache {
        static let maxAge: TimeInterval = 60 * 5 // 5 minutes
        static let maxSize: Int = 50 * 1024 * 1024 // 50 MB
    }
    
    enum News {
        static let maxNewsPerPage = 20
        static let preloadThreshold = 5
        static let maxRetryAttempts = 3
    }
} 