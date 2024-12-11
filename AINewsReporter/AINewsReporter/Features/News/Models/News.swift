import Foundation

// MARK: - News
struct News: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let summary: String?
    let source: String
    let author: String?
    let publishedAt: Date
    let url: URL
    let imageUrl: URL?
    let category: Category
    var aiSummary: String?
    
    // MARK: - Category
    enum Category: String, Codable, CaseIterable {
        case general = "综合"
        case technology = "科技"
        case business = "财经"
        case entertainment = "娱乐"
        case sports = "体育"
        case science = "科学"
        case health = "健康"
        
        var icon: String {
            switch self {
            case .general: return "newspaper"
            case .technology: return "laptopcomputer"
            case .business: return "chart.bar"
            case .entertainment: return "film"
            case .sports: return "sportscourt"
            case .science: return "atom"
            case .health: return "heart"
            }
        }
    }
}

// MARK: - NewsResponse
struct NewsResponse: Codable {
    let totalResults: Int
    let articles: [News]
    let nextPage: Int?
}

// MARK: - AIResponse
struct AIResponse: Codable {
    let summary: String
    let keywords: [String]
    let sentiment: Sentiment
    
    enum Sentiment: String, Codable {
        case positive = "积极"
        case neutral = "中性"
        case negative = "消极"
        
        var icon: String {
            switch self {
            case .positive: return "😊"
            case .neutral: return "😐"
            case .negative: return "😔"
            }
        }
    }
}

// MARK: - News Extensions
extension News {
    static var preview: News {
        News(
            id: UUID().uuidString,
            title: "苹果发布 iPhone 15 系列，搭载 A17 Pro 芯片",
            content: "苹果公司在秋季发布会上推出了全新的 iPhone 15 系列手机。新机型采用了最新的 A17 Pro 芯片，支持实时光线追踪，并首次使用 USB-C 接口。",
            summary: "苹果发布 iPhone 15，搭载 A17 Pro 芯片，支持光追，改用 USB-C 接口。",
            source: "科技日报",
            author: "张三",
            publishedAt: Date(),
            url: URL(string: "https://example.com/news/1")!,
            imageUrl: URL(string: "https://example.com/images/iphone15.jpg"),
            category: .technology
        )
    }
    
    static var previewList: [News] {
        [
            preview,
            News(
                id: UUID().uuidString,
                title: "世界杯预选赛：中国队2:1战胜泰国队",
                content: "在昨晚进行的2026世界杯预选赛中，中国队凭借武磊和张琳芃的进球，以2:1战胜泰国队。",
                summary: "世预赛中国2:1胜泰国，武磊、张琳芃建功。",
                source: "体育新闻",
                author: "李四",
                publishedAt: Date().addingTimeInterval(-3600),
                url: URL(string: "https://example.com/news/2")!,
                imageUrl: URL(string: "https://example.com/images/football.jpg"),
                category: .sports
            )
        ]
    }
} 