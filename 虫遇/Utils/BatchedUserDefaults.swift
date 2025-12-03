import Foundation
import UIKit

/**
 * 批量UserDefaults管理器
 * Phase 2优化 - 阶段1：UserDefaults批量优化
 * 
 * 功能：
 * - 将频繁的单次写入合并为批量写入
 * - 减少磁盘I/O操作
 * - 提供紧急写入机制
 * - 自动内存压力处理
 */
class BatchedUserDefaults {
    static let shared = BatchedUserDefaults()
    
    // MARK: - 配置
    private let batchInterval: TimeInterval = 0.5 // 500ms批量写入间隔
    private let maxBatchSize = 50 // 最大批量大小
    private let emergencyKeys: Set<String> = [
        "current_user_id",
        "user_login_status", 
        "critical_user_data"
    ] // 需要立即写入的关键数据
    
    // MARK: - 批量写入管理
    private var pendingWrites: [String: Any] = [:]
    private var writeTimer: Timer?
    private let writeQueue = DispatchQueue(label: "batched.userdefaults", qos: .utility)
    
    // MARK: - 性能监控
    private var batchCount = 0
    private var individualWrites = 0
    private var emergencyWrites = 0
    
    private init() {
        setupAppStateObservers()
    }
    
    // MARK: - 应用状态监控
    private func setupAppStateObservers() {
        // 应用进入后台时立即写入
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // 应用即将终止时立即写入
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        
        // 内存警告时立即写入
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func applicationDidEnterBackground() {
        #if DEBUG
        print("📱 应用进入后台，立即执行批量写入")
        #endif
        flushWrites()
    }
    
    @objc private func applicationWillTerminate() {
        #if DEBUG
        print("📱 应用即将终止，立即执行批量写入")
        #endif
        flushWrites()
    }
    
    @objc private func applicationDidReceiveMemoryWarning() {
        #if DEBUG
        print("🧠 内存警告，立即执行批量写入")
        #endif
        flushWrites()
    }
    
    // MARK: - 核心API
    
    /**
     * 设置值（批量模式）
     */
    func setValue(_ value: Any?, forKey key: String) {
        writeQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 检查是否为紧急key
            if self.emergencyKeys.contains(key) {
                // 立即写入关键数据
                UserDefaults.standard.set(value, forKey: key)
                self.emergencyWrites += 1
                #if DEBUG
                print("🚨 紧急写入: \(key)")
                #endif
                return
            }
            
            // 添加到批量写入队列
            if let value = value {
                self.pendingWrites[key] = value
            } else {
                // nil值表示删除
                self.pendingWrites[key] = NSNull()
            }
            
            // 检查是否需要立即写入（批量大小限制）
            if self.pendingWrites.count >= self.maxBatchSize {
                #if DEBUG
                print("📦 达到批量大小限制，立即写入")
                #endif
                self.flushWrites()
                return
            }
            
            // 调度批量写入
            self.scheduleWrite()
        }
    }
    
    /**
     * 获取值（直接从UserDefaults读取）
     */
    func getValue(forKey key: String) -> Any? {
        // 先检查待写入队列
        if let pendingValue = writeQueue.sync(execute: { pendingWrites[key] }) {
            if pendingValue is NSNull {
                return nil
            }
            return pendingValue
        }
        
        // 从UserDefaults读取
        return UserDefaults.standard.object(forKey: key)
    }
    
    /**
     * 删除值
     */
    func removeValue(forKey key: String) {
        setValue(nil, forKey: key)
    }
    
    /**
     * 立即写入所有待定数据
     */
    func flushWrites() {
        writeQueue.sync { [weak self] in
            guard let self = self else { return }
            
            guard !self.pendingWrites.isEmpty else {
                return
            }
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // 执行批量写入
            for (key, value) in self.pendingWrites {
                if value is NSNull {
                    UserDefaults.standard.removeObject(forKey: key)
                } else {
                    UserDefaults.standard.set(value, forKey: key)
                }
            }
            
            let writeCount = self.pendingWrites.count
            self.pendingWrites.removeAll()
            
            // 取消定时器
            DispatchQueue.main.async {
                self.writeTimer?.invalidate()
                self.writeTimer = nil
            }
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            self.batchCount += 1
            
            #if DEBUG
            print("💾 批量写入完成: \(writeCount)个键值对, 耗时: \(String(format: "%.1f", duration * 1000))ms")
            #endif
        }
    }
    
    // MARK: - 私有方法
    
