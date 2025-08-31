import Foundation
import SwiftUI
import SwiftData
import UIKit

// MARK: - 成就等级枚举
enum AchievementLevel: String, CaseIterable, Codable {
    case bronze = "青铜"
    case silver = "白银" 
    case gold = "黄金"
    
    var emoji: String {
        switch self {
        case .bronze: return "🥉"
        case .silver: return "🥈"
        case .gold: return "🥇"
        }
    }
    
    var color: Color {
        switch self {
        case .bronze: return Color(red: 0.80, green: 0.52, blue: 0.25)  // 青铜色：温暖的棕橙色
        case .silver: return Color(red: 0.75, green: 0.82, blue: 0.95)  // 银色：冷艳的银蓝色
        case .gold: return Color(red: 0.95, green: 0.75, blue: 0.20)    // 金色：纯正的金黄色
        }
    }
    
    var thresholds: (Int, Int, Int) {
        switch self {
        case .bronze: return (5, 10, 15)   // 青铜门槛较低
        case .silver: return (15, 30, 50)  // 白银中等难度
        case .gold: return (50, 100, 200)  // 黄金高挑战性
        }
    }
}

// MARK: - 成就类型枚举
enum AchievementType: String, CaseIterable, Codable {
    case interaction = "互动达人"
    case popularity = "人气之星"  
    case exploration = "探索者"
    case temporal = "时光旅人"
    case social = "社交高手"
    case insight = "见解独到"
    case consistency = "坚持不懈"
    case milestone = "里程碑"
}

// MARK: - 成就数据模型
struct CYAchievement: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let type: AchievementType
    let currentProgress: Int
    let targetProgress: Int
    let level: AchievementLevel
    let isUnlocked: Bool
    let unlockedAt: Date?
    let isPinned: Bool
    
    var progressPercentage: Double {
        guard targetProgress > 0 else { return 0 }
        return min(Double(currentProgress) / Double(targetProgress), 1.0)
    }
    
    var progressText: String {
        return "\(currentProgress)/\(targetProgress)"
    }
}

// MARK: - 成就评估器
class AchievementEvaluator: ObservableObject {
    @Published var achievements: [CYAchievement] = []
    
    // 单例模式
    static let shared = AchievementEvaluator()
    
    // UserDefaults键名
    private let pinnedAchievementsKey = "PinnedAchievements"
    
    private init() {
        setupInitialAchievements()
    }
    
    // MARK: - 固定成就管理
    
    /// 切换成就的固定状态
    func toggleAchievementPin(achievementId: String) {
        // 立即触发触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        var pinnedIds = getPinnedAchievementIds()
        let wasPinned = pinnedIds.contains(achievementId)
        
        if wasPinned {
            pinnedIds.removeAll { $0 == achievementId }
        } else {
            // 限制最多固定6个成就
            if pinnedIds.count >= 6 {
                pinnedIds.removeFirst() // 移除最早固定的
            }
            pinnedIds.append(achievementId)
        }
        
        savePinnedAchievementIds(pinnedIds)
        refreshAchievementsPinnedStatus()
        
        // 强制立即更新UI
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
        

    }
    
    /// 获取优先展示的成就（固定的成就 + 按默认顺序的其他成就）
    func getDisplayAchievements() -> [CYAchievement] {
        let pinnedAchievements = achievements.filter { $0.isPinned }
        let unpinnedAchievements = achievements.filter { !$0.isPinned }
        
        // 如果固定的成就不足6个，用默认顺序的成就补充
        var displayAchievements = pinnedAchievements
        
        if displayAchievements.count < 6 {
            let remainingSlots = 6 - displayAchievements.count
            // 保持原始顺序，不进行重新排序
            displayAchievements.append(contentsOf: Array(unpinnedAchievements.prefix(remainingSlots)))
        }
        
        return Array(displayAchievements.prefix(6))
    }
    
    /// 按优先级排序成就（等级高、进度高的优先）
    private func prioritizeAchievements(_ achievements: [CYAchievement]) -> [CYAchievement] {
        return achievements.sorted { achievement1, achievement2 in
            // 优先级规则：1) 等级高的优先 2) 进度百分比高的优先 3) 已解锁的优先
            if achievement1.level != achievement2.level {
                return levelPriority(achievement1.level) > levelPriority(achievement2.level)
            }
            
            if achievement1.progressPercentage != achievement2.progressPercentage {
                return achievement1.progressPercentage > achievement2.progressPercentage
            }
            
            if achievement1.isUnlocked != achievement2.isUnlocked {
                return achievement1.isUnlocked && !achievement2.isUnlocked
            }
            
            return false
        }
    }
    
