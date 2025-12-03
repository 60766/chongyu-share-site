import SwiftUI
import UIKit
import Combine

/**
 * 增强型文本显示视图 - 终极版
 * 完美同步光标与文本，解决长文本对齐问题
 */
struct EnhancedTextDisplayView: View {
    @Binding var text: String
    @FocusState var isFocused: Bool
    
    // 中间状态变量，用于连接FocusState和Binding<Bool>
    @State private var isTextFieldFocused: Bool = false
    
    // 基本属性
    var placeholder: String
    var minHeight: CGFloat
    var maxHeight: CGFloat
    var cornerRadius: CGFloat
    var borderColor: Color
    var backgroundColor: Color
    var showDebugInfo: Bool
    
    // 调试计数器
    @State private var tapCount: Int = 0
    
    // 滚动同步
    @State private var textEditorContentOffset = CGPoint.zero
    @State private var manualScrollOffset = CGFloat.zero
    @State private var currentLineHeight: CGFloat = 0 // 跟踪当前行高
    
    // 布局常量 - 精确控制对齐
    private let fontSize: CGFloat = 16.0
    private let horizontalPadding: CGFloat = 12.0
    private let textTopPadding: CGFloat = 8.0
    private let lineSpacing: CGFloat = 4.0 // 增加行间距到4.0
    
    // 初始化方法
    init(text: Binding<String>, 
         placeholder: String = "",
         minHeight: CGFloat = 100,
         maxHeight: CGFloat = 300,
         cornerRadius: CGFloat = 15,
         borderColor: Color = .purple,
         backgroundColor: Color = .white,
         showDebugInfo: Bool = false) {
        self._text = text
        self.placeholder = placeholder
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.backgroundColor = backgroundColor
        self.showDebugInfo = showDebugInfo
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topLeading) {
                // 1. 背景层 - 纯白色
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white)
                
                // 2. 输入层 - TextEditor处理输入和显示光标
                PerfectTextEditor(
                    text: $text,
                    placeholderText: placeholder,
                    isFirstResponder: $isTextFieldFocused,
                    fontSize: fontSize,
                    textColor: .black,  // 使用黑色文本，不再需要透明
                    cursorColor: .blue,
                    backgroundColor: .white,
                    horizontalPadding: horizontalPadding,
                    topPadding: textTopPadding,
                    lineSpacing: lineSpacing, // 传递行间距参数
                    contentOffset: $textEditorContentOffset,
                    onScrollChange: { newOffset in
                        // 使用DispatchQueue.main.async延迟状态更新，避免在视图更新期间直接修改状态
                        DispatchQueue.main.async {
                            withAnimation(.linear(duration: 0.01)) {
                                manualScrollOffset = newOffset.y
                            }
                        }
                    },
                    onLineHeightChange: { height in
                        // 使用异步更新避免在视图更新期间直接修改状态
                        DispatchQueue.main.async {
                            currentLineHeight = height
                        }
                    },
                    onTap: {
                        // 使用异步更新避免在视图更新期间修改状态
                        DispatchQueue.main.async {
                            isTextFieldFocused = true
                            tapCount += 1
                            #if DEBUG
                            print("点击TextEditor - 次数: \(tapCount)")
                            #endif
                        }
                    }
                )
                .frame(minHeight: minHeight, maxHeight: maxHeight)
                
