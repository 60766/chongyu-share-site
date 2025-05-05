import SwiftUI
import SwiftData

// 引入CYChatCharacter
import Foundation

/**
 * 聊天角色模型
 * 用于ChatView中表示对话角色
 */
struct ChatCharacter: Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var introduction: String
    var field: String
    var birthYear: String
    var deathYear: String
    var avatarUrl: String
    var eraTag: String
    var achievements: [String]
    var mainWorks: [String]
    var keyThoughts: [String]
}

/**
 * 聊天视图
 * 用于用户与历史人物进行对话
 */
struct ChatView: View {
    /// 聊天角色
    var character: CYChatCharacter
    /// 对话ID
    var conversationId: String
    /// 用户消息输入
    @State private var messageText = ""
    /// 是否正在发送消息
    @State private var isSending = false
    /// 模拟消息数据
    @State private var messages: [Message] = []
    /// 是否显示分享菜单
    @State private var showingShareSheet = false
    /// 是否显示录音界面
    @State private var isRecording = false
    
    // TabBar管理器
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    // 获取角色主题色
    private var characterThemeColor: Color {
        switch character.name {
        case "阿尔伯特·爱因斯坦": 
            return Color(hex: "6A8CAF") // 科学蓝色调
        case "莎士比亚": 
            return Color(hex: "9B7FA6") // 文学紫色调
        case "达芬奇": 
            return Color(hex: "A08F6F") // 文艺复兴棕色调
        case "孔子": 
            return Color(hex: "7D9672") // 古典绿色调
        case "李白": 
            return Color(hex: "A08F6F") // 唐朝风格棕色调
        default: 
            return Color(hex: "9A8BB0") // 默认历史感紫色
        }
    }
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // 主内容区域
            VStack(spacing: 0) {
                // 顶部导航安全区
                Color.clear
                    .frame(height: 1)
                    .background(Color.clear)
                
                // 消息列表
                GeometryReader { geometry in
                    ScrollViewReader { scrollView in
                        ScrollView {
                            // 顶部安全区域和会话信息
                            VStack(spacing: 0) {
                                // 顶部安全间距 - 增大空间提高视觉平衡
                                Spacer()
                                    .frame(height: 40)
                                
                                // 底部渐变覆盖，增强顶部视觉层次感
                                ZStack {
                                    // 顶部下方渐变，防止内容被导航栏遮挡
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(.systemBackground).opacity(0.95),
                                            Color(.systemBackground).opacity(0)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .frame(height: 30)
                                    .offset(y: -30)
                                }
                                
                                // 会话信息卡片 - 更精致的设计
                                if !messages.isEmpty {
                                    ZStack {
                                        // 装饰线
                                        HStack(spacing: 0) {
                                            Rectangle()
                                                .fill(LinearGradient(
                                                    gradient: Gradient(colors: [Color.clear, characterThemeColor.opacity(0.2), Color.clear]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing))
                                                .frame(height: 1)
                                        }
                                        .padding(.horizontal, 65)
                                        
                                        // 会话开始文本
                                        Text("穿越时空的对话")
                                            .font(.system(size: 12, weight: .light))
                                            .kerning(1)
                                            .foregroundColor(characterThemeColor.opacity(0.7))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 3)
                                            .background(Color(.systemBackground))
                                    }
                                    .padding(.top, 10)
                                    .padding(.bottom, 16)
                                }
                            }
                            
                            // 消息列表区域
                            LazyVStack(spacing: 16) {
                                // 消息气泡
                                ForEach(messages, id: \.id) { message in
                                    ChatMessageBubbleView(message: message, characterThemeColor: characterThemeColor)
                                        .id(message.id)
                                }
                                
                                // 底部占位区域 - 增加高度确保内容能滚动到底部安全区以上
                                Color.clear
                                    .frame(height: 60)
                                    .id("bottomId")
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 30)
                        }
                        .onChangeCompat(of: messages) { oldValue, newValue in
                            if oldValue.count != newValue.count {
                                withAnimation {
                                    scrollView.scrollTo("bottomId", anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                // 底部输入区域
                VStack(spacing: 0) {
                    Divider()
                        .opacity(0.8)
                        .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: -1)
                    
                    HStack(spacing: 14) {
                        // 语音按钮
                        Button(action: {
                            isRecording.toggle()
                            // 触感反馈
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(isRecording ? Color.red.opacity(0.1) : Color(.systemGray6).opacity(0.5))
                                    .frame(width: 38, height: 38)
                                    .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                                
                                Image(systemName: isRecording ? "mic.fill" : "mic")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isRecording ? .red : characterThemeColor.opacity(0.8))
                            }
                            .frame(width: 42, height: 42) // 增加点击区域
                            .contentShape(Circle())
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        // 文本输入框
                        HStack {
                            TextField("写下你想说的...", text: $messageText)
                                .font(.system(size: 15))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color(.systemGray6).opacity(0.5))
                                        .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
                                )
                                .disabled(isRecording)
                                .opacity(isRecording ? 0.5 : 1)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // 发送按钮
                        Button(action: {
                            sendMessage()
                            // 触感反馈
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(messageText.isEmpty ? Color(.systemGray5) : characterThemeColor)
                                    .frame(width: 38, height: 38)
                                    .shadow(color: messageText.isEmpty ? Color.black.opacity(0.05) : characterThemeColor.opacity(0.3), radius: 2, x: 0, y: 1)
                                
                                Image(systemName: messageText.isEmpty ? "plus" : "arrow.up")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(messageText.isEmpty ? Color.gray : Color.white)
                            }
                            .frame(width: 42, height: 42) // 增加点击区域
                            .contentShape(Circle())
                        }
                        .buttonStyle(ScaleButtonStyle()) // 添加按压效果
                        .disabled(messageText.isEmpty && !isRecording)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Color(.systemBackground)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: -2)
                    )
                    
                    // 底部安全区域
                    Color.clear
                        .frame(height: 8)
                }
            }
            
            // 录音界面
            if isRecording {
                VStack(spacing: 16) {
                    // 时空穿越波形元素 - 更加简洁且有穿越感
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { index in
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            characterThemeColor.opacity(0.6),
                                            characterThemeColor.opacity(0.9)
                                        ]),
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(width: 3, height: CGFloat(6 + Int.random(in: 5...24)))
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.1),
                                    value: isRecording
                                )
                        }
                    }
                    .frame(height: 32)
                    .overlay(
                        Image(systemName: "waveform")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(characterThemeColor.opacity(0.15))
                            .offset(x: -1)
                    )
                    
