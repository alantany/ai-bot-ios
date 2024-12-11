import Foundation
import OSLog

final class Logger {
    // MARK: - Singleton
    static let shared = Logger()
    private init() {}
    
    // MARK: - Properties
    private let osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.ainews.reporter", category: "default")
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    // MARK: - Log Levels
    enum Level: String {
        case debug = "🔍 DEBUG"
        case info = "ℹ️ INFO"
        case warning = "⚠️ WARNING"
        case error = "❌ ERROR"
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .error
            case .error: return .fault
            }
        }
    }
    
    // MARK: - Public Methods
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        var fullMessage = message
        if let error = error {
            fullMessage += "\nError: \(error.localizedDescription)"
        }
        log(fullMessage, level: .error, file: file, function: function, line: line)
    }
    
    // MARK: - Private Methods
    private func log(_ message: String, level: Level, file: String, function: String, line: Int) {
        let timestamp = dateFormatter.string(from: Date())
        let filename = (file as NSString).lastPathComponent
        let logMessage = "\(timestamp) [\(level.rawValue)] [\(filename):\(line)] \(function) - \(message)"
        
        #if DEBUG
        // 在调试环境下，同时输出到控制台
        print(logMessage)
        #endif
        
        // 记录到系统日志
        os_log("%{public}@", log: osLog, type: level.osLogType, logMessage)
        
        // TODO: 可以在这里添加日志持久化、上传等功能
    }
    
    // MARK: - Helper Methods
    func logNetworkRequest(_ request: URLRequest) {
        #if DEBUG
        var message = "\n=== Network Request ===\n"
        message += "URL: \(request.url?.absoluteString ?? "nil")\n"
        message += "Method: \(request.httpMethod ?? "GET")\n"
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            message += "Headers: \(headers)\n"
        }
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            message += "Body: \(bodyString)\n"
        }
        message += "====================="
        debug(message)
        #endif
    }
    
    func logNetworkResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        #if DEBUG
        var message = "\n=== Network Response ===\n"
        if let httpResponse = response as? HTTPURLResponse {
            message += "Status Code: \(httpResponse.statusCode)\n"
            message += "Headers: \(httpResponse.allHeaderFields)\n"
        }
        if let data = data, let jsonString = String(data: data, encoding: .utf8) {
            message += "Response: \(jsonString)\n"
        }
        if let error = error {
            message += "Error: \(error.localizedDescription)\n"
        }
        message += "====================="
        debug(message)
        #endif
    }
} 