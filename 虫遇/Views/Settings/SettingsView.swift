import SwiftUI

/**
 * 设置页视图
 * 用于配置应用的各种设置选项
 */
struct SettingsView: View {
    /// 环境变量，用于关闭sheet
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
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
    
    // 优化的颜色系统
    private var primaryAccentColor: Color {
        Color(hex: "9A8BB0") // 统一的主题色
    }
    
    private var iconColors: [String: Color] {
        [
            "character": Color(hex: "8B7EC8"),      // 紫色 - 角色相关
            "system": Color(hex: "5C9BD5"),         // 蓝色 - 系统设置
            "security": Color(hex: "E67E22"),       // 橙色 - 安全相关
            "help": Color(hex: "27AE60"),           // 绿色 - 帮助支持
            "account": Color(hex: "8E44AD"),        // 深紫色 - 账号管理
            "danger": Color(hex: "E74C3C")          // 红色 - 危险操作
        ]
    }
    
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
                Section {
                    // 角色分配模式
                    NavigationLink(destination: CharacterDistributionModeView(selectedMode: $characterDistributionMode)) {
                        SettingRowView(
                            icon: "arrow.triangle.2.circlepath",
                            title: "角色分配模式",
                            subtitle: characterDistributionMode,
                            iconColor: iconColors["character"]!
                        )
                    }
                    
                    // 已屏蔽角色管理
                    NavigationLink(destination: BlockedCharactersView()) {
                        SettingRowView(
                            icon: "hand.thumbsdown",
                            title: "已屏蔽角色",
                            subtitle: getBlockedCharactersCount().map { "\($0)个已屏蔽" },
                            iconColor: iconColors["character"]!,
                            subtitleColor: .orange
                        )
                    }
                } header: {
                    Text("角色互动设置")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.none)
                } footer: {
                    Text("管理角色在对话中的出现频率和屏蔽设置")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                
                // 系统设置
                Section {
                    // 暗黑模式
                    NavigationLink(destination: DarkModeSettingView(selectedOption: $darkModeOption)) {
                        SettingRowView(
                            icon: "moon.fill",
                            title: "暗黑模式",
                            subtitle: darkModeOption,
                            iconColor: iconColors["system"]!
                        )
                    }
                    
                    // 内容偏好设置
                    NavigationLink(destination: ContentPreferencesView()) {
                        SettingRowView(
                            icon: "slider.horizontal.3",
                            title: "内容偏好",
                            subtitle: getReducedContentTypesCount().map { "\($0)种已调整" },
                            iconColor: iconColors["system"]!,
                            subtitleColor: .orange
                        )
                    }
                    
                    // 清除缓存
                    Button(action: clearCache) {
                        SettingRowView(
                            icon: "trash.fill",
                            title: "清除缓存",
                            subtitle: isClearingCache ? nil : "25.6MB",
                            iconColor: iconColors["system"]!,
                            trailing: {
                            if isClearingCache {
                                ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: primaryAccentColor))
                                        .scaleEffect(0.8)
                                }
                            }
                        )
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("系统设置")
                        .font(.caption)
                                    .foregroundColor(.secondary)
                        .textCase(.none)
                }
                
                // 账号设置 - 合并重复的section
                Section {
                    // 账号管理
                    NavigationLink(destination: AccountManagementView()) {
                        SettingRowView(
                            icon: "person.circle.fill",
                            title: "账号管理",
                            subtitle: String(AppAccountManager.shared.accountDisplayId.prefix(3)) + " " + 
                                     String(AppAccountManager.shared.accountDisplayId.dropFirst(3).prefix(3)) + " " +
                                     String(AppAccountManager.shared.accountDisplayId.dropFirst(6).prefix(3)),
                            iconColor: iconColors["account"]!
                        )
                    }
                    
                    // 隐私设置
                    NavigationLink(destination: PrivacySettingsView()) {
                        SettingRowView(
                            icon: "lock.shield.fill",
                            title: "隐私设置",
                            iconColor: iconColors["security"]!
                        )
                    }
                } header: {
                    Text("账号设置")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.none)
                } footer: {
                    Text("管理您的账号信息和隐私设置")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                
                // 帮助和关于
                Section {
                    // 联系我们
                    NavigationLink(destination: ContactUsView()) {
                        SettingRowView(
                            icon: "envelope.fill",
                            title: "联系我们",
                            iconColor: iconColors["help"]!
                        )
                    }
                    
                    // 关于我们
                    Button(action: { showingAbout = true }) {
                        SettingRowView(
                            icon: "info.circle.fill",
                            title: "关于虫遇",
                            subtitle: "v1.0.0",
                            iconColor: iconColors["help"]!
                        )
                    }
                                .foregroundColor(.primary)
                } header: {
                    Text("帮助和关于")
                        .font(.caption)
                                .foregroundColor(.secondary)
                        .textCase(.none)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .scrollContentBackground(.hidden)
            .background(DesignSystem.Colors.background)
            .navigationBarTitle("设置", displayMode: .inline)
            .navigationBarTitleTextColor(.primary)
            .navigationBarItems(
                leading: Button(action: {
                    // 触觉反馈
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .medium))
                        Text("返回")
                            .font(.system(size: 16, weight: .regular))
                    }
                    .foregroundColor(primaryAccentColor)
                }
            )
            .onAppear {
                print("SettingsView已显示")
            }
            .alert(isPresented: $showingAbout) {
                Alert(
                    title: Text("关于虫遇"),
                    message: Text("虫遇 v1.0.0\n一款让你与历史人物进行对话的应用\n\n© 2024 虫遇团队\n技术支持: support@chongyu.com"),
                    dismissButton: .default(Text("确定"))
                )
            }
        }
    }
    
    // MARK: - 辅助方法
    
    /**
     * 清除缓存
     */
    private func clearCache() {
        // 触觉反馈
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        isClearingCache = true
        
        // 模拟清除缓存过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isClearingCache = false
            
            // 轻微的成功反馈
            let successGenerator = UINotificationFeedbackGenerator()
            successGenerator.notificationOccurred(.success)
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

// MARK: - 设置行组件

/// 统一的设置行视图组件
/// 提供一致的视觉样式和交互体验
struct SettingRowView<Trailing: View>: View {
    let icon: String
    let title: String
    let subtitle: String?
    let iconColor: Color
    let subtitleColor: Color
    let trailing: () -> Trailing
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        iconColor: Color,
        subtitleColor: Color = .secondary,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.subtitleColor = subtitleColor
        self.trailing = trailing
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标容器
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(iconColor)
                    }
            
            // 文本内容
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(subtitleColor)
                }
            }
            
            Spacer()
            
            // 右侧内容
            trailing()
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
            }
        }

