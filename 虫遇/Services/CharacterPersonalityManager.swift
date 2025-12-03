import Foundation
import Combine
import UIKit

/**
 * 角色个性特性
 * 只存储用户的个性化调整参数
 */
struct CharacterPersonality: Codable, Equatable {
    // 个性化调整参数 - 只在用户调整时使用
    var intimacy: Float = 0.5       // 亲密度 (0: 陌生人模式 - 1: 老朋友模式)
    var engagementDepth: Float = 0.5 // 互动深度 (0: 浅层交流 - 1: 深度探索)
    var emotionality: Float = 0.5   // 情感表达 (0: 理性克制 - 1: 感性丰富)
    var responseStyle: Float = 0.5  // 回应方式 (0: 直接建议 - 1: 启发引导)
    var communicationPace: Float = 0.5 // 交流节奏 (0: 精炼简洁 - 1: 详细展开)
    
    static func == (lhs: CharacterPersonality, rhs: CharacterPersonality) -> Bool {
        return lhs.intimacy == rhs.intimacy &&
               lhs.engagementDepth == rhs.engagementDepth &&
               lhs.emotionality == rhs.emotionality &&
               lhs.responseStyle == rhs.responseStyle &&
               lhs.communicationPace == rhs.communicationPace
    }
}

/**
 * 用户调整的个性化参数 - 只存储用户实际调整的参数
 */
struct UserPersonalityAdjustments: Codable {
    var intimacy: Float?
    var engagementDepth: Float?
    var emotionality: Float?
    var responseStyle: Float?
    var communicationPace: Float?
    
    // 检查是否有任何调整
    var hasAnyAdjustments: Bool {
        return intimacy != nil || engagementDepth != nil || emotionality != nil || 
               responseStyle != nil || communicationPace != nil
    }
    
    // 转换为完整的CharacterPersonality（未调整的使用默认值0.5）
    func toCharacterPersonality() -> CharacterPersonality {
        return CharacterPersonality(
            intimacy: intimacy ?? 0.5,
            engagementDepth: engagementDepth ?? 0.5,
            emotionality: emotionality ?? 0.5,
            responseStyle: responseStyle ?? 0.5,
            communicationPace: communicationPace ?? 0.5
        )
    }
}

/**
 * 角色个性化管理器
 * 简洁版本：只管理用户的个性化调整，无需预设模板
 */
class CharacterPersonalityManager {
    // 单例实例
    static let shared = CharacterPersonalityManager()
    
    // MARK: - 私有属性
    
    // 用户调整存储 - 只存储用户实际调整过的参数
    private var userAdjustments: [String: UserPersonalityAdjustments] = [:]
    
    // 数据存储键
    private let userAdjustmentsKey = "com.chongyu.characterPersonalityAdjustments"
    
    // MARK: - 初始化
    
    private init() {
        loadUserAdjustments()
    }
    
    // MARK: - 公共方法
    
    /**
     * 检查用户是否对该角色进行了个性化调整
     * @param characterId 角色ID
     * @return 是否有调整
     */
    func hasUserAdjustments(for characterId: String) -> Bool {
        return userAdjustments[characterId]?.hasAnyAdjustments ?? false
    }
    
    /**
     * 获取用户的个性化调整
     * @param characterId 角色ID
     * @return 个性化调整，如果用户没有调整则返回nil
     */
    func getUserAdjustments(for characterId: String) -> CharacterPersonality? {
        guard let adjustments = userAdjustments[characterId], adjustments.hasAnyAdjustments else {
            return nil
        }
        return adjustments.toCharacterPersonality()
    }
    
