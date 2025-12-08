import SwiftUI
import UIKit

/**
 * 发布面板测试视图
 * 用于测试不同的文本输入实现
 */
struct PublishPanelTestView: View {
    @State private var showingPanel = false
    @State private var inputOption = 0
    
    var body: some View {
        VStack(spacing: 24) {
            Text("发布面板测试")
                .font(.headline)
            
            Picker("输入组件", selection: $inputOption) {
                Text("原生TextEditor").tag(0)
                Text("DirectTextInput").tag(1)
                Text("SimpleInputArea").tag(2)
                Text("HighlightableTextField").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            Button("显示测试面板") {
                showingPanel = true
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            // 当前选择的输入组件说明
            Group {
                switch inputOption {
                case 0:
                    Text("原生TextEditor: SwiftUI内置组件，功能完整但可能存在兼容性问题")
                case 1:
                    Text("DirectTextInput: 使用UITextView封装的自定义组件，直接处理点击和焦点")
                case 2:
                    Text("SimpleInputArea: 基于TextField的轻量实现，可能具有更好的兼容性")
                case 3:
                    Text("HighlightableTextField: 增强型TextField，添加了视觉反馈")
                default:
                    Text("未知选项")
                }
            }
            .font(.caption)
            .multilineTextAlignment(.center)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 40)
        .overlay(
            TestPublishPanelView(isVisible: $showingPanel, inputOption: inputOption)
                .ignoresSafeArea(.all, edges: .bottom)
        )
    }
}

/**
 * 测试用发布面板视图
 * 允许切换不同的输入组件实现
 */
struct TestPublishPanelView: View {
    // 绑定和状态变量
    @Binding var isVisible: Bool
    @State private var contentText: String = ""
    @State private var selectedCharacters: [CharacterModel] = []
    @State private var selectedEra: String = "现代"
    let inputOption: Int
    
    // 简化的内部状态
    @State private var simpleInputFocused = false
    @State private var directInputFocused = false
    @State private var highlightableFocused = false
    @FocusState private var textEditorFocused: Bool
    
    // 时代选项
    private let eras = ["现代", "古代", "中世纪", "文艺复兴", "启蒙运动", "未来"]
    
    var body: some View {
        ZStack {
            // 背景蒙版
            if isVisible {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        hideKeyboard()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isVisible = false
                        }
                    }
            }
            
            // 主面板
            VStack(spacing: 0) {
                Spacer()
                
                // 面板内容
                VStack(spacing: 0) {
                    // 顶部拖拽条
                    Rectangle()
                        .frame(width: 40, height: 4)
                        .foregroundColor(Color.gray.opacity(0.3))
                        .padding(.vertical, 12)
                    
                    // 内容输入区域
                    contentInputArea
                    
                    // 时代选择器
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(eras, id: \.self) { era in
                                Button(action: {
                                    selectedEra = era
                                }) {
                                    Text(era)
                                        .font(.system(size: 14))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(selectedEra == era ? Color.blue : Color.gray.opacity(0.1))
                                        )
                                        .foregroundColor(selectedEra == era ? .white : .primary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // 底部工具栏
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            contentText = ""
                        }) {
                            Text("清空")
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 16)
                        
                        Button(action: {
                            hideKeyboard()
                            withAnimation {
                                isVisible = false
                            }
                        }) {
                            Text("关闭")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(22)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .padding(.horizontal, 12)
                .background(
                    Color(.systemBackground)
                        .debugCornerRadius(24, corners: [.topLeft, .topRight])
                        .shadow(color: Color.black.opacity(0.1), radius: 10, y: -5)
                )
                .offset(y: isVisible ? 0 : UIScreen.main.bounds.height)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isVisible)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // 内容输入区域 - 根据用户选择显示不同的输入组件
    private var contentInputArea: some View {
        VStack(spacing: 16) {
            // 标题
            Text("输入测试 - \(getInputComponentName())")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            
            // 显示当前文字内容和长度
            HStack {
                VStack(alignment: .leading) {
                    Text("文字长度: \(contentText.count)")
                    Text("内容: \(contentText.isEmpty ? "(空)" : contentText)")
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Spacer()
                
                // 显示焦点状态
                Circle()
                    .fill(getFocusStateColor())
                    .frame(width: 14, height: 14)
            }
            .padding(.horizontal, 16)
            
            // 不同的输入组件
            Group {
                switch inputOption {
                case 0: // 原生TextEditor
                    nativeTextEditor
                case 1: // DirectTextInput
                    directTextInputView
                case 2: // SimpleInputArea
                    simpleInputAreaView
                case 3: // HighlightableTextField
                    highlightableTextFieldView
                default:
                    nativeTextEditor
                }
            }
            .frame(height: 120)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .padding(.bottom, 16)
    }
    
    // 原生TextEditor
    private var nativeTextEditor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $contentText)
                .focused($textEditorFocused)
                .frame(height: 120)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            if contentText.isEmpty {
                Text("请输入内容...")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 5)
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }
        }
        .background(Color.yellow.opacity(0.1))
    }
    
    // DirectTextInput
    private var directTextInputView: some View {
        DirectTextInput(
            text: $contentText,
            placeholder: "请输入内容...",
            onFocus: { focused in
                directInputFocused = focused
                #if DEBUG
                debugLog("DirectTextInput焦点变化: \(focused)")
                #endif
            },
            debug: true
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(directInputFocused ? Color.blue : Color.gray, lineWidth: 1)
        )
        .background(Color.blue.opacity(0.1))
    }
    
    // SimpleInputArea
    private var simpleInputAreaView: some View {
        SimpleInputArea(
            text: $contentText,
            placeholder: "请输入内容...",
            isFocused: $simpleInputFocused,
            debug: true
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(simpleInputFocused ? Color.blue : Color.gray, lineWidth: 1)
        )
        .background(Color.green.opacity(0.1))
    }
    
    // HighlightableTextField
    private var highlightableTextFieldView: some View {
        HighlightableTextField(
            text: $contentText,
            placeholder: "请输入内容...",
            isFocused: $highlightableFocused,
            debug: true
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(highlightableFocused ? Color.blue : Color.gray, lineWidth: 1)
        )
        .background(Color.purple.opacity(0.1))
    }
    
    // 辅助方法
    private func getInputComponentName() -> String {
        switch inputOption {
        case 0: return "原生TextEditor"
        case 1: return "DirectTextInput"
        case 2: return "SimpleInputArea"
        case 3: return "HighlightableTextField"
        default: return "未知组件"
        }
    }
    
    private func getFocusStateColor() -> Color {
        switch inputOption {
        case 0: return textEditorFocused ? .green : .red
        case 1: return directInputFocused ? .green : .red
        case 2: return simpleInputFocused ? .green : .red
        case 3: return highlightableFocused ? .green : .red
        default: return .gray
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// 扩展用于圆角指定角落
extension View {
    func debugCornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(DebugRoundedCorner(radius: radius, corners: corners))
    }
}

struct DebugRoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, 
                                byRoundingCorners: corners, 
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct PublishPanelTestView_Previews: PreviewProvider {
    static var previews: some View {
        PublishPanelTestView()
    }
} 