import Foundation
import SwiftUI

/**
 * 智能数据缓存系统
 * Phase 2优化 - 阶段1：低风险高收益优化
 * 
 * 功能：
 * - 帖子数据智能缓存
 * - 评论数据预加载
 * - 预测性数据获取
 * - 内存压力自适应清理
 */
class IntelligentDataCache: ObservableObject {
    static let shared = IntelligentDataCache()
    
    // MARK: - 缓存存储
    private var postDataCache: [UUID: UserPostModel] = [:]
    private var commentCache: [UUID: [DetailedCommentModel]] = [:]
    private var viewModelCache: [UUID: Any] = [:]
    
    // MARK: - 缓存策略配置
    private let maxPostCacheSize = 50 // 最多缓存50个帖子
    private let maxCommentCacheSize = 30 // 最多缓存30个帖子的评论
    private let prefetchDistance = 3 // 预加载前后3个帖子
    
    // MARK: - 访问跟踪（LRU实现）
    private var postAccessOrder: [UUID] = []
    private var commentAccessOrder: [UUID] = []
    
    // MARK: - 线程安全
    private let cacheQueue = DispatchQueue(label: "intelligent.cache", qos: .utility, attributes: .concurrent)
    
    // MARK: - 性能监控
    private var cacheHits = 0
    private var cacheMisses = 0
    
    private init() {
        setupMemoryWarningObserver()
    }
    
