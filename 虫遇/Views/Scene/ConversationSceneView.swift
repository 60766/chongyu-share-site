import SwiftUI
import UIKit
import Combine
import Foundation

// 导入所有必需的模型
import SwiftData

/**
 * 对话场景视图
 * 用于展示与历史人物的对话界面
 * 支持虚拟角色回复和用户输入
 */
struct ConversationSceneView: View {
    // 使用适配后的模型和状态
    @State private var conversation: ConversationViewModel?
    @State private var replyText: String = ""
    @State private var isShowingMenu: Bool = false
    @State private var isViewingSettings: Bool = false
    @State private var isKeyboardVisible: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var isShowingCharacterInfo: Bool = false
    
    // 滚动相关状态
    @State private var scrollViewHeight: CGFloat = 0
    @State private var scrollToBottom: Bool = false
    
    // 传入的会话ID（如果是从列表进入）
    var conversationId: String?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 对话内容区域
            ScrollViewReader { scrollView in
                ScrollView {
                    VStack(spacing: 0) {
                        // 加载更多按钮
                        loadMoreButton
                        
                        // 日期标签
                        dateLabel(for: conversation?.createdAt ?? Date())
                        
                        // 消息区域
                        LazyVStack(spacing: 12) {
                            ForEach(conversation?.messages.indices.map { $0 } ?? [], id: \.self) { index in
                                if let message = conversation?.messages[index],
                                   let messages = conversation?.messages {
                                let isFirstInGroup = isFirstMessageInGroup(at: index, in: messages)
                                let isLastInGroup = isLastMessageInGroup(at: index, in: messages)
                                
                                MessageBubbleView(
                                    message: message,
                                    isFirstInGroup: isFirstInGroup,
                                    isLastInGroup: isLastInGroup,
                                    onLongPress: {
                                        // 长按操作
                                    }
                                )
                                .id(index)
                                .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.bottom, 8)
                    }
                    .padding(.bottom, keyboardHeight > 0 ? 60 : 0) // 底部固定空间而非随键盘变化
                }
                .onChange(of: scrollToBottom) { oldValue, newValue in
                    if newValue {
                        scrollToLastMessage(scrollView)
                    }
                }
            }
            
            // 底部回复栏 - 始终位于屏幕底部
            VStack(spacing: 0) {
                // 分隔线
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 0.5)
                
                // 回复输入区
                HStack(alignment: .center, spacing: 12) {
                    // 输入框
                    ZStack(alignment: .leading) {
                        if replyText.isEmpty {
                            Text("发送消息...")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                                .padding(.leading, 8)
                                .padding(.top, 1)
                        }
                        
                        TextField("", text: $replyText, onCommit: {
                            sendMessage()
                        })
                        .font(.system(size: 15))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6).opacity(0.5))
                        .cornerRadius(20)
                    }
                    
                    // 发送按钮
                    Button(action: {
                        sendMessage()
                        hideKeyboard()
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(replyText.isEmpty ? .gray : .blue)
                    }
                    .disabled(replyText.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .animation(.easeInOut(duration: 0.2), value: isKeyboardVisible)
            }
        }
        .keyboardAdaptive(enabled: true, adjustLayout: false) // 使用KeyboardAdaptive但不自动调整布局
        .onReceive(Publishers.keyboardHeight) { height in
            isKeyboardVisible = height > 0
            keyboardHeight = height
        }
        .onAppear {
            // 加载或初始化对话
            loadConversation()
            
            // 准备一些初始消息（如果需要）
            if let convo = conversation, convo.messages.isEmpty {
                prepareInitialMessages()
            }
            
            // 隐藏TabBar
            TabBarManager.shared.pushHideState()
            
            // 用来确保消息显示在最底部
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                scrollToBottom = true
            }
        }
        .onDisappear {
            // 恢复TabBar
            TabBarManager.shared.popHideState()
        }
    }
    
    // MARK: - 消息分组逻辑
    
    // 判断消息是否是组中的第一条
    private func isFirstMessageInGroup(at index: Int, in messages: [MessageViewModel]) -> Bool {
        guard index > 0 else { return true }
        
        let currentMessage = messages[index]
        let previousMessage = messages[index - 1]
        
        // 不同发送者或时间间隔大于5分钟视为新组
        return currentMessage.isFromUser != previousMessage.isFromUser ||
               !isWithinTimeThreshold(currentMessage.timestamp, previousMessage.timestamp)
    }
    
    // 判断消息是否是组中的最后一条
    private func isLastMessageInGroup(at index: Int, in messages: [MessageViewModel]) -> Bool {
        guard index < messages.count - 1 else { return true }
        
        let currentMessage = messages[index]
        let nextMessage = messages[index + 1]
        
        // 不同发送者或时间间隔大于5分钟视为新组
        return currentMessage.isFromUser != nextMessage.isFromUser ||
               !isWithinTimeThreshold(currentMessage.timestamp, nextMessage.timestamp)
    }
    
    // 判断是否在时间阈值内（5分钟）
    private func isWithinTimeThreshold(_ date1: Date, _ date2: Date) -> Bool {
        return abs(date1.timeIntervalSince(date2)) < 300 // 5分钟
    }
    
    // MARK: - 数据加载
    
    // 加载会话数据
    private func loadConversation() {
        if let conversationId = conversationId {
            // 实际应用中应该根据ID从数据源加载
            if let foundConversation = ConversationViewModel.sampleConversations.first(where: { $0.id == conversationId }) {
                self.conversation = foundConversation
            }
        } else {
            // 示例会话
            self.conversation = ConversationViewModel.sampleConversations.first
        }
    }
    
    // 发送新消息
    private func sendMessage() {
        guard !replyText.isEmpty, var conversation = conversation else { return }
        
        let userMessage = MessageViewModel(
            id: UUID().uuidString,
            content: replyText,
            isFromUser: true,
            timestamp: Date()
        )
        
        // 添加用户消息
        conversation.messages.append(userMessage)
        self.conversation = conversation
        
        // 清空输入框
        replyText = ""
        
        // 模拟角色回复
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            var updatedConversation = self.conversation
            
            let characterMessage = MessageViewModel(
                id: UUID().uuidString,
                content: generateCharacterReply(to: userMessage.content, by: conversation.character),
                isFromUser: false,
                timestamp: Date()
            )
            
            updatedConversation?.messages.append(characterMessage)
            updatedConversation?.lastMessageAt = characterMessage.timestamp
            
            self.conversation = updatedConversation
        }
    }
    
    // 生成角色回复（简单示例）
    private func generateCharacterReply(to message: String, by character: CharacterViewModel) -> String {
        // 实际应用中应该使用更复杂的逻辑或AI来生成回复
        let genericResponses = [
            "这是个很有趣的问题。",
            "让我思考一下这个问题。",
            "从历史的角度来看，",
            "这让我想起了一个故事。",
            "根据我的经验，"
        ]
        
        let characterSpecificResponses: [String]
        
        switch character.name {
        case "爱因斯坦":
            characterSpecificResponses = [
                "从相对论的角度来看，",
                "科学的本质是好奇心，",
                "想象力比知识更重要，因为",
                "真理是相对的，"
            ]
        case "莎士比亚":
            characterSpecificResponses = [
                "如同我在作品中描述的，",
                "生活的舞台上，",
                "人性的复杂性体现在",
                "爱与恨的交织中，"
            ]
        case "孔子":
            characterSpecificResponses = [
                "学而时习之，",
                "仁者爱人，",
                "君子和而不同，",
                "吾日三省吾身，"
            ]
        default:
            characterSpecificResponses = genericResponses
        }
        
        let allResponses = genericResponses + characterSpecificResponses
        let randomResponse = allResponses.randomElement() ?? "这是个很好的问题。"
        
        return randomResponse + " " + message.replacingOccurrences(of: "?", with: "。").replacingOccurrences(of: "？", with: "。")
    }
    
    // MARK: - 键盘处理
    
    // 隐藏键盘
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - 视图模型

