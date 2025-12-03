import SwiftUI
import Combine

/// 专门为私聊设计的输入框组件 - 和梦幻联动完全一致的配置
struct ChatInputBar: View {
    @Binding var messageText: String
    @Binding var isSending: Bool
    var characterThemeColor: Color
    var onSend: () -> Void

    @State private var textFieldFocused: Bool = false
    @State private var textViewHeight: CGFloat = 36  // 和梦幻联动一致
    @State private var isKeyboardTransitioning: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    
    // 私聊占位符文本
    private var placeholderText: String {
        return "跨越时空的对话..."
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.12))
                .frame(height: 0.3)

            HStack(alignment: .bottom, spacing: 10) {
                ZStack(alignment: .leading) {
                    Text(placeholderText)
                        .font(.system(size: 14))
                        .foregroundColor(Color.gray.opacity(0.7))
                        .padding(.leading, 14)
                        .padding(.top, 5)  // 和梦幻联动一致
                        .zIndex(1)
                        .opacity(messageText.isEmpty && !textFieldFocused ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: textFieldFocused)
                    
                    // 使用和多人聊天相同的文本视图组件
                    MultiChatTextView(text: $messageText, isFocused: $textFieldFocused, heightChanged: { height in
                        // 使用和梦幻联动完全一致的逻辑
                        withAnimation(.easeInOut(duration: 0.3)) {
                            textViewHeight = min(height, 100)
                        }
                    })
                    .frame(height: textViewHeight)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)  // 和梦幻联动一致
                    .disabled(false)
                    .opacity(1)
                    .onAppear {
                        // 不在页面出现时自动获得焦点，让用户手动点击输入框来激活
                        #if DEBUG
                        print("ChatInputBar - 组件已出现，等待用户点击激活")
                        #endif
                    }
                    .onDisappear {
                        // 组件消失时立即失去焦点，确保键盘快速收起（和梦幻联动一致）
                        #if DEBUG
                        print("ChatInputBar - 组件消失，立即失去焦点")
                        #endif
                        if textFieldFocused {
                            textFieldFocused = false
                        }
                    }
                }
                .frame(minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(UIColor.systemGray6))
                        .opacity(0.9)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    #if DEBUG
                    print("ChatInputBar - 输入框被点击")
                    #endif
                    
                    // 防止重复触发键盘动画
                    if !isKeyboardTransitioning && !textFieldFocused {
                        isKeyboardTransitioning = true
                        
                        // 使用平滑动画激活键盘
                        withAnimation(.easeInOut(duration: 0.25)) {
                            textFieldFocused = true
                        }
                        
                        // 重置过渡状态
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isKeyboardTransitioning = false
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    // 发送前先重置焦点状态，防止键盘弹动
                    withAnimation(.easeInOut(duration: 0.25)) {
                        textFieldFocused = false
                    }
                    
                    // 延迟执行发送操作，等待键盘收起动画完成
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onSend()
                    }
                }) {
                    Text("发送")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : Color(red: 0.55, green: 0.35, blue: 0.75))
                                .shadow(color: Color(red: 0.55, green: 0.35, blue: 0.75).opacity(0.2), radius: 3, x: 0, y: 1)
                        )
                }
                .disabled(messageText.isEmpty)
                .transition(.scale.combined(with: .opacity))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)  // 和梦幻联动完全一致
            .padding(.bottom, max(8, keyboardHeight > 0 ? 8 : 8)) // 根据键盘状态调整底部间距
            .background(
                Color.white
            )
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.gray.opacity(0.15))
                    .offset(y: -0.5),
                alignment: .top
            )
            // 添加整体动画 - 和梦幻联动完全一致
            .animation(.easeInOut(duration: 0.3), value: textFieldFocused)
            .animation(.easeInOut(duration: 0.3), value: textViewHeight)
            .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
        }
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: -1)
        .offset(y: keyboardHeight > 0 ? -keyboardHeight : 0) // 根据键盘高度调整位置
        .onReceive(KeyboardHeightPublisher()) { height in
            // 防抖动：只有高度变化超过阈值时才更新
            if abs(height - keyboardHeight) > 5 {
                withAnimation(.easeInOut(duration: 0.25)) {
                    keyboardHeight = height
                    
                    // 当键盘收起时，同时重置焦点状态
                    if height == 0 && textFieldFocused {
                        textFieldFocused = false
                    }
                }
            }
        }
    }
}

struct ChatInputBar_Previews: PreviewProvider {
    static var previews: some View {
        ChatInputBar(
            messageText: .constant(""),
            isSending: .constant(false),
            characterThemeColor: Color.blue,
            onSend: {}
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
} 