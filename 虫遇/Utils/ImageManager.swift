import UIKit
import SwiftUI

/**
 * 图片管理器
 * 负责图片的存储、检索和缓存
 */
class ImageManager {
    /// 单例实例
    static let shared = ImageManager()
    
    /// 内存缓存
    private var imageCache = NSCache<NSString, UIImage>()
    
    /// 私有初始化方法，确保单例模式
    private init() {
        // 设置缓存限制
        imageCache.countLimit = 100 // 最多缓存100张图片
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    /**
     * 保存图片到文件系统
     * @param image 要保存的图片
     * @param id 图片唯一标识符
     * @return 是否保存成功
     */
    func saveImage(_ image: UIImage, withId id: String) -> Bool {
        // 处理图片 - 压缩大图片
        let processedImage = processImage(image)
        
        // 缓存图片
        imageCache.setObject(processedImage, forKey: id as NSString)
        
        // 获取文档目录路径
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("无法访问文档目录")
            return false
        }
        
        // 创建图片目录
        let imageDirectory = documentsDirectory.appendingPathComponent("PostImages")
        
        // 如果目录不存在，创建目录
        if !FileManager.default.fileExists(atPath: imageDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
            } catch {
                print("创建图片目录失败: \(error)")
                return false
            }
        }
        
        // 创建图片文件路径
        let imagePath = imageDirectory.appendingPathComponent("\(id).jpg")
        
        // 将图片保存为JPEG格式
        if let imageData = processedImage.jpegData(compressionQuality: 0.8) {
            do {
                try imageData.write(to: imagePath)
                print("✅ 图片保存成功: \(id), 路径: \(imagePath.path)")
                return true
            } catch {
                print("❌ 保存图片失败: \(error), ID: \(id)")
                return false
            }
        }
        
        print("❌ 无法生成图片数据: \(id)")
        return false
    }
    
    /**
     * 根据ID获取图片
     * @param id 图片唯一标识符
     * @return 图片对象，如果不存在则返回nil
     */
    func getImage(withId id: String) -> UIImage? {
        // 先从缓存中查找
        if let cachedImage = imageCache.object(forKey: id as NSString) {
            print("✅ 从缓存加载图片: \(id)")
            return cachedImage
        }
        
        // 如果缓存中没有，从文件系统加载
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ 无法访问文档目录")
            return nil
        }
        
        let imagePath = documentsDirectory.appendingPathComponent("PostImages/\(id).jpg")
        
        // 检查文件是否存在
        if FileManager.default.fileExists(atPath: imagePath.path) {
            print("📁 找到图片文件: \(imagePath.path)")
            if let imageData = try? Data(contentsOf: imagePath),
               let image = UIImage(data: imageData) {
                // 加载成功后缓存图片
                imageCache.setObject(image, forKey: id as NSString)
                print("✅ 成功加载图片: \(id)")
                return image
            } else {
                print("❌ 无法解码图片数据: \(id)")
            }
        } else {
            print("❌ 图片文件不存在: \(imagePath.path)")
        }
        
        return nil
    }
    
    /**
     * 处理图片，进行压缩等操作
     * @param image 原始图片
     * @return 处理后的图片
     */
    private func processImage(_ image: UIImage) -> UIImage {
        // 如果图片太大，进行压缩
        if let resizedImage = resizeImage(image, targetSize: 1080) {
            return resizedImage
        }
        return image
    }
    
    /**
     * 调整图片大小
     * @param image 原始图片
     * @param targetSize 目标尺寸的最大边长
     * @return 调整后的图片
     */
    private func resizeImage(_ image: UIImage, targetSize: CGFloat) -> UIImage? {
        let originalSize = image.size
        
        // 如果图片尺寸已经足够小，不需要调整
        if originalSize.width <= targetSize && originalSize.height <= targetSize {
            return image
        }
        
        // 计算新的尺寸，保持宽高比
        var newSize: CGSize
        
        if originalSize.width > originalSize.height {
            let ratio = targetSize / originalSize.width
            newSize = CGSize(width: targetSize, height: originalSize.height * ratio)
        } else {
            let ratio = targetSize / originalSize.height
            newSize = CGSize(width: originalSize.width * ratio, height: targetSize)
        }
        
        // 渲染新图片
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    /**
     * 删除图片
     * @param id 图片唯一标识符
     * @return 是否删除成功
     */
    func deleteImage(withId id: String) -> Bool {
        // 从缓存中移除
        imageCache.removeObject(forKey: id as NSString)
        
        // 从文件系统中删除
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let imagePath = documentsDirectory.appendingPathComponent("PostImages/\(id).jpg")
        
        // 检查文件是否存在
        if FileManager.default.fileExists(atPath: imagePath.path) {
            do {
                try FileManager.default.removeItem(at: imagePath)
                return true
            } catch {
                print("删除图片失败: \(error)")
                return false
            }
        }
        
        return false
    }
}

/**
 * 图片加载视图
 * 用于异步加载和显示图片
 */
struct PostImageView: View {
    let imageId: String
    var contentMode: ContentMode = .fill
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var cornerRadius: CGFloat = 12
    
    @State private var image: UIImage? = nil
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let image = image {
                // 加载成功状态
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .clipped()
                    .cornerRadius(cornerRadius)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
            } else if isLoading {
                // 加载中状态
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .cornerRadius(cornerRadius)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(Color(.systemGray5), lineWidth: 0.5)
                        )
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                }
            } else {
                // 加载失败状态
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .cornerRadius(cornerRadius)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(Color(.systemGray5), lineWidth: 0.5)
                        )
                    
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                        
                        Text("图片加载失败")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .frame(width: width, height: height)
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        print("🔍 PostImageView 开始加载图片: \(imageId)")
        isLoading = true
        
        // 在后台线程加载图片
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedImage = ImageManager.shared.getImage(withId: imageId)
            
            // 在主线程更新UI
            DispatchQueue.main.async {
                self.image = loadedImage
                self.isLoading = false
                
                if loadedImage != nil {
                    print("✅ PostImageView 成功加载图片: \(imageId)")
                } else {
                    print("❌ PostImageView 加载图片失败: \(imageId)")
                }
            }
        }
    }
} 