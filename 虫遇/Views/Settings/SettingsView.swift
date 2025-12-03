import SwiftUI
import SwiftData

/**
 * 设置页视图
 * 用于配置应用的各种设置选项
 */
struct SettingsView: View {
    /// 环境变量，用于关闭sheet
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    /// 暗黑模式选项
    /// 角色分配模式
    @State private var characterDistributionMode = "均衡分配"
    /// 关于我们展示状态
    @State private var showingAbout = false
    /// API设置展示状态
    @State private var showingAPISettings = false
    
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
    
    /// 安全获取图标颜色，如果不存在则返回默认颜色
    private func getIconColor(_ key: String) -> Color {
        return iconColors[key] ?? primaryAccentColor
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
                // 账号设置 - 最重要，放在最前面
                Section {
                    // 账号管理
                    NavigationLink(destination: AccountManagementView()) {
                        SettingRowView(
                            icon: "person.circle.fill",
                            title: "账号管理",
                            subtitle: AppAccountManager.shared.accountDisplayIdentifier,
                            iconColor: getIconColor("account")
                        )
                    }
                    
                    // 隐私设置
                    NavigationLink(destination: PrivacySettingsView()) {
                        SettingRowView(
                            icon: "lock.shield.fill",
                            title: "隐私设置",
                            iconColor: getIconColor("security")
                        )
                    }
                } header: {
                    Text("账号设置")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.none)
                }
                