    /**
     * 更新角色的个性化调整 - 智能保存，只保存用户调整的参数
     * @param characterId 角色ID
     * @param personality 个性化参数
     */
    func updatePersonality(for characterId: String, personality: CharacterPersonality) {
        // 构建只包含非默认值的调整
        var adjustments = UserPersonalityAdjustments()
        
        // 只存储非默认值(0.5)的参数
        if personality.intimacy != 0.5 {
            adjustments.intimacy = personality.intimacy
        }
        if personality.engagementDepth != 0.5 {
            adjustments.engagementDepth = personality.engagementDepth
        }
        if personality.emotionality != 0.5 {
            adjustments.emotionality = personality.emotionality
        }
        if personality.responseStyle != 0.5 {
            adjustments.responseStyle = personality.responseStyle
        }
        if personality.communicationPace != 0.5 {
            adjustments.communicationPace = personality.communicationPace
        }
        
        // 如果没有任何调整，删除该角色的记录
        if !adjustments.hasAnyAdjustments {
            userAdjustments.removeValue(forKey: characterId)
            #if DEBUG
            print("✅ CharacterPersonalityManager: 重置了角色个性参数 - \(characterId)")
            #endif
        } else {
            userAdjustments[characterId] = adjustments
            let adjustedParams = [
                adjustments.intimacy != nil ? "intimacy" : nil,
                adjustments.engagementDepth != nil ? "engagementDepth" : nil,
                adjustments.emotionality != nil ? "emotionality" : nil,
                adjustments.responseStyle != nil ? "responseStyle" : nil,
                adjustments.communicationPace != nil ? "communicationPace" : nil
            ].compactMap { $0 }
            #if DEBUG
            print("✅ CharacterPersonalityManager: 更新了角色个性参数 - \(characterId), 调整的参数: \(adjustedParams)")
            #endif
        }
        
        saveUserAdjustments()
    }
    
    /**
     * 重置角色的个性化调整
     * @param characterId 角色ID
     */
    func resetPersonality(for characterId: String) {
        userAdjustments.removeValue(forKey: characterId)
        saveUserAdjustments()
        #if DEBUG
        print("✅ CharacterPersonalityManager: 重置了角色个性参数 - \(characterId)")
        #endif
    }
    
    /**
     * 生成个性化提示词片段
     * @param characterId 角色ID
     * @return 提示词片段，如果用户没有调整则返回空字符串
     */
    func generatePersonalityPrompt(for characterId: String) -> String {
        guard let adjustments = userAdjustments[characterId], adjustments.hasAnyAdjustments else {
            // 用户没有调整，返回空字符串
            return ""
        }
        
        let personality = adjustments.toCharacterPersonality()
        var prompt = "\n\n【个性化调整】"
        
        // 只为用户实际调整的参数生成提示词
        if adjustments.intimacy != nil {
            prompt += "\n亲密度："
            if personality.intimacy < 0.2 {
                prompt += "陌生人模式，正式称呼，保持适当距离，客观回应"
            } else if personality.intimacy < 0.4 {
                prompt += "初识模式，礼貌友好，保持一定边界感"
            } else if personality.intimacy < 0.6 {
                prompt += "熟人模式，自然交流，适度亲近"
            } else if personality.intimacy < 0.8 {
                prompt += "朋友模式，亲切随和，分享个人想法"
            } else {
                prompt += "密友模式，可以使用昵称，关心对方日常，像老朋友般温暖"
            }
        }
        
        if adjustments.engagementDepth != nil {
            prompt += "\n互动深度："
            if personality.engagementDepth < 0.2 {
                prompt += "表面交流，轻松聊天，不深入探讨"
            } else if personality.engagementDepth < 0.4 {
                prompt += "浅层互动，关注话题本身，少量延伸"
            } else if personality.engagementDepth < 0.6 {
                prompt += "适度深入，结合话题进行一定思考"
            } else if personality.engagementDepth < 0.8 {
                prompt += "深入探索，追问背后原因，引导思考"
            } else {
                prompt += "深度挖掘，探索内心动机，帮助自我认知和成长"
            }
        }
        
        if adjustments.emotionality != nil {
            prompt += "\n情感表达："
            if personality.emotionality < 0.2 {
                prompt += "极度理性，纯粹客观分析，避免情感色彩"
            } else if personality.emotionality < 0.4 {
                prompt += "偏向理性，以逻辑为主，适度体现理解"
            } else if personality.emotionality < 0.6 {
                prompt += "理性与感性平衡，既有逻辑也有温度"
            } else if personality.emotionality < 0.8 {
                prompt += "偏向感性，情感丰富，用心感受和回应"
            } else {
                prompt += "极度感性，情感充沛，用心感受对方情绪"
            }
        }
        
        if adjustments.responseStyle != nil {
            prompt += "\n回应方式："
            if personality.responseStyle < 0.2 {
                prompt += "极其直接，给出明确答案和解决方案"
            } else if personality.responseStyle < 0.4 {
                prompt += "偏向直接，主要提供建议，少量引导"
            } else if personality.responseStyle < 0.6 {
                prompt += "平衡建议和启发，既给方向也引导思考"
            } else if personality.responseStyle < 0.8 {
                prompt += "偏向启发，主要引导思考，适度给建议"
            } else {
                prompt += "纯启发式，通过提问引导对方自己找到答案"
            }
        }
        
        if adjustments.communicationPace != nil {
            prompt += "\n交流节奏："
            if personality.communicationPace < 0.2 {
                prompt += "极其简洁，点到为止，言简意赅"
            } else if personality.communicationPace < 0.4 {
                prompt += "偏向简洁，主要观点明确，少量展开"
            } else if personality.communicationPace < 0.6 {
                prompt += "适度详细，既不简陋也不冗长"
            } else if personality.communicationPace < 0.8 {
                prompt += "详细阐述，充分展开想法，提供丰富信息"
            } else {
                prompt += "详尽深入，全面展开，提供完整的思考过程"
            }
        }
        
        return prompt
    }
    
