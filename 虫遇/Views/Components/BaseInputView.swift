import SwiftUI

/**
 * 基础输入组件协议
 * 定义统一的输入组件行为
 */
protocol BaseInputViewProtocol {
    /// 输入文本
    var text: String { get set }
    
    /// 占位符文本
    var placeholder: String { get }
    
    /// 焦点状态
    var isFocused: Bool { get set }
    
    /// 调试模式
    var debug: Bool { get }
}

/**
 * 基础输入组件配置
 * 提供统一的配置选项
 */
struct BaseInputConfig {
    /// 最小高度
    var minHeight: CGFloat = 100
    
    /// 内边距
    var padding: CGFloat = 12
    
    /// 圆角半径
    var cornerRadius: CGFloat = 10
    
    /// 边框宽度
    var borderWidth: CGFloat = 1
    
    /// 字体大小
    var fontSize: CGFloat = 16
    
    /// 是否显示完成按钮
    var showDoneButton: Bool = true
    
    /// 是否启用触觉反馈
    var hapticFeedback: Bool = true
}

/**
 * 基础输入组件样式
 * 提供统一的视觉样式
 */
struct BaseInputStyle {
    /// 背景色
    var backgroundColor: Color = Color(.systemBackground)
    
    /// 边框颜色
    var borderColor: Color = Color.gray.opacity(0.5)
    
    /// 焦点边框颜色
    var focusedBorderColor: Color = Color.blue
    
    /// 文本颜色
    var textColor: Color = .primary
    
    /// 占位符颜色
    var placeholderColor: Color = Color.gray.opacity(0.8)
}

/**
 * 基础输入组件
 * 提供统一的输入组件实现
 */
struct BaseInputView<Content: View>: View, BaseInputViewProtocol {
    // MARK: - 属性
    
    /// 输入文本
    @Binding var text: String
    
    /// 占位符文本
    var placeholder: String
    
    /// 焦点状态
    @Binding var isFocused: Bool
    
    /// 调试模式
    var debug: Bool = false
    
    /// 配置
    var config: BaseInputConfig = BaseInputConfig()
    
    /// 样式
    var style: BaseInputStyle = BaseInputStyle()
    
    /// 内容视图
    let content: () -> Content
    
    // MARK: - 内部状态
    
    /// 内部焦点状态
    @FocusState private var internalFocus: Bool
    
    // MARK: - 初始化
    
    init(
        text: Binding<String>,
        placeholder: String,
        isFocused: Binding<Bool>,
        debug: Bool = false,
        config: BaseInputConfig = BaseInputConfig(),
        style: BaseInputStyle = BaseInputStyle(),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._text = text
        self.placeholder = placeholder
        self._isFocused = isFocused
        self.debug = debug
        self.config = config
        self.style = style
        self.content = content
    }
    
    // MARK: - 视图
    
    var body: some View {
        VStack(spacing: 0) {
            // 内容视图
            content()
                .focused($internalFocus)
                .frame(minHeight: config.minHeight)
                .padding(config.padding)
                .background(style.backgroundColor)
                .cornerRadius(config.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: config.cornerRadius)
                        .stroke(internalFocus ? style.focusedBorderColor : style.borderColor,
                                lineWidth: internalFocus ? config.borderWidth + 1 : config.borderWidth)
                )
                .onTapGesture {
                    if debug {
                        #if DEBUG
                        print("输入区域被点击")
                        #endif
                    }
                    internalFocus = true
                    isFocused = true
                    
                    // 触觉反馈
                    if config.hapticFeedback {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }
                }
            
            // 调试信息
            if debug {
                HStack {
                    Text("文本长度: \(text.count) 字符")
                        .font(.system(size: 12))
                        .foregroundColor(Color.gray)
                    
                    Spacer()
                    
                    Text("状态: \(internalFocus ? "编辑中" : "未编辑")")
                        .font(.system(size: 12))
                        .foregroundColor(internalFocus ? Color.blue : Color.gray)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
            }
        }
        .onAppear {
            if debug {
                #if DEBUG
                print("BaseInputView出现，初始文本: '\(text)'")
                #endif
            }
            
            // 同步焦点状态
            DispatchQueue.main.async {
                internalFocus = isFocused
            }
        }
        .onChange(of: internalFocus) { oldValue, newValue in
            if debug {
                #if DEBUG
                print("BaseInputView焦点状态变化: \(newValue)")
                #endif
            }
            isFocused = newValue
        }
        .onChange(of: isFocused) { oldValue, newValue in
            if newValue != internalFocus {
                internalFocus = newValue
            }
        }
    }
}

// MARK: - 预览

struct BaseInputView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BaseInputView(
                text: .constant(""),
                placeholder: "请输入文本",
                isFocused: .constant(false),
                debug: true
            ) {
                TextField("", text: .constant(""))
                    .font(.system(size: 16))
            }
            
            BaseInputView(
                text: .constant(""),
                placeholder: "请输入文本",
                isFocused: .constant(false),
                debug: true
            ) {
                TextEditor(text: .constant(""))
                    .font(.system(size: 16))
            }
        }
        .padding()
    }
} 