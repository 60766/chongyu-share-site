import Foundation

/**
 * 全局点赞状态管理器
 * 使用第一性原理：最简单的方式存储点赞状态，避免复杂的状态同步
 */
class LikeStateManager: ObservableObject {
    static let shared = LikeStateManager()
    
    // 存储所有点赞状态的字典 - postId/commentId -> 是否点赞
    @Published private var likedItems: Set<String> = []
    
    // UserDefaults key
    private let likedItemsKey = "user_liked_items"
    
    private init() {
        loadLikedItems()
    }
    
    // MARK: - 公共接口
    
    /**
     * 检查是否已点赞
     */
    func isLiked(_ itemId: String) -> Bool {
        return likedItems.contains(itemId)
    }
    
    /**
     * 切换点赞状态
     * 返回新的点赞状态
     */
    func toggleLike(_ itemId: String) -> Bool {
        if likedItems.contains(itemId) {
            likedItems.remove(itemId)
            saveLikedItems()
            return false
        } else {
            likedItems.insert(itemId)
            saveLikedItems()
            return true
        }
    }
    
    /**
     * 设置点赞状态
     */
    func setLiked(_ itemId: String, isLiked: Bool) {
        if isLiked {
            likedItems.insert(itemId)
        } else {
            likedItems.remove(itemId)
        }
        saveLikedItems()
    }
    
    /**
     * 获取所有已点赞的项目ID
     */
    func getAllLikedItems() -> Set<String> {
        return likedItems
    }
    
    // MARK: - 持久化
    
    private func loadLikedItems() {
        if let data = UserDefaults.standard.data(forKey: likedItemsKey),
           let items = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.likedItems = items
            print("📖 加载了 \(items.count) 个点赞状态")
        }
    }
    
    private func saveLikedItems() {
        if let data = try? JSONEncoder().encode(likedItems) {
            UserDefaults.standard.set(data, forKey: likedItemsKey)
            print("💾 保存了 \(likedItems.count) 个点赞状态")
        }
    }
} 