    /// 等级优先级权重
    private func levelPriority(_ level: AchievementLevel) -> Int {
        switch level {
        case .gold: return 3
        case .silver: return 2
        case .bronze: return 1
        }
    }
    
    /// 获取固定的成就ID列表
    private func getPinnedAchievementIds() -> [String] {
        return UserDefaults.standard.stringArray(forKey: pinnedAchievementsKey) ?? []
    }
    
    /// 保存固定的成就ID列表
    private func savePinnedAchievementIds(_ ids: [String]) {
        UserDefaults.standard.set(ids, forKey: pinnedAchievementsKey)
    }
    
    /// 刷新所有成就的固定状态
    private func refreshAchievementsPinnedStatus() {
        let pinnedIds = Set(getPinnedAchievementIds())
        
        for i in 0..<achievements.count {
            let achievement = achievements[i]
            let shouldBePinned = pinnedIds.contains(achievement.id)
            
            if achievement.isPinned != shouldBePinned {
                achievements[i] = CYAchievement(
                    id: achievement.id,
                    name: achievement.name,
                    description: achievement.description,
                    icon: achievement.icon,
                    type: achievement.type,
                    currentProgress: achievement.currentProgress,
                    targetProgress: achievement.targetProgress,
                    level: achievement.level,
                    isUnlocked: achievement.isUnlocked,
                    unlockedAt: achievement.unlockedAt,
                    isPinned: shouldBePinned
                )
            }
        }
    }
    
    private func setupInitialAchievements() {
        achievements = [
            // 1. 心有灵犀 - 核心情感连接成就
            CYAchievement(
                id: "heart_connection_bronze",
                name: "心有灵犀",
                description: "与AI角色进行深度对话，建立心灵连接",
                icon: "🌟",
                type: .interaction,
                currentProgress: 7,
                targetProgress: 10,
                level: .bronze,
                isUnlocked: false,
                unlockedAt: nil,
                isPinned: false
            ),
            
            // 2. 共鸣之星 - 社交认可成就
            CYAchievement(
                id: "resonance_star_bronze",
                name: "共鸣之星",
                description: "收获社区成员的点赞与认可",
                icon: "✨",
                type: .popularity,
                currentProgress: 6,
                targetProgress: 10,
                level: .bronze,
                isUnlocked: false,
                unlockedAt: nil,
                isPinned: false
            ),
            
            // 3. 时光旅人 - 习惯养成成就
            CYAchievement(
                id: "time_traveler_bronze",
                name: "时光旅人",
                description: "连续7天活跃使用APP，养成良好习惯",
                icon: "🕰️",
                type: .temporal,
                currentProgress: 17,
                targetProgress: 30,
                level: .bronze,
                isUnlocked: false,
                unlockedAt: nil,
                isPinned: false
            ),
            
            // 4. 夜猫子 - 夜间认同成就
            CYAchievement(
                id: "night_owl_bronze",
                name: "夜猫子",
                description: "在深夜时光中寻找知音，拥抱夜之宁静",
                icon: "🌙",
                type: .consistency,
                currentProgress: 3,
                targetProgress: 7,
                level: .bronze,
                isUnlocked: false,
                unlockedAt: nil,
                isPinned: false
            ),
            
            // 5. 次元段位 - 身份体系成就 (白银级别)
            CYAchievement(
                id: "dimension_rank_silver",
                name: "次元段位",
                description: "在虚拟世界中证明实力，获得认可",
                icon: "👑",
                type: .milestone,
                currentProgress: 388,
                targetProgress: 600,
                level: .bronze,
                isUnlocked: false,
                unlockedAt: nil,
                isPinned: false
            ),
            
            // 6. 领域漫游者 - 探索激励成就 (白银级别)
            CYAchievement(
                id: "domain_wanderer_silver",
                name: "领域漫游者",
                description: "深度探索不同领域，与每个领域的5个角色互动",
                icon: "🧭",
                type: .exploration,
                currentProgress: 2,
                targetProgress: 3,
                level: .silver,
                isUnlocked: false,
                unlockedAt: nil,
                isPinned: false
            ),
            
            // 7. 晨光对话 - 健康作息成就
            CYAchievement(
                id: "dawn_dialogue_bronze",
                name: "晨光对话",
                description: "在第一缕阳光中开始美好的一天",
                icon: "🌅",
                type: .consistency,
                currentProgress: 4,
                targetProgress: 7,
                level: .bronze,
                isUnlocked: false,
                unlockedAt: nil,
                isPinned: false
            ),
            
            // 8. 社交达人 - 角色互动广度成就 (黄金级别)
            CYAchievement(
                id: "social_master_gold",
                name: "社交达人",
                description: "与15个不同的AI角色建立互动，开启社交之路",
                icon: "🤝",
                type: .social,
                currentProgress: 11,
                targetProgress: 15,
                level: .bronze,
                isUnlocked: false,
                unlockedAt: nil,
                isPinned: false
            )
        ]
        
        // 初始化完成后，刷新固定状态
        refreshAchievementsPinnedStatus()
    }
    
