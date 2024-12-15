import Foundation

struct News: Identifiable, Equatable {
    let id: String
    let title: String
    let content: String
    let publishedAt: Date
    
    init(from item: SinaNewsResponse.Result.NewsItem) {
        self.id = item.ctime
        self.title = item.title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        self.content = item.intro.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        // 解析日期
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.publishedAt = formatter.date(from: item.ctime) ?? Date()
    }
    
    // 添加预览数据
    static var preview: News {
        News(
            id: "1",
            title: "苹果发布 Vision Pro",
            content: "苹果公司在WWDC 2023上发布了革命性的混合现实设备Vision Pro，这款设备将改变我们与数字世界交互的方式。",
            publishedAt: Date()
        )
    }
    
    // 用于创建预览数据的初始化方法
    init(id: String, title: String, content: String, publishedAt: Date) {
        self.id = id
        self.title = title
        self.content = content
        self.publishedAt = publishedAt
    }
    
    // 实现 Equatable
    static func == (lhs: News, rhs: News) -> Bool {
        return lhs.id == rhs.id
    }
} 