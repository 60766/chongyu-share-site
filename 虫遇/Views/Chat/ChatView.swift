import SwiftUI
import SwiftData

/**
 * 聊天视图
 * 用于用户与历史人物进行对话
 */
struct ChatView: View {
    /// 聊天角色
    var character: Character
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
    
    var body: some View {
        VStack(spacing: 0) {
            // 消息列表
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // 对话开始提示
                        HStack {
                            Spacer()
                            
                            Text("与 \(character.name) 的对话开始")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(16)
                            
                            Spacer()
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        
                        // 消息气泡
                        ForEach(messages, id: \.id) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                        
                        // 底部占位，确保能滚动到底部
                        Color.clear
                            .frame(height: 1)
                            .id("bottomId")
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                .onChangeCompat(of: messages) { oldValue, newValue in
                    if oldValue.count != newValue.count {
                        withAnimation {
                            scrollView.scrollTo("bottomId", anchor: .bottom)
                        }
                    }
                }
            }
            
            // 底部输入栏
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 12) {
                    // 语音按钮
                    Button(action: {
                        isRecording.toggle()
                    }) {
                        Image(systemName: isRecording ? "mic.fill" : "mic")
                            .font(.system(size: 20))
                            .foregroundColor(isRecording ? .red : .primary)
                            .frame(width: 36, height: 36)
                    }
                    
                    // 文本输入框
                    TextField("输入消息...", text: $messageText)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(18)
                        .disabled(isRecording)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(isRecording ? Color.gray.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                        .opacity(isRecording ? 0.5 : 1)
                    
                    // 发送按钮
                    Button(action: {
                        sendMessage()
                    }) {
                        Image(systemName: messageText.isEmpty ? "plus" : "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(messageText.isEmpty ? .primary : .primaryColor)
                            .frame(width: 36, height: 36)
                    }
                    .disabled(messageText.isEmpty && !isRecording)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            
            // 录音界面
            if isRecording {
                VStack(spacing: 16) {
                    // 录音波形
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.primaryColor)
                                .frame(width: 3, height: CGFloat(10 + Int.random(in: 5...30)))
                                .animation(
                                    Animation.easeInOut(duration: 0.5)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.1),
                                    value: isRecording
                                )
                        }
                    }
                    .frame(height: 40)
                    
                    Text("正在聆听...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    // 取消录音按钮
                    Button(action: {
                        isRecording = false
                    }) {
                        Text("取消")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.red)
                            .cornerRadius(20)
                    }
                }
                .padding(.vertical, 16)
                .background(Color.white)
                .transition(.move(edge: .bottom))
            }
        }
        .navigationTitle(character.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            // 分享界面
            Text("分享与 \(character.name) 的对话")
        }
        .onAppear {
            loadMessages()
        }
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
struct MessageBubbleView: View {
    /// 消息数据
    var message: Message
    /// 消息状态
    var status: MessageStatus = .sent
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // 用户头像（仅在非用户消息时显示）
            if !message.isFromUser {
                AsyncImage(url: URL(string: "https://example.com/avatar.jpg")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray.opacity(0.3))
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                Spacer()
            }
            
            // 消息气泡
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 2) {
                // 消息内容
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isFromUser ? Color.primaryColor : Color.gray.opacity(0.1))
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // 消息时间和状态
                HStack(spacing: 4) {
                    if message.isFromUser {
                        // 消息状态指示器
                        if status == .sending {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        } else if status == .sent {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        } else if status == .delivered {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        } else if status == .read {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // 时间
                    Text(formatMessageTime(message.timestamp))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
            }
            
            // 用户头像（仅在用户消息时显示）
            if message.isFromUser {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 32, height: 32)
            } else {
                Spacer()
            }
        }
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
                character: Character(
                    name: "阿尔伯特·爱因斯坦",
                    introduction: "现代物理学最重要的科学家之一，相对论的创立者",
                    field: "物理学家",
                    birthYear: "1879",
                    deathYear: "1955",
                    avatarUrl: "https://example.com/einstein.jpg",
                    eraTag: "1900s",
                    achievements: ["相对论", "光电效应", "质能方程"],
                    mainWorks: ["相对论：广义和狭义"],
                    keyThoughts: ["时间和空间是相对的", "质量可以转化为能量"]
                ),
                conversationId: "testConversation"
            )
        }
    }
} 