                // 数据与备份 - 数据保护功能
                Section {
                    // 数据备份
                    NavigationLink(destination: DataBackupView()) {
                        SettingRowView(
                            icon: "icloud.and.arrow.up.fill",
                            title: "数据备份",
                            subtitle: getBackupStatusSubtitle(),
                            iconColor: Color(hex: "3498DB")
                        )
                    }
                } header: {
                    Text("数据与备份")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.none)
                }
                
                // 角色互动设置 - 核心功能，日常使用
                Section {
                    // 角色分配模式
                    NavigationLink(destination: CharacterDistributionModeView(selectedMode: $characterDistributionMode)) {
                        SettingRowView(
                            icon: "arrow.triangle.2.circlepath",
                            title: "角色分配模式",
                            subtitle: characterDistributionMode,
                            iconColor: getIconColor("character")
                        )
                    }
                    
                    // 已屏蔽角色管理
                    NavigationLink(destination: BlockedCharactersView()) {
                        SettingRowView(
                            icon: "hand.thumbsdown",
                            title: "已屏蔽角色",
                            subtitle: getBlockedCharactersCount().map { "\($0)个已屏蔽" },
                            iconColor: getIconColor("character"),
                            subtitleColor: .orange
                        )
                    }
                    
                    // 屏蔽角色分类
                    NavigationLink(destination: BlockedCategoriesView()) {
                        SettingRowView(
                            icon: "rectangle.stack.badge.minus",
                            title: "屏蔽角色分类",
                            subtitle: getBlockedCategoriesCount().map { "已屏蔽\($0)个分类" },
                            iconColor: getIconColor("character"),
                            subtitleColor: .orange
                        )
                    }
                    
                    // 内容偏好设置
                    NavigationLink(destination: ContentPreferencesView()) {
                        SettingRowView(
                            icon: "slider.horizontal.3",
                            title: "内容偏好",
                            subtitle: getReducedContentTypesCount().map { "\($0)种已调整" },
                            iconColor: getIconColor("character"),
                            subtitleColor: .orange
                        )
                    }
                } header: {
                    Text("帖子生成设置")
                        .font(.caption)
                                    .foregroundColor(.secondary)
                        .textCase(.none)
                }
                
                // 帮助和关于 - 信息类，放在最后
                Section {
                    // 联系我们
                    NavigationLink(destination: ContactUsView()) {
                        SettingRowView(
                            icon: "envelope.fill",
                            title: "联系我们",
                            iconColor: iconColors["help"]!
                        )
                    }
                    
                    NavigationLink(destination: ReviewGuideView()) {
                        SettingRowView(
                            icon: "checkmark.shield.fill",
                            title: "审核使用说明",
                            subtitle: "提供测试账号与操作路径",
                            iconColor: getIconColor("security")
                        )
                    }
                    
                    // 关于我们
                    Button(action: { showingAbout = true }) {
                        SettingRowView(
                            icon: "info.circle.fill",
                            title: "关于虫遇",
                            subtitle: AppVersionHelper.fullVersion,
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
            .alert(isPresented: $showingAbout) {
                Alert(
                    title: Text("关于虫遇"),
                    message: Text("虫遇 \(AppVersionHelper.fullVersion)\n一款让你与历史人物进行对话的应用\n\n© 2024 虫遇团队\n技术支持: li2410669277@gmail.com\n\n备案号：冀ICP备2025136339号-1"),
                    dismissButton: .default(Text("确定"))
                )
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private func getBackupStatusSubtitle() -> String {
        let backups = iCloudBackupService.shared.getAllBackups()
        if backups.isEmpty {
            return "暂无备份"
        } else {
            return "\(backups.count) 个备份"
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
    
    /**
     * 获取已屏蔽分类的数量
     * @return 已屏蔽分类的数量，如果没有则返回nil
     */
    private func getBlockedCategoriesCount() -> Int? {
        let count = BlockedCategoriesManager.shared.getBlockedCategoriesCount()
        if count == 0 {
            return nil
        }
        return count
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
            // 模式选择（整合说明和选择）
            Section(header:
                        VStack(alignment: .leading, spacing: 4) {
                            Text("决定「一键生成」与「虫洞探索」时的角色选择策略。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
            ) {
                // 均衡分配
                Button(action: {
                    selectedMode = "均衡分配"
                    CharacterRotationSystem.shared.switchToMode(.equal)
                }) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                    Text("均衡分配")
                        .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedMode == "均衡分配" {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(primaryAccentColor)
                            }
                        }
                        
                        Text("生成帖子时，根据使用频率平衡分配虚拟角色，确保各角色出现机会均等，但可能会在短期内看到重复角色")
                        .font(.caption)
                        .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedMode == "均衡分配" ? primaryAccentColor.opacity(0.14) : Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedMode == "均衡分配" ? primaryAccentColor.opacity(0.35) : Color(.systemGray4).opacity(0.6), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .listRowBackground(Color.clear)
                
                // 严格轮换
                Button(action: {
                    selectedMode = "严格轮换"
                    CharacterRotationSystem.shared.switchToMode(.strictRotation)
                }) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                    Text("严格轮换")
                        .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedMode == "严格轮换" {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(primaryAccentColor)
                            }
                        }
                        
                        Text("生成帖子时，确保每个虚拟角色仅出现一次，直到所有角色都展示过后才重新开始循环，最大化角色多样性")
                        .font(.caption)
                        .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedMode == "严格轮换" ? primaryAccentColor.opacity(0.14) : Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedMode == "严格轮换" ? primaryAccentColor.opacity(0.35) : Color(.systemGray4).opacity(0.6), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .listRowBackground(Color.clear)
            
                // 关注优先
                    Button(action: {
                    selectedMode = "关注优先"
                            CharacterRotationSystem.shared.switchToMode(.preferenceBase)
                    }) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("关注优先")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedMode == "关注优先" {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(primaryAccentColor)
                            }
                        }
                        
                        Text("生成帖子时，优先展示您关注的虚拟角色，同时保持一定程度的多样性（尚未完全开放）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedMode == "关注优先" ? primaryAccentColor.opacity(0.14) : Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedMode == "关注优先" ? primaryAccentColor.opacity(0.35) : Color(.systemGray4).opacity(0.6), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .listRowBackground(Color.clear)
            }
            
            // 重置轮换状态
            Section {
                Button(action: {
                    CharacterRotationSystem.shared.resetRotationState()
                }) {
                    HStack {
                        Spacer()
                        Text("重置轮换状态")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(primaryAccentColor)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            } footer: {
                Text("重置将清除所有虚拟角色在帖子生成时的使用记录，所有角色将重新开始轮换")
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