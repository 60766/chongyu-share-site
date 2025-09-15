import SwiftUI

/**
 * 设置页视图
 * 用于配置应用的各种设置选项
 */
struct SettingsView: View {
    /// 环境变量，用于关闭sheet
    @Environment(\.dismiss) private var dismiss
    
    /// 是否开启角色互动通知
    @State private var enableCharacterNotification = true
    /// 角色互动方式
    @State private var interactionMethod = "语音+文字"
    /// 暗黑模式选项
    @State private var darkModeOption = "跟随系统"
    /// 角色分配模式
    @State private var characterDistributionMode = "均衡分配"
    /// 清除缓存按钮状态
    @State private var isClearingCache = false
    /// 关于我们展示状态
    @State private var showingAbout = false
    /// API设置展示状态
    @State private var showingAPISettings = false
    @State private var balanceText: String = "—"
    
    // 在初始化时加载当前的角色分配模式
    init() {
        let mode = CharacterRotationSystem.shared.currentMode
        let modeName: String
        switch mode {
        case .equal:
            modeName = "均衡分配"
        case .strictRotation:
            modeName = "严格轮换"
        case .preferenceBase:
            modeName = "关注优先"
        }
        _characterDistributionMode = State(initialValue: modeName)
    }
    
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
                    
                    // 角色分配模式
                    NavigationLink(destination: CharacterDistributionModeView(selectedMode: $characterDistributionMode)) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .frame(width: 24)
                                .foregroundColor(.primaryColor)
                            
                            Text("角色分配模式")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(characterDistributionMode)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 已屏蔽角色管理
                    NavigationLink(destination: BlockedCharactersView()) {
                        HStack {
                            Image(systemName: "hand.thumbsdown")
                                .frame(width: 24)
                                .foregroundColor(.primaryColor)
                            
                            Text("已屏蔽角色")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // 显示已屏蔽角色数量
                            if let blockedCount = getBlockedCharactersCount(), blockedCount > 0 {
                                Text("\(blockedCount)个已屏蔽")
                                    .foregroundColor(.orange)
                            }
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
                    
                    // 内容偏好设置
                    NavigationLink(destination: ContentPreferencesView()) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .frame(width: 24)
                                .foregroundColor(.primaryColor)
                            
                            Text("内容偏好")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // 显示已减少的内容类型数量
                            if let reducedTypes = getReducedContentTypesCount(), reducedTypes > 0 {
                                Text("\(reducedTypes)种已调整")
                                    .foregroundColor(.orange)
                            }
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
                    
                    // API设置
                    NavigationLink(destination: APISettingsView()) {
                        HStack {
                            Image(systemName: "key.fill")
                                .frame(width: 24)
                                .foregroundColor(.primaryColor)
                            
                            Text("API密钥设置")
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
            .navigationBarTitle("设置", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    // 触觉反馈
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("返回")
                    }
                    .foregroundColor(.primaryColor)
                }
            )
            .onAppear {
                print("SettingsView已显示")
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
    
    /**
     * 获取已减少权重的内容类型数量
     * @return 已减少权重的内容类型数量，如果没有则返回nil
     */
    private func getReducedContentTypesCount() -> Int? {
        let reducedTypes = ContentTypeWeightManager.shared.getAllReducedContentTypes()
        if reducedTypes.isEmpty {
            return nil
        }
        return reducedTypes.count
    }
    
    /**
     * 获取已屏蔽角色的数量
     * @return 已屏蔽角色的数量，如果没有则返回nil
     */
    private func getBlockedCharactersCount() -> Int? {
        let blockedCharacters = CharacterRotationSystem.shared.getAllDislikedCharacters()
        if blockedCharacters.isEmpty {
            return nil
        }
        return blockedCharacters.count
    }
}

/**
 * API密钥设置视图
 */
struct APISettingsView: View {
    @State private var apiKey: String = APIConfigManager.shared.apiKey ?? ""
    @State private var showSuccess = false
    @State private var showError = false
    @State private var selectedEndpoint = APIConfigManager.shared.currentEndpointIndex
    
    var body: some View {
        Form {
            Section(header: Text("API密钥配置"), footer: Text("请输入有效的API密钥，支持DeepSeek和ARK两种格式")) {
                SecureField("API密钥", text: $apiKey)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Button(action: {
                    if apiKey.isEmpty {
                        showError = true
                    } else {
                        APIConfigManager.shared.setAPIKey(apiKey)
                        showSuccess = true
                    }
                }) {
                    Text("保存API密钥")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .background(Color.primaryColor)
                        .cornerRadius(8)
                }
            }
            
            Section(header: Text("API端点选择")) {
                Picker("API端点", selection: $selectedEndpoint) {
                    Text("DeepSeek").tag(0)
                    Text("ARK").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedEndpoint) { oldValue, newValue in
                    if newValue != APIConfigManager.shared.currentEndpointIndex {
                        APIConfigManager.shared.switchEndpoint()
                    }
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("当前API端点:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(APIConfigManager.shared.deepSeekEndpoint)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 5)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("当前模型:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(APIConfigManager.shared.modelName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 5)
            }
        }
        .navigationTitle("API设置")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showSuccess) {
            Alert(
                title: Text("成功"),
                message: Text("API密钥已成功保存"),
                dismissButton: .default(Text("确定"))
            )
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("错误"),
                message: Text("请输入有效的API密钥"),
                dismissButton: .default(Text("确定"))
            )
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
 * 角色分配模式设置视图
 */
struct CharacterDistributionModeView: View {
    @Binding var selectedMode: String
    private let modes = ["均衡分配", "严格轮换", "关注优先"]
    
    var body: some View {
        List {
            // 模式说明
            Section(header: Text("模式说明")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("均衡分配")
                        .font(.headline)
                    Text("根据使用频率平衡分配角色，确保各角色出现机会均等，但可能会在短期内看到重复角色")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("严格轮换")
                        .font(.headline)
                        .padding(.top, 5)
                    Text("确保每个角色仅出现一次，直到所有角色都展示过后才重新开始循环，最大化角色多样性")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("关注优先")
                        .font(.headline)
                        .padding(.top, 5)
                    Text("优先展示您关注的角色，同时保持一定程度的多样性（尚未完全开放）")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 5)
            }
            
            // 模式选择
            Section(header: Text("选择模式")) {
                ForEach(modes, id: \.self) { mode in
                    Button(action: {
                        selectedMode = mode
                        
                        // 切换角色分配模式
                        switch mode {
                        case "均衡分配":
                            CharacterRotationSystem.shared.switchToMode(.equal)
                        case "严格轮换":
                            CharacterRotationSystem.shared.switchToMode(.strictRotation)
                        case "关注优先":
                            CharacterRotationSystem.shared.switchToMode(.preferenceBase)
                        default:
                            break
                        }
                    }) {
                        HStack {
                            Text(mode)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.primaryColor)
                            }
                        }
                    }
                }
            }
            
            // 重置轮换状态
            Section {
                Button(action: {
                    CharacterRotationSystem.shared.resetRotationState()
                }) {
                    HStack {
                        Spacer()
                        Text("重置轮换状态")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            } footer: {
                Text("重置将清除所有角色使用记录，所有角色将重新开始轮换")
                    .font(.caption)
            }
        }
        .navigationTitle("角色分配模式")
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