    private func scheduleWrite() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 如果已有定时器，则不重复创建
            if self.writeTimer != nil {
                return
            }
            
            self.writeTimer = Timer.scheduledTimer(withTimeInterval: self.batchInterval, repeats: false) { _ in
                self.flushWrites()
            }
        }
    }
    
    // MARK: - 便捷方法
    
    /**
     * 设置字符串值
     */
    func setString(_ value: String?, forKey key: String) {
        setValue(value, forKey: key)
    }
    
    /**
     * 获取字符串值
     */
    func getString(forKey key: String) -> String? {
        return getValue(forKey: key) as? String
    }
    
    /**
     * 设置布尔值
     */
    func setBool(_ value: Bool, forKey key: String) {
        setValue(value, forKey: key)
    }
    
    /**
     * 获取布尔值
     */
    func getBool(forKey key: String) -> Bool {
        return getValue(forKey: key) as? Bool ?? false
    }
    
    /**
     * 设置整数值
     */
    func setInt(_ value: Int, forKey key: String) {
        setValue(value, forKey: key)
    }
    
    /**
     * 获取整数值
     */
    func getInt(forKey key: String) -> Int {
        return getValue(forKey: key) as? Int ?? 0
    }
    
    /**
     * 设置Double值
     */
    func setDouble(_ value: Double, forKey key: String) {
        setValue(value, forKey: key)
    }
    
    /**
     * 获取Double值
     */
    func getDouble(forKey key: String) -> Double {
        return getValue(forKey: key) as? Double ?? 0.0
    }
    
    // MARK: - 数组和字典支持
    
    /**
     * 设置数组值
     */
    func setArray(_ value: [Any]?, forKey key: String) {
        setValue(value, forKey: key)
    }
    
    /**
     * 获取数组值
     */
    func getArray(forKey key: String) -> [Any]? {
        return getValue(forKey: key) as? [Any]
    }
    
    /**
     * 设置字典值
     */
    func setDictionary(_ value: [String: Any]?, forKey key: String) {
        setValue(value, forKey: key)
    }
    
    /**
     * 获取字典值
     */
    func getDictionary(forKey key: String) -> [String: Any]? {
        return getValue(forKey: key) as? [String: Any]
    }
    
    // MARK: - 性能监控
    
    /**
     * 获取性能统计
     */
    func getPerformanceStats() -> (batches: Int, individual: Int, emergency: Int, pending: Int) {
        return writeQueue.sync {
            (
                batches: batchCount,
                individual: individualWrites,
                emergency: emergencyWrites,
                pending: pendingWrites.count
            )
        }
    }
    
    /**
     * 打印性能统计
     */
    func printPerformanceStats() {
        let stats = getPerformanceStats()
        #if DEBUG
        print("""
        📊 BatchedUserDefaults 性能统计:
        - 批量写入次数: \(stats.batches)
        - 单独写入次数: \(stats.individual)
        - 紧急写入次数: \(stats.emergency)
        - 待写入项目: \(stats.pending)
        - 节省写入次数: \(max(0, stats.individual - stats.batches))
        """)
        #endif
    }
    
    /**
     * 重置统计信息
     */
    func resetStats() {
        writeQueue.async { [weak self] in
            self?.batchCount = 0
            self?.individualWrites = 0
            self?.emergencyWrites = 0
        }
    }
}

// MARK: - 扩展功能

extension BatchedUserDefaults {
    
    /**
     * 批量设置多个值
     */
    func setBatch(_ values: [String: Any]) {
        writeQueue.async { [weak self] in
            guard let self = self else { return }
            
            for (key, value) in values {
                if self.emergencyKeys.contains(key) {
                    // 立即写入关键数据
                    UserDefaults.standard.set(value, forKey: key)
                    self.emergencyWrites += 1
                } else {
                    self.pendingWrites[key] = value
                }
            }
            
            #if DEBUG
            print("📦 批量设置 \(values.count) 个键值对")
            #endif
            
            // 如果批量大小超限，立即写入
            if self.pendingWrites.count >= self.maxBatchSize {
                self.flushWrites()
            } else {
                self.scheduleWrite()
            }
        }
    }
    
    /**
     * 检查是否有待写入的数据
     */
    func hasPendingWrites() -> Bool {
        return writeQueue.sync {
            return !pendingWrites.isEmpty
        }
    }
    
    /**
     * 获取待写入的键列表
     */
    func getPendingKeys() -> [String] {
        return writeQueue.sync {
            return Array(pendingWrites.keys)
        }
    }
} 