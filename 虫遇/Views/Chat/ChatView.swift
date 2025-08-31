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
    @State private var keyboardHeight: CGFloat = 0
    @State private var keyboardVisible = false
    @State private var bottomPadding: CGFloat = 0
    @State private var viewOffset: CGFloat = 0 // 添加视图偏移量
    @State private var isExpanded: Bool = false // 控制是否展开全屏模式
    @State private var textViewHeight: CGFloat = 36 // 默认高度
    @State private var lastText = "" // 用于检测文本变化
    
    // 添加用于API请求的取消令牌集合
    private var cancellables = Set<AnyCancellable>()
    
    // 虚拟角色服务
    private let virtualCharacterService = VirtualCharacterService.shared
    
    // TabBar管理器
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
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
                                
                                // 消息列表区域
                                LazyVStack(spacing: 12) {  // 减小消息间距从16到12，让对话更紧凑
                                    // 消息气泡
                                    ForEach(messages, id: \.id) { message in
                                        ChatMessageBubbleView(message: message, characterThemeColor: characterThemeColor)
                                            .id(message.id)
                                    }
                                    
                                    // 底部占位区域 - 增加高度确保内容能滚动到底部安全区以上
                                    // 增加更多空间，确保键盘弹出时消息不被遮挡
                                    Color.clear
                                        .frame(height: keyboardVisible ? 300 : 180)
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
                                .padding(.bottom, keyboardVisible ? 100 : 30)
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
                        // 监听键盘状态变化
                        .onChangeCompat(of: keyboardVisible) { _, newValue in
                            if newValue && !messages.isEmpty {
                                // 键盘弹出时，确保消息可见
                                // 使用更短的延迟，提高响应速度
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    // 只有在初始化完成后才使用动画滚动
                                    if hasInitialized {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            scrollView.scrollTo("bottomId", anchor: .center)
                                        }
                                    } else {
                                        // 初始加载时直接滚动，不使用动画
                                        scrollView.scrollTo("bottomId", anchor: .center)
                                    }
                                }
                            }
                        }
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
                
                // 底部输入区域
                ZStack(alignment: .bottom) {
                    // 键盘显示时的点击层已移除，使用系统键盘处理
                    
                    // 非展开模式 - 底部输入框
                VStack(spacing: 0) {
                        // 分隔线
                    Rectangle()
                            .fill(Color.gray.opacity(0.12))  // 减小不透明度从0.2到0.12
                            .frame(height: 0.3)  // 减小高度从0.5到0.3
                        
                        // 输入框和发送按钮
                        HStack(alignment: .bottom, spacing: 10) {
                            // 录音按钮已删除
                            
                            // 评论输入框
                            ZStack(alignment: .leading) {
                                if messageText.isEmpty && !textFieldFocused {
                                    Text("跨越时空的对话...")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.gray.opacity(0.7))
                                        .padding(.leading, 14)
                                        .padding(.top, 5)
                                        .zIndex(1)
                                }
                                
                                AutoSizingTextView(text: $messageText, isFocused: $textFieldFocused, heightChanged: { height in
                                    // 使用动画平滑过渡高度变化
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        // 限制最大高度为100
                                        textViewHeight = min(height, 100)
                                    }
                                })
                                .frame(height: textViewHeight)
                                .padding(.horizontal, 14)
                                .padding(.vertical, textFieldFocused ? 6 : 2)
                                .disabled(false)
                                .opacity(1)
                            }
                            .frame(minHeight: textFieldFocused ? 44 : 34)  // 减小输入框高度从46/36到44/34，更紧凑
                            .background(
                                RoundedRectangle(cornerRadius: 18)  // 减小圆角从20到18，更符合iOS标准
                                    .fill(Color(UIColor.systemGray6))
                                    .opacity(0.9)
                            )
                            .animation(.easeInOut(duration: 0.2), value: textFieldFocused) // 添加动画
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if !textFieldFocused {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        textFieldFocused = true
                                    }
                                }
                                
                                // 立即滚动到底部，确保用户能看到最新内容
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    // 自定义通知，指定使用center锚点
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("ScrollToBottom"),
                                        object: nil,
                                        userInfo: ["anchorPoint": "center"]
                                    )
                                }
                                
                                // 如果有文字，立即根据文字内容调整高度
                                if !messageText.isEmpty {
                                    calculateTextViewHeight(messageText)
                                }
                                
                                // 延迟触发键盘显示，确保状态已更新
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    // 触发键盘显示
                                    UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                                    
                                    // 键盘弹出后再次滚动，确保消息不被遮挡
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            // 自定义通知，指定使用center锚点
                                            NotificationCenter.default.post(
                                                name: NSNotification.Name("ScrollToBottom"),
                                                object: nil,
                                                userInfo: ["anchorPoint": "center"]
                                            )
                                        }
                                    }
                                }
                            }
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
                            .frame(maxWidth: .infinity)
                            
                            // 发送按钮
                            Button(action: sendMessage) {
                                Text("发送")
                                    .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                        .padding(.horizontal, 14)  // 减小水平内边距从16到14
                        .padding(.vertical, 10)
                .background(
                                        RoundedRectangle(cornerRadius: 16)  // 减小圆角从18到16
                                            .fill(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : characterThemeColor)
                                            .shadow(color: characterThemeColor.opacity(0.2), radius: 3, x: 0, y: 1)
                                    )
                            }
                            .disabled(messageText.isEmpty)
                            .transition(.scale.combined(with: .opacity))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        // 添加半透明背景，保持专业外观
                            .background(
                            Color(.systemBackground).opacity(0.9)
                                    )
                        // 修改分隔线使其更加明显
                                    .overlay(
                            Rectangle()
                                .frame(height: 0.5)  // 减小高度从0.8到0.5
                                .foregroundColor(Color.gray.opacity(0.15))  // 减小不透明度从0.3到0.15
                                .offset(y: -0.5),
                            alignment: .top
                        )
                    }
                    // 添加键盘避让 - 使视图随键盘上移
                    .offset(y: viewOffset)
                    // 移除阴影效果
                    .animation(.easeInOut(duration: 0.25), value: viewOffset) // 添加键盘弹出动画
                    .zIndex(10) // 确保显示在最顶层
                }
                // 添加轻微阴影效果，增强层次感
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: -1)
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
                                        characterThemeColor.opacity(0.10),  // 减小不透明度从0.15到0.10
                                        characterThemeColor.opacity(0.03)   // 减小不透明度从0.05到0.03
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 0.3)  // 减小高度从0.5到0.3
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
        .keyboardAdaptive(enabled: true, dismissOnTap: true) // 添加键盘自适应
        // 不在这里监听键盘通知，而是在onAppear中设置
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
                
                // 设置键盘通知
                setupKeyboardNotifications()
                
                // 确保从其他页面进入时输入框高度为默认值
                textViewHeight = 36
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
            
            // 移除键盘通知
            removeKeyboardNotifications()
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
                    viewOffset = 0
                    keyboardVisible = false
                    keyboardHeight = 0
                    
                    // 重置输入框高度为初始状态
                    textViewHeight = 36
                    
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
            // 如果输入框处于激活状态，根据文本内容调整高度
            if textFieldFocused && oldValue != newValue {
                calculateTextViewHeight(newValue)
            }
        }
        .onChange(of: viewOffset) { oldValue, newValue in
            // 移除重复的动画，因为父视图已经添加了动画
            viewOffset = newValue
        }
        .onChange(of: keyboardHeight) { oldValue, newValue in
            // 移除重复的动画，因为父视图已经添加了动画
            keyboardHeight = newValue
        }
        .onChange(of: textViewHeight) { oldValue, newHeight in
            // 保留动画但简化代码
            textViewHeight = min(newHeight, 100)
        }
    }
    
    /**
     * 发送消息
     */
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let content = messageText
        
        // 添加详细日志
        print("\n📱 ===== 用户发送消息 =====")
        print("📤 消息内容: \"\(content)\"")
        print("🗣️ 发送给角色: \(character.name) (ID: \(character.id))")
        print("🔄 会话ID: \(conversationId)")
        print("📱 ===== 消息详情结束 =====\n")
        
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
        textViewHeight = 36 // 重置输入框高度
        
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
        // 修改为保留最近3轮对话（最多6条消息）
        let recentMessages = messages.suffix(6) // 最近6条消息，相当于3轮对话
        
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
        
        // 添加详细日志
        print("\n🔄 ===== 构建对话上下文 =====")
        print("📜 最近消息数量: \(recentMessages.count)")
        print("📝 对话上下文内容:")
        print(context)
        print("🔄 ===== 上下文构建结束 =====\n")
        
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
                        print("📱 没有找到历史消息记录")
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
    
    // 更新视图偏移量以避开键盘（添加动画）
    private func updateViewOffset() {
        if keyboardVisible {
            // 计算需要上移的距离，使输入框刚好在键盘上方
            // 微信风格：将输入框移动到键盘上方，并额外增加一些空间
            let baseOffset = -(keyboardHeight + 20) // 增加额外的20点偏移，让消息有更多显示空间
            
            // 设置最终的偏移量
            viewOffset = baseOffset
            
            // 使用单次滚动通知，在视图偏移后立即执行
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ScrollToBottom"),
                        object: nil
                    )
                }
            }
        } else {
            viewOffset = 0
        }
    }
    
    // 添加一个计算文本高度的辅助方法
    private func calculateTextViewHeight(_ text: String) {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 15)
        textView.frame.size.width = UIScreen.main.bounds.width - 80 // 估算宽度
        textView.text = text
        
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let minHeight: CGFloat = 36 // 最小高度
        let maxHeight: CGFloat = isExpanded ? 200 : 100 // 根据是否展开设置最大高度
        
        // 使用动画更新高度，并限制最大高度
        withAnimation(.easeInOut(duration: 0.2)) {
            textViewHeight = min(max(minHeight, newSize.height), maxHeight)
        }
    }
    
    // 键盘通知处理方法 - 结构体版本
    private func setupKeyboardNotifications() {
        // 移除之前可能存在的观察者
        removeKeyboardNotifications()
        
        // 监听键盘显示通知
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            self.keyboardWillShow(notification)
        }
        
        // 监听键盘隐藏通知
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { notification in
            self.keyboardWillHide(notification)
        }
    }
    
    // 由于结构体不支持@objc，改为普通方法
    private func keyboardWillShow(_ notification: Notification) {
        handleKeyboardNotification(notification, isShowing: true)
    }
    
    private func keyboardWillHide(_ notification: Notification) {
        handleKeyboardNotification(notification, isShowing: false)
    }
    
    private func removeKeyboardNotifications() {
        // 移除所有键盘相关通知
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )
        
        // 移除滚动通知
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("ScrollCommentToBottom"),
            object: nil
        )
    }
    
    // 处理键盘显示和隐藏的通知
    private func handleKeyboardNotification(_ notification: Notification, isShowing: Bool) {
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
                    self.keyboardHeight = keyboardFrame.height
                    self.keyboardVisible = true
                    
                    // 调整底部内边距，避免被键盘遮挡
                    self.bottomPadding = keyboardFrame.height
                    
                    // 更新视图偏移量以避免键盘遮挡
                    self.updateViewOffset()
                }
                
                // 创建与键盘完全相同的动画参数
                let animator = UIViewPropertyAnimator(
                    duration: duration,
                    curve: UIView.AnimationCurve(rawValue: Int(animationCurve)) ?? .easeInOut
                )
                
                // 添加滚动动画，与键盘弹出完全同步
                animator.addAnimations {
                    // 发送滚动通知
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ScrollToBottom"),
                        object: nil
                    )
                }
                
                // 启动动画
                animator.startAnimation()
                
                // 设置进度监听，中途时再次滚动以确保流畅
                DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.5) {
                    withAnimation(.easeInOut(duration: duration * 0.5)) {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ScrollToBottom"),
                            object: nil
                        )
                    }
                }
                
                // 键盘完全弹出后再次确认滚动位置
                DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.05) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ScrollToBottom"),
                            object: nil
                        )
                    }
                }
            }
        } else {
            // 键盘隐藏
            // 获取动画持续时间
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
            
            // 获取动画曲线
            let animationCurve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 7
            let animationOptions = UIView.AnimationOptions(rawValue: animationCurve << 16)
            
            // 使用系统提供的动画参数
            UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, animationOptions]) {
                self.keyboardHeight = 0
                self.keyboardVisible = false
                self.bottomPadding = 0
                self.viewOffset = 0
            }
        }
    }
    
    // 重置键盘和视图偏移（不使用动画）
    private func resetKeyboardAndOffset() {
        // 隐藏键盘
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // 直接重置所有状态，不使用动画
        viewOffset = 0
        keyboardVisible = false
        keyboardHeight = 0
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
            
            // 在模拟器中，可能需要手动触发键盘
            #if targetEnvironment(simulator)
            if !self.keyboardVisible {
                self.simulateKeyboardForSimulator()
            }
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
    
    // 在模拟器中模拟键盘弹出
    private func simulateKeyboardForSimulator() {
        #if targetEnvironment(simulator)
        // 在模拟器中，可能需要手动模拟键盘高度
        if keyboardHeight == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // 固定模拟键盘高度，不受文本内容影响
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.keyboardHeight = 280 // 减小模拟键盘高度
                    self.keyboardVisible = true
                    self.updateViewOffset()
                }
            }
        }
        #endif
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
        let status = message.isFromUser
            ? messageStatus
            : .read // 角色的消息总是已读
        
        // 检查是否为等待消息
        let isWaitingMessage = !message.isFromUser && message.content == "..."
        
        HStack(alignment: isWaitingMessage ? .center : .top, spacing: 8) {
            // 角色头像（仅在角色消息时显示）
            if !message.isFromUser {
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
                        .frame(width: 36, height: 36)  // 减小头像尺寸从38到36，更符合iOS标准
                        .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)  // 减弱阴影不透明度从0.08到0.06
                    
                    // 角色头像 - 使用Avatar组件
                    Avatar(url: message.senderId, name: "历史人物", size: 32)  // 减小头像尺寸从34到32
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.8), lineWidth: 1)
                        )
                }
                .padding(.top, isWaitingMessage ? 0 : 4) // 等待消息时不需要顶部间距
            } else {
                Spacer()
            }
            
            // 消息气泡
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 2) {
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
                Text(message.content)
                    .font(.system(size: 15))
                    .lineSpacing(5) // 增加行间距改善阅读体验
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)  // 减小垂直内边距从10到8，让气泡更紧凑
                    }
                }
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
                        : isWaitingMessage
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
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .clipShape(
                        RoundedRectangle(
                        cornerRadius: message.isFromUser ? 18 : (isWaitingMessage ? 14 : 16),
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
                                                characterThemeColor.opacity(0.25),  // 增加不透明度从0.2到0.25，提高边框可见度
                                                characterThemeColor.opacity(0.08)   // 增加不透明度从0.05到0.08
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
                if !isWaitingMessage {
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
                        .font(.system(size: 10, weight: .light))  // 增加字体大小从9到10，提高可读性
                        .kerning(0.3)
                        .foregroundColor(.secondary.opacity(0.8))  // 增加不透明度从0.7到0.8，提高对比度
                }
                .padding(.horizontal, 4) // 减小水平内边距
                .padding(.vertical, 1) // 减小垂直内边距
                }
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
                        .frame(width: 36, height: 36)  // 减小头像尺寸从38到36，更符合iOS标准
                        .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)  // 减弱阴影不透明度从0.08到0.06
                    
                    // 用户头像
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundColor(Color.blue.opacity(0.7))
                        .frame(width: 32, height: 32)  // 减小头像尺寸从34到32
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
}

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