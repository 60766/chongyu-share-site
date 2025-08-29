import Foundation
import Combine
import UIKit

/**
 * 角色数据管理器
 * 负责加载、缓存和提供角色数据
 * 遵循第一性原理：直接使用角色ID，不使用别名映射
 */
class CharacterDataManager {
    // 单例实例
    static let shared = CharacterDataManager()
    
    // 缓存的角色数据
    private var characterData: [String: [String: Any]] = [:]
    
    // 初始化方法
    private init() {
        loadCharacterData()
    }
    
    /**
     * 加载角色数据
     */
    private func loadCharacterData() {
        // 从characters.json加载数据
        guard let url = Bundle.main.url(forResource: "characters", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("⚠️ 无法加载characters.json文件")
            return
        }
        
        // 解析JSON数据
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let characters = json["characters"] as? [[String: Any]] {
                
                // 构建以ID为键的字典
                for character in characters {
                    if let id = character["id"] as? String {
                        characterData[id.lowercased()] = character
                        
                        // 记录角色信息用于调试
                        if let name = character["name"] as? String,
                           let avatar = character["avatarName"] as? String {
                            print("📋 加载角色: \(id) -> 名称: \(name), 头像: \(avatar)")
                        }
                    }
                }
                
                print("✅ 成功加载角色数据，共 \(characterData.count) 个角色")
                
                // 检查常用ID是否存在
                let importantIds = ["einstein", "shakespeare", "sunwukong", "kongzi", "davinci"]
                for id in importantIds {
                    if characterData[id] != nil {
                        print("✓ 角色存在: \(id)")
                    } else {
                        print("⚠️ 角色不存在: \(id)")
                    }
                }
            }
        } catch {
            print("⚠️ 解析characters.json出错: \(error.localizedDescription)")
        }
    }
    
    /**
     * 获取角色属性
     * @param id 角色ID
     * @param attribute 属性名
     * @return 属性值
     */
    func getAttribute(id: String, attribute: String) -> String? {
        let lowercaseId = id.lowercased()
        
        // 检查是否有缓存数据
        if characterData.isEmpty {
            loadCharacterData()
        }
        
        // 查找角色数据
        var character: [String: Any]?
        
        // 直接查找
        character = characterData[lowercaseId]
        
        // 获取属性值
        if let value = character?[attribute] as? String {
            return value
        }
        
        print("⚠️ 无法获取角色 \(id) 的 \(attribute) 属性")
        return nil
    }
    
    /**
     * 获取角色名称
     * @param id 角色ID
     * @return 角色名称
     */
    func getName(for id: String) -> String? {
        return getAttribute(id: id, attribute: "name")
    }
    
    /**
     * 获取角色头像
     * @param id 角色ID
     * @return 角色头像名称
     */
    func getAvatarName(for id: String) -> String? {
        return getAttribute(id: id, attribute: "avatarName")
    }
    
    /**
     * 获取所有角色IDs
     * @return 角色ID数组
     */
    func getAllCharacterIds() -> [String] {
        return Array(characterData.keys)
    }
    
    /**
     * 获取所有可用的角色信息
     * @return 角色信息数组
     */
    func getAllCharactersInfo() -> [(id: String, name: String, avatar: String, type: String, subtype: String, era: String, primaryField: String)] {
        var result: [(id: String, name: String, avatar: String, type: String, subtype: String, era: String, primaryField: String)] = []
        
        for (id, characterInfo) in characterData {
            if let name = characterInfo["name"] as? String,
               let avatar = characterInfo["avatarName"] as? String,
               let type = characterInfo["type"] as? String,
               let subtype = characterInfo["subtype"] as? String,
               let era = characterInfo["era"] as? String,
               let primaryField = characterInfo["primaryField"] as? String {
                result.append((id: id, name: name, avatar: avatar, type: type, subtype: subtype, era: era, primaryField: primaryField))
            }
        }
        
        return result
    }
    
    /**
     * 将角色的type和subtype映射到CharacterCategory
     */
    private func mapToCharacterCategory(type: String, subtype: String) -> CharacterCategory {
        switch (type, subtype) {
        case ("historical", "scientist"), ("literary", "scientist"), ("movie", "scientist"), ("anime", "scientist"):
            return .scientist
        case ("historical", "writer"), ("literary", "writer"), ("movie", "writer"), ("anime", "writer"):
            return .writer
        case ("historical", "artist"), ("literary", "artist"), ("movie", "artist"), ("anime", "artist"):
            return .artist
        case ("historical", "philosopher"), ("literary", "philosopher"), ("movie", "philosopher"), ("anime", "philosopher"):
            return .philosopher
        case ("historical", "politician"), ("literary", "politician"), ("movie", "politician"), ("anime", "politician"):
            return .historical
        case ("historical", "military"), ("literary", "military"), ("movie", "military"), ("anime", "military"):
            return .historical
        case ("historical", "explorer"), ("literary", "explorer"), ("movie", "explorer"), ("anime", "explorer"):
            return .historical
        case ("historical", "inventor"), ("literary", "inventor"), ("movie", "inventor"), ("anime", "inventor"):
            return .scientist
        case ("historical", "musician"), ("literary", "musician"), ("movie", "musician"), ("anime", "musician"):
            return .artist
        case ("historical", "athlete"), ("literary", "athlete"), ("movie", "athlete"), ("anime", "athlete"):
            return .historical
        case ("historical", "business"), ("literary", "business"), ("movie", "business"), ("anime", "business"):
            return .historical
        case ("historical", "religious"), ("literary", "religious"), ("movie", "religious"), ("anime", "religious"):
            return .historical
        case ("historical", "mythological"), ("literary", "mythological"), ("movie", "mythological"), ("anime", "mythological"):
            return .mythCharacter
        case ("historical", "fictional"), ("literary", "fictional"), ("movie", "fictional"), ("anime", "fictional"):
            return .fictionCharacter
        default:
            // 根据type进行默认分类
            switch type {
            case "historical":
                return .scientist
            case "literary":
                return .writer
            case "movie":
                return .movieCharacter
            case "anime":
                return .animeCharacter
            case "game":
                return .gameCharacter
            default:
                return .scientist
            }
        }
    }
}

/**
 * 虚拟角色服务
 * 处理虚拟角色的交互、评论生成等功能
 */
class VirtualCharacterService {
    // 单例实例
    static let shared = VirtualCharacterService()
    
    // MARK: - 测试API配置
    static func testAPIOnStartup() {
        shared.testGenerateCharacterComment()
    }
    
    // MARK: - 私有属性
    private init() {
        print("✅ VirtualCharacterService: 初始化")
        // 初始化时检查孔子角色
        checkKongziCharacter()
        // 在服务初始化时进行一些健康检查
        performInitialHealthChecks()
    }
    
