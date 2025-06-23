import Foundation
import Combine
import UIKit

/**
 * 角色个性特性
 * 定义角色的性格、表达方式等特性
 */
struct CharacterPersonality: Codable, Equatable {
    // 基础特性
    var tone: String                // 语调(例如：思考深入，富有哲理)
    var knowledgeAreas: [String]    // 知识领域
    var speechPatterns: [String]    // 常用表达方式
    
    // 个性化调整参数
    var directness: Float = 0.5     // 直接程度 (0: 含蓄 - 1: 直接)
    var formality: Float = 0.5      // 正式程度 (0: 随意 - 1: 正式)
    var emotionality: Float = 0.5   // 情感程度 (0: 理性 - 1: 感性)
    var verbosity: Float = 0.5      // 话语量 (0: 简短 - 1: 详细)
    var creativity: Float = 0.5     // 创造性 (0: 保守 - 1: 创新)
    
    // 表达偏好
    var expressionPreferences: [String: Bool] = [:]  // 表达偏好选项
    
    static func == (lhs: CharacterPersonality, rhs: CharacterPersonality) -> Bool {
        return lhs.tone == rhs.tone &&
               lhs.knowledgeAreas == rhs.knowledgeAreas &&
               lhs.speechPatterns == rhs.speechPatterns &&
               lhs.directness == rhs.directness &&
               lhs.formality == rhs.formality &&
               lhs.emotionality == rhs.emotionality &&
               lhs.verbosity == rhs.verbosity &&
               lhs.creativity == rhs.creativity &&
               lhs.expressionPreferences == rhs.expressionPreferences
    }
}

/**
 * 角色模板
 * 角色的基础模板信息
 */
struct CharacterTemplate: Codable {
    var id: String                  // 角色ID
    var name: String                // 角色名称
    var basePersonality: CharacterPersonality  // 基础性格特性
    var defaultAdjustments: [String: Float]    // 默认调整参数
    var availableExpressions: [String]         // 可用表达方式
}

/**
 * 角色个性化管理器
 * 负责管理角色预设模板和用户个性化调整
 */
class CharacterPersonalityManager {
    // 单例实例
    static let shared = CharacterPersonalityManager()
    
    // MARK: - 私有属性
    
    // 预设模板库
    private var templateLibrary: [String: CharacterTemplate] = [:]
    
    // 用户调整存储
    private var userAdjustments: [String: [String: Float]] = [:]
    
    // 用户表达偏好存储
    private var userExpressionPreferences: [String: [String: Bool]] = [:]
    
    // 取消令牌
    private var cancellables = Set<AnyCancellable>()
    
    // 数据存储键
    private let userAdjustmentsKey = "com.chongyu.characterAdjustments"
    private let userExpressionPreferencesKey = "com.chongyu.expressionPreferences"
    
    // MARK: - 初始化
    
    private init() {
        loadTemplateLibrary()
        loadUserPreferences()
    }
    
    // MARK: - 公共方法
    
    /**
     * 获取角色预设模板
     * @param characterId 角色ID
     * @return 角色模板
     */
    func getTemplate(for characterId: String) -> CharacterTemplate? {
        return templateLibrary[characterId]
    }
    
    /**
     * 获取所有可用模板ID
     * @return 模板ID数组
     */
    func getAllTemplateIds() -> [String] {
        return Array(templateLibrary.keys)
    }
    
    /**
     * 获取角色个性化特性
     * @param characterId 角色ID
     * @return 角色个性化特性
     */
    func getPersonality(for characterId: String) -> CharacterPersonality? {
        guard let template = templateLibrary[characterId] else {
            print("⚠️ CharacterPersonalityManager: 未找到角色模板 - \(characterId)")
            return nil
        }
        
        // 获取基础模板
        var personality = template.basePersonality
        
        // 应用用户调整
        if let adjustments = userAdjustments[characterId] {
            personality = applyUserAdjustments(personality, adjustments)
        }
        
        // 应用表达偏好
        if let preferences = userExpressionPreferences[characterId] {
            personality.expressionPreferences = preferences
        }
        
        return personality
    }
    
