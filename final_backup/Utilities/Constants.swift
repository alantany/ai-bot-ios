import Foundation

enum Constants {
    enum UserDefaultsKeys {
        static let lastSyncTime = "lastSyncTime"
        static let readArticles = "readArticles"
        static let userSettings = "userSettings"
    }
    
    enum NotificationNames {
        static let speechStateChanged = "speechStateChanged"
        static let newArticleAvailable = "newArticleAvailable"
    }
    
    enum Animation {
        static let defaultDuration: Double = 0.3
        static let longDuration: Double = 0.5
    }
    
    enum Layout {
        static let spacing: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let maxWidth: CGFloat = 414
    }
} 