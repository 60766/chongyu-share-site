import SwiftUI

/**
 * TabBar行为测试视图
 * 用于测试和演示TabBar管理器的各种功能
 */
struct TabBarTest: View {
    @ObservedObject private var tabBarManager = TabBarManager.shared
    @State private var tabBarStateText: String = "正常状态"
    @State private var stackCount: Int = 0
    
    // 添加环境变量用于自定义返回按钮
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("TabBar管理器测试")
                    .font(.system(size: 22, weight: .bold))
                    .padding(.top, 20)
                
                // 当前状态显示
                VStack(spacing: 8) {
                    Text("当前状态: \(tabBarStateText)")
                        .font(.headline)
                    
                    Text("堆栈深度: \(stackCount)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("TabBar可见性: \(tabBarManager.isVisible ? "可见" : "隐藏")")
                        .font(.subheadline)
                        .foregroundColor(tabBarManager.isVisible ? .green : .orange)
                    
                    Text("TabBar物理状态: \(tabBarManager.isFullyHidden ? "完全移除" : "存在")")
                        .font(.subheadline)
                        .foregroundColor(tabBarManager.isFullyHidden ? .red : .green)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // 测试按钮
                Group {
                    // 推入隐藏状态
                    Button(action: {
                        tabBarManager.pushHideState()
                        updateState()
                    }) {
                        makeButtonLabel("推入隐藏状态", systemImage: "arrow.down.to.line")
                    }
                    
                    // 弹出隐藏状态
                    Button(action: {
                        tabBarManager.popHideState()
                        updateState()
                    }) {
                        makeButtonLabel("弹出隐藏状态", systemImage: "arrow.up.to.line")
                    }
                    
                    // 强制重置并显示
                    Button(action: {
                        tabBarManager.forceResetAndShow()
                        updateState()
                    }) {
                        makeButtonLabel("强制重置并显示", systemImage: "arrow.clockwise")
                    }
                    
                    // 仅视觉隐藏
                    Button(action: {
                        tabBarManager.hide()
                        updateState()
                    }) {
                        makeButtonLabel("视觉隐藏 (透明度)", systemImage: "eye.slash")
                    }
                    
                    // 物理隐藏
                    Button(action: {
                        tabBarManager.completelyHide()
                        updateState()
                    }) {
                        makeButtonLabel("物理隐藏 (移除)", systemImage: "trash")
                    }
                    
                    // 显示TabBar
                    Button(action: {
                        tabBarManager.show()
                        updateState()
                    }) {
                        makeButtonLabel("显示TabBar", systemImage: "eye")
                    }
                    
                    // 打印堆栈状态
                    Button(action: {
                        #if DEBUG
                        tabBarManager.printStackState()
                        #endif
                        updateState()
                    }) {
                        makeButtonLabel("打印堆栈状态", systemImage: "list.bullet")
                    }
                    
                    // 重新应用样式
                    Button(action: {
                        tabBarManager.applyConsistentStyle()
                        updateState()
                    }) {
                        makeButtonLabel("重新应用样式", systemImage: "wand.and.stars")
                    }
                }
                
                Spacer()
                    .frame(height: 100)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                // 自定义返回按钮
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("返回")
                            .font(.system(size: 17, weight: .regular))
                    }
                    .foregroundColor(.primaryColor)
                }
                .contentShape(Rectangle())
            }
            
            ToolbarItem(placement: .principal) {
                Text("TabBar调试")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .onAppear {
            updateState()
        }
    }
    
    // 更新状态显示
    private func updateState() {
        stackCount = tabBarManager.hideStateStack.count
        
        if tabBarManager.isFullyHidden {
            tabBarStateText = "完全隐藏状态"
        } else if !tabBarManager.isVisible {
            tabBarStateText = "视觉隐藏状态"
        } else {
            tabBarStateText = "正常显示状态"
        }
    }
    
    // 创建一致风格的按钮标签
    private func makeButtonLabel(_ text: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .font(.system(size: 16))
            Text(text)
                .font(.system(size: 16, weight: .medium))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

/**
 * Debug菜单视图
 * 包含各种调试工具和测试功能
 */
struct DebugMenu: View {
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToTabBarTest = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("TabBar测试")) {
                    NavigationLink(destination: TabBarTest()) {
                        HStack {
                            Image(systemName: "menubar.dock.rectangle")
                                .foregroundColor(.blue)
                            Text("TabBar状态测试")
                        }
                    }
                }
                
                Section(header: Text("其他调试工具")) {
                    Button {
                        // 打印当前环境信息
                        #if DEBUG
                        debugLog("当前环境: \(Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? "未知")")
                        #endif
                    } label: {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.green)
                            Text("打印环境信息")
                        }
                    }
                }
            }
            .navigationTitle("开发者菜单")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("返回")
                                .font(.system(size: 17, weight: .regular))
                        }
                        .foregroundColor(.primaryColor)
                    }
                }
            }
        }
    }
}

struct TabBarTest_Previews: PreviewProvider {
    static var previews: some View {
        DebugMenu()
    }
}