    /**
     * 更新角色特性参数
     * @param characterId 角色ID
     * @param adjustments 调整参数
     */
    func updatePersonalityAdjustments(for characterId: String, adjustments: [String: Float]) {
        // 确保角色模板存在
        guard templateLibrary[characterId] != nil else {
            print("⚠️ CharacterPersonalityManager: 无法更新不存在的角色 - \(characterId)")
            return
        }
        
        // 更新调整参数
        userAdjustments[characterId] = adjustments
        
        // 保存到持久化存储
        saveUserPreferences()
        
        print("✅ CharacterPersonalityManager: 更新了角色个性参数 - \(characterId)")
    }
    
    /**
     * 更新表达偏好
     * @param characterId 角色ID
     * @param preferences 表达偏好
     */
    func updateExpressionPreferences(for characterId: String, preferences: [String: Bool]) {
        // 确保角色模板存在
        guard templateLibrary[characterId] != nil else {
            print("⚠️ CharacterPersonalityManager: 无法更新不存在的角色表达偏好 - \(characterId)")
            return
        }
        
        // 更新表达偏好
        userExpressionPreferences[characterId] = preferences
        
        // 保存到持久化存储
        saveUserPreferences()
        
        print("✅ CharacterPersonalityManager: 更新了角色表达偏好 - \(characterId)")
    }
    
    /**
     * 重置角色个性化设置为默认
     * @param characterId 角色ID
     */
    func resetToDefault(characterId: String) {
        guard let template = templateLibrary[characterId] else {
            print("⚠️ CharacterPersonalityManager: 无法重置不存在的角色 - \(characterId)")
            return
        }
        
        // 重置为默认调整
        userAdjustments[characterId] = template.defaultAdjustments
        
        // 重置表达偏好
        var defaultPreferences: [String: Bool] = [:]
        for expression in template.availableExpressions {
            defaultPreferences[expression] = true
        }
        userExpressionPreferences[characterId] = defaultPreferences
        
        // 保存到持久化存储
        saveUserPreferences()
        
        print("✅ CharacterPersonalityManager: 重置角色个性设置 - \(characterId)")
    }
    
    /**
     * 生成增强提示词
     * 结合角色基础模板和用户调整，生成用于AI的提示词
     * @param characterId 角色ID
     * @param userComment 用户评论
     * @param postContent 帖子内容
     * @return 增强提示词
     */
    func generateEnhancedPrompt(
        characterId: String,
        userComment: String,
        postContent: String
    ) -> String? {
        guard let personality = getPersonality(for: characterId),
              let template = templateLibrary[characterId] else {
            return nil
        }
        
        // 构建基础提示词
        var prompt = """
        你是\(template.name)，正在回复一条评论。
        
        原评论："\(userComment)"
        原帖内容："\(String(postContent.prefix(100)))..."
        
        【角色特性】
        基本风格：\(personality.tone)
        知识领域：\(personality.knowledgeAreas.joined(separator: "、"))
        """
        
        // 添加个性化调整说明
        prompt += "\n\n【个性化调整】"
        prompt += "\n表达方式："
        prompt += personality.directness < 0.4 ? "含蓄，倾向于间接表达" : (personality.directness > 0.7 ? "直接，喜欢开门见山" : "适度直接")
        prompt += "\n语言风格："
        prompt += personality.formality < 0.4 ? "随意，口语化" : (personality.formality > 0.7 ? "正式，文雅" : "中等正式度")
        prompt += "\n情感表达："
        prompt += personality.emotionality < 0.4 ? "理性，克制情感" : (personality.emotionality > 0.7 ? "感性，情感丰富" : "情感适中")
        prompt += "\n回复详细度："
        prompt += personality.verbosity < 0.4 ? "简短，点到为止" : (personality.verbosity > 0.7 ? "详细，乐于解释" : "中等详细度")
        prompt += "\n创意程度："
        prompt += personality.creativity < 0.4 ? "保守，遵循传统" : (personality.creativity > 0.7 ? "创新，独特视角" : "中等创意度")
        
        // 添加特定表达偏好
        if !personality.expressionPreferences.isEmpty {
            prompt += "\n\n【表达偏好】"
            for (expression, isEnabled) in personality.expressionPreferences where isEnabled {
                prompt += "\n- " + expression
            }
        }
        
        // 添加示例表达方式
        if !personality.speechPatterns.isEmpty {
            prompt += "\n\n【参考表达方式】"
            for pattern in personality.speechPatterns.prefix(3) {
                prompt += "\n- " + pattern
            }
        }
        
        // 通用指导
        prompt += """
        
        请按照以上角色特性和个性化调整回复评论。注意：
        1. 保持自然，像真人对话一样
        2. 不要用固定句式开头，如"作为[角色]"
        3. 不要重复引用对方内容
        4. 回复长度控制在100字以内，简短有力
        """
        
        return prompt
    }
    
