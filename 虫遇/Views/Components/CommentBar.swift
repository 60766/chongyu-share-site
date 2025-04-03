import SwiftUI
import UIKit

/**
 * 现代社交媒体风格评论输入栏组件
 * 参考主流社交平台实现，包含表情选择器和更丰富的交互
 */
struct CommentBar: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onSend: () -> Void
    var activateImmediately: Bool = false
    
    // 增加表情选择状态
    @Binding var showEmojiPicker: Bool
    
    func makeUIView(context: Context) -> UIView {
        // 创建主容器视图
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        
        // 创建内部容器（包含文本框和操作按钮）
        let inputContainer = UIView()
        inputContainer.backgroundColor = .systemGray6
        inputContainer.layer.cornerRadius = 20
        inputContainer.clipsToBounds = true
        
        // 创建文本输入框
        let textField = UITextField()
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.placeholder = placeholder
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.returnKeyType = .send
        textField.delegate = context.coordinator
        
        // 改进文本框样式，更贴近现代社交应用
        textField.layer.cornerRadius = 18
        textField.clipsToBounds = true
        
        // 创建左侧表情按钮，使用自定义配置更生动
        let emojiButton = UIButton(type: .system)
        let emojiConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        emojiButton.setImage(UIImage(systemName: "face.smiling", withConfiguration: emojiConfig), for: .normal)
        emojiButton.tintColor = .systemGray2
        emojiButton.addTarget(context.coordinator, action: #selector(Coordinator.emojiTapped), for: .touchUpInside)
        
        // 创建@按钮，同样使用自定义配置
        let atButton = UIButton(type: .system)
        let atConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        atButton.setImage(UIImage(systemName: "at", withConfiguration: atConfig), for: .normal)
        atButton.tintColor = .systemGray2
        
        // 发送按钮 (根据输入内容显示或隐藏)
        let sendButton = UIButton(type: .system)
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        // 使用primaryColor作为发送按钮的颜色
        let primaryColor = UIColor(Color.primaryColor)
        sendButton.tintColor = primaryColor
        sendButton.addTarget(context.coordinator, action: #selector(Coordinator.sendTapped), for: .touchUpInside)
        
        // 添加所有子视图
        containerView.addSubview(inputContainer)
        inputContainer.addSubview(emojiButton)
        inputContainer.addSubview(textField)
        inputContainer.addSubview(atButton)
        containerView.addSubview(sendButton)
        
        // 设置自动布局约束
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        emojiButton.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        atButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 输入容器约束
            inputContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            inputContainer.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            inputContainer.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            inputContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            
            // 表情按钮约束
            emojiButton.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 8),
            emojiButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            emojiButton.widthAnchor.constraint(equalToConstant: 30),
            emojiButton.heightAnchor.constraint(equalToConstant: 30),
            
            // 文本输入框约束
            textField.leadingAnchor.constraint(equalTo: emojiButton.trailingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: atButton.leadingAnchor, constant: -8),
            textField.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 4),
            textField.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -4),
            
            // @按钮约束
            atButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -8),
            atButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            atButton.widthAnchor.constraint(equalToConstant: 30),
            atButton.heightAnchor.constraint(equalToConstant: 30),
            
            // 发送按钮约束
            sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 40),
            sendButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // 保存引用以供更新
        context.coordinator.textField = textField
        context.coordinator.sendButton = sendButton
        context.coordinator.emojiButton = emojiButton
        
        // 更新发送按钮状态
        context.coordinator.updateSendButtonState()
        
        // 如果需要立即激活，就立即获得焦点
        if activateImmediately {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                textField.becomeFirstResponder()
            }
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 更新TextField的文本
        if let textField = context.coordinator.textField {
            if textField.text != text {
                textField.text = text
                context.coordinator.updateSendButtonState()
            }
            
            // 如果activateImmediately发生变化，响应它
            if activateImmediately && !textField.isFirstResponder {
                textField.becomeFirstResponder()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, showEmojiPicker: $showEmojiPicker, onSend: onSend)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        @Binding var showEmojiPicker: Bool
        var onSend: () -> Void
        var textField: UITextField?
        var sendButton: UIButton?
        var emojiButton: UIButton?
        
        init(text: Binding<String>, showEmojiPicker: Binding<Bool>, onSend: @escaping () -> Void) {
            self._text = text
            self._showEmojiPicker = showEmojiPicker
            self.onSend = onSend
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.text = textField.text ?? ""
                self.updateSendButtonState()
            }
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            if !(textField.text?.isEmpty ?? true) {
                onSend()
                // 增强触觉反馈
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
            return true
        }
        
        @objc func sendTapped() {
            if !(text.isEmpty) {
                // 增强触觉反馈
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.prepare()
                
                // 添加轻微动画效果
                if let button = sendButton {
                    UIView.animate(withDuration: 0.1, animations: {
                        button.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    }, completion: { _ in
                        UIView.animate(withDuration: 0.1) {
                            button.transform = CGAffineTransform.identity
                        }
                        // 执行完动画后触发触觉反馈
                        impactFeedback.impactOccurred()
                    })
                } else {
                    impactFeedback.impactOccurred()
                }
                
                onSend()
            }
        }
        
        @objc func emojiTapped() {
            // 增强触觉反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.prepare()
            
            // 添加轻微动画效果
            if let button = self.emojiButton {
                UIView.animate(withDuration: 0.1, animations: {
                    button.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                }, completion: { _ in
                    UIView.animate(withDuration: 0.1) {
                        button.transform = CGAffineTransform.identity
                    }
                    // 执行完动画后触发触觉反馈
                    impactFeedback.impactOccurred()
                })
            } else {
                impactFeedback.impactOccurred()
            }
            
            // 切换表情选择器的显示状态
            showEmojiPicker.toggle()
            
            // 如果表情选择器显示，取消输入框的焦点
            if showEmojiPicker, let textField = self.textField {
                textField.resignFirstResponder()
            }
        }
        
        // 根据文本内容更新发送按钮状态
        func updateSendButtonState() {
            DispatchQueue.main.async {
                let isEmpty = self.text.isEmpty
                // 使用primaryColor作为发送按钮的颜色
                let primaryColor = UIColor(Color.primaryColor)
                self.sendButton?.tintColor = isEmpty ? .systemGray3 : primaryColor
                self.sendButton?.isEnabled = !isEmpty
            }
        }
    }
}