// 为可选值提供便利方法
extension Optional where Wrapped == Int {
    func map<T>(_ transform: (Wrapped) -> T) -> T? {
        switch self {
        case .some(let value):
            return transform(value)
        case .none:
            return nil
        }
    }
}

// 添加导航栏标题颜色扩展
extension View {
    func navigationBarTitleTextColor(_ color: Color) -> some View {
        self.onAppear {
            UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(color)]
        }
    }
}

/**
 * 暗黑模式设置视图
 */
struct DarkModeSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedOption: String
    private let options = ["开启", "关闭", "跟随系统"]
    
    // 主题颜色
    private var primaryAccentColor: Color {
        Color(hex: "9A8BB0")
    }
    
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
                                .foregroundColor(primaryAccentColor)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.background)
        .navigationTitle("暗黑模式")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                // 触觉反馈
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .medium))
                    Text("设置")
                        .font(.system(size: 16, weight: .regular))
                }
                .foregroundColor(primaryAccentColor)
            }
        )
    }
}

/**
 * 角色分配模式设置视图
 */
struct CharacterDistributionModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedMode: String
    private let modes = ["均衡分配", "严格轮换", "关注优先"]
    
    // 主题颜色
    private var primaryAccentColor: Color {
        Color(hex: "9A8BB0")
    }
    
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
                                    .foregroundColor(primaryAccentColor)
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
        .listStyle(InsetGroupedListStyle())
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.background)
        .navigationTitle("角色分配模式")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                // 触觉反馈
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .medium))
                    Text("设置")
                        .font(.system(size: 16, weight: .regular))
                }
                .foregroundColor(primaryAccentColor)
            }
        )
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