/**
 * 消息视图模型 - 用于适配Message模型
 */
struct MessageViewModel: Identifiable {
    var id: String
    var content: String
    var isFromUser: Bool
    var timestamp: Date
    var isRead: Bool = true
}

/**
 * 角色视图模型 - 用于适配CharacterModel模型
 */
struct CharacterViewModel: Identifiable {
    var id: String
    var name: String
    var profession: String
    var era: String
    var avatar: String
    var bio: [String]
    var category: String
    
    // 示例角色
    static let sampleCharacters: [CharacterViewModel] = [
        CharacterViewModel(
            id: "einstein",
            name: "爱因斯坦",
            profession: "物理学家",
            era: "现代",
            avatar: "einstein",
            bio: ["相对论创立者", "诺贝尔物理学奖获得者"],
            category: "科学家"
        ),
        CharacterViewModel(
            id: "shakespeare",
            name: "莎士比亚",
            profession: "剧作家",
            era: "文艺复兴",
            avatar: "shakespeare",
            bio: ["《哈姆雷特》作者", "英国文学巨匠"],
            category: "艺术家"
        ),
        CharacterViewModel(
            id: "confucius",
            name: "孔子",
            profession: "思想家",
            era: "古代",
            avatar: "confucius",
            bio: ["儒家学派创始人", "《论语》作者"],
            category: "哲学家"
        )
    ]
}

