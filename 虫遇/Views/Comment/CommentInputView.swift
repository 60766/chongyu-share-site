import SwiftUI
import Combine
import UIKit

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
    @State private var textFieldFocused: Bool = false  // 新增：用于绑定到AutoSizingTextView
    @State private var keyboardHeight: CGFloat = 0
    @State private var keyboardVisible = false
    @State private var bottomPadding: CGFloat = 0
    @State private var viewOffset: CGFloat = 0 // 添加视图偏移量
    @State private var isExpanded: Bool = false // 控制是否展开全屏模式
    @State private var textViewHeight: CGFloat = 36 // 默认高度从38减小到36
    @State private var lastText = "" // 用于检测文本变化
    @State private var dragOffset: CGFloat = 0 // 添加拖动偏移量
    @State private var isDragging: Bool = false // 添加拖动状态
    
    // @功能状态
    @State private var showMentionPicker = false
    @State private var mentionSearchText = ""
    
    var body: some View {
        // 使用ZStack替代Group，并将内容限制在底部
        ZStack(alignment: .bottom) {
            // 键盘显示时添加透明点击层，放在最底层
            if keyboardVisible || textFieldFocused {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // 先设置状态变量，再一次性执行所有状态重置
                        textFieldFocused = false
                        isExpanded = false
                        
                        // 重置输入框高度
                        textViewHeight = 36
                        
                        // 立即隐藏键盘
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                        // 直接重置所有状态，不使用动画
                        viewOffset = 0
                        keyboardVisible = false
                        keyboardHeight = 0
                    }
                    .edgesIgnoringSafeArea(.all)
                    .zIndex(1) // 确保在最底层
            }
            
            if isExpanded {
                // 全屏评论编辑模式
                ZStack {
                    // 添加完全透明背景蒙层，点击时关闭输入框
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            // 直接重置所有状态，不使用动画
                            isExpanded = false
                            textFieldFocused = false
                            viewOffset = 0
                            keyboardVisible = false
                            keyboardHeight = 0
                            
                            // 立即隐藏键盘
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    
                    VStack(spacing: 0) {
                        // 顶部导航栏
                        HStack {
                            Button(action: {
                                // 添加平滑动画关闭
                                withAnimation(.easeOut(duration: 0.25)) {
                                    isExpanded = false
                                    textFieldFocused = false
                                    resetKeyboardAndOffset()
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            .padding(.leading)
                            
                            Spacer()
                            
                            Text("添加评论")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: {
                                if !commentManager.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    submitComment()
                                }
                            }) {
                                Text("发送")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.blue)
                                    )
                            }
                            .disabled(commentManager.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .padding(.trailing)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 0)  // 完全移除垂直内边距，让标题紧贴顶部
                        .padding(.top, getSafeAreaTop())
                        .background(
                            // 背景 - 统一样式
                            Rectangle()
                                .fill(Color(.systemBackground))
                                .edgesIgnoringSafeArea(.top)
                        )
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
                            .background(
                                BlurView(style: .systemThinMaterial)
                                    .opacity(0.95)
                                    .overlay(Color.gray.opacity(0.05))
                            )
                        }
                        
                        // 评论输入区域
                        ZStack(alignment: .topLeading) {
                            if commentManager.commentText.isEmpty && !textFieldFocused {
                                Text("跨越时空的对话...")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.gray.opacity(0.7))
                                    .padding(.leading, 14)
                                    .padding(.top, 5)
                                    .zIndex(1)
                            }
                            
                            AutoSizingTextView(text: $commentManager.commentText, isFocused: $textFieldFocused, heightChanged: { height in
                                // 全屏模式下可以有更大的高度
                                // 使用动画平滑过渡高度变化
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    textViewHeight = min(height, 200)
                                }
                            })
                            .frame(minHeight: 108) // 考虑行间距增加，从100增加到108
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(UIColor.systemBackground))
                                    .opacity(0.7)
                                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }
                        .background(DesignSystem.Colors.background)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !textFieldFocused {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    textFieldFocused = true
                                }
                            }
                            
                            // 触发滚动到底部的通知，这会使光标定位在文本末尾
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ScrollCommentToBottom"),
                                object: nil
                            )
                            
                            // 如果有文字，立即根据文字内容调整高度
                            if !commentManager.commentText.isEmpty {
                                calculateTextViewHeight(commentManager.commentText)
                            }
                            
                            // 延迟触发键盘显示，确保状态已更新
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                // 触发键盘显示
                                UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                            }
                            
                            // 如果文字超过30个字符，展开输入框
                            if commentManager.commentText.count > 30 {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    isExpanded = true
                                }
                            }
                        }
                        
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
                                        Button(action: { 
                                            mentionSearchText = ""
                                            hapticFeedback(style: .light)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.secondary)
                                                .padding(5)
                                        }
                                        .contentShape(Circle())
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray6))
                                .cornerRadius(16)
                                .padding(.horizontal, 16)
                                .padding(.top, 10)
                                
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
                                                textFieldFocused = true
                                            }) {
                                                characterRow(character)
                                                    .background(Color.clear)
                                                    .contentShape(Rectangle())
                                                    .padding(.vertical, 2)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .contentShape(Rectangle())
                                            
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
                            .background(DesignSystem.Colors.background)
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
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                                    .frame(width: 36, height: 36)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .contentShape(Rectangle())
                            
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
                        .background(DesignSystem.Colors.background)
                        
                        Spacer()
                    }
                    .background(DesignSystem.Colors.background)
                    .cornerRadius(10)
                    .offset(y: max(0, dragOffset)) // 添加拖动偏移
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                if gesture.translation.height > 0 { // 只允许向下拖动
                                    isDragging = true
                                    dragOffset = gesture.translation.height
                                }
                            }
                            .onEnded { gesture in
                                isDragging = false
                                // 如果拖动超过100点，关闭输入框
                                if gesture.translation.height > 100 {
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        isExpanded = false
                                        textFieldFocused = false
                                        resetKeyboardAndOffset()
                                        dragOffset = 0
                                    }
                                } else {
                                    // 否则恢复原位
                                    withAnimation(.spring()) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                }
                .edgesIgnoringSafeArea(.bottom)
                .onTapGesture {
                    // 点击背景关闭@选择器并收起键盘
                    if showMentionPicker {
                        showMentionPicker = false
                    }
                    
                    // 收起键盘并重置输入框状态
                    textFieldFocused = false
                    isInputFocused = false
                    
                    // 重置输入框高度
                    textViewHeight = 36
                    
                    // 收起输入框
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded = false
                    }
                }
                // 为全屏模式添加键盘回避
                .padding(.bottom, keyboardVisible ? keyboardHeight - 30 : 0)
                .zIndex(10) // 确保显示在最顶层
            } else {
                // 非展开模式 - 底部输入框，不使用遮挡层
                // 只显示输入框，不覆盖整个屏幕
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
                        .background(
                            BlurView(style: .systemThinMaterial)
                                .opacity(0.95)
                                .overlay(Color.gray.opacity(0.05))
                        )
                    }
                    
                    // 输入框和发送按钮
                    HStack(alignment: .bottom, spacing: 10) {
                        // 评论输入框
                        ZStack(alignment: .leading) {
                            if commentManager.commentText.isEmpty && !textFieldFocused {
                                Text("跨越时空的对话...")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.gray.opacity(0.7))
                                    .padding(.leading, 14)
                                    .padding(.top, 5)
                                    .zIndex(1)
                            }
                            
                            AutoSizingTextView(text: $commentManager.commentText, isFocused: $textFieldFocused, heightChanged: { height in
                                // 使用动画平滑过渡高度变化
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    // 限制最大高度为100
                                    textViewHeight = min(height, 100)
                                }
                            })
                            .frame(height: textViewHeight)
                            .padding(.horizontal, 14)
                            .padding(.vertical, textFieldFocused ? 6 : 2)
                        }
                        .frame(minHeight: textFieldFocused ? 50 : 48) // 考虑行间距，从46/44调整到50/48
                        .background(
                            RoundedRectangle(cornerRadius: 20)
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
                            
                            // 触发滚动到底部的通知，这会使光标定位在文本末尾
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ScrollCommentToBottom"),
                                object: nil
                            )
                            
                            // 如果有文字，立即根据文字内容调整高度
                            if !commentManager.commentText.isEmpty {
                                calculateTextViewHeight(commentManager.commentText)
                            }
                            
                            // 延迟触发键盘显示，确保状态已更新
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                // 触发键盘显示
                                UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                            }
                            
                            // 如果文字超过30个字符，展开输入框
                            if commentManager.commentText.count > 30 {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    isExpanded = true
                                }
                            }
                        }
                        
                        // 发送按钮
                        Button(action: {
                            if !commentManager.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                submitComment()
                                hapticFeedback(style: .medium)
                            }
                        }) {
                            Text("发送")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(commentManager.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : Color(red: 0.55, green: 0.35, blue: 0.75))
                                        .shadow(color: Color(red: 0.55, green: 0.35, blue: 0.75).opacity(0.2), radius: 3, x: 0, y: 1)
                                )
                        }
                        .disabled(commentManager.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .transition(.scale.combined(with: .opacity))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white) // 使用白色背景
                    // 修改分隔线使其更加明显
                    .overlay(
                        Rectangle()
                            .frame(height: 0.8)
                            .foregroundColor(Color.gray.opacity(0.3))
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
        }
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
        // 监听评论文本变化
        .onChange(of: commentManager.commentText) { oldValue, newValue in
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
        .onAppear {
            setupKeyboardNotifications()
            
            // 确保从其他页面进入时输入框高度为默认值
            DispatchQueue.main.async {
                textViewHeight = 36
                isExpanded = false
                
                // 触发输入框内文本显示到底部
                if !commentManager.commentText.isEmpty {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ScrollCommentToBottom"),
                        object: nil
                    )
                }
            }
            
            // 监听键盘显示通知
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                handleKeyboardNotification(notification, isShowing: true)
            }
            
            // 监听键盘隐藏通知
            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { _ in
                    // 使用异步方式更新状态，避免在视图更新过程中修改状态
                    DispatchQueue.main.async {
                        self.keyboardHeight = 0
                        self.keyboardVisible = false
                        self.bottomPadding = 0
                        self.viewOffset = 0
                    }
                }
            
            // 监听回复按钮点击通知，激活输入框
            NotificationCenter.default.addObserver(forName: NSNotification.Name("FocusCommentInput"), object: nil, queue: .main) { _ in
                focusInputField()
            }
        }
        .onDisappear {
            removeKeyboardNotifications()
            
            // 移除通知监听
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("FocusCommentInput"),
                object: nil
            )
            
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("ScrollCommentToBottom"),
                object: nil
            )
        }
    }
    
    // 提交评论
    private func submitComment() {
        // 检查评论内容是否为空
        guard !commentManager.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ 评论内容为空，取消提交")
            return
        }
        
        print("📝 CommentInputView - 开始提交评论: \"\(commentManager.commentText.prefix(30))...\"")
        
        // 发送通知，确保不会滚动页面
        NotificationCenter.default.post(
            name: NSNotification.Name("PreventScrollAfterSubmit"),
            object: nil
        )
        
        // 提交评论
        commentManager.submitComment()
        
        // 确保输入框文本被清空（双重保险）
        DispatchQueue.main.async {
            if !self.commentManager.commentText.isEmpty {
                print("🔧 CommentInputView - 手动清空输入框文本")
                self.commentManager.commentText = ""
            }
        }
        
        // 重置输入框状态
        withAnimation(.easeInOut(duration: 0.2)) {
            textFieldFocused = false
            isExpanded = false
            textViewHeight = 36 // 重置输入框高度
            
            // 强制重置键盘和位置状态，确保输入框回到底部
            keyboardVisible = false
            keyboardHeight = 0
            viewOffset = 0
            bottomPadding = 0
        }
        
        // 隐藏键盘
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
    
    // 更新视图偏移量以避开键盘（添加动画）
    private func updateViewOffset() {
        // 使用动画设置偏移量
        withAnimation(.easeInOut(duration: 0.25)) {
            if keyboardVisible {
                // 计算需要上移的距离，使输入框刚好在键盘上方
                // 修改计算逻辑，让输入框精确贴合键盘顶部
                let baseOffset = -keyboardHeight // 基础偏移量，直接使用键盘高度
                
                // 根据文本高度调整偏移量，确保输入框始终在键盘上方
                if textViewHeight > 100 {
                    viewOffset = baseOffset - 10 // 文本较多时稍微向上一点
                } else {
                    // 根据文本高度适当调整偏移量
                    let textHeightFactor = (textViewHeight - 36) / 2 // 文本高度因子
                    viewOffset = baseOffset - max(0, textHeightFactor) // 确保不会向下偏移
                }
            } else {
                viewOffset = 0
            }
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
        let minHeight: CGFloat = 44 // 最小高度调整为44，与梦幻联动保持一致
        let maxHeight: CGFloat = isExpanded ? 200 : 100 // 根据是否展开设置最大高度
        
        // 使用异步方式更新状态，避免在视图更新过程中修改状态
        DispatchQueue.main.async {
            // 使用动画更新高度，并限制最大高度
            withAnimation(.easeInOut(duration: 0.2)) {
                self.textViewHeight = min(max(minHeight, newSize.height), maxHeight)
            }
        }
    }
    
    // 角色行视图
    private func characterRow(_ character: CommentCharacter) -> some View {
        HStack(alignment: .center, spacing: 14) {
            // 头像
            Circle()
                .fill(character.category.color.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(character.name.prefix(1)))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(character.category.color)
                )
            
            // 名称和类别
            VStack(alignment: .leading, spacing: 3) {
                Text(character.name)
                    .font(.system(size: 15, weight: .medium))
                
                Text(character.category.displayName)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground).opacity(0.01)) // 几乎透明但可点击的背景
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
        // 使用异步方式更新状态，避免在视图更新过程中修改状态
        DispatchQueue.main.async {
            // 如果评论框为空，直接添加@用户名，否则添加空格+@用户名
            if self.commentManager.commentText.isEmpty {
                self.commentManager.commentText = "@\(character.name) "
            } else if self.commentManager.commentText.last == " " {
                self.commentManager.commentText += "@\(character.name) "
            } else {
                self.commentManager.commentText += " @\(character.name) "
            }
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
        CommentCharacter(id: "kongzi", name: "孔子", category: .philosopher),
        CommentCharacter(id: "curie", name: "居里夫人", category: .scientist),
        CommentCharacter(id: "newton", name: "牛顿", category: .scientist),
        CommentCharacter(id: "socrates", name: "苏格拉底", category: .philosopher),
        CommentCharacter(id: "mozart", name: "莫扎特", category: .writer),
        CommentCharacter(id: "libai", name: "李白", category: .writer)
    ]
    
    // 键盘通知处理方法
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                self.keyboardHeight = keyboardFrame.height
                self.keyboardVisible = true
                
                // 调整底部内边距，避免被键盘遮挡
                self.bottomPadding = keyboardFrame.height
                
                // 更新视图偏移量以避免键盘遮挡
                self.updateViewOffset()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            // 使用异步方式更新状态，避免在视图更新过程中修改状态
            DispatchQueue.main.async {
                self.keyboardHeight = 0
                self.keyboardVisible = false
                self.bottomPadding = 0
                self.viewOffset = 0
            }
        }
    }
    
    private func removeKeyboardNotifications() {
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
    
    // 激活输入框并弹出键盘的方法
    private func focusInputField() {
        // 使用异步方式更新状态，避免在视图更新过程中修改状态
        DispatchQueue.main.async {
            self.textFieldFocused = true
        }
        
        // 延迟一点点时间确保状态已更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 触发键盘显示
            UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // 处理键盘显示和隐藏的通知
    private func handleKeyboardNotification(_ notification: Notification, isShowing: Bool) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            // 使用异步方式更新状态，避免在视图更新过程中修改状态
            DispatchQueue.main.async {
                self.keyboardHeight = keyboardFrame.height
                self.keyboardVisible = isShowing
                
                // 调整底部内边距，避免被键盘遮挡
                self.bottomPadding = keyboardFrame.height
                
                // 更新视图偏移量以避免键盘遮挡
                self.updateViewOffset()
            }
        }
    }
    
    // 获取顶部安全区域高度
    private func getSafeAreaTop() -> CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.top
        }
        return 0
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