import Foundation
import SwiftUI
import Combine
import SwiftData

/// 梦幻联动管理器
class MultiChatManager: ObservableObject {
    // 发布的状态
    @Published var messages: [ChatMessage] = []
    @Published var hasStartedConversation = false
    @Published var isGeneratingResponse = false
    @Published var shouldShowConversationEndIndicator = false // 新增：是否显示对话结束指示器

    @Published var isFirstTimeStart = true // 新增：标记是否为首次开始对话
    
    // 私有属性
    private var characters: [CharacterModel] = []
    private var mode: ChatMode = .freeTalk
    private var theme: String = ""
    private var userRole: UserRole = .observer
    private var multiChatContext: MultiChatContext = MultiChatContext() // 新增：梦幻联动上下文
    
    // 数据持久化
    private var currentSession: MultiPersonChatSession?
    private var modelContext: ModelContext?
    private let dataService = MultiPersonChatDataService.shared
    
    // 定时器和取消标记
    private var thinkingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // 新增：对话状态追踪
    private var lastSpeakerIds: [String] = [] // 最近发言者历史
    private var topicProgression: [String] = [] // 话题发展轨迹
    private var characterMoods: [String: CharacterMood] = [:] // 角色情绪状态
    private var userMessagesAlreadySaved = false // 标记用户消息是否已保存
    
    // 固定的时间设置（使用慢节奏的设置）
    private let responseDelay: TimeInterval = 2.5 // 消息间隔时间
    private let thinkingTime: TimeInterval = 1.0  // 思考显示时间
    
    // MARK: - 公开方法
    
