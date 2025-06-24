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
    @State private var isExpanded: Bool = false // 新增：控制是否展开全屏模式
    
    // @功能状态
    @State private var showMentionPicker = false
    @State private var mentionSearchText = ""
    
    var body: some View {
        ZStack {
            if isExpanded {
                // 全屏评论编辑模式
                VStack(spacing: 0) {
                    // 顶部导航栏
                    HStack {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = false
                                isInputFocused = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .padding(.leading)
                        
                        Spacer()
                        
                        Text("添加评论")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            if !commentManager.commentText.isEmpty {
                                submitComment()
                            }
                        }) {
                            Text("发送")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(commentManager.commentText.isEmpty ? .gray : .blue)
                        }
                        .disabled(commentManager.commentText.isEmpty)
                        .padding(.trailing)
                    }
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .overlay(
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundColor(Color.gray.opacity(0.3)),
                        alignment: .bottom
                    )
                    
                    // 如果有回复对象，显示回复信息
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
                    
                    // 评论输入区域
                    ZStack(alignment: .topLeading) {
                        if commentManager.commentText.isEmpty {
                            Text("跨越时空的对话...")
                                .foregroundColor(.gray.opacity(0.7))
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                        }
                        
                        TextEditor(text: $commentManager.commentText)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 100)
                            .focused($isInputFocused)
                            .background(Color(.systemBackground))
                    }
                    .background(Color(.systemBackground))
                    
                    // @人物选择器
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
                            .cornerRadius(16)
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
                                            characterRow(character)
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
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // 底部工具栏
                    HStack(spacing: 16) {
                        // @按钮
                        Button(action: {
                            hapticFeedback(style: .light)
                            withAnimation {
                                showMentionPicker.toggle()
                                mentionSearchText = ""
                            }
                        }) {
                            Image(systemName: "at")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // 字数提示
                        if !commentManager.commentText.isEmpty {
                            Text("\(commentManager.commentText.count)/200")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    
                    Spacer()
                }
                .background(Color(.systemBackground))
                .edgesIgnoringSafeArea(.bottom)
                .onTapGesture {
                    // 点击背景关闭@选择器
                    if showMentionPicker {
                        showMentionPicker = false
                    }
                }
            } else {
                // 非展开模式 - 底部输入框
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
                    
                    // 输入框和发送按钮
                    HStack(alignment: .center, spacing: 10) {
                        // 评论输入框
                        ZStack(alignment: .leading) {
                            if commentManager.commentText.isEmpty && !isInputFocused {
                                Text("跨越时空的对话...")
                                    .font(.system(size: 15))
                                    .foregroundColor(.gray.opacity(0.7))
                                    .padding(.leading, 6)
                            }
                            
                            TextField("", text: $commentManager.commentText)
                                .font(.system(size: 15))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .focused($isInputFocused)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isExpanded = true
                                        isInputFocused = true
                                    }
                                }
                        }
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color(.systemGray6).opacity(isInputFocused ? 1.0 : 0.6))
                        )
                        
                        // 发送按钮
                        if !commentManager.commentText.isEmpty && isInputFocused {
                            Button(action: {
                                if !commentManager.commentText.isEmpty {
                                    submitComment()
                                }
                            }) {
                                Text("发送")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .cornerRadius(22)
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
                }
            }
        }
        .onChange(of: isInputFocused) { oldValue, newValue in
            if !newValue && isExpanded {
                // 如果失去焦点且处于展开状态，可能需要延迟关闭
                // 这里可以添加一些逻辑来决定是否关闭展开状态
            }
        }
    }
    
    // 提交评论并重置状态
    private func submitComment() {
        commentManager.submitComment()
        
        // 提交后清空输入框并关闭键盘
        withAnimation(.easeInOut(duration: 0.2)) {
            isExpanded = false
            isInputFocused = false
        }
        
        // 为确保评论显示，延迟关闭评论输入框
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // 强制更新评论列表
            commentManager.updateCommentLists()
            
            // 在主线程生成虚拟角色回复
            Task {
                await commentManager.generateVirtualReply()
            }
        }
    }
    
    // 角色行视图
    private func characterRow(_ character: CommentCharacter) -> some View {
        HStack(alignment: .center, spacing: 12) {
            // 头像
            Circle()
                .fill(character.category.color.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(character.name.prefix(1)))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(character.category.color)
                )
            
            // 名称和类别
            VStack(alignment: .leading, spacing: 2) {
                Text(character.name)
                    .font(.system(size: 14, weight: .medium))
                
                Text(character.category.displayName)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    // @虚拟人物相关方法
    
    // 过滤角色列表
    private func filteredCharacters() -> [CommentCharacter] {
        if mentionSearchText.isEmpty {
            return characters
        } else {
            return characters.filter {
                $0.name.lowercased().contains(mentionSearchText.lowercased()) ||
                $0.category.displayName.lowercased().contains(mentionSearchText.lowercased())
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
    
    // 评论角色结构体 - 改名避免与CharacterModel冲突
    struct CommentCharacter: Identifiable {
        let id: String
        let name: String
        let category: CharacterCategory
        
        init(id: String, name: String, category: CharacterCategory) {
            self.id = id
            self.name = name
            self.category = category
        }
    }
    
    // 虚拟人物数据
    private let characters = [
        CommentCharacter(id: "einstein", name: "爱因斯坦", category: .scientist),
        CommentCharacter(id: "shakespeare", name: "莎士比亚", category: .writer),
        CommentCharacter(id: "davinci", name: "达芬奇", category: .artist),
        CommentCharacter(id: "confucius", name: "孔子", category: .philosopher),
        CommentCharacter(id: "curie", name: "居里夫人", category: .scientist),
        CommentCharacter(id: "newton", name: "牛顿", category: .scientist),
        CommentCharacter(id: "socrates", name: "苏格拉底", category: .philosopher),
        CommentCharacter(id: "mozart", name: "莫扎特", category: .writer),
        CommentCharacter(id: "libai", name: "李白", category: .writer)
    ]
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