    // MARK: - 内存压力监控
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        print("🧠 收到内存警告，开始智能清理缓存")
        cleanupLeastRecentlyUsedCache()
    }
    
    // MARK: - 帖子缓存管理
    
    /**
     * 获取帖子数据（智能缓存）
     */
    func getPost(id: UUID) -> UserPostModel? {
        return cacheQueue.sync {
            if let cachedPost = postDataCache[id] {
                // 更新访问顺序
                updatePostAccessOrder(id)
                cacheHits += 1
                print("📈 帖子缓存命中: \(id)")
                return cachedPost
            } else {
                cacheMisses += 1
                print("📉 帖子缓存未命中: \(id)")
                return nil
            }
        }
    }
    
    /**
     * 缓存帖子数据
     */
    func cachePost(_ post: UserPostModel) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            self.postDataCache[post.id] = post
            self.updatePostAccessOrder(post.id)
            
            // 检查缓存大小限制
            if self.postDataCache.count > self.maxPostCacheSize {
                self.evictOldestPost()
            }
            
            print("💾 已缓存帖子: \(post.id)")
        }
    }
    
    /**
     * 预测性预加载相邻帖子
     */
    func prefetchAdjacentPosts(currentPostId: UUID, posts: [UserPostModel]) {
        guard let currentIndex = posts.firstIndex(where: { $0.id == currentPostId }) else {
            return
        }
        
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 预加载前后N个帖子
            let startIndex = max(0, currentIndex - self.prefetchDistance)
            let endIndex = min(posts.count - 1, currentIndex + self.prefetchDistance)
            
            for i in startIndex...endIndex {
                let post = posts[i]
                if self.postDataCache[post.id] == nil {
                    self.postDataCache[post.id] = post
                    print("🔮 预加载帖子: \(post.id)")
                }
            }
        }
    }
    
    // MARK: - 评论缓存管理
    
    /**
     * 获取评论数据（智能缓存）
     */
    func getComments(for postId: UUID) -> [DetailedCommentModel]? {
        return cacheQueue.sync {
            if let cachedComments = commentCache[postId] {
                updateCommentAccessOrder(postId)
                cacheHits += 1
                print("📈 评论缓存命中: \(postId)")
                return cachedComments
            } else {
                cacheMisses += 1
                print("📉 评论缓存未命中: \(postId)")
                return nil
            }
        }
    }
    
    /**
     * 缓存评论数据
     */
    func cacheComments(_ comments: [DetailedCommentModel], for postId: UUID) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            self.commentCache[postId] = comments
            self.updateCommentAccessOrder(postId)
            
            // 检查缓存大小限制
            if self.commentCache.count > self.maxCommentCacheSize {
                self.evictOldestComments()
            }
            
            print("💾 已缓存评论: \(postId), 数量: \(comments.count)")
        }
    }
    
    /**
     * 更新评论缓存（用于新增评论后）
     */
    func updateComments(_ comments: [DetailedCommentModel], for postId: UUID) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.commentCache[postId] = comments
            print("🔄 已更新评论缓存: \(postId)")
        }
    }
    
    // MARK: - LRU访问顺序管理
    
    private func updatePostAccessOrder(_ postId: UUID) {
        postAccessOrder.removeAll { $0 == postId }
        postAccessOrder.append(postId)
    }
    
    private func updateCommentAccessOrder(_ postId: UUID) {
        commentAccessOrder.removeAll { $0 == postId }
        commentAccessOrder.append(postId)
    }
    
    // MARK: - 缓存清理
    
    private func evictOldestPost() {
        guard let oldestPostId = postAccessOrder.first else { return }
        postDataCache.removeValue(forKey: oldestPostId)
        postAccessOrder.removeFirst()
        print("🗑️ 清理最旧帖子缓存: \(oldestPostId)")
    }
    
    private func evictOldestComments() {
        guard let oldestPostId = commentAccessOrder.first else { return }
        commentCache.removeValue(forKey: oldestPostId)
        commentAccessOrder.removeFirst()
        print("🗑️ 清理最旧评论缓存: \(oldestPostId)")
    }
    
    /**
     * 智能清理最少使用的缓存
     */
    private func cleanupLeastRecentlyUsedCache() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // 清理一半的缓存
            let postsToRemove = self.postAccessOrder.count / 2
            let commentsToRemove = self.commentAccessOrder.count / 2
            
            // 清理帖子缓存
            for _ in 0..<postsToRemove {
                self.evictOldestPost()
            }
            
            // 清理评论缓存
            for _ in 0..<commentsToRemove {
                self.evictOldestComments()
            }
            
            print("🧹 内存压力清理完成，剩余帖子: \(self.postDataCache.count), 剩余评论: \(self.commentCache.count)")
        }
    }
    
    /**
     * 手动清理所有缓存
     */
    func clearAllCache() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.postDataCache.removeAll()
            self?.commentCache.removeAll()
            self?.viewModelCache.removeAll()
            self?.postAccessOrder.removeAll()
            self?.commentAccessOrder.removeAll()
            print("🧹 已清理所有智能缓存")
        }
    }
    
    // MARK: - 性能监控
    
    /**
     * 获取缓存命中率
     */
    func getCacheHitRatio() -> Double {
        let total = cacheHits + cacheMisses
        return total > 0 ? Double(cacheHits) / Double(total) : 0.0
    }
    
    /**
     * 获取缓存状态
     */
    func getCacheStatus() -> (posts: Int, comments: Int, hitRatio: Double) {
        return cacheQueue.sync {
            (
                posts: postDataCache.count,
                comments: commentCache.count,
                hitRatio: getCacheHitRatio()
            )
        }
    }
    
    /**
     * 打印缓存统计信息
     */
    func printCacheStats() {
        let status = getCacheStatus()
        print("""
        📊 智能缓存统计:
        - 缓存帖子数: \(status.posts)/\(maxPostCacheSize)
        - 缓存评论数: \(status.comments)/\(maxCommentCacheSize)
        - 命中率: \(String(format: "%.1f", status.hitRatio * 100))%
        - 命中次数: \(cacheHits)
        - 未命中次数: \(cacheMisses)
        """)
    }
}

// MARK: - 扩展方法

extension IntelligentDataCache {
    
    /**
     * 批量预加载帖子数据
     */
    func batchPrefetchPosts(_ posts: [UserPostModel]) {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            for post in posts {
                if self.postDataCache[post.id] == nil && self.postDataCache.count < self.maxPostCacheSize {
                    self.postDataCache[post.id] = post
                }
            }
            
            print("📦 批量预加载 \(posts.count) 个帖子")
        }
    }
    
    /**
     * 检查帖子是否已缓存
     */
    func isPostCached(_ postId: UUID) -> Bool {
        return cacheQueue.sync {
            return postDataCache[postId] != nil
        }
    }
    
    /**
     * 检查评论是否已缓存
     */
    func areCommentsCached(for postId: UUID) -> Bool {
        return cacheQueue.sync {
            return commentCache[postId] != nil
        }
    }
} 