                // 3. 显示层 - 只负责显示文本
                VStack {
                    if text.isEmpty && !isTextFieldFocused {
                        // 占位符
                        Text(placeholder)
                            .font(.system(size: fontSize))
                            .foregroundColor(.gray)
                            .lineSpacing(lineSpacing)
                            .padding(.horizontal, horizontalPadding)
                            .padding(.top, textTopPadding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .allowsHitTesting(false)
            }
            .frame(minHeight: minHeight, maxHeight: maxHeight)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isTextFieldFocused ? borderColor : borderColor.opacity(0.6), lineWidth: isTextFieldFocused ? 2.0 : 1.0)
            )
            .cornerRadius(cornerRadius)
            .contentShape(Rectangle())
            .onTapGesture {
                // 使用异步更新避免在视图更新期间修改状态
                DispatchQueue.main.async {
                    isTextFieldFocused = true
                    isFocused = true 
                    tapCount += 1
                    #if DEBUG
                    print("点击视图区域 - 次数: \(tapCount)")
                    #endif
                    
                    // 强制激活输入
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        let _ = UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            // 同步FocusState和中间状态变量
            .onChange(of: isFocused) { oldValue, newValue in
                DispatchQueue.main.async {
                    isTextFieldFocused = newValue
                }
            }
            .onChange(of: isTextFieldFocused) { oldValue, newValue in
                DispatchQueue.main.async {
                    isFocused = newValue
                }
            }
            // 使用自定义焦点控制
            .focused($isFocused)
        }
    }
}

// 用于监测Text视图高度的PreferenceKey
struct TextHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/**
 * 完美对齐的TextEditor
 * 精确控制排版和滚动行为
 */
struct PerfectTextEditor: UIViewRepresentable {
    @Binding var text: String
    var placeholderText: String
    @Binding var isFirstResponder: Bool
    
    // 样式属性
    var fontSize: CGFloat
    var textColor: Color
    var cursorColor: Color
    var backgroundColor: Color
    var horizontalPadding: CGFloat
    var topPadding: CGFloat
    var lineSpacing: CGFloat // 添加行间距属性
    
    // 滚动同步属性
    @Binding var contentOffset: CGPoint
    var onScrollChange: ((CGPoint) -> Void)
    var onLineHeightChange: ((CGFloat) -> Void)
    var onTap: (() -> Void)
    
    func makeUIView(context: Context) -> SuperPreciseTextView {
        let textView = SuperPreciseTextView()
        textView.font = UIFont.systemFont(ofSize: fontSize)
        textView.textColor = UIColor.black  // 改为黑色文本，让TextEditor显示文本
        textView.tintColor = UIColor(cursorColor) // 光标颜色
        textView.backgroundColor = UIColor(backgroundColor)
        textView.delegate = context.coordinator
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        
        // 精确控制内边距 - 调整左内边距以适应0.3的字间距
        let topPaddingAdjusted = topPadding
        let leftPaddingAdjusted = horizontalPadding - 3.0  // 减小左内边距以修正光标位置
        let bottomPaddingAdjusted = topPadding
        
        textView.textContainerInset = UIEdgeInsets(
            top: topPaddingAdjusted,
            left: leftPaddingAdjusted,
            bottom: bottomPaddingAdjusted,
            right: horizontalPadding
        )
        textView.textContainer.lineFragmentPadding = 0
        
        // 创建段落样式并设置行间距
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        // 设置默认行高，帮助与SwiftUI的Text对齐
        paragraphStyle.minimumLineHeight = UIFont.systemFont(ofSize: fontSize).lineHeight
        // 设置段落对齐方式为左对齐
        paragraphStyle.alignment = .left
        // 取消首行缩进
        paragraphStyle.firstLineHeadIndent = 0
        // 设置段落头部缩进
        paragraphStyle.headIndent = 0
        
        // 设置格式化属性 - 不设置kern，让系统处理字间距
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: UIColor.black
        ]
        
        // 应用到默认输入属性
        textView.typingAttributes = attributes
        
        // 使用默认行高但启用行距调整
        textView.layoutManager.usesFontLeading = true
        
        // 禁用自动校正功能，提高准确性
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.smartInsertDeleteType = .no
        textView.keyboardType = .default
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        textView.addGestureRecognizer(tapGesture)
        
        // 添加滚动和行高监听
        textView.onScrollCallback = { point in
            DispatchQueue.main.async {
                self.contentOffset = point
            }
            onScrollChange(point)
        }
        
        textView.onLineHeightCallback = { height in
            DispatchQueue.main.async {
                self.onLineHeightChange(height)
            }
        }
        
