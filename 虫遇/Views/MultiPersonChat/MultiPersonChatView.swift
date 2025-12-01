import SwiftUI
import SwiftData

// 导入包含圆角扩展的文件
import UIKit

struct MultiPersonChatView: View {
    // 从上一个视图传入的属性
    let selectedCharacters: [CharacterModel]
    let chatMode: ChatMode
    let chatTheme: String
    let userRole: UserRole
    let historicalSessionId: String? // 添加历史会话ID参数
    
    // 状态
    @StateObject private var chatManager = MultiChatManager()
    @State private var inputText = ""
    @State private var scrollToBottom = false
    @State private var showUserGuidanceInput = false
    @State private var userGuidanceText = ""
    @State private var hasShownGuidanceTooltip = false
    @State private var isSending = false
    @State private var keyboardVisible = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var textViewHeight: CGFloat = 36 // 添加文本框高度状态
    @State private var viewOffset: CGFloat = 0 // 添加视图偏移状态

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext
    
    // 角色ID到颜色索引的映射，确保每个角色使用不同的颜色
    private var characterColorMap: [String: Int] {
        var map: [String: Int] = [:]
        for (index, character) in selectedCharacters.enumerated() {
            map[character.id] = index % 4 // 循环使用4种颜色
        }
        return map
    }
    
    // 获取角色主题色
    private var characterThemeColor: Color {
        return Color(hex: "9A8BB0") // 默认历史感紫色
    }
    
    // 添加环境变量获取安全区域值
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    // 计算实际底部安全区域高度
    private var bottomSafeAreaHeight: CGFloat {
        return safeAreaInsets?.bottom ?? 34 // 使用默认值34，适配大部分设备
    }
    