/**
 * 表情选择器组件
 */
struct EmojiPickerView: View {
    @Binding var text: String
    
    // 常用表情符号，按照参考图片排列
    let commonEmojis = [
        ["🌹", "😄", "🐺", "😊", "😆", "😍", "🤤"],
        ["🌸", "🙂", "😊", "😂", "🤣", "😅", "😁", "😌"],
        ["😒", "🙄", "😏", "😔", "🤩", "🥳", "😎", "🧐"],
        ["🫠", "😱", "😤", "😡", "🥺", "😳", "🤯", "😴"]
    ]
    
    // 分类标签
    let categories = ["常用", "动物", "表情", "对象", "符号", "旗帜"]
    @State private var selectedCategory = 0
    
    // 触觉反馈
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        VStack(spacing: 0) {
            // 表情分类标签栏
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.m) {
                    ForEach(0..<categories.count, id: \.self) { index in
                        Button(action: {
                            withAnimation(DesignSystem.Animations.quick) {
                                selectedCategory = index
                            }
                            feedbackGenerator.impactOccurred(intensity: 0.4)
                        }) {
                            Text(categories[index])
                                .font(selectedCategory == index ? 
                                      DesignSystem.Typography.footnote.weight(.medium) : 
                                      DesignSystem.Typography.footnote)
                                .foregroundColor(selectedCategory == index ? 
                                                DesignSystem.Colors.primary : 
                                                DesignSystem.Colors.secondaryText)
                                .padding(.horizontal, DesignSystem.Spacing.m)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                                .background(selectedCategory == index ? 
                                           DesignSystem.Colors.primary.opacity(0.1) : 
                                           Color.clear)
                                .cornerRadius(DesignSystem.Radius.l)
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.m)
                .padding(.vertical, DesignSystem.Spacing.s)
            }
            
            Divider()
                .padding(.horizontal, DesignSystem.Spacing.s)
            
            // 表情网格
            VStack(spacing: DesignSystem.Spacing.l) {
                ForEach(0..<commonEmojis.count, id: \.self) { row in
                    HStack(spacing: DesignSystem.Spacing.l) {
                        ForEach(commonEmojis[row], id: \.self) { emoji in
                            Button(action: {
                                text += emoji
                                
                                // 触觉反馈
                                feedbackGenerator.impactOccurred(intensity: 0.5)
                            }) {
                                Text(emoji)
                                    .font(.system(size: 28))
                            }
                            .buttonStyle(EmojiButtonStyle())
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.l)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.m)
            
            Spacer()
        }
        .frame(height: 220)
        .background(DesignSystem.Colors.background)
        .onAppear {
            // 准备触觉反馈
            feedbackGenerator.prepare()
        }
    }
}

// 表情按钮样式
struct EmojiButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.3 : 1.0)
            .animation(DesignSystem.Animations.quick, value: configuration.isPressed)
    }
}

// 预览
struct CommentBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CommentBar(
                text: .constant(""),
                placeholder: "跨越时空的对话...",
                onSend: {},
                showEmojiPicker: .constant(false)
            )
            .frame(height: 50)
            .previewDisplayName("空白状态")
        }
        .background(DesignSystem.Colors.background)
    }
} 