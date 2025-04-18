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
    private let lineSpacing: CGFloat = 0.0 // 设置为0确保与TextEditor默认行距一致
    
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
                    textColor: .clear,  // 透明文本，只显示光标
                    cursorColor: .blue,
                    backgroundColor: .white,
                    horizontalPadding: horizontalPadding,
                    topPadding: textTopPadding,
                    contentOffset: $textEditorContentOffset,
                    onScrollChange: { newOffset in
                        withAnimation(.linear(duration: 0.01)) {
                            manualScrollOffset = newOffset.y
                        }
                    },
                    onLineHeightChange: { height in
                        currentLineHeight = height
                    },
                    onTap: {
                        isTextFieldFocused = true
                        tapCount += 1
                        print("点击TextEditor - 次数: \(tapCount)")
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
                            .padding(.leading, horizontalPadding)
                            .padding(.top, textTopPadding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if !text.isEmpty {
                        // 实际文本 - 精确同步滚动位置
                        GeometryReader { geometry in
                            ScrollView {
                                Text(text)
                                    .font(.system(size: fontSize))
                                    .foregroundColor(.black)
                                    .tracking(0) // 字符间距设为0
                                    .lineSpacing(lineSpacing)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    // 精确匹配TextEditor的内边距
                                    .padding(.horizontal, horizontalPadding)
                                    .padding(.top, textTopPadding) 
                                    .id("textContent")
                                    // 监测Text的布局变化
                                    .background(
                                        GeometryReader { textGeometry in
                                            Color.clear.preference(
                                                key: TextHeightPreferenceKey.self,
                                                value: textGeometry.size.height
                                            )
                                        }
                                    )
                            }
                            .scrollDisabled(true)
                            .offset(y: manualScrollOffset)
                        }
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
                isTextFieldFocused = true
                isFocused = true 
                tapCount += 1
                print("点击视图区域 - 次数: \(tapCount)")
                
                // 强制激活输入
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let _ = UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                }
            }
            // 同步FocusState和中间状态变量
            .onChange(of: isFocused) { newValue in
                isTextFieldFocused = newValue
            }
            .onChange(of: isTextFieldFocused) { newValue in
                isFocused = newValue
            }
            // 使用自定义焦点控制
            .focused($isFocused)
            
            // 调试信息
            if showDebugInfo {
                HStack {
                    Text("字数: \(text.count)")
                        .font(.caption2)
                    Spacer()
                    Text("状态: \(isTextFieldFocused ? "编辑中" : "未编辑")")
                        .font(.caption2)
                    Spacer()
                    Text("行高: \(Int(currentLineHeight))")
                        .font(.caption2)
                }
                .padding(.horizontal, 4)
                .foregroundColor(.gray)
            }
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
    
    // 滚动同步属性
    @Binding var contentOffset: CGPoint
    var onScrollChange: ((CGPoint) -> Void)
    var onLineHeightChange: ((CGFloat) -> Void)
    var onTap: (() -> Void)
    
    func makeUIView(context: Context) -> SuperPreciseTextView {
        let textView = SuperPreciseTextView()
        textView.font = UIFont.systemFont(ofSize: fontSize)
        textView.textColor = UIColor(textColor)
        textView.tintColor = UIColor(cursorColor) // 光标颜色
        textView.backgroundColor = UIColor(backgroundColor)
        textView.delegate = context.coordinator
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        
        // 精确控制内边距
        textView.textContainerInset = UIEdgeInsets(
            top: topPadding,
            left: horizontalPadding,
            bottom: topPadding,
            right: horizontalPadding
        )
        textView.textContainer.lineFragmentPadding = 0
        
        // 使用默认行高
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
            contentOffset = point
            onScrollChange(point)
        }
        
        textView.onLineHeightCallback = { height in
            onLineHeightChange(height)
        }
        
        // 计算初始行高
        calculateLineHeight(textView)
        
        return textView
    }
    
    func updateUIView(_ uiView: SuperPreciseTextView, context: Context) {
        // 更新文本内容
        if uiView.text != text {
            // 保存选择范围
            let selectedRange = uiView.selectedRange
            
            // 更新文本
            uiView.text = text
            
            // 恢复选择范围（如果可能）
            if selectedRange.location <= text.count {
                uiView.selectedRange = selectedRange
            }
            
            // 重新计算行高
            calculateLineHeight(uiView)
        }
        
        // 处理焦点状态
        if isFirstResponder && !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
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
        let textContainer = textView.textContainer
        
        guard layoutManager.numberOfGlyphs > 0 else { return }
        
        // 计算第一行的范围
        var lineRange = NSRange(location: 0, length: 1)
        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: 0, effectiveRange: &lineRange)
        
        // 将行高提供给回调
        textView.onLineHeightCallback?(lineRect.height)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFirstResponder: $isFirstResponder, onTap: onTap)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        @Binding var isFirstResponder: Bool
        var onTap: () -> Void
        
        init(text: Binding<String>, isFirstResponder: Binding<Bool>, onTap: @escaping () -> Void) {
            self._text = text
            self._isFirstResponder = isFirstResponder
            self.onTap = onTap
        }
        
        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
            
            // 计算行高并报告
            if let superTextView = textView as? SuperPreciseTextView {
                if let layoutManager = textView.layoutManager as? NSLayoutManager, 
                   layoutManager.numberOfGlyphs > 0 {
                    var lineRange = NSRange(location: 0, length: 1)
                    let lineRect = layoutManager.lineFragmentRect(forGlyphAt: 0, effectiveRange: &lineRange)
                    superTextView.onLineHeightCallback?(lineRect.height)
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
        if let layoutManager = self.layoutManager as? NSLayoutManager, 
           layoutManager.numberOfGlyphs > 0 && !text.isEmpty {
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
                showDebugInfo: true
            )
            .padding()
            .frame(height: 150)
            
            EnhancedTextDisplayView(
                text: .constant(""),
                placeholder: "请输入内容...",
                showDebugInfo: false
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