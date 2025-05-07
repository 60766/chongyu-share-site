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
    
    // 系统返回按钮窗口引用
    @State private var systemBackButtonWindow: UIWindow?
    
    var body: some View {
        ZStack {
            // 添加动态背景 - 增加丰富度但保持简洁
            ZStack {
                // 基础背景色 - 微妙渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.98),
                        Color(UIColor.systemBackground).opacity(0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                // 添加微妙的纹理图案，增强时空感
                GeometryReader { geometry in
                    // 上半部分微妙装饰
                    VStack {
                        HStack(spacing: 0) {
                            // 顶部装饰元素 - 星点图案
                            ForEach(0..<20) { _ in
                                Circle()
                                    .fill(characterThemeColor.opacity(Double.random(in: 0.01...0.05)))
                                    .frame(width: Double.random(in: 1...3), height: Double.random(in: 1...3))
                                    .offset(
                                        x: Double.random(in: 0...geometry.size.width),
                                        y: Double.random(in: 0...geometry.size.height * 0.3)
                                    )
                            }
                        }
                        Spacer()
                    }
                    
                    // 时代印记装饰元素
                    ZStack {
                        // 底部装饰元素 - 代表历史的轻微印记
                        Circle()
                            .stroke(characterThemeColor.opacity(0.03), lineWidth: 60)
                            .frame(width: geometry.size.width * 1.8, height: geometry.size.width * 1.8)
                            .offset(y: geometry.size.height * 0.65)
                            .blur(radius: 30)
                        
                        // 中部装饰元素
                        Circle()
                            .stroke(characterThemeColor.opacity(0.02), lineWidth: 1.5)
                            .frame(width: 220, height: 220)
                            .offset(x: geometry.size.width * 0.4, y: geometry.size.height * 0.25)
                            .blur(radius: 1)
                            
                        // 中部装饰元素 - 扩散圆环，代表思想传播
                        ForEach(0..<3) { index in
                            Circle()
                                .stroke(characterThemeColor.opacity(0.01 + 0.01 * Double(3 - index)), lineWidth: 1)
                                .frame(width: 100 + CGFloat(index) * 60, height: 100 + CGFloat(index) * 60)
                                .offset(x: -geometry.size.width * 0.3, y: geometry.size.height * 0.28)
                        }
                    }
                }
            }
            
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
                                            Color(.systemBackground),
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
                
                // 底部输入区域 - 优化设计，增加质感和互动性
                VStack(spacing: 0) {
                    // 顶部微妙阴影线
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.05),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 4)
                    
                    ZStack {
                        // 背景半透明模糊效果 - 增强现代感
                        Rectangle()
                            .fill(Color(.systemBackground).opacity(0.95))
                            .frame(height: 70)
                        
                        // 内容区
                        HStack(spacing: 14) {
                            // 语音按钮 - 优化样式，增强视觉吸引力
                            Button(action: {
                                isRecording.toggle()
                                // 触感反馈
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }) {
                                ZStack {
                                    // 背景增加渐变，增强立体感
                                    Circle()
                                        .fill(
                                            isRecording 
                                                ? LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.red.opacity(0.15),
                                                        Color.red.opacity(0.1)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                                : LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        characterThemeColor.opacity(0.08),
                                                        characterThemeColor.opacity(0.05)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                        )
                                        .frame(width: 38, height: 38)
                                        .shadow(color: isRecording ? Color.red.opacity(0.2) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                    
                                    // 内部微妙描边
                                    Circle()
                                        .stroke(
                                            isRecording 
                                                ? Color.red.opacity(0.3) 
                                                : characterThemeColor.opacity(0.2),
                                            lineWidth: 1
                                        )
                                        .frame(width: 38, height: 38)
                                    
                                    // 图标
                                    Image(systemName: isRecording ? "mic.fill" : "mic")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(isRecording ? .red : characterThemeColor.opacity(0.8))
                                        .shadow(color: isRecording ? Color.red.opacity(0.3) : Color.clear, radius: 2, x: 0, y: 0)
                                }
                                .frame(width: 42, height: 42) // 增加点击区域
                                .contentShape(Circle())
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            // 文本输入框 - 更精致的设计
                            HStack {
                                TextField("写下你想说的...", text: $messageText)
                                    .font(.system(size: 15))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        characterThemeColor.opacity(0.05),
                                                        Color(.systemGray6).opacity(0.35)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                characterThemeColor.opacity(0.2),
                                                                characterThemeColor.opacity(0.05)
                                                            ]),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                        lineWidth: 0.8
                                                    )
                                            )
                                            .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
                                    )
                                    .disabled(isRecording)
                                    .opacity(isRecording ? 0.5 : 1)
                            }
                            .frame(maxWidth: .infinity)
                            
                            // 发送按钮 - 更精致的设计
                            Button(action: sendMessage) {
                                ZStack {
                                    // 渐变背景
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    characterThemeColor,
                                                    characterThemeColor.opacity(0.8)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 38, height: 38)
                                        .shadow(color: characterThemeColor.opacity(0.3), radius: 3, x: 0, y: 2)
                                    
                                    // 发送图标
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    // 顶部微妙高光
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        .frame(width: 36, height: 36)
                                        .offset(y: -0.5)
                                }
                            }
                            .disabled(messageText.isEmpty && !isRecording)
                            .opacity(messageText.isEmpty && !isRecording ? 0.6 : 1.0)
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                }
                .background(
                    // 微妙的波浪线纹理，增加古典感但保持简洁
                    ZStack {
                        ForEach(0..<3) { index in
                            Path { path in
                                let width = UIScreen.main.bounds.width
                                let height: CGFloat = 5
                                
                                path.move(to: CGPoint(x: 0, y: height * CGFloat(index + 1)))
                                
                                for i in stride(from: 0, to: width, by: 1) {
                                    let x = i
                                    let y = sin(i * 0.01 + Double(index) * 2) * 2 + Double(height * CGFloat(index + 1))
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                            .stroke(characterThemeColor.opacity(0.04), lineWidth: 0.8)
                        }
                    }
                    .mask(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.clear, .black, .black, .clear]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                )
            }
            
            // 录音界面
            if isRecording {
                VStack(spacing: 16) {
                    // 时空穿越波形元素 - 更加优雅
                    ZStack {
                        // 背景辉光效果
                        Circle()
                            .fill(characterThemeColor.opacity(0.05))
                            .frame(width: 70, height: 70)
                            .blur(radius: 10)
                        
                        // 波形动画
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
                    }
                    .padding(.bottom, 8)
                    
                    // 录音状态文本
                    Text("正在聆听...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(characterThemeColor.opacity(0.8))
                        .kerning(0.5)
                    
                    // 取消按钮 - 更优雅设计
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
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
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
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(.systemBackground),
                                        Color(.systemBackground).opacity(0.98)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
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
                        
                        // 微妙边框 - 更精致的渐变效果
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
                // 高级导航栏背景
                ZStack {
                    // 背景色
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(.systemBackground).opacity(0.98),
                                    Color(.systemBackground).opacity(0.95)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 44)
                    
                    // 顶部精致描边
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        characterThemeColor.opacity(0.15),
                                        characterThemeColor.opacity(0.05)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 0.5)
                    }
                    .frame(height: 44)
                }
                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                
                Spacer()
            }
            .edgesIgnoringSafeArea(.top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(character.name)
        // 自定义导航栏样式，但不显示返回按钮
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .edgesIgnoringSafeArea(.bottom)
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
                
                // 添加系统级返回按钮
                addSystemLevelBackButton()
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
                
                // 清理返回按钮窗口
                if let window = systemBackButtonWindow {
                    // 立即隐藏窗口
                    window.isHidden = true
                    window.rootViewController?.view.subviews.forEach { $0.removeFromSuperview() }
                    window.rootViewController = nil
                    
                    // 立即清除引用
                    systemBackButtonWindow = nil
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
    
    /**
     * 创建一个覆盖在左上角的浮动返回按钮
     */
    private func addSystemLevelBackButton() {
        // 计算顶部安全区域高度，为返回按钮定位
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let topPadding = windowScene?.windows.first?.safeAreaInsets.top ?? 44
        
        // 创建新窗口 - 只覆盖左上角返回按钮区域
        let buttonWindow = UIWindow(frame: CGRect(
            x: 0,
            y: 0,
            width: 50,
            height: topPadding + 44
        ))
        buttonWindow.tag = 9999 // 为后续标识设置tag
        
        // 设置窗口属性
        buttonWindow.isUserInteractionEnabled = true
        buttonWindow.windowLevel = .alert // 使用高层级确保可见
        buttonWindow.backgroundColor = .clear
        buttonWindow.accessibilityViewIsModal = false
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            buttonWindow.windowScene = windowScene
        }
        
        // 设置根视图控制器
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        buttonWindow.rootViewController = viewController
        
        // 配置返回按钮
        let backButton = UIButton(type: .system)
        backButton.frame = CGRect(x: 16, y: topPadding + 10, width: 30, height: 30)
        
        // 设置按钮图标
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = UIImage(systemName: "chevron.left", withConfiguration: imageConfig)
        backButton.setImage(image, for: .normal)
        
        // 使用主题色作为按钮颜色
        let themeColor = UIColor(characterThemeColor)
        backButton.tintColor = themeColor
        
        // 添加按钮点击事件
        backButton.addAction(UIAction { _ in
            // 立即隐藏按钮窗口
            buttonWindow.isHidden = true
            
            // 触发轻柔触觉反馈
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            // 返回操作
            dismiss()
        }, for: .touchUpInside)
        
        // 添加到视图控制器的视图
        viewController.view.addSubview(backButton)
        
        // 保存窗口引用并显示
        systemBackButtonWindow = buttonWindow
        buttonWindow.makeKeyAndVisible()
    }
}

