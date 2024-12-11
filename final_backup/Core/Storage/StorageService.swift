import Foundation
import CoreData

class StorageService {
    private let container: NSPersistentContainer
    private let backgroundContext: NSManagedObjectContext
    
    init() {
        container = NSPersistentContainer(name: "AINewsReporter")
        container.loadPersistentStores { description, error in
            if let error = error {
                Logger.error("Core Data加载失败", error: error, log: .storage)
            }
        }
        
        backgroundContext = container.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - News Operations
    
    func saveNews(_ news: [News]) async throws {
        try await backgroundContext.perform {
            news.forEach { newsItem in
                let entity = NewsEntity(context: self.backgroundContext)
                entity.id = newsItem.id
                entity.title = newsItem.title
                entity.content = newsItem.content
                entity.publishDate = newsItem.publishDate
                entity.category = newsItem.category.rawValue
                entity.isRead = false
            }
            
            if self.backgroundContext.hasChanges {
                try self.backgroundContext.save()
                Logger.info("保存新闻成功", log: .storage)
            }
        }
    }
    
    func fetchNews(category: NewsCategory? = nil) async throws -> [News] {
        try await backgroundContext.perform {
            let request = NewsEntity.fetchRequest()
            
            if let category = category {
                request.predicate = NSPredicate(format: "category == %@", category.rawValue)
            }
            
            request.sortDescriptors = [NSSortDescriptor(key: "publishDate", ascending: false)]
            
            let entities = try request.execute()
            return entities.map { entity in
                News(
                    id: entity.id,
                    title: entity.title,
                    content: entity.content,
                    publishDate: entity.publishDate,
                    category: NewsCategory(rawValue: entity.category) ?? .domestic
                )
            }
        }
    }
    
    func markAsRead(_ newsId: String) async throws {
        try await backgroundContext.perform {
            let request = NewsEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", newsId)
            
            if let news = try request.execute().first {
                news.isRead = true
                try self.backgroundContext.save()
                Logger.info("标记新闻已读: \(newsId)", log: .storage)
            }
        }
    }
    
    // MARK: - Cache Operations
    
    func clearOldCache() async throws {
        try await backgroundContext.perform {
            let request = NewsEntity.fetchRequest()
            let oldDate = Date().addingTimeInterval(-AppConfig.Cache.maxAge)
            request.predicate = NSPredicate(format: "publishDate < %@", oldDate as NSDate)
            
            let oldNews = try request.execute()
            oldNews.forEach { self.backgroundContext.delete($0) }
            
            if self.backgroundContext.hasChanges {
                try self.backgroundContext.save()
                Logger.info("清理旧缓存成功", log: .storage)
            }
        }
    }
}

// MARK: - Core Data Model
extension StorageService {
    class NewsEntity: NSManagedObject {
        @NSManaged var id: String
        @NSManaged var title: String
        @NSManaged var content: String
        @NSManaged var publishDate: Date
        @NSManaged var category: String
        @NSManaged var isRead: Bool
    }
} 