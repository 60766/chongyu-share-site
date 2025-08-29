import Foundation
import Combine
import SwiftUI

/**
 * 全局应用状态管理器
 * 这是一个遵循观察者模式的类，用于管理整个应用的共享状态。
 * 使用 @MainActor 确保所有状态更新都在主线程上进行。
 */
@MainActor
class AppState: ObservableObject {
    // MARK: - 单例
    static let shared = AppState()

    // MARK: - 导航状态
    @Published var selectedTab: Int = 0

    // MARK: - 全局数据源
    @Published var posts: [UserPostModel] = []
    @Published var characters: [CharacterModel] = []
    @Published var notifications: [NotificationModel] = []
    
    // MARK: - 用户统计数据
    @Published var userStats: UserStatsModel?

    // MARK: - 服务与视图模型
    // 将现有的单例服务集中管理，方便访问并解耦视图
    let postViewModel = PostViewModel.shared
    let notificationService = NotificationService.shared
    
    // MARK: - 缓存控制
    private var lastLoadTime: [String: Date] = [:]
    private let cacheDuration: TimeInterval = 300 // 5分钟缓存有效期

    private var cancellables = Set<AnyCancellable>()

    // MARK: - 初始化
    private init() {
        print("🚀 AppState 初始化...")
        setupBindings()
        loadInitialData()
    }

    private func setupBindings() {
        // 将 PostViewModel 的 posts 数据绑定到 AppState 的 posts
        postViewModel.$posts
            .receive(on: RunLoop.main)
            .assign(to: \.posts, on: self)
            .store(in: &cancellables)

        // 将 NotificationService 的 notifications 数据绑定到 AppState 的 notifications
        notificationService.$notifications
            .receive(on: RunLoop.main)
            .assign(to: \.notifications, on: self)
            .store(in: &cancellables)
    }

    // MARK: - 数据加载
    func loadInitialData() {
        print("⏳ AppState 开始加载初始数据...")
        loadCharacters()
        // postViewModel 和 notificationService 会在初始化时自动加载数据
        // 因此这里只需要确保它们被初始化即可
        
        // 计算初始用户统计
        updateUserStats()
    }
    
    // 加载角色数据
    func loadCharacters(force: Bool = false) {
        if shouldLoadData(forKey: "characters", force: force) {
            print("🎭 AppState 正在加载角色数据...")
            self.characters = CharacterModel.getAllCharacters()
            self.lastLoadTime["characters"] = Date()
            print("✅ AppState 角色数据加载完成，共 \(self.characters.count) 个角色。")
        }
    }
    
    // 更新用户统计数据
    func updateUserStats(force: Bool = false) {
        if shouldLoadData(forKey: "userStats", force: force) {
            print("📊 AppState 正在更新用户统计...")
            
            // 使用后台线程进行计算，避免阻塞UI
            Task(priority: .utility) {
                let stats = await calculateUserStats()
                // 计算完成后，切换回主线程更新UI
                await MainActor.run {
                    self.userStats = stats
                    self.lastLoadTime["userStats"] = Date()
                    print("✅ AppState 用户统计更新完成。")
                }
            }
        }
    }

    // MARK: - 缓存逻辑
    private func shouldLoadData(forKey key: String, force: Bool) -> Bool {
        if force {
            print("⚡️ 强制刷新: \(key)")
            return true
        }
        guard let lastLoad = lastLoadTime[key] else {
            print("⏳ 首次加载: \(key)")
            return true
        }
        let interval = Date().timeIntervalSince(lastLoad)
        if interval > cacheDuration {
            print("⏰ 缓存过期，重新加载: \(key) (已过 \(Int(interval)) 秒)")
            return true
        }
        print("✅ 从缓存加载: \(key)")
        return false
    }
    
    // MARK: - 统计计算 (私有)
    private func calculateUserStats() async -> UserStatsModel {
        // 在这里执行 ProfileView 中的复杂计算
        // 这是一个示例，你需要将 ProfileView 中的逻辑迁移到这里
        let dialogueCount = postViewModel.posts.count // 示例：动态数
        let resonanceScore = notificationService.notifications.filter { $0.type == .like }.count // 示例：获赞数
        let deepConnectionCount = 0 // 示例：好友数，需要具体逻辑
        let explorationDays = 0 // 示例：探索天数，需要具体逻辑
        
        return UserStatsModel(
            dialogueCount: dialogueCount,
            resonanceScore: resonanceScore,
            deepConnectionCount: deepConnectionCount,
            explorationDays: explorationDays,
            collectedHighlights: 0,
            dimensionJumps: 0
        )
    }
}

// 定义一个简单的用户统计数据模型
struct UserStatsModel {
    let dialogueCount: Int       // 次元对话数
    let resonanceScore: Int      // 共鸣分数
    let deepConnectionCount: Int // 互动好友数
    let explorationDays: Int     // 探索天数
    let collectedHighlights: Int // 点赞收藏数
    let dimensionJumps: Int      // 我的动态数
} 