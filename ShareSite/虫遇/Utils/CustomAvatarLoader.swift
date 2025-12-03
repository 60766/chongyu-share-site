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
        // 检查角色ID是否是自定义角色（以"custom_"开头）
        if characterId.hasPrefix("custom_") {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsDirectory.appendingPathComponent("\(characterId).jpg")
            
            // 检查文件是否存在
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let imageData = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: imageData) {
                    return image
                }
            }
        }
        
        return nil
    }
} 