        // 计算初始行高
        calculateLineHeight(textView)
        
        return textView
    }
    
    func updateUIView(_ uiView: SuperPreciseTextView, context: Context) {
        // 更新文本内容
        if uiView.text != text {
            // 保存选择范围和光标位置
            let selectedRange = uiView.selectedRange
            let currentOffset = uiView.contentOffset
            
            // 直接使用attributedString替代设置text
            let attributedString = NSMutableAttributedString(string: text)
            
            // 创建段落样式
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = lineSpacing
            paragraphStyle.minimumLineHeight = UIFont.systemFont(ofSize: fontSize).lineHeight
            paragraphStyle.alignment = .left
            paragraphStyle.firstLineHeadIndent = 0
            paragraphStyle.headIndent = 0
            
            // 应用样式到全部文本
            attributedString.addAttributes(
                [
                    .paragraphStyle: paragraphStyle,
                    .font: UIFont.systemFont(ofSize: fontSize),
                    .foregroundColor: UIColor.black
                ],
                range: NSRange(location: 0, length: text.count)
            )
            
            // 更新文本
            uiView.attributedText = attributedString
            
            // 恢复选择范围（如果可能）
            if selectedRange.location <= text.count {
                uiView.selectedRange = selectedRange
            }
            
            // 设置默认输入属性以保持一致的样式
            uiView.typingAttributes = [
                .paragraphStyle: paragraphStyle,
                .font: UIFont.systemFont(ofSize: fontSize),
                .foregroundColor: UIColor.black
            ]
            
            // 恢复滚动位置
            DispatchQueue.main.async {
                uiView.contentOffset = currentOffset
            }
            
            // 重新计算行高
            calculateLineHeight(uiView)
        }
        
        // 处理焦点状态
        if isFirstResponder && !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
                
                // 确保光标可见
                if let selectedTextRange = uiView.selectedTextRange {
                    uiView.scrollRectToVisible(uiView.caretRect(for: selectedTextRange.end), animated: true)
                }
            }
        } else if !isFirstResponder && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }
    
    private func calculateLineHeight(_ textView: SuperPreciseTextView) {
        // 如果文本为空，使用默认字体行高
        if text.isEmpty {
            let defaultHeight = UIFont.systemFont(ofSize: fontSize).lineHeight
            textView.onLineHeightCallback?(defaultHeight)
            return
        }
        
        // 获取第一行的高度
        let layoutManager = textView.layoutManager
        
        guard layoutManager.numberOfGlyphs > 0 else { return }
        
        // 计算第一行的范围
        var lineRange = NSRange(location: 0, length: 1)
        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: 0, effectiveRange: &lineRange)
        
        // 将行高提供给回调
        textView.onLineHeightCallback?(lineRect.height)
    }
    
    // 应用一致的样式
    private func applyConsistentStyling(_ textView: SuperPreciseTextView) {
        // 创建段落样式
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing // 使用相同的行间距
        // 设置默认行高，帮助与SwiftUI的Text对齐
        paragraphStyle.minimumLineHeight = UIFont.systemFont(ofSize: fontSize).lineHeight
        // 设置段落对齐方式为左对齐
        paragraphStyle.alignment = .left
        // 取消首行缩进
        paragraphStyle.firstLineHeadIndent = 0
        // 设置段落头部缩进
        paragraphStyle.headIndent = 0
        
        // 设置默认输入属性和已输入文本的属性
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: UIColor.black
        ]
        
        textView.typingAttributes = attributes
        
        // 如果文本不为空，应用样式到现有文本
        if !textView.text.isEmpty {
            let attributedString = NSMutableAttributedString(string: textView.text)
            attributedString.addAttributes(
                attributes,
                range: NSRange(location: 0, length: textView.text.count)
            )
            
            // 保存选择范围
            let selectedRange = textView.selectedRange
            
            // 更新文本
            textView.attributedText = attributedString
            
            // 恢复选择范围
            textView.selectedRange = selectedRange
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFirstResponder: $isFirstResponder, onTap: onTap, parent: self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        @Binding var isFirstResponder: Bool
        var onTap: () -> Void
        // 引用父视图
        let parent: PerfectTextEditor
        
        init(text: Binding<String>, isFirstResponder: Binding<Bool>, onTap: @escaping () -> Void, parent: PerfectTextEditor) {
            self._text = text
            self._isFirstResponder = isFirstResponder
            self.onTap = onTap
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            // 保存选择范围和光标位置
            let selectedRange = textView.selectedRange
            
            // 异步更新绑定的文本，避免在视图更新期间修改状态
            DispatchQueue.main.async {
                self.text = textView.text
            }
            
            // 计算行高并报告
            if let superTextView = textView as? SuperPreciseTextView {
                // NSLayoutManager不是Optional类型，不需要使用if let
                let layoutManager = textView.layoutManager
                if layoutManager.numberOfGlyphs > 0 {
                    var lineRange = NSRange(location: 0, length: 1)
                    let lineRect = layoutManager.lineFragmentRect(forGlyphAt: 0, effectiveRange: &lineRange)
                    superTextView.onLineHeightCallback?(lineRect.height)
                }
                
                // 创建段落样式
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = self.parent.lineSpacing
                paragraphStyle.minimumLineHeight = UIFont.systemFont(ofSize: self.parent.fontSize).lineHeight
                paragraphStyle.alignment = .left
                paragraphStyle.firstLineHeadIndent = 0
                paragraphStyle.headIndent = 0
                
                // 设置默认输入属性以保持一致的样式
                textView.typingAttributes = [
                    .paragraphStyle: paragraphStyle,
                    .font: UIFont.systemFont(ofSize: self.parent.fontSize),
                    .foregroundColor: UIColor.black
                ]
                
                // 确保维持正确的选择范围，避免光标位置丢失
                textView.selectedRange = selectedRange
                
                // 确保光标可见
                if let selectedTextRange = textView.selectedTextRange {
                    textView.scrollRectToVisible(textView.caretRect(for: selectedTextRange.end), animated: false)
                }
            }
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            isFirstResponder = true
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            isFirstResponder = false
        }
        
        @objc func handleTap() {
            onTap()
        }
    }
}

