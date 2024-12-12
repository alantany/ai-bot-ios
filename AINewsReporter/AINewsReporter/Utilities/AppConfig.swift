import Foundation

final class AppConfig {
    // MARK: - Singleton
    static let shared = AppConfig()
    private init() {
        // 初始化时设置API密钥
        self.baiduApiKey = "aAmfR6JzI6v3kRi5Ja05CsB1"
        self.baiduSecretKey = "Y7knVNbR5dlOOJ6DWoarPZ09uJ1QMwDy"
        self.baiduAppId = "6135044"
    }
    
    // MARK: - Environment
    enum Environment: String {
        case development
        case staging
        case production
        
        var baseURL: String {
            switch self {
            case .development:
                return "https://dev-api.ainews.com"
            case .staging:
                return "https://staging-api.ainews.com"
            case .production:
                return "https://api.ainews.com"
            }
        }
    }
    
    // MARK: - Properties
    private(set) var environment: Environment = {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }()
    
    // MARK: - Feature Flags
    var isVoiceEnabled: Bool {
        #if DEBUG
        return true
        #else
        // 这里可以接入远程配置系统
        return true
        #endif
    }
    
    var isOfflineMode: Bool = false
    
    // MARK: - App Version
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - Methods
    func configure(with environment: Environment) {
        self.environment = environment
    }
    
    func toggleOfflineMode() {
        isOfflineMode.toggle()
    }
    
    // MARK: - Debug Helpers
    #if DEBUG
    func simulateSlowNetwork() {
        // 在开发环境下模拟网络延迟
        URLSession.shared.configuration.timeoutIntervalForRequest = 3
        URLSession.shared.configuration.timeoutIntervalForResource = 5
    }
    
    func resetNetworkSimulation() {
        URLSession.shared.configuration.timeoutIntervalForRequest = AppConfig.API.timeout
        URLSession.shared.configuration.timeoutIntervalForResource = AppConfig.API.timeout
    }
    #endif
    
    // MARK: - API Keys
    private(set) var baiduApiKey: String
    private(set) var baiduSecretKey: String
    private(set) var baiduAppId: String
    private var baiduAccessToken: String?
    private var tokenExpireTime: Date?
    
    // 获取百度API的访问令牌
    func getBaiduAccessToken() async throws -> String {
        // 如果token还在有效期内，直接返回
        if let token = baiduAccessToken, let expireTime = tokenExpireTime,
           expireTime > Date() {
            return token
        }
        
        // 构建token请求
        var components = URLComponents(string: "https://aip.baidubce.com/oauth/2.0/token")!
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "client_credentials"),
            URLQueryItem(name: "client_id", value: baiduApiKey),
            URLQueryItem(name: "client_secret", value: baiduSecretKey)
        ]
        
        let request = URLRequest(url: components.url!)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        // 保存token和过期时间
        baiduAccessToken = response.accessToken
        tokenExpireTime = Date().addingTimeInterval(TimeInterval(response.expiresIn))
        
        return response.accessToken
    }
    
    private struct TokenResponse: Codable {
        let refreshToken: String
        let expiresIn: Int
        let sessionKey: String
        let accessToken: String
        let scope: String
        let sessionSecret: String
        
        enum CodingKeys: String, CodingKey {
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case sessionKey = "session_key"
            case accessToken = "access_token"
            case scope
            case sessionSecret = "session_secret"
        }
    }
    
    var azureApiKey: String? {
        // 从环境变量或配置文件中获取
        ProcessInfo.processInfo.environment["AZURE_API_KEY"]
    }
    
    // MARK: - Constants
    enum Constants {
        static let newsRefreshInterval: TimeInterval = 300 // 5分钟
        static let maxNewsAge: TimeInterval = 86400 // 24小时
        static let maxCacheSize = 100 // 最多缓存100条新闻
    }
    
    enum API {
        static let timeout: TimeInterval = 30
        static let maxRetries = 3
        static let retryInterval: TimeInterval = 1
    }
} 