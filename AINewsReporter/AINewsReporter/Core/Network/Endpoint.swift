import Foundation

enum Endpoint {
    case newsSummary(title: String, content: String, maxSummaryLen: Int = 200)  // 生成新闻摘要
    case textToSpeech(text: String)
    case sinaNews(category: String = "2510", num: Int = 10)  // 新浪新闻API
    
    private var baseURL: URL {
        switch self {
        case .newsSummary:
            return URL(string: "https://aip.baidubce.com/rpc/2.0/nlp/v1")!
        case .textToSpeech:
            return URL(string: "https://api.azure.com")!
        case .sinaNews:
            return URL(string: "https://feed.mix.sina.com.cn/api/roll/get")!
        }
    }
    
    private var path: String {
        switch self {
        case .newsSummary:
            return "/news_summary"
        case .textToSpeech:
            return "/v1/tts/synthesize"
        case .sinaNews:
            return ""
        }
    }
    
    private var queryItems: [URLQueryItem]? {
        switch self {
        case .newsSummary:
            return [
                URLQueryItem(name: "charset", value: "UTF-8")
            ]
        case .sinaNews(let category, let num):
            return [
                URLQueryItem(name: "pageid", value: "153"),
                URLQueryItem(name: "lid", value: category),
                URLQueryItem(name: "num", value: String(num)),
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "type", value: "1"),
                URLQueryItem(name: "level", value: "1,2,3"),
                URLQueryItem(name: "up", value: "0"),
                URLQueryItem(name: "down", value: "0"),
                URLQueryItem(name: "fields", value: "wapurl,title,media_name,keywords,create_time,url,intro,author,img")
            ]
        case .textToSpeech:
            return nil
        }
    }
    
    private var method: String {
        switch self {
        case .newsSummary, .textToSpeech:
            return "POST"
        case .sinaNews:
            return "GET"
        }
    }
    
    private var headers: [String: String] {
        switch self {
        case .newsSummary:
            return [
                "Content-Type": "application/json",
                "Accept": "application/json"
            ]
        case .textToSpeech:
            return [
                "Content-Type": "application/json",
                "Ocp-Apim-Subscription-Key": AppConfig.shared.azureApiKey ?? ""
            ]
        case .sinaNews:
            return [
                "Accept": "application/json",
                "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1"
            ]
        }
    }
    
    private var body: Data? {
        switch self {
        case .newsSummary(let title, let content, let maxSummaryLen):
            // 验证参数
            guard title.utf8.count <= 512 else {
                print("警告: 标题长度超过512字节限制")
                return nil
            }
            
            guard content.utf8.count <= 65535 else {
                print("警告: 正文长度超过65535字节限制")
                return nil
            }
            
            let params: [String: Any] = [
                "title": title,
                "content": content,
                "max_summary_len": maxSummaryLen
            ]
            return try? JSONSerialization.data(withJSONObject: params)
        case .textToSpeech(let text):
            let params = [
                "text": text,
                "language": "zh-CN",
                "voice": "zh-CN-XiaoxiaoNeural",
                "style": "newscast-casual"
            ]
            return try? JSONSerialization.data(withJSONObject: params)
        case .sinaNews:
            return nil  // GET请求不需要请求体
        }
    }
    
    func asURLRequest(accessToken: String? = nil) -> URLRequest? {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)!
        
        // 如果是新闻摘要API，需要添加access_token
        if case .newsSummary = self {
            var items = queryItems ?? []
            if let token = accessToken {
                items.append(URLQueryItem(name: "access_token", value: token))
            }
            components.queryItems = items
        } else {
            components.queryItems = queryItems
        }
        
        print("请求 URL: \(components.url!.absoluteString)")
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.timeoutInterval = 30
        
        // 添加请求头
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // 添加请求体（只有在有请求体的情况下才添加）
        if let body = body {
            request.httpBody = body
        }
        
        print("发送请求到: \(request.url!.absoluteString)")
        return request
    }
} 