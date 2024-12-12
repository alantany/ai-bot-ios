import Foundation

struct SinaNewsResponse: Codable {
    let result: Result
    
    struct Result: Codable {
        let status: Status
        let data: [NewsItem]
        
        struct Status: Codable {
            let code: Int
            let msg: String
        }
        
        struct NewsItem: Codable {
            let title: String
            let intro: String
            let ctime: String
            
            // 其他字段我们不需要，可以忽略
            private enum CodingKeys: String, CodingKey {
                case title
                case intro
                case ctime
            }
        }
    }
} 