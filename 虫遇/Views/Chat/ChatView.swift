import SwiftUI
import SwiftData

// 引入CYChatCharacter
import Foundation
import Combine

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
    /// 是否已完成初始加载，用于控制初始滚动动画
    @State private var hasInitialized = false
    // 录音功能已移除
    
    // 键盘和输入框状态
    @FocusState private var isInputFocused: Bool
    @State private var textFieldFocused: Bool = false  // 绑定到AutoSizingTextView
    // 使用ChatInputBar组件，移除不再需要的状态变量
    @State private var isExpanded: Bool = false // 控制是否展开全屏模式
    @State private var lastText = "" // 用于检测文本变化
    
    // 添加用于API请求的取消令牌集合
    private var cancellables = Set<AnyCancellable>()
    
    // 虚拟角色服务
    private let virtualCharacterService = VirtualCharacterService.shared
    
    // TabBar管理器
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    // 分享相关状态
    @State private var isShareMode = false
    @State private var selectedMessages: Set<String> = []
    @State private var showShareModal = false
    @State private var shareCards: [UIImage] = []
    
    // 获取SwiftData的ModelContext
    @Environment(\.modelContext) private var modelContext
    
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
    // 系统分享按钮窗口引用（与角色详情一致的右上角小图标）
    @State private var systemShareButtonWindow: UIWindow?
    
    // 添加公开的初始化器，解决访问控制问题
    init(character: CYChatCharacter, conversationId: String) {
        self.character = character
        self.conversationId = conversationId
    }
    
    // 添加简化的初始化方法，自动生成稳定的会话ID
    init(character: CYChatCharacter) {
        self.character = character
        // 为每个角色生成一个固定的会话ID，确保每次打开同一角色时使用相同的ID
        self.conversationId = "chat_\(character.id)_currentUser"
    }
    
    var body: some View {
        ZStack {
            // 添加动态背景 - 增加丰富度但保持简洁
            ZStack {
                // 基础背景色 - 微妙渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        DesignSystem.Colors.background,
                        DesignSystem.Colors.background.opacity(0.98),
                        DesignSystem.Colors.background.opacity(0.95)
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
                                            DesignSystem.Colors.background,
                                            DesignSystem.Colors.background.opacity(0)
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
                                            .background(DesignSystem.Colors.background)
                                    }
                                    .padding(.top, 10)
                                    .padding(.bottom, 16)
                                }
                                
                                // 消息列表区域
                                LazyVStack(spacing: 12) {  // 减小消息间距从16到12，让对话更紧凑
                                    // 消息气泡
                                    ForEach(messages, id: \.id) { message in
                                        ShareableMessageBubbleView(
                                            message: message, 
                                            characterThemeColor: characterThemeColor,
                                            isShareMode: isShareMode,
                                            isSelected: selectedMessages.contains(message.id),
                                            onSelectionToggle: {
                                                toggleMessageSelection(message.id)
                                            }
                                        )
                                        .id(message.id)
                                    }
                                    
                                    // 底部占位区域 - 增加高度确保内容能滚动到底部安全区以上
                                    // 增加更多空间，确保键盘弹出时消息不被遮挡
                                    Color.clear
                                        .frame(height: 180) // 使用固定高度，keyboardAdaptive会自动处理键盘适配
                                        .id("bottomId")
                                        // 添加一个onAppear处理器，确保当此视图出现时滚动到底部
                                        .onAppear {
                                            // 当底部ID出现时，确保滚动到底部
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                                NotificationCenter.default.post(
                                                    name: NSNotification.Name("ScrollToBottom"),
                                                    object: nil
                                                )
                                            }
                                        }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 30) // 使用固定底部间距，keyboardAdaptive会自动处理键盘适配
                            }
                        }
                        .onChangeCompat(of: messages) { oldValue, newValue in
                            // 只在以下情况滚动：1. 消息数量增加 2. 初始化完成 3. 用户发送了新消息
                            if oldValue.count != newValue.count && hasInitialized {
                                // 检查是否是用户发送的新消息或AI回复
                                let isUserSentNewMessage = newValue.last?.isFromUser ?? false
                                let isAIReply = !isUserSentNewMessage && newValue.count > oldValue.count
                                
                                if isUserSentNewMessage || isAIReply {
                                    // 使用更短的延迟，提高响应速度
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            // 使用centerY而不是bottom，这样最新消息会显示在视图中间位置
                                            // 而不是贴着输入框的底部
                                            scrollView.scrollTo("bottomId", anchor: .center)
                                        }
                                    }
                                }
                            }
                        }
                        // 监听滚动到底部的通知
                        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ScrollToBottom"))) { _ in
                            // 只有在初始化完成后才使用动画滚动
                            if hasInitialized {
                                withAnimation(.easeInOut(duration: 0.25)) {  // 减少动画时长，提高响应速度
                                // 使用滚动动画，确保流畅的滚动效果
                                    // 使用centerY锚点，让最新消息显示在中间位置而不是底部
                                    scrollView.scrollTo("bottomId", anchor: .center)
                                }
                            } else {
                                // 初始加载时直接滚动，不使用动画
                                // 使用双重保险确保滚动到底部
                                // 使用centerY锚点，确保最新消息显示在更合适的位置
                                scrollView.scrollTo("bottomId", anchor: .center)
                                
                                // 延迟再次滚动，确保内容已完全加载
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    scrollView.scrollTo("bottomId", anchor: .center)
                                }
                            }
                        }
                        // 标记滚动视图，方便在键盘通知中直接访问
                        .background(
                            // 使用空视图，但附加标记
                            Color.clear
                                .preference(key: ViewTagPreferenceKey.self, value: 9999)
                                .onPreferenceChange(ViewTagPreferenceKey.self) { tag in
                                    // 设置滚动视图的标记
                                    DispatchQueue.main.async {
                                        // 修复iOS 15+弃用警告，使用UIWindowScene.windows
                                        if #available(iOS 15.0, *) {
                                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                               let rootViewController = windowScene.windows.first?.rootViewController,
                                               let scrollView = rootViewController.view.viewWithTag(9999) as? UIScrollView {
                                                scrollView.tag = tag
                                            }
                                        } else {
                                            // 旧版本继续使用已弃用的API
                                            if let scrollView = UIApplication.shared.windows.first?.rootViewController?.view.viewWithTag(9999) as? UIScrollView {
                                                scrollView.tag = tag
                                            }
                                        }
                                    }
                                }
                        )
                        // 移除键盘状态监听，keyboardAdaptive会自动处理
                    }
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded { _ in
                                // 点击空白区域时收起键盘
                                if textFieldFocused {
                                    hideKeyboard()
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        textFieldFocused = false
                                    }
                                }
                            }
                    )
                }
                
                // 分享模式底部操作栏
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
                    // 底部输入区域 - 使用和多人聊天完全相同的组件
                    ChatInputBar(
                        messageText: $messageText,
                        isSending: $isSending,
                        characterThemeColor: characterThemeColor,
                        onSend: {
                            sendMessage()
                        }
                    )
                    .background(DesignSystem.Colors.background)
                    .edgesIgnoringSafeArea(.bottom)
                }
            }
            
            // 录音界面已移除
            
            // 顶部安全遮罩 - 确保内容不会与导航栏重叠
            VStack {
                // 高级导航栏背景
                ZStack {
                    // 背景色
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    DesignSystem.Colors.background.opacity(0.98),
                                    DesignSystem.Colors.background.opacity(0.95)
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
                                        Color.warmAccent.opacity(0.01),
                                        Color.warmAccent.opacity(0.005)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 0.15)
                    }
                    .frame(height: 44)
                }
                .background(DesignSystem.Colors.background) // 添加背景色，确保贴合键盘
                .shadow(color: Color.black.opacity(0.01), radius: 1, x: 0, y: 1)
                
                Spacer()
            }
            .edgesIgnoringSafeArea(.top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(character.name)
        // 自定义导航栏样式，但不显示返回按钮
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        // 移除导航栏内置的分享按钮，改为系统级覆盖按钮以保持与角色详情一致
        .edgesIgnoringSafeArea(.bottom) // 忽略底部安全区域，确保输入框贴合屏幕底部
        .fullScreenCover(isPresented: $showShareModal) {
            ChatShareModalView(
                isPresented: $showShareModal,
                shareCards: shareCards,
                characterName: character.name
            )
        }
        .dismissKeyboardOnTap() // 添加点击空白区域收起键盘的功能
        .onAppear {
            DispatchQueue.main.async {
                // 不再处理TabBar状态，保持底部导航栏可见
                /*
                // 检查当前TabBar状态栈
                if tabBarManager.hideStateStack.isEmpty {
                    // 如果状态栈为空，这是首次进入聊天页面
                    // 推入一个新的隐藏状态
                    tabBarManager.pushHideState()
                    print("ChatView首次出现：TabBar已隐藏")
                } else {
                    // 如果状态栈不为空，表示可能是从角色详情页返回
                    // 确保TabBar仍然是隐藏的，但不重置堆栈
                    
                    // 确保状态栈中只有一个隐藏状态
                    while tabBarManager.hideStateStack.count > 1 {
                        tabBarManager.popHideState()
                    }
                    
                    // 如果状态栈为空，重新隐藏TabBar
                    if tabBarManager.hideStateStack.isEmpty {
                        tabBarManager.pushHideState()
                    }
                    
                    print("ChatView再次出现：TabBar状态已调整，当前深度: \(tabBarManager.hideStateStack.count)")
                }
                */
                
                // 加载消息数据
                loadMessages()
                
                // 立即标记初始化完成，但不立即允许动画滚动
                hasInitialized = false
                
                // 使用更短的延迟时间
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    hasInitialized = true
                    
                    // 初始化完成后，再次确保滚动到底部
                    if !self.messages.isEmpty {
                        // 发送滚动通知
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ScrollToBottom"),
                            object: nil
                        )
                    }
                }
                
                // 添加系统级返回按钮
                addSystemLevelBackButton()
                // 添加系统级分享按钮（与角色详情视觉一致）
                addSystemLevelShareButton()
                
                // 使用keyboardAdaptive，无需手动设置键盘通知
                
                // ChatInputBar组件会自动管理高度
                isExpanded = false
                
                // 触发输入框内文本显示到底部
                if !messageText.isEmpty {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ScrollCommentToBottom"),
                        object: nil
                    )
                }
            }
        }
        .onDisappear {
            // 不再处理TabBar状态，保持底部导航栏可见
            /*
            // 立即处理TabBar状态，无任何延迟
            // 我们需要检查当前导航路径以确定是否应该恢复TabBar
            // 如果是导航到CharacterDetailView，则不恢复TabBar
            // 如果是返回到角色详情页，我们需要确保TabBar状态栈的一致性
            
            if tabBarManager.hideStateStack.isEmpty {
                // 仅当完全离开需要隐藏TabBar的页面层级时才重置TabBar
                // 立即强制显示，无任何延迟
                tabBarManager.showImmediately()
                print("ChatView消失返回主页：TabBar立即重置并显示")
            } else {
                // 如果是返回到角色详情页，我们需要确保TabBar状态栈的一致性
                // 确保状态栈中只有一个隐藏状态
                while tabBarManager.hideStateStack.count > 1 {
                    tabBarManager.popHideState()
                }
                print("ChatView消失返回角色详情页：TabBar状态栈已调整，当前深度: \(tabBarManager.hideStateStack.count)")
            }
            */
            
            // 清理系统返回按钮窗口
            if let window = systemBackButtonWindow {
                window.isHidden = true
                window.rootViewController = nil
                systemBackButtonWindow = nil
            }
            // 清理系统分享按钮窗口
            if let window = systemShareButtonWindow {
                window.isHidden = true
                window.rootViewController = nil
                systemShareButtonWindow = nil
            }
            
            // 使用keyboardAdaptive，无需手动移除键盘通知
        }
        // 修改返回按钮为中文
        .environment(\.locale, Locale(identifier: "zh_CN"))
        // 同步FocusState和普通State变量
        .onChange(of: textFieldFocused) { oldValue, newValue in
            // 使用动画使状态变化更平滑
            withAnimation(.easeInOut(duration: 0.2)) {
                isInputFocused = newValue
            }
            
            // 如果失去焦点，重置视图位置和输入框高度
            if !newValue {
                // 使用动画重置状态
                withAnimation(.easeInOut(duration: 0.25)) {
                    // keyboardAdaptive会自动处理键盘状态
                    
                    // 重置输入框高度为初始状态
                    // ChatInputBar组件会自动管理高度
                    
                    // 如果输入框已展开，则收起
                    if isExpanded {
                        isExpanded = false
                    }
                }
                
                // 立即隐藏键盘
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            // 如果获得焦点，模拟键盘弹出（仅适用于模拟器测试）
            else if newValue {
                // 模拟器中可能需要手动触发键盘
                simulateKeyboardForSimulator()
            }
        }
        .onChange(of: isInputFocused) { oldValue, newValue in
            // 使用动画使状态变化更平滑
            withAnimation(.easeInOut(duration: 0.2)) {
                textFieldFocused = newValue
            }
        }
        // 监听消息文本变化
        .onChange(of: messageText) { oldValue, newValue in
            // ChatInputBar组件会自动处理高度调整
        }
        // 在自定义分享卡片全屏打开/关闭时，隐藏/恢复系统级返回与分享按钮
        .onChange(of: showShareModal) { oldValue, newValue in
            if newValue {
                // 打开分享卡片：隐藏系统级按钮避免遮挡
                if let backWindow = systemBackButtonWindow { backWindow.isHidden = true }
                if let shareWindow = systemShareButtonWindow { shareWindow.isHidden = true }
            } else {
                // 关闭分享卡片：恢复系统级按钮
                if let backWindow = systemBackButtonWindow {
                    backWindow.isHidden = false
                } else {
                    addSystemLevelBackButton()
                }
                if let shareWindow = systemShareButtonWindow {
                    shareWindow.isHidden = false
                } else {
                    addSystemLevelShareButton()
                }
            }
        }
        // 移除viewOffset的onChange，使用统一的键盘适配
        // 移除keyboardHeight的onChange，使用keyboardAdaptive统一管理
        // ChatInputBar组件会自动处理高度变化
    }
    
    /**
     * 发送消息
     */
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let content = messageText
        
        // 调试日志已关闭
        // print("\n📱 ===== 用户发送消息 =====")
        // print("📤 消息内容: \"\(content)\"")
        // print("🗣️ 发送给角色: \(character.name) (ID: \(character.id))")
        // print("🔄 会话ID: \(conversationId)")
        // print("📱 ===== 消息详情结束 =====\n")
        
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
        messageText = ""
        
        // 保存消息到数据库
        saveMessage(userMessage)
        
        // 添加触觉反馈
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // 发送消息后重置输入框状态
        textFieldFocused = false
        isInputFocused = false
        // ChatInputBar组件会自动管理高度 // 重置输入框高度
        
        // 发送消息后隐藏键盘
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // 检查是否已经有等待响应的消息，如果有，则不再生成新的等待消息和API请求
        if !isSending {
            isSending = true
            
            // 添加等待指示器消息
            let waitingMessage = Message(
                id: UUID().uuidString + "_waiting",
                conversationId: conversationId,
                senderId: character.id,
                receiverId: "currentUser",
                content: "...",
                isFromUser: false
            )
            
            // 添加等待消息到UI（但不保存到数据库）
            messages.append(waitingMessage)
            
            // 启动一个延迟计时器，如果短时间内用户没有继续发送消息，则发送API请求
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [self] in
                // 如果用户在短时间内没有继续发送新消息，则发送API请求
                if self.isSending {
                    self.processUserMessages(waitingMessageId: waitingMessage.id)
                }
            }
        }
    }
    
    /**
     * 处理用户发送的消息，并获取角色回复
     * @param waitingMessageId 等待消息的ID，用于移除等待指示器
     */
    private func processUserMessages(waitingMessageId: String) {
        // 获取最近的用户消息
        let userMessages = messages.filter { $0.isFromUser }
        
        // 如果没有用户消息，不处理
        guard !userMessages.isEmpty else {
            isSending = false
            return
        }
        
        // 获取最后一条用户消息
        guard let latestUserMessage = userMessages.last else {
            isSending = false
            return
        }
        
        // 构建对话历史上下文
        let conversationHistory = buildConversationContext()
        
        // 调用虚拟角色服务获取回复
        virtualCharacterService.getCharacterChatReply(
            character: character,
            userMessage: latestUserMessage.content,
            conversationHistory: conversationHistory
        ) { [self] result in
            // 切换到主线程更新UI
            DispatchQueue.main.async {
                // 如果存在等待消息，移除它
                if !waitingMessageId.isEmpty {
                    messages.removeAll(where: { $0.id == waitingMessageId })
                }
                
                // 处理API调用结果
                switch result {
                case .success(let responseContent):
                    // 创建角色消息
                    let characterMessage = Message(
                        id: UUID().uuidString,
                        conversationId: conversationId,
                        senderId: character.id,
                        receiverId: "currentUser",
                        content: responseContent,
                        isFromUser: false
                    )
                    
                    // 添加到消息列表
                    messages.append(characterMessage)
                    
                    // 保存角色消息到数据库
                    saveMessage(characterMessage)
                    
                case .failure(_):
                    // 处理错误情况
                    
                    // 创建错误提示消息
                    let errorMessage = Message(
                        id: UUID().uuidString,
                        conversationId: conversationId,
                        senderId: character.id,
                        receiverId: "currentUser",
                        content: "抱歉，我暂时无法回复。请稍后再试。",
                        isFromUser: false
                    )
                    
                    // 添加到消息列表
                    messages.append(errorMessage)
                    
                    // 保存错误消息到数据库
                    saveMessage(errorMessage)
                }
                
                // 无论成功失败，都结束发送状态
                isSending = false
            }
        }
    }
    
    /**
     * 获取角色回复（API调用）
     */
    private func getCharacterReply(userContent: String, waitingMessageId: String? = nil) {
        // 构建对话历史上下文
        let conversationHistory = buildConversationContext()
        
        // 调用虚拟角色服务获取回复
        virtualCharacterService.getCharacterChatReply(
            character: character,
            userMessage: userContent,
            conversationHistory: conversationHistory
        ) { result in
            // 切换到主线程更新UI
            DispatchQueue.main.async {
                // 如果存在等待消息，移除它
                if let waitingId = waitingMessageId {
                    self.messages.removeAll(where: { $0.id == waitingId })
                }
                
                // 处理API调用结果
                switch result {
                case .success(let responseContent):
                    // 创建角色消息
                    let characterMessage = Message(
                        id: UUID().uuidString,
                        conversationId: conversationId,
                        senderId: character.id,
                        receiverId: "currentUser",
                        content: responseContent,
                        isFromUser: false
                    )
                    
                    // 添加到消息列表
                    self.messages.append(characterMessage)
                    
                    // 保存角色消息到数据库
                    self.saveMessage(characterMessage)
                    
                case .failure(_):
                    // 处理错误情况
                    
                    // 创建错误提示消息
                    let errorMessage = Message(
                        id: UUID().uuidString,
                        conversationId: conversationId,
                        senderId: character.id,
                        receiverId: "currentUser",
                        content: "抱歉，我暂时无法回复。请稍后再试。",
                        isFromUser: false
                    )
                    
                    // 添加到消息列表
                    self.messages.append(errorMessage)
                    
                    // 保存错误消息到数据库
                    self.saveMessage(errorMessage)
                }
                
                // 无论成功失败，都结束发送状态
                self.isSending = false
            }
        }
    }
    
    /**
     * 构建对话上下文
     * 用于提供给API更好的上下文理解
     */
    private func buildConversationContext() -> String {
        // 优化为保留最近4轮对话（最多8条消息）- 产品经理建议的最佳平衡点
        let recentMessages = messages.suffix(8) // 最近8条消息，相当于4轮对话
        
        // 极简上下文格式
        var context = ""
        
        for message in recentMessages {
            // 使用极简标识，完全去除多余字符
            let prefix = message.isFromUser ? "用户:" : "\(character.name):"
            // 移除所有不必要的空白和换行
            let content = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: " ")
            context += "\(prefix)\(content) "
        }
        
        // 调试日志已关闭
        // print("\n🔄 ===== 构建对话上下文 =====")
        // print("📜 最近消息数量: \(recentMessages.count)")
        // print("📝 对话上下文内容:")
        // print(context)
        // print("🔄 ===== 上下文构建结束 =====\n")
        
        return context
    }
    
    /**
     * 加载历史消息
     */
    private func loadMessages() {
        // 优化：不要先清空消息数组，这会导致界面闪烁
        // 而是在加载完成后一次性更新
        
        // 使用SwiftData加载历史消息，优先级设为高
        Task(priority: .high) {
            do {
                // 创建查询条件：按conversationId筛选
                let predicate = #Predicate<Message> { message in
                    message.conversationId == conversationId
                }
                
                // 创建排序描述符：按时间戳排序
                let sortDescriptor = SortDescriptor<Message>(\.timestamp)
                
                // 执行查询
                let fetchDescriptor = FetchDescriptor<Message>(
                    predicate: predicate,
                    sortBy: [sortDescriptor]
                )
                
                // 获取结果
                let historicalMessages = try modelContext.fetch(fetchDescriptor)
                
                // 更新UI，使用主线程同步执行以提高响应速度
                await MainActor.run {
                    if historicalMessages.isEmpty {
                        // 🔧 修复：当没有历史消息时，清空消息数组，避免显示错误的消息
                        self.messages = []
                        print("📱 没有找到历史消息记录，已清空消息数组")
                    } else {
                        print("📱 成功加载 \(historicalMessages.count) 条历史消息")
                        
                        // 一次性更新消息数组，避免多次重绘
                        self.messages = historicalMessages
                        
                        // 立即滚动到底部，不使用动画
                        // 使用两种方式确保滚动到底部
                        DispatchQueue.main.async {
                            // 方法1: 通过UIScrollView直接控制
                            if let scrollView = UIScrollView.findScrollViewInHierarchy() {
                                scrollView.scrollToBottom(animated: false)
                            }
                            
                            // 方法2: 通过通知触发SwiftUI的ScrollViewReader
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ScrollToBottom"),
                                object: nil
                            )
                        }
                    }
                }
            } catch {
    
            }
        }
    }
    
    /**
     * 保存消息到数据库
     */
    private func saveMessage(_ message: Message) {
        // 插入消息
        modelContext.insert(message)
        
        // 保存更改
        do {
            try modelContext.save()

            
            // 更新或创建会话记录
            updateConversation(with: message)
        } catch {

        }
    }
    
    /**
     * 更新或创建会话记录
     */
    private func updateConversation(with message: Message) {
        do {
            // 查找现有会话
            let predicate = #Predicate<SDConversation> { conversation in
                conversation.id == conversationId
            }
            let fetchDescriptor = FetchDescriptor<SDConversation>(predicate: predicate)
            let existingConversations = try modelContext.fetch(fetchDescriptor)
            
            if let existingConversation = existingConversations.first {
                // 更新现有会话
                existingConversation.lastMessageContent = message.content
                existingConversation.lastMessageTime = message.timestamp
                existingConversation.messageCount += 1
                existingConversation.updatedAt = Date()
            } else {
                // 创建新会话
                let newConversation = SDConversation(
                    id: conversationId,
                    characterId: character.id,
                    userId: "currentUser",
                    lastMessageContent: message.content,
                    lastMessageTime: message.timestamp,
                    messageCount: 1,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                modelContext.insert(newConversation)
            }
            
            // 保存更改
            try modelContext.save()
            
        } catch {

        }
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
        
        // 配置返回按钮（恢复原尺寸与边距）
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
    
    /**
     * 创建一个覆盖在右上角的系统级分享按钮
     * 视觉与 `CharacterDetailView` 保持一致
     */
    private func addSystemLevelShareButton() {
        // 计算顶部安全区域高度，为分享按钮定位
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let topPadding = windowScene?.windows.first?.safeAreaInsets.top ?? 44
        let screenWidth = UIScreen.main.bounds.width
        
        // 先移除旧窗口（如果存在）
        systemShareButtonWindow?.isHidden = true
        systemShareButtonWindow = nil
        
        // 创建新窗口 - 只覆盖右上角分享按钮区域
        if let windowScene = windowScene {
            let buttonWindow = UIWindow(windowScene: windowScene)
            buttonWindow.frame = CGRect(
                x: screenWidth - 55,
                y: 0,
                width: 55,
                height: topPadding + 44
            )
            buttonWindow.tag = 9998
            buttonWindow.isUserInteractionEnabled = true
            buttonWindow.windowLevel = .alert + 1
            buttonWindow.backgroundColor = .clear
            
            // 设置根视图控制器
            let viewController = UIViewController()
            viewController.view.backgroundColor = .clear
            buttonWindow.rootViewController = viewController
            
            // 配置分享按钮（与角色详情相同尺寸与字重）
            let shareButton = UIButton(type: .system)
            shareButton.frame = CGRect(x: 16, y: topPadding + 11, width: 26, height: 26)
            let imageConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            let image = UIImage(systemName: "square.and.arrow.up", withConfiguration: imageConfig)
            shareButton.setImage(image, for: .normal)
            // 使用与角色详情一致的紫色
            shareButton.tintColor = UIColor(red: 149/255, green: 138/255, blue: 177/255, alpha: 1.0)
            
            // 点击进入聊天分享模式
            shareButton.addAction(UIAction { _ in
                // 触发轻触反馈
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                enterShareMode()
            }, for: .touchUpInside)
            
            viewController.view.addSubview(shareButton)
            
            systemShareButtonWindow = buttonWindow
            DispatchQueue.main.async {
                buttonWindow.isHidden = false
                buttonWindow.makeKeyAndVisible()
            }
        }
    }
    
    // 移除updateViewOffset方法，使用统一的键盘适配
    
    // 移除calculateTextViewHeight方法，ChatInputBar组件会自动处理
    
            // 移除所有手动键盘监听方法，使用keyboardAdaptive统一管理
    
    // 重置键盘状态（不使用动画）
    private func resetKeyboardAndOffset() {
        // 隐藏键盘，keyboardAdaptive会自动处理状态
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // 激活输入框并弹出键盘的方法
    private func focusInputField() {
        // 设置焦点状态
        withAnimation(.easeInOut(duration: 0.2)) {
            textFieldFocused = true
        }
        
        // 触发键盘显示前先确保输入框获得焦点
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 触发键盘显示
            UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
            
            // 在模拟器中，keyboardAdaptive会自动处理键盘
            #if targetEnvironment(simulator)
            print("ChatView - 模拟器环境，keyboardAdaptive会自动处理")
            #endif
        }
        
        // 键盘将要弹出时，预先滚动一次，确保后续动画更流畅
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.25)) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ScrollToBottom"),
                    object: nil
                )
            }
        }
    }
    
    // 在模拟器中模拟键盘弹出 - 简化版本
    private func simulateKeyboardForSimulator() {
        #if targetEnvironment(simulator)
                    // keyboardAdaptive会自动处理键盘适配，无需手动模拟
        print("ChatView - 模拟器环境，keyboardAdaptive会自动处理键盘")
        #endif
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - 分享功能
    
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
        let selectedMessagesList = messages.filter { selectedMessages.contains($0.id) }
        
        if selectedMessagesList.isEmpty {
            return
        }
        
        // 生成分享卡片
        let shareCards: [UIImage]
        
        if selectedMessagesList.count > 1 {
            // 多条消息：生成合并卡片
            let mergedCardResult = ChatShareCardGenerator.generateMergedCard(
                messages: selectedMessagesList,
                character: character,
                characterThemeColor: characterThemeColor
            )
            shareCards = [mergedCardResult.saveImage]  // 使用保存版（带彩色边框）
        } else {
            // 单条消息：生成单独卡片
            shareCards = selectedMessagesList.map { message in
                let cardResult = ChatShareCardGenerator.generateCard(
                    message: message,
                    character: character,
                    characterThemeColor: characterThemeColor
                )
                return cardResult.saveImage  // 使用保存版（带彩色边框）
            }
        }
        
        if shareCards.isEmpty {
            return
        }
        
        // 保存分享卡片并显示自定义分享模态视图
        self.shareCards = shareCards
        
        // 先退出分享模式，然后显示分享模态视图
        exitShareMode()
        
        // 延迟一点时间再展示分享界面，确保UI状态稳定
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showShareModal = true
        }
    }