    // MARK: - 辅助方法
    
    /// 创建更新后的成就，保持固定状态
    private func createUpdatedAchievement(
        from original: CYAchievement,
        currentProgress: Int,
        targetProgress: Int,
        level: AchievementLevel,
        isUnlocked: Bool
    ) -> CYAchievement {
        return CYAchievement(
            id: original.id,
            name: original.name,
            description: original.description,
            icon: original.icon,
            type: original.type,
            currentProgress: currentProgress,
            targetProgress: targetProgress,
            level: level,
            isUnlocked: isUnlocked,
            unlockedAt: isUnlocked ? Date() : nil,
            isPinned: original.isPinned
        )
    }
    
    // MARK: - 成就进度更新方法
    
    func updateAllAchievements(using modelContext: ModelContext? = nil) {

        updatePopularityAchievement()
        updateSocialMasterAchievement()
        updateInteractionAchievement(using: modelContext)
        updateExplorationAchievement(using: modelContext)
        updateTemporalAchievement(using: modelContext)
        updateConsistencyAchievements(using: modelContext)
        updateMilestoneAchievement()
        
        // 刷新固定状态
        refreshAchievementsPinnedStatus()
        

        
        // 强制触发UI更新
        DispatchQueue.main.async {
    
            self.objectWillChange.send()
        }
    }
    
    func updateInteractionAchievement(using modelContext: ModelContext? = nil) {
        // 根据与单个角色的对话轮次更新"心有灵犀"成就
        let maxDialogueCount = calculateMaxDialogueWithSingleCharacter(using: modelContext)
        
        // 心有灵犀成就等级门槛：青铜10 → 白银50 → 黄金200
        let (level, targetProgress, isUnlocked) = determineAchievementLevel(
            progress: maxDialogueCount,
            bronzeThreshold: 10,
            silverThreshold: 50,
            goldThreshold: 200
        )
        
        for i in 0..<achievements.count {
            if achievements[i].name == "心有灵犀" {
                let _ = achievements[i].currentProgress
                let _ = achievements[i].level
                
                achievements[i] = createUpdatedAchievement(
                    from: achievements[i],
                    currentProgress: maxDialogueCount,
                    targetProgress: targetProgress,
                    level: level,
                    isUnlocked: isUnlocked
                )
                
    
                break
            }
        }
    }
    
    func updatePopularityAchievement() {
        // 根据通知系统中的点赞数据更新"共鸣之星"成就
        let totalLikes = calculateTotalResonance()
        
        // 共鸣之星成就等级门槛：青铜10 → 白银100 → 黄金500
        let (level, targetProgress, isUnlocked) = determineAchievementLevel(
            progress: totalLikes,
            bronzeThreshold: 10,
            silverThreshold: 100,
            goldThreshold: 500
        )
        
        for i in 0..<achievements.count {
            if achievements[i].name == "共鸣之星" {
                achievements[i] = createUpdatedAchievement(
                    from: achievements[i],
                    currentProgress: totalLikes,
                    targetProgress: targetProgress,
                    level: level,
                    isUnlocked: isUnlocked
                )
                break
            }
        }
    }
    
    func updateSocialMasterAchievement() {
        // 根据互动角色数量更新"社交达人"成就
        let interactedCharacters = calculateTotalActiveCharacters()
        

        
        // 社交达人成就等级门槛：青铜15 → 白银40 → 黄金80（共169个角色，挑战性门槛）
        let (level, targetProgress, isUnlocked) = determineAchievementLevel(
            progress: interactedCharacters,
            bronzeThreshold: 15,
            silverThreshold: 40,
            goldThreshold: 80
        )
        
        for i in 0..<achievements.count {
            if achievements[i].name == "社交达人" {
                let _ = achievements[i].currentProgress
                let _ = achievements[i].level
                
                achievements[i] = createUpdatedAchievement(
                    from: achievements[i],
                    currentProgress: interactedCharacters,
                    targetProgress: targetProgress,
                    level: level,
                    isUnlocked: isUnlocked
                )
                
    
                break
            }
        }
    }
    
