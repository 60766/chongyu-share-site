import SwiftUI

/// 专门为梦幻联动设计的输入框组件
struct MultiChatInputBar: View {
    @Binding var messageText: String
    @Binding var isSending: Bool
    var characterThemeColor: Color
    var userRole: UserRole
    var selectedCharacters: [CharacterModel]
    var onSend: () -> Void

    @State private var textFieldFocused: Bool = false
    @State private var textViewHeight: CGFloat = 36
    @State private var isKeyboardTransitioning: Bool = false
    
    // 🔍 观察者模式占位符文本
    private var placeholderText: String {
            let observerPrompts = [
                "提出问题，引导对话方向...",
                "请继续分享这个话题...",
                "您觉得这个问题如何？",
                "能详细谈谈您的观点吗？"
            ]
            // 可以基于对话状态选择不同提示，这里先用第一个
            return observerPrompts[0]
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
                        .padding(.top, 5)
                        .zIndex(1)
                        .opacity(messageText.isEmpty && !textFieldFocused ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: userRole) // 添加角色切换动画
                    
                    MultiChatTextView(text: $messageText, isFocused: $textFieldFocused, heightChanged: { height in
                        // 使用更平滑的动画过渡
                        withAnimation(.easeInOut(duration: 0.3)) {
                            textViewHeight = min(height, 100)
                        }
                    })
                    .frame(height: textViewHeight)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .disabled(false)
                    .opacity(1)
                    .onAppear {
                        // 延迟一小段时间再获得焦点，确保键盘监听已准备好，避免闪烁
                        print("MultiChatInputBar - 组件已出现，准备获得焦点")
                        // 使用非常短的延迟，确保 MultiChatKeyboardAdaptive 的监听已准备好
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            if !textFieldFocused {
                                print("MultiChatInputBar - 设置焦点，触发键盘")
                                // 立即设置焦点，不使用动画，让键盘立即弹出
                                // 键盘高度更新会使用系统键盘的动画参数，自动同步
                                textFieldFocused = true
                            }
                        }
                    }
                    .onDisappear {
                        // 组件消失时立即失去焦点，确保键盘快速收起
                        print("MultiChatInputBar - 组件消失，立即失去焦点")
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
                    print("MultiChatInputBar - 输入框被点击")
                    
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
            .padding(.vertical, 6)
            .padding(.bottom, 8) // 增加底部内边距，确保在安全区域内有足够的间距
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
            // 添加整体动画
            .animation(.easeInOut(duration: 0.3), value: textFieldFocused)
            .animation(.easeInOut(duration: 0.3), value: textViewHeight)
        }
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: -1)
    }
} 