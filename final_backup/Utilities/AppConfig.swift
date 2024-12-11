import Foundation

enum AppConfig {
    static let baseURL = URL(string: "https://api.example.com")!
    
    enum API {
        static let newsPath = "/news"
        static let detailPath = "/detail"
    }
    
    enum Cache {
        static let maxAge: TimeInterval = 60 * 60 // 1 hour
        static let maxSize: Int = 50 * 1024 * 1024 // 50 MB
    }
    
    enum Speech {
        static let defaultLanguage = "zh-CN"
        static let defaultRate: Float = 0.5
        static let defaultPitch: Float = 1.0
    }
} 