/**
 * 消息气泡视图
 */
struct ChatMessageBubbleView: View {
    let message: Message
    let characterThemeColor: Color
    
    @State private var messageStatus: MessageStatus = .delivered
    
    var body: some View {
        // 计算气泡状态
        let status = message.isFromUser
            ? messageStatus
            : .read // 角色的消息总是已读
        
        HStack(alignment: .top, spacing: 8) {
            // 角色头像（仅在角色消息时显示）
            if !message.isFromUser {
                ZStack {
                    // 背景装饰 - 增加纸张质感，代表历史感
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.98),
                                    Color.white.opacity(0.90)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                    
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
                            .stroke(characterThemeColor.opacity(0.4), lineWidth: 1)
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
                            ? LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.95),
                                    Color.blue.opacity(0.85)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                gradient: Gradient(colors: [
                                    characterThemeColor.opacity(0.14),
                                    characterThemeColor.opacity(0.10)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
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
                        ZStack {
                            if message.isFromUser {
                                // 用户消息上部高光，增强视觉层次感
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                                    .blendMode(.overlay)
                                    .mask(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.white, .clear]),
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                            } else {
                                // 历史角色消息添加精致边框
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                characterThemeColor.opacity(0.2),
                                                characterThemeColor.opacity(0.05)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.8
                                    )
                                
                                // 角色消息添加微妙的纸张纹理 - 代表历史感
                                if !message.isFromUser {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color(.displayP3, white: 0.5, opacity: 0.03))
                                        .mask(
                                            ZStack {
                                                // 创建随机点状纹理
                                                ForEach(0..<20) { _ in
                                                    Circle()
                                                        .fill(Color.white.opacity(Double.random(in: 0.1...0.3)))
                                                        .frame(width: Double.random(in: 1...2), height: Double.random(in: 1...2))
                                                        .offset(
                                                            x: Double.random(in: -50...50),
                                                            y: Double.random(in: -20...20)
                                                        )
                                                }
                                            }
                                        )
                                        .allowsHitTesting(false)
                                }
                            }
                        }
                    )
                    // 增强阴影效果
                    .shadow(color: message.isFromUser 
                            ? Color.blue.opacity(0.15)
                            : characterThemeColor.opacity(0.08), 
                           radius: message.isFromUser ? 2 : 1.5, x: 0, y: 1)
                
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
                        .kerning(0.3)
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
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.98),
                                    Color.white.opacity(0.90)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                    
                    // 用户头像
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundColor(Color.blue.opacity(0.7))
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.8), lineWidth: 1)
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