    /**
     * 检查孔子角色的配置
     * 用于诊断孔子头像问题
     */
    private func checkKongziCharacter() {
        print("🔍 检查孔子角色配置:")
        
        // 检查角色ID映射
        let kongziName = getCharacterName(for: "kongzi")
        print("✅ 孔子名称映射: kongzi -> \(kongziName)")
        
        // 检查头像路径
        let avatarPath = "HistoricalFigures/kongzi"
        if let _ = UIImage(named: avatarPath) {
            print("✅ 孔子头像可用: \(avatarPath)")
        } else {
            print("❌ 孔子头像不可用: \(avatarPath)")
            
            // 检查直接路径
            if let _ = UIImage(named: "kongzi") {
                print("✅ 直接路径可用: kongzi")
            } else {
                print("❌ 直接路径不可用: kongzi")
            }
        }
        
        // 检查资源目录
        if let resourcePath = Bundle.main.resourcePath {
            print("📁 资源路径: \(resourcePath)")
            
            // 检查是否存在HistoricalFigures目录
            let historicalPath = resourcePath + "/HistoricalFigures"
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: historicalPath) {
                print("✅ HistoricalFigures目录存在")
                
                // 检查孔子图片是否存在
                let kongziPath = historicalPath + "/kongzi.png"
                if fileManager.fileExists(atPath: kongziPath) {
                    print("✅ 孔子图片存在于: \(kongziPath)")
                } else {
                    print("❌ 孔子图片不存在于: \(kongziPath)")
                }
                
                // 尝试列出目录内容
                do {
                    let files = try fileManager.contentsOfDirectory(atPath: historicalPath)
                    print("📋 HistoricalFigures目录内容: \(files)")
                } catch {
                    print("❌ 无法列出HistoricalFigures目录内容: \(error)")
                }
            } else {
                print("❌ HistoricalFigures目录不存在")
            }
        }
    }
    
    // 核心组件
    private let semanticProcessor = SemanticProcessor()
    private let memoryManager = ConversationMemoryManager()
    private let promptGenerator = AIPromptGenerator()
    private let personalityManager = CharacterPersonalityManager.shared
    private let characterDataManager = CharacterDataManager.shared
    
    // 取消令牌
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 公共方法
    
    /**
     * 获取角色回复 (回调版本)
     * @param characterId 角色ID
     * @param userContent 用户评论
     * @param postContent 帖子内容
     * @param completion 完成回调
     */
    func getCharacterReply(
        characterId: String,
        userContent: String,
        postContent: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // 创建后台任务，确保即使用户退出页面也能完成API调用
        let backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            print("⚠️ VirtualCharacterService: 获取角色回复的后台任务超时")
        }
        
        print("🚀🚀🚀 API请求开始 - 角色ID: \(characterId)")
        print("📝 用户评论内容: \"\(userContent)\"")
        print("🔄 VirtualCharacterService: 创建获取角色回复后台任务，ID: \(backgroundTaskID)")
        
        // 获取带个性化调整的增强提示词
        let enhancedPrompt = personalityManager.generateEnhancedPrompt(
            characterId: characterId.lowercased(),
            userComment: userContent,
            postContent: postContent
        )
        
        // 如果个性化提示词不可用，使用传统方式生成提示词
        let prompt: String
        if let enhancedPrompt = enhancedPrompt {
            prompt = enhancedPrompt
            print("🎭 使用个性化提示词，长度: \(prompt.count)字符")
        } else {
            // 传统方式生成提示词
            // 分析评论语义
            let semanticModel = semanticProcessor.analyze(comment: userContent, postContent: postContent)
            
            // 检查是否有该帖子的记忆
            let memoryKey = "post_\(postContent.prefix(50).hashValue)"
            let memories = memoryManager.retrieveMemories(forKey: memoryKey)
            
            // 使用传统方式生成提示词
            prompt = promptGenerator.generateReplyPrompt(
                characterID: characterId,
                userComment: userContent,
                postContent: postContent,
                semanticModel: semanticModel,
                memories: memories
            )
            print("📝 使用传统提示词，长度: \(prompt.count)字符")
        }
        
        print("📤 准备发送API请求 - 提示词长度: \(prompt.count)字符")
        
        // 使用Publisher版本的方法并转换为回调
        let cancellable = AINetworkService.shared.sendRequest(prompt: prompt)
            .sink(
                receiveCompletion: { completionStatus in
                    // 在任务完成时结束后台任务
                    if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                        UIApplication.shared.endBackgroundTask(backgroundTaskID)
                        print("🏁 VirtualCharacterService: 角色回复生成任务已完成，后台任务结束")
                    }
                    
                    if case .failure(let error) = completionStatus {
                        print("❌❌❌ 生成角色回复失败: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                },
                receiveValue: { output in
                    // 存储这次交互的记忆
                    let memoryKey = "post_\(postContent.prefix(50).hashValue)"
                    self.memoryManager.storeMemory(
                        forKey: memoryKey,
                        content: "用户: \(userContent)\n\(characterId): \(output)"
                    )
                    
                    print("✅✅✅ API返回成功! 角色: \(characterId)")
                    print("💬 回复内容: \"\(output)\"")
                    completion(.success(output))
                }
            )
        
        // 存储可取消项，以防需要提前取消
        cancellables.insert(cancellable)
    }
    
    /**
     * 获取角色回复
     * @param characterID 角色ID
     * @param userComment 用户评论
     * @param postContent 帖子内容
     * @return 角色回复内容
     */
    func getCharacterReply(
        characterID: String,
        to userComment: String,
        in postContent: String
    ) -> AnyPublisher<String, Error> {
        // 创建后台任务，确保即使用户退出页面也能完成API调用
        let backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            print("⚠️ VirtualCharacterService: 获取角色回复的后台任务超时")
        }
        
        print("🔄 VirtualCharacterService: 创建获取角色回复后台任务，ID: \(backgroundTaskID)")
        
        // 获取带个性化调整的增强提示词
        let enhancedPrompt = personalityManager.generateEnhancedPrompt(
            characterId: characterID.lowercased(),
            userComment: userComment,
            postContent: postContent
        )
        
        // 如果个性化提示词不可用，使用传统方式生成提示词
        let prompt: String
        if let enhancedPrompt = enhancedPrompt {
            prompt = enhancedPrompt
            print("🎭 使用个性化提示词，长度: \(prompt.count)字符")
        } else {
            // 传统方式生成提示词
            // 分析评论语义
            let semanticModel = semanticProcessor.analyze(comment: userComment, postContent: postContent)
            
            // 检查是否有该帖子的记忆
            let memoryKey = "post_\(postContent.prefix(50).hashValue)"
            let memories = memoryManager.retrieveMemories(forKey: memoryKey)
            
            // 使用传统方式生成提示词
            prompt = promptGenerator.generateReplyPrompt(
                characterID: characterID,
                userComment: userComment,
                postContent: postContent,
                semanticModel: semanticModel,
                memories: memories
            )
            print("📝 使用传统提示词，长度: \(prompt.count)字符")
        }
        
        // 调用API生成回复
        return AINetworkService.shared.sendRequest(prompt: prompt)
            .handleEvents(
                receiveOutput: { output in
                    // 存储这次交互的记忆
                    let memoryKey = "post_\(postContent.prefix(50).hashValue)"
                    self.memoryManager.storeMemory(
                        forKey: memoryKey,
                        content: "用户: \(userComment)\n\(characterID): \(output)"
                    )
                    
                    print("✅ 成功生成角色回复: \"\(output.prefix(50))...\"")
                },
                receiveCompletion: { completion in
                    // 在任务完成时结束后台任务
                    if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                        UIApplication.shared.endBackgroundTask(backgroundTaskID)
                        print("🏁 VirtualCharacterService: 角色回复生成任务已完成，后台任务结束")
                    }
                    
                    if case .failure(let error) = completion {
                        print("❌ 生成角色回复失败: \(error.localizedDescription)")
                    }
                }
            )
            .mapError { error -> Error in
                // 将AINetworkError转换为一般Error
                return error as Error
        }
        .eraseToAnyPublisher()
    }
    
    /**
     * 生成角色评论
     * @param characterID 角色ID
     * @param forPost 帖子内容
     * @return 生成的评论内容
     */
    func generateCharacterComment(
        characterID: String,
        forPost postContent: String
    ) -> AnyPublisher<String, Error> {
        // 创建后台任务，确保即使用户退出页面也能完成API调用
        let backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            print("⚠️ VirtualCharacterService: 生成角色评论的后台任务超时")
        }
        
        print("🔄 VirtualCharacterService: 创建生成角色评论后台任务，ID: \(backgroundTaskID)")
        
        // 构建提示词
        let prompt: String
        
        // 🔴🔴🔴 超级醒目的角色评论生成开始日志 🔴🔴🔴
        print("\n🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡")
        print("🚨🚨🚨 【虚拟角色评论生成】开始处理！🚨🚨🚨")
        print("🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡")
        print("👤 目标角色ID: \(characterID)")
        print("📝 帖子内容预览: \"\(String(postContent.prefix(100)))...\"")
        print("🔄 后台任务ID: \(backgroundTaskID)")
        
        // 尝试从个性化管理器获取提示词
        if let enhancedPrompt = personalityManager.generateEnhancedPrompt(
            characterId: characterID.lowercased(),
            userComment: "",
            postContent: postContent
        ) {
            // 使用增强提示词
            prompt = enhancedPrompt
            print("\n🎭 ✅ 使用个性化提示词生成评论")
            print("📏 提示词长度: \(prompt.count)字符")
            print("\n🟡 ===== 个性化提示词内容 =====")
            print(prompt)
            print("🟡 ===== 个性化提示词结束 =====")
        } else {
            // 使用传统方式生成提示词
            // 分析帖子内容
            let _ = semanticProcessor.analyze(comment: "", postContent: postContent)
            
            // 获取基本角色特性 - 使用与AI生成帖子内容相同的数据源
            var figureTraits = VCCharacterPersonality(
                tone: "友好专业",
                knowledgeAreas: ["一般知识"],
                speechPatterns: ["我认为"]
            )
            
            // 尝试从CharacterSystem获取角色完整信息
            let allCharacters = CharacterSystem.shared.getAllCharacters()
            if let character = allCharacters.first(where: { $0.id == characterID }) {
                figureTraits = VCCharacterPersonality(
                    tone: "\(character.type.displayName)风格",
                    knowledgeAreas: [character.primaryField],
                    speechPatterns: ["我认为", "从我的角度来看"]
                )
            }
            
            // 使用传统方式生成提示词
            prompt = """
            你是\(characterID)，正在给一篇帖子写评论。请以你的风格和个性回答。
            
            帖子内容："\(postContent)"
            
            你的语调：\(figureTraits.tone)
            你的知识领域：\(figureTraits.knowledgeAreas.joined(separator: "、"))
            
            请以你的风格评论这篇帖子，但注意：
            1. 保持自然，像真人评论一样
            2. 不要用固定句式开头，如"作为[角色]"
            3. 不要重复引用帖子内容
            4. 使用符合你性格的表达方式
            5. 评论长度控制在100字以内，简短有力
            """
            
            print("\n📝 ⚠️ 使用传统提示词生成评论（个性化提示词不可用）")
            print("📏 传统提示词长度: \(prompt.count)字符")
            print("\n🟡 ===== 传统提示词内容 =====")
            print(prompt)
            print("🟡 ===== 传统提示词结束 =====")
        }
        
        print("\n🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡")
        print("🚀🚀🚀 准备发送API请求生成角色评论... 🚀🚀🚀")
        print("🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡")
        
        // 调用API生成评论
        return AINetworkService.shared.sendRequest(prompt: prompt)
            .handleEvents(
                receiveOutput: { output in
                    // 🔴🔴🔴 超级醒目的评论生成成功日志 🔴🔴🔴
                    print("\n🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊")
                    print("🌟🌟🌟 【虚拟角色服务】评论生成成功！🌟🌟🌟")
                    print("🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊")
                    print("✅ 角色[\(characterID)]成功生成评论")
                    print("📝 评论内容预览: \"\(output.prefix(80))...\"")
                    print("📏 评论完整长度: \(output.count)字符")
                    print("\n🎊 ===== 完整评论内容 =====")
                    print(output)
                    print("🎊 ===== 评论内容结束 =====")
                    print("🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊")
                    print("💾 正在存储到记忆管理器...\n")
                    
                    // 存储到记忆
                    let memoryKey = "post_\(postContent.prefix(50).hashValue)"
                    self.memoryManager.storeMemory(
                        forKey: memoryKey, 
                        content: "\(characterID)对帖子的评论: \(output)"
                    )
                },
                receiveCompletion: { completion in
                    // 在任务完成时结束后台任务
                    if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                        UIApplication.shared.endBackgroundTask(backgroundTaskID)
                        print("🏁 VirtualCharacterService: 角色评论生成任务已完成，后台任务结束")
                    }
                    
                    if case .failure(let error) = completion {
                        print("❌ 生成角色评论失败: \(error.localizedDescription)")
                    }
                }
            )
            .mapError { error -> Error in
                // 将AINetworkError转换为一般Error
                return error as Error
        }
        .eraseToAnyPublisher()
    }
    
    /**
     * 生成角色评论回复
     * @param characterID 角色ID
     * @param userComment 用户评论内容
     * @param postContent 帖子内容
     * @param postAuthor 帖子作者
     * @param completion 完成回调
     */
    func generateCharacterComment(
        characterID: String,
        userComment: String,
        postContent: String,
        postAuthor: String? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        print("🚀 开始生成角色评论回复: 角色=\(characterID), 帖子作者=\(postAuthor ?? "未指定")")
        print("📝 用户评论: \"\(userComment.prefix(50))...\"")
        print("📄 帖子内容: \"\(postContent.prefix(50))...\"")
        
        // 创建后台任务，确保即使用户退出页面也能完成API调用
        let backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            print("⚠️ VirtualCharacterService: 生成角色评论回复的后台任务超时")
        }
        
        // 检查用户评论是否是增强提示词（由CommentManager传入）
        let isEnhancedPrompt = userComment.contains("请注意：") && 
                               (userComment.contains("必须直接回应用户评论的具体内容") || 
                                userComment.contains("在回复中明确引用用户评论中的关键词或短语"))
        
        var prompt: String
        
        if isEnhancedPrompt {
            // 直接使用CommentManager中构建的增强提示词
            prompt = userComment
            // 如果有帖子作者信息，添加到提示词中
            if let author = postAuthor, !author.isEmpty {
                prompt = prompt.replacingOccurrences(of: "帖子作者：帖子作者", with: "帖子作者：\(author)")
            }
            print("🔍 检测到增强提示词，直接使用 - 长度: \(prompt.count)字符")
            
            // 提取原始用户评论以判断长度
            let originalUserComment = userComment.components(separatedBy: "\n\n请注意：").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            // 对于简短评论，添加精简版角色指导；对于一般评论，添加标准角色指导
            let traits = getCharacterName(for: characterID)
            let isVeryShortComment = originalUserComment.count <= 15
            
            let characterGuidance: String
            
            if isVeryShortComment {
                // 对极短评论使用更强的约束
                switch characterID.lowercased() {
                case "einstein":
                    characterGuidance = """
                    
                    你是爱因斯坦，但请注意：
                    1. 禁止使用括号中的动作描述
                    2. 禁止使用物理学术语、公式或理论
                    3. 不要尝试"表现"你是爱因斯坦，只需正常回答
                    4. 回应必须与用户评论直接相关
                    5. 使用日常语言，不要故意表现得很聪明
                    6. 像普通人一样自然回复简短评论
                    """
                case "shakespeare":
                    characterGuidance = """
                    
                    你是莎士比亚，但请注意：
                    1. 禁止使用括号中的动作描述
                    2. 禁止使用古英语或文学引用
                    3. 不要尝试"表现"你是莎士比亚，只需正常回答
                    4. 回应必须与用户评论直接相关
                    5. 使用日常现代语言，不要故意表现得很文艺
                    6. 像普通人一样自然回复简短评论
                    """
                case "davinci":
                    characterGuidance = """
                    
                    你是达芬奇，但请注意：
                    1. 禁止使用括号中的动作描述，如"(用羽毛笔蘸取)"等
                    2. 禁止提及绘画工具、飞行器或任何专业术语
                    3. 不要尝试"表现"你是达芬奇，只需正常回答
                    4. 回应必须与用户评论直接相关
                    5. 使用日常语言，不要故意表现得很艺术或科学
                    6. 像普通人一样自然回复简短评论
                    """
                case "curie":
                    characterGuidance = """
                    
                    你是居里夫人，但请注意：
                    1. 禁止使用括号中的动作描述
                    2. 禁止提及实验、科学术语或研究
                    3. 不要尝试"表现"你是居里夫人，只需正常回答
                    4. 回应必须与用户评论直接相关
                    5. 使用日常语言，不要故意表现得很科学
                    6. 像普通人一样自然回复简短评论
                    """
                case "kongzi":
                    characterGuidance = """
                    
                    你是孔子，但请注意：
                    1. 禁止使用括号中的动作描述
                    2. 禁止引用古语或论语
                    3. 不要尝试"表现"你是孔子，只需正常回答
                    4. 回应必须与用户评论直接相关
                    5. 使用日常现代语言，不要故意表现得很哲学
                    6. 像普通人一样自然回复简短评论
                    """
                case "libai":
                    characterGuidance = """
                    
                    你是李白，但请注意：
                    1. 禁止使用括号中的动作描述
                    2. 禁止使用诗句或古语
                    3. 不要尝试"表现"你是李白，只需正常回答
                    4. 回应必须与用户评论直接相关
                    5. 使用日常现代语言，不要故意表现得很诗意
                    6. 像普通人一样自然回复简短评论
                    """
                default:
                    characterGuidance = """
                    
                    请注意：
                    1. 禁止使用括号中的动作描述
                    2. 禁止使用专业术语或复杂概念
                    3. 不要尝试"表现"自己的角色，只需正常回答
                    4. 回应必须与用户评论直接相关
                    5. 使用日常语言，像普通人一样交流
                    6. 简短直接地回复用户的简短评论
                    """
                }
            } else {
                // 对一般评论的处理
                characterGuidance = """
                
                你是\(traits)，请在保持以上指导原则的同时，确保回复体现出你的独特风格和个性，但首要任务是真正回应用户。
                """
            }
            
            // 使用增强提示词加角色特定指导
            prompt = userComment + characterGuidance
        } else {
            // 分析评论语义
            let semanticModel = semanticProcessor.analyze(comment: userComment, postContent: postContent)
            
            // 检查是否有该帖子的记忆
            let memoryKey = "post_\(postContent.prefix(50).hashValue)"
            let memories = memoryManager.retrieveMemories(forKey: memoryKey)
            
            // 生成标准提示词
            prompt = promptGenerator.generateReplyPrompt(
                characterID: characterID,
                userComment: userComment,
                postContent: postContent,
                postAuthor: postAuthor,
                semanticModel: semanticModel,
                memories: memories
            )
            
            print("📝 使用标准提示词 - 长度: \(prompt.count)字符")
        }
        
        print("📤 准备发送API请求 - 提示词长度: \(prompt.count)字符")
        
        // 调用API生成回复
        let cancellable = AINetworkService.shared.sendRequest(prompt: prompt)
            .sink(
                receiveCompletion: { completionStatus in
                    // 在任务完成时结束后台任务
                    if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                        UIApplication.shared.endBackgroundTask(backgroundTaskID)
                        print("🏁 VirtualCharacterService: 角色回复生成任务已完成，后台任务结束")
                    }
                    
                    if case .failure(let error) = completionStatus {
                        print("❌ 生成角色回复失败: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                },
                receiveValue: { output in
                    // 存储这次交互的记忆
                    let extractedUserComment = isEnhancedPrompt ? 
                        userComment.components(separatedBy: "\n\n请注意：").first ?? userComment :
                        userComment
                        
                    self.memoryManager.storeMemory(
                        forKey: "post_\(postContent.prefix(50).hashValue)",
                        content: "用户: \(extractedUserComment)\n\(characterID): \(output)"
                    )
                    
                    print("✅ API返回成功! 角色: \(characterID)")
                    print("💬 回复内容: \"\(output.prefix(50))...\"")
                    
                    // 无需检查模板语言或添加备用回复，直接返回API生成的内容
                    completion(.success(output))
                }
            )
        
        // 存储可取消项，以防需要提前取消
        cancellables.insert(cancellable)
    }
    
    /**
     * 邀请角色参与帖子讨论
     * @param characterIDs 被邀请的角色ID列表，可以是单个或多个
     * @param postId 当前帖子ID
     * @param postAuthor 帖子作者名称，可选
     */
    func inviteCharactersToComment(characterIDs: [String], postId: String, postAuthor: String? = nil) {
        print("🔔 开始邀请角色参与讨论 - 角色数量: \(characterIDs.count), 帖子ID: \(postId), 帖子作者: \(postAuthor ?? "未指定")")
        
        // 创建一个后台任务ID - 使用正确的方式处理后台任务
        let backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "CharacterCommentGeneration") {
            // 系统即将终止此后台任务时的回调
            // 不需要在这里引用backgroundTaskID，因为这是一个逃逸闭包，
            // 在任务结束前系统会调用这个闭包，此时我们只需终止一个无效任务即可
            UIApplication.shared.endBackgroundTask(.invalid)
            print("⚠️ 角色评论生成后台任务被系统终止")
        }
        
        // 过滤空ID，规范化角色ID
        let validCharacterIDs = characterIDs.filter { !$0.isEmpty }.map { $0.lowercased() }
        
        if validCharacterIDs.isEmpty {
            print("⚠️ 没有有效的角色ID，取消邀请")
            // 结束后台任务
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            return
        }
        
        // 验证角色ID
        for characterID in validCharacterIDs {
            let characterName = getCharacterName(for: characterID)
            // 使用我们修复过的CharacterAvatarService
            let characterAvatar = CharacterAvatarService.shared.getAvatarName(for: characterID)
            print("👤 邀请角色: ID=\(characterID), 名称=\(characterName), 头像=\(characterAvatar)")
        }
        
        // 获取帖子数据
        guard let viewModel = getPostViewModel() else {
            print("❌ VirtualCharacterService: 无法获取PostViewModel实例")
            // 结束后台任务
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            return
        }
        
        // 查找对应帖子
        guard let postIndex = viewModel.posts.firstIndex(where: { $0.id.uuidString == postId }) else {
            print("❌ VirtualCharacterService: 未找到指定的帖子ID: \(postId)")
            // 结束后台任务
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            return
        }
        
        let post = viewModel.posts[postIndex]
        
        // 如果没有提供帖子作者，尝试从帖子中获取
        let finalPostAuthor = postAuthor ?? post.username
        print("👤 最终使用的帖子作者: \(finalPostAuthor)")
        
        // 在生成评论之前，先发送一个通知，确保UI准备好接收新评论
        DispatchQueue.main.async {
            // 强制触发 objectWillChange 通知，确保 SwiftUI 视图准备好更新
            viewModel.posts[postIndex].objectWillChange.send()
            
            // 发送预备通知
            NotificationCenter.default.post(
                name: NSNotification.Name("PrepareForNewComments"),
                object: nil,
                userInfo: ["postID": postId]
            )
        }
        
        // 保存帖子内容的副本，确保即使在后台也能访问
        let postContent = post.content
        
        // 统一使用MultiCharacterCommentService处理所有角色评论生成，无论是单个还是多个角色
        print("🔄 使用批量评论生成服务处理\(validCharacterIDs.count)个角色")
        MultiCharacterCommentService.shared.generateMultiCharacterComments(
            characterIDs: validCharacterIDs,
            postId: postId,
            postContent: postContent,
            postAuthor: finalPostAuthor,
            userComment: "",  // 🔧 邀请评论模式：没有用户评论内容
            isInvited: true,  // 标记为邀请的角色评论
            completion: { [weak self] result in
            guard let self = self else {
                // 如果self已被释放，结束后台任务
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                return 
            }
            
            switch result {
            case .success(let commentsMap):
                print("✅ 批量生成成功，共生成\(commentsMap.count)条评论")
                
                // 批量评论已经在MultiCharacterCommentService中添加到帖子
                // 通过CommentsGenerated通知处理，不需要再发送CharacterReplyGenerated通知
                
                // 额外的刷新机制，确保UI立即更新，无论用户是否在当前页面
                DispatchQueue.main.async {
                    // 尝试直接更新PostViewModel中的数据
                    if let viewModel = self.getPostViewModel() {
                        if let postIndex = viewModel.posts.firstIndex(where: { $0.id.uuidString == postId }) {
                            // 去除重复评论
                            self.removeDuplicateComments(for: postIndex, in: viewModel)
                            
                        // 强制触发 objectWillChange 通知
                        viewModel.posts[postIndex].objectWillChange.send()
                        
                        // 创建一个临时副本并重新赋值，强制 SwiftUI 刷新
                        let tempPost = viewModel.posts[postIndex]
                        viewModel.posts[postIndex] = tempPost
                        }
                        
                        // 发送多个刷新通知，确保所有相关视图都能更新
                        // 1. 强制刷新评论
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ForceRefreshComments"),
                            object: nil,
                            userInfo: [
                                "keepExpandState": true,
                                "preventScroll": true,
                                "immediateDisplay": true,
                                "postID": postId
                            ]
                        )
                        
                        // 2. 刷新帖子评论
                        NotificationCenter.default.post(
                            name: NSNotification.Name("RefreshPostComments"),
                            object: nil,
                            userInfo: [
                                "postID": postId,
                                "immediateDisplay": true
                            ]
                        )
                        
                        // 注意：CommentsGenerated通知已在MultiCharacterCommentService中发送，这里不再重复发送
                        
                        // 3. 全局刷新所有帖子
                        NotificationCenter.default.post(
                            name: NSNotification.Name("GlobalPostsRefresh"),
                            object: nil
                        )
                    }
                }
                
                // 结束后台任务
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                print("✅ 角色评论生成后台任务完成")
                
            case .failure(let error):
                print("❌ 批量生成角色评论失败 - \(error.localizedDescription)")
                
                // 发送批量生成失败的通知
                NotificationCenter.default.post(
                    name: NSNotification.Name("CharacterReplyGenerationFailed"),
                    object: nil,
                    userInfo: [
                        "postID": postId,
                        "error": error.localizedDescription
                    ]
                )
                
                // 结束后台任务
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                print("❌ 角色评论生成后台任务失败")
            }
        })
    }
    
    /**
     * 获取角色聊天回复
     * 专门为聊天界面设计的API调用方法
     * @param character 聊天角色
     * @param userMessage 用户消息
     * @param conversationHistory 对话历史
     * @return 角色回复内容的Publisher
     */
    func getCharacterChatReply(
        character: CYChatCharacter,
        userMessage: String,
        conversationHistory: String
    ) -> AnyPublisher<String, Error> {
        // 创建后台任务，确保即使用户退出页面也能完成API调用
        let backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            print("⚠️ VirtualCharacterService: 获取聊天回复的后台任务超时")
        }
        
        print("🔄 VirtualCharacterService: 创建获取聊天回复后台任务，ID: \(backgroundTaskID)")
        
        // 构建角色信息
        let characterInfo = buildCharacterInfo(character)
        
        // 调用专门的聊天API
        return AINetworkService.shared.sendChatRequest(
            characterName: character.name,
            characterInfo: characterInfo,
            conversationHistory: conversationHistory,
            userMessage: userMessage
        )
        .handleEvents(
            receiveOutput: { output in
                print("✅ 成功生成聊天回复: \"\(output.prefix(50))...\"")
                
                // 存储这次交互的记忆
                let memoryKey = "chat_\(character.id)"
                self.memoryManager.storeMemory(
                    forKey: memoryKey,
                    content: "用户: \(userMessage)\n\(character.name): \(output)"
                )
            },
            receiveCompletion: { completion in
                // 在任务完成时结束后台任务
                if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(backgroundTaskID)
                    print("🏁 VirtualCharacterService: 聊天回复生成任务已完成，后台任务结束")
                }
                
                if case .failure(let error) = completion {
                    print("❌ 生成聊天回复失败: \(error.localizedDescription)")
                }
            }
        )
        .mapError { error -> Error in
            // 将AINetworkError转换为一般Error
            return error as Error
        }
        .eraseToAnyPublisher()
    }

    /**
     * 获取角色聊天回复（回调版本）
     * @param character 聊天角色
     * @param userMessage 用户消息
     * @param conversationHistory 对话历史
     * @param completion 完成回调
     */
    func getCharacterChatReply(
        character: CYChatCharacter,
        userMessage: String,
        conversationHistory: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // 创建后台任务，确保即使用户退出页面也能完成API调用
        let backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            print("⚠️ VirtualCharacterService: 获取聊天回复的后台任务超时")
        }
        
        print("🚀 聊天API请求开始 - 角色: \(character.name)")
        print("📝 用户消息: \"\(userMessage)\"")
        print("🔄 VirtualCharacterService: 创建获取聊天回复后台任务，ID: \(backgroundTaskID)")
        
        // 构建角色信息
        let characterInfo = buildCharacterInfo(character)
        
        // 添加详细日志
        print("\n📊 ===== 聊天请求详细数据 =====")
        print("🧩 角色ID: \(character.id)")
        print("👤 角色名称: \(character.name)")
        print("🌍 时代: \(character.eraTag)")
        print("🔬 领域: \(character.field)")
        
        print("\n📜 角色详细信息:")
        print(characterInfo)
        
        print("\n💬 对话历史:")
        print(conversationHistory)
        
        print("\n💭 用户最新消息:")
        print(userMessage)
        print("📊 ===== 详细数据结束 =====\n")
        
        // 使用Publisher版本的方法并转换为回调
        let cancellable = AINetworkService.shared.sendChatRequest(
            characterName: character.name,
            characterInfo: characterInfo,
            conversationHistory: conversationHistory,
            userMessage: userMessage
        )
        .sink(
            receiveCompletion: { completionStatus in
                // 在任务完成时结束后台任务
                if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(backgroundTaskID)
                    print("🏁 VirtualCharacterService: 聊天回复生成任务已完成，后台任务结束")
                }
                
                if case .failure(let error) = completionStatus {
                    print("❌❌❌ 生成聊天回复失败: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            },
            receiveValue: { output in
                // 存储这次交互的记忆
                let memoryKey = "chat_\(character.id)"
                self.memoryManager.storeMemory(
                    forKey: memoryKey,
                    content: "用户: \(userMessage)\n\(character.name): \(output)"
                )
                
                print("✅✅✅ 聊天API返回成功! 角色: \(character.name)")
                print("💬 回复内容: \"\(output.prefix(100))...\"")
                completion(.success(output))
            }
        )
        
        // 存储可取消项，以防需要提前取消
        cancellables.insert(cancellable)
    }

    /**
     * 构建角色详细信息
     * @param character 角色对象
     * @return 格式化的角色信息字符串
     */
    private func buildCharacterInfo(_ character: CYChatCharacter) -> String {
        // 极简基本信息
        var info = "\(character.birthYear)-\(character.deathYear)，\(character.field)。\(character.introduction)"
        
        // 创建唯一内容集合，避免重复
        var uniqueItems = Set<String>()
        
        // 合并成就、作品和思想，去除重复
        var allItems = [String]()
        
        // 添加成就，确保唯一性
        for achievement in character.achievements {
            if uniqueItems.insert(achievement).inserted {
                allItems.append(achievement)
            }
        }
        
        // 添加主要作品，确保唯一性
        for work in character.mainWorks {
            if uniqueItems.insert(work).inserted {
                allItems.append(work)
            }
        }
        
        // 添加核心思想，确保唯一性
        for thought in character.keyThoughts {
            if uniqueItems.insert(thought).inserted {
                allItems.append(thought)
            }
        }
        
        // 只有当有内容时才添加
        if !allItems.isEmpty {
            info += "\n\n主要贡献与思想:"
            // 最多添加3个项目，避免过长
            for (_, item) in allItems.prefix(3).enumerated() {
                info += "\n• \(item)"
            }
        }
        
        return info
    }
    
    // MARK: - 测试方法
    
    /**
     * 测试生成虚拟角色评论
     * 此方法用于测试API对角色评论生成的响应，包括详细的日志记录和质量评估
     * @param characterID 要测试的角色ID，可选
     */
    func testGenerateCharacterComment(characterID: String? = nil) {
        // 测试用帖子内容样本
        let testPosts = [
            "今天天气真好，我去公园散步，看到了很多美丽的花朵。",
            "我最近在学习Swift编程，感觉很有趣也很有挑战性。",
            "有人知道附近有什么好吃的餐厅吗？我想尝试一些新的美食。",
            "昨天看了一部很感人的电影，情节扣人心弦，演员表演也很出色。"
        ]
        
        // 随机选择一个测试帖子
        let testPost = testPosts.randomElement() ?? "这是一个测试帖子。"
        
        // 获取所有可用的角色
        let availableCharacters = characterDataManager.getAllCharacterIds()
        
        // 使用传入的角色ID、随机选择一个可用角色，或使用默认角色
        let finalCharacterID: String
        if let providedID = characterID {
            finalCharacterID = providedID
        } else if !availableCharacters.isEmpty {
            // 随机选择一个可用角色
            finalCharacterID = availableCharacters.randomElement() ?? "einstein"
            print("🎲 随机选择可用角色: \(finalCharacterID)")
        } else {
            // 使用默认角色
            finalCharacterID = "einstein"
            print("⚠️ 没有可用角色，使用默认角色: einstein")
        }
        
        // 获取角色信息
        let characterName = getCharacterName(for: finalCharacterID)
        // 使用我们修复过的CharacterAvatarService
        let characterAvatar = CharacterAvatarService.shared.getAvatarName(for: finalCharacterID)
        
        print("\n�� API测试: 生成虚拟角色评论")
        print("🔹 使用角色ID: \(finalCharacterID)")
        print("🔹 角色名称: \(characterName)")
        print("🔹 角色头像: \(characterAvatar)")
        print("🔹 测试帖子内容: \"\(testPost)\"")
        
        // 发起API请求
        generateCharacterComment(characterID: finalCharacterID, forPost: testPost)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("✅ API请求完成")
                    case .failure(let error):
                        print("❌ API请求失败: \(error.localizedDescription)")
                        self.handleTestError(error)
                    }
                },
                receiveValue: { commentContent in
                    print("\n🎯 API响应成功")
                    print("📊 评论统计:")
                    print("  - 字数: \(commentContent.count)")
                    print("  - 段落数: \(commentContent.components(separatedBy: "\n\n").count)")
                    
                    print("\n💬 生成的评论内容:")
                    print("------------------------------")
                    print("\(commentContent)")
                    print("------------------------------")
                    
                    // 实际添加评论到帖子
                    DispatchQueue.main.async {
                        // 获取PostViewModel实例
                        if let postViewModel = self.getPostViewModel() {
                            // 找到一个合适的帖子添加评论
                            if let postIndex = self.findSuitablePostIndex(in: postViewModel) {
                                // 获取当前帖子
                                let post = postViewModel.posts[postIndex]
                                
                                // 查找父评论
                                if let (parentId, parentUsername) = self.findParentComment(in: post) {
                                    // 创建回复评论模型
                                    let replyComment = DetailedCommentModel(
                                        id: UUID(),
                                        username: self.getCharacterName(for: finalCharacterID),
                                        // 使用我们修复过的CharacterAvatarService
                                        userAvatar: CharacterAvatarService.shared.getAvatarName(for: finalCharacterID),
                                        content: commentContent,
                                        datePosted: Date(),
                                        isVirtualCharacter: true,
                                        characterID: finalCharacterID,
                                        parentCommentId: parentId,
                                        replyToUsername: parentUsername
                                    )
                                    
                                    print("\n🔄 实际添加评论回复:")
                                    print("  角色: \(replyComment.username)")
                                    print("  头像: \(replyComment.userAvatar)")
                                    print("  特殊标记: isVirtualCharacter=\(replyComment.isVirtualCharacter)")
                                    print("  回复给: \(parentUsername)")
                                    
                                    // 将回复添加到父评论下
                                    post.addReplyToParent(parentId: parentId, reply: replyComment)
                                    
                                    // 🔧 重要修复：保存帖子数据到持久化存储
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("SavePostData"),
                                        object: nil,
                                        userInfo: ["postID": post.id.uuidString]
                                    )
                                    
                                    // 发送真实通知更新UI
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("PostCommentsUpdated"),
                                        object: nil,
                                        userInfo: ["postID": post.id.uuidString]
                                    )
                                    
                                    // 确保UI刷新
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("RefreshPostComments"),
                                        object: nil
                                    )
                                    
                                    print("✅ 评论回复已添加到父评论，ID: \(parentId)")
                                } else {
                                    // 如果没有找到合适的父评论，则作为新评论添加
                                    let newComment = DetailedCommentModel(
                                        id: UUID(),
                                        username: self.getCharacterName(for: finalCharacterID),
                                        // 使用我们修复过的CharacterAvatarService
                                        userAvatar: CharacterAvatarService.shared.getAvatarName(for: finalCharacterID),
                                        content: commentContent,
                                        datePosted: Date(),
                                        isVirtualCharacter: true,
                                        characterID: finalCharacterID
                                    )
                                    
                                    print("\n🔄 未找到父评论，作为新评论添加:")
                                    print("  角色: \(newComment.username)")
                                    print("  头像: \(newComment.userAvatar)")
                                    
                                    // 使用addComment方法添加评论到帖子，确保应用过滤逻辑
                                    postViewModel.posts[postIndex].addComment(newComment)
                                    
                                    // 🔧 重要修复：保存帖子数据到持久化存储
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("SavePostData"),
                                        object: nil,
                                        userInfo: ["postID": post.id.uuidString]
                                    )
                                    
                                    // 发送真实通知更新UI
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("PostCommentsUpdated"),
                                        object: nil,
                                        userInfo: ["postID": post.id.uuidString]
                                    )
                                    
                                    // 确保UI刷新
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("RefreshPostComments"),
                                        object: nil
                                    )
                                    
                                    print("✅ 评论已作为新评论添加到帖子")
                                }
                                
                                print("✅ 评论总数: \(postViewModel.posts[postIndex].comments.count)")
                            } else {
                                print("❌ 未找到合适的帖子添加评论")
                            }
                        } else {
                            print("❌ 无法获取PostViewModel实例")
                        }
                    }
                    
                    print("\n🏁 测试流程完成")
                }
            )
            .store(in: &cancellables)
    }
    
    /**
     * 获取角色头像系统名称
     * @param characterID 角色ID
     * @return 角色头像系统图标名称
     */
    private func getCharacterAvatar(for characterID: String) -> String {
        // 这个方法现在已经过时，可以直接调用CharacterAvatarService.shared.getAvatarName
        return CharacterAvatarService.shared.getAvatarName(for: characterID)
    }
    
    /**
     * 获取角色名称
     * @param characterID 角色ID
     * @return 角色名称
     */
    private func getCharacterName(for characterID: String) -> String {
        // 中文名称映射
        let characterNames: [String: String] = [
            "einstein": "爱因斯坦",
            "shakespeare": "莎士比亚", 
            "davinci": "达芬奇",
            "kongzi": "孔子",
            "curie": "居里夫人",
            "libai": "李白",
            "newton": "牛顿",
            "holmes": "福尔摩斯",
            "naruto": "鸣人",
            "sunwukong": "孙悟空",
            "goku": "孙悟空",
            "socrates": "苏格拉底",
            "nietzsche": "尼采",
            "darwin": "达尔文",
            "luxun": "鲁迅",
            "plato": "柏拉图",
            "dufu": "杜甫",
            "aristotle": "亚里士多德",
            "napoleon": "拿破仑",
            "picasso": "毕加索",
            "vangogh": "梵高",
            "quyuan": "屈原",
            "laozi": "老子",
            "mozart": "莫扎特",
            "beethoven": "贝多芬",
            "heraclitus": "赫拉克利特",
            "zhuangzi": "庄子",
            "marquez": "马尔克斯",
            "hawking": "霍金",
            "edison": "爱迪生",
            "tesla": "特斯拉",
            "kant": "康德",
            "hegel": "黑格尔",
            "baudelaire": "波德莱尔",
            "kafka": "卡夫卡",
            "smith": "亚当·斯密",
            "marx": "马克思",
            "camus": "加缪",
            "freud": "弗洛伊德",
            "jung": "荣格",
            "heidegger": "海德格尔",
            "xuzhimo": "徐志摩",
            "hemingway": "海明威",
            "bach": "巴赫",
            "turing": "图灵",
            "feynman": "费曼",
            "popper": "波普尔",
            "tagore": "泰戈尔",
            "schopenhauer": "叔本华",
            "dostoevsky": "陀思妥耶夫斯基",
            "lincoln": "林肯",
            "gandhi": "甘地",
            "beauvoir": "波伏娃",
            "yangming": "王阳明",
            "xiaobo": "王小波",
            "pascal": "帕斯卡",
            "russell": "罗素",
            "wittgenstein": "维特根斯坦",
            "sartre": "萨特",
            "wordsworth": "华兹华斯",
            "qingzhao": "李清照"
        ]
        
        // 先检查是否有中文名称映射
        if let chineseName = characterNames[characterID.lowercased()] {
            print("✅ 使用中文名称映射: \(characterID) -> \(chineseName)")
            
            // 特殊处理孔子
            if characterID.lowercased() == "kongzi" {
                print("🔍 特殊处理孔子名称 - 返回中文名称: 孔子")
            }
            
            return chineseName
        }
        
        // 尝试从角色数据管理器中获取
        if let name = characterDataManager.getName(for: characterID) {
            print("✅ 从CharacterDataManager获取名称: \(characterID) -> \(name)")
            return name
        }
        
        // 如果找不到角色数据，返回ID的首字母大写形式作为名称
        print("⚠️ 未找到角色ID \(characterID) 对应的名称，返回ID首字母大写形式")
        return characterID.capitalized
    }
    
    /**
     * 从角色数据中获取属性值
     * @param id 角色ID
     * @param attribute 要获取的属性名
     * @return 属性值，如果不存在则返回nil
     */
    private func getCharacterAttributeFromData(id: String, attribute: String) -> String? {
        // 已经通过CharacterDataManager处理，此方法可以直接返回nil
        // 保留此方法是为了向后兼容
        return nil
    }
    
    /**
     * 检查API密钥是否有效
     * @return 是否有有效的API密钥
     */
    private func isAPIKeyValid() -> Bool {
        guard let apiKey = APIConfigManager.shared.apiKey else {
            print("❌ API密钥未设置")
            return false
        }
        
        // 使用APIConfigManager的方法检查API密钥格式
        let isValidFormat = APIConfigManager.shared.isValidAPIKeyFormat(apiKey)
        
        print("🔑 API密钥检查: \(String(apiKey.prefix(8)))... - 格式\(isValidFormat ? "正确" : "不正确")")
        
        return isValidFormat && APIConfigManager.shared.hasValidAPIKey
    }
    
    /// 处理测试响应中的错误
    private func handleTestError(_ error: Error) {
        print("❌ 测试失败: \(error.localizedDescription)")
        
        // 记录详细错误信息
        if let networkError = error as? AINetworkError {
            switch networkError {
            case .invalidURL:
                print("🔴 错误: 无效的API URL")
            case .noAPIKey:
                print("🔴 错误: 未设置API密钥")
            case .requestFailed(let error):
                print("🔴 网络请求失败: \(error.localizedDescription)")
            case .invalidResponse:
                print("🔴 无效响应: 无法解析响应数据")
            case .decodingError(let error):
                print("🔴 解码失败: \(error.localizedDescription)")
            case .httpError(let code):
                print("🔴 HTTP错误: 状态码\(code)")
            }
        }
    }
    
    /**
     * 获取PostViewModel实例
     * 通过NotificationCenter获取已存在的PostViewModel实例
     */
    private func getPostViewModel() -> PostViewModel? {
        // 尝试从应用中获取PostViewModel实例
        let viewModel = PostViewModel.shared
        return viewModel
    }
    
    /**
     * 找到合适的帖子索引
     * @param viewModel PostViewModel实例
     * @return 合适的帖子索引，如果没有找到则返回nil
     */
    private func findSuitablePostIndex(in viewModel: PostViewModel) -> Int? {
        // 如果有帖子，返回第一个帖子的索引
        if !viewModel.posts.isEmpty {
            return 0
        }
        return nil
    }
    
    /**
     * 找到合适的父评论作为回复目标
     * @param post 帖子模型
     * @return 父评论ID和用户名元组
     */
    private func findParentComment(in post: UserPostModel) -> (parentId: UUID, username: String)? {
        // 如果帖子有评论，选择第一条非虚拟角色的评论作为回复目标
        if !post.comments.isEmpty {
            // 优先选择非虚拟角色的评论作为回复目标
            for comment in post.comments {
                if !comment.isVirtualCharacter {
                    return (comment.id, comment.username)
                }
            }
            
            // 如果没有非虚拟角色评论，则选择第一条评论
            return (post.comments[0].id, post.comments[0].username)
        }
        return nil
    }
    
    /**
     * 构建批量提示词
     * @param characterIDs 角色ID列表
     * @param postContent 帖子内容
     * @param postAuthor 帖子作者
     * @return 批量提示词
     */
    private func buildBatchPrompt(characterIDs: [String], postContent: String, postAuthor: String? = nil) -> String {
        // 收集角色信息，包括名称、性格特点和专业领域
        let characterInfo = characterIDs.map { id -> String in
            let name = characterDataManager.getName(for: id) ?? id.capitalized
            
            // 尝试获取角色的性格特点
            var traits = ""
            if let personality = personalityManager.getPersonality(for: id) {
                let tone = personality.tone
                let knowledgeAreas = personality.knowledgeAreas.joined(separator: "、")
                traits = "（性格特点：\(tone)，专业领域：\(knowledgeAreas)）"
            }
            
            return "- \(name) (ID: \(id)) \(traits)"
        }.joined(separator: "\n")
        
        // 获取帖子作者信息 - 如果提供了作者名称则使用，否则使用默认值
        let authorInfo = postAuthor ?? "帖子作者"
        print("👤 使用帖子作者: \(authorInfo)")
        
        let prompt = """
        你需要为以下角色分别生成评论回复。每个角色都有自己的风格和特点。针对同一个帖子内容，生成每个角色独特的回复。

        帖子内容："\(postContent)"
        帖子作者：\(authorInfo)

        角色列表：
        \(characterInfo)

        请按照以下格式生成每个角色的回复：

        [角色ID]
        这里是该角色的评论内容...

        [下一个角色ID]
        这里是下一个角色的评论内容...

        重要任务要求：
        1. 为每个角色找到与帖子内容或作者的联系点或共鸣点，这可能是：
           - 角色的专业领域与帖子的关联
           - 角色的人生经历与帖子作者的情感共鸣
           - 角色特有的观点与帖子内容的思想碰撞
           - 角色可能对作者(即\(authorInfo))的直接回应或评价
        
        2. 基于找到的联系点，让角色进行有深度、有趣且有个性的评论
           - 避免泛泛而谈，要体现角色与帖子内容或作者的真实互动
           - 让评论展现角色如何从自己独特视角理解帖子
           - 创造让用户感到"这评论太有趣了"的惊喜效果
           - 适当加入角色特有的幽默感、智慧或视角

        3. 每个角色的回复必须符合其性格、风格和背景
        4. 每个回复控制在25-50字之间，简短有力
        5. 不要重复引用帖子内容
        6. 不要使用固定句式开头，如"作为[角色]"
        7. 确保每个角色评论都以[角色ID]开头，便于解析
        8. 每个角色的评论应当清晰分隔，不要混淆
        9. 可以在适当情况下直接称呼作者名字，增加互动感
        10. 使用通俗易懂的语言，避免晦涩难懂的表达
        11. 不要使用专业术语或高深理论，确保普通用户能理解
        12. 禁止添加任何形式的注释、解释或理论分析
        13. 不要在评论后添加"注："或类似的解释说明
        14. 评论必须是纯粹的内容，不包含任何元解释
        15. 禁止使用括号中的内容，如"(微笑)"、"(思考中)"等
        """
        
        print("📋 构建批量提示词，包含\(characterIDs.count)个角色")
        return prompt
    }
    
    // 在服务初始化时进行一些健康检查
    private func performInitialHealthChecks() {
        // 检查一些重要的角色数据是否能正确加载
        let importantIds = ["einstein", "shakespeare", "sunwukong", "davinci"]
        for id in importantIds {
            let name = getCharacterName(for: id)
            if name == id {
                print("⚠️ 健康检查警告: 角色 \(id) 可能缺少中文名称映射。")
        }
    }
}