    /// 开始对话
    /// - Parameters:
    ///   - characters: 参与对话的角色
    ///   - mode: 对话模式
    ///   - theme: 对话主题
    ///   - userRole: 用户角色
    ///   - modelContext: SwiftData模型上下文
    func startConversation(characters: [CharacterModel], mode: ChatMode, theme: String, userRole: UserRole, modelContext: ModelContext? = nil) {
        self.characters = characters
        self.mode = mode
        self.theme = theme
        self.userRole = userRole
        self.modelContext = modelContext
        
        // 不立即创建会话，等到有AI消息时再创建
        // currentSession 保持为 nil，在 createSessionIfNeeded() 中按需创建
        
        // 延迟一小段时间后显示对话开始
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.hasStartedConversation = true
            
            // 生成初始消息
            self.generateInitialMessages()
        }
    }
    
    /// 发送用户消息（观察者模式）
    /// - Parameter content: 消息内容
    func sendUserMessage(content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // 隐藏对话结束指示器
        shouldShowConversationEndIndicator = false
        
            // 观察者模式：显示为用户引导消息
        let userMessage = ChatMessage(
            characterId: "user",
            content: content,
            timestamp: Date(),
            isUserMessage: true
        )
        
        // 使用动画添加消息
        withAnimation(.easeInOut(duration: 0.3)) {
        messages.append(userMessage)
        }
        
        // 保存用户消息到数据库
        saveMessage(userMessage, messageType: "user")
        
        // 💡 用户体验优化：即时显示"其他角色正在思考"的提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 显示角色们开始思考的状态
            self.showCharactersThinking()
        }
        
        // 模拟AI回复
        generateAIResponse()
    }
    
    /// 发送用户引导消息
    /// - Parameter content: 引导内容
    func sendUserGuidance(content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // 隐藏对话结束指示器
        shouldShowConversationEndIndicator = false
        
        // 创建用户引导消息
        let guidanceMessage = ChatMessage(
            characterId: "user",
            content: content,
            timestamp: Date(),
            isUserMessage: true
        )
        messages.append(guidanceMessage)
        
        // 保存用户引导消息到数据库
        saveMessage(guidanceMessage, messageType: "guidance")
        
        // 根据引导内容生成AI回复
        generateAIResponse()
    }
    
    /// 继续对话
    func continueConversation() {
        // 防止重复点击
        guard !isGeneratingResponse else { return }
        
        // 隐藏对话结束指示器
        shouldShowConversationEndIndicator = false
        
        // 标记为非首次开始
        isFirstTimeStart = false
        
        // 生成AI回复
        generateAIResponse()
    }
    

    
    /// 更新梦幻联动上下文
    private func updateMultiChatContext(with message: ChatMessage, character: CharacterModel) {
        // 更新最近发言者历史
        lastSpeakerIds.append(character.id)
        if lastSpeakerIds.count > 5 {
            lastSpeakerIds.removeFirst()
        }
        
        // 更新对话深度
        multiChatContext.conversationDepth += 1
        
        // 简单的话题检测和更新
        if let topic = extractTopic(from: message.content) {
            multiChatContext.updateTopic(topic)
        }
        
        // 更新角色情绪（简化版本）
        let mood = detectCharacterMood(from: message.content)
        characterMoods[character.id] = mood
    }
    
    /// 从消息中提取话题（简化版本）
    private func extractTopic(from content: String) -> String? {
        // 这里可以实现更复杂的话题提取逻辑
        // 暂时返回主题
        return theme.isEmpty ? nil : theme
    }
    
    /// 检测角色情绪（简化版本）
    private func detectCharacterMood(from content: String) -> CharacterMood {
        // 简单的情绪检测逻辑
        if content.contains("！") || content.contains("激动") || content.contains("兴奋") {
            return .excited
        } else if content.contains("？") || content.contains("疑问") || content.contains("质疑") {
            return .disagreeing
        } else if content.contains("思考") || content.contains("深入") || content.contains("哲学") {
            return .thoughtful
        } else if content.contains("好奇") || content.contains("想知道") {
            return .curious
        } else if content.contains("启发") || content.contains("灵感") {
            return .inspired
        } else {
            return .calm
        }
    }
    
    // MARK: - 私有方法
    
    /// 生成初始消息 - 初始化完成，等待用户开始
    private func generateInitialMessages() {
        // ✅ 初始化完成，等待用户点击"开始对话"按钮
        #if DEBUG
        print("💬 多角色聊天初始化完成，等待用户开始对话...")
        #endif
        
        // 保持 isFirstTimeStart = true，让按钮显示"开始对话"
        // 用户点击按钮时才会调用 continueConversation() 开始对话
    }
    
    /// 生成AI回复 - 使用批量生成优化
    private func generateAIResponse() {
        isGeneratingResponse = true
        
        // 清理预先显示的思考状态
        messages.removeAll { $0.isThinking }
        
        // 检查最后一条消息是否是用户发送的（观察者模式）
        let lastUserMessage: String? = {
            if let lastMessage = messages.last, lastMessage.isUserMessage {
                return lastMessage.content
            }
            return nil
        }()
        
        // 获取用户名字（从UserProfileManager获取）
        let userName = UserProfileManager.shared.getCurrentUsername()
        
        // 使用新的批量生成服务
        MultiCharacterChatService.shared.generateMultiCharacterChat(
            characters: characters,
            conversationHistory: messages,
            userMessage: lastUserMessage,
            chatTheme: theme,
            maxResponders: characters.count, // 用户选择多少角色就让多少角色参与对话
            userRole: .observer,
            userName: userName
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let responses):
                    #if DEBUG
                    print("✅ 批量生成成功，获得\(responses.count)个角色回复")
                    #endif
                    self.addBatchResponses(responses)
                    
                case .failure(let error):
                    #if DEBUG
                    print("❌ 批量生成失败: \(error.localizedDescription)")
                    #endif
                    // 直接显示失败，不使用降级方案
                }
                
                self.isGeneratingResponse = false
            }
        }
    }
    
    /// 添加批量回复到对话中
    private func addBatchResponses(_ responses: [(characterId: String, content: String)]) {
        // 保持API返回的原始顺序，不再重新排序
        #if DEBUG
        print("📥 按原始顺序添加 \(responses.count) 个角色回复")
        #endif
        
        // 逐个添加回复，带有时间间隔
        for (index, response) in responses.enumerated() {
            let delay = Double(index) * responseDelay + 0.2
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // 先显示思考状态
                let thinkingMessage = ChatMessage(
                    characterId: response.characterId,
                    content: "",
                    timestamp: Date(),
                    isThinking: true
                )
                
                #if DEBUG
                print("🤔 添加思考消息 - 角色: \(response.characterId)")
                #endif
                #if DEBUG
                print("📊 思考前消息数量: \(self.messages.count)")
                #endif
                
                self.messages.append(thinkingMessage)
                
                #if DEBUG
                print("📊 思考后消息数量: \(self.messages.count)")
                #endif
                
                // 强制触发UI更新
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
                
                // 思考一段时间后显示真实回复
                DispatchQueue.main.asyncAfter(deadline: .now() + self.thinkingTime) {
                    // 移除思考消息
                    #if DEBUG
                    print("🗑️ 移除思考消息 - 角色: \(response.characterId)")
                    #endif
                    #if DEBUG
                    print("📊 移除前消息数量: \(self.messages.count)")
                    #endif
                    
                    self.messages.removeAll { $0.id == thinkingMessage.id }
                    
                    #if DEBUG
                    print("📊 移除后消息数量: \(self.messages.count)")
                    #endif
                    
                    // 添加实际回复
                    let responseMessage = ChatMessage(
                        characterId: response.characterId,
                        content: response.content,
                        timestamp: Date()
                    )
                    
                    #if DEBUG
                    print("🔧 准备添加消息到UI - 角色: \(response.characterId), 内容长度: \(response.content.count)")
                    #endif
                    #if DEBUG
                    print("📊 当前消息数量: \(self.messages.count)")
                    #endif
                    
                    self.messages.append(responseMessage)
                    
                    // 保存角色回复到数据库
                    self.saveMessage(responseMessage, messageType: "text")
                    
                    #if DEBUG
                    print("✅ 消息已添加到数组 - 新的消息数量: \(self.messages.count)")
                    #endif
                    #if DEBUG
                    print("💬 添加角色回复: \(response.characterId) -> \(response.content.prefix(20))...")
                    #endif
                    
                    // 强制触发UI更新
                    DispatchQueue.main.async {
                        self.objectWillChange.send()
                    }
                    
                    // 更新对话上下文
                    if let character = self.characters.first(where: { $0.id == response.characterId }) {
                        self.updateMultiChatContext(with: responseMessage, character: character)
                    } else {
                        #if DEBUG
                        print("⚠️ 未找到角色: \(response.characterId)")
                        #endif
                    }
                    
                    // 如果这是最后一个角色的回复，显示对话结束指示器
                    if index == responses.count - 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.shouldShowConversationEndIndicator = true
                            #if DEBUG
                            print("🏁 显示对话结束指示器")
                            #endif
                        }
                    }
                }
            }
        }
    }
    

    

    
    /// 生成下一个回复
    /// - Parameter delay: 延迟时间
    private func generateNextResponse(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // 观察者模式下自动继续对话
                self.generateAIResponse()
            }
        }
    

    
    /// 获取下一个回复的角色
    /// - Returns: 角色模型
    private func getNextRespondingCharacter() -> CharacterModel? {
        // 在实际实现中，我们需要更复杂的逻辑来决定下一个回复的角色
        // 现在我们简单地随机选择一个不是用户扮演的角色
        
        // 观察者模式下，所有角色都可以发言
        let availableCharacters = characters
        
        // 如果最近几条消息中有角色发言，尽量避免同一角色连续发言
        if let lastSpeakerId = messages.last(where: { !$0.isThinking })?.characterId {
            // 优先选择其他角色
            let otherCharacters = availableCharacters.filter { $0.id != lastSpeakerId }
            if !otherCharacters.isEmpty {
                return otherCharacters.randomElement()
            }
        }
        
        return availableCharacters.randomElement()
    }
    
    /// 显示多个角色开始思考的状态
    private func showCharactersThinking() {
        // 只在非生成状态时显示思考提示
        guard !isGeneratingResponse else { return }
        
        // 选择2-3个角色显示思考状态
        let thinkingCharacters = characters.prefix(mode == .freeTalk ? 2 : 3)
        
        for (index, character) in thinkingCharacters.enumerated() {
            // 错开显示时间，让思考状态更自然
            let delay = Double(index) * 0.3
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let thinkingMessage = ChatMessage(
                    characterId: character.id,
                    content: "",
                    timestamp: Date(),
                    isThinking: true
                )
                
                // 只有在还没开始正式生成时才添加思考状态
                if !self.isGeneratingResponse {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.messages.append(thinkingMessage)
                    }
                    
                    // 2秒后如果还没开始正式生成，就移除这个思考状态
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if !self.isGeneratingResponse {
                            self.messages.removeAll { $0.id == thinkingMessage.id }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 数据持久化
    
    /// 按需创建会话（仅在有AI消息时创建）
    private func createSessionIfNeeded() {
        #if DEBUG
        print("🔍 检查会话创建需求:")
        #endif
        #if DEBUG
        print("  - currentSession存在: \(currentSession != nil)")
        #endif
        #if DEBUG
        print("  - modelContext存在: \(modelContext != nil)")
        #endif
        #if DEBUG
        print("  - characters数量: \(characters.count)")
        #endif
        #if DEBUG
        print("  - theme: \"\(theme)\"")
        #endif
        
        // 如果会话已存在或没有ModelContext，则不创建
        guard currentSession == nil, let modelContext = modelContext else { 
            #if DEBUG
            print("  - 跳过会话创建（已存在或缺少ModelContext）")
            #endif
            return 
        }
        
        #if DEBUG
        print("  - 开始创建新会话...")
        #endif
        
        // 创建新的聊天会话
        currentSession = dataService.createChatSession(
            topic: theme,
            participants: characters,
            chatMode: mode,
            chatTheme: theme,
            userRole: userRole,
            modelContext: modelContext
        )
        
        #if DEBUG
        print("✅ 按需创建聊天会话: \(currentSession?.id ?? "创建失败")")
        #endif
    }
    
    /// 保存消息到数据库
    private func saveMessage(_ message: ChatMessage, messageType: String) {
        #if DEBUG
        print("🔍 开始保存消息 - 类型: \(message.isUserMessage ? "用户" : "AI"), 内容: \"\(String(message.content.prefix(30)))...\"")
        #endif
        
        guard let modelContext = modelContext else {
            #if DEBUG
            print("⚠️ 无法保存消息：缺少ModelContext")
            #endif
            return
        }
        
        #if DEBUG
        print("🔍 保存前会话状态: currentSession=\(currentSession?.id ?? "nil")")
        #endif
        
        // 确保会话已创建（无论是用户消息还是AI消息）
        createSessionIfNeeded()
        
        #if DEBUG
        print("🔍 保存后会话状态: currentSession=\(currentSession?.id ?? "nil")")
        #endif
        
        // 如果是AI消息，保存之前未保存的用户消息（向后兼容）
        if !message.isUserMessage {
            saveUnsavedUserMessages()
        }
        
        guard let sessionId = currentSession?.id else {
            #if DEBUG
            print("❌ 无法保存消息：缺少会话ID，会话创建可能失败")
            #endif
            return
        }
        
        // 获取角色名称
        let characterName: String
        if message.characterId == "user" {
            characterName = "用户"
        } else {
            characterName = characters.first { $0.id == message.characterId }?.name ?? message.characterId
        }
        
        let _ = dataService.saveChatMessage(
            sessionId: sessionId,
            characterId: message.characterId,
            characterName: characterName,
            content: message.content,
            isUserMessage: message.isUserMessage,
            messageType: messageType,
            modelContext: modelContext
        )
        
        #if DEBUG
        print("✅ 已保存消息到数据库 - 类型: \(message.isUserMessage ? "用户" : "AI"), 内容: \"\(String(message.content.prefix(50)))...\"")
        #endif
    }
    
    /// 保存所有未保存的用户消息
    private func saveUnsavedUserMessages() {
        guard let sessionId = currentSession?.id,
              let modelContext = modelContext,
              !userMessagesAlreadySaved else { return }
        
        // 找出所有用户消息
        let userMessages = messages.filter { $0.isUserMessage }
        
        // 保存用户消息
        if !userMessages.isEmpty {
            for userMessage in userMessages {
                let _ = dataService.saveChatMessage(
                    sessionId: sessionId,
                    characterId: userMessage.characterId,
                    characterName: "用户",
                    content: userMessage.content,
                    isUserMessage: true,
                    messageType: "guidance",
                    modelContext: modelContext
                )
            }
            
            userMessagesAlreadySaved = true // 标记已保存
            #if DEBUG
            print("✅ 已保存 \(userMessages.count) 条用户消息")
            #endif
        }
    }
    
    /// 加载历史对话
    func loadChatHistory(sessionId: String, modelContext: ModelContext, characters: [CharacterModel] = []) {
        self.modelContext = modelContext
        
        // 加载会话信息
        if let session = dataService.getChatSession(sessionId: sessionId, modelContext: modelContext) {
            currentSession = session
            
            // 🔧 设置角色数据 - 从参与者ID加载角色信息
            if characters.isEmpty {
                // 如果没有传入角色数据，从会话的participantIds重建角色列表
                // 多人聊天不受分类屏蔽影响，使用不过滤的版本
                self.characters = session.participantIds.compactMap { characterId in
                    CharacterModel.loadAllCharactersWithoutFilter().first { $0.id == characterId }
                }
                #if DEBUG
                print("✅ 从会话重建角色列表：\(self.characters.map { $0.name }.joined(separator: ", "))")
                #endif
            } else {
                // 使用传入的角色数据
                self.characters = characters
                #if DEBUG
                print("✅ 使用传入角色数据：\(characters.map { $0.name }.joined(separator: ", "))")
                #endif
            }
            
            // 🔧 设置其他会话属性
            self.mode = ChatMode(rawValue: session.chatMode) ?? .freeTalk
            self.theme = session.chatTheme
            self.userRole = UserRole(rawValue: session.userRole) ?? .observer
            
            #if DEBUG
            print("✅ 已设置当前会话: \(session.topic)")
            #endif
            #if DEBUG
            print("   - 角色数量: \(self.characters.count)")
            #endif
            #if DEBUG
            print("   - 对话模式: \(self.mode)")
            #endif
            #if DEBUG
            print("   - 用户角色: \(self.userRole)")
            #endif
        }
        
        // 加载历史消息
        let dbMessages = dataService.getChatMessages(sessionId: sessionId, modelContext: modelContext)
        let chatMessages = dataService.convertToChatMessages(dbMessages)
        
        DispatchQueue.main.async {
            self.messages = chatMessages
            self.hasStartedConversation = !chatMessages.isEmpty
            self.isFirstTimeStart = false
            #if DEBUG
            print("✅ 已加载历史对话：\(chatMessages.count) 条消息")
            #endif
        }
    }
    
    /// 获取当前会话ID
    func getCurrentSessionId() -> String? {
        return currentSession?.id
    }
    
    // MARK: - 析构函数
    
    deinit {
        thinkingTimer?.invalidate()
        cancellables.forEach { $0.cancel() }
    }
} 

// MARK: - 新增数据模型

/// 角色情绪状态
enum CharacterMood: String, CaseIterable {
    case calm = "平静"
    case excited = "兴奋"
    case thoughtful = "深思"
    case curious = "好奇"
    case disagreeing = "质疑"
    case inspired = "受启发"
    
    var responseStyle: String {
        switch self {
        case .calm: return "平和地"
        case .excited: return "激动地"
        case .thoughtful: return "沉思地"
        case .curious: return "好奇地"
        case .disagreeing: return "质疑地"
        case .inspired: return "受启发地"
        }
    }
}

/// 梦幻联动上下文
class MultiChatContext {
    var currentTopic: String = ""
    var topicIntensity: Double = 0.5 // 话题激烈程度
    var agreementLevel: Double = 0.5 // 观点一致程度
    var conversationDepth: Int = 0 // 对话深度层级
    
    func updateTopic(_ newTopic: String) {
        currentTopic = newTopic
        conversationDepth += 1
    }
    
    // MARK: - 类型转换辅助函数
    
    /// 将UserRole转换为MultiChatUserRole（观察者模式）
    private func convertToMultiChatUserRole(_ userRole: UserRole) -> MultiChatUserRole {
        return .observer
    }
} 