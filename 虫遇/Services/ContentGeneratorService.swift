import Foundation
import Combine

/**
 * 内容生成服务
 * 整合角色系统和内容生成系统，提供统一的内容生成接口
 */
class ContentGeneratorService {
    // 单例模式
    static let shared = ContentGeneratorService()
    private init() {}
    
    // 依赖服务
    private let characterSystem = CharacterSystem.shared
    private let aiContentGenerator = AIContentGenerator.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    // 内容类型枚举
    enum ContentType: String, CaseIterable {
        case resonance = "虫洞共鸣"
        case mood = "日常心情"
        case ancient2modern = "古潮新语"
        case creativeIdea = "穿越吐槽"
        case timelineEvent = "时空记事"
    }
    
    /**
     * 评论存储类 - 用于管理和存储不同内容项的评论
     */
    class CommentStore {
        // 单例实例
        static let shared = CommentStore()
        
        // 评论存储 - 以内容项ID为键
        private var commentsMap: [String: [CommentItem]] = [:]
        
        // 私有初始化方法确保单例模式
        private init() {}
        
        /**
         * 保存评论
         * @param comments 评论数组
         * @param forContentID 内容项ID
         */
        func saveComments(_ comments: [CommentItem], forContentID contentID: String) {
            commentsMap[contentID] = comments
            print("📦 已保存\(comments.count)条评论，内容ID: \(contentID)")
        }
        
        /**
         * 批量保存评论
         * @param commentsMap 评论映射表 [内容项ID: 评论数组]
         */
        func saveComments(_ commentsMap: [String: [CommentItem]]) {
            for (contentID, comments) in commentsMap {
                self.commentsMap[contentID] = comments
                print("📦 已批量保存\(comments.count)条评论，内容ID: \(contentID)")
            }
        }
        
        /**
         * 获取评论
         * @param contentID 内容项ID
         * @return [CommentItem] 评论数组
         */
        func getComments(forContentID contentID: String) -> [CommentItem] {
            let comments = commentsMap[contentID] ?? []
            print("📦 获取到\(comments.count)条评论，内容ID: \(contentID)")
            return comments
        }
        
        /**
         * 清除所有评论
         */
        func clearAllComments() {
            commentsMap.removeAll()
            print("🧹 已清除所有评论")
        }
    }
    
    /**
     * 根据角色和内容类型生成内容
     */
    func generateContent(for characterID: String, contentType: ContentType, topic: String? = nil) -> Future<ContentItem, Error> {
        return Future { promise in
            // 获取角色详细特征
            self.characterSystem.getCharacterTraits(characterID)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { traits in
                        // 将ContentType转换为字符串表示
                        let contentTypeString = self.contentTypeToString(contentType)
                        
                        // 构建提示词
                        let prompt = traits.buildContentPrompt(contentType: contentTypeString, topic: topic)
                        
                        // 使用AI内容生成器生成内容
                        self.aiContentGenerator.generateContent(prompt: prompt)
                            .sink(receiveCompletion: { completion in
                                if case .failure(let error) = completion {
                                    promise(.failure(error))
                                }
                            }, receiveValue: { content in
                                let contentItem = ContentItem(
                                    id: UUID().uuidString,
                                    characterID: characterID,
                                    characterName: traits.identity.name,
                                    characterType: traits.identity.type.rawValue,
                                    characterAvatar: traits.identity.avatarName,
                                    contentType: contentType.rawValue,
                                    content: content,
                                    timestamp: Date(),
                                    likes: Int.random(in: 10...200),
                                    comments: [],
                                    topics: self.extractTopicFromContent(content)
                                )
                                promise(.success(contentItem))
                            })
                            .store(in: &self.cancellables)
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    /**
     * 将ContentType枚举转换为对应的字符串表示
     */
    private func contentTypeToString(_ contentType: ContentType) -> String {
        return contentType.rawValue
    }
    
    /**
     * 生成随机角色的内容
     */
    func generateRandomContent(contentType: ContentType, count: Int, topic: String? = nil) -> Future<[ContentItem], Error> {
        return Future { promise in
            // 开始新一轮生成会话，确保角色均衡分配
            CharacterRotationSystem.shared.beginNewGenerationSession()
            
            // 使用角色轮换系统获取平衡分配的角色
            let characters = CharacterRotationSystem.shared.getRecommendedCharacters(count: count)
            
            var contentItems: [ContentItem] = []
            var contentErrors: [Error] = []
            let contentGroup = DispatchGroup()
            
            for character in characters {
                contentGroup.enter()
                self.generateContent(for: character.id, contentType: contentType, topic: topic)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                contentErrors.append(error)
                                // 失败时在这里调用leave
                                contentGroup.leave()
                            }
                            // 成功完成时不调用leave，因为会在receiveValue中调用
                        },
                        receiveValue: { contentItem in
                            contentItems.append(contentItem)
                            contentGroup.leave() // 成功时在这里调用leave
                        }
                    )
                    .store(in: &self.cancellables)
            }
            
            contentGroup.notify(queue: .main) {
                // 即使有错误也返回成功生成的内容
                if contentItems.isEmpty && !contentErrors.isEmpty {
                    // 如果没有成功生成的内容，但有错误，则返回第一个错误
                    promise(.failure(contentErrors[0]))
                } else {
                    promise(.success(contentItems))
                }
            }
        }
    }
    
