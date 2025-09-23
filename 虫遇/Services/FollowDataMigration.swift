import Foundation

/**
 * 关注数据迁移服务
 * 用于将现有的不同关注数据统一迁移到FollowManager中
 */
class FollowDataMigration {
    static let shared = FollowDataMigration()
    
    private init() {}
    
    /**
     * 执行数据迁移
     * 将所有旧的关注数据合并到统一的FollowManager中
     */
    func migrateFollowData() {
        print("🔄 开始关注数据迁移...")
        
        var allFollowedUsers: Set<String> = Set()
        
        // 1. 迁移帖子详情页面的关注数据 (FollowedUsers)
        if let followedUsers = UserDefaults.standard.stringArray(forKey: "FollowedUsers") {
            allFollowedUsers.formUnion(followedUsers)
            print("📱 从FollowedUsers迁移了 \(followedUsers.count) 个用户")
        }
        
        // 2. 迁移探索页面的角色关注数据 (favoriteCharacters)
        if let favoriteCharactersData = UserDefaults.standard.data(forKey: "favoriteCharacters"),
           let favoriteCharacterIds = try? JSONDecoder().decode([String].self, from: favoriteCharactersData) {
            
            // 将角色ID转换为角色名称
            let characterNames = favoriteCharacterIds.compactMap { id in
                CharacterModel.allCharacters.first(where: { $0.id == id })?.name
            }
            allFollowedUsers.formUnion(characterNames)
            print("🎭 从favoriteCharacters迁移了 \(characterNames.count) 个角色")
        }
        
        // 3. 迁移选项菜单的关注数据 (FollowedCharacters)
        if let followedCharacters = UserDefaults.standard.stringArray(forKey: "FollowedCharacters") {
            // 尝试将角色ID转换为名称，如果找不到就直接使用原值
            let characterNames = followedCharacters.compactMap { idOrName in
                // 先尝试作为ID查找
                if let character = CharacterModel.allCharacters.first(where: { $0.id == idOrName }) {
                    return character.name
                }
                // 如果找不到，可能本身就是名称，直接返回
                return idOrName
            }
            allFollowedUsers.formUnion(characterNames)
            print("⚙️ 从FollowedCharacters迁移了 \(characterNames.count) 个角色")
        }
        
        // 4. 将合并后的数据导入到FollowManager
        let uniqueFollowedUsers = Array(allFollowedUsers)
        FollowManager.shared.importFollowedUsers(uniqueFollowedUsers)
        
        // 5. 清理旧数据（可选，保留一段时间以防需要回滚）
        // cleanupOldData()
        
        print("✅ 关注数据迁移完成，共迁移了 \(uniqueFollowedUsers.count) 个用户/角色")
        
        // 6. 标记迁移已完成
        UserDefaults.standard.set(true, forKey: "FollowDataMigrationCompleted")
        
        // 7. 发送通知，让所有UI组件刷新关注状态
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("FollowDataMigrationCompleted"),
                object: nil,
                userInfo: ["migratedUsers": uniqueFollowedUsers]
            )
        }
    }
    
    /**
     * 检查是否需要执行数据迁移
     */
    func shouldMigrate() -> Bool {
        return !UserDefaults.standard.bool(forKey: "FollowDataMigrationCompleted")
    }
    
    /**
     * 清理旧的关注数据
     * 注意：只有在确认新系统工作正常后才调用此方法
     */
    private func cleanupOldData() {
        UserDefaults.standard.removeObject(forKey: "favoriteCharacters")
        UserDefaults.standard.removeObject(forKey: "FollowedCharacters")
        // 保留FollowedUsers作为主数据源，不删除
        
        print("🗑️ 已清理旧的关注数据")
    }
    
    /**
     * 强制重新迁移（用于调试）
     */
    func forceMigration() {
        UserDefaults.standard.removeObject(forKey: "FollowDataMigrationCompleted")
        migrateFollowData()
    }
} 