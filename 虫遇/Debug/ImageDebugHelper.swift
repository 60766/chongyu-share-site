import Foundation
import UIKit

/**
 * 图片调试助手
 * 用于诊断图片保存和加载问题
 */
class ImageDebugHelper {
    static let shared = ImageDebugHelper()
    
    private init() {}
    
    /// 检查图片目录和文件
    func inspectImageStorage() {
        print("\n" + String(repeating: "=", count: 60))
        print("🔍 开始检查图片存储状态...")
        print(String(repeating: "=", count: 60))
        
        // 获取文档目录
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ 无法访问文档目录")
            return
        }
        
        print("\n📁 文档目录路径: \(documentsDirectory.path)")
        
        // 检查PostImages目录
        let imageDirectory = documentsDirectory.appendingPathComponent("PostImages")
        print("📁 图片目录路径: \(imageDirectory.path)")
        
        if FileManager.default.fileExists(atPath: imageDirectory.path) {
            print("✅ 图片目录存在")
            
            // 列出目录中的所有文件
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: imageDirectory.path)
                print("\n📊 图片目录中的文件数量: \(files.count)")
                
                if files.isEmpty {
                    print("⚠️ 图片目录为空")
                } else {
                    print("\n📋 图片文件列表:")
                    for (index, file) in files.enumerated() {
                        let filePath = imageDirectory.appendingPathComponent(file)
                        if let attributes = try? FileManager.default.attributesOfItem(atPath: filePath.path),
                           let fileSize = attributes[.size] as? Int64 {
                            let sizeInKB = Double(fileSize) / 1024.0
                            print("  \(index + 1). \(file) (\(String(format: "%.2f", sizeInKB)) KB)")
                        } else {
                            print("  \(index + 1). \(file)")
                        }
                    }
                }
            } catch {
                print("❌ 读取图片目录失败: \(error)")
            }
        } else {
            print("❌ 图片目录不存在")
        }
        
        print("\n" + String(repeating: "=", count: 60))
    }
    
    /// 检查用户帖子数据
    func inspectUserPostsData() {
        print("\n" + String(repeating: "=", count: 60))
        print("🔍 开始检查用户帖子数据...")
        print(String(repeating: "=", count: 60))
        
        guard let data = UserDefaults.standard.data(forKey: "UserPosts_v1") else {
            print("❌ 没有找到用户帖子数据")
            print(String(repeating: "=", count: 60))
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let userPosts = try decoder.decode([UserPostModel].self, from: data)
            
            print("\n✅ 成功读取用户帖子数据")
            print("📊 用户帖子总数: \(userPosts.count)\n")
            
            for (index, post) in userPosts.enumerated() {
                print("帖子 #\(index + 1):")
                print("  ID: \(post.id)")
                print("  内容: \(post.content.prefix(50))...")
                print("  图片数量: \(post.images.count)")
                if !post.images.isEmpty {
                    print("  图片IDs:")
                    for (imgIndex, imageId) in post.images.enumerated() {
                        print("    \(imgIndex + 1). \(imageId)")
                        
                        // 检查图片是否存在
                        if let image = ImageManager.shared.getImage(withId: imageId) {
                            print("       ✅ 图片可加载 (尺寸: \(image.size))")
                        } else {
                            print("       ❌ 图片无法加载")
                        }
                    }
                }
                print("  发布时间: \(post.datePosted)")
                print("  来源: \(post.source ?? "unknown")")
                print()
            }
        } catch {
            print("❌ 解析用户帖子数据失败: \(error)")
        }
        
        print(String(repeating: "=", count: 60))
    }
    
    /// 综合检查
    func runFullDiagnostics() {
        inspectImageStorage()
        inspectUserPostsData()
        
        print("\n✅ 诊断完成！")
    }
} 