    /**
     * 生成混合内容
     * 生成不同类型的内容，按照指定的数量分布
     */
    func generateMixedContent(
        resonanceCount: Int = 2,
        moodCount: Int = 3,
        ancient2modernCount: Int = 2,
        creativeIdeaCount: Int = 2,
        timelineEventCount: Int = 1
    ) -> Future<[ContentItem], Error> {
        return Future { promise in
            // 开始新一轮生成会话
            CharacterRotationSystem.shared.beginNewGenerationSession()
            
            var allContentItems: [ContentItem] = []
            var contentErrors: [Error] = []
            
            let contentGroup = DispatchGroup()
            
            // 生成共鸣内容
            if resonanceCount > 0 {
                contentGroup.enter()
                self.generateRandomContent(contentType: .resonance, count: resonanceCount)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                contentErrors.append(error)
                                // 只在失败且没有值返回时离开组
                                // leave()将在receiveValue中调用
                            }
                            // 不在这里调用leave()
                        },
                        receiveValue: { items in
                            allContentItems.append(contentsOf: items)
                            contentGroup.leave() // 只在这里调用一次leave()
                        }
                    )
                    .store(in: &self.cancellables)
            }
            
            // 生成心情内容
            if moodCount > 0 {
                contentGroup.enter()
                self.generateRandomContent(contentType: .mood, count: moodCount)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                contentErrors.append(error)
                                // 只有在失败且没有值返回时才调用leave
                                contentGroup.leave()
                            }
                            // 成功完成时不调用leave，因为会在receiveValue中调用
                        },
                        receiveValue: { items in
                            allContentItems.append(contentsOf: items)
                            contentGroup.leave() // 成功时在这里调用一次leave()
                        }
                    )
                    .store(in: &self.cancellables)
            }
            
            // 生成古今对望内容
            if ancient2modernCount > 0 {
                contentGroup.enter()
                self.generateRandomContent(contentType: .ancient2modern, count: ancient2modernCount)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                contentErrors.append(error)
                                // 只有在失败且没有值返回时才调用leave
                                contentGroup.leave()
                            }
                            // 成功完成时不调用leave，因为会在receiveValue中调用
                        },
                        receiveValue: { items in
                            allContentItems.append(contentsOf: items)
                            contentGroup.leave() // 成功时在这里调用一次leave()
                        }
                    )
                    .store(in: &self.cancellables)
            }
            
            // 生成创意点子内容
            if creativeIdeaCount > 0 {
                contentGroup.enter()
                self.generateRandomContent(contentType: .creativeIdea, count: creativeIdeaCount)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                contentErrors.append(error)
                                // 只有在失败且没有值返回时才调用leave
                                contentGroup.leave()
                            }
                            // 成功完成时不调用leave，因为会在receiveValue中调用
                        },
                        receiveValue: { items in
                            allContentItems.append(contentsOf: items)
                            contentGroup.leave() // 成功时在这里调用一次leave()
                        }
                    )
                    .store(in: &self.cancellables)
            }
            
            // 生成时间线事件内容
            if timelineEventCount > 0 {
                contentGroup.enter()
                self.generateRandomContent(contentType: .timelineEvent, count: timelineEventCount)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                contentErrors.append(error)
                                // 只有在失败且没有值返回时才调用leave
                                contentGroup.leave()
                            }
                            // 成功完成时不调用leave，因为会在receiveValue中调用
                        },
                        receiveValue: { items in
                            allContentItems.append(contentsOf: items)
                            contentGroup.leave() // 成功时在这里调用一次leave()
                        }
                    )
                    .store(in: &self.cancellables)
            }
            
            contentGroup.notify(queue: .main) {
                // 对所有内容按时间戳进行排序
                let sortedItems = allContentItems.sorted(by: { $0.timestamp > $1.timestamp })
                
                // 即使有错误也返回成功生成的内容
                if sortedItems.isEmpty && !contentErrors.isEmpty {
                    // 如果没有成功生成的内容，但有错误，则返回第一个错误
                    promise(.failure(contentErrors[0]))
                } else {
                    promise(.success(sortedItems))
                }
            }
        }
    }
    
    /**
     * 生成混合内容，按照指定的内容类型分布
     */
    func generateMixedContent(contentTypes: [ContentType: Int]) -> Future<[ContentItem], Error> {
        return Future { promise in
            // 开始新一轮生成会话
            CharacterRotationSystem.shared.beginNewGenerationSession()
            
            var allContentItems: [ContentItem] = []
            var contentErrors: [Error] = []
            
            let contentGroup = DispatchGroup()
            
            for (contentType, count) in contentTypes {
                if count > 0 {
                    contentGroup.enter()
                    self.generateRandomContent(contentType: contentType, count: count)
                        .sink(
                            receiveCompletion: { completion in
                                if case .failure(let error) = completion {
                                    contentErrors.append(error)
                                    // 只有在失败且没有值返回时才调用leave
                                    contentGroup.leave()
                                }
                                // 成功完成时不调用leave，因为会在receiveValue中调用
                            },
                            receiveValue: { items in
                                allContentItems.append(contentsOf: items)
                                contentGroup.leave() // 成功时在这里调用一次leave()
                            }
                        )
                        .store(in: &self.cancellables)
                }
            }
            
            contentGroup.notify(queue: .main) {
                // 对所有内容按时间戳进行排序
                let sortedItems = allContentItems.sorted(by: { $0.timestamp > $1.timestamp })
                
                // 即使有错误也返回成功生成的内容
                if sortedItems.isEmpty && !contentErrors.isEmpty {
                    promise(.failure(contentErrors[0]))
                } else {
                    promise(.success(sortedItems))
                }
            }
        }
    }
    
    /**
     * 生成虫洞演习场景的内容集合
     * @param count 要生成的内容总数
     * @return Future<[ContentItem], Error>
     */
    func generateWormholeContent(count: Int = 5) -> Future<[ContentItem], Error> {
        // 设置不同内容类型的比例（已移除虫洞共鸣）
        let contentTypeDistribution: [ContentType: Int] = [
            .ancient2modern: Int(Double(count) * 0.225),
            .creativeIdea: Int(Double(count) * 0.525),
            .mood: Int(Double(count) * 0.175),
            .timelineEvent: Int(Double(count) * 0.075)
        ]
        
        // 确保总数匹配
        var adjustedDistribution = contentTypeDistribution
        let totalInDistribution = contentTypeDistribution.values.reduce(0, +)
        if totalInDistribution < count {
            // 如果分配的总数小于请求数量，将差额添加到穿越吐槽类型
            adjustedDistribution[.creativeIdea] = (adjustedDistribution[.creativeIdea] ?? 0) + (count - totalInDistribution)
        }
        
        return generateMixedContent(contentTypes: adjustedDistribution)
    }
    
    /**
     * 生成单一类型的内容
     * 这个方法保证生成指定数量的指定类型内容
     * 适用于用户在虫洞探索界面单独点击某个内容类型时使用
     * @param contentType 内容类型
     * @param topic 可选主题
     * @param count 要生成的内容数量，默认为6篇
     * @return Future<[ContentItem], Error>
     */
    func generateSingleTypeContent(contentType: ContentType, topic: String? = nil, count: Int = 6) -> Future<[ContentItem], Error> {
        return Future { promise in
            // 开始新一轮生成会话
            CharacterRotationSystem.shared.beginNewGenerationSession()
            
            // 使用传入的count参数，而不是固定值
            let contentCount = count
            
            // 并行发布者集合，用于同时生成多篇内容
            var publishers: [Future<(contentItem: ContentItem, comments: [CommentItem]), Error>] = []
            
            // 为每篇内容创建生成器
            for _ in 0..<contentCount {
                // 使用generateRandomContentWithComments方法替代之前的批量生成方法
                // 这个方法会根据内容类型动态调整评论数量
                let publisher = self.generateRandomContentWithComments(contentType: contentType, topic: topic)
                publishers.append(publisher)
            }
            
            // 使用MergeMany合并所有发布者的结果
            Publishers.MergeMany(publishers)
                .collect() // 收集所有结果
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ 生成带评论的内容失败: \(error.localizedDescription)")
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { results in
                        print("✅ 成功生成\(results.count)篇带评论的内容")
                        
                        var contentItems: [ContentItem] = []
                        var commentsMap: [String: [CommentItem]] = [:] // 存储每个内容项的评论
                        
                        // 处理每个生成结果
                        for result in results {
                            let contentItem = result.contentItem
                            contentItems.append(contentItem)
                            
                            // 存储评论
                            commentsMap[contentItem.id] = result.comments
                            
                            print("📝 内容「\(contentItem.characterName)」: 评论数=\(result.comments.count)")
                        }
                        
                        // 使用CommentStore保存所有评论
                        CommentStore.shared.saveComments(commentsMap)
                        
                        // 返回内容项数组
                        promise(.success(contentItems))
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    /**
     * 生成带评论的内容
     * 一次API调用同时生成内容和初始评论
     */
    func generateContentWithComments(for characterID: String, contentType: ContentType, topic: String? = nil, commentersCount: Int = 3) -> Future<(contentItem: ContentItem, comments: [CommentItem]), Error> {
        return Future { promise in
            print("🔄 生成带评论的内容: 角色ID=\(characterID), 类型=\(contentType.rawValue), 评论数=\(commentersCount)")
            
            // 获取角色信息
            self.characterSystem.getCharacter(characterID)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ 获取角色信息失败: \(error.localizedDescription)")
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { character in
                        print("👤 获取角色成功: \(character.name)")
                        
                        // 将ContentType转换为字符串表示
                        let contentTypeString = self.contentTypeToString(contentType)
                        
                        // 使用AI内容生成器生成内容和评论
                        self.aiContentGenerator.generateContentWithComments(
                            contentType: contentTypeString,
                            character: character,
                            commentersCount: commentersCount,
                            topic: topic ?? "未指定主题"
                        )
                        .sink(
                            receiveCompletion: { completion in
                                if case .failure(let error) = completion {
                                    print("❌ AI生成内容和评论失败: \(error.localizedDescription)")
                                    promise(.failure(error))
                                }
                            },
                            receiveValue: { result in
                                print("✅ AI成功生成内容和\(result.comments.count)条评论")
                                
                                // 创建内容项
                                let contentItem = ContentItem(
                                    id: UUID().uuidString,
                                    characterID: characterID,
                                    characterName: character.name,
                                    characterType: character.type.rawValue,
                                    characterAvatar: character.avatarName,
                                    contentType: contentType.rawValue,
                                    content: result.content,
                                    timestamp: Date(),
                                    likes: Int.random(in: 10...200),
                                    comments: [],
                                    topics: self.extractTopicFromContent(result.content)
                                )
                                
                                // 如果没有评论，直接返回结果
                                if result.comments.isEmpty {
                                    print("⚠️ 警告：AI没有生成任何评论")
                                    promise(.success((contentItem, [])))
                                    return
                                }
                                
                                // 创建评论项
                                var comments: [CommentItem] = []
                                let now = Date()
                                let dispatchGroup = DispatchGroup()
                                
                                print("🔄 开始处理\(result.comments.count)条评论...")
                                
                                for (index, commentData) in result.comments.enumerated() {
                                    dispatchGroup.enter()
                                    
                                    // 尝试查找评论者角色
                                    self.characterSystem.findCharacterByName(commentData.character)
                                        .sink(
                                            receiveCompletion: { completion in
                                                if case .failure(let error) = completion {
                                                    print("⚠️ 查找评论者角色失败: \(error.localizedDescription), 使用默认值")
                                                    // 继续处理，不中断评论生成
                                                }
                                                // 不管成功失败都需要离开组
                                                dispatchGroup.leave()
                                            },
                                            receiveValue: { commenter in
                                                // 创建评论，设置递减的时间戳（最早的评论在最前面）
                                                let timestamp = now.addingTimeInterval(-Double((result.comments.count - index) * 120))
                                                
                                                // 只有当评论内容不为空时才创建评论项
                                                if !commentData.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                    let commentItem = CommentItem(
                                                        id: UUID().uuidString,
                                                        contentID: contentItem.id,
                                                        characterID: commenter?.id ?? "unknown",
                                                        characterName: commenter?.name ?? commentData.character,
                                                        characterAvatar: commenter?.avatarName ?? "default_avatar",
                                                        content: commentData.comment,
                                                        timestamp: timestamp,
                                                        likes: Int.random(in: 5...50)
                                                    )
                                                    
                                                    print("📝 创建评论项 #\(index+1): \(commentItem.characterName)")
                                                    comments.append(commentItem)
                                                } else {
                                                    print("⚠️ 跳过空评论内容 - 角色: \(commenter?.name ?? commentData.character)")
                                                }
                                            }
                                        )
                                        .store(in: &self.cancellables)
                                }
                                
                                // 当所有评论都处理完毕时，返回结果
                                dispatchGroup.notify(queue: .main) {
                                    print("✅ 所有评论处理完成，共\(comments.count)条评论")
                                    // 按时间排序评论
                                    let sortedComments = comments.sorted { $0.timestamp > $1.timestamp }
                                    promise(.success((contentItem, sortedComments)))
                                }
                            }
                        )
                        .store(in: &self.cancellables)
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    /**
     * 生成随机内容，并包含评论
     * @param contentType 内容类型
     * @param topic 可选主题
     * @return Future<(contentItem: ContentItem, comments: [CommentItem]), Error>
     */
    func generateRandomContentWithComments(contentType: ContentType, topic: String? = nil) -> Future<(contentItem: ContentItem, comments: [CommentItem]), Error> {
        return Future { promise in
            // 根据内容类型动态调整评论数量
            var dynamicCommentersCount = 3
            
            // 为不同内容类型设置不同的评论数量范围
            switch contentType {
            case .resonance: // 虫洞共鸣
                // 根据话题复杂度动态调整评论数量
                // 分析话题复杂度：检查话题字符串中是否包含特定关键词来评估复杂度
                let complexTopics = ["困境", "挑战", "迷茫", "矛盾", "冲突", "抉择", "选择", "平衡", "深度", "思考", "哲学", "价值", "人生", "意义"]
                
                // 检查话题中是否包含复杂度指示词
                var topicComplexity = 0
                if let topicString = topic?.lowercased() {
                    for keyword in complexTopics {
                        if topicString.contains(keyword) {
                            topicComplexity += 1
                        }
                    }
                }
                
                // 根据复杂度设置评论数量
                if topicComplexity >= 2 {
                    // 复杂主题，生成更多评论
                    dynamicCommentersCount = 4
                    print("🧠 检测到复杂话题，设置评论数量=4")
                } else if topicComplexity >= 1 {
                    // 中等复杂度主题
                    dynamicCommentersCount = 3
                    print("📝 检测到中等复杂度话题，设置评论数量=3")
                } else {
                    // 简单主题
                    dynamicCommentersCount = Int.random(in: 2...3)
                    print("📌 检测到一般话题，设置评论数量=\(dynamicCommentersCount)")
                }
                
                print("🌟 开始生成虫洞共鸣内容: 话题=\(topic ?? "未指定")，评论数=\(dynamicCommentersCount)")
                
            case .ancient2modern: // 古潮新语
                // 深度思考类内容，评论数量较多，3-4条
                dynamicCommentersCount = Int.random(in: 3...4)
                print("🌟 开始生成古潮新语内容: 设置评论数=\(dynamicCommentersCount)，突出思想深度和现代意义")
                
            case .creativeIdea: // 穿越吐槽
                // 轻松幽默类内容，评论数量适中，2-3条
                dynamicCommentersCount = Int.random(in: 2...3)
                print("🌟 开始生成穿越吐槽内容: 设置评论数=\(dynamicCommentersCount)，注重幽默和文化对比")
                
            case .mood: // 日常心情
                // 情感抒发类内容，评论数量适中，2-3条
                dynamicCommentersCount = Int.random(in: 2...3)
                print("🌟 开始生成日常心情内容: 设置评论数=\(dynamicCommentersCount)，注重情感共鸣和生活智慧")
                
            case .timelineEvent: // 时空记事
                // 叙事类内容，评论数量较多，3-4条
                dynamicCommentersCount = Int.random(in: 3...4)
                print("🌟 开始生成时空记事内容: 设置评论数=\(dynamicCommentersCount)，注重历史视角和知识补充")
            }
            
            // 使用角色轮换系统获取一个角色
            let characters = CharacterRotationSystem.shared.getRecommendedCharacters(count: 1)
            guard let character = characters.first else {
                let error = NSError(domain: "ContentGeneratorService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "无法获取随机角色"])
                print("❌ 生成随机角色失败: \(error.localizedDescription)")
                promise(.failure(error))
                return
            }
            
            print("👤 已选择随机角色: \(character.name) (\(character.type.displayName))")
            
            // 根据内容类型选择合适的话题
            var selectedTopic = topic
            if selectedTopic == nil {
                // 如果未提供话题，为特定内容类型选择专业话题
                if contentType == .resonance { // 虫洞共鸣
                    // 为虫洞共鸣选择情境和期望组合作为话题
                    let situations = [
                        "工作压力与平衡", "人际关系困扰", "目标实现与坚持", "自我价值与认同", 
                        "心灵成长与突破", "决策困境与选择", "专注力与效率", "创造力与灵感"
                    ]
                    
                    let expectations = [
                        "内心平静", "方向指引", "行动勇气", "深度思考", 
                        "情感理解", "实用智慧", "新视角", "自我突破"
                    ]
                    
                    let selectedSituation = situations.randomElement() ?? "生活的挑战"
                    let selectedExpectation = expectations.randomElement() ?? "内心平静"
                    
                    selectedTopic = "\(selectedSituation)与\(selectedExpectation)"
                    
                } else if contentType == .ancient2modern { // 古潮新语
                    let topicCategories = ["科技类", "交通类", "生活类", "社交类", "职场类", "休闲类", "文化类"]
                    let selectedCategory = topicCategories.randomElement() ?? "科技类"
                    
                    let topicsByCategory: [String: [String]] = [
                        "科技类": ["智能手机", "无人机", "电子支付", "人工智能", "VR/AR", "智能家居"],
                        "交通类": ["共享单车", "电动车", "高铁", "地铁", "网约车", "堵车"],
                        "生活类": ["外卖", "奶茶", "快递", "健身房", "网购", "短视频"],
                        "社交类": ["社交媒体", "点赞", "评论区争论", "表情包", "网络用语", "直播"],
                        "职场类": ["996工作制", "居家办公", "打工人", "副业", "创业", "内卷"],
                        "休闲类": ["密室逃脱", "剧本杀", "电子游戏", "露营", "瑜伽", "咖啡馆"],
                        "文化类": ["二次元", "饭圈", "追剧", "网文", "潮流穿搭", "国潮"]
                    ]
                    
                    if let topics = topicsByCategory[selectedCategory] {
                        selectedTopic = topics.randomElement()
                    }
                }
            }
            
            // 使用选定的角色生成带评论的内容
            self.generateContentWithComments(
                for: character.id,
                contentType: contentType,
                topic: selectedTopic,
                commentersCount: dynamicCommentersCount
            )
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ 生成内容失败: \(error.localizedDescription)")
                        promise(.failure(error))
                    }
                },
                receiveValue: { result in
                    print("✅ 成功生成内容和\(result.comments.count)条评论")
                    promise(.success(result))
                }
            )
            .store(in: &self.cancellables)
        }
    }
    
    /**
     * 批量生成带评论的随机内容
     * 该方法一次性生成指定数量和类型的内容，保持一次API调用
     * @param contentType 内容类型
     * @param count 要生成的内容数量
     * @param topic 可选主题
     * @return Future<[(contentItem: ContentItem, comments: [CommentItem])], Error>
     */
    func generateRandomContentBatchWithComments(
        contentType: ContentType,
        count: Int = 3,
        topic: String? = nil
    ) -> Future<[(contentItem: ContentItem, comments: [CommentItem])], Error> {
        return Future { promise in
            // 创建一个内容生成任务组
            var futures: [Future<(contentItem: ContentItem, comments: [CommentItem]), Error>] = []
            
            // 添加指定数量的内容生成任务
            for _ in 0..<count {
                let future = self.generateRandomContentWithComments(contentType: contentType, topic: topic)
                futures.append(future)
            }
            
            // 合并所有任务结果
            Publishers.MergeMany(futures)
                .collect()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { results in
                        promise(.success(results))
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    // MARK: - 助手方法
    
    /**
     * 从内容中提取主题
     */
    private func extractTopicFromContent(_ content: String) -> String {
        // 这是一个简化实现，实际应用中可能需要更复杂的主题提取算法
        let sentences = content.components(separatedBy: [".","。","!","！","?","？"])
        let firstSentence = sentences.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if firstSentence.count > 10 {
            return String(firstSentence.prefix(10)) + "..."
        }
        return firstSentence
    }
    
    // MARK: - 错误类型
    
    enum ContentError: Error {
        case noCharactersAvailable
        case contentGenerationFailed
        case invalidContentType
    }
    
    /**
     * 快速生成评论
     * 生成角色对特定内容的评论
     */
    func generateQuickComment(forContent content: String, byCharacter character: CharacterSystem.CharacterIdentity) async -> String {
        // 根据评论风格分类评论模板
        
        // 1. 共鸣认同型模板 - 表达理解和情感支持
        let empathyTemplates = [
            "这个思考很有启发性。虽然我是\(character.primaryField)出身，但也曾有过类似的困惑，能理解这种感受。",
            "看完你的想法，我感到很有共鸣。在\(character.era)时，我也思考过这样的问题，就像两座山看到同一轮月亮。",
            "你说的这些让我想起了自己经历过的挑战，很多时候困境就像迷雾，但走过去后会发现本质是相通的。",
            "这段话真的触动了我，在研究\(character.primaryField)时，我也常常感到类似的纠结和思考。",
            "我很认同你的观点，它触及了我们都面对的内心问题，无论是现代人还是\(character.era)的人。"
        ]
        
        // 2. 新视角启发型模板 - 提供不同角度思考
        let perspectiveTemplates = [
            "从另一个角度看，如果用\(character.primaryField)的思路，这个问题就像是看一幅画：近看是细节，远看才能见全貌。",
            "这个想法很深刻，不过我想补充一点：在我生活的年代，我们更关注的是事物的联系而非区别。",
            "你的思考很有价值，让我想到了另一种可能：如果把这个问题放在更大的生活背景中考虑...",
            "作为\(character.type.displayName)，我会建议用不同方式看待：就像一棵树，既能看到向上生长的枝叶，也能关注向下扎根的部分。",
            "有意思的观点，不过我想提醒你可能忽略的一面：在我的时代，我们发现很多问题的答案往往藏在日常生活的点滴中。"
        ]
        
        // 3. 实践指导型模板 - 提供具体可行的建议
        let practicalTemplates = [
            "根据我在\(character.primaryField)的经验，有个简单方法可能对你有帮助：就像搭积木一样，先从基础开始...",
            "我曾在类似情况下找到突破口，关键是换个思路，就像走迷宫时偶尔需要先往后退一步...",
            "这个问题在我的研究中也出现过，最有效的方法其实很简单：把复杂问题拆分成小步骤，一步步来。",
            "经历过\(character.era)的变化后，我的建议是：与其纠结于理论，不如先采取行动，哪怕是小小的尝试。",
            "从实际出发，我推荐一个在我那个年代也有效的方法：每天花一点时间反思，就像给思想浇水一样..."
        ]
        
        // 根据内容随机选择一种风格，确保多样性
        let randomStyle = Int.random(in: 0...2)
        let selectedTemplate: String
        
        switch randomStyle {
        case 0:
            selectedTemplate = empathyTemplates.randomElement() ?? "你的想法很有启发性，引起了我的共鸣。"
        case 1:
            selectedTemplate = perspectiveTemplates.randomElement() ?? "从不同角度看，这个问题还有其他可能的解读。"
        case 2:
            selectedTemplate = practicalTemplates.randomElement() ?? "基于我的经验，有个简单方法可能对你有帮助。"
        default:
            selectedTemplate = "这个观点很有价值，让我想到了生活中的很多启示。"
        }
        
        return selectedTemplate
    }
}

/**
 * 生成的内容项
 */
struct ContentItem {
    let id: String
    let characterID: String
    let characterName: String
    let characterType: String
    let characterAvatar: String?
    let contentType: String
    let content: String
    let timestamp: Date
    let likes: Int
    let comments: [Any]
    let topics: String
}

/**
 * 生成的评论项
 */
struct CommentItem {
    let id: String
    let contentID: String
    let characterID: String
    let characterName: String
    let characterAvatar: String?
    let content: String
    let timestamp: Date
    let likes: Int
} 