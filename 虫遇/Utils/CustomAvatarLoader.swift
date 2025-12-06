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
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // 🔒 修复：支持custom_开头的角色ID，也支持user_avatar_开头的文件名
        let isCustomCharacter = characterId.hasPrefix("custom_")
        let isUserAvatar = avatarName.hasPrefix("user_avatar_") || avatarName.hasPrefix("custom_")
        
        if isCustomCharacter || isUserAvatar {
            // 🔒 修复：尝试多种可能的文件扩展名和文件名格式
            let possibleExtensions = ["jpg", "jpeg", "png"]
            
            // 首先尝试使用characterId作为文件名（如果是custom_开头）
            if isCustomCharacter {
                for ext in possibleExtensions {
                    let fileURL = documentsDirectory.appendingPathComponent("\(characterId).\(ext)")
                    
                    #if DEBUG
                    print("🔍 CustomAvatarLoader: 检查文件（characterId） - \(fileURL.path)")
                    #endif
                    
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        if let imageData = try? Data(contentsOf: fileURL),
                           let image = UIImage(data: imageData) {
                            #if DEBUG
                            print("✅ CustomAvatarLoader: 成功加载头像（characterId） - \(fileURL.path)")
                            #endif
                            return image
                        }
                    }
                }
            }
            
            // 如果characterId不是custom_开头，但avatarName是user_avatar_或custom_开头，尝试使用avatarName
            if isUserAvatar && !isCustomCharacter {
                // 尝试直接使用avatarName作为文件名（可能已经包含扩展名）
                let fileURL1 = documentsDirectory.appendingPathComponent(avatarName)
                
                #if DEBUG
                print("🔍 CustomAvatarLoader: 检查文件（avatarName直接） - \(fileURL1.path)")
                #endif
                
                if FileManager.default.fileExists(atPath: fileURL1.path) {
                    if let imageData = try? Data(contentsOf: fileURL1),
                       let image = UIImage(data: imageData) {
                        #if DEBUG
                        print("✅ CustomAvatarLoader: 成功加载头像（avatarName直接） - \(fileURL1.path)")
                        #endif
                        return image
                    }
                }
                
                // 尝试添加扩展名
                for ext in possibleExtensions {
                    let fileURL = documentsDirectory.appendingPathComponent("\(avatarName).\(ext)")
                    
                    #if DEBUG
                    print("🔍 CustomAvatarLoader: 检查文件（avatarName+扩展名） - \(fileURL.path)")
                    #endif
                    
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let imageData = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: imageData) {
                            #if DEBUG
                            print("✅ CustomAvatarLoader: 成功加载头像（avatarName+扩展名） - \(fileURL.path)")
                            #endif
                    return image
                }
            }
                }
            }
            
            #if DEBUG
            print("⚠️ CustomAvatarLoader: 未找到头像文件 - characterId: \(characterId), avatarName: \(avatarName)")
            // 列出文档目录中的所有文件，帮助调试
            if let files = try? FileManager.default.contentsOfDirectory(atPath: documentsDirectory.path) {
                let customFiles = files.filter { $0.hasPrefix("custom_") || $0.hasPrefix("user_avatar_") }
                print("📁 文档目录中的custom_/user_avatar_文件: \(customFiles.prefix(10))")
            }
            #endif
        }
        
        return nil
    }
} 