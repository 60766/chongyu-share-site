import Foundation
import SwiftData

/**
 * 角色模型类，表示应用中的历史人物或虚构角色
 */
@Model
final class Character: Identifiable {
    /// 角色ID
    var id: String
    /// 角色名称
    var name: String
    /// 角色介绍
    var introduction: String
    /// 角色所属领域（科学家、艺术家、哲学家等）
    var field: String
    /// 角色出生年份
    var birthYear: String
    /// 角色逝世年份（如果适用）
    var deathYear: String?
    /// 角色头像URL
    var avatarUrl: String
    /// 角色时代标签
    var eraTag: String?
    /// 角色成就列表
    var achievements: [String]
    /// 角色主要作品
    var mainWorks: [String]
    /// 角色关键思想
    var keyThoughts: [String]
    /// 角色粉丝数量
    var followerCount: Int
    /// 角色互动量
    var interactionCount: Int
    /// 角色评分
    var rating: Double
    /// 创建时间
    var createdAt: Date
    
    /**
     * 初始化一个角色实例
     * @param id - 角色唯一标识
     * @param name - 角色名称
     * @param introduction - 角色简介
     * @param field - 角色领域
     * @param birthYear - 出生年份
     * @param deathYear - 逝世年份（可选）
     * @param avatarUrl - 头像URL
     * @param eraTag - 时代标签
     * @param achievements - 成就列表
     * @param mainWorks - 主要作品
     * @param keyThoughts - 关键思想
     * @param followerCount - 粉丝数量
     * @param interactionCount - 互动量
     * @param rating - 评分
     * @param createdAt - 创建时间
     */
    init(
        id: String = UUID().uuidString,
        name: String,
        introduction: String,
        field: String,
        birthYear: String,
        deathYear: String? = nil,
        avatarUrl: String,
        eraTag: String? = nil,
        achievements: [String] = [],
        mainWorks: [String] = [],
        keyThoughts: [String] = [],
        followerCount: Int = 0,
        interactionCount: Int = 0,
        rating: Double = 4.5,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.introduction = introduction
        self.field = field
        self.birthYear = birthYear
        self.deathYear = deathYear
        self.avatarUrl = avatarUrl
        self.eraTag = eraTag
        self.achievements = achievements
        self.mainWorks = mainWorks
        self.keyThoughts = keyThoughts
        self.followerCount = followerCount
        self.interactionCount = interactionCount
        self.rating = rating
        self.createdAt = createdAt
    }
}

/**
 * Character扩展 - 角色类型识别
 */
extension Character {
    /**
     * 角色类型枚举
     */
    enum CharacterType {
        case historical   // 历史人物
        case anime        // 动漫角色
        case fictional    // 虚构人物
        case animal       // 动物角色
        case futuristic   // 未来人
        case ai           // AI角色
        case custom       // 自定义角色
        case unknown      // 未知类型
    }
    
    /**
     * 获取角色类型
     * @return CharacterType - 角色类型
     */
    var characterType: CharacterType {
        // 基于eraTag判断
        if let tag = eraTag?.lowercased() {
            if tag.contains("动漫") || tag.contains("anime") {
                return .anime
            } else if tag.contains("未来") || tag.contains("future") {
                return .futuristic
            } else if tag == "现代" && (field.contains("AI") || field.contains("人工智能")) {
                return .ai
            }
        }
        
        // 基于field判断
        if field.lowercased().contains("宠物") || field.lowercased().contains("动物") {
            return .animal
        }
        
        // 基于名称和介绍判断
        let nameAndIntro = (name + introduction).lowercased()
        if nameAndIntro.contains("动漫") || 
           nameAndIntro.contains("anime") || 
           nameAndIntro.contains("漫画") {
            return .anime
        } else if nameAndIntro.contains("虚构") || 
                 nameAndIntro.contains("fictional") || 
                 nameAndIntro.contains("fiction") {
            return .fictional
        } else if nameAndIntro.contains("未来") || 
                 nameAndIntro.contains("future") {
            return .futuristic
        } else if nameAndIntro.contains("ai") || 
                 nameAndIntro.contains("人工智能") || 
                 nameAndIntro.contains("artificial intelligence") {
            return .ai
        } else if nameAndIntro.contains("自定义") || 
                 nameAndIntro.contains("custom") {
            return .custom
        }
        
        // 基于出生年份判断未来人
        if let year = Int(birthYear.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)) {
            if year > 2023 {
                return .futuristic
            }
        }
        
        // 如果上述条件都不满足，默认判断为历史人物
        if avatarUrl.contains("custom_") {
            return .custom
        } else {
            return .historical
        }
    }
    
    /**
     * 判断是否为历史人物
     * @return Bool - 是否为历史人物
     */
    var isHistorical: Bool {
        return characterType == .historical
    }
    
    /**
     * 判断是否为虚构角色（包括动漫、虚构人物、动物角色、未来人等）
     * @return Bool - 是否为虚构角色
     */
    var isVirtual: Bool {
        return characterType != .historical
    }
    
    /**
     * 获取角色类型的中文描述
     * @return String - 类型描述
     */
    var characterTypeDescription: String {
        switch characterType {
        case .historical:
            return "历史人物"
        case .anime:
            return "动漫角色"
        case .fictional:
            return "虚构人物"
        case .animal:
            return "动物角色"
        case .futuristic:
            return "未来人"
        case .ai:
            return "AI角色"
        case .custom:
            return "自定义角色"
        case .unknown:
            return "未知类型"
        }
    }
} 