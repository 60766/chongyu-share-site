import SwiftUI

/**
 * 设置页视图
 * 用于配置应用的各种设置选项
 */
struct SettingsView: View {
    /// 是否开启角色互动通知
    @State private var enableCharacterNotification = true
    /// 角色互动方式
    @State private var interactionMethod = "语音+文字"
    /// 暗黑模式选项
    @State private var darkModeOption = "跟随系统"
    /// 清除缓存按钮状态
    @State private var isClearingCache = false
    /// 关于我们展示状态
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            List {
                // 角色互动设置
                Section(header: Text("角色互动设置")) {
                    // 开启角色互动通知
                    Toggle(isOn: $enableCharacterNotification) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .frame(width: 24)
                                .foregroundColor(.primaryColor)
                            
                            Text("开启角色互动通知")
                                .foregroundColor(.primary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .primaryColor))
                    
                    // 角色互动方式
                    NavigationLink(destination: InteractionMethodView(selectedMethod: $interactionMethod)) {
                        HStack {
                            Image(systemName: "bubble.left.fill")
                                .frame(width: 24)
                                .foregroundColor(.primaryColor)
                            
                            Text("角色互动方式")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(interactionMethod)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 系统设置
                Section(header: Text("系统设置")) {
                    // 暗黑模式
                    NavigationLink(destination: DarkModeSettingView(selectedOption: $darkModeOption)) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .frame(width: 24)
                                .foregroundColor(.primaryColor)
                            
                            Text("暗黑模式")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(darkModeOption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 清除缓存
                    Button(action: {
                        clearCache()
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .frame(width: 24)
                                .foregroundColor(.primaryColor)
                            
                            Text("清除缓存")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if isClearingCache {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("25.6MB")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // 账号设置
                Section(header: Text("账号设置")) {
                    // 账号与安全
                    NavigationLink(destination: Text("账号与安全设置")) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .frame(width: 24)
                                .foregroundColor(.primaryColor)
                            
                            Text("账号与安全")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // 隐私设置
                    NavigationLink(destination: Text("隐私设置")) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .frame(width: 24)
                                .foregroundColor(.primaryColor)
                            
                            Text("隐私设置")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                // 帮助和关于
                Section(header: Text("帮助和关于")) {
                    // 联系我们
                    NavigationLink(destination: Text("联系我们")) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .frame(width: 24)
                                .foregroundColor(.primaryColor)
                            
                            Text("联系我们")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // 关于我们
                    Button(action: {
                        showingAbout = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .frame(width: 24)
                                .foregroundColor(.primaryColor)
                            
                            Text("关于虫遇")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("v1.0.0")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 退出登录
                Section {
                    Button(action: {
                        // 退出登录操作
                    }) {
                        HStack {
                            Spacer()
                            Text("退出登录")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("设置")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
            .alert(isPresented: $showingAbout) {
                Alert(
                    title: Text("关于虫遇"),
                    message: Text("虫遇 v1.0.0\n一款让你与历史人物进行对话的应用\n技术支持: support@chongyu.com"),
                    dismissButton: .default(Text("确定"))
                )
            }
        }
    }
    
    /**
     * 清除缓存
     */
    private func clearCache() {
        isClearingCache = true
        
        // 模拟清除缓存过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isClearingCache = false
            
            // 显示清除成功提示
            // 在实际应用中，这里应该有真实的缓存清理逻辑
        }
    }
}

/**
 * 互动方式设置视图
 */
struct InteractionMethodView: View {
    @Binding var selectedMethod: String
    private let methods = ["仅文字", "语音+文字", "语音优先"]
    
    var body: some View {
        List {
            ForEach(methods, id: \.self) { method in
                Button(action: {
                    selectedMethod = method
                }) {
                    HStack {
                        Text(method)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedMethod == method {
                            Image(systemName: "checkmark")
                                .foregroundColor(.primaryColor)
                        }
                    }
                }
            }
        }
        .navigationTitle("角色互动方式")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/**
 * 暗黑模式设置视图
 */
struct DarkModeSettingView: View {
    @Binding var selectedOption: String
    private let options = ["开启", "关闭", "跟随系统"]
    
    var body: some View {
        List {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selectedOption = option
                }) {
                    HStack {
                        Text(option)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedOption == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(.primaryColor)
                        }
                    }
                }
            }
        }
        .navigationTitle("暗黑模式")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/**
 * 设置页预览
 */
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 