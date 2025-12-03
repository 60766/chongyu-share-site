import SwiftUI
import Combine

/**
 * 键盘调试视图
 * 用于测试和展示各种键盘适配方案
 */
struct KeyboardDebugView: View {
    // 测试文本
    @State private var textInput = ""
    @State private var textInput2 = ""
    @State private var textInput3 = ""
    
    // 焦点状态
    @FocusState private var input1Focused: Bool
    @FocusState private var input2Focused: Bool
    @FocusState private var input3Focused: Bool
    
    // 键盘管理器
    @ObservedObject private var keyboardManager = KeyboardManager.shared
    
    // 配置选项
    @State private var adjustLayout: Bool = true
    @State private var dismissOnTap: Bool = true
    @State private var enableAnimation: Bool = true
    @State private var hapticFeedback: Bool = false
    @State private var safeArea: Double = 16 // 添加安全区域设置
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 标题
                Text("键盘适配调试")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                // 键盘状态信息
                VStack(spacing: 8) {
                    Text("键盘状态")
                        .font(.headline)
                    
                    HStack {
                        Text("可见性:")
                        Spacer()
                        Text(keyboardManager.isVisible ? "显示中" : "隐藏")
                            .foregroundColor(keyboardManager.isVisible ? .green : .secondary)
                    }
                    
                    HStack {
                        Text("高度:")
                        Spacer()
                        Text("\(Int(keyboardManager.height))pt")
                    }
                    
                    HStack {
                        Text("动画持续时间:")
                        Spacer()
                        Text(String(format: "%.2f秒", keyboardManager.animationDuration))
                    }
                    
                    HStack {
                        Text("动画曲线:")
                        Spacer()
                        Text(animationCurveName(keyboardManager.animationCurve))
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // 配置选项
                VStack(alignment: .leading, spacing: 8) {
                    Text("配置选项")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    Toggle("调整布局", isOn: $adjustLayout)
                    Toggle("点击空白处关闭键盘", isOn: $dismissOnTap)
                    Toggle("启用动画", isOn: $enableAnimation)
                    Toggle("触感反馈", isOn: $hapticFeedback)
                    
                    // 添加安全区域滑块
                    if dismissOnTap {
                        HStack {
                            Text("安全区域: \(Int(safeArea))pt")
                            Spacer()
                            Slider(value: $safeArea, in: 0...50, step: 1)
                                .frame(width: 150)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // 测试区域1 - 使用KeyboardAdaptive
                VStack(alignment: .leading, spacing: 8) {
                    Text("测试1: KeyboardAdaptive")
                        .font(.headline)
                    
                    TextField("KeyboardAdaptive测试", text: $textInput)
                        .focused($input1Focused)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(input1Focused ? Color.blue : Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .onTapGesture {
                            input1Focused = true
                        }
                    
                    Text("当前状态: \(input1Focused ? "已获取焦点" : "未获取焦点")")
                        .font(.caption)
                        .foregroundColor(input1Focused ? .green : .secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // 测试区域2 - 使用dismissKeyboardOnTap
                VStack(alignment: .leading, spacing: 8) {
                    Text("测试2: dismissKeyboardOnTap")
                        .font(.headline)
                    
                    TextField("dismissKeyboardOnTap测试", text: $textInput2)
                        .focused($input2Focused)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(input2Focused ? Color.blue : Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .onTapGesture {
                            input2Focused = true
                        }
                    
                    Text("当前状态: \(input2Focused ? "已获取焦点" : "未获取焦点")")
                        .font(.caption)
                        .foregroundColor(input2Focused ? .green : .secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                .dismissKeyboardOnTap(
                    notifyObservers: true,
                    hapticFeedback: hapticFeedback
                )
                
                // 测试区域3 - 使用KeyboardManager
                VStack(alignment: .leading, spacing: 8) {
                    Text("测试3: KeyboardManager")
                        .font(.headline)
                    
                    TextField("KeyboardManager测试", text: $textInput3)
                        .focused($input3Focused)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(input3Focused ? Color.blue : Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .onTapGesture {
                            input3Focused = true
                        }
                    
                    Text("当前状态: \(input3Focused ? "已获取焦点" : "未获取焦点")")
                        .font(.caption)
                        .foregroundColor(input3Focused ? .green : .secondary)
                    
                    Button("关闭键盘") {
                        keyboardManager.dismissKeyboard()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // 底部空白，确保内容可滚动
                Spacer()
                    .frame(height: 200)
            }
        }
        .navigationTitle("键盘调试")
        .keyboardAdaptive(
            enabled: true,
            adjustLayout: adjustLayout,
            dismissOnTap: dismissOnTap,
            animation: enableAnimation ? .easeInOut(duration: 0.25) : nil,
            safeArea: CGFloat(safeArea)
        )
        .onKeyboardHeightChange { height, isVisible in
            #if DEBUG
            print("键盘高度变化: \(height)pt, 可见性: \(isVisible)")
            #endif
        }
    }
    
    /**
     * 获取动画曲线名称
     */
    private func animationCurveName(_ curve: Int) -> String {
        switch curve {
        case UIView.AnimationCurve.easeIn.rawValue:
            return "easeIn (渐快)"
        case UIView.AnimationCurve.easeOut.rawValue:
            return "easeOut (渐慢)"
        case UIView.AnimationCurve.easeInOut.rawValue:
            return "easeInOut (渐快渐慢)"
        case UIView.AnimationCurve.linear.rawValue:
            return "linear (线性)"
        default:
            return "未知曲线(\(curve))"
        }
    }
}

/**
 * 预览
 */
struct KeyboardDebugView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            KeyboardDebugView()
        }
    }
} 