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
                    print("✅ ImageCache: 预加载图片成功 - \(url)")
                }
            } catch {
                print("❌ ImageCache: 预加载图片失败 - \(url), 错误: \(error.localizedDescription)")
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
        
        URLSession.shared.dataTask(with: imageURL) { data, response, error in
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