    func updateExplorationAchievement(using modelContext: ModelContext? = nil) {
        // 根据探索的不同角色领域数量更新"领域漫游者"成就
        let exploredDomains = calculateExploredCharacterDomains(using: modelContext)
        

        
        // 领域漫游者成就等级门槛：青铜1 → 白银3 → 黄金6（每领域需要5个角色，难度大幅提升）
        let (level, targetProgress, isUnlocked) = determineAchievementLevel(
            progress: exploredDomains,
            bronzeThreshold: 1,
            silverThreshold: 3,
            goldThreshold: 6
        )
        
        for i in 0..<achievements.count {
            if achievements[i].name == "领域漫游者" {
                let _ = achievements[i].currentProgress
                let _ = achievements[i].level
                
                achievements[i] = createUpdatedAchievement(
                    from: achievements[i],
                    currentProgress: exploredDomains,
                    targetProgress: targetProgress,
                    level: level,
                    isUnlocked: isUnlocked
                )
                
    
                break
            }
        }
    }
    
    func updateTemporalAchievement(using modelContext: ModelContext? = nil) {
        // 根据活跃天数更新"时光旅人"成就
        let activeDays = calculateActiveDays(using: modelContext)
        

        
        // 时光旅人成就等级门槛：青铜7 → 白银30 → 黄金100
        let (level, targetProgress, isUnlocked) = determineAchievementLevel(
            progress: activeDays,
            bronzeThreshold: 7,
            silverThreshold: 30,
            goldThreshold: 100
        )
        
        for i in 0..<achievements.count {
            if achievements[i].name == "时光旅人" {
                let _ = achievements[i].currentProgress
                let _ = achievements[i].level
                
                achievements[i] = createUpdatedAchievement(
                    from: achievements[i],
                    currentProgress: activeDays,
                    targetProgress: targetProgress,
                    level: level,
                    isUnlocked: isUnlocked
                )
                
    
                break
            }
        }
    }
    
    func updateConsistencyAchievements(using modelContext: ModelContext? = nil) {
        // 根据使用时间段更新"晨光对话"和"夜猫子"成就
        let nightOwlCount = calculateNightTimeConversations(using: modelContext)
        let morningLightCount = calculateMorningTimeConversations(using: modelContext)
        
        // 夜猫子成就等级门槛：青铜7 → 白银30 → 黄金100
        let (nightLevel, nightTargetProgress, nightIsUnlocked) = determineAchievementLevel(
            progress: nightOwlCount,
            bronzeThreshold: 7,
            silverThreshold: 30,
            goldThreshold: 100
        )
        
        // 晨光对话成就等级门槛：青铜7 → 白银30 → 黄金100
        let (morningLevel, morningTargetProgress, morningIsUnlocked) = determineAchievementLevel(
            progress: morningLightCount,
            bronzeThreshold: 7,
            silverThreshold: 30,
            goldThreshold: 100
        )
        
        // 更新夜猫子成就
        for i in 0..<achievements.count {
            if achievements[i].name == "夜猫子" {
                achievements[i] = createUpdatedAchievement(
                    from: achievements[i],
                    currentProgress: nightOwlCount,
                    targetProgress: nightTargetProgress,
                    level: nightLevel,
                    isUnlocked: nightIsUnlocked
                )
                break
            }
        }
        
        // 更新晨光对话成就
        for i in 0..<achievements.count {
            if achievements[i].name == "晨光对话" {
                achievements[i] = createUpdatedAchievement(
                    from: achievements[i],
                    currentProgress: morningLightCount,
                    targetProgress: morningTargetProgress,
                    level: morningLevel,
                    isUnlocked: morningIsUnlocked
                )
                break
            }
        }
    }
    
    func updateMilestoneAchievement() {
        // 根据综合评分更新"次元段位"成就
        let comprehensiveScore = calculateComprehensiveScore()
        

        
        // 次元段位成就等级门槛：青铜200 → 白银600 → 黄金1200（删除质量加成后重新平衡，总分1350）
        let (level, targetProgress, isUnlocked) = determineAchievementLevel(
            progress: comprehensiveScore,
            bronzeThreshold: 200,
            silverThreshold: 600,
            goldThreshold: 1200
        )
        
        for i in 0..<achievements.count {
            if achievements[i].name == "次元段位" {
                let _ = achievements[i].currentProgress
                let _ = achievements[i].level
                
                achievements[i] = createUpdatedAchievement(
                    from: achievements[i],
                    currentProgress: comprehensiveScore,
                    targetProgress: targetProgress,
                    level: level,
                    isUnlocked: isUnlocked
                )
                
    
                break
            }
        }
    }
    
    // MARK: - 数据计算方法（从ProfileView复制过来）
    
    /// 计算总共鸣数：从通知数据中统计用户收到的实际点赞总数
    private func calculateTotalResonance() -> Int {
        // 从NotificationService的永久存储中获取所有点赞通知
        let likeNotifications = NotificationService.shared.notifications.filter { notification in
            notification.type == .like
        }
        

        
        // 统计总点赞数
        let totalLikes = likeNotifications.count
        

        
        return totalLikes
    }
    