/**
 * 超精确UITextView，支持滚动和行高回调
 */
class SuperPreciseTextView: UITextView {
    var onScrollCallback: ((CGPoint) -> Void)?
    var onLineHeightCallback: ((CGFloat) -> Void)?
    
    // 提高精度的布局
    override func layoutSubviews() {
        super.layoutSubviews()
        onScrollCallback?(contentOffset)
        
        // 在布局更新后重新计算行高
        // NSLayoutManager不是Optional类型，不需要使用if let
        let layoutManager = self.layoutManager
        if layoutManager.numberOfGlyphs > 0 && !text.isEmpty {
            var lineRange = NSRange(location: 0, length: 1)
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: 0, effectiveRange: &lineRange)
            onLineHeightCallback?(lineRect.height)
        }
    }
    
    override func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
        super.scrollRectToVisible(rect, animated: animated)
        onScrollCallback?(contentOffset)
    }
    
    override func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        super.setContentOffset(contentOffset, animated: animated)
        onScrollCallback?(contentOffset)
    }
}

// 预览
struct EnhancedTextDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            EnhancedTextDisplayView(
                text: .constant("这是一段示例文本，用于测试在较小高度下的显示效果。这是一段示例文本，用于测试在较小高度下的显示效果。"),
                placeholder: "请输入内容...",
                minHeight: 80,
                showDebugInfo: false  // 确保不显示调试信息
            )
            .padding()
            .frame(height: 150)
            
            EnhancedTextDisplayView(
                text: .constant(""),
                placeholder: "请输入内容...",
                showDebugInfo: false  // 已设置为false
            )
            .padding()
            .frame(height: 120)
        }
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}

// 删除重复的类型别名声明，移至不同文件
// typealias TextDisplayView = EnhancedTextDisplayView 