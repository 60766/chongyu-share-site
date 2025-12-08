import Foundation
import Combine
import UIKit
import SwiftData

/**
 * 角色回复数据结构
 * 包含评论内容和点赞判断
 */
struct CharacterResponse {
    let content: String
    let shouldLike: Bool
}

/**
 * 多角色评论服务
 * 用于批量生成多个虚拟角色的评论，共用一次API调用
 */
class MultiCharacterCommentService {
    // 单例实例
    static let shared = MultiCharacterCommentService()
    
    // 依赖的服务
    private let characterDataManager = CharacterDataManager.shared
    private let personalityManager = CharacterPersonalityManager.shared
    private let insightService = CharacterChatInsightService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // 🔧 第一性原理：使用串行队列确保对同一个帖子ID的添加操作是串行的，防止并发导致的重复
    // 使用帖子ID作为key，每个帖子有独立的串行队列
    private var postQueues: [String: DispatchQueue] = [:]
    private let queueLock = NSLock()
    
    // 存储当前请求的上下文信息
    private struct CommentRequestContext {
        let userComment: String?
        let userCommentId: String?
        let originalPost: String?
        let originalPostAuthor: String?
    }
    private var currentRequestContext: CommentRequestContext?
    
    // 私有初始化方法
    private init() {}
    
    /// 🔧 第一性原理：获取或创建帖子专用的串行队列
    private func getQueue(for postId: String) -> DispatchQueue {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        if let queue = postQueues[postId] {
            return queue
        }
        
        let queue = DispatchQueue(label: "comment.add.\(postId)", qos: .userInitiated)
        postQueues[postId] = queue
        return queue
    }
    
    /**
     * 批量生成多个角色的评论
     * @param characterIDs 角色ID列表
     * @param postId 帖子ID
     * @param postContent 帖子内容
     * @param postAuthor 帖子作者
     * @param userComment 用户评论内容，用于生成针对性回复
     * @param userCommentId 用户评论ID，用于点赞
     * @param targetUsername 目标用户名，被回复的用户
     * @param authorCharacterId 帖子作者的角色ID，如果作者是虚拟角色
     * @param isInvited 是否为邀请的角色评论，默认为false
     * @param completion 完成回调，返回角色ID到评论内容的映射
     */
    func generateMultiCharacterComments(
        characterIDs: [String],
        postId: String,
        postContent: String,
        postAuthor: String? = nil,
        userComment: String? = nil,
        userCommentId: String? = nil,
        targetUsername: String? = nil,
        authorCharacterId: String? = nil,
        isInvited: Bool = false,
        modelContext: ModelContext? = nil,
        completion: @escaping (Result<[String: String], Error>) -> Void
    ) {
        // 🔧 修复：创建独立的请求上下文，不覆盖全局变量
        let requestContext = CommentRequestContext(
            userComment: userComment,
            userCommentId: userCommentId,
            originalPost: postContent,
            originalPostAuthor: postAuthor
        )
        
        // 如果没有角色，直接返回空结果
        if characterIDs.isEmpty {
            completion(.success([:]))
            return
        }
        
        // 创建后台任务，确保即使用户退出页面也能完成API调用
        let backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            #if DEBUG
            debugLog("⚠️ MultiCharacterCommentService: 批量生成角色评论的后台任务超时")
            #endif
        }
        
        // 构建批量提示词
        let batchPrompt = buildBatchPrompt(
            characterIDs: characterIDs,
            postContent: postContent,
            postAuthor: postAuthor,
            userComment: userComment,
            targetUsername: targetUsername,
            authorCharacterId: authorCharacterId,
            isInvited: isInvited,
            modelContext: modelContext
        )
        
        // 移除60秒超时保护，允许长时间生成
        let timerCancellable: AnyCancellable? = nil
        
