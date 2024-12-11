import Foundation

struct News: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let content: String
    let publishDate: Date
    let category: NewsCategory
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case publishDate = "publish_date"
        case category
    }
}

enum NewsCategory: String, Codable, CaseIterable {
    case domestic = "domestic"
    case international = "international"
    
    var displayName: String {
        switch self {
        case .domestic:
            return "国内新闻"
        case .international:
            return "国际新闻"
        }
    }
} 