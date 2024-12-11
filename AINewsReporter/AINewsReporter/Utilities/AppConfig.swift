import Foundation

final class AppConfig {
    // MARK: - Singleton
    static let shared = AppConfig()
    private init() {}
    
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
        URLSession.shared.configuration.timeoutIntervalForRequest = Constants.API.timeout
        URLSession.shared.configuration.timeoutIntervalForResource = Constants.API.timeout
    }
    #endif
} 