    // 临时测试方法 - 添加测试消息
    private func addTestMessages() {
        if chatManager.messages.isEmpty {
            let testMessages = [
                ChatMessage(
                    characterId: selectedCharacters.first?.id ?? "test1",
                    content: "这是第一条测试消息，用来验证分享功能是否正常工作。",
                    timestamp: Date().addingTimeInterval(-60),
                    isUserMessage: false
                ),
                ChatMessage(
                    characterId: selectedCharacters.count > 1 ? selectedCharacters[1].id : "test2",
                    content: "这是第二条测试消息，我们来看看能否正确生成分享卡片。",
                    timestamp: Date().addingTimeInterval(-30),
                    isUserMessage: false
                ),
                ChatMessage(
                    characterId: "user",
                    content: "这是用户的测试消息。",
                    timestamp: Date(),
                    isUserMessage: true
                )
            ]
            
            DispatchQueue.main.async {
                self.chatManager.messages.append(contentsOf: testMessages)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // 背景 - 与单聊一致的多层彩色渐变
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "FFF0F5"),
                        Color(hex: "FFE8F0"),
                        Color(hex: "F0E8FF"),
                        Color(hex: "E8F4FF"),
                        Color(hex: "FFE8D4")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "FFE8F0").opacity(0.4),
                        Color(hex: "FFD4E5").opacity(0.3),
                        Color.clear,
                        Color(hex: "E8F4FF").opacity(0.3),
                        Color(hex: "F0E8FF").opacity(0.4)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 300)
                .frame(maxHeight: .infinity, alignment: .top)
                
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.8),
                        Color(hex: "FFFEF5").opacity(0.7),
                        Color(hex: "FFF9E6").opacity(0.5),
                        Color(hex: "FFE8CC").opacity(0.3),
                        Color.clear
                    ]),
                    center: .topLeading,
                    startRadius: 5,
                    endRadius: 450
                )
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .ignoresSafeArea(.all)
            .allowsHitTesting(false)
            
            VStack(spacing: 0) {
                // 顶部信息区
                ChatHeader(
                    chatTheme: chatTheme,
                    participants: selectedCharacters,
                    onBackTapped: { presentationMode.wrappedValue.dismiss() },
                    onShareTapped: { shareConversation() }
                )
                .background(Color.clear)
                

                
                // 主对话区域
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // 如果没有消息，显示引导界面
                            if chatManager.messages.isEmpty && !chatManager.isGeneratingResponse {
                                welcomeSection
                                    .padding(.top, 40)
                                    .id("welcomeSection")
                            }
                            
                            ForEach(chatManager.messages) { message in
                                HStack(alignment: .top, spacing: 12) {
                                    // 分享模式下的选择框
                                    if isShareMode {
                                        Button(action: {
                                            toggleMessageSelection(message.id.uuidString)
                                        }) {
                                            Image(systemName: selectedMessages.contains(message.id.uuidString) ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 20))
                                                .foregroundColor(selectedMessages.contains(message.id.uuidString) ? characterThemeColor : .gray.opacity(0.6))
                                                .animation(.spring(response: 0.3), value: selectedMessages.contains(message.id.uuidString))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    
                                    // 原有的消息内容
                                    VStack {
                                        // 🎯 判断消息显示类型
                                        if message.isUserMessage {
                                            // 用户引导消息 - 右侧显示
                                            UserMessageBubble(message: message)
                                        } else if isUserPlayingCharacter(message.characterId) {
                                            // 用户扮演的角色消息 - 右侧显示
                                            UserRolePlayingBubble(message: message, character: selectedCharacters.first(where: { $0.id == message.characterId })!)
                                        } else if let character = selectedCharacters.first(where: { $0.id == message.characterId }) {
                                            // AI角色消息 - 左侧显示，传入颜色索引确保不同角色使用不同颜色
                                            ChatBubble(
                                                message: message,
                                                character: character,
                                                colorIndex: characterColorMap[character.id] ?? 0
                                            )
                                        }
                                    }
                                    .opacity(isShareMode ? 0.8 : 1.0)
                                    .animation(.easeInOut(duration: 0.3), value: isShareMode)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if isShareMode {
                                        toggleMessageSelection(message.id.uuidString)
                                    }
                                }
                                .id(message.id)
                            }
                            
                            // 对话结束指示器
                            if chatManager.shouldShowConversationEndIndicator {
                                ConversationEndIndicator()
                                    .padding(.top, 8)
                                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                                    .id("conversationEndIndicator")
                            }
                            
                            // 底部占位区域 - 动态调整高度确保内容能滚动到合适位置
                            Color.clear
                                .frame(height: keyboardVisible ? 300 : 180)
                                .id("bottomId")
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 16)
                        .padding(.bottom, keyboardVisible ? 80 : 30)
                    }
                    // 监听滚动到底部的通知
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ScrollToBottom"))) { notification in
                        let anchor: UnitPoint = (notification.userInfo?["anchor"] as? String == "center") ? .center : .bottom
                                withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo("bottomId", anchor: anchor)
                                }
                            }
                    .onChange(of: chatManager.messages.count) {
                        // 滚动到最新消息，使用center锚点让消息显示在更合适的位置
                        if !chatManager.messages.isEmpty {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("bottomId", anchor: .center)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 0) // 添加一个弹性空间，将输入框推到底部
                
                // 用户引导输入框或标准输入栏
                if showUserGuidanceInput {
                    userGuidanceInputView
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if case .observer = userRole {
                    // 观察者模式：在分享模式下显示分享栏，否则只保留占位
                    if isShareMode {
                        ShareModeBottomBar(
                            selectedCount: selectedMessages.count,
                            onCancel: {
                                exitShareMode()
                            },
                            onShare: {
                                generateAndShareCards()
                            }
                        )
                        .background(DesignSystem.Colors.background)
                        .edgesIgnoringSafeArea(.bottom)
                    } else {
                        Color.clear.frame(height: bottomSafeAreaHeight)
                    }
                } else {
                    // 参与者模式：显示输入框
                    participantInputBar
                }
            }
            .overlay(
                // 引导按钮 - 固定在右下角
                // 只在观察者模式下显示引导按钮，分享模式下隐藏避免重叠
                Group {
                    if case .observer = userRole, !isShareMode {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                guidanceButton()
                                    .padding(.trailing, 16)
                                    .padding(.bottom, 80)
                            }
                        }
                        .transition(.opacity.combined(with: .scale))
                    }
                }
            )
            // 在屏幕底部覆盖显示"继续对话"按钮（仅观察者模式且非分享模式）
            .overlay(alignment: .bottom) {
                if case .observer = userRole, !showUserGuidanceInput, !isShareMode {
                    continueChatButton
                }
            }
        }
        .multiChatKeyboardAdaptive(dismissOnTap: true, safeArea: 50) // 启用点击空白区域关闭键盘，并增加安全区域
        .edgesIgnoringSafeArea(.bottom) // 忽略底部安全区域，确保输入框贴合屏幕底部
        .fullScreenCover(isPresented: $showShareModal) {
            MultiChatShareModalView(
                isPresented: $showShareModal,
                previewCards: previewCards,
                saveCards: saveCards,
                chatTheme: chatTheme
            )
        }
        .onAppear {
            // 根据是否有历史会话ID决定是新对话还是加载历史对话
            if let sessionId = historicalSessionId {
                // 加载历史对话
                chatManager.loadChatHistory(sessionId: sessionId, modelContext: modelContext, characters: selectedCharacters)
            } else {
                // 开始新对话
            chatManager.startConversation(
                characters: selectedCharacters,
                mode: chatMode,
                theme: chatTheme,
                    userRole: userRole,
                    modelContext: modelContext
            )
            }
            
            // 添加键盘通知监听
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                handleKeyboardNotification(notification, isShowing: true)
            }
            
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { notification in
                handleKeyboardNotification(notification, isShowing: false)
            }
        }
        .onDisappear {
            // 移除键盘通知监听
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        }
        // 修改键盘状态变化处理
        .onChange(of: keyboardVisible) { _, newValue in
            if newValue && !chatManager.messages.isEmpty {
                // 键盘弹出时，确保消息可见，使用center锚点
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ScrollToBottom"),
                            object: nil,
                            userInfo: ["anchor": "center"]
                    )
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // 继续对话按钮 - 使用 safeAreaInset 固定在屏幕底部
    private var continueChatButton: some View {
        // 占位视图本身不占空间，把按钮插入到底部安全区域
        Color.clear
            .frame(height: 0)
            .safeAreaInset(edge: .bottom) {
            Button(action: continueConversation) {
                HStack(spacing: 8) {
                    if chatManager.isGeneratingResponse {
                        // 加载状态：显示三个点动画
                        LoadingDotsView()
                    } else {
                        // 正常状态：根据是否首次显示不同文字
                        Text(chatManager.isFirstTimeStart ? "开聊" : "继续对话")
                        .font(.system(size: 17, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundColor(.white)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "A78DC7"),
                            Color(hex: "9680B7")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                )
                .shadow(color: Color(hex: "A78DC7").opacity(0.4), radius: 6, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
                .contentShape(Rectangle())
            }
            .disabled(chatManager.isGeneratingResponse)
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 20)
                .padding(.bottom, 12) // 略微上移，避免过于贴底
        }
    }
    
    // 用户引导输入视图
    private var userGuidanceInputView: some View {
        MultiChatInputBar(
            messageText: $userGuidanceText,
            isSending: $isSending,
            characterThemeColor: characterThemeColor,
            userRole: userRole,
            selectedCharacters: selectedCharacters,
            onSend: {
                sendUserGuidance()
                withAnimation(.spring()) {
                    showUserGuidanceInput = false
                }
            }
        )
        .background(DesignSystem.Colors.background)
        .edgesIgnoringSafeArea(.bottom) // 忽略底部安全区域，确保输入框贴合屏幕底部
        .onAppear {
            // 输入框出现时立即滚动到合适位置，为键盘弹出做准备
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ScrollToBottom"),
                        object: nil,
                        userInfo: ["anchor": "center"]
                    )
                }
            }
        }
    }
    
    // 参与者模式的输入栏
    private var participantInputBar: some View {
        Group {
            if isShareMode {
                ShareModeBottomBar(
                    selectedCount: selectedMessages.count,
                    onCancel: {
                        exitShareMode()
                    },
                    onShare: {
                        generateAndShareCards()
                    }
                )
            } else {
                MultiChatInputBar(
                    messageText: $inputText,
                    isSending: $isSending,
                    characterThemeColor: characterThemeColor,
                    userRole: userRole,
                    selectedCharacters: selectedCharacters,
                    onSend: {
                        sendMessage()
                    }
                )
            }
        }
        .background(DesignSystem.Colors.background)
        .edgesIgnoringSafeArea(.bottom) // 忽略底部安全区域，确保输入框贴合屏幕底部
    }
    
    // 引导按钮 - 修改为更符合iOS设计风格
    private func guidanceButton() -> some View {
        Button(action: {
            if showUserGuidanceInput {
                // 🎯 点击叉号：完美无弹跳关闭
                
                // 1. 立即接管所有控制权，冻结所有状态
                isManuallyControllingKeyboard = true
                
                // 2. 瞬间固定所有高度值（防止弹跳）
                keyboardHeight = 0
                keyboardVisible = false
                viewOffset = 0
                
                // 3. 强制立即收起键盘
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                
                // 4. 在状态稳定后，清空文字+关闭界面（一次性完成）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                    // 一次性清空文字并关闭界面，避免两次布局变化
                    userGuidanceText = ""
                    inputText = ""
                    
                    withAnimation(.easeOut(duration: 0.06)) {
                        showUserGuidanceInput = false
                    }
                }
                
                // 5. 延迟恢复系统控制
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    isManuallyControllingKeyboard = false
                }
            } else {
                // 显示输入框并立即滚动到合适位置 - 使用更快的动画
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showUserGuidanceInput = true
                }
                
                // 立即预测性滚动，为键盘弹出做准备 - 减少延迟
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ScrollToBottom"),
                            object: nil,
                            userInfo: ["anchor": "center"]
                        )
                    }
                }
            }
        }) {
            Image(systemName: showUserGuidanceInput ? "xmark" : "text.bubble")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "A78DC7"),
                            Color(hex: "9680B7")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: Color(hex: "A78DC7").opacity(0.4), radius: 6, x: 0, y: 3)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // 按钮缩放动画样式
    private struct ScaleButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }
    
    // 用户消息视图（支持长按复制）
    private func userMessageView(message: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 8) { // 减小间距从10到8
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("你")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "A78DC7")) // 使用更淡的紫色
                    .padding(.trailing, 4)
                
                Text(message.content.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.system(size: 15))
                    .lineSpacing(4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .foregroundColor(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(hex: "A78DC7")) // 使用更淡的紫色
                    )
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ShowToast"),
                                object: nil,
                                userInfo: ["message": "已复制消息内容"]
                            )
                        } label: {
                            Label("复制消息内容", systemImage: "doc.on.doc")
                        }
                    }
            }
            
            Image(systemName: "person.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(Color(hex: "A78DC7")) // 使用更淡的紫色
                .padding(.top, 2)
        }
        .padding(.horizontal, 8) // 减小水平内边距从16到8
        .padding(.vertical, 4) // 减小垂直内边距从6到4
    }
    
    // 获取用户角色对应的角色名称（观察者模式下返回nil）
    private func getUserCharacterName() -> String? {
        return nil
    }
    
    // 判断用户是否在扮演某个角色（观察者模式下总是false）
    private func isUserPlayingCharacter(_ characterId: String) -> Bool {
        return false
    }
    
    // 发送消息方法
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            
        // 保存消息内容并清空输入框
        let messageContent = inputText
            inputText = ""
            
        // 重置输入框状态
        textViewHeight = 36 // 重置输入框高度
        
        // 使用动画平滑过渡
        withAnimation(.easeInOut(duration: 0.2)) {
            // 先发送消息，确保消息立即显示
            chatManager.sendUserMessage(content: messageContent)
            
            // 触觉反馈
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        
        // 延迟收起键盘，确保消息已经显示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 再收起键盘
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
    
    // 获取用户角色对应的角色ID（观察者模式下返回nil）
    private func getUserCharacterId() -> String? {
        return nil
    }
    
    // 发送用户引导
    private func sendUserGuidance() {
        let trimmedText = userGuidanceText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            withAnimation {
                isSending = true
            }
            
            // 发送用户引导逻辑
            chatManager.sendUserGuidance(content: trimmedText)
            
            // 清空输入框
            userGuidanceText = ""
            
            // 发送后隐藏键盘并确保焦点状态重置
            hideKeyboard()
            
            // 延迟关闭发送状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    self.isSending = false
                }
            }
        }
    }
    
    // 继续对话
    private func continueConversation() {
        chatManager.continueConversation()
    }
    
    // 分享对话
    private func shareConversation() {
        enterShareMode()
    }
    
    // MARK: - 分享功能
    
    // 分享相关状态
    @State private var isShareMode = false
    @State private var selectedMessages: Set<String> = []
    @State private var showShareModal = false
    @State private var previewCards: [UIImage] = []  // 预览版（无白边）
    @State private var saveCards: [UIImage] = []     // 保存版（带白边）
    
    /// 进入分享模式
    private func enterShareMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isShareMode = true
        }
        // 隐藏键盘
        hideKeyboard()
    }
    
    /// 退出分享模式
    private func exitShareMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isShareMode = false
            selectedMessages.removeAll()
        }
    }
    
    /// 切换消息选择状态
    private func toggleMessageSelection(_ messageId: String) {
        withAnimation(.spring(response: 0.3)) {
            if selectedMessages.contains(messageId) {
                selectedMessages.remove(messageId)
            } else {
                selectedMessages.insert(messageId)
            }
        }
    }
    
    /// 生成并分享卡片
    private func generateAndShareCards() {
        let selectedMessagesList = chatManager.messages.filter { selectedMessages.contains($0.id.uuidString) }
        
        if selectedMessagesList.isEmpty {
            return
        }
        
        // 生成分享卡片（预览版 + 保存版）
        let cardResults: [ShareCardResult]
        
        if selectedMessagesList.count > 1 {
            // 多条消息：生成合并卡片
            let mergedCard = MultiChatShareCardGenerator.generateMergedCard(
                messages: selectedMessagesList,
                characters: selectedCharacters,
                theme: chatTheme
            )
            cardResults = [mergedCard]
        } else {
            // 单条消息：生成单独卡片
            cardResults = selectedMessagesList.compactMap { message -> ShareCardResult? in
                if let character = selectedCharacters.first(where: { $0.id == message.characterId }) {
                    let card = MultiChatShareCardGenerator.generateCard(
                        message: message,
                        character: character,
                        theme: chatTheme
                    )
                    return card
                } else {
                    return nil
                }
            }
        }
        
        if cardResults.isEmpty {
            return
        }
        
        // 分离预览版和保存版
        self.previewCards = cardResults.map { $0.previewImage }
        self.saveCards = cardResults.map { $0.saveImage }
        
        // 先退出分享模式，然后显示分享模态视图
        exitShareMode()
        
        // 延迟一点时间再展示分享界面，确保UI状态稳定
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showShareModal = true
        }
    }
    
    // 激活键盘
    private func activateKeyboard() {
        MultiChatKeyboardHelper.forceShowKeyboard()
    }
    
    // 隐藏键盘
    private func hideKeyboard() {
        MultiChatKeyboardHelper.forceHideKeyboard()
    }
    
    // 添加手动控制标志，防止状态冲突
    @State private var isManuallyControllingKeyboard = false
    
    // 添加键盘通知处理方法
    private func handleKeyboardNotification(_ notification: Notification, isShowing: Bool) {
        // 如果正在手动控制键盘，忽略系统通知避免状态冲突
        if isManuallyControllingKeyboard {
            return
        }
        
        if isShowing {
            // 键盘显示
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                // 获取动画持续时间
                let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
                
                // 获取动画曲线
                let animationCurve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 7
                let animationOptions = UIView.AnimationOptions(rawValue: animationCurve << 16)
                
                // 使用系统提供的动画参数
                    UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, animationOptions]) {
                        DispatchQueue.main.async {
                    self.keyboardHeight = keyboardFrame.height
                    self.keyboardVisible = true
                    self.viewOffset = -keyboardFrame.height / 12
                        }
                    }
                    
                    // 创建与键盘完全相同的动画参数
                    let animator = UIViewPropertyAnimator(
                        duration: duration,
                        curve: UIView.AnimationCurve(rawValue: Int(animationCurve)) ?? .easeInOut
                    )
                    
                    // 添加滚动动画，与键盘弹出完全同步
                    animator.addAnimations {
                    // 发送通知以滚动到底部，使用center锚点
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ScrollToBottom"),
                        object: nil,
                        userInfo: ["anchor": "center"]
                    )
                }
                
                // 启动动画
                animator.startAnimation()
                
                // 键盘弹出后再次确认滚动位置
                DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.05) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ScrollToBottom"),
                            object: nil,
                            userInfo: ["anchor": "center"]
                        )
                    }
                }
            }
        } else {
            // 键盘隐藏 - 优化为更快的响应
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
            let animationCurve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 7
            let animationOptions = UIView.AnimationOptions(rawValue: animationCurve << 16)
            
            // 使用更短的动画时间，确保与UI动画同步
            let optimizedDuration = min(duration * 0.8, 0.2) // 最多0.2秒
            
            UIView.animate(withDuration: optimizedDuration, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction, animationOptions]) {
                        DispatchQueue.main.async {
                        self.keyboardHeight = 0
                        self.keyboardVisible = false
                        self.viewOffset = 0
                    }
                }
    }
    }
    

    
    // 新增：欢迎界面
    private var welcomeSection: some View {
        VStack(spacing: 32) {
            // 精致标题 - 平衡版本
            HStack(spacing: 0) {
                Text("—— ")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.secondary.opacity(0.4))
                
                HStack(spacing: 3) {
                    Text("梦")
                    Text("幻")
                    Text("联")
                    Text("动")
                    Text("时")
                    Text("刻")
                }
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary.opacity(0.5))
                
                Text(" ——")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.secondary.opacity(0.4))
            }
            

        }
        .padding(.horizontal, 16)
    }
    

}

