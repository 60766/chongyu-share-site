import SwiftUI
import Foundation

/**
 * 图片缓存服务
 * 用于缓存和预加载图片
 */
class ImageCache {
    // 单例实例
    static let shared = ImageCache()
    
    // 内存缓存
    private var cache = NSCache<NSString, UIImage>()
    
    // 下载队列
    private let downloadQueue = DispatchQueue(label: "image.download", qos: .utility, attributes: .concurrent)
    
    // 初始化
    private init() {
        // 设置缓存限制
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // 监听内存警告
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    // 清理缓存
    @objc private func clearCache() {
        cache.removeAllObjects()
    }
    
    // 获取缓存的图片
    func getImage(for url: String) -> UIImage? {
        return cache.object(forKey: url as NSString)
    }
    
    // 缓存图片
    func cacheImage(_ image: UIImage, for url: String) {
        cache.setObject(image, forKey: url as NSString)
    }
    
    // 预加载图片
    func prefetchImage(url: String, priority: Float = 0.5) {
        // 如果已经缓存，则不需要预加载
        if cache.object(forKey: url as NSString) != nil {
            return
        }
        
        // 创建URL
        guard let imageURL = URL(string: url) else {
            return
        }
        
        // 设置下载任务优先级
        let qos: DispatchQoS = {
            if priority > 0.8 {
                return .userInitiated
            } else if priority > 0.5 {
                return .default
            } else if priority > 0.2 {
                return .utility
            } else {
                return .background
            }
        }()
        
        // 在后台下载图片
        DispatchQueue.global(qos: qos.qosClass).async {
            do {
                let data = try Data(contentsOf: imageURL)
                if let image = UIImage(data: data) {
                    self.cache.setObject(image, forKey: url as NSString)
                    #if DEBUG
                    debugLog("✅ ImageCache: 预加载图片成功 - \(url)")
                    #endif
                }
            } catch {
                #if DEBUG
                debugLog("❌ ImageCache: 预加载图片失败 - \(url), 错误: \(error.localizedDescription)")
                #endif
            }
        }
    }
}

// 图片加载视图
struct CachedImage: View {
    let url: String
    let placeholder: Image
    
    @State private var image: UIImage? = nil
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        // 先检查缓存
        if let cachedImage = ImageCache.shared.getImage(for: url) {
            self.image = cachedImage
            return
        }
        
        // 如果没有缓存，则下载图片
        guard let imageURL = URL(string: url) else {
            return
        }
        
        // Use longer timeouts for image downloads
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 300
        let session = URLSession(configuration: config)
        session.dataTask(with: imageURL) { data, response, error in
            if let data = data, let downloadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    // 缓存图片
                    ImageCache.shared.cacheImage(downloadedImage, for: url)
                    self.image = downloadedImage
                }
            }
        }.resume()
    }
}

// MARK: - Phase 2优化扩展

extension ImageCache {
    
    /**
     * 批量预加载帖子图片（智能优化）
     */
    func prefetchPostImages(posts: [UserPostModel]) {
        downloadQueue.async { [weak self] in
            guard let self = self else { return }
            
            #if DEBUG
            debugLog("🖼️ 开始批量预加载 \(posts.count) 个帖子的图片")
            #endif
            
            for post in posts {
                // 预加载所有图片
                for imageURL in post.images {
                    if !imageURL.isEmpty && self.getImage(for: imageURL) == nil {
                        self.prefetchImage(url: imageURL, priority: 0.3)
                    }
                }
                
                // 预加载头像（如果有的话）
                if !post.userAvatar.isEmpty {
                    if self.getImage(for: post.userAvatar) == nil {
                        self.prefetchImage(url: post.userAvatar, priority: 0.2)
                    }
                }
            }
        }
    }
    
    /**
     * 智能内存优化
     */
    func optimizeMemoryUsage() {
        downloadQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 获取当前内存使用情况
            let processInfo = ProcessInfo.processInfo
            let usedMemory = processInfo.physicalMemory
            
            // 如果内存使用过高，减少缓存限制
            if usedMemory > 150 * 1024 * 1024 { // 150MB
                self.cache.totalCostLimit = 30 * 1024 * 1024 // 降低到30MB
                self.cache.countLimit = 50 // 降低图片数量
                #if DEBUG
                debugLog("🧠 检测到内存压力，降低图片缓存限制")
                #endif
            } else {
                // 恢复正常缓存限制
                self.cache.totalCostLimit = 50 * 1024 * 1024
                self.cache.countLimit = 100
            }
        }
    }
    
    /**
     * 预测性预加载（基于滑动方向）
     */
    func predictivelyPrefetch(currentPost: UserPostModel, nextPosts: [UserPostModel], direction: String) {
        downloadQueue.async { [weak self] in
            guard let self = self else { return }
            
            let prefetchCount = direction == "forward" ? 3 : 2 // 向前预加载更多
            let postsToLoad = Array(nextPosts.prefix(prefetchCount))
            
            for post in postsToLoad {
                for imageURL in post.images {
                    if !imageURL.isEmpty && self.getImage(for: imageURL) == nil {
                        self.prefetchImage(url: imageURL, priority: 0.4)
                    }
                }
            }
            
            #if DEBUG
            debugLog("🔮 预测性预加载: \(postsToLoad.count) 个帖子，方向: \(direction)")
            #endif
        }
    }
    
    /**
     * 获取缓存统计信息
     */
    func getCacheStats() -> (count: Int, size: Int, limit: Int) {
        return (
            count: cache.countLimit,
            size: cache.totalCostLimit,
            limit: cache.totalCostLimit
        )
    }
    
    /**
     * 打印缓存统计
     */
    func printCacheStats() {
        let stats = getCacheStats()
        #if DEBUG
        debugLog("""
        🖼️ 图片缓存统计:
        - 缓存限制: \(stats.count) 张图片
        - 大小限制: \(stats.size / (1024*1024)) MB
        """)
        #endif
    }
} 