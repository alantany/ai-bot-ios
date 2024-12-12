import Foundation

actor NetworkService: ServiceProtocol {
    // MARK: - Singleton
    static let shared = NetworkService()
    private init() {}
    
    // MARK: - Properties
    private var urlSession: URLSession = .shared
    
    // 使用全局变量来存储状态
    private static var _isReady = false
    
    nonisolated var isReady: Bool {
        Self._isReady
    }
    
    // MARK: - ServiceProtocol
    func initialize() async throws {
        // 配置URLSession
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Constants.API.timeout
        configuration.timeoutIntervalForResource = Constants.API.timeout
        configuration.waitsForConnectivity = true
        
        urlSession = URLSession(configuration: configuration)
        Self._isReady = true
    }
    
    // MARK: - Public Methods
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard isReady else {
            throw NetworkError.networkError(NSError(domain: "NetworkService", code: -1, userInfo: [NSLocalizedDescriptionKey: "NetworkService not initialized"]))
        }
        
        do {
            guard let request = endpoint.asURLRequest() else {
                throw NetworkError.invalidRequest
            }
            Logger.shared.logNetworkRequest(request)
            
            let (data, response) = try await urlSession.data(for: request)
            Logger.shared.logNetworkResponse(response, data: data, error: nil)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    return try decoder.decode(T.self, from: data)
                } catch {
                    Logger.shared.error("Decoding error", error: error)
                    throw NetworkError.decodingError(error)
                }
            case 401:
                throw NetworkError.unauthorized
            case 500...599:
                throw NetworkError.serverError
            default:
                throw NetworkError.httpError(httpResponse.statusCode)
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            Logger.shared.error("Network request failed", error: error)
            throw NetworkError.networkError(error)
        }
    }
    
    func requestData(_ endpoint: Endpoint) async throws -> Data {
        guard isReady else {
            throw NetworkError.networkError(NSError(domain: "NetworkService", code: -1, userInfo: [NSLocalizedDescriptionKey: "NetworkService not initialized"]))
        }
        
        do {
            guard let request = endpoint.asURLRequest() else {
                throw NetworkError.invalidRequest
            }
            Logger.shared.logNetworkRequest(request)
            
            let (data, response) = try await urlSession.data(for: request)
            Logger.shared.logNetworkResponse(response, data: data, error: nil)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 401:
                throw NetworkError.unauthorized
            case 500...599:
                throw NetworkError.serverError
            default:
                throw NetworkError.httpError(httpResponse.statusCode)
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            Logger.shared.error("Network request failed", error: error)
            throw NetworkError.networkError(error)
        }
    }
    
    // MARK: - Mock Data Methods
    #if DEBUG
    func setMockData<T: Encodable>(_ mockData: T, for endpoint: Endpoint) {
        // TODO: 实现mock数据功能
    }
    
    func removeMockData(for endpoint: Endpoint) {
        // TODO: 实现移除mock数据功能
    }
    #endif
} 
