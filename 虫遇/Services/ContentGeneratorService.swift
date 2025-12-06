import Foundation
import Combine

/**
 * 内容生成服务
 * 整合角色系统和内容生成系统，提供统一的内容生成接口
 */
class ContentGeneratorService: ObservableObject {
    // 单例模式
    static let shared = ContentGeneratorService()
    private init() {}
    
    @Published private(set) var isBackendBusy: Bool = false
    
    @MainActor
    func markBackendBusy(_ busy: Bool) {
        guard isBackendBusy != busy else { return }
        isBackendBusy = busy
    }
    
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
            #if DEBUG
            print("📦 已保存\(comments.count)条评论，内容ID: \(contentID)")
            #endif
        }
        
        /**
         * 批量保存评论
         * @param commentsMap 评论映射表 [内容项ID: 评论数组]
         */
        func saveComments(_ commentsMap: [String: [CommentItem]]) {
            for (contentID, comments) in commentsMap {
                self.commentsMap[contentID] = comments
                #if DEBUG
                print("📦 已批量保存\(comments.count)条评论，内容ID: \(contentID)")
                #endif
            }
        }
        
        /**
         * 获取评论
         * @param contentID 内容项ID
         * @return [CommentItem] 评论数组
         */
        func getComments(forContentID contentID: String) -> [CommentItem] {
            let comments = commentsMap[contentID] ?? []
            #if DEBUG
            print("📦 获取到\(comments.count)条评论，内容ID: \(contentID)")
            #endif
            return comments
        }
        
        /**
         * 清除所有评论
         */
        func clearAllComments() {
            commentsMap.removeAll()
            #if DEBUG
            print("🧹 已清除所有评论")
            #endif
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
            var publishers: [AnyPublisher<(contentItem: ContentItem, comments: [CommentItem]), Never>] = []
            
            // 为每篇内容创建生成器
            for _ in 0..<contentCount {
                // 使用generateRandomContentWithComments方法替代之前的批量生成方法
                // 这个方法会根据内容类型动态调整评论数量
                let safePublisher = self.generateRandomContentWithComments(contentType: contentType, topic: topic)
                    .catch { _ in
                        Empty<(contentItem: ContentItem, comments: [CommentItem]), Never>(completeImmediately: true)
                    }
                    .eraseToAnyPublisher()
                publishers.append(safePublisher)
            }
            
            // 使用MergeMany合并所有发布者的结果
            Publishers.MergeMany(publishers)
                .collect() // 收集所有结果
                .sink(
                    receiveValue: { results in
                        #if DEBUG
                        print("✅ 成功生成\(results.count)篇带评论的内容")
                        #endif
                        
                        var contentItems: [ContentItem] = []
                        var commentsMap: [String: [CommentItem]] = [:] // 存储每个内容项的评论
                        
                        // 处理每个生成结果
                        for result in results {
                            let contentItem = result.contentItem
                            contentItems.append(contentItem)
                            
                            // 存储评论
                            commentsMap[contentItem.id] = result.comments
                            
                            #if DEBUG
                            print("📝 内容「\(contentItem.characterName)」: 评论数=\(result.comments.count)")
                            #endif
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
            #if DEBUG
            print("🔄 生成带评论的内容: 角色ID=\(characterID), 类型=\(contentType.rawValue), 评论数=\(commentersCount)")
            #endif
            
            // 🔒 优先从CharacterModel获取角色信息（包含用户创建的角色）
            // 如果CharacterModel中没有，再从CharacterSystem获取
            let allCharacterModels = CharacterModel.getAllCharacters()
            if let characterModel = allCharacterModels.first(where: { $0.id == characterID }) {
                // 将CharacterModel转换为CharacterIdentity
                let characterType: CharacterSystem.CharacterType = {
                    switch characterModel.category {
                    case .historical: return .historical
                    case .philosopher: return .historical
                    case .writer: return .literary
                    case .animeCharacter: return .anime
                    case .gameCharacter: return .game
                    case .filmCharacter: return .movie
                    case .mythCharacter: return .mythological
                    case .myCreation: return .custom // 用户创建的角色使用custom类型
                    case .all: return .historical
                    }
                }()
                
                let character = CharacterSystem.CharacterIdentity(
                    id: characterModel.id,
                    name: characterModel.name,
                    type: characterType,
                    era: characterModel.era,
                    primaryField: characterModel.profession,
                    briefDescription: characterModel.bio,
                    avatarName: characterModel.avatar,
                    region: "",
                    contentAffinities: [:],
                    subtype: nil
                )
                
                        #if DEBUG
                print("👤 从CharacterModel获取角色成功: \(character.name)")
                        #endif
                        
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
                                    #if DEBUG
                                    print("❌ AI生成内容和评论失败: \(error.localizedDescription)")
                                    #endif
                                    
                                    // 显示友好的错误提示给用户
                                    // 注意：403错误已经在AINetworkService中显示Toast，这里避免重复显示
                                    Task { @MainActor in
                                        if let aiError = error as? AINetworkError {
                                            // 检查是否是403错误（已在AINetworkService中显示Toast）
                                            var is403Error = false
                                            if case .httpError(let code) = aiError {
                                                is403Error = (code == 403)
                                            }
                                            
                                            // 403错误已在AINetworkService中显示Toast，跳过
                                            // 其他错误显示友好提示
                                            if !is403Error {
                                                ToastManager.shared.showToast(message: aiError.localizedDescription)
                                            }
                                        } else {
                                            // 对于其他错误，显示通用提示
                                            ToastManager.shared.showToast(message: "生成失败，请稍后重试")
                                        }
                                    }
                                    
                                    promise(.failure(error))
                                }
                            },
                            receiveValue: { result in
                                #if DEBUG
                                print("✅ AI成功生成内容和\(result.comments.count)条评论")
                                #endif
                                
                                // 🔒 修复：对于用户创建的角色，使用characterID作为avatar（确保使用最新头像）
                                let avatarName: String = {
                                    // 如果是用户创建的角色，使用characterID作为avatar路径
                                    if characterID.hasPrefix("custom_") || characterID.hasPrefix("user_avatar_") {
                                        return characterID
                                    } else {
                                        // 其他角色使用原始avatarName
                                        return character.avatarName
                                    }
                                }()
                                
                                // 创建内容项
                                let contentItem = ContentItem(
                                    id: UUID().uuidString,
                                    characterID: characterID,
                                    characterName: character.name, // 🔒 确保使用角色名称，不是用户名
                                    characterType: character.type.rawValue,
                                    characterAvatar: avatarName, // 🔒 使用修复后的avatar
                                    contentType: contentType.rawValue,
                                    content: result.content,
                                    timestamp: Date(),
                                    likes: Int.random(in: 10...200),
                                    comments: [],
                                    topics: self.extractTopicFromContent(result.content)
                                )
                                
                                // 如果没有评论，直接返回结果
                                if result.comments.isEmpty {
                                    #if DEBUG
                                    print("⚠️ 警告：AI没有生成任何评论")
                                    #endif
                                    promise(.success((contentItem, [])))
                                    return
                                }
                                
                                // 创建评论项
                                var comments: [CommentItem] = []
                                let now = Date()
                                let dispatchGroup = DispatchGroup()
                                
                                #if DEBUG
                                print("🔄 开始处理\(result.comments.count)条评论...")
                                #endif
                                
                                // 存储基础评论的ID和角色名映射，用于后续处理回复评论
                                var baseCommentIdMap: [String: String] = [:]
                                
                                // 首先处理所有评论
                                for (index, commentData) in result.comments.enumerated() {
                                    dispatchGroup.enter()
                                    
                                    // 🔒 修复：优先从CharacterModel查找评论者角色（包含用户创建的角色）
                                    var commenter: CharacterSystem.CharacterIdentity? = nil
                                    var commenterCharacterModel: CharacterModel? = nil
                                    
                                    // 首先尝试从CharacterModel查找（包含用户创建的角色）
                                    let allCharacterModels = CharacterModel.getAllCharacters()
                                    if let characterModel = allCharacterModels.first(where: { $0.name == commentData.character }) {
                                        commenterCharacterModel = characterModel
                                        
                                        // 将CharacterModel转换为CharacterIdentity
                                        let characterType: CharacterSystem.CharacterType = {
                                            switch characterModel.category {
                                            case .historical: return .historical
                                            case .philosopher: return .historical
                                            case .writer: return .literary
                                            case .animeCharacter: return .anime
                                            case .gameCharacter: return .game
                                            case .filmCharacter: return .movie
                                            case .mythCharacter: return .mythological
                                            case .myCreation: return .custom
                                            case .all: return .historical
                                            }
                                        }()
                                        
                                        commenter = CharacterSystem.CharacterIdentity(
                                            id: characterModel.id,
                                            name: characterModel.name,
                                            type: characterType,
                                            era: characterModel.era,
                                            primaryField: characterModel.profession,
                                            briefDescription: characterModel.bio,
                                            avatarName: characterModel.avatar,
                                            region: "",
                                            contentAffinities: [:],
                                            subtype: nil
                                        )
                                    } else {
                                        // 如果CharacterModel中找不到，从CharacterSystem查找（备用方案）
                                        commenter = self.characterSystem.findCharacterByName(commentData.character)
                                    }
                            
                            // 🔒 检查评论者角色是否被屏蔽（自动生成的评论需要应用屏蔽过滤）
                            if let commenter = commenter {
                                // 检查是否为用户创建的角色（ID以"custom_"开头）
                                let isUserCreated = commenter.id.hasPrefix("custom_")
                                
                                // 🔒 用户创建的角色：只受"我的创建"分类的屏蔽影响
                                if isUserCreated {
                                    if BlockedCategoriesManager.shared.isCategoryBlocked(.myCreation) {
                                        #if DEBUG
                                        print("🚫 跳过被屏蔽的用户创建角色: \(commenter.name)")
                                        #endif
                                        dispatchGroup.leave()
                                        continue
                                    }
                                    // 用户创建的角色不受其他分类屏蔽影响，继续处理
                                } else {
                                    // 🔒 非用户创建的角色：检查分类是否被屏蔽
                                    if let characterModel = commenterCharacterModel ?? CharacterModel.getAllCharacters().first(where: { $0.id == commenter.id }) {
                                        let isBlocked = BlockedCategoriesManager.shared.isCategoryBlocked(characterModel.category)
                                        if isBlocked {
                                            #if DEBUG
                                            print("🚫 跳过被屏蔽分类的评论者: \(commenter.name) (分类: \(characterModel.category.rawValue))")
                                            #endif
                                            dispatchGroup.leave()
                                            continue
                                        }
                                    }
                                }
                            }
                                    
                                    // 创建评论，设置递减的时间戳（最早的评论在最前面）
                                    let timestamp = now.addingTimeInterval(-Double((result.comments.count - index) * 120))
                                    
                                    // 只有当评论内容不为空时才创建评论项
                                    if !commentData.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        let commentId = UUID()
                                        
                                        // 🔒 修复：对于用户创建的角色，使用characterID作为avatar（确保使用最新头像）
                                        let avatarName: String = {
                                            if let characterModel = commenterCharacterModel {
                                                // 如果是用户创建的角色，使用characterID作为avatar路径
                                                if characterModel.id.hasPrefix("custom_") || characterModel.id.hasPrefix("user_avatar_") {
                                                    return characterModel.id
                                                } else {
                                                    return characterModel.avatar
                                                }
                                            } else {
                                                // 如果找不到CharacterModel，使用commenter的avatarName
                                                if let commenter = commenter, (commenter.id.hasPrefix("custom_") || commenter.id.hasPrefix("user_avatar_")) {
                                                    return commenter.id
                                                } else {
                                                    return commenter?.avatarName ?? "person.circle.fill"
                                                }
                                            }
                                        }()
                                        
                                        let commentItem = CommentItem(
                                            id: commentId.uuidString,
                                            characterId: commenter?.id ?? "unknown",
                                            characterName: commenter?.name ?? commentData.character,
                                            characterAvatar: avatarName,
                                            characterRole: commenter?.primaryField ?? "unknown",
                                            content: commentData.comment,
                                            timestamp: timestamp,
                                            likes: Int.random(in: 5...50),
                                            parentCommentId: commentData.isReply ? baseCommentIdMap[commentData.replyTo ?? ""] : nil
                                        )
                                        
                                        // 保存评论ID和角色名的映射
                                        baseCommentIdMap[commentData.character] = commentId.uuidString
                                        
                                        #if DEBUG
                                        print("📝 创建评论项 #\(index+1): \(commentItem.characterName)")
                                        #endif
                                        comments.append(commentItem)
                                    } else {
                                        #if DEBUG
                                        print("⚠️ 跳过空评论内容 - 角色: \(commenter?.name ?? commentData.character)")
                                        #endif
                                    }
                                    
                                    dispatchGroup.leave()
                                }
                                
                                // 等待所有评论处理完成
                                dispatchGroup.notify(queue: .main) {
                                    #if DEBUG
                                    print("✅ 所有评论处理完成，共\(comments.count)条评论")
                                    #endif
                                    // 按时间排序评论
                                    let sortedComments = comments.sorted { $0.timestamp > $1.timestamp }
                                    promise(.success((contentItem, sortedComments)))
                                }
                            }
                        )
                        .store(in: &self.cancellables)
            } else {
                // 🔒 如果CharacterModel中没有找到，从CharacterSystem获取（备用方案）
                #if DEBUG
                print("⚠️ CharacterModel中未找到角色，尝试从CharacterSystem获取: \(characterID)")
                #endif
                
                self.characterSystem.getCharacter(characterID)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                #if DEBUG
                                print("❌ 获取角色信息失败: \(error.localizedDescription)")
                                #endif
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { character in
                            #if DEBUG
                            print("👤 从CharacterSystem获取角色成功: \(character.name)")
                            #endif
                            
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
                                        #if DEBUG
                                        print("❌ AI生成内容和评论失败: \(error.localizedDescription)")
                                        #endif
                                        
                                        // 显示友好的错误提示给用户
                                        Task { @MainActor in
                                            if let aiError = error as? AINetworkError {
                                                var is403Error = false
                                                if case .httpError(let code) = aiError {
                                                    is403Error = (code == 403)
                                                }
                                                
                                                if !is403Error {
                                                    ToastManager.shared.showToast(message: aiError.localizedDescription)
                                                }
                                            } else {
                                                ToastManager.shared.showToast(message: "生成失败，请稍后重试")
                                            }
                                        }
                                        
                                        promise(.failure(error))
                                    }
                                },
                                receiveValue: { result in
                                    #if DEBUG
                                    print("✅ AI成功生成内容和\(result.comments.count)条评论")
                                    #endif
                                    
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
                                        #if DEBUG
                                        print("⚠️ 警告：AI没有生成任何评论")
                                        #endif
                                        promise(.success((contentItem, [])))
                                        return
                                    }
                                    
                                    // 创建评论项（使用相同的评论处理逻辑）
                                    var comments: [CommentItem] = []
                                    let now = Date()
                                    let dispatchGroup = DispatchGroup()
                                    
                                    #if DEBUG
                                    print("🔄 开始处理\(result.comments.count)条评论...")
                                    #endif
                                    
                                    var baseCommentIdMap: [String: String] = [:]
                                    
                                    for (index, commentData) in result.comments.enumerated() {
                                        dispatchGroup.enter()
                                        
                                        // 🔒 修复：优先从CharacterModel查找评论者角色（包含用户创建的角色）
                                        var commenter: CharacterSystem.CharacterIdentity? = nil
                                        var commenterCharacterModel: CharacterModel? = nil
                                        
                                        // 首先尝试从CharacterModel查找（包含用户创建的角色）
                                        let allCharacterModels = CharacterModel.getAllCharacters()
                                        if let characterModel = allCharacterModels.first(where: { $0.name == commentData.character }) {
                                            commenterCharacterModel = characterModel
                                            
                                            // 将CharacterModel转换为CharacterIdentity
                                            let characterType: CharacterSystem.CharacterType = {
                                                switch characterModel.category {
                                                case .historical: return .historical
                                                case .philosopher: return .historical
                                                case .writer: return .literary
                                                case .animeCharacter: return .anime
                                                case .gameCharacter: return .game
                                                case .filmCharacter: return .movie
                                                case .mythCharacter: return .mythological
                                                case .myCreation: return .custom
                                                case .all: return .historical
                                                }
                                            }()
                                            
                                            commenter = CharacterSystem.CharacterIdentity(
                                                id: characterModel.id,
                                                name: characterModel.name,
                                                type: characterType,
                                                era: characterModel.era,
                                                primaryField: characterModel.profession,
                                                briefDescription: characterModel.bio,
                                                avatarName: characterModel.avatar,
                                                region: "",
                                                contentAffinities: [:],
                                                subtype: nil
                                            )
                                        } else {
                                            // 如果CharacterModel中找不到，从CharacterSystem查找（备用方案）
                                            commenter = self.characterSystem.findCharacterByName(commentData.character)
                                        }
                                        
                                        // 🔒 检查评论者角色是否被屏蔽
                                        if let commenter = commenter {
                                            let isUserCreated = commenter.id.hasPrefix("custom_")
                                            
                                            if isUserCreated {
                                                if BlockedCategoriesManager.shared.isCategoryBlocked(.myCreation) {
                                                    dispatchGroup.leave()
                                                    continue
                                                }
                                            } else {
                                                if let characterModel = commenterCharacterModel ?? CharacterModel.getAllCharacters().first(where: { $0.id == commenter.id }) {
                                                    if BlockedCategoriesManager.shared.isCategoryBlocked(characterModel.category) {
                                                        dispatchGroup.leave()
                                                        continue
                                                    }
                                                }
                                            }
                                        }
                                        
                                        let timestamp = now.addingTimeInterval(-Double((result.comments.count - index) * 120))
                                        
                                        if !commentData.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            let commentId = UUID()
                                            
                                            // 🔒 修复：使用CharacterModel的avatar（如果是用户创建的角色）
                                            let avatarName: String = {
                                                if let characterModel = commenterCharacterModel {
                                                    return characterModel.avatar
                                                } else {
                                                    return commenter?.avatarName ?? "person.circle.fill"
                                                }
                                            }()
                                            
                                            let commentItem = CommentItem(
                                                id: commentId.uuidString,
                                                characterId: commenter?.id ?? "unknown",
                                                characterName: commenter?.name ?? commentData.character,
                                                characterAvatar: avatarName,
                                                characterRole: commenter?.primaryField ?? "unknown",
                                                content: commentData.comment,
                                                timestamp: timestamp,
                                                likes: Int.random(in: 5...50),
                                                parentCommentId: commentData.isReply ? baseCommentIdMap[commentData.replyTo ?? ""] : nil
                                            )
                                            
                                            baseCommentIdMap[commentData.character] = commentId.uuidString
                                            comments.append(commentItem)
                                        }
                                        
                                        dispatchGroup.leave()
                                    }
                                    
                                    dispatchGroup.notify(queue: .main) {
                                        #if DEBUG
                                        print("✅ 所有评论处理完成，共\(comments.count)条评论")
                                        #endif
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
    }
    
    /**
     * 根据内容类型获取随机角色
     * @param contentType 内容类型
     * @return Future<CharacterSystem.CharacterIdentity, Error>
     */
    func getRandomCharacterForContentType(_ contentType: ContentType) -> Future<CharacterSystem.CharacterIdentity, Error> {
        return Future { promise in
            // 使用角色轮换系统获取平衡分配的角色
            let characters = CharacterRotationSystem.shared.getRecommendedCharacters(count: 1)
            if let character = characters.first {
                promise(.success(character))
            } else {
                promise(.failure(ContentError.noCharactersAvailable))
            }
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
            // 获取随机角色
            self.getRandomCharacterForContentType(contentType)
                .flatMap { character in
                    // 使用选定角色生成内容
                    self.generateContentWithComments(for: character.id, contentType: contentType, topic: topic)
                }
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { result in
                        promise(.success(result))
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    /**
     * 生成多篇带评论的内容
     * 适用于批量生成内容
     */
    func generatePostsWithComments(
        contentType: ContentType,
        count: Int = 3,
        topic: String? = nil
    ) -> Future<[(contentItem: ContentItem, comments: [CommentItem])], Error> {
        return Future { promise in
            // 创建一个内容生成任务组
            var futures: [AnyPublisher<(contentItem: ContentItem, comments: [CommentItem]), Never>] = []
            
            // 添加指定数量的内容生成任务
            for _ in 0..<count {
                let future = self.generateRandomContentWithComments(contentType: contentType, topic: topic)
                    .catch { _ in
                        Empty<(contentItem: ContentItem, comments: [CommentItem]), Never>(completeImmediately: true)
                    }
                    .eraseToAnyPublisher()
                futures.append(future)
            }
            
            // 合并所有任务结果
            Publishers.MergeMany(futures)
                .collect()
                .sink(
                    receiveValue: { results in
                        promise(.success(results))
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    /**
     * 批量生成随机内容和评论
     * @param contentType 内容类型
     * @param count 生成数量
     * @return Future<[(contentItem: ContentItem, comments: [CommentItem])], Error>
     */
    func generateRandomContentBatchWithComments(contentType: ContentType, count: Int) -> Future<[(contentItem: ContentItem, comments: [CommentItem])], Error> {
        return Future { promise in
            var results: [(contentItem: ContentItem, comments: [CommentItem])] = []
            let group = DispatchGroup()
            var errors: [Error] = []
            
            for _ in 0..<count {
                group.enter()
                
                self.generateRandomContentWithComments(contentType: contentType)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                errors.append(error)
                                group.leave()
                            }
                        },
                        receiveValue: { contentItem, comments in
                            results.append((contentItem: contentItem, comments: comments))
                            group.leave()
                        }
                    )
                    .store(in: &self.cancellables)
            }
            
            group.notify(queue: .main) {
                if results.isEmpty && !errors.isEmpty {
                    promise(.failure(errors.first ?? ContentError.unknown))
                } else {
                    promise(.success(results))
                }
            }
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
        case unknown
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
 * 评论项结果
 */
struct CommentItemResult {
    let character: String
    let comment: String
    let isReply: Bool
    let replyTo: String?
    
    init(character: String, comment: String, isReply: Bool = false, replyTo: String? = nil) {
        self.character = character
        self.comment = comment
        self.isReply = isReply
        self.replyTo = replyTo
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
public struct CommentItem {
    public let id: String
    public let characterId: String
    public let characterName: String
    public let characterAvatar: String?
    public let characterRole: String
    public let content: String
    public let timestamp: Date
    public let likes: Int
    public let parentCommentId: String?
    
    public var isReply: Bool {
        return parentCommentId != nil
    }
    
    public init(id: UUID, characterId: String, characterName: String, characterAvatar: String?, characterRole: String, content: String, timestamp: Date, likes: Int, parentCommentId: String?) {
        self.id = id.uuidString
        self.characterId = characterId
        self.characterName = characterName
        self.characterAvatar = characterAvatar ?? "person.circle.fill"
        self.characterRole = characterRole
        self.content = content
        self.timestamp = timestamp
        self.likes = likes
        self.parentCommentId = parentCommentId
    }
    
    public init(id: String, characterId: String, characterName: String, characterAvatar: String?, characterRole: String, content: String, timestamp: Date, likes: Int, parentCommentId: String?) {
        self.id = id
        self.characterId = characterId
        self.characterName = characterName
        self.characterAvatar = characterAvatar ?? "person.circle.fill"
        self.characterRole = characterRole
        self.content = content
        self.timestamp = timestamp
        self.likes = likes
        self.parentCommentId = parentCommentId
    }
}

/**
 * 处理评论数据，将原始评论数据转换为CommentItem对象
 */
public func processComments(
    _ commentItems: [(character: String, comment: String, isReply: Bool, replyTo: String?)],
    contentID: String
) -> [CommentItem] {
    #if DEBUG
    print("🔄 处理\(commentItems.count)条评论...")
    #endif
    
    var comments: [CommentItem] = []
    var commentMap: [String: String] = [:] // 角色名到评论ID的映射
    
    // 第一步：创建所有非回复评论
    for item in commentItems where !item.isReply {
        // 获取角色信息
        if let characterInfo = CharacterSystem.shared.findCharacterByName(item.character) {
            // 创建评论
            let commentId = UUID().uuidString
            let comment = CommentItem(
                id: commentId,
                characterId: characterInfo.id,
                characterName: characterInfo.name,
                characterAvatar: characterInfo.avatarName,
                characterRole: characterInfo.primaryField,
                content: item.comment,
                timestamp: Date(),
                likes: Int.random(in: 1...50),
                parentCommentId: nil
            )
            
            // 添加到评论列表
            comments.append(comment)
            
            // 保存角色名到评论ID的映射
            commentMap[item.character] = commentId
        }
    }
    
    // 第二步：处理回复评论
    for item in commentItems where item.isReply {
        // 获取回复者角色信息
        if let replierInfo = CharacterSystem.shared.findCharacterByName(item.character) {
            // 查找父评论ID
            let parentCommentId = item.replyTo.flatMap { commentMap[$0] }
            
            // 创建回复评论
            let comment = CommentItem(
                id: UUID().uuidString,
                characterId: replierInfo.id,
                characterName: replierInfo.name,
                characterAvatar: replierInfo.avatarName,
                characterRole: replierInfo.primaryField,
                content: item.comment,
                timestamp: Date(),
                likes: Int.random(in: 1...30),
                parentCommentId: parentCommentId
            )
            
            // 添加到评论列表
            comments.append(comment)
        }
    }
    
    // 保存评论到评论存储
    CommentStore.shared.saveComments(comments, forContentID: contentID)
    
    #if DEBUG
    print("✅ 成功处理\(comments.count)条评论")
    #endif
    return comments
} 