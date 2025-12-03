import Foundation
import SwiftUI

/**
 * 统一的关注管理服务
 * 负责管理所有页面的关注状态，确保数据一致性
 */
class FollowManager: ObservableObject {
    static let shared = FollowManager()
    
    // 关注列表存储键
    private let followedUsersKey = "FollowedUsers"
    
    // 发布的关注列表，供UI订阅
    @Published var followedUsers: [String] = []
    
    private init() {
        loadFollowedUsers()
        setupNotificationListeners()
    }
    
    // MARK: - 公共接口
    
    /**
     * 切换用户的关注状态
     * @param username 用户名或角色名
     * @return 返回新的关注状态
     */
    func toggleFollow(for username: String) -> Bool {
        let isCurrentlyFollowed = isFollowing(username)
        
        if isCurrentlyFollowed {
            unfollowUser(username)
        } else {
            followUser(username)
        }
        
        return !isCurrentlyFollowed
    }
    
    /**
     * 关注用户
     * @param username 用户名或角色名
     */
    func followUser(_ username: String) {
        guard !username.isEmpty && !followedUsers.contains(username) else { return }
        
        followedUsers.append(username)
        saveFollowedUsers()
        
        // 发送通知
        NotificationCenter.default.post(
            name: NSNotification.Name("FollowStatusChanged"),
            object: nil,
            userInfo: [
                "username": username,
                "isFollowed": true
            ]
        )
        
        print("✅ 已关注用户: \(username)")
    }
    
    /**
     * 取消关注用户
     * @param username 用户名或角色名
     */
    func unfollowUser(_ username: String) {
        followedUsers.removeAll { $0 == username }
        saveFollowedUsers()
        
        // 发送通知
        NotificationCenter.default.post(
            name: NSNotification.Name("FollowStatusChanged"),
            object: nil,
            userInfo: [
                "username": username,
                "isFollowed": false
            ]
        )
        
        print("❌ 已取消关注用户: \(username)")
    }
    
    /**
     * 检查是否关注了某个用户
     * @param username 用户名或角色名
     * @return 是否已关注
     */
    func isFollowing(_ username: String) -> Bool {
        return followedUsers.contains(username)
    }
    
    /**
     * 获取所有关注的用户列表
     * @return 关注的用户名数组
     */
    func getFollowedUsers() -> [String] {
        return followedUsers
    }
    
    /**
     * 获取关注的用户数量
     * @return 关注数量
     */
    func getFollowedCount() -> Int {
        return followedUsers.count
    }
    
    // MARK: - 私有方法
    
    /**
     * 从UserDefaults加载关注列表
     */
    private func loadFollowedUsers() {
        followedUsers = UserDefaults.standard.stringArray(forKey: followedUsersKey) ?? []
        print("📱 已加载关注列表，共 \(followedUsers.count) 个用户")
    }
    
    /**
     * 保存关注列表到UserDefaults
     */
    private func saveFollowedUsers() {
        UserDefaults.standard.set(followedUsers, forKey: followedUsersKey)
        print("💾 已保存关注列表到本地存储")
    }
    
    /**
     * 设置通知监听器
     */
    private func setupNotificationListeners() {
        // 监听应用进入前台，重新加载数据
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadFollowedUsers()
        }
    }
    
    /**
     * 批量导入关注列表（用于数据迁移）
     * @param usernames 用户名数组
     */
    func importFollowedUsers(_ usernames: [String]) {
        let uniqueUsernames = Array(Set(usernames + followedUsers))
        followedUsers = uniqueUsernames
        saveFollowedUsers()
        
        print("📥 批量导入关注列表，共 \(uniqueUsernames.count) 个用户")
    }
    
    /**
     * 清空所有关注
     */
    func clearAllFollows() {
        followedUsers.removeAll()
        saveFollowedUsers()
        
        NotificationCenter.default.post(
            name: NSNotification.Name("AllFollowsCleared"),
            object: nil
        )
        
        print("🗑️ 已清空所有关注")
    }
}

// MARK: - 扩展：与角色系统集成

extension FollowManager {
    /**
     * 根据角色ID关注角色
     * @param characterId 角色ID
     */
    func followCharacter(by characterId: String) {
        // 尝试通过角色ID找到角色名
        if let character = CharacterModel.allCharacters.first(where: { $0.id == characterId }) {
            followUser(character.name)
        } else {
            // 如果找不到角色，直接使用ID作为名称
            followUser(characterId)
        }
    }
    
    /**
     * 根据角色ID取消关注角色
     * @param characterId 角色ID
     */
    func unfollowCharacter(by characterId: String) {
        // 尝试通过角色ID找到角色名
        if let character = CharacterModel.allCharacters.first(where: { $0.id == characterId }) {
            unfollowUser(character.name)
        } else {
            // 如果找不到角色，直接使用ID作为名称
            unfollowUser(characterId)
        }
    }
    
    /**
     * 检查是否关注了某个角色
     * @param characterId 角色ID
     * @return 是否已关注
     */
    func isFollowingCharacter(by characterId: String) -> Bool {
        // 尝试通过角色ID找到角色名
        if let character = CharacterModel.allCharacters.first(where: { $0.id == characterId }) {
            return isFollowing(character.name)
        } else {
            return isFollowing(characterId)
        }
    }
} 