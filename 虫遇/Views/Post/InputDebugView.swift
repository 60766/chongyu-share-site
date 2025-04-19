import SwiftUI

/**
 * 输入调试专用视图
 * 用于诊断文本输入相关问题
 */
public struct InputDebugView: View {
    @StateObject private var debugState = InputDebugState()
    
    // 使用 FocusState 而不是 Binding
    @FocusState private var textFieldIsFocused: Bool
    @FocusState private var textEditorIsFocused: Bool
    
    // 公开初始化方法
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            Text("输入组件测试")
                .font(.headline)
            
            // 测试区
            Group {
                Text("1. 原生TextField（推荐）")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                testTextField
                
                Text("2. 原生TextEditor")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                testTextEditor
                
                Text("3. 简化版输入区域")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                testSimpleInput
            }
            
            // 状态显示
            statusSection
            
            // 控制按钮
            controlButtons
        }
        .padding()
        .onChange(of: textFieldIsFocused) { oldValue, newValue in
            debugState.textFieldFocused = newValue
        }
        .onChange(of: textEditorIsFocused) { oldValue, newValue in
            debugState.textEditorFocused = newValue
        }
    }
    
    // TextField测试
    private var testTextField: some View {
        VStack {
            TextField("输入文字", text: $debugState.textFieldText)
                .focused($textFieldIsFocused)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(textFieldIsFocused ? Color.blue : Color.gray, lineWidth: 1)
                )
                .onChange(of: textFieldIsFocused) { oldValue, newValue in
                    print("TextField焦点状态: \(newValue)")
                }
                .padding(.horizontal)
        }
    }
    
    // TextEditor测试
    private var testTextEditor: some View {
        VStack {
            TextEditor(text: $debugState.textEditorText)
                .focused($textEditorIsFocused)
                .frame(height: 100)
                .padding(.horizontal, 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(textEditorIsFocused ? Color.blue : Color.gray, lineWidth: 1)
                )
                .onChange(of: textEditorIsFocused) { oldValue, newValue in
                    print("TextEditor焦点状态: \(newValue)")
                }
                .padding(.horizontal)
        }
    }
    
    // 简化版输入区域
    private var testSimpleInput: some View {
        VStack {
            SimpleInputArea(
                text: $debugState.simpleInputText,
                placeholder: "点击输入文字",
                isFocused: $debugState.simpleInputFocused,
                debug: true
            )
            .padding(.horizontal)
            .onChange(of: debugState.simpleInputFocused) { oldValue, newValue in
                print("SimpleInput焦点状态: \(newValue)")
            }
        }
    }
    
    // 状态显示区域
    private var statusSection: some View {
        GroupBox(label: Text("当前状态").font(.caption)) {
            VStack(alignment: .leading, spacing: 6) {
                Text("TextField: \"\(debugState.textFieldText)\" (焦点: \(debugState.textFieldFocused ? "是" : "否"))")
                Text("TextEditor: \"\(debugState.textEditorText)\" (焦点: \(debugState.textEditorFocused ? "是" : "否"))")
                Text("SimpleInput: \"\(debugState.simpleInputText)\" (焦点: \(debugState.simpleInputFocused ? "是" : "否"))")
            }
            .font(.system(size: 12))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
    }
    
    // 控制按钮
    private var controlButtons: some View {
        HStack(spacing: 20) {
            Button("清空内容") {
                debugState.clearText()
            }
            .buttonStyle(.bordered)
            
            Button("切换焦点") {
                debugState.cycleFocus()
                
                // 手动更新FocusState
                if debugState.textFieldFocused {
                    textFieldIsFocused = true
                    textEditorIsFocused = false
                } else if debugState.textEditorFocused {
                    textFieldIsFocused = false
                    textEditorIsFocused = true
                } else {
                    textFieldIsFocused = false
                    textEditorIsFocused = false
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

/**
 * 输入调试状态管理
 */
class InputDebugState: ObservableObject {
    // TextField
    @Published var textFieldText: String = ""
    @Published var textFieldFocused: Bool = false
    
    // TextEditor
    @Published var textEditorText: String = ""
    @Published var textEditorFocused: Bool = false
    
    // SimpleInput
    @Published var simpleInputText: String = ""
    @Published var simpleInputFocused: Bool = false
    
    // 清空所有文本
    func clearText() {
        textFieldText = ""
        textEditorText = ""
        simpleInputText = ""
    }
    
    // 循环切换焦点
    func cycleFocus() {
        if textFieldFocused {
            textFieldFocused = false
            textEditorFocused = true
            simpleInputFocused = false
        } else if textEditorFocused {
            textFieldFocused = false
            textEditorFocused = false
            simpleInputFocused = true
        } else if simpleInputFocused {
            textFieldFocused = true
            textEditorFocused = false
            simpleInputFocused = false
        } else {
            textFieldFocused = true
            textEditorFocused = false
            simpleInputFocused = false
        }
    }
}

// 预览提供者
struct InputDebugView_Previews: PreviewProvider {
    static var previews: some View {
        InputDebugView()
    }
} 