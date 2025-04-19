import SwiftUI
import Combine

/**
 * 评论输入视图
 * 处理用户评论输入和提交
 * 支持@虚拟人物功能
 */
struct CommentInputView: View {
    // 评论管理器
    @ObservedObject var commentManager: CommentManager
    
    // 输入框状态
    @FocusState private var isInputFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    @State private var keyboardVisible = false
    @State private var bottomPadding: CGFloat = 0
    
    // @功能状态
    @State private var showMentionPicker = false
    @State private var mentionSearchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 显示正在回复的状态
            if let replyingTo = commentManager.replyingToComment {
                HStack {
                    Text("回复：")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    
                    Text(replyingTo.username)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        commentManager.cancelReply()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.06))
            }
            
            // 输入框和发送按钮 - 优化布局
            HStack(alignment: .center, spacing: 10) {
                // 评论输入框 - 更圆润的设计
                ZStack(alignment: .leading) {
                    if commentManager.commentText.isEmpty && !isInputFocused {
                        Text("跨越时空的对话...")
                            .font(.system(size: 15))
                            .foregroundColor(.gray.opacity(0.7))
                            .padding(.leading, 6)
                    }
                    
                    // 输入框与功能按钮的组合
                    HStack(spacing: 0) {
                        TextField("", text: $commentManager.commentText)
                            .font(.system(size: 15))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .focused($isInputFocused)
                        
                        // 右侧功能区域
                        if isInputFocused {
                            HStack(spacing: 12) {
                                // @按钮
                                Button(action: {
                                    hapticFeedback(style: .light)
                                    withAnimation {
                                        showMentionPicker.toggle()
                                        mentionSearchText = ""
                                    }
                                }) {
                                    Image(systemName: "at")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray.opacity(0.8))
                                }
                                
                                // 表情按钮
                                Button(action: {
                                    // 暂时保留原功能，但调整样式
                                    hapticFeedback(style: .light)
                                }) {
                                    Image(systemName: "face.smiling")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray.opacity(0.8))
                                }
                            }
                            .padding(.trailing, 12)
                        }
                    }
                }
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 22) // 更圆润的边角
                        .fill(Color(.systemGray6).opacity(isInputFocused ? 1.0 : 0.6))
                )
                .onTapGesture {
                    isInputFocused = true
                }
                
                // 发送按钮 - 仅在有内容且输入框聚焦时显示
                if !commentManager.commentText.isEmpty && isInputFocused {
                    Button(action: {
                        if !commentManager.commentText.isEmpty {
                            commentManager.submitComment()
                            // 提交后取消焦点
                            isInputFocused = false
                            
                            // 处理@提及并触发虚拟角色回复
                            Task {
                                // 提交后延迟一小段时间再触发虚拟回复，模拟更真实的交互
                                try? await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
                                await commentManager.generateVirtualReply()
                            }
                        }
                    }) {
                        Text("发送")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12) // 调整高度与输入框一致
                            .background(Color.blue) // 使用更柔和的蓝色
                            .cornerRadius(22) // 统一圆角
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .animation(.easeInOut(duration: 0.15), value: commentManager.commentText)
            .animation(.easeInOut(duration: 0.15), value: isInputFocused)
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.gray.opacity(0.15))
                    .offset(y: -0.5),
                alignment: .top
            )
            
            // @人物选择器 - 只在显示时展示
            if showMentionPicker {
                VStack(spacing: 0) {
                    // 搜索区域
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        TextField("搜索历史人物", text: $mentionSearchText)
                            .font(.system(size: 14))
                        
                        if !mentionSearchText.isEmpty {
                            Button(action: { mentionSearchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(16) // 更圆润的边角
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // 人物列表
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredCharacters(), id: \.id) { character in
                                Button(action: {
                                    // 添加@提及
                                    insertMention(character)
                                    withAnimation {
                                        showMentionPicker = false
                                    }
                                    isInputFocused = true
                                }) {
                                    HStack(alignment: .center, spacing: 12) {
                                        // 头像
                                        Circle()
                                            .fill(character.color.opacity(0.2))
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Text(String(character.name.prefix(1)))
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(character.color)
                                            )
                                        
                                        // 名称和类别
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(character.name)
                                                .font(.system(size: 14, weight: .medium))
                                            
                                            Text(character.category)
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if character.id != filteredCharacters().last?.id {
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        }
                    }
                    .frame(height: min(CGFloat(filteredCharacters().count) * 48, 220))
                    .padding(.top, 8)
                }
                .background(Color(.systemBackground))
                .cornerRadius(16) // 更圆润的边角
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .keyboardAdaptive(
            enabled: true, 
            adjustLayout: false, 
            dismissOnTap: true
        ) // 使用增强版KeyboardAdaptive，不调整布局但启用点击关闭功能
        .onReceive(Publishers.keyboardHeight) { height in
            keyboardVisible = height > 0
            keyboardHeight = height
        }
        .animation(.easeInOut(duration: 0.2), value: showMentionPicker)
        // 保留对外部点击的处理
        .onAppear {
            // 添加对外部点击的处理
            NotificationCenter.default.addObserver(
                forName: UITapGestureRecognizer.dismissKeyboardNotification,
                object: nil,
                queue: .main
            ) { _ in
                self.isInputFocused = false
            }
        }
        .onDisappear {
            // 移除外部点击观察者
            NotificationCenter.default.removeObserver(
                self,
                name: UITapGestureRecognizer.dismissKeyboardNotification,
                object: nil
            )
        }
    }
    
    // @虚拟人物相关方法
    
    // 过滤角色列表
    private func filteredCharacters() -> [CommentCharacter] {
        if mentionSearchText.isEmpty {
            return characters
        } else {
            return characters.filter {
                $0.name.lowercased().contains(mentionSearchText.lowercased()) ||
                $0.category.lowercased().contains(mentionSearchText.lowercased())
            }
        }
    }
    
    // 插入@提及
    private func insertMention(_ character: CommentCharacter) {
        // 如果评论框为空，直接添加@用户名，否则添加空格+@用户名
        if commentManager.commentText.isEmpty {
            commentManager.commentText = "@\(character.name) "
        } else if commentManager.commentText.last == " " {
            commentManager.commentText += "@\(character.name) "
        } else {
            commentManager.commentText += " @\(character.name) "
        }
        
        // 触发触感反馈
        hapticFeedback(style: .medium)
    }
    
    // 检查输入文本是否包含@提及
    private func containsMention(_ text: String) -> Bool {
        let pattern = "@([\\p{L}\\s]+)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = text as NSString
        let matches = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        return !matches.isEmpty
    }
    
    // 触感反馈
    private func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    // 虚拟人物数据
    private let characters = [
        CommentCharacter(id: "einstein", name: "爱因斯坦", category: "科学家", color: .blue),
        CommentCharacter(id: "shakespeare", name: "莎士比亚", category: "文学家", color: .purple),
        CommentCharacter(id: "davinci", name: "达芬奇", category: "艺术家", color: .green),
        CommentCharacter(id: "confucius", name: "孔子", category: "哲学家", color: .orange),
        CommentCharacter(id: "curie", name: "居里夫人", category: "科学家", color: .indigo),
        CommentCharacter(id: "newton", name: "牛顿", category: "科学家", color: .blue),
        CommentCharacter(id: "socrates", name: "苏格拉底", category: "哲学家", color: .teal),
        CommentCharacter(id: "mozart", name: "莫扎特", category: "音乐家", color: .pink),
        CommentCharacter(id: "libai", name: "李白", category: "诗人", color: .orange)
    ]
    
    // 评论角色结构体 - 改名避免与CharacterModel冲突
    struct CommentCharacter: Identifiable {
        let id: String
        let name: String
        let category: String
        let color: Color
    }
}

// 预览
struct CommentInputView_Previews: PreviewProvider {
    static var previews: some View {
        let commentManager = CommentManager(post: ModelData.samplePosts[0])
        
        CommentInputView(commentManager: commentManager)
            .previewLayout(.sizeThatFits)
    }
}

// 扩展UITapGestureRecognizer以添加关闭键盘的通知名
extension UITapGestureRecognizer {
    static let dismissKeyboardNotification = Notification.Name("dismissKeyboardNotification")
}

// 扩展View以添加点击空白处关闭键盘的修饰符
extension View {
    /**
     * 添加点击空白处关闭键盘的功能
     * - Parameters:
     *   - notifyObservers: 是否在关闭键盘后发送通知，默认为true
     *   - hapticFeedback: 是否在点击时产生触感反馈，默认为false
     *   - feedbackStyle: 触感反馈的强度，默认为light
     * - Returns: 应用了点击关闭键盘功能的视图
     */
    func dismissKeyboardOnTap(
        notifyObservers: Bool = true,
        hapticFeedback: Bool = false,
        feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light
    ) -> some View {
        return self.onTapGesture {
            // 关闭键盘
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            
            // 发送通知
            if notifyObservers {
                NotificationCenter.default.post(name: UITapGestureRecognizer.dismissKeyboardNotification, object: nil)
            }
            
            // 触感反馈
            if hapticFeedback {
                let generator = UIImpactFeedbackGenerator(style: feedbackStyle)
                generator.impactOccurred()
            }
        }
    }
} 