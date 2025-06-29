import SwiftUI
import UIKit
import Combine
import Foundation

/**
 * 评论管理器
 * 
 * 负责处理评论的提交、回复和显示逻辑
 * 处理用户评论和虚拟角色回复
 */
class CommentManager: ObservableObject {
    // 当前帖子
    @Published var currentPost: UserPostModel
    // 所有评论（包括回复）
    @Published var allComments: [DetailedCommentModel] = []
    // 只包含顶级评论
    @Published var topLevelComments: [DetailedCommentModel] = []
    // 当前被回复的评论
    @Published var replyingToComment: DetailedCommentModel? = nil
    // 输入框内容
    @Published var commentText: String = ""
    
    // 用户信息
    private let currentUsername: String
    private let currentUserAvatar: String
    
    // 虚拟角色服务
    private let virtualCharacterService = VirtualCharacterService.shared
    
    // 取消订阅标记
    private var cancellables = Set<AnyCancellable>()
    
    /**
     * 初始化评论管理器
     * @param post 当前帖子
     * @param username 当前用户名
     * @param userAvatar 当前用户头像
     */
    init(post: UserPostModel, username: String = "当前用户", userAvatar: String = "user_avatar") {
        self.currentPost = post
        self.currentUsername = username
        self.currentUserAvatar = userAvatar
        
        // 初始化评论列表
        updateCommentLists()
    }
    
    /**
     * 更新评论列表
     * 分离顶级评论和所有回复，并按小红书风格处理评论层级
     */
    func updateCommentLists() {
        // 获取所有顶级评论（不包含回复）
        var topLevelResults: [DetailedCommentModel] = []
        
        // 创建一个字典，用于将回复分组到各自的主评论下
        var commentMap: [UUID: DetailedCommentModel] = [:]
        
        // 先找出所有主评论
        for comment in currentPost.comments {
            if comment.parentCommentId == nil {
                var commentCopy = comment
                commentCopy.replies = [] // 清空回复列表，后面重新组织
                commentMap[comment.id] = commentCopy
                topLevelResults.append(commentCopy)
            }
        }
        
        // 将所有回复添加到对应的主评论下
        // 小红书风格：所有回复都作为一级回复，通过replyToUsername标记回复关系
        for comment in currentPost.comments {
            if comment.parentCommentId != nil {
                // 找到顶级父评论
                if let rootComment = findRootComment(for: comment, in: currentPost.comments) {
                    if let index = topLevelResults.firstIndex(where: { $0.id == rootComment.id }) {
                        topLevelResults[index].replies.append(comment)
                    }
                }
            }
        }
        
        // 排序回复（按时间倒序，最新的在前面）
        for i in 0..<topLevelResults.count {
            topLevelResults[i].replies.sort { $0.datePosted > $1.datePosted }
        }
        
        // 更新顶级评论列表（按时间倒序，最新的在前面）
        self.topLevelComments = topLevelResults.sorted { $0.datePosted > $1.datePosted }
        
        // 创建包含所有评论和回复的扁平列表
        self.allComments = getAllCommentsFlattened()
    }
    
    /**
     * 查找评论的根评论（顶级评论）
     * 用于将多层嵌套的回复组织到正确的顶级评论下
     */
    private func findRootComment(for comment: DetailedCommentModel, in allComments: [DetailedCommentModel]) -> DetailedCommentModel? {
        // 如果没有父评论ID，则自身就是根评论
        if comment.parentCommentId == nil {
            return comment
        }
        
        // 查找父评论
        if let parentComment = allComments.first(where: { $0.id == comment.parentCommentId }) {
            // 递归查找根评论
            return findRootComment(for: parentComment, in: allComments)
        }
        
        return nil
    }
    
