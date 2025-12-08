import Foundation

/**
 * 虫洞探索生成数量管理器
 * 负责管理不同内容类型的生成数量设置
 */
class ExplorationCountManager {
    // 单例实例
    static let shared = ExplorationCountManager()
    
    // 默认生成数量
    private let defaultCount = 6
    
    // 生成数量范围
    private let minCount = 1
    private let maxCount = 12
    
    // 存储不同内容类型的生成数量
    private var contentTypeCounts: [String: Int] = [:]
    
    // 初始化
    private init() {
        loadCounts()
        #if DEBUG
        debugLog("🔢 ExplorationCountManager初始化完成，加载配置: \(contentTypeCounts)")
        #endif
    }
    
    /**
     * 获取指定内容类型的生成数量
     */
    func getCount(for contentType: ContentGeneratorService.ContentType) -> Int {
        let typeKey = contentType.rawValue
        
        // 如果没有设置过，返回默认值
        guard let count = contentTypeCounts[typeKey] else {
            return defaultCount
        }
        
        return count
    }
    
    /**
     * 增加指定内容类型的生成数量
     * 返回更新后的数量
     */
    func increaseCount(for contentType: ContentGeneratorService.ContentType) -> Int {
        let typeKey = contentType.rawValue
        let currentCount = contentTypeCounts[typeKey] ?? defaultCount
        
        // 确保不超过最大值
        let newCount = min(currentCount + 1, maxCount)
        
        // 更新并保存
        contentTypeCounts[typeKey] = newCount
        saveCounts()
        
        #if DEBUG
        debugLog("📈 增加「\(typeKey)」生成数量: \(currentCount) → \(newCount)")
        #endif
        return newCount
    }
    
    /**
     * 减少指定内容类型的生成数量
     * 返回更新后的数量
     */
    func decreaseCount(for contentType: ContentGeneratorService.ContentType) -> Int {
        let typeKey = contentType.rawValue
        let currentCount = contentTypeCounts[typeKey] ?? defaultCount
        
        // 确保不低于最小值
        let newCount = max(currentCount - 1, minCount)
        
        // 更新并保存
        contentTypeCounts[typeKey] = newCount
        saveCounts()
        
        #if DEBUG
        debugLog("📉 减少「\(typeKey)」生成数量: \(currentCount) → \(newCount)")
        #endif
        return newCount
    }
    
    /**
     * 设置指定内容类型的生成数量
     * 返回更新后的数量
     */
    func setCount(_ count: Int, for contentType: ContentGeneratorService.ContentType) -> Int {
        let typeKey = contentType.rawValue
        let currentCount = contentTypeCounts[typeKey] ?? defaultCount
        
        // 确保在有效范围内
        let newCount = max(minCount, min(count, maxCount))
        
        // 更新并保存
        contentTypeCounts[typeKey] = newCount
        saveCounts()
        
        #if DEBUG
        debugLog("🔄 设置「\(typeKey)」生成数量: \(currentCount) → \(newCount)")
        #endif
        return newCount
    }
    
    /**
     * 重置指定内容类型的生成数量为默认值
     * 返回更新后的数量
     */
    func resetCount(for contentType: ContentGeneratorService.ContentType) -> Int {
        let typeKey = contentType.rawValue
        let currentCount = contentTypeCounts[typeKey] ?? defaultCount
        
        // 重置为默认值
        contentTypeCounts[typeKey] = defaultCount
        saveCounts()
        
        #if DEBUG
        debugLog("🔄 重置「\(typeKey)」生成数量: \(currentCount) → \(defaultCount)")
        #endif
        return defaultCount
    }
    
    /**
     * 重置所有内容类型的生成数量为默认值
     */
    func resetAllCounts() {
        contentTypeCounts.removeAll()
        saveCounts()
        #if DEBUG
        debugLog("🔄 已重置所有内容类型的生成数量为默认值 \(defaultCount)")
        #endif
    }
    
    /**
     * 打印所有内容类型的当前生成数量
     * 用于调试
     */
    func printAllCounts() {
        #if DEBUG
        debugLog("📊 当前所有内容类型生成数量配置:")
        #endif
        
        if contentTypeCounts.isEmpty {
            #if DEBUG
            debugLog("   - 暂无自定义配置，所有类型使用默认值: \(defaultCount)")
            #endif
            return
        }
        
        for (type, count) in contentTypeCounts {
            #if DEBUG
            debugLog("   - \(type): \(count)")
            #endif
        }
    }
    
    // MARK: - 私有方法
    
    /**
     * 保存所有内容类型的生成数量到UserDefaults
     */
    private func saveCounts() {
        UserDefaults.standard.set(contentTypeCounts, forKey: "ExplorationContentTypeCounts")
        UserDefaults.standard.synchronize()
    }
    
    /**
     * 从UserDefaults加载所有内容类型的生成数量
     */
    private func loadCounts() {
        if let savedCounts = UserDefaults.standard.dictionary(forKey: "ExplorationContentTypeCounts") as? [String: Int] {
            contentTypeCounts = savedCounts
        }
    }
} 