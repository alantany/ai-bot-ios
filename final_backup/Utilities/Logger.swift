import Foundation
import os.log

enum Logger {
    static let subsystem = Bundle.main.bundleIdentifier!
    
    static let network = OSLog(subsystem: subsystem, category: "Network")
    static let storage = OSLog(subsystem: subsystem, category: "Storage")
    static let speech = OSLog(subsystem: subsystem, category: "Speech")
    static let ui = OSLog(subsystem: subsystem, category: "UI")
    
    static func debug(_ message: String, log: OSLog = .default) {
        #if DEBUG
        os_log(.debug, log: log, "%{public}@", message)
        #endif
    }
    
    static func info(_ message: String, log: OSLog = .default) {
        os_log(.info, log: log, "%{public}@", message)
    }
    
    static func error(_ message: String, error: Error? = nil, log: OSLog = .default) {
        if let error = error {
            os_log(.error, log: log, "%{public}@: %{public}@", message, error.localizedDescription)
        } else {
            os_log(.error, log: log, "%{public}@", message)
        }
    }
} 