    /**
     * 获取所有评论和回复的扁平列表
     */
    private func getAllCommentsFlattened() -> [DetailedCommentModel] {
        var result: [DetailedCommentModel] = []
        
        // 添加所有顶级评论
        for comment in topLevelComments {
            result.append(comment)
            // 递归添加所有回复
            result.append(contentsOf: flattenReplies(comment.replies))
        }
        
        return result
    }
    
    /**
     * 递归扁平化回复列表
     */
    private func flattenReplies(_ replies: [DetailedCommentModel]) -> [DetailedCommentModel] {
        var result: [DetailedCommentModel] = []
        
        for reply in replies {
            result.append(reply)
            result.append(contentsOf: flattenReplies(reply.replies))
        }
        
        return result
    }
    
    /**
     * 提交评论
     * 用户提交普通评论或回复评论
     * 修改后每次提交都会触发虚拟角色回复
     */
    func submitComment() {
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // 处理评论内容
        let processedContent = commentText
        
        if let replyTo = replyingToComment {
            // 添加回复 - 如果有回复对象，直接使用replyToUsername参数，不需要在内容中添加@
            currentPost.addComment(
                username: currentUsername,
                userAvatar: currentUserAvatar,
                content: processedContent, // 不需要显式添加@前缀
                parentCommentId: replyTo.id,
                replyToUsername: replyTo.username // 使用回复对象的用户名
            )
        } else {
            // 添加顶级评论 - 无需特殊处理
            currentPost.addComment(
                username: currentUsername,
                userAvatar: currentUserAvatar,
                content: processedContent
            )
        }
        
        // 重置状态
        commentText = ""
        replyingToComment = nil
        
        // 更新评论列表
        updateCommentLists()
        
        // 生成虚拟角色回复
        // 对于每条用户评论，都进行回复生成
        Task {
            await generateVirtualReply()
        }
    }
    
    /**
     * 设置回复目标
     * @param comment 要回复的评论
     */
    func replyTo(comment: DetailedCommentModel) {
        self.replyingToComment = comment
        self.commentText = ""
    }
    
    /**
     * 取消回复
     * 清除当前回复目标
     */
    func cancelReply() {
        self.replyingToComment = nil
    }
    