/**
 * 对话视图模型 - 用于适配Conversation模型
 */
struct ConversationViewModel: Identifiable {
    var id: String
    var title: String
    var character: CharacterViewModel
    var messages: [MessageViewModel]
    var createdAt: Date
    var lastMessageAt: Date
    
    // 示例对话
    static var sampleConversations: [ConversationViewModel] = [
        ConversationViewModel(
            id: "conv1",
            title: "与爱因斯坦的对话",
            character: CharacterViewModel.sampleCharacters[0],
            messages: [
                MessageViewModel(
                    id: "msg1",
                    content: "你好，我是爱因斯坦。今天我们可以讨论什么？",
                    isFromUser: false,
                    timestamp: Date().addingTimeInterval(-3600)
                ),
                MessageViewModel(
                    id: "msg2",
                    content: "我对相对论很感兴趣，您能简单解释一下吗？",
                    isFromUser: true,
                    timestamp: Date().addingTimeInterval(-3500)
                ),
                MessageViewModel(
                    id: "msg3",
                    content: "相对论的核心思想是空间和时间不是绝对的，而是相对的。简单来说，运动会影响时间流逝的速度，接近光速时，时间会变慢。这就是著名的时间膨胀效应。",
                    isFromUser: false,
                    timestamp: Date().addingTimeInterval(-3400)
                )
            ],
            createdAt: Date().addingTimeInterval(-86400),
            lastMessageAt: Date().addingTimeInterval(-3400)
        )
    ]
}

/**
 * 消息气泡视图
 * 用于显示单条消息
 */
struct MessageBubbleView: View {
    var message: MessageViewModel
    var isFirstInGroup: Bool
    var isLastInGroup: Bool
    var onLongPress: () -> Void
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !message.isFromUser {
                if isFirstInGroup {
                    // 角色头像 - 使用一个通用的占位头像
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("H") // 历史人物的首字母
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.blue)
                        )
                } else {
                    // 占位空间保持对齐
                    Spacer()
                        .frame(width: 32)
                }
                
                // 消息气泡
                Text(message.content)
                    .font(.system(size: 15))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(16, corners: bubbleCorners(isUser: false, isFirst: isFirstInGroup, isLast: isLastInGroup))
                    .onLongPressGesture {
                        onLongPress()
                    }
                
                Spacer()
            } else {
                // 用户消息向右对齐
                Spacer()
                
                // 消息气泡
                Text(message.content)
                    .font(.system(size: 15))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(16, corners: bubbleCorners(isUser: true, isFirst: isFirstInGroup, isLast: isLastInGroup))
                    .onLongPressGesture {
                        onLongPress()
                    }
            }
        }
    }
    
    // 根据消息位置确定圆角
    private func bubbleCorners(isUser: Bool, isFirst: Bool, isLast: Bool) -> UIRectCorner {
        if isUser {
            if isFirst && isLast {
                return [.allCorners]
            } else if isFirst {
                return [.topLeft, .topRight, .bottomLeft]
            } else if isLast {
                return [.topRight, .bottomLeft, .bottomRight]
            } else {
                return [.topRight, .bottomLeft]
            }
        } else {
            if isFirst && isLast {
                return [.allCorners]
            } else if isFirst {
                return [.topLeft, .topRight, .bottomRight]
            } else if isLast {
                return [.topLeft, .bottomLeft, .bottomRight]
            } else {
                return [.topLeft, .bottomRight]
            }
        }
    }
}

/**
 * 角色对话设置视图
 */
struct ConversationSettingsView: View {
    @Binding var isViewingSettings: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // 顶部标题栏
            HStack {
                Text("对话设置")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isViewingSettings = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // 设置项列表
            ScrollView {
                VStack(spacing: 16) {
                    // 通知设置
                    SettingItemView(
                        icon: "bell.fill",
                        title: "通知",
                        description: "管理对话提醒和通知设置",
                        color: .blue
                    )
                    
                    // 隐私设置
                    SettingItemView(
                        icon: "lock.fill",
                        title: "隐私",
                        description: "管理谁可以查看和参与对话",
                        color: .green
                    )
                    
                    // 导出对话
                    SettingItemView(
                        icon: "square.and.arrow.up",
                        title: "导出对话",
                        description: "保存对话内容到手机或云端",
                        color: .orange
                    )
                    
                    // 删除对话
                    SettingItemView(
                        icon: "trash.fill",
                        title: "删除对话",
                        description: "永久删除此对话及其内容",
                        color: .red
                    )
                }
                .padding(.horizontal, 16)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.bottom, 32)
        .background(Color(.systemBackground))
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.2), radius: 10, y: -5)
    }
}

