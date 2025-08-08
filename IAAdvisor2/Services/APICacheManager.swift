import Foundation
import CommonCrypto

class APICacheManager {
    nonisolated static let shared = APICacheManager()
    
    private let cache = NSCache<NSString, CachedResponse>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    // 缓存配置
    private let memoryLimit = 50 * 1024 * 1024  // 50MB
    private let diskLimit = 100 * 1024 * 1024   // 100MB
    private let defaultTTL: TimeInterval = 300   // 5分钟
    
    private init() {
        // 配置内存缓存
        cache.totalCostLimit = memoryLimit
        cache.countLimit = 100
        
        // 设置磁盘缓存目录
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("APICache")
        
        // 创建缓存目录
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // 定期清理过期缓存
        startCacheCleanupTimer()
    }
    
    // MARK: - 缓存操作
    
    func cacheResponse(_ data: Data, for key: String, ttl: TimeInterval = 0) {
        let actualTTL = ttl > 0 ? ttl : defaultTTL
        let cachedResponse = CachedResponse(
            data: data,
            timestamp: Date(),
            ttl: actualTTL
        )
        
        // 内存缓存
        cache.setObject(cachedResponse, forKey: key as NSString, cost: data.count)
        
        // 磁盘缓存（异步）
        Task {
            await saveToDisk(cachedResponse, key: key)
        }
    }
    
    func getCachedResponse(for key: String) -> Data? {
        // 先查内存缓存
        if let cached = cache.object(forKey: key as NSString) {
            if cached.isValid {
                return cached.data
            } else {
                cache.removeObject(forKey: key as NSString)
            }
        }
        
        // 再查磁盘缓存
        if let cached = loadFromDisk(key: key), cached.isValid {
            // 重新加载到内存
            cache.setObject(cached, forKey: key as NSString, cost: cached.data.count)
            return cached.data
        }
        
        return nil
    }
    
    func removeCachedResponse(for key: String) {
        cache.removeObject(forKey: key as NSString)
        removeDiskCache(key: key)
    }
    
    func clearCache() {
        cache.removeAllObjects()
        clearDiskCache()
    }
    
    // MARK: - 磁盘缓存操作
    
    private func saveToDisk(_ response: CachedResponse, key: String) async {
        let url = diskCacheURL(for: key)
        do {
            let data = try JSONEncoder().encode(response)
            try data.write(to: url)
        } catch {
            print("API缓存: 磁盘写入失败 - \(error)")
        }
    }
    
    private func loadFromDisk(key: String) -> CachedResponse? {
        let url = diskCacheURL(for: key)
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(CachedResponse.self, from: data)
        } catch {
            return nil
        }
    }
    
    private func removeDiskCache(key: String) {
        let url = diskCacheURL(for: key)
        try? fileManager.removeItem(at: url)
    }
    
    private func clearDiskCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    private func diskCacheURL(for key: String) -> URL {
        let filename = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        return cacheDirectory.appendingPathComponent("\(filename).cache")
    }
    
    // MARK: - 缓存清理
    
    private func startCacheCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            self.cleanupExpiredCache()
        }
    }
    
    private func cleanupExpiredCache() {
        // 清理过期的磁盘缓存
        Task {
            await cleanupDiskCache()
        }
    }
    
    private func cleanupDiskCache() async {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
            
            for file in files {
                if let key = extractKeyFromFilename(file.lastPathComponent),
                   let cached = loadFromDisk(key: key),
                   !cached.isValid {
                    try? fileManager.removeItem(at: file)
                }
            }
        } catch {
            print("API缓存: 清理失败 - \(error)")
        }
    }
    
    private func extractKeyFromFilename(_ filename: String) -> String? {
        let key = filename.replacingOccurrences(of: ".cache", with: "")
        return key.removingPercentEncoding
    }
    
    // MARK: - 缓存键生成
    
    static func cacheKey(endpoint: String, method: String, body: Data? = nil) -> String {
        var components = [endpoint, method]
        
        if let body = body,
           let bodyString = String(data: body, encoding: .utf8) {
            components.append(bodyString)
        }
        
        let combined = components.joined(separator: "|")
        return combined.sha256
    }
}

// MARK: - 缓存响应模型

private class CachedResponse: NSObject, Codable {
    let data: Data
    let timestamp: Date
    let ttl: TimeInterval
    
    init(data: Data, timestamp: Date, ttl: TimeInterval) {
        self.data = data
        self.timestamp = timestamp
        self.ttl = ttl
    }
    
    var isValid: Bool {
        return Date().timeIntervalSince(timestamp) < ttl
    }
}

// MARK: - String Extension for SHA256

private extension String {
    var sha256: String {
        let data = self.data(using: .utf8)!
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