    /**
     * 生成虚拟角色回复
     * 优先选择帖子作者对最新评论做出回复，否则随机选择其他虚拟角色
     * 修改为支持对每条评论都做出回复，并确保回复不会太相似
     * 并且避免同一个角色对同一用户的不同评论进行重复回复
     * 帖子作者只回复一次，给其他虚拟角色留出回复空间
     */
    @MainActor
    func generateVirtualReply() async {
        // 获取最新评论
        guard let latestComment = allComments.max(by: { $0.datePosted < $1.datePosted }) else {
            return
        }
        
        // 如果最新评论来自虚拟角色，不进行回复
        if latestComment.isVirtualCharacter {
            print("🤖 最新评论来自虚拟角色，跳过回复")
            return
        }
        
        // 保存最新评论ID，确保回复到正确位置
        let targetCommentID = latestComment.id
        let targetUsername = latestComment.username
        
        print("⭐️ 生成回复目标 - 评论ID: \(targetCommentID), 用户: \(targetUsername), 内容: \"\(latestComment.content.prefix(20))...\"")
        
        // 检查评论中是否包含@特定角色
        let mentionedCharacter = checkForMentionedCharacter(in: latestComment.content)
        
        // 获取帖子作者
        let postAuthorName = currentPost.username
        var authorCharacterId: String? = nil
        
        // 角色名称及其ID映射
        let characterMapping: [String: String] = [
            "爱因斯坦": "einstein",
            "莎士比亚": "shakespeare",
            "达芬奇": "davinci",
            "孔子": "confucius",
            "居里夫人": "curie",
            "李白": "libai"
        ]
        
        // 反向映射，通过ID获取名称
        let characterNames: [String: String] = [
            "einstein": "爱因斯坦",
            "shakespeare": "莎士比亚",
            "davinci": "达芬奇",
            "confucius": "孔子",
            "curie": "居里夫人",
            "libai": "李白"
        ]
        
        // 检查帖子作者是否为虚拟角色
        var isAuthorVirtualCharacter = false
        for (name, id) in characterMapping {
            if name == postAuthorName {
                isAuthorVirtualCharacter = true
                authorCharacterId = id
                break
            }
        }
        
        print("👤 帖子作者: \(postAuthorName), 是否虚拟角色: \(isAuthorVirtualCharacter), 角色ID: \(authorCharacterId ?? "无")")
        
        // 用户ID - 使用用户名作为标识
        let userId = latestComment.username
        
        // 获取该用户已收到回复的角色列表
        let userRepliedCharactersKey = "user_\(userId)_replied_characters"
        var repliedCharacters = UserDefaults.standard.stringArray(forKey: userRepliedCharactersKey) ?? []
        
        // 决定哪个角色会回复
        var selectedCharacter: String? = nil
        
        if let mentioned = mentionedCharacter {
            // 如果@了特定角色，该角色100%会回复
            selectedCharacter = mentioned
            print("👥 检测到@提及角色: \(characterNames[mentioned] ?? mentioned)")
        } else if isAuthorVirtualCharacter, let authorId = authorCharacterId {
            // 检查帖子作者是否已经回复过这条评论
            let commentAuthorReplyKey = "author_replied_\(latestComment.id.uuidString)"
            let hasAuthorReplied = UserDefaults.standard.bool(forKey: commentAuthorReplyKey)
            
            if hasAuthorReplied {
                // 如果帖子作者已回复过，随机选择其他角色
                print("👑 帖子作者已经回复过此评论，让其他角色回复")
                // 过滤掉作者角色
                let otherCharacters = Array(characterMapping.values).filter { $0 != authorId }
                // 过滤掉已经回复过的角色
                var unusedCharacters = otherCharacters.filter { !repliedCharacters.contains($0) }
                
                if unusedCharacters.isEmpty {
                    // 如果所有角色都已经回复过，则重置列表（但仍排除作者）
                    unusedCharacters = otherCharacters
                    // 仅保留作者在已回复列表中
                    repliedCharacters = repliedCharacters.filter { $0 == authorId }
                    print("🔄 所有非作者角色都已回复过，重置角色列表")
                }
                
                selectedCharacter = unusedCharacters.randomElement()
            } else {
                // 帖子作者首次回复此评论
                selectedCharacter = authorId
                print("👑 帖子作者是虚拟角色，将由作者回复此评论")
                // 标记作者已回复此评论
                UserDefaults.standard.set(true, forKey: commentAuthorReplyKey)
            }
        } else {
            // 获取所有可用角色
            let availableCharacters = Array(characterMapping.values)
            
            // 过滤出未回复过该用户的角色
            var unusedCharacters = availableCharacters.filter { !repliedCharacters.contains($0) }
            
            if unusedCharacters.isEmpty {
                // 如果所有角色都已经回复过，则重置已回复列表
                unusedCharacters = availableCharacters
                repliedCharacters = []
                print("🔄 所有角色都已回复过此用户，重置角色列表")
            }
            
            // 从未使用过的角色中随机选择
            selectedCharacter = unusedCharacters.randomElement()
            print("🎲 选择新角色回复: \(characterNames[selectedCharacter ?? ""] ?? "未知角色")")
        }
        
        // 确保有选定的角色
        guard let character = selectedCharacter else {
            print("❌ 没有可用的虚拟角色进行回复")
            return
        }
        
        // 记录该角色已经回复过此用户
        if !repliedCharacters.contains(character) {
            repliedCharacters.append(character)
            UserDefaults.standard.set(repliedCharacters, forKey: userRepliedCharactersKey)
        }
        
        // 记录用户评论，用于跟踪历史
        let userCommentKey = "\(character)_latest_user_comment"
        let previousUserComment = UserDefaults.standard.string(forKey: userCommentKey)
        
        // 记录角色回复，用于避免相似回复
        let characterReplyKey = "\(character)_latest_replies"
        var previousReplies = UserDefaults.standard.stringArray(forKey: characterReplyKey) ?? []
        
        print("🔍 检查是否需要回复 - 角色ID: \(character), 角色名: \(characterNames[character] ?? "未知")")
        
        // 生成虚拟角色回复
        do {
            // 判断是否需要添加额外上下文来避免相似回复
            var additionalPromptContext = ""
            
            // 如果有之前的评论和回复记录，添加到提示词中
            if let prevComment = previousUserComment, !previousReplies.isEmpty {
                additionalPromptContext = "\n\n前一次评论: \"\(prevComment)\"\n"
                additionalPromptContext += "你的回复: \"\(previousReplies.first ?? "")\"\n"
                additionalPromptContext += "请确保这次的回复与之前不同，使用新的表达方式和角度。"
            }
            
            // 添加模拟打字延迟
            // 延迟0.5-2秒之间的随机时间，模拟思考和打字时间
            try await Task.sleep(nanoseconds: UInt64(Double.random(in: 0.5...2.0) * 1_000_000_000))
            
            // 增强提示词，使回复更针对用户评论
            let enhancedPrompt = """
            \(latestComment.content)\(additionalPromptContext)

            请注意：
            1. 你必须直接回应用户评论的实际内容，不要泛泛而谈或自说自话
            2. 绝对禁止使用括号描述动作或思考过程，如"(用笔轻敲)"、"(微笑着)"、"(思考中)"等
            3. 每一句话都必须与用户评论直接相关，而不是展示你自己的角色特点
            4. 不得使用任何与用户评论无关的比喻或概念，无论多么有特色
            5. 如果用户评论是"哈哈"或其他简短感叹，直接用简单幽默的一句话响应
            6. 避免所有专业术语、行业术语，使用日常对话语言
            7. 假设自己是在社交媒体上回复普通朋友，而不是在展示你的独特身份
            8. 严格禁止在回复中加入任何括号内的解释、分析或理论
            9. 不要解释你的回复逻辑或创作过程
            10. 不要在回复前后或中间添加任何形式的注释
            """ + (latestComment.content.count <= 15 ? """
            
            特别重要警告：
            用户评论非常简短，你必须简短直接地回应！
            - 不要使用括号中的动作描述或思考过程，直接说话
            - 禁止使用任何复杂比喻或术语
            - 禁止自我介绍或强调身份
            - 禁止提及与用户评论无关的概念
            - 回复必须在20字以内
            - 就像普通人回复"哈哈"或"说得好"一样自然
            - 你可以表现出一点个性，但首要任务是自然、相关的回应
            """ : "")
            
            // 使用API生成回复
            var content = try await withCheckedThrowingContinuation { continuation in
                virtualCharacterService.generateCharacterComment(
                    characterID: character,
                    userComment: enhancedPrompt,
                    postContent: currentPost.content
                ) { result in
                    switch result {
                    case .success(let content):
                        continuation.resume(returning: content)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            // 过滤掉可能出现的括号内容
            content = cleanResponseContent(content)
            
            print("✅ API生成回复成功: \(content.prefix(50))...")
            
            // 记录本次用户评论和角色回复
            UserDefaults.standard.set(latestComment.content, forKey: userCommentKey)
            
            // 最多保存最近3条回复历史
            previousReplies.insert(content, at: 0)
            if previousReplies.count > 3 {
                previousReplies = Array(previousReplies.prefix(3))
            }
            UserDefaults.standard.set(previousReplies, forKey: characterReplyKey)
            
            await MainActor.run {
                // 添加虚拟角色回复 - 确保使用保存的targetCommentID而不是再次引用latestComment
                currentPost.addComment(
                    username: characterNames[character] ?? character,
                    userAvatar: getCharacterAvatar(for: character),
                    content: content,
                    parentCommentId: targetCommentID,  // 使用之前保存的ID，确保回复指向正确评论
                    replyToUsername: targetUsername,   // 使用之前保存的用户名
                    replyToName: targetUsername,      // 添加replyToName字段
                    isVirtualCharacter: true,
                    characterID: character
                )
                
                // 更新评论列表
                updateCommentLists()
                
                print("✅ 虚拟角色回复已添加 - 角色: \(characterNames[character] ?? character), 回复给: \(targetUsername), 评论ID: \(targetCommentID)")
                
                // 不再在帖子作者回复后额外生成其他角色评论
                // 当帖子作者和选定角色相同时，其他角色回复由下次用户触发
            }
        } catch {
            print("❌ API生成回复失败: \(error.localizedDescription)")
        }
    }
    
    /**
     * 获取角色头像
     * @param characterID 角色ID
     * @return 角色头像系统图标名称
     */
    private func getCharacterAvatar(for characterID: String) -> String {
        switch characterID.lowercased() {
        case "einstein":
            return "atom" // 原子图标适合爱因斯坦
        case "shakespeare":
            return "book.fill" // 书籍图标适合莎士比亚
        case "davinci":
            return "paintpalette.fill" // 绘画图标适合达芬奇
        case "confucius":
            return "scroll.fill" // 卷轴适合孔子
        case "libai":
            return "text.book.closed.fill" // 诗集适合李白
        case "curie":
            return "sparkles" // 闪光适合居里夫人
        default:
            return "person.circle.fill" // 通用人物图标
        }
    }
    
    /**
     * 检查评论中是否@了特定的虚拟角色
     * @param content 评论内容
     * @return 被@的角色ID，如果没有则返回nil
     */
    private func checkForMentionedCharacter(in content: String) -> String? {
        // 角色名称及其ID映射
        let characterMapping: [String: String] = [
            "爱因斯坦": "einstein",
            "莎士比亚": "shakespeare",
            "达芬奇": "davinci",
            "孔子": "confucius",
            "居里夫人": "curie",
            "李白": "libai"
        ]
        
        // 检查评论中是否包含@角色名
        for (characterName, characterId) in characterMapping {
            if content.contains("@\(characterName)") {
                return characterId
            }
        }
        
        return nil
    }
    
    // 获取角色名称
    private func getCharacterName(for characterId: String) -> String {
        let characterNames: [String: String] = [
            "einstein": "爱因斯坦",
            "shakespeare": "莎士比亚",
            "davinci": "达芬奇",
            "confucius": "孔子",
            "curie": "居里夫人",
            "libai": "李白"
        ]
        
        return characterNames[characterId] ?? characterId
    }
    
    /**
     * 清理回复内容，移除括号中的内容和其他不需要的元素
     * @param content 原始回复内容
     * @return 清理后的内容
     */
    private func cleanResponseContent(_ content: String) -> String {
        var cleanedContent = content
        
        // 移除所有括号及其中的内容，支持中文和英文括号
        let bracketPatterns = [
            "\\([^\\)]*\\)",             // 英文小括号 (...)
            "（[^）]*）",                 // 中文小括号 （...）
            "\\[[^\\]]*\\]",             // 英文中括号 [...]
            "【[^】]*】",                // 中文中括号 【...】
            "\\{[^\\}]*\\}",             // 英文大括号 {...}
            "｛[^｝]*｝"                  // 中文大括号 ｛...｝
        ]
        
        for pattern in bracketPatterns {
            cleanedContent = cleanedContent.replacingOccurrences(
                of: pattern,
                with: "",
                options: .regularExpression
            )
        }
        
        // 移除多余的空格和换行
        cleanedContent = cleanedContent.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        cleanedContent = cleanedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果清理后内容为空，返回一个默认回复
        if cleanedContent.isEmpty {
            cleanedContent = "我明白你的意思。"
        }
        
        return cleanedContent
    }
    
    /**
     * 生成强化提示，以提升回复质量
     * - Parameters:
     *   - comment: 用户评论
     *   - characterID: 角色ID
     *   - traits: 角色特性
     * - Returns: 强化后的提示
     */
    func enhancedPrompt(for comment: DetailedCommentModel, characterID: String, traits: AIPromptCharacterTraits) -> String {
        let commentContent = comment.content
        
        // 检查评论长度，如果非常短，则使用简短回复策略
        if commentContent.count <= 10 {
            // 对于特别短的评论（如"哈哈哈"、"666"等），给出更直接的指导
            let shortCommentPrompt = """
            用户发送了一条简短评论: "\(commentContent)"
            
            作为回复指南：
            1. 直接针对这条评论做出简短自然的回应，就像正常人一样
            2. 禁止使用任何角色扮演式的描述，如"(微笑)"、"(思考中)"等
            3. 不要过度表现你的历史人物身份，就像普通朋友间的对话
            4. 回复必须与用户的评论直接相关，不要自说自话
            5. 如果用户发送的是笑声或表情，请用同样轻松的语气回应
            6. 完全禁止使用括号内的动作描述或思考过程说明
            7. 回复控制在15字以内，越简短越好
            8. 绝对不要使用括号解释你的回复理由
            
            示例：
            用户: "哈哈哈哈"
            不好的回复: "(用羽毛笔蘸墨) 笑声是最美的音符呢"
            好的回复: "看到你开心，我也笑了"
            
            用户: "666"
            不好的回复: "(调整望远镜) 数字背后藏着宇宙的奥秘"
            好的回复: "谢谢夸奖，你真好"
            
            记住：回复必须自然、相关、简短，像普通人一样说话，不要故意表现得很特别。
            绝对不要在任何地方使用括号来解释你的回复思路或理论。
            """
            return shortCommentPrompt
        }
        
        let basePrompt = """
        以下是用户对你的评论: "\(commentContent)"
        
        请以\(traits.description)的风格，作为\(traits.name)回复这条评论。
        
        回复要求:
        1. 必须直接针对用户评论的具体内容作出回应，不要泛泛而谈
        2. 严格禁止使用任何括号中的内容，如"(思考中)"、"(微笑)"、"(以XX理论分析)"等
        3. 不要过度"扮演"你的角色，而是自然地表达观点
        4. 回复应该与用户评论保持紧密的话题相关性
        5. 使用现代通俗语言，避免晦涩难懂的专业术语
        6. 回复长度应适中，通常不超过50字
        7. 绝对不要解释你的回复思路或理论依据
        8. 不要在回复中添加任何形式的注释
        
        记住：始终保持对用户评论内容的直接回应，不要自说自话或离题。
        你的回复将直接发送给用户，不需要任何附加说明或解释，就像普通人在社交平台上的对话。
        """
        
        // 如果评论来自当前用户，添加额外的提示以确保回复的相关性
        if comment.username == currentUsername {
            return basePrompt + """
            
            额外提醒：这条评论来自与你正在交流的用户，请确保你的回复与用户评论有明确的关联，不要漫无目的地展示你的角色特点。
            绝对不要使用任何括号内的内容，如注释、解释或理论分析。
            """
        }
        
        return basePrompt
    }
}

/**
 * 预览
 */
struct CommentManager_Previews: PreviewProvider {
    static var previews: some View {
        // 创建一个临时视图来包装CommentManager
        VStack {
            Text("评论管理器预览")
                .font(.headline)
                .padding()
            
            Spacer()
            
            Text("CommentManager不是一个View，但已初始化为：")
                .font(.footnote)
                .foregroundColor(.gray)
            
            Text("CommentManager(post: ModelData.samplePosts[0])")
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
        .frame(height: 200)
        .onAppear {
            // 初始化CommentManager但不显示
            let _ = CommentManager(post: ModelData.samplePosts[0])
        }
    }
}
