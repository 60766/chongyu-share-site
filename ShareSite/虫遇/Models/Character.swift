import Foundation
import SwiftData

/**
 * Character角色模型
 * 表示角色信息，包括历史人物、虚构角色等
 */
@Model
final class Character: Identifiable {
    /// 角色ID
    var id: String
    /// 角色名称
    var name: String
    /// 角色简介
    var introduction: String
    /// 领域（如哲学家、科学家等）
    var field: String
    /// 出生年份
    var birthYear: String
    /// 逝世年份
    var deathYear: String?
    /// 头像URL
    var avatarUrl: String
    /// 时代标签
    var eraTag: String?
    /// 主要成就
    var achievements: [String]
    /// 主要作品
    var mainWorks: [String]
    /// 核心思想
    var keyThoughts: [String]
    /// 粉丝数
    var followerCount: Int
    /// 互动次数
    var interactionCount: Int
    /// 角色评分
    var rating: Double
    /// 创建时间
    var createdAt: Date
    /// 是否被关注
    var isFavorited: Bool = false
    
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
     * @param isFavorited - 是否被关注
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
        createdAt: Date = Date(),
        isFavorited: Bool = false
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
        self.isFavorited = isFavorited
    }
}

/**
 * UI角色模型结构体
 * 用于视图层显示角色信息，避免直接在视图中使用SwiftData模型
 */
struct UICharacter: Identifiable {
    /// 角色ID
    var id: String
    /// 角色名称
    var name: String
    /// 角色简介
    var introduction: String
    /// 领域（如哲学家、科学家等）
    var field: String
    /// 出生年份
    var birthYear: String
    /// 逝世年份
    var deathYear: String?
    /// 头像URL
    var avatarUrl: String
    /// 时代标签
    var eraTag: String?
    /// 主要成就
    var achievements: [String]
    /// 主要作品
    var mainWorks: [String]
    /// 核心思想
    var keyThoughts: [String]
    /// 粉丝数
    var followerCount: Int
    /// 互动次数
    var interactionCount: Int
    /// 角色评分
    var rating: Double
    
    /**
     * 初始化一个UI角色实例
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
        rating: Double = 4.5
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
    }
    
    /**
     * 从SwiftData模型转换为UI模型
     * @param character - SwiftData角色模型
     */
    init(from character: Character) {
        self.id = character.id
        self.name = character.name
        self.introduction = character.introduction
        self.field = character.field
        self.birthYear = character.birthYear
        self.deathYear = character.deathYear
        self.avatarUrl = character.avatarUrl
        self.eraTag = character.eraTag
        self.achievements = character.achievements
        self.mainWorks = character.mainWorks
        self.keyThoughts = character.keyThoughts
        self.followerCount = character.followerCount
        self.interactionCount = character.interactionCount
        self.rating = character.rating
    }
    
    /**
     * 从CharacterModel转换为UICharacter
     * @param model - CharacterModel模型
     */
    init(from model: CharacterModel) {
        self.id = model.id
        self.name = model.name
        self.introduction = model.bio
        self.field = model.profession
        self.birthYear = model.era
        self.deathYear = nil
        self.avatarUrl = model.avatar
        self.eraTag = model.era
        self.achievements = []
        self.mainWorks = []
        self.keyThoughts = []
        self.followerCount = 0
        self.interactionCount = 0
        self.rating = 4.5
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
            return .anime  // 虚构角色归类为动漫角色
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

/**
 * UICharacter扩展 - 角色类型识别
 */
extension UICharacter {
    /**
     * 角色类型枚举
     */
    enum CharacterType {
        case historical   // 历史人物
        case anime        // 动漫角色
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
            return .anime  // 虚构角色归类为动漫角色
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