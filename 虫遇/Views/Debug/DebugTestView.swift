import SwiftUI

/**
 * 调试测试视图
 * 用于测试项目中各种组件的性能和可靠性
 */
struct DebugTestView: View {
    @State private var showSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("调试测试工具")
                    .font(.headline)
                
                Button("测试文本输入组件") {
                    showSheet = true
                }
                .buttonStyle(.borderedProminent)
                .padding()
                
                NavigationLink(destination: InputDebugView()) {
                    Text("打开输入调试视图")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                NavigationLink(destination: TextComponentComparisonView()) {
                    Text("文本组件比较")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
                
                NavigationLink(destination: PublishPanelTestView()) {
                    Text("发布面板测试")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // 添加键盘调试视图入口
                NavigationLink(destination: KeyboardDebugView()) {
                    Text("键盘行为调试")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                }

                // 添加点击事件调试视图入口
                NavigationLink(destination: TouchDebugView()) {
                    Text("点击事件调试")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.pink.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                // 调试信息
                Text("长按屏幕顶部区域可随时打开调试面板")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("调试测试")
            .sheet(isPresented: $showSheet) {
                NavigationView {
                    InputDebugView()
                        .navigationTitle("输入组件测试")
                        .navigationBarItems(
                            trailing: Button("关闭") { showSheet = false }
                        )
                }
            }
        }
    }
}

/**
 * 文本组件比较视图
 * 同时展示和比较多种文本输入组件的行为
 */
struct TextComponentComparisonView: View {
    @State private var textEditorText = ""
    @State private var simpleInputText = ""
    @State private var directInputText = ""
    @State private var highlightableText = ""
    
    @State private var simpleInputFocused = false
    @State private var directInputFocused = false
    @State private var highlightableFocused = false
    
    @FocusState private var textEditorFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("输入组件比较")
                    .font(.headline)
                
                Group {
                    // 原生 TextEditor
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("原生 TextEditor")
                                .font(.subheadline)
                            Spacer()
                            Text(textEditorFocused ? "已获取焦点" : "未获取焦点")
                                .font(.caption)
                                .foregroundColor(textEditorFocused ? .green : .gray)
                        }
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $textEditorText)
                                .focused($textEditorFocused)
                                .frame(height: 100)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(textEditorFocused ? Color.blue : Color.gray, lineWidth: 1)
                                )
                            
                            if textEditorText.isEmpty {
                                Text("请输入内容...")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 5)
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                        .background(Color.yellow.opacity(0.1))
                    }
                    .padding(.horizontal)
                    
                    // SimpleInputArea
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("SimpleInputArea")
                                .font(.subheadline)
                            Spacer()
                            Text(simpleInputFocused ? "已获取焦点" : "未获取焦点")
                                .font(.caption)
                                .foregroundColor(simpleInputFocused ? .green : .gray)
                        }
                        
                        SimpleInputArea(
                            text: $simpleInputText,
                            placeholder: "请输入内容...",
                            isFocused: $simpleInputFocused,
                            debug: true
                        )
                        .frame(height: 100)
                        .background(Color.green.opacity(0.1))
                    }
                    .padding(.horizontal)
                    
                    // DirectTextInput
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("DirectTextInput")
                                .font(.subheadline)
                            Spacer()
                            Text(directInputFocused ? "已获取焦点" : "未获取焦点")
                                .font(.caption)
                                .foregroundColor(directInputFocused ? .green : .gray)
                        }
                        
                        DirectTextInput(
                            text: $directInputText,
                            placeholder: "请输入内容...",
                            onFocus: { focused in
                                directInputFocused = focused
                            },
                            debug: true
                        )
                        .frame(height: 100)
                        .background(Color.blue.opacity(0.1))
                    }
                    .padding(.horizontal)
                    
                    // HighlightableTextField (如果存在)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("HighlightableTextField")
                                .font(.subheadline)
                            Spacer()
                            Text(highlightableFocused ? "已获取焦点" : "未获取焦点")
                                .font(.caption)
                                .foregroundColor(highlightableFocused ? .green : .gray)
                        }
                        
                        HighlightableTextField(
                            text: $highlightableText,
                            placeholder: "请输入内容...",
                            isFocused: $highlightableFocused,
                            debug: true
                        )
                        .frame(height: 100)
                        .background(Color.purple.opacity(0.1))
                    }
                    .padding(.horizontal)
                }
                
                // 输入状态显示
                VStack(alignment: .leading, spacing: 8) {
                    Text("当前输入状态:")
                        .font(.subheadline)
                    
                    Group {
                        Text("TextEditor: \"\(textEditorText)\"")
                        Text("SimpleInput: \"\(simpleInputText)\"")
                        Text("DirectInput: \"\(directInputText)\"")
                        Text("Highlightable: \"\(highlightableText)\"")
                    }
                    .font(.caption)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                
                // 控制按钮
                HStack {
                    Button("清空全部") {
                        textEditorText = ""
                        simpleInputText = ""
                        directInputText = ""
                        highlightableText = ""
                    }
                    .buttonStyle(.bordered)
                    
                    Button("全部复制到第一个") {
                        let combinedText = "TextEditor: \(textEditorText)\nSimpleInput: \(simpleInputText)\nDirectInput: \(directInputText)\nHighlightable: \(highlightableText)"
                        textEditorText = combinedText
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .padding(.vertical)
        }
        .navigationTitle("组件比较")
    }
}

struct DebugTestView_Previews: PreviewProvider {
    static var previews: some View {
        DebugTestView()
    }
} 