    /// 计算总互动角色数：仅统计帖子互动，避免数据冲突
    private func calculateTotalActiveCharacters() -> Int {
        var interactedCharacters: Set<String> = []
        let posts = PostViewModel.shared.posts
        
        // 注意：跳过私聊统计以避免ModelContext冲突
        
        // 2. 统计在帖子中与用户互动的角色（给用户帖子点赞或评论）
        let userPosts = posts.filter { $0.characterID == nil }
        for post in userPosts {
            // 检查给用户帖子点赞的角色（通过点赞通知）
            let postLikeNotifications = NotificationService.shared.notifications.filter { notification in
                notification.type == .like && notification.relatedPostId == post.id.uuidString
            }
            for notification in postLikeNotifications {
                if let character = notification.character {
                    // 通过角色名称查找角色ID
                    let characterInfoList = CharacterDataManager.shared.getAllCharactersInfo()
                    if let characterInfo = characterInfoList.first(where: { $0.name == character.name }) {
                        interactedCharacters.insert(characterInfo.id)
                    }
                }
            }
            
            // 检查给用户帖子评论的角色
            for comment in post.comments where comment.isVirtualCharacter {
                if let characterID = comment.characterID {
                    interactedCharacters.insert(characterID)
                }
            }
        }
        
        // 3. 统计在评论中与用户互动的角色（给用户评论点赞或回复）
        for post in posts {
            for comment in post.comments where !comment.isVirtualCharacter {
                // 这是用户的评论，检查哪些角色回复了
                for reply in comment.replies where reply.isVirtualCharacter {
                    if let characterID = reply.characterID {
                        interactedCharacters.insert(characterID)
                    }
                }
            }
        }
        
        return interactedCharacters.count
    }
    
