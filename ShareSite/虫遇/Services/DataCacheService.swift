import Foundation
import SwiftUI
import Combine

/**
 * 数据缓存服务
 * 统一管理应用中各种数据的缓存，减少重复加载和计算
 */
class DataCacheService: ObservableObject {
    // 单例实例
    static let shared = DataCacheService()
    
    // 缓存存储
    private var cache: [String: CacheEntry] = [:]
    
    // 缓存条目过期时间（秒）
    private let defaultExpirationTime: TimeInterval = 300 // 5分钟
    
    // 发布者，用于通知数据更新
    private var dataUpdateSubject = PassthroughSubject<String, Never>()
    var dataUpdates: AnyPublisher<String, Never> {
        dataUpdateSubject.eraseToAnyPublisher()
    }
    
    // 缓存命中统计
    private var cacheHits: [String: Int] = [:]
    private var cacheMisses: [String: Int] = [:]
    
    private init() {
        // 注册应用生命周期通知
        setupLifecycleObservers()
        
        print("🗄️ 数据缓存服务初始化")
    }
    
    // MARK: - 缓存条目结构
    
    /// 缓存条目
    private struct CacheEntry {
        let value: Any
        let expirationDate: Date
        let type: String
        
        var isExpired: Bool {
            return Date() > expirationDate
        }
    }
    
    // MARK: - 公共接口
    
    /**
     * 存储数据到缓存
     * @param key 缓存键
     * @param value 要缓存的数据
     * @param type 数据类型描述
     * @param expirationTime 过期时间（秒），默认为5分钟
     */
    func store<T>(key: String, value: T, type: String, expirationTime: TimeInterval? = nil) {
        let expiration = Date().addingTimeInterval(expirationTime ?? defaultExpirationTime)
        let entry = CacheEntry(value: value, expirationDate: expiration, type: type)
        
        cache[key] = entry
        dataUpdateSubject.send(key)
        
        #if DEBUG
        print("🗄️ 缓存数据: \(key) (\(type))")
        #endif
    }
    
    /**
     * 从缓存获取数据
     * @param key 缓存键
     * @param defaultValue 默认值，如果缓存不存在或已过期
     * @return 缓存的数据或默认值
     */
    func retrieve<T>(key: String, defaultValue: T? = nil) -> T? {
        guard let entry = cache[key], !entry.isExpired else {
            // 缓存未命中或已过期
            cacheMisses[key] = (cacheMisses[key] ?? 0) + 1
            
            if cache[key] != nil {
                // 缓存已过期，清除
                cache.removeValue(forKey: key)
                #if DEBUG
                print("🗄️ 缓存过期: \(key)")
                #endif
            }
            
            return defaultValue
        }
        
        // 缓存命中
        cacheHits[key] = (cacheHits[key] ?? 0) + 1
        
        guard let value = entry.value as? T else {
            #if DEBUG
            print("⚠️ 缓存类型不匹配: \(key), 期望 \(T.self), 实际 \(type(of: entry.value))")
            #endif
            return defaultValue
        }
        
        return value
    }
    
    /**
     * 检查缓存是否存在且有效
     * @param key 缓存键
     * @return 缓存是否有效
     */
    func isValid(key: String) -> Bool {
        guard let entry = cache[key] else {
            return false
        }
        
        return !entry.isExpired
    }
    
    /**
     * 获取缓存的剩余有效时间（秒）
     * @param key 缓存键
     * @return 剩余有效时间，如果缓存不存在或已过期则返回0
     */
    func timeToLive(key: String) -> TimeInterval {
        guard let entry = cache[key], !entry.isExpired else {
            return 0
        }
        
        return entry.expirationDate.timeIntervalSinceNow
    }
    
    /**
     * 清除特定键的缓存
     * @param key 缓存键
     */
    func invalidate(key: String) {
        cache.removeValue(forKey: key)
        #if DEBUG
        print("🗄️ 缓存已清除: \(key)")
        #endif
    }
    
    /**
     * 清除特定前缀的所有缓存
     * @param prefix 缓存键前缀
     */
    func invalidateWithPrefix(prefix: String) {
        let keysToRemove = cache.keys.filter { $0.hasPrefix(prefix) }
        
        for key in keysToRemove {
            cache.removeValue(forKey: key)
        }
        
        #if DEBUG
        print("🗄️ 已清除\(keysToRemove.count)个前缀为'\(prefix)'的缓存")
        #endif
    }
    
    /**
     * 清除所有缓存
     */
    func invalidateAll() {
        cache.removeAll()
        #if DEBUG
        print("🗄️ 已清除所有缓存")
        #endif
    }
    
    /**
     * 清除所有过期缓存
     */
    func cleanExpiredCache() {
        let expiredKeys = cache.filter { $0.value.isExpired }.keys
        
        for key in expiredKeys {
            cache.removeValue(forKey: key)
        }
        
        #if DEBUG
        if !expiredKeys.isEmpty {
            print("🗄️ 已清除\(expiredKeys.count)个过期缓存")
        }
        #endif
    }
    
    // MARK: - 生命周期管理
    
    private func setupLifecycleObservers() {
        // 应用进入后台时清理过期缓存
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // 应用内存警告时清理所有非关键缓存
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func applicationDidEnterBackground() {
        cleanExpiredCache()
    }
    
    @objc private func didReceiveMemoryWarning() {
        // 内存警告时，清理所有非关键缓存
        let nonCriticalPrefixes = ["stats.", "recommendations.", "history."]
        
        for prefix in nonCriticalPrefixes {
            invalidateWithPrefix(prefix: prefix)
        }
        
        #if DEBUG
        print("⚠️ 收到内存警告，已清理非关键缓存")
        #endif
    }
    
    // MARK: - 调试信息
    
    #if DEBUG
    /// 打印缓存统计信息
    func printCacheStats() {
        let totalEntries = cache.count
        let expiredEntries = cache.filter { $0.value.isExpired }.count
        let validEntries = totalEntries - expiredEntries
        
        let totalHits = cacheHits.values.reduce(0, +)
        let totalMisses = cacheMisses.values.reduce(0, +)
        let hitRate = totalHits + totalMisses > 0 ? Double(totalHits) / Double(totalHits + totalMisses) : 0
        
        print("📊 缓存统计:")
        print("   - 总条目数: \(totalEntries)")
        print("   - 有效条目: \(validEntries)")
        print("   - 过期条目: \(expiredEntries)")
        print("   - 命中次数: \(totalHits)")
        print("   - 未命中次数: \(totalMisses)")
        print("   - 命中率: \(String(format: "%.2f%%", hitRate * 100))")
        
        // 打印最常用的缓存键
        let topHits = cacheHits.sorted { $0.value > $1.value }.prefix(5)
        if !topHits.isEmpty {
            print("   - 最常用的缓存键:")
            for (key, hits) in topHits {
                print("     * \(key): \(hits)次")
            }
        }
    }
    #endif
} 