/**
 * 消息气泡视图
 */
struct ChatMessageBubbleView: View {
    let message: Message
    let characterThemeColor: Color
    
    @State private var messageStatus: MessageStatus = .delivered
    @State private var isWaitingForReply: Bool = false
    @State private var animationDots = "..."
    @State private var animationTimer: Timer? = nil
    
    var body: some View {
        // 计算气泡状态
        let _ = message.isFromUser
            ? messageStatus
            : .read // 角色的消息总是已读
        
        // 检查是否为等待消息
        let isWaitingMessage = !message.isFromUser && message.content == "..."
        
        Group {
            if message.isFromUser {
                // 用户消息：水平布局（消息气泡在左，头像在右）
                HStack(alignment: .top, spacing: 8) {
                    Spacer()
                    
                    // 用户消息气泡
                    Text(message.content.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.system(size: 15))
                        .lineSpacing(5)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "B8B5FF"),
                                    Color(hex: "C7C4FF")
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .overlay(
                            // 用户消息上部高光，增强视觉层次感
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                                .blendMode(.overlay)
                                .mask(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.white, .clear]),
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                )
                        )
                        .shadow(color: Color(hex: "C7C4FF").opacity(0.25), radius: 4, x: 0, y: 2)
                        .padding(.top, 8)
                    
                    // 用户头像
                    ZStack {
                        // 背景装饰
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        DesignSystem.Colors.background.opacity(0.98),
                                        DesignSystem.Colors.background.opacity(0.90)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                            .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
                        
                        // 用户头像 - 使用统一的Avatar组件和UserProfileManager数据
                        Avatar(
                            url: UserProfileManager.shared.getCurrentAvatarURL(),
                            name: UserProfileManager.shared.getCurrentUsername(),
                            size: 32
                        )
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
                            )
                    }
                    .padding(.top, 4)
                }
            } else {
                // 角色消息：保持原有水平布局
                HStack(alignment: isWaitingMessage ? .center : .top, spacing: 8) {
                    // 角色头像
                    ZStack {
                        // 背景装饰
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        DesignSystem.Colors.background.opacity(0.98),
                                        DesignSystem.Colors.background.opacity(0.90)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                            .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
                        
                        // 角色头像 - 使用Avatar组件
                        Avatar(url: message.senderId, name: "历史人物", size: 32)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
                            )
                    }
                    .padding(.top, isWaitingMessage ? 0 : 4)
                    
                    // 角色消息气泡
                    VStack(alignment: .leading, spacing: 2) {
                        // 消息内容
                        Group {
                            if isWaitingMessage {
                                // 简化的等待动画
                                HStack(spacing: 5) {
                                    ForEach(0..<3) { index in
                                        Circle()
                                            .fill(characterThemeColor)
                                            .frame(width: 5, height: 5)
                                            .scaleEffect(getAnimationScale(for: index))
                                            .animation(
                                                Animation.easeInOut(duration: 0.5)
                                                    .repeatForever()
                                                    .delay(0.15 * Double(index)),
                                                value: animationDots
                                            )
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                            } else {
                                Text(message.content.trimmingCharacters(in: .whitespacesAndNewlines))
                                    .font(.system(size: 15))
                                    .lineSpacing(5)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 8)
                            }
                        }
                        .background(
                            isWaitingMessage
                                ? LinearGradient(
                                    gradient: Gradient(colors: [
                                        characterThemeColor.opacity(0.12),
                                        characterThemeColor.opacity(0.08)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    gradient: Gradient(colors: [
                                        characterThemeColor.opacity(0.16),
                                        characterThemeColor.opacity(0.12)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .foregroundColor(.primary)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: isWaitingMessage ? 14 : 16,
                                style: .continuous
                            )
                        )
                        .overlay(
                            // 历史角色消息添加精致边框
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            characterThemeColor.opacity(0.25),
                                            characterThemeColor.opacity(0.08)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.8
                                )
                        )
                        .shadow(color: characterThemeColor.opacity(0.08), radius: 1.5, x: 0, y: 1)
                    }
                    .padding(.leading, 4)
                    .padding(.top, 8)
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            // 如果是等待消息，启动动画
            if isWaitingMessage {
                startDotAnimation()
            }
        }
        .onDisappear {
            // 停止计时器
            animationTimer?.invalidate()
            animationTimer = nil
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

    // 获取动画缩放值
    private func getAnimationScale(for index: Int) -> CGFloat {
        switch animationDots {
        case ".··":
            return index == 0 ? 1.0 : 0.6
        case "·.·":
            return index == 1 ? 1.0 : 0.6
        case "··.":
            return index == 2 ? 1.0 : 0.6
        default:
            return index == 0 ? 1.0 : 0.6
        }
    }
    
    // 开始点动画
    private func startDotAnimation() {
        // 确保先停止现有计时器
        animationTimer?.invalidate()
        
        // 创建新计时器，每0.6秒更新一次
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                // 更新动画状态
                switch animationDots {
                case ".··": animationDots = "·.·"
                case "·.·": animationDots = "··."
                case "··.": animationDots = ".··"
                default: animationDots = ".··"
                }
            }
        }
        
        // 确保计时器在当前RunLoop中运行
        RunLoop.current.add(animationTimer!, forMode: .common)
        
        // 立即开始动画
        animationDots = ".··"
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

// 定义一个PreferenceKey来传递视图标签
struct ViewTagPreferenceKey: PreferenceKey {
    static var defaultValue: Int = 0
    static func reduce(value: inout Int, nextValue: () -> Int) {
        value = nextValue()
    }
}

/**
 * 聊天视图预览
 */
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // 为预览创建一个公共初始化器
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
}}

/**
 * UIScrollView扩展，用于查找和滚动操作
 */
extension UIScrollView {
    /// 在视图层次结构中查找标记为9999的UIScrollView
    static func findScrollViewInHierarchy() -> UIScrollView? {
        if #available(iOS 15.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                return findScrollView(in: rootViewController.view)
            }
        } else {
            if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                return findScrollView(in: rootViewController.view)
            }
        }
        return nil
    }
    
    /// 递归查找标记为9999的UIScrollView
    private static func findScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView, scrollView.tag == 9999 {
            return scrollView
        }
        
        for subview in view.subviews {
            if let scrollView = findScrollView(in: subview) {
                return scrollView
            }
        }
        
        return nil
    }
    
    /// 滚动到底部
    func scrollToBottom(animated: Bool) {
        // 确保在主线程执行
        DispatchQueue.main.async {
            // 计算底部偏移量，但留出额外空间
            // 这里我们减去一个值（如屏幕高度的30%），让最新消息显示在中间位置而不是底部
            let extraSpace = self.bounds.size.height * 0.3
            let bottomOffset = CGPoint(x: 0, y: max(0, self.contentSize.height - self.bounds.size.height + self.contentInset.bottom + extraSpace))
            
            // 立即滚动到计算的位置
            self.setContentOffset(bottomOffset, animated: animated)
            
            // 双重保险：如果内容尺寸可能还未更新，延迟再次尝试滚动
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // 重新计算偏移量，因为内容尺寸可能已更新
                let updatedOffset = CGPoint(x: 0, y: max(0, self.contentSize.height - self.bounds.size.height + self.contentInset.bottom + extraSpace))
                self.setContentOffset(updatedOffset, animated: false)
            }
        }
    }
}