    /// 计算与单个角色的最大对话轮次
    private func calculateMaxDialogueWithSingleCharacter(using providedContext: ModelContext? = nil) -> Int {
        var dialogueCountByCharacter: [String: Int] = [:]
        
        // 必须使用提供的ModelContext，不能创建独立的ModelContext
        guard let modelContext = providedContext else {
            return 0
        }
        
        do {
            // 获取所有用户发送的消息
            let messageDescriptor = FetchDescriptor<Message>(
                predicate: #Predicate<Message> { message in
                    message.isFromUser
                }
            )
            let userMessages = try modelContext.fetch(messageDescriptor)
            

            
            // 按接收者（角色）分组计算对话轮数
            for message in userMessages {
                let characterId = message.receiverId
                if !characterId.isEmpty && characterId != "currentUser" {
                    dialogueCountByCharacter[characterId, default: 0] += 1

                }
            }
            
            // 找出最大的对话轮数
            let maxCount = dialogueCountByCharacter.values.max() ?? 0
            

            
            return maxCount
            
        } catch {
            return 0
        }
    }
    
    /// 获取聊天最多的前三个角色信息（用于心有灵犀成就显示）
    func getTopThreeCharactersForHeartConnection(using providedContext: ModelContext? = nil) -> [(characterId: String, messageCount: Int, character: CharacterSystem.CharacterIdentity?)] {
        var dialogueCountByCharacter: [String: Int] = [:]
        
        // 必须使用提供的ModelContext，不能创建独立的ModelContext
        guard let modelContext = providedContext else {
            return []
        }
        
        do {
            // 获取所有用户发送的消息
            let messageDescriptor = FetchDescriptor<Message>(
                predicate: #Predicate<Message> { message in
                    message.isFromUser
                }
            )
            let userMessages = try modelContext.fetch(messageDescriptor)
            
            // 按接收者（角色）分组计算对话轮数
            for message in userMessages {
                let characterId = message.receiverId
                if !characterId.isEmpty && characterId != "currentUser" {
                    dialogueCountByCharacter[characterId, default: 0] += 1
                }
            }
            
            // 按对话数量排序，取前三名
            let sortedCharacters = dialogueCountByCharacter.sorted { $0.value > $1.value }
            let topThree = Array(sortedCharacters.prefix(3))
            
            // 获取角色详细信息
            let allCharacters = CharacterSystem.shared.getAllCharacters()
            let result = topThree.map { (characterId, count) in
                let character = allCharacters.first { $0.id == characterId }
                return (characterId: characterId, messageCount: count, character: character)
            }
            

            
            return result
            
        } catch {
            return []
        }
    }
    
    /// 计算探索的角色领域数量（每个领域需要与5个不同角色互动才算探索完成）
    /// 互动标准：1) 私聊消息往来 2) 评论区互动，不包括仅查看帖子
    private func calculateExploredCharacterDomains(using providedContext: ModelContext? = nil) -> Int {
        // 改为统计每个分类下的角色数量
        var categoryCharacterCounts: [CharacterCategory: Set<String>] = [:]
        
        // 1. 从私聊消息中获取互动过的角色
        var interactedCharacterIds: Set<String> = []
        
        // 必须使用提供的ModelContext，不能创建独立的ModelContext
        guard let modelContext = providedContext else {
            return 0
        }
        
        do {
            let messageDescriptor = FetchDescriptor<Message>()
            let allMessages = try modelContext.fetch(messageDescriptor)
            
            for message in allMessages {
                if message.isFromUser {
                    // 用户发送的消息，接收者是角色
                    if !message.receiverId.isEmpty && message.receiverId != "currentUser" {
                        interactedCharacterIds.insert(message.receiverId)
                    }
                } else {
                    // 角色发送的消息，发送者是角色
                    if !message.senderId.isEmpty && message.senderId != "currentUser" {
                        interactedCharacterIds.insert(message.senderId)
                    }
                }
            }
        } catch {
        }
        
        // 2. 从评论互动中获取角色（不包括仅查看帖子）
        let posts = PostViewModel.shared.posts
        for post in posts {
            // 只统计在评论区有互动的角色，不包括仅仅是帖子作者
            for comment in post.comments where comment.isVirtualCharacter {
                if let characterID = comment.characterID {
                    interactedCharacterIds.insert(characterID)
                }
            }
        }
        
        // 3. 根据角色ID获取角色分类
        let allCharacters = CharacterSystem.shared.getAllCharacters()
        
        // 4. 统计每个分类下的角色数量
        for characterId in interactedCharacterIds {
            if let character = allCharacters.first(where: { $0.id == characterId }) {
                // 根据角色的type和primaryField映射到分类
                let category = mapCharacterToCategory(character: character)
                
                // 初始化分类的角色集合
                if categoryCharacterCounts[category] == nil {
                    categoryCharacterCounts[category] = Set<String>()
                }
                categoryCharacterCounts[category]?.insert(characterId)
                
    
            } else {

            }
        }
        
        // 5. 计算达到探索标准的领域数量（每个领域需要5个不同角色）
        let requiredCharactersPerDomain = 5
        var fullyExploredDomains = 0
        

        for (_, characterIds) in categoryCharacterCounts {
            let count = characterIds.count
            let isFullyExplored = count >= requiredCharactersPerDomain
            
            if isFullyExplored {
                fullyExploredDomains += 1
            }
        }
        

        
        return fullyExploredDomains
    }
    
    /// 获取各领域的详细探索进度（用于显示详情）
    func getDomainExplorationProgress(using providedContext: ModelContext? = nil) -> [String: (current: Int, required: Int, isCompleted: Bool)] {
        var categoryCharacterCounts: [CharacterCategory: Set<String>] = [:]
        var interactedCharacterIds: Set<String> = []
        
        // 必须使用提供的ModelContext，不能创建独立的ModelContext
        guard let modelContext = providedContext else {
            return [:]
        }
        
        do {
            let messageDescriptor = FetchDescriptor<Message>()
            let allMessages = try modelContext.fetch(messageDescriptor)
            
            for message in allMessages {
                if message.isFromUser {
                    if !message.receiverId.isEmpty && message.receiverId != "currentUser" {
                        interactedCharacterIds.insert(message.receiverId)
                    }
        } else {
                    if !message.senderId.isEmpty && message.senderId != "currentUser" {
                        interactedCharacterIds.insert(message.senderId)
        }
                }
            }
        } catch {
    }
    
        // 从评论互动中获取角色（不包括仅查看帖子）
        let posts = PostViewModel.shared.posts
        for post in posts {
            // 只统计在评论区有互动的角色，不包括仅仅是帖子作者
            for comment in post.comments where comment.isVirtualCharacter {
                if let characterID = comment.characterID {
                    interactedCharacterIds.insert(characterID)
                }
            }
        }
        
        // 统计每个分类下的角色数量
        let allCharacters = CharacterSystem.shared.getAllCharacters()
        for characterId in interactedCharacterIds {
            if let character = allCharacters.first(where: { $0.id == characterId }) {
                let category = mapCharacterToCategory(character: character)
                if categoryCharacterCounts[category] == nil {
                    categoryCharacterCounts[category] = Set<String>()
                }
                categoryCharacterCounts[category]?.insert(characterId)
            }
        }
        
        // 转换为进度字典
        var progressDict: [String: (current: Int, required: Int, isCompleted: Bool)] = [:]
        let requiredCharactersPerDomain = 5
        
        for (category, characterIds) in categoryCharacterCounts {
            let current = characterIds.count
            let isCompleted = current >= requiredCharactersPerDomain
            progressDict[category.displayName] = (
                current: current,
                required: requiredCharactersPerDomain,
                isCompleted: isCompleted
            )
        }
        
        return progressDict
    }
    
    /// 将角色映射到分类（基于实际JSON数据的type和subtype）
    private func mapCharacterToCategory(character: CharacterSystem.CharacterIdentity) -> CharacterCategory {
        // 首先根据type进行主要分类
        switch character.type {
        case .historical:
            // 历史人物根据subtype进一步细分
            return mapHistoricalSubtype(character)
        case .literary:
            return .fictionCharacter // 文学角色
        case .movie:
            return .movieCharacter // 电影角色
        case .tv:
            return .tvCharacter // 电视剧角色
        case .anime:
            return .animeCharacter // 动漫角色
        case .game:
            return .gameCharacter // 游戏角色
        case .mythological:
            return .mythCharacter // 神话角色
        case .entrepreneur:
            return .historical // 企业家归类为历史人物
        case .scifi:
            return .fictionCharacter // 科幻角色归为虚构人物
        case .fantasy:
            return .fictionCharacter // 奇幻角色归为虚构人物
        case .custom:
            return .fictionCharacter // 自定义角色归为虚构人物
        case .unknown:
            return .historical // 未知类型默认归为历史人物
        }
    }
    
    /// 映射历史人物的子类型
    private func mapHistoricalSubtype(_ character: CharacterSystem.CharacterIdentity) -> CharacterCategory {
        // 获取subtype字符串（需要从CharacterIdentity中获取）
        // 由于CharacterIdentity可能没有直接的subtype字段，我们通过primaryField来判断
        let field = character.primaryField.lowercased()
        
        // 根据primaryField内容判断具体分类
        if field.contains("科学") || field.contains("物理") || field.contains("数学") || 
           field.contains("化学") || field.contains("生物") || field.contains("医学") ||
           field.contains("发明") || field.contains("scientist") {
            return .scientist
        } else if field.contains("哲学") || field.contains("思想") || field.contains("philosopher") {
            return .philosopher
        } else if field.contains("文学") || field.contains("诗") || field.contains("作家") || 
                 field.contains("戏剧") || field.contains("writer") || field.contains("poet") {
            return .writer
        } else if field.contains("艺术") || field.contains("画") || field.contains("音乐") || 
                 field.contains("雕塑") || field.contains("artist") || field.contains("painter") {
            return .artist
        } else {
            return .historical // 其他历史人物
        }
    }
    
    /// 计算活跃天数：统计用户所有互动行为的不同日期数
    private func calculateActiveDays(using providedContext: ModelContext? = nil) -> Int {
        // 时光旅人成就评判标准：
        // - 统计实际有活动的天数，包括：发消息、发帖、评论、点赞、收藏等所有互动
        // - 更准确反映用户参与度，使用统一的评判标准
        return calculateActualActiveDays(using: providedContext)
    }
    

    
    /// 计算实际活跃天数：包括所有用户活动（消息、发帖、评论、点赞、收藏、查看等互动行为）
    private func calculateActualActiveDays(using providedContext: ModelContext? = nil) -> Int {
        let calendar = Calendar.current
        var activeDays: Set<Date> = []
        
        // 1. 统计有对话的天数
        // 必须使用提供的ModelContext，不能创建独立的ModelContext
        guard let modelContext = providedContext else {
            return 1
        }
        
        do {
            // 统计用户发送的消息天数
            let messageDescriptor = FetchDescriptor<Message>(
                predicate: #Predicate<Message> { message in
                    message.isFromUser
                }
            )
            let userMessages = try modelContext.fetch(messageDescriptor)
            
            for message in userMessages {
                let dayStart = calendar.startOfDay(for: message.timestamp)
                activeDays.insert(dayStart)
            }
            
        } catch {
        }
        
        // 2. 统计用户发帖的天数
        let posts = PostViewModel.shared.posts
        let userPosts = posts.filter { $0.characterID == nil } // 用户发的帖子
        for post in userPosts {
            let dayStart = calendar.startOfDay(for: post.datePosted)
            activeDays.insert(dayStart)
        }
        
        // 3. 统计用户评论的天数
        var userCommentDays = 0
        for post in posts {
            for comment in post.comments where !comment.isVirtualCharacter {
                // 用户的评论
                let dayStart = calendar.startOfDay(for: comment.datePosted)
                activeDays.insert(dayStart)
                userCommentDays += 1
                
                // 用户回复的天数
                for reply in comment.replies where !reply.isVirtualCharacter {
                    let replyDayStart = calendar.startOfDay(for: reply.datePosted)
                    activeDays.insert(replyDayStart)
                }
            }
        }
        
        // 4. 统计用户的各种互动活动天数（通过UserInterestTracker）
        let interactionRecords = UserInterestTracker.shared.interestModel.interactionHistory
        var interactionActivityDays = 0
        
        for record in interactionRecords {
            let dayStart = calendar.startOfDay(for: record.timestamp)
            activeDays.insert(dayStart)
            interactionActivityDays += 1
        }
        
        // 5. 统计收到通知的天数（表示用户内容被互动，间接反映活跃度）
        let notifications = NotificationService.shared.notifications
        var notificationDays = 0
        
        for notification in notifications {
            let dayStart = calendar.startOfDay(for: notification.createdAt)
            // 收到通知的日期意味着用户在前一段时间有活动产生了内容
            activeDays.insert(dayStart)
            notificationDays += 1
        }
        
        
        
        return max(activeDays.count, 1)
    }
    
    /// 计算综合评分：多维度表现的综合评分
    private func calculateComprehensiveScore() -> Int {
        let posts = PostViewModel.shared.posts
        let userPosts = posts.filter { $0.characterID == nil }
        
        // 计算各项指标
        let dialogueCount = calculateMaxDialogueWithSingleCharacter()
        let totalLikes = calculateTotalResonance()
        let activeDays = calculateActualActiveDays()
        let exploredDomains = calculateExploredCharacterDomains()
        let socialConnections = calculateTotalActiveCharacters()
        
        // 综合评分算法
        var score = 0
        
        // 1. 对话深度分数 (最高500分)
        score += min(dialogueCount * 2, 500)
        
        // 2. 社交影响力分数 (最高300分)
        score += min(totalLikes * 3, 300)
        
        // 3. 活跃度分数 (最高200分)
        score += min(activeDays * 10, 200)
        
        // 4. 探索广度分数 (最高150分)
        score += min(exploredDomains * 15, 150)
        
        // 5. 社交广度分数 (最高100分)
        score += min(socialConnections * 5, 100)
        
        // 6. 内容创作分数 (最高100分)
        score += min(userPosts.count * 10, 100)
        

        
        return score
    }
    
    /// 动态判定成就等级和目标进度
    private func determineAchievementLevel(
        progress: Int,
        bronzeThreshold: Int,
        silverThreshold: Int,
        goldThreshold: Int
    ) -> (level: AchievementLevel, targetProgress: Int, isUnlocked: Bool) {
        
        if progress >= goldThreshold {
            return (.gold, goldThreshold, true)
        } else if progress >= silverThreshold {
            return (.silver, goldThreshold, true) // 已达白银，显示下一级黄金目标
        } else if progress >= bronzeThreshold {
            return (.bronze, silverThreshold, true) // 已达青铜，显示下一级白银目标
        } else {
            return (.bronze, bronzeThreshold, false) // 未达青铜，显示青铜目标
        }
    }
    
    /// 计算深夜时段对话次数 (22:00-02:00)
    private func calculateNightTimeConversations(using providedContext: ModelContext? = nil) -> Int {
        // 必须使用提供的ModelContext，不能创建独立的ModelContext
        guard let modelContext = providedContext else {
            return 0
        }
        
        do {
            // 获取所有用户发送的消息
            let messageDescriptor = FetchDescriptor<Message>(
                predicate: #Predicate<Message> { message in
                    message.isFromUser
                }
            )
            let userMessages = try modelContext.fetch(messageDescriptor)
            
            // 统计深夜时段(22:00-02:00)的对话次数
            let nightConversations = userMessages.filter { message in
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: message.timestamp)
                // 深夜时段：22:00-23:59 和 00:00-02:59
                return (hour >= 22 && hour <= 23) || (hour >= 0 && hour <= 2)
            }
            

            
            return nightConversations.count
            
        } catch {
            return 0
        }
    }
    
    /// 计算晨光时段对话次数 (06:00-10:00)
    private func calculateMorningTimeConversations(using providedContext: ModelContext? = nil) -> Int {
        // 必须使用提供的ModelContext，不能创建独立的ModelContext
        guard let modelContext = providedContext else {
            return 0
        }
        
        do {
            // 获取所有用户发送的消息
            let messageDescriptor = FetchDescriptor<Message>(
                predicate: #Predicate<Message> { message in
                    message.isFromUser
                }
            )
            let userMessages = try modelContext.fetch(messageDescriptor)
            
            // 统计晨光时段(06:00-10:00)的对话次数
            let morningConversations = userMessages.filter { message in
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: message.timestamp)
                // 晨光时段：06:00-09:59
                return hour >= 6 && hour <= 9
            }
            

            
            return morningConversations.count
            
        } catch {
            return 0
        }
    }

} 