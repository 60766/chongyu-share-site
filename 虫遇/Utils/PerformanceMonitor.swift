import Foundation
import SwiftUI

/**
 * 性能监控系统
 * Phase 2优化 - 性能监控与验证
 * 
 * 功能：
 * - 监控帖子切换时间
 * - 跟踪内存使用情况
 * - 测量缓存命中率
 * - 监控用户交互响应时间
 */
class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    // MARK: - 性能指标
    @Published var averagePostSwitchTime: TimeInterval = 0.0
    @Published var currentMemoryUsage: Double = 0.0
    @Published var cacheHitRatio: Double = 0.0
    @Published var averageCommentLoadTime: TimeInterval = 0.0
    
    // MARK: - 内部跟踪
    private var postSwitchTimes: [TimeInterval] = []
    private var commentLoadTimes: [TimeInterval] = []
    private var currentSwitchStartTime: CFAbsoluteTime?
    private var currentCommentLoadStartTime: CFAbsoluteTime?
    
    // MARK: - 统计数据
    private var totalPostSwitches = 0
    private var totalCommentLoads = 0
    private var performanceSamples: [PerformanceSample] = []
    
    // MARK: - 配置
    private let maxSamples = 100 // 最多保留100个样本
    
    private init() {
        startMemoryMonitoring()
    }
    
    // MARK: - 帖子切换性能监控
    
    /**
     * 开始监控帖子切换
     */
    func startPostSwitchMeasurement() {
        currentSwitchStartTime = CFAbsoluteTimeGetCurrent()
    }
    
    /**
     * 结束帖子切换监控
     */
    func endPostSwitchMeasurement() {
        guard let startTime = currentSwitchStartTime else { return }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        postSwitchTimes.append(duration)
        totalPostSwitches += 1
        
        // 保持最近50个样本
        if postSwitchTimes.count > 50 {
            postSwitchTimes.removeFirst()
        }
        
        // 更新平均时间
        averagePostSwitchTime = postSwitchTimes.reduce(0, +) / Double(postSwitchTimes.count)
        
        // 记录性能样本
        let sample = PerformanceSample(
            type: .postSwitch,
            duration: duration,
            timestamp: Date(),
            memoryUsage: getCurrentMemoryUsage()
        )
        addPerformanceSample(sample)
        
        #if DEBUG
        print("⏱️ 帖子切换耗时: \(String(format: "%.1f", duration * 1000))ms, 平均: \(String(format: "%.1f", averagePostSwitchTime * 1000))ms")
        #endif
        
        currentSwitchStartTime = nil
    }
    
    // MARK: - 评论加载性能监控
    
    /**
     * 开始监控评论加载
     */
    func startCommentLoadMeasurement() {
        currentCommentLoadStartTime = CFAbsoluteTimeGetCurrent()
    }
    
    /**
     * 结束评论加载监控
     */
    func endCommentLoadMeasurement() {
        guard let startTime = currentCommentLoadStartTime else { return }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        commentLoadTimes.append(duration)
        totalCommentLoads += 1
        
        // 保持最近30个样本
        if commentLoadTimes.count > 30 {
            commentLoadTimes.removeFirst()
        }
        
        // 更新平均时间
        averageCommentLoadTime = commentLoadTimes.reduce(0, +) / Double(commentLoadTimes.count)
        
        // 记录性能样本
        let sample = PerformanceSample(
            type: .commentLoad,
            duration: duration,
            timestamp: Date(),
            memoryUsage: getCurrentMemoryUsage()
        )
        addPerformanceSample(sample)
        
        #if DEBUG
        print("💬 评论加载耗时: \(String(format: "%.1f", duration * 1000))ms, 平均: \(String(format: "%.1f", averageCommentLoadTime * 1000))ms")
        #endif
        
        currentCommentLoadStartTime = nil
    }
    
    // MARK: - 内存监控
    
    private func startMemoryMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.currentMemoryUsage = self.getCurrentMemoryUsage()
            }
        }
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Double(info.resident_size) / (1024 * 1024) : 0.0
    }
    
    // MARK: - 缓存命中率监控
    
    /**
     * 更新缓存命中率
     */
    func updateCacheHitRatio() {
        let cacheStatus = IntelligentDataCache.shared.getCacheHitRatio()
        DispatchQueue.main.async {
            self.cacheHitRatio = cacheStatus
        }
    }
    
    // MARK: - 性能样本管理
    
    private func addPerformanceSample(_ sample: PerformanceSample) {
        performanceSamples.append(sample)
        
        // 保持样本数量限制
        if performanceSamples.count > maxSamples {
            performanceSamples.removeFirst()
        }
    }
    
    // MARK: - 性能报告
    
    /**
     * 生成性能报告
     */
    func generatePerformanceReport() -> PerformanceReport {
        updateCacheHitRatio()
        
        let cacheStats = IntelligentDataCache.shared.getCacheStatus()
        let batchedStats = BatchedUserDefaults.shared.getPerformanceStats()
        
        return PerformanceReport(
            averagePostSwitchTime: averagePostSwitchTime,
            averageCommentLoadTime: averageCommentLoadTime,
            currentMemoryUsage: currentMemoryUsage,
            cacheHitRatio: cacheHitRatio,
            totalPostSwitches: totalPostSwitches,
            totalCommentLoads: totalCommentLoads,
            cacheStats: cacheStats,
            batchedUserDefaultsStats: batchedStats,
            samples: Array(performanceSamples.suffix(20)) // 最近20个样本
        )
    }
    
    /**
     * 打印详细性能报告
     */
    func printDetailedReport() {
        let report = generatePerformanceReport()
        
        #if DEBUG
        print("""
        📊 Phase 2优化性能报告:
        ════════════════════════════════════════
        🚀 响应时间指标:
        - 平均帖子切换时间: \(String(format: "%.1f", report.averagePostSwitchTime * 1000))ms
        - 平均评论加载时间: \(String(format: "%.1f", report.averageCommentLoadTime * 1000))ms
        - 总帖子切换次数: \(report.totalPostSwitches)
        - 总评论加载次数: \(report.totalCommentLoads)
        
        🧠 内存使用:
        - 当前内存使用: \(String(format: "%.1f", report.currentMemoryUsage))MB
        
        📈 缓存效果:
        - 缓存命中率: \(String(format: "%.1f", report.cacheHitRatio * 100))%
        - 缓存帖子数: \(report.cacheStats.posts)
        - 缓存评论数: \(report.cacheStats.comments)
        
        💾 UserDefaults优化:
        - 批量写入次数: \(report.batchedUserDefaultsStats.batches)
        - 紧急写入次数: \(report.batchedUserDefaultsStats.emergency)
        - 待写入项目: \(report.batchedUserDefaultsStats.pending)
        ════════════════════════════════════════
        """)
        #endif
    }
    
    /**
     * 重置所有统计数据
     */
    func resetStats() {
        postSwitchTimes.removeAll()
        commentLoadTimes.removeAll()
        performanceSamples.removeAll()
        totalPostSwitches = 0
        totalCommentLoads = 0
        averagePostSwitchTime = 0.0
        averageCommentLoadTime = 0.0
    }
    
    // MARK: - 性能基准测试
    
    /**
     * 运行性能基准测试
     */
    func runBenchmark() {
        #if DEBUG
        print("🧪 开始Phase 2优化基准测试...")
        #endif
        
        // 测试缓存性能
        let cacheTestStart = CFAbsoluteTimeGetCurrent()
        for _ in 0..<100 {
            _ = IntelligentDataCache.shared.getCacheStatus()
        }
        let cacheTestDuration = CFAbsoluteTimeGetCurrent() - cacheTestStart
        
        // 测试批量UserDefaults性能
        let defaultsTestStart = CFAbsoluteTimeGetCurrent()
        for i in 0..<50 {
            BatchedUserDefaults.shared.setString("test_\(i)", forKey: "benchmark_\(i)")
        }
        BatchedUserDefaults.shared.flushWrites()
        let defaultsTestDuration = CFAbsoluteTimeGetCurrent() - defaultsTestStart
        
        #if DEBUG
        print("""
        🧪 基准测试结果:
        - 缓存操作100次耗时: \(String(format: "%.1f", cacheTestDuration * 1000))ms
        - 批量UserDefaults 50次耗时: \(String(format: "%.1f", defaultsTestDuration * 1000))ms
        """)
        #endif
    }
}

// MARK: - 数据结构

/**
 * 性能样本
 */
struct PerformanceSample {
    let type: PerformanceType
    let duration: TimeInterval
    let timestamp: Date
    let memoryUsage: Double
}

/**
 * 性能类型
 */
enum PerformanceType {
    case postSwitch
    case commentLoad
    case imageLoad
    case other
}

/**
 * 性能报告
 */
struct PerformanceReport {
    let averagePostSwitchTime: TimeInterval
    let averageCommentLoadTime: TimeInterval
    let currentMemoryUsage: Double
    let cacheHitRatio: Double
    let totalPostSwitches: Int
    let totalCommentLoads: Int
    let cacheStats: (posts: Int, comments: Int, hitRatio: Double)
    let batchedUserDefaultsStats: (batches: Int, individual: Int, emergency: Int, pending: Int)
    let samples: [PerformanceSample]
} 