// 注意：cornerRadius 和 RoundedCorner 已在其他文件中定义，这里不需要重复定义

// 加载动画的三个点组件
struct LoadingDotsView: View {
    @State private var animationState = 0
    @State private var timer: Timer?
    
    var body: some View {
                HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animationState == index ? 1.2 : 0.8)
                    .opacity(animationState == index ? 1.0 : 0.5)
                    .animation(.easeInOut(duration: 0.3), value: animationState)
                }
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
                }
        }
    
    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            animationState = (animationState + 1) % 3
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
}

/// 对话结束指示器
struct ConversationEndIndicator: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            Spacer()
            
            Text("————————")
                .font(.system(size: 14, weight: .ultraLight))
                .foregroundColor(.secondary.opacity(0.7))
                .offset(y: animationOffset)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        animationOffset = 0
                    }
                    
                    // 轻微的脉冲动画
                    withAnimation(.easeInOut(duration: 1.2).repeatCount(1, autoreverses: true)) {
                        animationOffset = -2
                    }
                }
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

struct MultiPersonChatView_Previews: PreviewProvider {
    static var previews: some View {
            MultiPersonChatView(
                selectedCharacters: [
                CharacterModel.sampleCharacters[0],
                CharacterModel.sampleCharacters[1],
                CharacterModel.sampleCharacters[2]
                ],
                chatMode: .themedDiscussion,
            chatTheme: "探讨人性的本质",
                userRole: .observer,
                historicalSessionId: nil
            )
    }
} 