/**
 * 角色人格特征结构
 */
struct VCCharacterPersonality {
    let tone: String
    let knowledgeAreas: [String]
    let speechPatterns: [String]
    }

    /**
     * 移除重复的评论
     * @param postIndex 帖子在 viewModel.posts 中的索引
     * @param viewModel PostViewModel 实例
     */
    private func removeDuplicateComments(for postIndex: Int, in viewModel: PostViewModel) {
        var uniqueComments: [DetailedCommentModel] = []
        var seenKeys: Set<String> = []
        
        for comment in viewModel.posts[postIndex].comments {
            // 创建唯一键：角色ID + 内容
            let key = "\(comment.characterID ?? "")-\(comment.content)"
            
            if !seenKeys.contains(key) {
                uniqueComments.append(comment)
                seenKeys.insert(key)
            } else {
                print("⚠️ 检测到重复评论，已移除: \(comment.username)")
            }
        }
        
        if uniqueComments.count < viewModel.posts[postIndex].comments.count {
            print("🔍 去重前评论数: \(viewModel.posts[postIndex].comments.count), 去重后: \(uniqueComments.count)")
        }
        
        // 按时间排序，保持一致的排列方式（较新的评论在前）
        uniqueComments.sort { $0.datePosted > $1.datePosted }
        
        // 更新帖子的评论
        viewModel.posts[postIndex].comments = uniqueComments
    }
} 