                    Text("正在聆听...")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(characterThemeColor.opacity(0.7))
                        .kerning(0.5)
                    
                    // 取消按钮 - 更简洁
                    Button(action: {
                        isRecording = false
                        // 触感反馈
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }) {
                        Text("取消")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 100, height: 36)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                characterThemeColor.opacity(0.85),
                                                characterThemeColor.opacity(0.95)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: characterThemeColor.opacity(0.25), radius: 3, x: 0, y: 2)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle(scaleAmount: 0.95))
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .frame(width: 220) // 减小宽度，更加紧凑
                .background(
                    ZStack {
                        // 底层背景
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        // 时空穿越装饰元素 - 调整为更和谐的样式
                        Circle()
                            .stroke(characterThemeColor.opacity(0.05), lineWidth: 1.2)
                            .frame(width: 150, height: 150)
                            .offset(x: -120, y: -80)
                            .opacity(0.8)
                        
                        Circle()
                            .stroke(characterThemeColor.opacity(0.04), lineWidth: 1)
                            .frame(width: 90, height: 90)
                            .offset(x: 100, y: 70)
                            .opacity(0.6)
                        
                        // 微妙边框 - 调整渐变使其更和谐
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        characterThemeColor.opacity(0.12),
                                        characterThemeColor.opacity(0.08),
                                        characterThemeColor.opacity(0.02)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 120)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
                .zIndex(2)
                .offset(y: UIScreen.main.bounds.height * 0.1)
            }
            
            // 顶部安全遮罩 - 确保内容不会与导航栏重叠
            VStack {
                Rectangle()
                    .fill(Color(.systemBackground))
                    .frame(height: 44)
                    .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
                    .opacity(0.98)
                Spacer()
            }
            .edgesIgnoringSafeArea(.top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(character.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
            }
        }
        // 自定义导航栏返回按钮样式
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // 手动返回
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("返回")
                            .font(.system(size: 17, weight: .regular))
                    }
                    .foregroundColor(characterThemeColor)
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $showingShareSheet) {
            Text("分享与 \(character.name) 的对话")
        }
        .onAppear {
            DispatchQueue.main.async {
                // 检查当前TabBar状态栈
                if tabBarManager.hideStateStack.isEmpty {
                    // 如果状态栈为空，这是首次进入聊天页面
                    // 推入一个新的隐藏状态
                    tabBarManager.pushHideState()
                    print("ChatView首次出现：TabBar已隐藏")
                } else {
                    // 如果状态栈不为空，表示可能是从角色详情页返回
                    // 确保TabBar仍然是隐藏的，但不重置堆栈
                    if !tabBarManager.isFullyHidden {
                        tabBarManager.completelyHide()
                        print("ChatView从其他页面返回：确保TabBar仍然隐藏")
                    } else {
                        print("ChatView从其他页面返回：TabBar已经正确隐藏")
                    }
                }
                
                // 加载消息数据
                loadMessages()
            }
        }
        .onDisappear {
            DispatchQueue.main.async {
                // 我们需要检查当前导航路径以确定是否应该恢复TabBar
                // 如果是导航到CharacterDetailView，则不恢复TabBar
                // 在这种情况下，我们不应该做任何操作，因为CharacterDetailView也会隐藏TabBar
                
                // 注意：在SwiftUI中，我们无法直接访问导航栈，但可以检查hideStateStack
                // 如果栈仍然有隐藏状态，表示我们是导航到其他需要隐藏TabBar的视图，而不是返回到主页面
                if tabBarManager.hideStateStack.isEmpty {
                    // 仅当完全离开需要隐藏TabBar的页面层级时才重置TabBar
                    tabBarManager.forceResetAndShow()
                    tabBarManager.applyConsistentStyle()
                    print("ChatView消失返回主页：TabBar状态已重置")
                } else {
                    // 否则，我们是导航到另一个需要隐藏TabBar的页面，不做任何操作
                    print("ChatView消失但导航到其他隐藏TabBar的页面：保持TabBar隐藏")
                }
            }
        }
        // 修改返回按钮为中文
        .environment(\.locale, Locale(identifier: "zh_CN"))
    }
    
    /**
     * 发送消息
     */
    private func sendMessage() {
        guard !messageText.isEmpty || isRecording else { return }
        
        let content = isRecording ? "[语音消息]" : messageText
        
        // 创建用户消息
        let userMessage = Message(
            id: UUID().uuidString,
            conversationId: conversationId,
            senderId: "currentUser",
            receiverId: character.id,
            content: content,
            isFromUser: true
        )
        
        messages.append(userMessage)
        isSending = true
        messageText = ""
        isRecording = false
        
        // 模拟延迟后收到角色回复
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let responseContent = generateResponse(to: content)
            
            // 创建角色消息
            let characterMessage = Message(
                id: UUID().uuidString,
                conversationId: conversationId,
                senderId: character.id,
                receiverId: "currentUser",
                content: responseContent,
                isFromUser: false
            )
            
            messages.append(characterMessage)
            isSending = false
        }
    }
    
    /**
     * 生成角色回复（简单模拟）
     */
    private func generateResponse(to message: String) -> String {
        // 模拟生成回复，实际项目中应连接后端AI模型
        let responses = [
            "这是个很好的问题。从历史角度来看，我认为...",
            "我很高兴你对这个话题感兴趣。在我的时代，我们认为...",
            "让我思考一下这个问题。我想说的是...",
            "这引起了我的深思。基于我的经验，我可以告诉你...",
            "很有趣的观点！我想补充的是..."
        ]
        
        return responses.randomElement() ?? "谢谢你的消息，很高兴与你交流。"
    }
    
    /**
     * 加载历史消息
     */
    private func loadMessages() {
        // 模拟加载历史消息
        let historicalMessages: [Message] = [
            Message(
                id: "1",
                conversationId: conversationId,
                senderId: "currentUser",
                receiverId: character.id,
                content: "您好！很荣幸能与您交流。",
                isFromUser: true,
                timestamp: Date().addingTimeInterval(-3600),
                isRead: true
            ),
            Message(
                id: "2",
                conversationId: conversationId,
                senderId: character.id,
                receiverId: "currentUser",
                content: "你好！很高兴见到你。有什么我可以帮助你的吗？",
                isFromUser: false,
                timestamp: Date().addingTimeInterval(-3580),
                isRead: true
            )
        ]
        
        messages = historicalMessages
    }
}