    // MARK: - 私有方法
    
    /**
     * 加载预设模板库
     */
    private func loadTemplateLibrary() {
        // 模拟预设模板数据 - 实际应用中可能从配置文件或API加载
        let templates: [CharacterTemplate] = [
            // 李白模板
            CharacterTemplate(
                id: "libai",
                name: "李白",
                basePersonality: CharacterPersonality(
                    tone: "诗意飘逸，豪放不羁",
                    knowledgeAreas: ["诗歌", "文学", "自然", "酒文化", "道家思想"],
                    speechPatterns: [
                        "人生得意须尽欢",
                        "举杯邀明月",
                        "大道如青天",
                        "此情此景",
                        "人生如梦"
                    ]
                ),
                defaultAdjustments: [
                    "directness": 0.7,
                    "formality": 0.4,
                    "emotionality": 0.8,
                    "verbosity": 0.6,
                    "creativity": 0.9
                ],
                availableExpressions: [
                    "使用诗句",
                    "提及酒",
                    "引用古籍",
                    "描述自然景象",
                    "抒发豪情"
                ]
            ),
            
            // 爱因斯坦模板
            CharacterTemplate(
                id: "einstein",
                name: "爱因斯坦",
                basePersonality: CharacterPersonality(
                    tone: "思考深入，富有哲理，语言通俗易懂",
                    knowledgeAreas: ["物理学", "相对论", "宇宙", "科学哲学", "和平主义"],
                    speechPatterns: [
                        "我常思考的问题是",
                        "从相对论的角度看",
                        "这让我想起一个思想实验",
                        "科学的本质在于质疑",
                        "简单来说"
                    ]
                ),
                defaultAdjustments: [
                    "directness": 0.6,
                    "formality": 0.5,
                    "emotionality": 0.4,
                    "verbosity": 0.7,
                    "creativity": 0.8
                ],
                availableExpressions: [
                    "使用比喻",
                    "提出思想实验",
                    "科学观点",
                    "哲学思考",
                    "引用自己的研究"
                ]
            ),
            
            // 莎士比亚模板
            CharacterTemplate(
                id: "shakespeare",
                name: "莎士比亚",
                basePersonality: CharacterPersonality(
                    tone: "语言华丽，富有诗意，善用比喻",
                    knowledgeAreas: ["文学", "戏剧", "诗歌", "人性", "爱情"],
                    speechPatterns: [
                        "正如我在剧作中所写",
                        "这让我想起哈姆雷特的困境",
                        "人生如戏，我们都是演员",
                        "爱与恨常常交织",
                        "用莎翁的话来说"
                    ]
                ),
                defaultAdjustments: [
                    "directness": 0.4,
                    "formality": 0.8,
                    "emotionality": 0.7,
                    "verbosity": 0.8,
                    "creativity": 0.7
                ],
                availableExpressions: [
                    "使用修辞手法",
                    "引用戏剧台词",
                    "双关语",
                    "诗意描述",
                    "戏剧化表达"
                ]
            ),
            
            // 孔子模板
            CharacterTemplate(
                id: "confucius",
                name: "孔子",
                basePersonality: CharacterPersonality(
                    tone: "儒雅谦逊，言简意赅，富含哲理",
                    knowledgeAreas: ["伦理", "教育", "政治", "礼制", "人际关系"],
                    speechPatterns: [
                        "学而时习之",
                        "吾日三省吾身",
                        "君子和而不同",
                        "中庸之道",
                        "仁者爱人"
                    ]
                ),
                defaultAdjustments: [
                    "directness": 0.5,
                    "formality": 0.9,
                    "emotionality": 0.3,
                    "verbosity": 0.4,
                    "creativity": 0.5
                ],
                availableExpressions: [
                    "引用论语",
                    "使用类比",
                    "伦理观点",
                    "教育思想",
                    "礼制观念"
                ]
            ),
            
            // 达芬奇模板
            CharacterTemplate(
                id: "davinci",
                name: "达芬奇",
                basePersonality: CharacterPersonality(
                    tone: "观察细致，思维跨界，注重细节",
                    knowledgeAreas: ["艺术", "解剖学", "工程学", "建筑", "自然科学"],
                    speechPatterns: [
                        "从艺术与科学的交汇处",
                        "观察自然会发现",
                        "细节决定成败",
                        "完美在于平衡",
                        "如同我设计的机械装置"
                    ]
                ),
                defaultAdjustments: [
                    "directness": 0.5,
                    "formality": 0.6,
                    "emotionality": 0.5,
                    "verbosity": 0.7,
                    "creativity": 0.9
                ],
                availableExpressions: [
                    "多学科视角",
                    "提及艺术原理",
                    "观察细节",
                    "科学思考",
                    "提及设计"
                ]
            )
        ]
        
        // 将模板数组转换为字典
        for template in templates {
            templateLibrary[template.id] = template
        }
        
        print("✅ CharacterPersonalityManager: 加载了\(templates.count)个角色模板")
    }
    
