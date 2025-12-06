import Foundation

/**
 * 被屏蔽的分类管理器
 * 用于管理用户在帖子生成时屏蔽的角色分类
 */
class BlockedCategoriesManager {
    // 单例模式
    static let shared = BlockedCategoriesManager()
    
    // UserDefaults 存储键
    private let blockedCategoriesKey = "BlockedCharacterCategories"
    
    private init() {
        loadBlockedCategories()
    }
    
    // 被屏蔽的分类列表
    private var blockedCategories: Set<String> = []
    
    /**
     * 从 UserDefaults 加载被屏蔽的分类
     */
    private func loadBlockedCategories() {
        if let categories = UserDefaults.standard.array(forKey: blockedCategoriesKey) as? [String] {
            blockedCategories = Set(categories)
        }
    }
    
    /**
     * 保存被屏蔽的分类到 UserDefaults
     */
    private func saveBlockedCategories() {
        UserDefaults.standard.set(Array(blockedCategories), forKey: blockedCategoriesKey)
    }
    
    /**
     * 检查分类是否被屏蔽
     * @param category - 要检查的分类
     * @return 是否被屏蔽
     */
    func isCategoryBlocked(_ category: CharacterCategory) -> Bool {
        return blockedCategories.contains(category.rawValue)
    }
    
    /**
     * 切换分类的屏蔽状态
     * @param category - 要切换的分类
     * @return 是否成功切换（如果尝试屏蔽最后一个分类，会返回false）
     */
    func toggleCategory(_ category: CharacterCategory) -> Bool {
        // 获取所有可用分类（排除"全部"）
        let allCategories = CharacterCategory.allCases.filter { $0 != .all }
        
        // 如果当前分类已被屏蔽，直接取消屏蔽
        if blockedCategories.contains(category.rawValue) {
            blockedCategories.remove(category.rawValue)
            saveBlockedCategories()
            // 通知角色轮换系统刷新（因为可用角色列表改变了）
            CharacterRotationSystem.shared.refreshAllCharacterIds()
            return true
        }
        
        // 如果要屏蔽分类，检查是否会屏蔽所有分类
        let willBeBlockedCount = blockedCategories.count + 1
        if willBeBlockedCount >= allCategories.count {
            // 尝试屏蔽最后一个分类，不允许
            return false
        }
        
        // 可以屏蔽
        blockedCategories.insert(category.rawValue)
        saveBlockedCategories()
        // 通知角色轮换系统刷新（因为可用角色列表改变了）
        CharacterRotationSystem.shared.refreshAllCharacterIds()
        return true
    }
    
    /**
     * 获取所有被屏蔽的分类
     * @return 被屏蔽的分类列表
     */
    func getBlockedCategories() -> [CharacterCategory] {
        return blockedCategories.compactMap { CharacterCategory(rawValue: $0) }
    }
    
    /**
     * 获取被屏蔽的分类数量
     * @return 被屏蔽的分类数量
     */
    func getBlockedCategoriesCount() -> Int {
        return blockedCategories.count
    }
    
    /**
     * 取消屏蔽所有分类
     */
    func unblockAllCategories() {
        blockedCategories.removeAll()
        saveBlockedCategories()
        // 通知角色轮换系统刷新（因为可用角色列表改变了）
        CharacterRotationSystem.shared.refreshAllCharacterIds()
    }
    
    /**
     * 检查分类是否可用于帖子生成
     * @param category - 要检查的分类
     * @return 是否可用
     */
    func isCategoryAvailableForPostGeneration(_ category: CharacterCategory) -> Bool {
        // "全部"分类总是可用（用于显示）
        if category == .all {
            return true
        }
        // 检查是否被屏蔽
        return !isCategoryBlocked(category)
    }
    
    /**
     * 过滤角色列表，移除被屏蔽分类的角色
     * @param characters - 角色列表
     * @return 过滤后的角色列表
     */
    func filterCharacters(_ characters: [CharacterModel]) -> [CharacterModel] {
        return characters.filter { character in
            let isUserCreated = character.id.hasPrefix("custom_")
            
            // 🔒 用户创建的角色：只受"我的创建"分类的屏蔽影响，不受其他分类屏蔽影响
            if isUserCreated {
                // 如果"我的创建"被屏蔽，过滤掉所有用户创建的角色
                if isCategoryBlocked(.myCreation) {
                    return false
                }
                // 用户创建的角色不受其他分类屏蔽影响，直接通过
                return true
            }
            
            // 🔒 非用户创建的角色：检查分类是否被屏蔽
            return isCategoryAvailableForPostGeneration(character.category)
        }
    }
    
    /**
     * 检查角色是否可用（用于帖子生成）
     * @param character - 要检查的角色
     * @return 是否可用
     */
    func isCharacterAvailable(_ character: CharacterModel) -> Bool {
        let isUserCreated = character.id.hasPrefix("custom_")
        
        // 🔒 用户创建的角色：只受"我的创建"分类的屏蔽影响
        if isUserCreated {
            return !isCategoryBlocked(.myCreation)
        }
        
        // 🔒 非用户创建的角色：检查分类是否被屏蔽
        return isCategoryAvailableForPostGeneration(character.category)
    }
}

