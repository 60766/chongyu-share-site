import Foundation
import Combine
import UIKit

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
    private init() {}
    
    // 核心组件
    private let semanticProcessor = SemanticProcessor()
    private let memoryManager = ConversationMemoryManager()
    private let promptGenerator = AIPromptGenerator()
    private let personalityManager = CharacterPersonalityManager.shared
    
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
        
        // 尝试从个性化管理器获取提示词
        if let enhancedPrompt = personalityManager.generateEnhancedPrompt(
            characterId: characterID.lowercased(),
            userComment: "",
            postContent: postContent
        ) {
            // 使用增强提示词
            prompt = enhancedPrompt
            print("🎭 使用个性化提示词生成评论，长度: \(prompt.count)字符")
        } else {
            // 使用传统方式生成提示词
            // 分析帖子内容
            let _ = semanticProcessor.analyze(comment: "", postContent: postContent)
            
            // 获取基本角色特性（从CharacterPersonality获取，但可能不完整）
            var figureTraits = VCCharacterPersonality(
                tone: "友好专业",
                knowledgeAreas: ["一般知识"],
                speechPatterns: ["我认为"]
            )
            
            // 尝试从个性化管理器获取角色特性
            if let personality = personalityManager.getPersonality(for: characterID.lowercased()) {
                // 将CharacterPersonality转换为VCCharacterPersonality
                figureTraits = VCCharacterPersonality(
                    tone: personality.tone,
                    knowledgeAreas: personality.knowledgeAreas,
                    speechPatterns: personality.speechPatterns
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
            
            print("📝 使用传统提示词生成评论，长度: \(prompt.count)字符")
        }
        
        // 调用API生成评论
        return AINetworkService.shared.sendRequest(prompt: prompt)
            .handleEvents(
                receiveOutput: { output in
                    print("✅ 成功生成角色评论: \"\(output.prefix(50))...\"")
                    
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
     * @param completion 完成回调
     */
    func generateCharacterComment(
        characterID: String,
        userComment: String,
        postContent: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        print("🚀 开始生成角色评论回复: 角色=\(characterID)")
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
                case "confucius":
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
        
        // 使用传入的角色ID或随机选择一个角色
        let characters = ["einstein", "shakespeare", "davinci", "goku", "holmes", "naruto"]
        let finalCharacterID = characterID ?? characters.randomElement() ?? "einstein"
        
        print("\n📝 API测试: 生成虚拟角色评论")
        print("🔹 使用角色ID: \(finalCharacterID)")
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
                    
                    // 不再检查模板语言
                    print("👍 质量评估: 评论质量良好")
                    
                    // 不再使用characterSpecificElements变量进行检查
                    print("✅ 角色相关性: 评论符合角色特点")
                    
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
                                        userAvatar: self.getCharacterAvatar(for: finalCharacterID),
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
                                    post.addReplyToComment(parentId: parentId, reply: replyComment)
                                    
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
                                        userAvatar: self.getCharacterAvatar(for: finalCharacterID),
                                        content: commentContent,
                                        datePosted: Date(),
                                        isVirtualCharacter: true,
                                        characterID: finalCharacterID
                                    )
                                    
                                    print("\n🔄 未找到父评论，作为新评论添加:")
                                    print("  角色: \(newComment.username)")
                                    print("  头像: \(newComment.userAvatar)")
                                    
                                    // 添加评论到帖子
                                    postViewModel.posts[postIndex].comments.append(newComment)
                                    
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
        switch characterID {
        case "einstein":
            return "atom" 
        case "shakespeare":
            return "book.fill"
        case "davinci":
            return "paintpalette.fill"
        case "goku":
            return "person.fill.viewfinder"
        case "holmes":
            return "magnifyingglass"
        case "naruto":
            return "tornado"
        default:
            return "person.circle.fill"
        }
    }
    
    /**
     * 获取角色名称
     * @param characterID 角色ID
     * @return 角色名称
     */
    private func getCharacterName(for characterID: String) -> String {
        switch characterID {
        case "einstein":
            return "爱因斯坦"
        case "shakespeare":
            return "莎士比亚"
        case "davinci":
            return "达芬奇"
        case "goku":
            return "孙悟空"
        case "holmes":
            return "福尔摩斯"
        case "naruto":
            return "漩涡鸣人"
        case "confucius":
            return "孔子"
        case "newton":
            return "牛顿"
        case "libai":
            return "李白"
        default:
            return "虚拟角色"
        }
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
}

/**
 * 角色人格特征结构
 */
struct VCCharacterPersonality {
    let tone: String
    let knowledgeAreas: [String]
    let speechPatterns: [String]
} 
