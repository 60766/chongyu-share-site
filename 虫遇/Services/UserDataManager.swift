import Foundation
import SwiftUI

/// 用户数据管理服务
/// 负责处理用户数据的备份、清理、导出等功能
class UserDataManager: ObservableObject {
    static let shared = UserDataManager()
    
    private init() {
        setupLogoutListener()
    }
    
    // MARK: - 数据清理
    
    /// 清除所有用户数据
    func clearAllUserData() {
        print("🧹 开始清除用户数据...")
        
        // 1. 清除用户资料
        clearUserProfile()
        
        // 2. 清除自定义角色
        clearCustomCharacters()
        
        // 3. 清除聊天记录（如果有的话）
        clearChatHistory()
        
        // 4. 清除其他用户偏好设置
        clearUserPreferences()
        
        print("🧹 用户数据清除完成")
    }
    
    /// 清除用户资料
    private func clearUserProfile() {
        let keysToRemove = [
            "user_profile_username",
            "user_profile_personal_signature",
            "user_profile_avatar_name",
            "user_profile_level",
            "user_profile_experience",
            "user_profile_level_title",
            "user_profile_last_level_update"
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // 通知用户资料管理器重置
        DispatchQueue.main.async {
            UserProfileManager.shared.resetToDefault()
        }
        
        print("✅ 已清除用户资料")
    }
    
    /// 清除自定义角色
    private func clearCustomCharacters() {
        // 获取所有自定义角色的键
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        let customCharacterKeys = allKeys.filter { key in
            key.hasPrefix("custom_character_") || 
            key.hasPrefix("character_avatar_") ||
            key == "custom_characters_list"
        }
        
        for key in customCharacterKeys {
            userDefaults.removeObject(forKey: key)
        }
        
        print("✅ 已清除自定义角色数据")
    }
    
    /// 清除聊天记录
    private func clearChatHistory() {
        // 如果有聊天记录存储，在这里清除
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        let chatKeys = allKeys.filter { key in
            key.hasPrefix("chat_") || 
            key.hasPrefix("conversation_") ||
            key.hasPrefix("message_")
        }
        
        for key in chatKeys {
            userDefaults.removeObject(forKey: key)
        }
        
        print("✅ 已清除聊天记录")
    }
    
    /// 清除用户偏好设置
    private func clearUserPreferences() {
        let keysToRemove = [
            "theme_preference",
            "notification_settings",
            "privacy_settings",
            "app_usage_stats"
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        print("✅ 已清除用户偏好设置")
    }
    
    // MARK: - 数据备份和导出
    
    /// 导出用户数据
    func exportUserData() -> [String: Any] {
        print("🔄 开始导出用户核心数据...")
        var exportData: [String: Any] = [:]
        
        // 1. 个人档案（简洁版）
        let profileManager = UserProfileManager.shared
        let profile: [String: Any] = [
            "nickname": profileManager.username,
            "signature": profileManager.personalSignature,
            "level": profileManager.userLevel,
            "levelTitle": profileManager.levelTitle,
            "joinDate": formatDate(AppAccountManager.shared.accountCreationDate)
        ]
        exportData["profile"] = profile
        print("👤 个人档案: \(profile)")
        
        // 2. 我的创作
        var myCreations: [String: Any] = [:]
        
        // 获取用户发布的帖子
        let userPosts = getUserCreatedPosts()
        let postsData = userPosts.map { post in
            [
                "content": post.content,
                "date": formatDate(post.datePosted),
                "likes": post.likes,
                "type": post.contentType ?? "动态"
            ]
        }
        myCreations["posts"] = postsData
        
        // 获取自定义角色（简化版）
        let customCharacters = getSimplifiedCustomCharacters()
        myCreations["customCharacters"] = customCharacters
        
        exportData["myCreations"] = myCreations
        print("✍️ 我的创作: \(postsData.count) 篇帖子, \(customCharacters.count) 个自定义角色")
        
        // 3. 成长记录
        let highlights: [String: Any] = [
            "totalPosts": postsData.count,
            "totalCustomCharacters": customCharacters.count,
            "currentLevel": profileManager.userLevel,
            "experience": profileManager.userExperience,
            "memberDays": calculateMemberDays()
        ]
        exportData["highlights"] = highlights
        print("📈 成长记录: \(highlights)")
        
        // 4. 导出信息
        exportData["exportInfo"] = [
            "exportDate": formatDate(Date()),
            "version": "2.0"
        ]
        
        print("📤 用户核心数据导出完成")
        return exportData
    }
    
    /// 获取用户创建的帖子（排除AI生成的）
    private func getUserCreatedPosts() -> [UserPostModel] {
        let allPosts = PostViewModel.shared.posts
        let currentUsername = UserProfileManager.shared.username
        
        // 过滤出用户真正创建的帖子
        return allPosts.filter { post in
            // 用户名匹配且不是虚拟角色生成的
            post.username == currentUsername && 
            post.source != "onekey" && 
            post.source != "wormhole" &&
            !isVirtualCharacterName(post.username)
        }
    }
    
    /// 检查是否为虚拟角色名称
    private func isVirtualCharacterName(_ name: String) -> Bool {
        let virtualCharacterNames = ["爱因斯坦", "莎士比亚", "达芬奇", "孔子", "牛顿", "李白", "AI助手"]
        return virtualCharacterNames.contains(name)
    }
    
    /// 获取简化的自定义角色信息
    private func getSimplifiedCustomCharacters() -> [[String: Any]] {
        var characters: [[String: Any]] = []
        
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let characterKeys = allKeys.filter { $0.hasPrefix("custom_character_") }
        
        for key in characterKeys {
            if let characterData = userDefaults.dictionary(forKey: key) {
                // 只保留用户关心的核心信息
                let simplifiedCharacter: [String: Any] = [
                    "name": characterData["name"] as? String ?? "未命名角色",
                    "description": characterData["description"] as? String ?? "",
                    "personality": characterData["personality"] as? String ?? "",
                    "createdDate": formatDate(characterData["createdDate"] as? Date ?? Date())
                ]
                characters.append(simplifiedCharacter)
            }
        }
        
        return characters.sorted { 
            ($0["createdDate"] as? String ?? "") > ($1["createdDate"] as? String ?? "")
        }
    }
    
    /// 计算成为会员的天数
    private func calculateMemberDays() -> Int {
        let creationDate = AppAccountManager.shared.accountCreationDate
        let daysBetween = Calendar.current.dateComponents([.day], from: creationDate, to: Date()).day ?? 0
        return max(daysBetween, 1) // 至少1天
    }
    
    /// 格式化日期为易读格式
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    /// 统计用户项目数量
    func countUserItems() -> [String: Int] {
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        return [
            "customCharacters": allKeys.filter { $0.hasPrefix("custom_character_") }.count,
            "chatSessions": allKeys.filter { $0.hasPrefix("chat_") }.count,
            "totalItems": allKeys.count
        ]
    }
    
    // MARK: - 数据恢复
    
    /// 恢复用户数据（从备份）
    func restoreUserData(from backupData: [String: Any]) -> Bool {
        guard let _ = backupData["account"] as? [String: Any],
              let profileData = backupData["profile"] as? [String: Any] else {
            print("❌ 备份数据格式无效")
            return false
        }
        
        // 恢复用户资料
        let userDefaults = UserDefaults.standard
        
        if let username = profileData["username"] as? String {
            userDefaults.set(username, forKey: "user_profile_username")
        }
        
        if let signature = profileData["personalSignature"] as? String {
            userDefaults.set(signature, forKey: "user_profile_personal_signature")
        }
        
        if let avatarName = profileData["avatarImageName"] as? String {
            userDefaults.set(avatarName, forKey: "user_profile_avatar_name")
        }
        
        if let level = profileData["userLevel"] as? Int {
            userDefaults.set(level, forKey: "user_profile_level")
        }
        
        if let experience = profileData["userExperience"] as? Int {
            userDefaults.set(experience, forKey: "user_profile_experience")
        }
        
        // 恢复自定义角色
        if let characters = backupData["customCharacters"] as? [[String: Any]] {
            for (index, characterData) in characters.enumerated() {
                let key = "custom_character_restored_\(index)"
                userDefaults.set(characterData, forKey: key)
            }
        }
        
        print("📥 用户数据恢复完成")
        return true
    }
    
    // MARK: - 监听器设置
    
    /// 设置退出登录监听器
    private func setupLogoutListener() {
        NotificationCenter.default.addObserver(
            forName: .userAccountLogout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearAllUserData()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UserProfileManager 扩展
extension UserProfileManager {
    /// 重置为默认值
    func resetToDefault() {
        DispatchQueue.main.async {
            self.username = "次元指挥官"
            self.personalSignature = "探索无限次元，寻找智慧宝藏 ✨"
            self.avatarImage = nil
            self.avatarImageName = "default_avatar"
            self.userLevel = 1
            self.userExperience = 0
            self.levelTitle = "时空新手"
            self.lastLevelUpdateTime = Date()
            
            // 发送重置通知
            NotificationCenter.default.post(name: .userProfileReset, object: nil)
        }
    }
}

// MARK: - 通知扩展
extension Notification.Name {
    static let userProfileReset = Notification.Name("userProfileReset")
    static let userDataExported = Notification.Name("userDataExported")
    static let userDataRestored = Notification.Name("userDataRestored")
} 