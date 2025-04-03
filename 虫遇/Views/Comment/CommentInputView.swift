import SwiftUI

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
                            
                            // 只在不是回复时处理@提及
                            if commentManager.replyingToComment == nil && containsMention(commentManager.commentText) {
                                processMentions(commentManager.commentText)
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
        .onAppear {
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
        .animation(.easeInOut(duration: 0.2), value: showMentionPicker)
    }
    
    // 设置键盘观察器
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                self.keyboardHeight = keyboardFrame.height
                
                // 当键盘出现时，确保动画平滑
                withAnimation(.easeOut(duration: 0.25)) {
                    // 可以在这里添加额外的显示逻辑，如自动滚动到评论区底部等
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeOut(duration: 0.2)) {
                self.keyboardHeight = 0
            }
        }
        
        // 添加对外部点击的处理
        NotificationCenter.default.addObserver(
            forName: UITapGestureRecognizer.dismissKeyboardNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isInputFocused = false
        }
    }
    
    // 移除键盘观察器
    private func removeKeyboardObservers() {
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
    }
    
    // @虚拟人物相关方法
    
    // 过滤角色列表
    private func filteredCharacters() -> [Character] {
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
    private func insertMention(_ character: Character) {
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
    
    // 判断是否包含@提及
    private func containsMention(_ text: String) -> Bool {
        let pattern = "@([\\p{L}\\s]+)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = text as NSString
        let matches = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        return !matches.isEmpty
    }
    
    // 处理@提及
    private func processMentions(_ text: String) {
        let mentionedCharacters = extractMentions(from: text)
        
        for characterID in mentionedCharacters {
            // 延迟生成虚拟角色回复
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1...2)) {
                // 生成回复
                generateVirtualReply(for: characterID)
            }
        }
    }
    
    // 提取@提及的虚拟人物ID
    private func extractMentions(from text: String) -> [String] {
        let pattern = "@([\\p{L}\\s]+)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = text as NSString
        let matches = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        var result = [String]()
        let nameToID = [
            "爱因斯坦": "einstein",
            "莎士比亚": "shakespeare",
            "达芬奇": "davinci",
            "孔子": "confucius",
            "居里夫人": "curie",
            "牛顿": "newton",
            "苏格拉底": "socrates",
            "莫扎特": "mozart",
            "李白": "libai"
        ]
        
        for match in matches {
            let nameRange = match.range(at: 1)
            if nameRange.location != NSNotFound {
                let name = nsString.substring(with: nameRange).trimmingCharacters(in: .whitespaces)
                if let id = nameToID[name] {
                    result.append(id)
                }
            }
        }
        
        return result
    }
    
    // 生成虚拟角色回复
    private func generateVirtualReply(for characterID: String) {
        // 根据角色生成回复内容
        let replyContent = getCharacterReply(for: characterID)
        
        // 获取被回复评论的ID（如果有）
        let parentId = commentManager.replyingToComment?.id
        let replyToUsername = commentManager.replyingToComment?.username
        
        // 添加虚拟角色回复
        commentManager.currentPost.addComment(
            username: getCharacterName(for: characterID),
            userAvatar: "avatar_\(characterID)",
            content: replyContent,
            parentCommentId: parentId,
            replyToUsername: replyToUsername,
            isVirtualCharacter: true,
            characterID: characterID
        )
        
        // 更新评论列表
        commentManager.updateCommentLists()
    }
    
    // 获取角色回复内容
    private func getCharacterReply(for characterID: String) -> String {
        // 根据不同角色返回不同的回复内容
        switch characterID {
        case "einstein":
            return "从相对论的角度看，你的观点有着有趣的物理意义。时间和空间在高速运动或强引力场中的表现，会让我们对宇宙有全新的理解。"
        case "shakespeare":
            return "正如我在作品中所探索的，人性的复杂性往往超出我们的想象。这让我想起了《哈姆雷特》中的一句话：'世上有千百事，是你们学问里所没有的。'"
        case "davinci":
            return "艺术与科学的统一是我毕生追求的。你的想法让我想到，真正的创新往往来自不同领域知识的融合与碰撞。"
        case "confucius":
            return "子曰：'学而时习之，不亦说乎？'你的思考很有深度，让我想起了学习与实践相结合的重要性。"
        case "libai":
            return "人生如梦，一尊还酹江月。你的感悟颇有诗意，不妨举杯邀明月，对影成三人。"
        default:
            return "你的观点很有见地，让我从不同角度思考了这个问题。"
        }
    }
    
    // 获取角色名称
    private func getCharacterName(for characterID: String) -> String {
        switch characterID {
        case "einstein": return "爱因斯坦"
        case "shakespeare": return "莎士比亚"
        case "davinci": return "达芬奇"
        case "confucius": return "孔子"
        case "curie": return "居里夫人"
        case "newton": return "牛顿"
        case "socrates": return "苏格拉底"
        case "mozart": return "莫扎特"
        case "libai": return "李白"
        default: return "历史人物"
        }
    }
    
    // 触感反馈
    private func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    // 虚拟人物数据
    private let characters = [
        Character(id: "einstein", name: "爱因斯坦", category: "科学家", color: .blue),
        Character(id: "shakespeare", name: "莎士比亚", category: "文学家", color: .purple),
        Character(id: "davinci", name: "达芬奇", category: "艺术家", color: .green),
        Character(id: "confucius", name: "孔子", category: "哲学家", color: .orange),
        Character(id: "curie", name: "居里夫人", category: "科学家", color: .indigo),
        Character(id: "newton", name: "牛顿", category: "科学家", color: .blue),
        Character(id: "socrates", name: "苏格拉底", category: "哲学家", color: .teal),
        Character(id: "mozart", name: "莫扎特", category: "音乐家", color: .pink),
        Character(id: "libai", name: "李白", category: "诗人", color: .orange)
    ]
    
    struct Character: Identifiable {
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
    func dismissKeyboardOnTap() -> some View {
        return self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            NotificationCenter.default.post(name: UITapGestureRecognizer.dismissKeyboardNotification, object: nil)
        }
    }
} 