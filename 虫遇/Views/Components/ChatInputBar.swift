import SwiftUI

struct ChatInputBar: View {
    @Binding var messageText: String
    @Binding var isSending: Bool
    var characterThemeColor: Color
    var onSend: () -> Void

    @State private var textFieldFocused: Bool = false
    @State private var textViewHeight: CGFloat = 36
    @State private var isKeyboardTransitioning: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.12))
                .frame(height: 0.3)

            HStack(alignment: .bottom, spacing: 10) {
                ZStack(alignment: .leading) {
                    Text("跨越时空的对话...")
                        .font(.system(size: 14))
                        .foregroundColor(Color.gray.opacity(0.7))
                        .padding(.leading, 14)
                        .padding(.top, 5)
                        .zIndex(1)
                        .opacity(messageText.isEmpty && !textFieldFocused ? 1 : 0)
                    
                    AutoSizingTextView(text: $messageText, isFocused: $textFieldFocused, heightChanged: { height in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            textViewHeight = min(height, 100)
                        }
                    })
                    .frame(height: textViewHeight)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6) // 使用固定的垂直内边距
                    .disabled(false)
                    .opacity(1)
                }
                .frame(minHeight: 44) // 使用固定的最小高度
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(UIColor.systemGray6))
                        .opacity(0.9)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    print("ChatInputBar - 输入框被点击")
                    
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
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : characterThemeColor)
                                .shadow(color: characterThemeColor.opacity(0.2), radius: 3, x: 0, y: 1)
                        )
                }
                .disabled(messageText.isEmpty)
                .transition(.scale.combined(with: .opacity))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .padding(.bottom, 4) // 增加底部内边距，确保平滑过渡
            .background(
                Color(.systemBackground).opacity(0.9)
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