/**
 * 消息气泡视图
 */
struct ChatMessageBubbleView: View {
    /// 消息数据
    var message: Message
    /// 角色主题色
    var characterThemeColor: Color
    /// 消息状态
    var status: MessageStatus = .sent
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // 角色头像（仅在非用户消息时显示）
            if !message.isFromUser {
                ZStack {
                    // 背景装饰 - 增加历史感
                    Circle()
                        .fill(Color.white)
                        .frame(width: 38, height: 38)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // 角色头像背景 - 增加质感
                    Circle()
                        .fill(characterThemeColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    // 虚拟头像
                    AsyncImage(url: URL(string: "https://example.com/avatar.jpg")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(characterThemeColor.opacity(0.6))
                    }
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(characterThemeColor.opacity(0.4), lineWidth: 1.5)
                    )
                }
                .padding(.top, 4) // 微调头像顶部间距以更好对齐
            } else {
                Spacer()
            }
            
            // 消息气泡
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 2) {
                // 消息内容
                Text(message.content)
                    .font(.system(size: 15))
                    .lineSpacing(5) // 增加行间距改善阅读体验
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(
                        message.isFromUser
                            ? Color.blue.opacity(0.9)
                            : characterThemeColor.opacity(0.12)
                    )
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: message.isFromUser ? 18 : 16,
                            style: .continuous
                        )
                    )
                    // 用户消息添加微妙的高光，历史角色消息添加纹理效果
                    .overlay(
                        Group {
                            if message.isFromUser {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                    .blendMode(.overlay)
                            } else {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(characterThemeColor.opacity(0.2), lineWidth: 0.5)
                            }
                        }
                    )
                    // 增强阴影效果
                    .shadow(color: Color.black.opacity(message.isFromUser ? 0.12 : 0.06), 
                           radius: message.isFromUser ? 1.5 : 1, x: 0, y: 1)
                
                // 消息时间和状态 - 减小与消息气泡的间距
                HStack(spacing: 4) {
                    if message.isFromUser {
                        // 消息状态指示器
                        if status == .sending {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary.opacity(0.7))
                        } else if status == .sent {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary.opacity(0.7))
                        } else if status == .delivered {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary.opacity(0.7))
                        } else if status == .read {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.blue.opacity(0.7))
                        }
                    }
                    
                    // 时间 - 更优雅的样式
                    Text(formatMessageTime(message.timestamp))
                        .font(.system(size: 9, weight: .light))
                        .kerning(0.5)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .padding(.horizontal, 4) // 减小水平内边距
                .padding(.vertical, 1) // 减小垂直内边距
            }
            .padding(.trailing, message.isFromUser ? 0 : 4)
            .padding(.leading, message.isFromUser ? 4 : 0)
            
            // 用户头像（仅在用户消息时显示）
            if message.isFromUser {
                ZStack {
                    // 背景装饰
                    Circle()
                        .fill(Color.white)
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // 用户头像
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundColor(Color.blue.opacity(0.7))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.7))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                }
                .padding(.top, 4) // 微调头像顶部间距以更好对齐
            } else {
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
    
    /**
     * 格式化消息时间
     */
    private func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/**
 * 消息状态枚举
 */
enum MessageStatus {
    case sending    // 发送中
    case sent       // 已发送
    case delivered  // 已送达
    case read       // 已读
}

/**
 * 聊天视图预览
 */
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatView(
                character: CYChatCharacter(
                    id: "preview-id",
                    name: "阿尔伯特·爱因斯坦",
                    introduction: "现代物理学最重要的科学家之一，相对论的创立者",
                    field: "物理学家",
                    birthYear: "1879",
                    deathYear: "1955",
                    avatarUrl: "https://example.com/einstein.jpg",
                    eraTag: "1900s",
                    achievements: ["相对论", "光电效应", "质能方程"],
                    mainWorks: ["相对论：广义和狭义"],
                    keyThoughts: ["时间和空间是相对的", "质量可以转化为能量", "自然界的规律是简单而统一的"],
                    followerCount: 5280,
                    interactionCount: 18600,
                    rating: 4.9
                ),
                conversationId: "testConversation"
            )
        }
    }
}