import Foundation

actor StorageService: ServiceProtocol {
    // MARK: - Singleton
    static let shared = StorageService()
    private init() {}
    
    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    private var cachePath: URL?
    
    // 使用全局变量来存储状态
    private static var _isReady = false
    
    nonisolated var isReady: Bool {
        Self._isReady
    }
    
    // MARK: - ServiceProtocol
    func initialize() async throws {
        // 设置缓存目录
        if let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let appCache = cacheDir.appendingPathComponent("com.ainews.reporter", isDirectory: true)
            
            if !fileManager.fileExists(atPath: appCache.path) {
                try fileManager.createDirectory(at: appCache, withIntermediateDirectories: true)
            }
            
            cachePath = appCache
            Self._isReady = true
            
            // 清理过期缓存
            await cleanExpiredCache()
        }
    }
    
    // MARK: - UserDefaults Methods
    func setValue<T>(_ value: T, forKey key: String) where T: Encodable {
        if let encoded = try? JSONEncoder().encode(value) {
            userDefaults.set(encoded, forKey: key)
        }
    }
    
    func getValue<T>(forKey key: String, type: T.Type) -> T? where T: Decodable {
        guard let data = userDefaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(type, from: data) else {
            return nil
        }
        return decoded
    }
    
    func removeValue(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    // MARK: - File Cache Methods
    func cacheData(_ data: Data, forKey key: String) async throws {
        guard let cachePath = cachePath else {
            throw StorageError.notInitialized
        }
        
        let fileURL = cachePath.appendingPathComponent(key)
        
        do {
            try data.write(to: fileURL)
            
            // 记录缓存时间
            let metadata = CacheMetadata(key: key, timestamp: Date())
            setValue(metadata, forKey: "cache_meta_\(key)")
            
            Logger.shared.info("Cached data for key: \(key)")
        } catch {
            Logger.shared.error("Failed to cache data", error: error)
            throw StorageError.writeFailed(error)
        }
    }
    
    func getCachedData(forKey key: String) async throws -> Data {
        guard let cachePath = cachePath else {
            throw StorageError.notInitialized
        }
        
        let fileURL = cachePath.appendingPathComponent(key)
        
        do {
            let data = try Data(contentsOf: fileURL)
            
            // 检查是否过期
            if let metadata: CacheMetadata = getValue(forKey: "cache_meta_\(key)", type: CacheMetadata.self),
               Date().timeIntervalSince(metadata.timestamp) > Constants.Cache.maxAge {
                try await removeCache(forKey: key)
                throw StorageError.expired
            }
            
            return data
        } catch {
            Logger.shared.error("Failed to read cached data", error: error)
            throw StorageError.readFailed(error)
        }
    }
    
    func removeCache(forKey key: String) async throws {
        guard let cachePath = cachePath else {
            throw StorageError.notInitialized
        }
        
        let fileURL = cachePath.appendingPathComponent(key)
        
        do {
            try fileManager.removeItem(at: fileURL)
            removeValue(forKey: "cache_meta_\(key)")
            Logger.shared.info("Removed cache for key: \(key)")
        } catch {
            Logger.shared.error("Failed to remove cache", error: error)
            throw StorageError.deleteFailed(error)
        }
    }
    
    // MARK: - Cache Management
    private func cleanExpiredCache() async {
        guard let cachePath = cachePath else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: cachePath, includingPropertiesForKeys: nil)
            for file in files {
                let key = file.lastPathComponent
                if let metadata: CacheMetadata = getValue(forKey: "cache_meta_\(key)", type: CacheMetadata.self),
                   Date().timeIntervalSince(metadata.timestamp) > Constants.Cache.maxAge {
                    try? await removeCache(forKey: key)
                }
            }
            
            // 检查缓存大小
            let cacheSize = try await calculateCacheSize()
            if cacheSize > Constants.Cache.maxSize {
                try await clearCache()
            }
            
            Logger.shared.info("Cache cleanup completed")
        } catch {
            Logger.shared.error("Cache cleanup failed", error: error)
        }
    }
    
    private func calculateCacheSize() async throws -> Int {
        guard let cachePath = cachePath else {
            throw StorageError.notInitialized
        }
        
        let files = try fileManager.contentsOfDirectory(at: cachePath, includingPropertiesForKeys: [.fileSizeKey])
        return try files.reduce(0) { try $0 + ($1.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) }
    }
    
    func clearCache() async throws {
        guard let cachePath = cachePath else {
            throw StorageError.notInitialized
        }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: cachePath, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
                removeValue(forKey: "cache_meta_\(file.lastPathComponent)")
            }
            Logger.shared.info("Cache cleared")
        } catch {
            Logger.shared.error("Failed to clear cache", error: error)
            throw StorageError.clearFailed(error)
        }
    }
}

// MARK: - Supporting Types
private struct CacheMetadata: Codable {
    let key: String
    let timestamp: Date
}

// MARK: - Storage Errors
enum StorageError: LocalizedError {
    case notInitialized
    case writeFailed(Error)
    case readFailed(Error)
    case deleteFailed(Error)
    case clearFailed(Error)
    case expired
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "存储服务未初始化"
        case .writeFailed(let error):
            return "写入失败: \(error.localizedDescription)"
        case .readFailed(let error):
            return "读取失败: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "删除失败: \(error.localizedDescription)"
        case .clearFailed(let error):
            return "清理失败: \(error.localizedDescription)"
        case .expired:
            return "缓存已过期"
        }
    }
} 