        // 调用API生成批量评论
        #if DEBUG
        debugLog("🔥🔥🔥 === 正在调用 AINetworkService.sendRequest === 🔥🔥🔥")
        #endif
        AINetworkService.shared.sendRequest(prompt: batchPrompt)
            .sink(
                receiveCompletion: { completionStatus in
                    // 取消超时计时器
                    timerCancellable?.cancel()
                    
                    // 在任务完成时结束后台任务
                    if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                        UIApplication.shared.endBackgroundTask(backgroundTaskID)
                        #if DEBUG
                        debugLog("🏁 MultiCharacterCommentService: 批量角色评论生成任务已完成，后台任务结束")
                        #endif
                    }
                    
                    if case .failure(let error) = completionStatus {
                        Logger.error("批量生成角色评论失败", error: error, log: Logger.data)
                        completion(.failure(error))
                    }
                },
                receiveValue: { output in
                    // 取消超时计时器
                    timerCancellable?.cancel()
                    
                    #if DEBUG
                    debugLog("✅ 批量API返回成功!")
                    
                    // 🔍 添加详细的API响应调试信息
                    debugLog("\n📥 ===== 批量角色评论API响应详细内容 =====")
                    debugLog("🔷 响应统计:")
                    debugLog("  - 响应长度: \(output.count)字符")
                    debugLog("  - 响应行数: \(output.components(separatedBy: .newlines).count)")
                    debugLog("\n🔷 完整响应内容:")
                    debugLog("=====================================")
                    debugLog(output)
                    debugLog("=====================================\n")
                    #endif
                    
                    // 解析API返回的批量评论结果
                    let commentsMap = self.parseAPIResponse(response: output, characterIDs: characterIDs)
                    
                    // 检查是否有角色的评论未能成功解析（在DEBUG块外也需要这个变量）
                    let missingCharacters = characterIDs.filter { !commentsMap.keys.contains($0) }
                    
                    // 🔍 添加详细的解析结果调试信息
                    #if DEBUG
                    debugLog("\n📊 ===== 批量评论解析结果 =====")
                    debugLog("🎯 请求的角色: \(characterIDs.joined(separator: ", "))")
                    debugLog("✅ 成功解析的角色: \(commentsMap.keys.joined(separator: ", "))")
                    debugLog("🔷 解析详情:")
                    for (characterId, response) in commentsMap {
                        let characterName = self.characterDataManager.getName(for: characterId) ?? characterId
                        debugLog("  - \(characterName) (\(characterId)): \"\(response.content.prefix(30))...\"")
                        debugLog("    点赞: \(response.shouldLike ? "是" : "否")")
                    }
                    
                    if !missingCharacters.isEmpty {
                        debugLog("❌ 未能解析的角色: \(missingCharacters.joined(separator: ", "))")
                        for missingId in missingCharacters {
                            let missingName = self.characterDataManager.getName(for: missingId) ?? missingId
                            debugLog("  - \(missingName) (\(missingId))")
                        }
                    }
                    debugLog("=====================================\n")
                    #endif
                    
                    if !missingCharacters.isEmpty && commentsMap.isEmpty {
                        // 如果所有角色都没有成功解析，返回错误
                        #if DEBUG
                        debugLog("❌ 批量评论生成失败: 无法解析任何角色的评论")
                        #endif
                        completion(.failure(NSError(domain: "MultiCharacterCommentService", code: -2, userInfo: [NSLocalizedDescriptionKey: "评论解析失败"])))
                        return
                    } else if !missingCharacters.isEmpty {
                        // 如果部分角色没有成功解析，记录日志
                        #if DEBUG
                        debugLog("⚠️ 部分角色评论未能解析: \(missingCharacters.joined(separator: ", "))")
                        #endif
                    }
                    
                    // 添加评论到帖子
                    self.addCommentsToPost(commentsMap: commentsMap, characterIDs: characterIDs, postId: postId, isInvited: isInvited, requestContext: requestContext)
                    
                    #if DEBUG
                    debugLog("✅ 批量评论生成完成，成功解析\(commentsMap.count)个角色的评论")
                    #endif
                    // 转换为只包含评论内容的映射，保持向后兼容
                    let contentOnlyMap = commentsMap.mapValues { $0.content }
                    completion(.success(contentOnlyMap))
                }
            )
            .store(in: &cancellables)
    }
    
    /**
     * 构建批量提示词
     * @param characterIDs 角色ID列表
     * @param postContent 帖子内容
     * @param postAuthor 帖子作者
     * @param userComment 用户评论内容，用于生成针对性回复
     * @param targetUsername 目标用户名，被回复的用户
     * @param authorCharacterId 帖子作者的角色ID，如果作者是虚拟角色
     * @param isInvited 是否为邀请的角色评论
     * @return 批量提示词
     */
    private func buildBatchPrompt(
        characterIDs: [String],
        postContent: String,
        postAuthor: String? = nil,
        userComment: String? = nil,
        targetUsername: String? = nil,
        authorCharacterId: String? = nil,
        isInvited: Bool = false,
        modelContext: ModelContext? = nil
    ) -> String {
        // 收集角色信息，包括名称、性格特点和专业领域
        let characterInfo = characterIDs.map { id -> String in
            let name = characterDataManager.getName(for: id) ?? id.capitalized
            
            // 标记是否为帖子作者
            let isAuthor = id == authorCharacterId
            let authorMark = isAuthor ? "（帖子作者）" : ""
            
            // 尝试获取角色的完整信息 - 使用与AI生成帖子内容相同的数据源
            var traits = ""
            let allCharacters = CharacterSystem.shared.getAllCharacters()
            if let character = allCharacters.first(where: { $0.id == id }) {
                traits = "（类型：\(character.type.displayName)，专业领域：\(character.primaryField)）"
            }
            
            // 尝试加载缓存的画像信息
            var insightInfo = ""
            if let context = modelContext,
               let insight = insightService.loadCachedInsight(characterId: id, modelContext: context) {
                #if DEBUG
                debugLog("✅ 为角色 \(name) 加载了缓存画像")
                #endif
                insightInfo = "\n  画像摘要：\(insight.summary)"
            }
            
            return "- \(name) (ID: \(id)) （@时使用：@\(name)） \(authorMark) \(traits)\(insightInfo)"
        }.joined(separator: "\n")
        
        // 获取帖子作者信息 - 如果提供了作者名称则使用，否则使用默认值
        let authorInfo = postAuthor ?? "帖子作者"
        #if DEBUG
        debugLog("👤 使用帖子作者: \(authorInfo)")
        #endif
        
        // 确定提示词类型和内容
        var prompt: String
        
        if let userComment = userComment, !userComment.isEmpty, let targetUsername = targetUsername, !isInvited {
            // 针对用户评论的回复提示词
            prompt = """
            你需要从以下角色列表中选择2-3个最适合回复用户评论的角色：
            \(characterInfo)
            
            帖子内容："\(postContent)"
            帖子作者：\(authorInfo)
            
            用户"\(targetUsername)"发表的评论："\(userComment)"

            请分析哪些角色对这条评论最感兴趣或最有发言权，然后只为这些角色生成回复。
            """
            
            // 如果帖子作者是虚拟角色且在列表中，强调必须选择作者回复
            if let authorId = authorCharacterId, characterIDs.contains(authorId) {
                let authorName = characterDataManager.getName(for: authorId) ?? authorId.capitalized
                prompt += """
                
                重要规则（必须严格遵守）：
                - 帖子作者"\(authorName)"必须是第一个回复的角色
                - 帖子作者的回复必须使用格式：[\(authorId)]
                - 帖子作者对评论的回复应该体现出作者对自己帖子的关注和理解
                - 其他角色可以根据兴趣和专业领域选择1-2个最适合的
                - 无论用户评论内容是什么，帖子作者都必须参与回复
                - 严格按照这个顺序：先生成作者回复，再生成其他角色回复
                """
            } else if let authorId = authorCharacterId {
                // 如果有作者ID但不在列表中，添加到列表的开头
                #if DEBUG
                debugLog("⚠️ 帖子作者ID不在角色列表中，将其添加到列表开头")
                #endif
                var newCharacterIDs = characterIDs
                newCharacterIDs.insert(authorId, at: 0)
                let authorName = characterDataManager.getName(for: authorId) ?? authorId.capitalized
                
                // 更新角色信息
                let authorInfo = "- \(authorName) (ID: \(authorId)) （帖子作者）"
                let updatedCharacterInfo = authorInfo + "\n" + characterInfo
                
                // 替换提示词中的角色列表
                prompt = prompt.replacingOccurrences(of: characterInfo, with: updatedCharacterInfo)
                
                // 添加强调作者必须回复的提示
                prompt += """
                
                重要规则（必须严格遵守）：
                - 帖子作者"\(authorName)"必须是第一个回复的角色
                - 帖子作者的回复必须使用格式：[\(authorId)]
                - 帖子作者对评论的回复应该体现出作者对自己帖子的关注和理解
                - 其他角色可以根据兴趣和专业领域选择1-2个最适合的
                - 无论用户评论内容是什么，帖子作者都必须参与回复
                - 严格按照这个顺序：先生成作者回复，再生成其他角色回复
                """
            }
            
            prompt += """
            
            选择角色时考虑：
            1. 评论内容与角色专业领域的相关性
            2. 角色可能对此评论的兴趣程度
            3. 角色的性格特点是否适合回应此类评论
            4. 角色是否能对此评论提供有趣或有见地的回应
            
            请按照以下格式生成选定角色的回复（每个角色的评论后必须包含点赞判断）：
            
            [角色ID]
            这里是该角色的评论内容...
            点赞：是
            
            [下一个角色ID]
            这里是下一个角色的评论内容...
            点赞：否
            
            点赞判断规则：
            - 如果角色认为用户的内容有趣、有价值、值得鼓励，请写"点赞：是"
            - 如果角色对内容不太感兴趣或不太认同，请写"点赞：否"
            - 每个角色评论后必须明确写出"点赞：是"或"点赞：否"
            """
            
            // 如果有作者角色，强调必须首先生成作者的回复
            if let authorId = authorCharacterId, characterIDs.contains(authorId) {
                let authorName = characterDataManager.getName(for: authorId) ?? authorId.capitalized
                prompt += """

                 特别注意：
                 - 必须首先生成帖子作者"\(authorName)"的回复，格式为：
                   [\(authorId)]
                   这里是作者的回复内容...
                   点赞：是
                 - 然后再生成其他角色的回复（每个角色评论后都要加上"点赞：是"或"点赞：否"）
                 """
            }
            
            prompt += """

            🚨 绝对强制要求：用户是这个评论区的中心！

            重要任务要求：
            1. 每个角色必须直接回应用户的评论内容，而非帖子本身
            2. 为每个角色找到与用户评论的联系点或共鸣点，这可能是：
               - 角色的专业领域与用户评论的关联
               - 角色的人生经历与用户评论的情感共鸣
               - 角色特有的观点与用户评论的思想碰撞
            
            3. 基于找到的联系点，让角色进行有深度、有趣且有个性的评论
               - 避免泛泛而谈，要体现角色与用户评论的真实互动
               - 让回复展现角色如何从自己独特视角理解用户评论
               - 创造让用户感到"这评论太有趣了"的惊喜效果
               - 适当加入角色特有的幽默感、智慧或视角

            4. 每个角色的回复必须符合其性格、风格和背景
            5. 每个回复控制在20-40字之间，简短有力
            6. 不要重复引用用户评论内容
            7. 不要使用固定句式开头，如"作为[角色]"
            8. 确保每个角色评论都以[角色ID]开头，便于解析
            9. 每个角色的评论应当清晰分隔，不要混淆
            10. 🚨每个角色都要直接对用户说话，用"你"来称呼用户：
                - 可以使用角色风格的自然称呼
                - 如果是回复问题，可以直接回答而不称呼
                - 如果是对话，可以用"您"表示尊重
                - 🚨严禁@其他角色，只能直接回应用户
                - 避免机械地重复用户名
            11. 使用通俗易懂的语言，避免晦涩难懂的表达
            12. 不要使用专业术语或高深理论，确保普通用户能理解
            
            🎭 真实评论区行为（让角色更有活人感）：
            - 😏 吃瓜围观："哦？这么刺激的吗？"、"说来听听"
            - 🔥 起哄站队："就是就是！"、"我支持你！"、"说得对！"
            - 🤔 抬杠质疑："真的假的？"、"我觉得不对"、"有证据吗？"
            - 😅 调侃吐槽："哈哈笑死"、"你这话说的"、"太逗了"
            - 🙄 不以为然："就这？"、"也没什么"、"一般般吧"
            - 😤 情绪激动："气死了！"、"太过分了！"、"不能忍！"
            - 🤨 表示怀疑："我不信"、"扯淡"、"你骗谁呢"
            - 😎 忍不住炫耀："我当年..."、"这个我熟"、"说起这个..."
            - 🥱 敷衍回应："哦"、"还行吧"、"无所谓"
            - 💭 话题跑偏：从用户评论联想到自己完全不相关的经历
            
            ⚠️ 注意：这些行为要符合角色身份，不要过度使用，保持真实感

            绝对禁止事项（必须严格遵守）：
            1. 严格禁止添加任何形式的注释、解释或理论分析
            2. 严格禁止在评论后添加"注："或类似的解释说明
            3. 严格禁止在评论中使用括号添加额外说明，如"(微笑)"、"(思考中)"等
            4. 严格禁止使用"PS:"、"补充:"等形式添加额外内容
            5. 评论必须是纯粹的内容，绝对不能包含任何元解释或元分析
            6. 严格禁止对评论内容进行自我解释或说明
            7. 严格禁止在评论中添加学术引用、出处或参考资料
            8. 评论必须是角色直接表达的内容，不允许有任何额外的解释层
            9. 严格禁止回复帖子内容，必须只回复用户评论
            10. 严格禁止直接称呼用户为"当前用户"或类似的明显网名

            格式要求：
            - 🚨必须使用角色信息中的英文ID，如[tolstoy]、[marquez]、[kawabata]、[libai]
            - 🚨禁止使用中文名称，如[托尔斯泰]、[川端康成]、[列夫·托尔斯泰]
            - 严格按照[角色ID]方括号格式，不添加额外标点
            - 🚨严禁@其他角色，只能直接对用户说话
            - 🚨每个角色都要用"你"来称呼用户，表现出在和用户直接对话
            
            点赞判断：
            在生成每个角色的回复后，请为每个角色额外判断：作为真实的这个角色，你会给用户的这条评论点赞吗？
            在每个角色的回复后添加：
            点赞：是 或 点赞：否
            
            输出格式示例：
            [einstein]
            这个思考很有逻辑性！
            点赞：是
            
            [libai]
            颇有诗意，真情流露。
            点赞：是
            """
        } else {
            // 🎯 专门针对用户发布帖子的提示词（使用作者判断）
            // 判断条件：没有userComment（不是回复评论），且postAuthor不为空（是用户发布的帖子）
            if userComment == nil && postAuthor != nil {
                // 用户发布的帖子，生成更加友好和鼓励性的评论
                
                // 获取当前时间戳作为随机因子
                let currentTime = Date().timeIntervalSince1970
                
                // 生成随机情绪状态
                let emotions = ["积极", "平静", "专注", "好奇", "温和", "愉悦", "深思", "轻松"]
                let randomEmotion = emotions.randomElement() ?? "平静"
                
                // 生成互动深度
                let interactionLevels = ["初次相遇", "熟悉朋友", "知己", "老友"]
                let interactionDepth = interactionLevels.randomElement() ?? "熟悉朋友"
                
                prompt = """
                为以下角色生成对用户帖子的评论，每个角色必须风格迥异、真实有趣：

                🎭 角色列表：
                \(characterInfo)

                帖子内容："\(postContent)"
                帖子作者：用户

                【核心要求】
                1. 多样性优先：每个角色必须从完全不同的角度切入，避免相似表达
                2. 真实感：像真人刷到这条动态时的第一反应，不要刻意迎合
                3. 角色特色：用角色特有的说话方式、思维模式、时代背景来评论
                4. 自然互动：可以是共鸣、质疑、调侃、联想、分享，但必须自然

                【禁止模板化】
                ❌ 不要用"作为[角色]"、"让我想起"、"很有道理"等套路开头
                ❌ 不要所有角色都夸赞或都提问，要有不同态度
                ❌ 不要重复帖子内容，直接说自己的话
                ❌ 不要@其他角色，只对用户说话

                【鼓励的表达方式】
                ✅ 直接反应："这啥？"、"有意思"、"不太懂"、"我也有过"
                ✅ 个人联想：从帖子想到自己的经历、专业、时代背景
                ✅ 真实情绪：好奇、困惑、认同、不以为然、兴奋、平静
                ✅ 角色特色：用角色时代的语言、专业术语、性格特点

                【格式】
                必须用英文ID：[角色ID]
                评论内容（20-45字，自然口语化）
                点赞：是/否

                【示例】
                [einstein]
                这个现象让我想到时空弯曲，虽然可能不是你想表达的意思。
                点赞：是

                [libai]
                哈哈，我当年也这样，不过是用诗写的。
                点赞：是

                [dante]
                在炼狱里见过类似的，但你的更轻松。
                点赞：否

                现在生成评论，确保每个角色风格完全不同：
                """
                        } else {
                // 原始提示词（针对其他帖子内容的回复）
            prompt = """
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
               - 角色可能对作者的直接回应或评价
            
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
            9. 🚨每个角色都要直接对帖子作者说话，用"你"来称呼作者：
               - 可以使用角色风格的自然称呼
               - 如果是回应观点，可以直接评论而不称呼
               - 如需称呼，使用"您"表示尊重
               - 🚨严禁@其他角色，只能直接回应作者
               - 避免机械地重复作者名
            10. 使用通俗易懂的语言，避免晦涩难懂的表达
            11. 不要使用专业术语或高深理论，确保普通用户能理解
            
            🎭 真实评论区行为（让角色更有活人感）：
            - 😏 吃瓜围观："哦？这么刺激的吗？"、"说来听听"
            - 🔥 起哄站队："就是就是！"、"我支持你！"、"说得对！"
            - 🤔 抬杠质疑："真的假的？"、"我觉得不对"、"有证据吗？"
            - 😅 调侃吐槽："哈哈笑死"、"你这话说的"、"太逗了"
            - 🙄 不以为然："就这？"、"也没什么"、"一般般吧"
            - 😤 情绪激动："气死了！"、"太过分了！"、"不能忍！"
            - 🤨 表示怀疑："我不信"、"扯淡"、"你骗谁呢"
            - 😎 忍不住炫耀："我当年..."、"这个我熟"、"说起这个..."
            - 🥱 敷衍回应："哦"、"还行吧"、"无所谓"
            - 💭 话题跑偏：从帖子内容联想到自己完全不相关的经历
            
            ⚠️ 注意：这些行为要符合角色身份，不要过度使用，保持真实感

            绝对禁止事项（必须严格遵守）：
            1. 严格禁止添加任何形式的注释、解释或理论分析
            2. 严格禁止在评论后添加"注："或类似的解释说明
            3. 严格禁止在评论中使用括号添加额外说明，如"(微笑)"、"(思考中)"等
            4. 严格禁止使用"PS:"、"补充:"等形式添加额外内容
            5. 评论必须是纯粹的内容，绝对不能包含任何元解释或元分析
            6. 严格禁止对评论内容进行自我解释或说明
            7. 严格禁止在评论中添加学术引用、出处或参考资料
            8. 评论必须是角色直接表达的内容，不允许有任何额外的解释层

            格式要求：
            - 🚨必须使用角色信息中的英文ID，如[tolstoy]、[marquez]、[kawabata]、[libai]
            - 🚨禁止使用中文名称，如[托尔斯泰]、[川端康成]、[列夫·托尔斯泰]
            - 严格按照[角色ID]方括号格式，不添加额外标点
            - 🚨严禁@其他角色，只能直接对帖子作者说话
            - 🚨每个角色都要用"你"来称呼作者，表现出在和作者直接对话
            
            点赞判断：
            在生成每个角色的回复后，请为每个角色判断：作为这个角色，你会给这条帖子点赞吗？
            在每个角色的回复后添加：
            点赞：是 或 点赞：否
            
            输出格式示例：
            [einstein]
            这个观点很有趣，值得深入思考。
            点赞：是
            
            [libai]
            好诗好诗，颇有意境！
            点赞：是
            """
             }
        }
        
        #if DEBUG
        debugLog("📋 构建批量提示词，包含\(characterIDs.count)个角色")
        #endif
        return prompt
    }
    
    /**
     * 解析API响应，包括评论内容和点赞判断
     * @param response API返回的响应内容
     * @param characterIDs 角色ID列表
     * @return 角色ID到CharacterResponse的映射
     */
    private func parseAPIResponse(response: String, characterIDs: [String]) -> [String: CharacterResponse] {
        #if DEBUG
        debugLog("📄 原始响应内容预览: \(response.prefix(100))...")
        
        debugLog("📄 AI原始响应（前500字符）:")
        debugLog("---")
        debugLog(String(response.prefix(500)))
        debugLog("---")
        #endif
        
        var result = [String: CharacterResponse]()
        var currentCharacterId: String? = nil
        var currentComment = ""
        
        // 将响应按行分割
        let lines = response.components(separatedBy: .newlines)
        
        // 规范化角色ID列表（全部转为小写）以便于比较
        let normalizedCharacterIDs = characterIDs.map { $0.lowercased() }
        
        #if DEBUG
        debugLog("📋 待解析角色ID: \(characterIDs.joined(separator: ", "))")
        debugLog("📊 总行数: \(lines.count)")
        #endif
        
        // 处理每一行
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 跳过空行，但如果当前正在处理某个角色的评论，则保留空行作为评论内容的一部分
            if trimmedLine.isEmpty {
                if currentCharacterId != nil && !currentComment.isEmpty {
                    // 添加空行到当前评论
                    currentComment += "\n"
                }
                continue
            }
            
            // 检查是否是角色ID标记行 - 方式1：[角色ID]格式
            if trimmedLine.hasPrefix("[") && trimmedLine.hasSuffix("]") {
                // 保存之前处理的角色评论
                if let id = currentCharacterId, !currentComment.isEmpty {
                    let (content, shouldLike) = parseCharacterContent(currentComment)
                    result[id] = CharacterResponse(content: content, shouldLike: shouldLike)
                    #if DEBUG
                    debugLog("✓ 已解析角色评论: \(id), 长度: \(content.count)字符, 点赞: \(shouldLike ? "是" : "否")")
                    #endif
                    currentComment = ""
                }
                
                // 提取新的角色ID
                let startIndex = trimmedLine.index(after: trimmedLine.startIndex)
                let endIndex = trimmedLine.index(before: trimmedLine.endIndex)
                let extractedId = String(trimmedLine[startIndex..<endIndex])
                
                // 规范化提取的ID并检查是否在请求的角色列表中
                let normalizedExtractedId = extractedId.lowercased()
                if normalizedCharacterIDs.contains(normalizedExtractedId) {
                    // 使用原始大小写的ID作为键
                    let originalId = characterIDs.first { $0.lowercased() == normalizedExtractedId } ?? extractedId
                    currentCharacterId = originalId
                    #if DEBUG
                    debugLog("✓ 找到角色评论标记[方括号]: \(originalId)")
                    #endif
                } else {
                    currentCharacterId = nil
                    #if DEBUG
                    debugLog("⚠️ 找到未知角色ID: \(extractedId)，已忽略")
                    #endif
                }
            }
            // 检查是否是角色ID标记行 - 方式2：单独一行的角色ID
            else if normalizedCharacterIDs.contains(trimmedLine.lowercased()) {
                // 保存之前处理的角色评论
                if let id = currentCharacterId, !currentComment.isEmpty {
                    let (content, shouldLike) = parseCharacterContent(currentComment)
                    result[id] = CharacterResponse(content: content, shouldLike: shouldLike)
                    #if DEBUG
                    debugLog("✓ 已解析角色评论: \(id), 长度: \(content.count)字符, 点赞: \(shouldLike ? "是" : "否")")
                    #endif
                    currentComment = ""
                }
                
                // 使用原始大小写的ID作为键
                let originalId = characterIDs.first { $0.lowercased() == trimmedLine.lowercased() } ?? trimmedLine
                currentCharacterId = originalId
                #if DEBUG
                debugLog("✓ 找到角色评论标记[直接ID]: \(originalId)")
                #endif
            }
            // 如果不是角色ID标记行，且当前有正在处理的角色ID，则添加到评论内容
            else if let _ = currentCharacterId {
                // 检查是否是下一个角色的开始
                let potentialCharacterId = trimmedLine.lowercased()
                if normalizedCharacterIDs.contains(potentialCharacterId) && 
                   // 确保这不是评论内容的一部分
                   (currentComment.isEmpty || 
                    // 或者是新段落的开始
                    (index > 0 && lines[index-1].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)) {
                    
                    // 保存之前的角色评论
                    if let id = currentCharacterId, !currentComment.isEmpty {
                        let (content, shouldLike) = parseCharacterContent(currentComment)
                        result[id] = CharacterResponse(content: content, shouldLike: shouldLike)
                        #if DEBUG
                        debugLog("✓ 已解析角色评论: \(id), 长度: \(content.count)字符, 点赞: \(shouldLike ? "是" : "否")")
                        #endif
                        currentComment = ""
                    }
                    
                    // 设置新的角色ID
                    let originalId = characterIDs.first { $0.lowercased() == potentialCharacterId } ?? trimmedLine
                    currentCharacterId = originalId
                    #if DEBUG
                    debugLog("✓ 找到角色评论标记[内容中]: \(originalId)")
                    #endif
                } else {
                    // 添加到当前评论内容
                    if !currentComment.isEmpty {
                        currentComment += "\n"
                    }
                    currentComment += trimmedLine
                }
            }
        }
        
        // 处理最后一个角色
        if let id = currentCharacterId, !currentComment.isEmpty {
            let (content, shouldLike) = parseCharacterContent(currentComment)
            result[id] = CharacterResponse(content: content, shouldLike: shouldLike)
            #if DEBUG
            debugLog("✓ 已解析最后一个角色评论: \(id), 长度: \(content.count)字符, 点赞: \(shouldLike ? "是" : "否")")
            #endif
        }
        
        // 输出解析结果统计
        #if DEBUG
        debugLog("📊 解析结果: 成功解析\(result.count)/\(characterIDs.count)个角色的评论")
        #endif
        
        // 如果标准解析方法失败，尝试使用后备方法
        if result.isEmpty {
            #if DEBUG
            debugLog("⚠️ 标准解析方法未能提取任何评论，尝试使用后备解析方法")
            #endif
            result = fallbackParseResponse(response: response, characterIDs: characterIDs)
        }
        
        // 尝试处理缺失的角色
        let missingCharacters = characterIDs.filter { !result.keys.contains($0) }
        if !missingCharacters.isEmpty {
            #if DEBUG
            debugLog("⚠️ 以下角色的评论未能解析: \(missingCharacters.joined(separator: ", "))")
            
            // 检查是否有帖子作者在缺失列表中
            if let authorId = characterIDs.first, missingCharacters.contains(authorId) {
                debugLog("❗️ 警告: 帖子作者的评论未能解析")
            }
            #endif
        }
        
        return result
    }
    
    /**
     * 解析角色的评论内容，分离评论和点赞判断
     * @param content 原始内容
     * @return (评论内容, 是否点赞)
     */
    private func parseCharacterContent(_ content: String) -> (String, Bool) {
        let lines = content.components(separatedBy: .newlines)
        var commentLines: [String] = []
        var shouldLike = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 检查是否是点赞判断行
            if trimmedLine.hasPrefix("点赞：") || trimmedLine.hasPrefix("点赞:") {
                let likeDecision = trimmedLine.replacingOccurrences(of: "点赞：", with: "")
                                             .replacingOccurrences(of: "点赞:", with: "")
                                             .trimmingCharacters(in: .whitespacesAndNewlines)
                shouldLike = (likeDecision == "是")
                #if DEBUG
                #endif
            } else if !trimmedLine.isEmpty {
                // 普通评论行
                commentLines.append(trimmedLine)
            }
        }
        
        let finalContent = commentLines.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        return (finalContent, shouldLike)
    }

    /**
     * 后备解析方法 - 尝试使用更简单的方式解析API响应
     * 适用于无法通过标准方式解析的情况
     */
    private func fallbackParseResponse(response: String, characterIDs: [String]) -> [String: CharacterResponse] {
        #if DEBUG
        debugLog("🔄 使用后备解析方法")
        #endif
        var result = [String: CharacterResponse]()
        
        // 规范化角色ID列表（全部转为小写）以便于比较
        let normalizedCharacterIDs = characterIDs.map { $0.lowercased() }
        
        // 尝试方法1：按照空行分割响应，然后检查每个块的第一行是否是角色ID
        let blocks = response.components(separatedBy: "\n\n")
        #if DEBUG
        debugLog("📊 后备解析：找到\(blocks.count)个文本块")
        #endif
        
        for block in blocks {
            let lines = block.components(separatedBy: .newlines)
            guard let firstLine = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                  !firstLine.isEmpty else {
                continue
            }
            
            // 检查第一行是否匹配任何角色ID
            for (index, characterId) in normalizedCharacterIDs.enumerated() {
                if firstLine == characterId || firstLine == "[\(characterId)]" {
                    let originalId = characterIDs[index]
                    // 提取评论内容（排除第一行）
                    let commentLines = Array(lines.dropFirst())
                    let comment = commentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !comment.isEmpty {
                        let (content, shouldLike) = parseCharacterContent(comment)
                        result[originalId] = CharacterResponse(content: content, shouldLike: shouldLike)
                        #if DEBUG
                        debugLog("✓ 后备方法解析到角色评论: \(originalId), 长度: \(content.count)字符, 点赞: \(shouldLike ? "是" : "否")")
                        #endif
                    }
                    break
                }
            }
        }
        
        // 如果方法1失败，尝试方法2：使用正则表达式查找角色ID和评论
        if result.isEmpty && !characterIDs.isEmpty {
            #if DEBUG
            debugLog("🔄 后备解析方法1失败，尝试方法2")
            #endif
            
            for characterId in characterIDs {
                let lowercaseId = characterId.lowercased()
                
                // 尝试多种模式匹配
                let patterns = [
                    // 模式1：[角色ID]后面跟着内容
                    "\\[\(lowercaseId)\\][\\s\\S]*?(?=\\[|$)",
                    // 模式2：角色ID单独一行，后面跟着内容
                    "(?:^|\n)\(lowercaseId)\\s*\n([\\s\\S]*?)(?=\n\\w+\\s*\n|$)",
                    // 模式3：角色ID开头，后面直接跟着内容
                    "\(lowercaseId)[\\s\\S]*?(?=\n\\w+|$)"
                ]
                
                for pattern in patterns {
                    if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                        let nsString = response as NSString
                        let matches = regex.matches(in: response, options: [], range: NSRange(location: 0, length: nsString.length))
                        
                        if let match = matches.first {
                            let matchedText = nsString.substring(with: match.range)
                            
                            // 提取评论内容（排除角色ID行）
                            var commentText = matchedText
                            if commentText.lowercased().hasPrefix("[\(lowercaseId)]") {
                                commentText = String(commentText.dropFirst(lowercaseId.count + 2))
                            } else if commentText.lowercased().hasPrefix("\(lowercaseId)") {
                                commentText = String(commentText.dropFirst(lowercaseId.count))
                            }
                            
                            // 清理评论内容
                            commentText = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            if !commentText.isEmpty {
                                let (content, shouldLike) = parseCharacterContent(commentText)
                                result[characterId] = CharacterResponse(content: content, shouldLike: shouldLike)
                                #if DEBUG
                                debugLog("✓ 后备方法2解析到角色评论: \(characterId), 长度: \(content.count)字符, 点赞: \(shouldLike ? "是" : "否")")
                                #endif
                                break
                            }
                        }
                    }
                }
            }
        }
        
        #if DEBUG
        debugLog("📊 后备解析结果: 成功解析\(result.count)/\(characterIDs.count)个角色的评论")
        #endif
        return result
    }
    
    /**
     * 将评论添加到帖子
     * @param commentsMap 角色ID到评论内容的映射
     * @param characterIDs 角色ID列表
     * @param postId 帖子ID
     * @param isInvited 是否为邀请的角色评论，默认为false
     * @param requestContext 请求上下文，包含用户评论和帖子信息
     */
    private func addCommentsToPost(commentsMap: [String: CharacterResponse], characterIDs: [String], postId: String, isInvited: Bool = false, requestContext: CommentRequestContext) {
        // 获取帖子数据
        let viewModel = PostViewModel.shared
        
        // 查找对应帖子
        guard viewModel.posts.firstIndex(where: { $0.id.uuidString == postId }) != nil else {
            #if DEBUG
            debugLog("❌ 未找到指定的帖子ID: \(postId)")
            #endif
            return
        }
        
        // 检查帖子作者是否在列表中但未返回评论
        if !isInvited && characterIDs.count > 0 {
            let authorId = characterIDs[0]
            if !commentsMap.keys.contains(authorId) {
                #if DEBUG
                debugLog("⚠️ 帖子作者(\(authorId))的评论未在API返回结果中，跳过默认回复")
                #endif
                
                // 不添加默认回复，直接使用原始的评论映射
                sendCommentsNotifications(
                    postId: postId, 
                    commentsMap: commentsMap, 
                    isInvited: isInvited,
                    requestContext: requestContext
                )
                return
            }
        }
        
        // 使用原始映射发送通知
        sendCommentsNotifications(
            postId: postId, 
            commentsMap: commentsMap, 
            isInvited: isInvited,
            requestContext: requestContext
        )
    }

    /**
     * 发送评论相关通知，并处理点赞逻辑
     * @param postId 帖子ID
     * @param commentsMap 角色ID到CharacterResponse的映射
     * @param isInvited 是否为邀请的角色评论
     * @param requestContext 请求上下文，包含用户评论和帖子信息
     */
    private func sendCommentsNotifications(postId: String, commentsMap: [String: CharacterResponse], isInvited: Bool, requestContext: CommentRequestContext) {
        // 🔧 第一性原理：直接将评论添加到帖子模型中，确保数据层面的更新
        // 使用串行队列确保不会重复添加
        self.directlyAddCommentsToPost(
            postId: postId, 
            commentsMap: commentsMap, 
            requestContext: requestContext
        )
        
            // 生成一个唯一的批次ID，用于区分不同的评论批次
            let batchId = UUID().uuidString
            
        // 在主线程上执行UI更新
        DispatchQueue.main.async {
            // 转换commentsMap为只包含评论内容的映射，用于通知
            let contentOnlyMap = commentsMap.mapValues { $0.content }
            
            // 发送通知，包含生成的评论内容映射
            var userInfo: [String: Any] = [
                "postID": postId,
                "commentsMap": contentOnlyMap,
                "isInvited": isInvited,
                "batchId": batchId,
                "forceUpdate": true  // 添加强制更新标记
            ]
            
            // 添加用户评论和原帖信息
            if let userComment = requestContext.userComment {
                userInfo["userComment"] = userComment
            }
            if let originalPost = requestContext.originalPost {
                userInfo["originalPost"] = originalPost
            }
            if let originalPostAuthor = requestContext.originalPostAuthor {
                userInfo["originalPostAuthor"] = originalPostAuthor
            }
            
            // 🔧 优化：只发送一个主要的通知，避免多次刷新导致重影
            NotificationCenter.default.post(
                name: NSNotification.Name("CommentsGenerated"),
                object: nil,
                userInfo: userInfo
            )
            
            // 🔧 优化：只更新数据，不强制触发多次刷新
            let viewModel = PostViewModel.shared
            if let postIndex = viewModel.posts.firstIndex(where: { $0.id.uuidString == postId }) {
                // 只触发一次 objectWillChange，让 SwiftUI 自然更新
                viewModel.posts[postIndex].objectWillChange.send()
            }
        }
    }
    
    /**
     * 直接将评论添加到帖子模型中，并处理点赞逻辑
     * 这是一个关键修复，确保评论在数据层面已经添加到帖子中
     * 🔧 第一性原理：使用串行队列确保对同一个帖子ID的操作是串行的，防止并发导致的重复
     * @param postId 帖子ID
     * @param commentsMap 角色ID到CharacterResponse的映射
     * @param requestContext 请求上下文，包含用户评论ID等信息
     */
    private func directlyAddCommentsToPost(postId: String, commentsMap: [String: CharacterResponse], requestContext: CommentRequestContext) {
        // 🔧 第一性原理：使用串行队列确保对同一个帖子ID的操作是串行的
        let queue = getQueue(for: postId)
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // 在主线程上执行，因为需要访问UI相关的数据
            DispatchQueue.main.async {
                self._directlyAddCommentsToPost(postId: postId, commentsMap: commentsMap, requestContext: requestContext)
            }
        }
    }
    
    /// 🔧 内部实现：实际执行添加评论的逻辑（必须在主线程调用）
    private func _directlyAddCommentsToPost(postId: String, commentsMap: [String: CharacterResponse], requestContext: CommentRequestContext) {
        let viewModel = PostViewModel.shared
        
        guard let postIndex = viewModel.posts.firstIndex(where: { $0.id.uuidString == postId }) else {
            #if DEBUG
            debugLog("❌ 未找到指定的帖子ID: \(postId)，无法直接添加评论")
            #endif
            return
        }
        
        // 创建评论模型并添加到帖子
        var newComments: [DetailedCommentModel] = []
        
        // 🔧 第一性原理：在开始处理前，先获取当前评论列表的快照，确保检查的一致性
        let currentCommentsSnapshot = viewModel.posts[postIndex].comments
        
        for (characterID, response) in commentsMap {
            // 🔧 修复：获取角色名称，优先从CharacterSystem获取用户创建的角色名称
            let characterName: String
            if characterID.hasPrefix("custom_") {
                // 用户创建的角色：从CharacterSystem获取名称
                let allCharacters = CharacterSystem.shared.getAllCharacters()
                if let customCharacter = allCharacters.first(where: { $0.id == characterID }) {
                    characterName = customCharacter.name
                } else {
                    // 如果CharacterSystem中没有，尝试从UserDefaults获取
                    // CustomCharactersData 的结构是 [[String: Any]]，是角色数组
                    if let data = UserDefaults.standard.data(forKey: "CustomCharactersData"),
                       let characterDicts = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                       let characterDict = characterDicts.first(where: { 
                           let id = $0["id"] as? String ?? ""
                           return id == characterID || id == characterID.replacingOccurrences(of: "custom_", with: "")
                       }),
                       let name = characterDict["name"] as? String {
                        characterName = name
                    } else {
                        // 如果都找不到，使用角色ID作为后备
                        characterName = characterID
                    }
                }
            } else {
                // 预设角色：使用CharacterDataManager
                characterName = characterDataManager.getAttribute(id: characterID, attribute: "name") ?? characterID
            }
            
            // 获取角色头像
            let avatarPath = CharacterAvatarService.shared.getAvatarName(for: characterID)
            
            // 🔧 第一性原理：检查是否已存在相同内容和角色的评论，避免重复添加
            // 使用快照进行检查，确保检查的一致性
            // 递归检查所有评论（包括回复），而不仅仅是顶级评论
            if hasExistingComment(characterID: characterID, content: response.content, in: currentCommentsSnapshot) {
                continue
            }
            
            // 创建评论模型，使用稍微延后的时间戳，确保虚拟角色回复在用户评论之后
            // 生成一个稍微晚于当前时间的时间戳（1-5秒之间的随机值）
            let randomOffset = Double.random(in: 1...5)
            let commentDate = Date().addingTimeInterval(randomOffset)
            
            // 🔧 关键修复：设置正确的父评论ID和回复对象
            // 如果这是对用户评论的回复，应该设置parentCommentId和replyToUsername
            let parentCommentId: UUID?
            let replyToUsername: String?
            
            if let userCommentId = requestContext.userCommentId {
                // 这是对用户评论的回复，设置父评论ID
                parentCommentId = UUID(uuidString: userCommentId)
                replyToUsername = "当前用户"
                #if DEBUG
                debugLog("🔧 设置虚拟角色回复的父评论ID: \(userCommentId)")
                #endif
            } else {
                // 这是邀请的虚拟角色评论，或者是虚拟角色对帖子的评论
                parentCommentId = nil
                replyToUsername = nil
                #if DEBUG
                debugLog("🔧 虚拟角色评论作为顶级评论（邀请评论或帖子评论）")
                #endif
            }
            
            // 🔧 优化：为每个评论生成稳定的ID，确保不会重复
            let commentId = UUID() // 每次生成新的唯一ID
            let comment = DetailedCommentModel(
                id: commentId, // 🔧 使用明确的ID
                username: characterName,
                userAvatar: avatarPath,
                content: response.content,
                datePosted: commentDate,
                isVirtualCharacter: true,
                characterID: characterID,
                parentCommentId: parentCommentId,
                replyToUsername: replyToUsername,
                likes: 0
            )
            
            // 处理点赞逻辑 - 🔧 使用传入的目标评论ID，确保点赞精确性
            // 延迟点赞，模拟虚拟角色先回复再点赞的真实行为
            if response.shouldLike {
                // 延迟2-8秒再进行点赞，模拟真实的点赞时机
                let likeDelay = Double.random(in: 2...8)
                
                if let userCommentId = requestContext.userCommentId {
                    // 有用户评论ID，说明是对用户评论的点赞
                    DispatchQueue.main.asyncAfter(deadline: .now() + likeDelay) {
                        VirtualCharacterLikeService.shared.processCharacterLike(
                            characterId: characterID,
                            postId: postId,
                            commentId: userCommentId,
                            userComment: requestContext.userComment
                        )
                    }
                } else {
                    // 没有用户评论ID，说明是虚拟角色对用户帖子的评论，应该对帖子点赞
                    DispatchQueue.main.asyncAfter(deadline: .now() + likeDelay) {
                        VirtualCharacterLikeService.shared.processPostLike(
                            characterId: characterID,
                            postId: postId,
                            userPostContent: requestContext.originalPost
                        )
                    }
                }
            }
            
            newComments.append(comment)
        }
        
        if newComments.isEmpty {
            #if DEBUG
            debugLog("⚠️ 没有新评论需要添加，所有评论都已存在")
            #endif
            return
        }
        
        // 🔧 第一性原理：批量添加评论，避免多次触发刷新
        // 关键：在添加前再次获取最新的评论列表，确保检查的是最新状态
        // 因为可能有其他线程/队列也在添加评论
        let currentComments = viewModel.posts[postIndex].comments
        let existingCommentIds = Set(currentComments.map { $0.id })
        
        // 🔧 第一性原理：双重检查，确保不会重复添加
        // 第一次检查：在创建评论之前（已在上面的循环中完成）
        // 第二次检查：在添加之前，再次检查（这里）
        let commentsToAdd = newComments.filter { comment in
            // 检查1：ID是否已存在
            if existingCommentIds.contains(comment.id) {
                return false
            }
            // 检查2：内容和角色ID的组合是否已存在（递归检查）
            if comment.isVirtualCharacter, let characterID = comment.characterID {
                if hasExistingComment(characterID: characterID, content: comment.content, in: currentComments) {
                    return false
                }
            }
            return true
        }
        
        if commentsToAdd.isEmpty {
            return
        }
        
        // 🔧 第一性原理：逐个添加评论，并在每次添加前再次检查，确保不会重复
        // 因为 addComment 方法内部也有检查，但我们需要在这里也做检查，双重保险
        // 关键：使用同步锁确保添加操作的原子性
        for comment in commentsToAdd {
            // 🔧 关键：在添加前再次检查，使用最新的评论列表
            // 因为可能有其他操作在同时进行（虽然使用了串行队列，但为了安全还是检查）
            let latestComments = viewModel.posts[postIndex].comments
            
            // 检查1：ID是否已存在
            if latestComments.contains(where: { $0.id == comment.id }) {
                continue
            }
            
            // 检查2：内容和角色ID的组合是否已存在
            if comment.isVirtualCharacter, let characterID = comment.characterID {
                if hasExistingComment(characterID: characterID, content: comment.content, in: latestComments) {
                    continue
                }
            }
            
            // 🔧 关键：调用 addComment，它内部也会检查，双重保险
            // addComment 方法内部有 hasDuplicateComment 检查，这是最后一道防线
            viewModel.posts[postIndex].addComment(comment)
        }
        
        // 🔧 重要修复：保存帖子数据到持久化存储
        NotificationCenter.default.post(
            name: NSNotification.Name("SavePostData"),
            object: nil,
            userInfo: ["postID": postId]
        )
        
    }
    
    // 🔧 优化：移除延迟刷新通知，避免多次刷新导致重影
    // 评论已经通过 directlyAddCommentsToPost 添加到数据模型中，
    // SwiftUI 会自动检测数据变化并更新视图，不需要额外的刷新通知
    
    /**
     * 🔧 第一性原理：递归检查是否存在相同内容和角色ID的评论
     * @param characterID 角色ID
     * @param content 评论内容
     * @param comments 评论列表（包括回复）
     * @return 是否存在重复评论
     */
    private func hasExistingComment(characterID: String, content: String, in comments: [DetailedCommentModel]) -> Bool {
        for comment in comments {
            // 检查当前评论
            if comment.isVirtualCharacter,
               comment.characterID == characterID,
               comment.content == content {
                        return true
            }
            
            // 递归检查回复
            if !comment.replies.isEmpty {
                if hasExistingComment(characterID: characterID, content: content, in: comment.replies) {
                    return true
                }
            }
        }
        return false
    }
    
    /**
     * 移除重复的评论
     * @param comments 评论列表
     * @return 去重后的评论列表
     */
    private func removeDuplicateComments(_ comments: [DetailedCommentModel]) -> [DetailedCommentModel] {
        var uniqueComments: [DetailedCommentModel] = []
        var seenContent: Set<String> = []
        
        // 遍历所有评论
        for comment in comments {
            // 创建唯一标识 - 使用内容和角色ID组合
            let uniqueKey = "\(comment.characterID ?? "")-\(comment.content)"
            
            // 如果这是一个新的评论（没有看到过相同的内容+角色组合）
            if !seenContent.contains(uniqueKey) {
                uniqueComments.append(comment)
                seenContent.insert(uniqueKey)
            } else {
                #if DEBUG
                debugLog("⚠️ 检测到重复评论，已跳过: \(comment.username)")
                #endif
            }
        }
        
        // 按时间排序，保持一致的排列方式（较新的评论在前）
        uniqueComments.sort { $0.datePosted > $1.datePosted }
        
        return uniqueComments
    }

    /**
     * 创建评论
     * @param content 评论内容
     * @param id 角色ID
     * @param name 角色名称
     * @param parentCommentId 父评论ID
     * @param replyToUsername 回复给谁
     * @return 评论模型
     */
    private func createComment(content: String, id: String, name: String, parentCommentId: UUID? = nil, replyToUsername: String? = nil) -> DetailedCommentModel {

        // **核心修复**: 统一使用CharacterAvatarService获取头像路径
        // 移除所有本地、硬编码的头像路径查找逻辑。
        // 这是解决问题的关键，确保所有角色的头像都通过唯一的、正确的服务获取。
        let avatarPath = CharacterAvatarService.shared.getAvatarName(for: id)
        #if DEBUG
        debugLog("✅ 使用 CharacterAvatarService 获取头像路径: ID '\(id)' -> Path '\(avatarPath)'")
        #endif
        
        let now = Date()
        let newComment = DetailedCommentModel(
            username: name,
            userAvatar: avatarPath, // 使用从服务获取的正确路径
            content: content,
            datePosted: now,
            isVirtualCharacter: true,
            characterID: id, // 使用原始ID
            parentCommentId: parentCommentId,
            replyToUsername: replyToUsername,
            likes: 0
        )
        
        #if DEBUG
        debugLog("✅ 成功创建评论: \(name), 头像路径: \(avatarPath)")
        #endif
        
        return newComment
    }
} 