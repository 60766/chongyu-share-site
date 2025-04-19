import SwiftUI

/**
 * 超简化文本编辑器
 * 专门用于解决文本不显示问题的最小实现
 */
struct BasicTextEditor: View {
    @Binding var text: String
    var placeholder: String
    @Binding var isFocused: Bool
    
    // 内部焦点状态
    @FocusState private var internalFocus: Bool
    
    var body: some View {
        // 使用极简实现，确保文本显示
        ZStack(alignment: .topLeading) {
            // 极简TextEditor - 移除所有可能影响文本显示的修饰符
            TextEditor(text: $text)
                .focused($internalFocus)
                .font(.system(size: 16))
                // 仅保留必要的设置
                .background(Color(UIColor.systemBackground))
                // 移除其他所有修饰符
            
            // 占位符
            if text.isEmpty && !internalFocus {
                Text(placeholder)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding(.leading, 4)
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }
        }
        .onTapGesture {
            internalFocus = true
        }
        .onChange(of: internalFocus) { _, newValue in
            // 更新外部焦点状态
            isFocused = newValue
            
            // 打印调试信息
            print("TextEditor焦点状态: \(newValue ? "获得焦点" : "失去焦点")")
            print("当前文本: \"\(text)\"")
        }
        .onChange(of: isFocused) { _, newValue in
            if internalFocus != newValue {
                internalFocus = newValue
            }
        }
        .onChange(of: text) { _, newValue in
            // 打印调试信息，监控文本变化
            print("文本已更新为: \"\(newValue)\"")
        }
    }
}

// 预览
struct BasicTextEditor_Previews: PreviewProvider {
    @State static var text = ""
    @State static var isFocused = false
    
    static var previews: some View {
        VStack {
            BasicTextEditor(
                text: $text,
                placeholder: "请输入内容...",
                isFocused: $isFocused
            )
            .frame(height: 120)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.blue : Color.gray, lineWidth: 1)
            )
            .padding()
            
            Text("当前文本: \(text)")
                .padding()
            
            Button("添加测试文本") {
                text = "测试文本 " + Date().formatted()
            }
            .padding()
        }
    }
} 