import Foundation
import Combine
import UIKit

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
    private var cancellables = Set<AnyCancellable>()
    
    // 私有初始化方法
    private init() {}
    
    /**
     * 批量生成多个角色的评论
     * @param characterIDs 角色ID列表
     * @param postId 帖子ID
     * @param postContent 帖子内容
     * @param postAuthor 帖子作者
     * @param userComment 用户评论内容，用于生成针对性回复
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
        targetUsername: String? = nil,
        authorCharacterId: String? = nil,
        isInvited: Bool = false,
        completion: @escaping (Result<[String: String], Error>) -> Void
    ) {
        print("🚀 开始批量生成角色评论 - 共\(characterIDs.count)个角色")
        
        // 如果没有角色，直接返回空结果
        if characterIDs.isEmpty {
            completion(.success([:]))
            return
        }
        
        // 创建后台任务，确保即使用户退出页面也能完成API调用
        let backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            print("⚠️ MultiCharacterCommentService: 批量生成角色评论的后台任务超时")
        }
        
        // 构建批量提示词
        let batchPrompt = buildBatchPrompt(
            characterIDs: characterIDs,
            postContent: postContent,
            postAuthor: postAuthor,
            userComment: userComment,
            targetUsername: targetUsername,
            authorCharacterId: authorCharacterId,
            isInvited: isInvited
        )
        
        print("📤 准备发送批量API请求 - 提示词长度: \(batchPrompt.count)字符")
        
        // 添加超时保护
        let timeoutInterval: TimeInterval = 60.0
        let timer = Timer.publish(every: timeoutInterval, on: .main, in: .common).autoconnect()
        var timerCancellable: AnyCancellable?
        
        timerCancellable = timer
            .sink { _ in
                print("⚠️ 批量生成评论请求超时")
                timerCancellable?.cancel()
                
                // 在主线程上调用完成回调
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "MultiCharacterCommentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "请求超时"])))
                }
                
                // 结束后台任务
                if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(backgroundTaskID)
                }
            }
        
        // 调用API生成批量评论
        AINetworkService.shared.sendRequest(prompt: batchPrompt)
            .sink(
                receiveCompletion: { completionStatus in
                    // 取消超时计时器
                    timerCancellable?.cancel()
                    
                    // 在任务完成时结束后台任务
                    if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                        UIApplication.shared.endBackgroundTask(backgroundTaskID)
                        print("🏁 MultiCharacterCommentService: 批量角色评论生成任务已完成，后台任务结束")
                    }
                    
                    if case .failure(let error) = completionStatus {
                        print("❌ 批量生成角色评论失败: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                },
                receiveValue: { output in
                    // 取消超时计时器
                    timerCancellable?.cancel()
                    
                    print("✅ 批量API返回成功!")
                    
                    // 解析API返回的批量评论结果
                    let commentsMap = self.parseAPIResponse(response: output, characterIDs: characterIDs)
                    
                    // 检查是否有角色的评论未能成功解析
                    let missingCharacters = characterIDs.filter { !commentsMap.keys.contains($0) }
                    
                    if !missingCharacters.isEmpty && commentsMap.isEmpty {
                        // 如果所有角色都没有成功解析，返回错误
                        print("❌ 批量评论生成失败: 无法解析任何角色的评论")
                        completion(.failure(NSError(domain: "MultiCharacterCommentService", code: -2, userInfo: [NSLocalizedDescriptionKey: "评论解析失败"])))
                        return
                    } else if !missingCharacters.isEmpty {
                        // 如果部分角色没有成功解析，记录日志
                        print("⚠️ 部分角色评论未能解析: \(missingCharacters.joined(separator: ", "))")
                    }
                    
                    // 添加评论到帖子
                    self.addCommentsToPost(commentsMap: commentsMap, characterIDs: characterIDs, postId: postId, isInvited: isInvited)
                    
                    print("✅ 批量评论生成完成，成功解析\(commentsMap.count)个角色的评论")
                    completion(.success(commentsMap))
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
        isInvited: Bool = false
    ) -> String {
        // 收集角色信息，包括名称、性格特点和专业领域
        let characterInfo = characterIDs.map { id -> String in
            let name = characterDataManager.getName(for: id) ?? id.capitalized
            
            // 标记是否为帖子作者
            let isAuthor = id == authorCharacterId
            let authorMark = isAuthor ? "（帖子作者）" : ""
            
            // 尝试获取角色的性格特点
            var traits = ""
            if let personality = personalityManager.getPersonality(for: id) {
                let tone = personality.tone
                let knowledgeAreas = personality.knowledgeAreas.joined(separator: "、")
                traits = "（性格特点：\(tone)，专业领域：\(knowledgeAreas)）"
            }
            
            return "- \(name) (ID: \(id)) \(authorMark) \(traits)"
        }.joined(separator: "\n")
        
        // 获取帖子作者信息 - 如果提供了作者名称则使用，否则使用默认值
        let authorInfo = postAuthor ?? "帖子作者"
        print("👤 使用帖子作者: \(authorInfo)")
        
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
                print("⚠️ 帖子作者ID不在角色列表中，将其添加到列表开头")
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
            
            请按照以下格式生成选定角色的回复：

            [角色ID]
            这里是该角色的评论内容...

            [下一个角色ID]
            这里是下一个角色的评论内容...
            """
            
            // 如果有作者角色，强调必须首先生成作者的回复
            if let authorId = authorCharacterId, characterIDs.contains(authorId) {
                let authorName = characterDataManager.getName(for: authorId) ?? authorId.capitalized
                prompt += """

                特别注意：
                - 必须首先生成帖子作者"\(authorName)"的回复，格式为：
                  [\(authorId)]
                  这里是作者的回复内容...
                - 然后再生成其他角色的回复
                """
            }
            
            prompt += """

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
            10. 称呼用户时，避免直接使用用户名"\(targetUsername)"，而应使用更自然的方式：
                - 可以使用"朋友"、"你"等自然的称呼
                - 如果是回复问题，可以直接回答而不称呼
                - 如果是对话，可以用"您"表示尊重
                - 避免机械地重复用户名
            11. 使用通俗易懂的语言，避免晦涩难懂的表达
            12. 不要使用专业术语或高深理论，确保普通用户能理解

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
            """
        } else {
            // 原始提示词（针对帖子内容的回复）
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
            9. 称呼作者时，避免机械地重复作者名，可以使用更自然的方式：
               - 可以使用"朋友"、"博主"等自然的称呼
               - 如果是回应观点，可以直接评论而不称呼
               - 如需称呼，使用"您"表示尊重
            10. 使用通俗易懂的语言，避免晦涩难懂的表达
            11. 不要使用专业术语或高深理论，确保普通用户能理解

            绝对禁止事项（必须严格遵守）：
            1. 严格禁止添加任何形式的注释、解释或理论分析
            2. 严格禁止在评论后添加"注："或类似的解释说明
            3. 严格禁止在评论中使用括号添加额外说明，如"(微笑)"、"(思考中)"等
            4. 严格禁止使用"PS:"、"补充:"等形式添加额外内容
            5. 评论必须是纯粹的内容，绝对不能包含任何元解释或元分析
            6. 严格禁止对评论内容进行自我解释或说明
            7. 严格禁止在评论中添加学术引用、出处或参考资料
            8. 评论必须是角色直接表达的内容，不允许有任何额外的解释层
            """
        }
        
        print("📋 构建批量提示词，包含\(characterIDs.count)个角色")
        return prompt
    }
    
    /**
     * 解析API响应
     * @param response API返回的响应内容
     * @param characterIDs 角色ID列表
     * @return 角色ID到评论内容的映射
     */
    private func parseAPIResponse(response: String, characterIDs: [String]) -> [String: String] {
        print("🔍 开始解析批量API响应")
        print("📄 原始响应内容预览: \(response.prefix(100))...")
        
        var result = [String: String]()
        var currentCharacterId: String? = nil
        var currentComment = ""
        
        // 将响应按行分割
        let lines = response.components(separatedBy: .newlines)
        
        // 规范化角色ID列表（全部转为小写）以便于比较
        let normalizedCharacterIDs = characterIDs.map { $0.lowercased() }
        
        print("📋 待解析角色ID: \(characterIDs.joined(separator: ", "))")
        print("📊 总行数: \(lines.count)")
        
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
                    result[id] = currentComment.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("✓ 已解析角色评论: \(id), 长度: \(result[id]?.count ?? 0)字符")
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
                    print("✓ 找到角色评论标记[方括号]: \(originalId)")
                } else {
                    currentCharacterId = nil
                    print("⚠️ 找到未知角色ID: \(extractedId)，已忽略")
                }
            }
            // 检查是否是角色ID标记行 - 方式2：单独一行的角色ID
            else if normalizedCharacterIDs.contains(trimmedLine.lowercased()) {
                // 保存之前处理的角色评论
                if let id = currentCharacterId, !currentComment.isEmpty {
                    result[id] = currentComment.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("✓ 已解析角色评论: \(id), 长度: \(result[id]?.count ?? 0)字符")
                    currentComment = ""
                }
                
                // 使用原始大小写的ID作为键
                let originalId = characterIDs.first { $0.lowercased() == trimmedLine.lowercased() } ?? trimmedLine
                currentCharacterId = originalId
                print("✓ 找到角色评论标记[直接ID]: \(originalId)")
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
                        result[id] = currentComment.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("✓ 已解析角色评论: \(id), 长度: \(result[id]?.count ?? 0)字符")
                        currentComment = ""
                    }
                    
                    // 设置新的角色ID
                    let originalId = characterIDs.first { $0.lowercased() == potentialCharacterId } ?? trimmedLine
                    currentCharacterId = originalId
                    print("✓ 找到角色评论标记[内容中]: \(originalId)")
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
            result[id] = currentComment.trimmingCharacters(in: .whitespacesAndNewlines)
            print("✓ 已解析最后一个角色评论: \(id), 长度: \(result[id]?.count ?? 0)字符")
        }
        
        // 输出解析结果统计
        print("📊 解析结果: 成功解析\(result.count)/\(characterIDs.count)个角色的评论")
        
        // 如果标准解析方法失败，尝试使用后备方法
        if result.isEmpty {
            print("⚠️ 标准解析方法未能提取任何评论，尝试使用后备解析方法")
            result = fallbackParseResponse(response: response, characterIDs: characterIDs)
        }
        
        // 尝试处理缺失的角色
        let missingCharacters = characterIDs.filter { !result.keys.contains($0) }
        if !missingCharacters.isEmpty {
            print("⚠️ 以下角色的评论未能解析: \(missingCharacters.joined(separator: ", "))")
            
            // 检查是否有帖子作者在缺失列表中
            if let authorId = characterIDs.first, missingCharacters.contains(authorId) {
                print("❗️ 警告: 帖子作者的评论未能解析")
            }
        }
        
        return result
    }

    /**
     * 后备解析方法 - 尝试使用更简单的方式解析API响应
     * 适用于无法通过标准方式解析的情况
     */
    private func fallbackParseResponse(response: String, characterIDs: [String]) -> [String: String] {
        print("🔄 使用后备解析方法")
        var result = [String: String]()
        
        // 规范化角色ID列表（全部转为小写）以便于比较
        let normalizedCharacterIDs = characterIDs.map { $0.lowercased() }
        
        // 尝试方法1：按照空行分割响应，然后检查每个块的第一行是否是角色ID
        let blocks = response.components(separatedBy: "\n\n")
        print("📊 后备解析：找到\(blocks.count)个文本块")
        
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
                        result[originalId] = comment
                        print("✓ 后备方法解析到角色评论: \(originalId), 长度: \(comment.count)字符")
                    }
                    break
                }
            }
        }
        
        // 如果方法1失败，尝试方法2：使用正则表达式查找角色ID和评论
        if result.isEmpty && !characterIDs.isEmpty {
            print("🔄 后备解析方法1失败，尝试方法2")
            
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
                                result[characterId] = commentText
                                print("✓ 后备方法2解析到角色评论: \(characterId), 长度: \(commentText.count)字符")
                                break
                            }
                        }
                    }
                }
            }
        }
        
        print("📊 后备解析结果: 成功解析\(result.count)/\(characterIDs.count)个角色的评论")
        return result
    }
    
    /**
     * 将评论添加到帖子
     * @param commentsMap 角色ID到评论内容的映射
     * @param characterIDs 角色ID列表
     * @param postId 帖子ID
     * @param isInvited 是否为邀请的角色评论，默认为false
     */
    private func addCommentsToPost(commentsMap: [String: String], characterIDs: [String], postId: String, isInvited: Bool = false) {
        // 获取帖子数据
        let viewModel = PostViewModel.shared
        
        // 查找对应帖子
        guard viewModel.posts.firstIndex(where: { $0.id.uuidString == postId }) != nil else {
            print("❌ 未找到指定的帖子ID: \(postId)")
            return
        }
        
        // 检查帖子作者是否在列表中但未返回评论
        if !isInvited && characterIDs.count > 0 {
            let authorId = characterIDs[0]
            if !commentsMap.keys.contains(authorId) {
                print("⚠️ 帖子作者(\(authorId))的评论未在API返回结果中，将添加默认回复")
                
                // 创建一个修改后的评论映射，包含作者的默认回复
                var updatedCommentsMap = commentsMap
                updatedCommentsMap[authorId] = "感谢你的评论，很高兴看到你的想法。"
                
                // 使用更新后的映射发送通知
                sendCommentsNotifications(postId: postId, commentsMap: updatedCommentsMap, isInvited: isInvited)
                return
            }
        }
        
        // 使用原始映射发送通知
        sendCommentsNotifications(postId: postId, commentsMap: commentsMap, isInvited: isInvited)
    }

    /**
     * 发送评论相关通知
     * @param postId 帖子ID
     * @param commentsMap 角色ID到评论内容的映射
     * @param isInvited 是否为邀请的角色评论
     */
    private func sendCommentsNotifications(postId: String, commentsMap: [String: String], isInvited: Bool) {
        DispatchQueue.main.async {
            // 生成一个唯一的批次ID，用于区分不同的评论批次
            let batchId = UUID().uuidString
            
            // 发送通知，包含生成的评论内容映射
            NotificationCenter.default.post(
                name: NSNotification.Name("CommentsGenerated"),
                object: nil,
                userInfo: [
                    "postID": postId,
                    "commentsMap": commentsMap,
                    "isInvited": isInvited,  // 添加标记表明是否为邀请的角色评论
                    "batchId": batchId       // 添加批次ID
                ]
            )
            
            // 直接触发 PostViewModel 中的帖子刷新
            let viewModel = PostViewModel.shared
            if let postIndex = viewModel.posts.firstIndex(where: { $0.id.uuidString == postId }) {
                // 强制触发 objectWillChange 通知
                viewModel.posts[postIndex].objectWillChange.send()
                
                // 额外的强制刷新，确保 SwiftUI 视图更新
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // 创建一个临时副本并重新赋值，强制 SwiftUI 刷新
                    let tempPost = viewModel.posts[postIndex]
                    viewModel.posts[postIndex] = tempPost
                    
            // 发送评论更新通知
            NotificationCenter.default.post(
                name: NSNotification.Name("PostCommentsUpdated"),
                object: nil,
                userInfo: ["postID": postId, "batchId": batchId]
            )
            
            // 确保UI刷新
            NotificationCenter.default.post(
                name: NSNotification.Name("RefreshPostComments"),
                        object: nil,
                        userInfo: [
                            "postID": postId, 
                            "batchId": batchId,
                            "immediateDisplay": true,
                            "preventScroll": true
                        ]
                    )
                    
                    // 添加额外的强制刷新通知，确保评论立即显示
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ForceRefreshComments"),
                        object: nil,
                        userInfo: [
                            "keepExpandState": true,
                            "preventScroll": true,
                            "immediateDisplay": true
                        ]
                    )
                }
            } else {
                // 如果找不到帖子，仍然发送常规通知
                // 发送评论更新通知
                NotificationCenter.default.post(
                    name: NSNotification.Name("PostCommentsUpdated"),
                object: nil,
                userInfo: ["postID": postId, "batchId": batchId]
            )
                
                // 确保UI刷新
                NotificationCenter.default.post(
                    name: NSNotification.Name("RefreshPostComments"),
                    object: nil,
                    userInfo: [
                        "postID": postId, 
                        "batchId": batchId,
                        "immediateDisplay": true,
                        "preventScroll": true
                    ]
                )
                
                // 添加额外的强制刷新通知，确保评论立即显示
                NotificationCenter.default.post(
                    name: NSNotification.Name("ForceRefreshComments"),
                    object: nil,
                    userInfo: [
                        "keepExpandState": true,
                        "preventScroll": true,
                        "immediateDisplay": true
                    ]
                )
            }
            
            print("📣 已发送所有通知，批量评论内容已生成，批次ID: \(batchId)")
        }
    }
} 