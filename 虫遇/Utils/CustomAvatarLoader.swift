import Foundation
import UIKit

/**
 * 自定义头像加载器
 * 用于加载用户创建的角色头像
 */
class CustomAvatarLoader {
    // 单例实例
    static let shared = CustomAvatarLoader()
    
    // 私有初始化方法
    private init() {}
    
    /**
     * 加载自定义头像
     * @param characterId 角色ID
     * @param avatarName 角色头像名称
     * @return 加载的头像图片，如果加载失败则返回nil
     */
    func loadCustomAvatar(characterId: String, avatarName: String) -> UIImage? {
        print("🔍 CustomAvatarLoader - 尝试加载头像 characterId: \(characterId), avatarName: \(avatarName)")
        
        // 检查角色ID是否是自定义角色（以"custom_"开头）
        if characterId.hasPrefix("custom_") {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsDirectory.appendingPathComponent("\(characterId).jpg")
            
            print("🔍 CustomAvatarLoader - 查找文件路径: \(fileURL.path)")
            
            // 列出目录中的所有文件
            if let files = try? FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil) {
                print("📁 CustomAvatarLoader - 文档目录中的文件:")
                for file in files {
                    print("   - \(file.lastPathComponent)")
                }
            }
            
            // 检查文件是否存在
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let imageData = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: imageData) {
                    print("✅ CustomAvatarLoader - 成功加载自定义头像: \(fileURL.path)")
                    return image
                } else {
                    print("❌ CustomAvatarLoader - 无法加载自定义头像数据: \(fileURL.path)")
                }
            } else {
                print("⚠️ CustomAvatarLoader - 自定义头像文件不存在: \(fileURL.path)")
            }
        } else {
            print("ℹ️ CustomAvatarLoader - 不是自定义角色")
        }
        
        return nil
    }
} 