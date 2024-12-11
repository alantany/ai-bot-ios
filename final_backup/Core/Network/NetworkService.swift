import Foundation

class NetworkService {
    private let baseURL: URL
    
    init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        // 使用模拟数据
        if T.self == [News].self {
            let mockNews = [
                News(
                    id: "1",
                    title: "中国经济持续复苏",
                    content: "最新数据显示，中国经济继续保持稳定复苏态势，多个关键指标持续改善。制造业PMI连续三个月保持在扩张区间，消费市场活力明显增强，外贸进出口保持增长。",
                    category: .domestic,
                    publishDate: Date()
                ),
                News(
                    id: "2",
                    title: "新能源汽车产业蓬勃发展",
                    content: "我国新能源汽车产业发展势头强劲，产销量连续8年位居全球第一。多家车企推出新款电动汽车，充电基础设施建设加快，产业链不断完善。",
                    category: .domestic,
                    publishDate: Date().addingTimeInterval(-3600)
                ),
                News(
                    id: "3",
                    title: "全球气候变化会议召开",
                    content: "联合国气候变化大会在迪拜举行，与会各国就减排目标达成新共识。多国承诺加大清洁能源投入，推动绿色转型，共同应对气候变化挑战。",
                    category: .international,
                    publishDate: Date().addingTimeInterval(-7200)
                ),
                News(
                    id: "4",
                    title: "国际贸易新格局形成",
                    content: "随着区域全面经济伙伴关系协定（RCEP）的深入实施，亚太地区贸易合作不断加强，数字经济、绿色贸易等新业态快速发展，推动国际贸易格局深刻变革。",
                    category: .international,
                    publishDate: Date().addingTimeInterval(-10800)
                )
            ]
            return mockNews as! T
        }
        
        throw NSError(domain: "NetworkService", code: -1, userInfo: [NSLocalizedDescriptionKey: "暂无数据"])
    }
} 