/**
 * 设置项视图
 */
struct SettingItemView: View {
    var icon: String
    var title: String
    var description: String
    var color: Color
    
    var body: some View {
        Button(action: {
            // 设置项操作
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(color)
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/**
 * 角色信息视图
 */
struct CharacterInfoView: View {
    var character: CharacterViewModel
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部拖动条
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 16)
            
            // 角色头像与名称
            VStack(spacing: 16) {
                // 头像
                Circle()
                    .fill(colorForCategory(character.category).opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(String(character.name.prefix(1)))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(colorForCategory(character.category))
                    )
                
                // 名称和职业
                VStack(spacing: 8) {
                    Text(character.name)
                        .font(.system(size: 24, weight: .bold))
                    
                    Text(character.profession)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 24)
            
            // 角色信息卡片
            VStack(alignment: .leading, spacing: 16) {
                // 时代
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(colorForCategory(character.category))
                        .frame(width: 24)
                    
                    Text("时代: " + character.era)
                        .font(.system(size: 16))
                }
                
                // 简介
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "text.quote")
                        .font(.system(size: 18))
                        .foregroundColor(colorForCategory(character.category))
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("简介")
                            .font(.system(size: 16, weight: .semibold))
                        
                        ForEach(character.bio, id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(colorForCategory(character.category))
                                
                                Text(point)
                                    .font(.system(size: 15))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(Color(.systemGray6).opacity(0.7))
            .cornerRadius(16)
            .padding(.horizontal, 16)
            
            // 动作按钮
            HStack(spacing: 16) {
                // 新对话按钮
                Button(action: {
                    // 开始新对话
                }) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                        Text("新对话")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(colorForCategory(character.category))
                    .cornerRadius(16)
                }
                
                // 关闭按钮
                Button(action: {
                    withAnimation {
                        isShowing = false
                    }
                }) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("关闭")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .padding(.bottom, 32)
        .background(Color(.systemBackground))
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.2), radius: 10, y: -5)
    }
}

// 扩展UIRectCorner以支持自定义圆角
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// 圆角形状
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// 扩展ConversationSceneView添加UI组件
extension ConversationSceneView {
    // 背景视图
    var backgroundView: some View {
        Color(.systemBackground)
            .edgesIgnoringSafeArea(.all)
    }
    
    // 导航栏
    var navigationBar: some View {
        HStack {
            Button(action: {
                // 返回操作
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(8)
                    .background(Color(.systemBackground).opacity(0.8))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            if let conversation = conversation {
                HStack(spacing: 8) {
                    // 角色头像
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(String(conversation.character.name.prefix(1)))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.blue)
                        )
                    
                    // 角色名称
                    VStack(alignment: .leading, spacing: 2) {
                        Text(conversation.character.name)
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(conversation.character.profession)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("加载中...")
                    .font(.headline)
            }
            
            Spacer()
            
            // 菜单按钮
            Button(action: {
                withAnimation {
                    isShowingMenu.toggle()
                }
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(8)
                    .background(Color(.systemBackground).opacity(0.8))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground).opacity(0.95))
    }
    
    // 加载视图
    func loadingView(width: CGFloat) -> some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("加载对话中...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(width: width, height: 300)
    }
    
    // 空视图
    var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("没有找到对话")
                .font(.headline)
            
            Text("这个对话可能已被删除或不存在")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // 加载更多按钮
    var loadMoreButton: some View {
        Button(action: {
            // 加载更多历史消息
        }) {
            Text("加载更多历史消息")
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(16)
        }
        .padding(.vertical, 12)
    }
    
    // 日期标签
    func dateLabel(for date: Date) -> some View {
        Text(formatDate(date))
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            .padding(.vertical, 8)
    }
    
    // 日期格式化
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // 用来确保消息显示在最底部
    private func scrollToLastMessage(_ scrollView: ScrollViewProxy) {
        if let lastIndex = conversation?.messages.indices.last {
            scrollView.scrollTo(lastIndex, anchor: .bottom)
        }
    }
    
    // 准备一些初始消息（如果需要）
    private func prepareInitialMessages() {
        // 实现准备初始消息的逻辑
    }
}

/**
 * 帮助函数 - 用于根据角色类别获取颜色
 */
func colorForCategory(_ category: String) -> Color {
    switch category {
    case "科学家": return .blue
    case "艺术家": return .purple
    case "哲学家": return .orange
    case "领袖": return .red
    case "作家": return .green
    default: return .gray
    }
} 