    /**
     * 应用用户调整
     * @param basePersonality 基础性格
     * @param adjustments 调整参数
     * @return 调整后的性格
     */
    private func applyUserAdjustments(_ basePersonality: CharacterPersonality, _ adjustments: [String: Float]) -> CharacterPersonality {
        var personality = basePersonality
        
        // 应用各项调整
        if let directness = adjustments["directness"] {
            personality.directness = directness
        }
        
        if let formality = adjustments["formality"] {
            personality.formality = formality
        }
        
        if let emotionality = adjustments["emotionality"] {
            personality.emotionality = emotionality
        }
        
        if let verbosity = adjustments["verbosity"] {
            personality.verbosity = verbosity
        }
        
        if let creativity = adjustments["creativity"] {
            personality.creativity = creativity
        }
        
        return personality
    }
    
    /**
     * 加载用户偏好
     */
    private func loadUserPreferences() {
        // 从UserDefaults加载用户调整
        if let savedAdjustments = UserDefaults.standard.data(forKey: userAdjustmentsKey) {
            do {
                userAdjustments = try JSONDecoder().decode([String: [String: Float]].self, from: savedAdjustments)
                print("✅ CharacterPersonalityManager: 加载用户调整成功")
            } catch {
                print("⚠️ CharacterPersonalityManager: 加载用户调整失败 - \(error.localizedDescription)")
            }
        }
        
        // 从UserDefaults加载表达偏好
        if let savedPreferences = UserDefaults.standard.data(forKey: userExpressionPreferencesKey) {
            do {
                userExpressionPreferences = try JSONDecoder().decode([String: [String: Bool]].self, from: savedPreferences)
                print("✅ CharacterPersonalityManager: 加载表达偏好成功")
            } catch {
                print("⚠️ CharacterPersonalityManager: 加载表达偏好失败 - \(error.localizedDescription)")
            }
        }
        
        // 初始化缺失的默认值
        for (id, template) in templateLibrary {
            // 如果没有用户调整，使用默认调整
            if userAdjustments[id] == nil {
                userAdjustments[id] = template.defaultAdjustments
            }
            
            // 如果没有表达偏好，使用默认全开启
            if userExpressionPreferences[id] == nil {
                var defaultPreferences: [String: Bool] = [:]
                for expression in template.availableExpressions {
                    defaultPreferences[expression] = true
                }
                userExpressionPreferences[id] = defaultPreferences
            }
        }
    }
    
    /**
     * 保存用户偏好
     */
    private func saveUserPreferences() {
        // 保存用户调整
        do {
            let encodedAdjustments = try JSONEncoder().encode(userAdjustments)
            UserDefaults.standard.set(encodedAdjustments, forKey: userAdjustmentsKey)
        } catch {
            print("⚠️ CharacterPersonalityManager: 保存用户调整失败 - \(error.localizedDescription)")
        }
        
        // 保存表达偏好
        do {
            let encodedPreferences = try JSONEncoder().encode(userExpressionPreferences)
            UserDefaults.standard.set(encodedPreferences, forKey: userExpressionPreferencesKey)
        } catch {
            print("⚠️ CharacterPersonalityManager: 保存表达偏好失败 - \(error.localizedDescription)")
        }
    }
} 