    // MARK: - 私有方法
    
    /**
     * 检查是否为默认个性设置（全部0.5）
     */
    private func isDefaultPersonality(_ personality: CharacterPersonality) -> Bool {
        return personality.intimacy == 0.5 &&
               personality.engagementDepth == 0.5 &&
               personality.emotionality == 0.5 &&
               personality.responseStyle == 0.5 &&
               personality.communicationPace == 0.5
    }
    
    /**
     * 加载用户调整
     */
    private func loadUserAdjustments() {
        if let savedData = UserDefaults.standard.data(forKey: userAdjustmentsKey) {
            do {
                userAdjustments = try JSONDecoder().decode([String: UserPersonalityAdjustments].self, from: savedData)
                let totalAdjustments = userAdjustments.values.reduce(0) { count, adj in
                    count + [adj.intimacy, adj.engagementDepth, adj.emotionality, adj.responseStyle, adj.communicationPace].compactMap { $0 }.count
                }
                #if DEBUG
                print("✅ CharacterPersonalityManager: 加载用户调整成功，共\(userAdjustments.count)个角色，\(totalAdjustments)个参数调整")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ CharacterPersonalityManager: 加载用户调整失败，尝试加载旧格式 - \(error.localizedDescription)")
                #endif
                // 尝试加载旧格式并转换
                if let oldAdjustments = try? JSONDecoder().decode([String: CharacterPersonality].self, from: savedData) {
                    userAdjustments = convertOldFormat(oldAdjustments)
                    #if DEBUG
                    print("✅ CharacterPersonalityManager: 成功转换旧格式数据，共\(userAdjustments.count)个角色")
                    #endif
                    saveUserAdjustments() // 保存转换后的新格式
                }
            }
        } else {
            #if DEBUG
            print("📝 CharacterPersonalityManager: 首次启动，无用户调整数据")
            #endif
        }
    }
    
    /**
     * 转换旧格式数据
     */
    private func convertOldFormat(_ oldAdjustments: [String: CharacterPersonality]) -> [String: UserPersonalityAdjustments] {
        var newAdjustments: [String: UserPersonalityAdjustments] = [:]
        
        for (characterId, personality) in oldAdjustments {
            var adjustments = UserPersonalityAdjustments()
            
            // 只保存非默认值的参数
            if personality.intimacy != 0.5 { adjustments.intimacy = personality.intimacy }
            if personality.engagementDepth != 0.5 { adjustments.engagementDepth = personality.engagementDepth }
            if personality.emotionality != 0.5 { adjustments.emotionality = personality.emotionality }
            if personality.responseStyle != 0.5 { adjustments.responseStyle = personality.responseStyle }
            if personality.communicationPace != 0.5 { adjustments.communicationPace = personality.communicationPace }
            
            if adjustments.hasAnyAdjustments {
                newAdjustments[characterId] = adjustments
            }
        }
        
        return newAdjustments
    }
    
    /**
     * 保存用户调整
     */
    private func saveUserAdjustments() {
        do {
            let encodedData = try JSONEncoder().encode(userAdjustments)
            UserDefaults.standard.set(encodedData, forKey: userAdjustmentsKey)
            let totalAdjustments = userAdjustments.values.reduce(0) { count, adj in
                count + [adj.intimacy, adj.engagementDepth, adj.emotionality, adj.responseStyle, adj.communicationPace].compactMap { $0 }.count
            }
            #if DEBUG
            print("💾 CharacterPersonalityManager: 保存用户调整成功，共\(userAdjustments.count)个角色，\(totalAdjustments)个参数调整")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ CharacterPersonalityManager: 保存用户调整失败 - \(error.localizedDescription)")
            #endif
        }
    }
} 