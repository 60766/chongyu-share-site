import SwiftUI

struct ExportPayload: Identifiable {
    let id = UUID()
    let data: [String: Any]?
}

/// 账号管理界面
/// 提供账号信息查看、数据管理、退出登录等功能
struct AccountManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var accountManager = AppAccountManager.shared
    @StateObject private var dataManager = UserDataManager.shared
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var appleSignInManager = AppleSignInManager.shared
    
    @State private var exportPayload: ExportPayload?
    @State private var copiedAccountIdentifier = false
    @State private var showingSignOutConfirmation = false
    @State private var showingFirstBackupGuide = false
    
    // 优化的颜色系统
    private var primaryAccentColor: Color {
        Color(hex: "9A8BB0")
    }
    
    private var statusColors: [String: Color] {
        [
            "safe": Color(hex: "27AE60"),      // 绿色 - 安全
            "warning": Color(hex: "F39C12"),   // 橙色 - 警告
            "danger": Color(hex: "E74C3C"),    // 红色 - 危险
            "info": Color(hex: "3498DB"),      // 蓝色 - 信息
            "neutral": Color(hex: "95A5A6")    // 灰色 - 中性
        ]
    }
    
    var body: some View {
        List {
            // 1. Apple ID 登录区块（最核心功能，放在最前面）
            appleSignInSection
            
            // 2. 账号信息区块（登录后查看账号详情）
            accountInfoSection
            
            // 3. 账号找回区块（应急功能，放在最后）
            accountRestoreSection
        }
        .listStyle(InsetGroupedListStyle())
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.background)
        .navigationBarTitle("账号管理", displayMode: .inline)
        .navigationBarTitleTextColor(.primary)
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
        .alert("账号冲突", isPresented: Binding(
            get: { appleSignInManager.accountConflict != nil },
            set: { if !$0 { appleSignInManager.cancelAccountConflict() } }
        )) {
            Button("切换到旧账号（保留余额）") {
                appleSignInManager.switchToExistingAccount()
            }
            Button("用新账号替换（放弃旧账号）", role: .destructive) {
                appleSignInManager.replaceExistingAccountBinding()
            }
            Button("取消", role: .cancel) {
                appleSignInManager.cancelAccountConflict()
            }
        } message: {
            if let conflict = appleSignInManager.accountConflict {
                Text("检测到该 Apple ID 已绑定另一个账号。\n\n已绑定账号余额: \(conflict.existingBalance) 虫洞币\n\n请选择处理方式：\n• 切换到旧账号：保留余额，使用已绑定的账号\n• 用新账号替换：放弃旧账号，将 Apple ID 绑定到当前新账号")
            }
        }
        .alert("开启自动备份", isPresented: $showingFirstBackupGuide) {
            Button("稍后提醒") {
                UserDefaults.standard.set(true, forKey: "HasSeenFirstBackupGuide")
            }
            Button("开启备份") {
                UserDefaults.standard.set(true, forKey: "iCloudAutoBackupEnabled")
                UserDefaults.standard.set(true, forKey: "HasSeenFirstBackupGuide")
                // 立即触发一次备份
                NotificationCenter.default.post(name: NSNotification.Name("PerformAutoBackup"), object: nil)
            }
        } message: {
            Text("检测到您已创建内容，建议开启自动备份以保护您的数据。备份将自动保存到iCloud Drive，换设备时也能恢复。")
        }
        .alert("退出登录", isPresented: $showingSignOutConfirmation) {
            Button("确定", role: .destructive) {
                appleSignInManager.signOut()
        }
            Button("取消", role: .cancel) { }
        } message: {
            Text("退出登录后：\n\n✅ 保留内容：\n• 您的虫洞币余额\n• 您的帖子和创作\n• 您的自定义角色\n• 账号与 Apple ID 的绑定关系\n\n⚠️ 清除内容：\n• 本地登录状态\n\n💡 下次登录：\n• 可通过 Apple ID 重新登录\n• 自动恢复所有数据和余额")
        }
        .onAppear {
            appleSignInManager.checkAppleSignInStatus()
            // 检查是否需要显示首次备份引导
            checkAndShowFirstBackupGuide()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PerformAutoBackup"))) { _ in
            // 执行自动备份（在后台线程）
            performAutoBackupInBackground()
        }
    }
    
    // MARK: - 账号信息区块
    
    private var accountInfoSection: some View {
        Section {
            // 账号标识
            AccountInfoRow(
                icon: "person.circle.fill",
                title: "账号标识",
                value: accountManager.accountDisplayIdentifier,
                iconColor: statusColors["info"]!,
                trailing: {
                    // 复制按钮
                    Button(action: {
                        copyAccountIdentifier()
                    }) {
                        Image(systemName: copiedAccountIdentifier ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.system(size: 16))
                            .foregroundColor(copiedAccountIdentifier ? .green : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            )
            
            // 创建时间
            AccountInfoRow(
                icon: "calendar",
                title: "创建时间",
                value: formatCreationDate(),
                subtitle: getAccountAgeText(),
                iconColor: statusColors["neutral"]!
            )
            
            // 用户昵称
            AccountInfoRow(
                icon: "person.text.rectangle",
                title: "用户昵称",
                value: profileManager.username.isEmpty ? "虫遇大王" : profileManager.username,
                subtitle: "Lv.\(profileManager.userLevel)",
                iconColor: statusColors["info"]!
            )
        } header: {
            Text("账号信息")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.none)
        }
    }
    
    // MARK: - Apple ID 登录区块
    
    private var appleSignInSection: some View {
        Section {
            if appleSignInManager.isSignedIn {
                // 已登录Apple ID的状态显示
                AccountInfoRow(
                    icon: "applelogo",
                    title: "Apple ID",
                    value: appleSignInManager.userDisplayName ?? "已登录",
                    subtitle: appleSignInManager.userAppleIDEmail ?? "已绑定",
                    iconColor: Color.black,
                    trailing: {
                        Button("退出登录") {
                            showingSignOutConfirmation = true
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                )
            } else {
                // Apple ID 登录按钮（自定义中文按钮）
                VStack(spacing: 12) {
                    Button(action: {
                        appleSignInManager.signInWithApple()
                    }) {
                        HStack {
                            Image(systemName: "applelogo")
                                .font(.system(size: 18, weight: .medium))
                            Text("通过 Apple 登录")
                                .font(.system(size: 17, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .background(Color.black)
                        .cornerRadius(8)
                    }
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("账号登录")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.none)
        } footer: {
            if appleSignInManager.isSignedIn {
                Text("已绑定，可通过 Apple ID 找回账号和虫洞币余额")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.8))
            } else {
                Text("绑定后可通过 Apple ID 找回账号和虫洞币余额")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.8))
            }
        }
    }
    
    // MARK: - 账号找回区块
    
    private var accountRestoreSection: some View {
        Section {
            NavigationLink(destination: AccountRestoreView()) {
                AccountInfoRow(
                    icon: "arrow.clockwise.circle.fill",
                    title: "找回账号",
                    value: nil,
                    iconColor: statusColors["info"]!
            )
            }
        } header: {
            Text("账号找回")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.none)
        } footer: {
            Text("可通过 Apple ID 或账号标识找回账号和虫洞币余额")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.8))
        }
    }
    
    // MARK: - 数据管理区块
    
    private var dataManagementSection: some View {
        Section {
            
            // 立即备份
            Button(action: exportUserData) {
                DataManagementRow(
                    icon: "icloud.and.arrow.up.fill",
                    title: "立即备份",
                    subtitle: "保存当前数据状态到 iCloud Drive",
                    iconColor: statusColors["info"]!
                )
            }
            .foregroundColor(.primary)
            
            // 备份历史
            NavigationLink(destination: BackupHistoryView()) {
                DataManagementRow(
                    icon: "clock.arrow.circlepath",
                    title: "备份历史",
                    subtitle: getBackupHistorySubtitle(),
                    iconColor: statusColors["info"]!
                )
            }
            
            // iCloud自动备份开关
            if iCloudBackupService.shared.isiCloudAvailable {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: "icloud.fill")
                                    .foregroundColor(statusColors["info"]!)
                                Text("iCloud自动备份")
                                    .font(.body)
                            }
                            Text(getBackupStatusSubtitle())
                .font(.caption)
                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { UserDefaults.standard.bool(forKey: "iCloudAutoBackupEnabled") },
                            set: { newValue in
                                UserDefaults.standard.set(newValue, forKey: "iCloudAutoBackupEnabled")
                                if newValue {
                                    // 开启备份时，清除失败标记
                                    UserDefaults.standard.set(false, forKey: "iCloudBackupLastFailed")
        }
                            }
                        ))
                        .labelsHidden()
    }
    
                    // 备份状态详情（仅在开启时显示）
                    if UserDefaults.standard.bool(forKey: "iCloudAutoBackupEnabled") {
                        VStack(alignment: .leading, spacing: 6) {
                            // 备份状态指示器
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(getBackupStatusColor())
                                    .frame(width: 8, height: 8)
                                Text(getBackupStatusText())
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            // 备份时间信息
                            if let lastBackup = iCloudBackupService.shared.lastBackupDate {
                                Text("上次备份：\(formatBackupDate(lastBackup))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary.opacity(0.8))
                            } else {
                                Text("尚未进行过备份")
                                    .font(.caption2)
                                    .foregroundColor(.secondary.opacity(0.8))
            }
            
                            if let nextBackup = iCloudBackupService.shared.nextBackupDate {
                                Text("下次备份：\(formatBackupDate(nextBackup))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary.opacity(0.8))
                            }
                            
                            // 备份频率选项
                            NavigationLink(destination: BackupFrequencySettingsView()) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("备份频率：每\(iCloudBackupService.shared.backupFrequencyDays)天")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                            }
                            .padding(.leading, 24)
                            .padding(.top, 4)
                        }
                    }
            }
                .padding(.vertical, 4)
            }
        } header: {
            Text("数据管理")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.none)
        } footer: {
            Text("定期备份数据可以保护您的创作内容和成长记录")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.8))
        }
    }
    
    private func getBackupHistorySubtitle() -> String {
        let backups = iCloudBackupService.shared.getAllBackups()
        if backups.isEmpty {
            return "暂无备份"
        } else {
            return "\(backups.count) 个备份"
        }
    }
    
    private func getBackupStatusSubtitle() -> String {
        let frequency = iCloudBackupService.shared.backupFrequencyDays
        return "每\(frequency)天自动备份到iCloud Drive"
    }
    
    private func getBackupStatusText() -> String {
        let status = iCloudBackupService.shared.backupStatus
        switch status {
        case .notEnabled:
            return "未开启"
        case .neverBackedUp:
            return "等待首次备份"
        case .upToDate:
            return "备份正常"
        case .needsBackup:
            return "需要备份"
        case .backupFailed:
            return "备份失败，请检查iCloud设置"
        }
    }
    
    private func getBackupStatusColor() -> Color {
        let status = iCloudBackupService.shared.backupStatus
        switch status {
        case .notEnabled:
            return .gray
        case .neverBackedUp:
            return .orange
        case .upToDate:
            return .green
        case .needsBackup:
            return .orange
        case .backupFailed:
            return .red
        }
    }
    
    private func formatBackupDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
                }
    
    /// 检查并显示首次备份引导
    private func checkAndShowFirstBackupGuide() {
        // 只在用户有内容但未开启备份时显示
        let hasContent = PostViewModel.shared.posts.count > 0 || 
                        UserProfileManager.shared.userLevel > 1
        
        let backupEnabled = UserDefaults.standard.bool(forKey: "iCloudAutoBackupEnabled")
        let hasSeenGuide = UserDefaults.standard.bool(forKey: "HasSeenFirstBackupGuide")
        
        if hasContent && !backupEnabled && !hasSeenGuide && iCloudBackupService.shared.isiCloudAvailable {
            // 延迟显示，不打断用户当前操作
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showingFirstBackupGuide = true
            }
        }
    }
    
    // MARK: - 操作方法
    
    @Environment(\.modelContext) private var modelContext
    
    private func exportUserData() {
        let data = dataManager.exportUserData(modelContext: modelContext)
        
        // 检查是否需要自动备份
        if UserDefaults.standard.bool(forKey: "iCloudAutoBackupEnabled"),
           iCloudBackupService.shared.shouldAutoBackup() {
            iCloudBackupService.shared.performAutoBackup(data: data) { result in
                switch result {
                case .success:
                    print("✅ 自动备份成功")
                case .failure(let error):
                    print("⚠️ 自动备份失败: \(error.localizedDescription)")
                }
            }
        }
        
        DispatchQueue.main.async {
            self.exportPayload = ExportPayload(data: data)
        }
    }
    
    /// 在后台执行自动备份
    private func performAutoBackupInBackground() {
        // 检查自动备份是否开启
        guard UserDefaults.standard.bool(forKey: "iCloudAutoBackupEnabled") else {
            return
        }
        
        // 检查是否需要备份
        guard iCloudBackupService.shared.shouldAutoBackup() else {
            return
        }
        
        // ⚠️ 重要：ModelContext 必须在主线程使用
        // 在主线程导出数据，然后在后台线程保存到 iCloud
        DispatchQueue.main.async {
            // 在主线程导出用户数据（ModelContext 操作必须在主线程）
            let data = dataManager.exportUserData(modelContext: modelContext)
            
            // 在后台线程执行 iCloud 保存操作
            DispatchQueue.global(qos: .utility).async {
                iCloudBackupService.shared.performAutoBackup(data: data) { result in
                    switch result {
                    case .success(let filePath):
                        print("✅ [自动备份] 备份成功: \(filePath)")
                    case .failure(let error):
                        print("⚠️ [自动备份] 备份失败: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func copyAccountIdentifier() {
        Task { @MainActor in
            let fullIdentifier = accountManager.fullAccountIdentifier
            UIPasteboard.general.string = fullIdentifier
            copiedAccountIdentifier = true
            
            // 2秒后恢复按钮状态
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            copiedAccountIdentifier = false
        }
    }
    
    // MARK: - 辅助方法
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    
    private func formatCreationDate() -> String {
        return formatDate(accountManager.accountCreationDate)
    }
    
    private func getAccountAgeText() -> String {
        let days = accountManager.getAccountStats()["daysSinceCreation"] as? Int ?? 0
        return "已使用 \(days) 天"
    }
    
}

// MARK: - 账号管理专用组件

/// 账号信息行组件
struct AccountInfoRow<Trailing: View>: View {
    let icon: String
    let title: String
    let value: String?
    let subtitle: String?
    let iconColor: Color
    let trailing: () -> Trailing
    
    init(
        icon: String,
        title: String,
        value: String? = nil,
        subtitle: String? = nil,
        iconColor: Color,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.trailing = trailing
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // 内容
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)
                
                if let value = value {
                Text(value)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
                }
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
            
            Spacer()
            
            trailing()
        }
        .padding(.vertical, 2)
    }
}


/// 危险操作行组件
struct DangerActionRow<Trailing: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let trailing: () -> Trailing
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        iconColor: Color,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.trailing = trailing
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // 内容
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            trailing()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 数据导出界面

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    let exportedData: [String: Any]?
    
    @StateObject private var iCloudService = iCloudBackupService.shared
    
    @State private var isSavingToiCloud = false
    @State private var showingiCloudSuccess = false
    @State private var showingiCloudError = false
    @State private var iCloudErrorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let data = exportedData {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 保存按钮（放在最上方，避免误导）
                            VStack(spacing: 12) {
                                // 保存到iCloud Drive按钮（核心功能）
                                if iCloudService.isiCloudAvailable {
                                    Button(action: saveToiCloud) {
                                        HStack {
                                            if isSavingToiCloud {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(0.8)
                                            } else {
                                                Image(systemName: "icloud.fill")
                                            }
                                            Text(isSavingToiCloud ? "正在保存..." : "保存到iCloud Drive")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(hex: "9A8BB0"))
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    }
                                    .disabled(isSavingToiCloud)
                                } else {
                                    // iCloud不可用时的提示
                                    VStack(spacing: 8) {
                                        Image(systemName: "icloud.slash")
                                    .font(.title2)
                                            .foregroundColor(.secondary)
                                        Text("iCloud Drive 不可用")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("请在「设置」→「Apple ID」→「iCloud」中启用 iCloud Drive")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                
                                // 提示文字
                                Text("点击上方按钮将当前数据状态保存到 iCloud Drive")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            
                            // 成长记录卡片
                            if let highlights = data["highlights"] as? [String: Any] {
                                HighlightsCard(highlights: highlights)
                            }
                            
                            // 次元足迹卡片
                            if let highlights = data["highlights"] as? [String: Any] {
                                FootprintCard(highlights: highlights)
                            }
                            
                            // 成就展示卡片
                            if let achievements = data["achievements"] as? [String: Any] {
                                AchievementsPreviewCard(achievements: achievements)
                            }
                            
                            // 关注角色预览
                            if let followed = data["followedCharacters"] as? [String: Any],
                               let characters = followed["characters"] as? [[String: Any]],
                               let count = followed["count"] as? Int,
                               count > 0 {
                                FollowedCharactersPreviewCard(characters: characters, count: count)
                            }
                            
                            // 数据内容预览
                            DataPreviewCard(data: data)
                            
                            // 我的帖子预览
                            if let myCreations = data["myCreations"] as? [String: Any],
                               let posts = myCreations["posts"] as? [[String: Any]],
                               !posts.isEmpty {
                                PostsPreviewCard(posts: posts)
                            }
                            
                            // 自定义角色预览
                            if let myCreations = data["myCreations"] as? [String: Any],
                               let customCharacters = myCreations["customCharacters"] as? [[String: Any]],
                               !customCharacters.isEmpty {
                                CustomCharactersPreviewCard(characters: customCharacters)
                                }
                                
                            // 私聊对话预览
                            if let conversations = data["conversations"] as? [String: Any] {
                                ConversationsPreviewCard(conversations: conversations)
                                    }
                            
                            // 多人对话预览
                            if let multiPersonChats = data["multiPersonChats"] as? [String: Any] {
                                MultiPersonChatPreviewCard(multiPersonChats: multiPersonChats)
                                }
                            
                            // 底部间距
                            Spacer()
                                .frame(height: 20)
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("数据导出失败")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("请稍后重试")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("数据备份")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("关闭") {
                    dismiss()
                }
                .foregroundColor(Color(hex: "9A8BB0"))
            )
            .alert("保存成功", isPresented: $showingiCloudSuccess) {
                Button("确定") {
                    dismiss()
                }
            } message: {
                Text("数据已成功保存到iCloud Drive\n\n您可以在「文件」应用的「iCloud Drive」→「虫遇备份」中找到备份文件")
            }
            .alert("保存失败", isPresented: $showingiCloudError) {
                Button("确定") { }
            } message: {
                Text(iCloudErrorMessage)
            }
        }
    }
    
    private func saveToiCloud() {
        guard let data = exportedData else { return }
        
        isSavingToiCloud = true
        
        iCloudService.saveBackupToiCloud(data: data) { result in
            DispatchQueue.main.async {
                isSavingToiCloud = false
                
                switch result {
                case .success:
                    showingiCloudSuccess = true
                case .failure(let error):
                    iCloudErrorMessage = error.localizedDescription
                    showingiCloudError = true
                }
            }
        }
    }
}

// MARK: - 成长记录卡片
struct HighlightsCard: View {
    let highlights: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("我的成长记录")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                if let totalPosts = highlights["totalPosts"] as? Int {
                    StatItem(
                        icon: "pencil.circle.fill",
                        title: "我的创作",
                        value: "\(totalPosts)",
                        color: .blue
                    )
                }
                
                if let currentLevel = highlights["currentLevel"] as? Int {
                    StatItem(
                        icon: "star.circle.fill",
                        title: "当前等级",
                        value: "Lv.\(currentLevel)",
                        color: .orange
                    )
                }
                
                if let memberDays = highlights["memberDays"] as? Int {
                    StatItem(
                        icon: "calendar.circle.fill",
                        title: "陪伴天数",
                        value: "\(memberDays)天",
                        color: .green
                    )
                }
            }
            
            VStack(spacing: 8) {
                if let totalCharacters = highlights["totalCustomCharacters"] as? Int {
                    DetailStatRow(label: "自定义角色", value: "\(totalCharacters) 个")
                }
                if let experience = highlights["experience"] as? Int {
                    DetailStatRow(label: "当前经验值", value: "\(experience) XP")
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DetailStatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
}

// MARK: - 数据预览卡片
struct DataPreviewCard: View {
    let data: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("我的虫遇档案")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                if let profile = data["profile"] as? [String: Any] {
                    if let nickname = profile["nickname"] as? String {
                        PreviewRow(label: "昵称", value: nickname)
                    }
                    if let signature = profile["signature"] as? String {
                        PreviewRow(label: "签名", value: signature)
                    }
                    if let levelTitle = profile["levelTitle"] as? String {
                        PreviewRow(label: "称号", value: levelTitle)
                    }
                    if let joinDate = profile["joinDate"] as? String {
                        PreviewRow(label: "加入日期", value: joinDate)
                    }
                }
                
                if let myCreations = data["myCreations"] as? [String: Any] {
                    if let posts = myCreations["posts"] as? [[String: Any]] {
                        PreviewRow(label: "我的创作", value: "\(posts.count) 篇")
                    }
                    if let characters = myCreations["customCharacters"] as? [[String: Any]] {
                        PreviewRow(label: "自定义角色", value: "\(characters.count) 个")
                    }
                }
                
                if let exportInfo = data["exportInfo"] as? [String: Any],
                   let exportDate = exportInfo["exportDate"] as? String {
                    PreviewRow(label: "导出日期", value: exportDate)
                }
            }
            
            Text("包含您在虫遇的所有珍贵回忆和创作")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct PreviewRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// 新增：我的帖子预览卡片
struct PostsPreviewCard: View {
    let posts: [[String: Any]]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("我的创作预览")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 10) {
                ForEach(Array(posts.prefix(5).enumerated()), id: \.offset) { _, post in
                    PostRow(post: post)
                }
                
                if posts.count > 5 {
                    HStack {
                        Text("还有 \(posts.count - 5) 篇…")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        NavigationLink(destination: DataPostsListView(posts: posts)) {
                            HStack(spacing: 4) {
                                Text("查看全部帖子")
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                            }
                        }
                        .font(.caption)
                    }
                    .padding(.top, 4)
                } else {
                    HStack {
                        Spacer()
                        NavigationLink(destination: DataPostsListView(posts: posts)) {
                            HStack(spacing: 4) {
                                Text("查看全部帖子")
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                            }
                        }
                        .font(.caption)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct PostRow: View {
    let post: [String: Any]
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "pencil")
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 6) {
                // 作者名称（角色名称或用户名）
                if let characterName = post["characterName"] as? String {
                    // 角色发的帖子
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.purple)
                        Text(characterName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                    }
                } else if let username = post["username"] as? String {
                    // 用户自己发的帖子
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text(username)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
                
                // 帖子内容
                Text(extractContent(from: post))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // 帖子图片（如果有）
                if let images = post["images"] as? [String], !images.isEmpty {
                    BackupPostImagesView(imageIds: images, postImages: post["postImages"] as? [[String: Any]])
                }
                
                // 元数据
                HStack(spacing: 8) {
                    if let date = post["date"] as? String {
                        Label(date, systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let likes = post["likes"] as? Int {
                        Label("\(likes)", systemImage: "hand.thumbsup")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    // 评论数量
                    if let comments = post["comments"] as? [[String: Any]], !comments.isEmpty {
                        Label("\(comments.count)", systemImage: "bubble.left")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let type = post["type"] as? String {
                        Text(type)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
            }
        }
    }
    
    private func extractContent(from post: [String: Any]) -> String {
        if let content = post["content"] as? String, !content.isEmpty {
            return content
        }
        // 兼容可能的字段名
        if let text = post["text"] as? String { return text }
        if let title = post["title"] as? String { return title }
        return "(无内容)"
    }
}

// 全量帖子列表
struct DataPostsListView: View {
    let posts: [[String: Any]]
    
    var body: some View {
        List {
            Section(header: Text("我的帖子（\(posts.count)）").textCase(nil)) {
                ForEach(Array(posts.enumerated()), id: \.offset) { _, post in
                    VStack(alignment: .leading, spacing: 8) {
                        // 作者名称（角色名称或用户名）
                        if let characterName = post["characterName"] as? String {
                            // 角色发的帖子
                            HStack(spacing: 4) {
                                Image(systemName: "person.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                                Text(characterName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.purple)
                            }
                            .padding(.bottom, 2)
                        } else if let username = post["username"] as? String {
                            // 用户自己发的帖子
                            HStack(spacing: 4) {
                                Image(systemName: "person.circle")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text(username)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                            .padding(.bottom, 2)
                        }
                        
                        // 帖子内容
                        Text(extractContent(from: post))
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        // 帖子图片（如果有）
                        if let images = post["images"] as? [String], !images.isEmpty {
                            BackupPostImagesView(imageIds: images, postImages: post["postImages"] as? [[String: Any]])
                                .padding(.top, 4)
                        }
                        
                        // 元数据
                        HStack(spacing: 12) {
                            if let date = post["date"] as? String {
                                Label(date, systemImage: "calendar")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if let likes = post["likes"] as? Int {
                                Label("\(likes)", systemImage: "hand.thumbsup")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            // 评论数量
                            if let comments = post["comments"] as? [[String: Any]], !comments.isEmpty {
                                Label("\(comments.count)条评论", systemImage: "bubble.left")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if let type = post["type"] as? String {
                                Text(type)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(4)
                            }
                        }
                        
                        // 评论预览（显示前3条）
                        if let comments = post["comments"] as? [[String: Any]], !comments.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Divider()
                                    .padding(.vertical, 4)
                                
                                Text("评论（\(comments.count)）")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                ForEach(Array(comments.prefix(3).enumerated()), id: \.offset) { _, comment in
                                    CommentRow(comment: comment)
                                }
                                
                                if comments.count > 3 {
                                    Text("还有 \(comments.count - 3) 条评论...")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("我的帖子")
    }
    
    private func extractContent(from post: [String: Any]) -> String {
        if let content = post["content"] as? String, !content.isEmpty { return content }
        if let text = post["text"] as? String { return text }
        if let title = post["title"] as? String { return title }
        return "(无内容)"
    }
}

// 评论行视图
struct CommentRow: View {
    let comment: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                // 角色名称（如果是角色评论）
                if let characterName = comment["characterName"] as? String {
                    Image(systemName: "person.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.purple)
                    Text(characterName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                } else if let username = comment["username"] as? String {
                    Text(username)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if let date = comment["date"] as? String {
                    Text(date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if let content = comment["content"] as? String {
                Text(content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // 回复信息
            if let replyTo = comment["replyToUsername"] as? String {
                HStack(spacing: 4) {
                    Image(systemName: "arrowshape.turn.up.left")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("回复 \(replyTo)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
}

// MARK: - 备份数据中的角色头像视图组件

struct BackupCharacterAvatarView: View {
    let characterId: String
    let size: CGFloat
    
    @State private var avatarImage: UIImage?
    
    var body: some View {
        Group {
            if let image = avatarImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: size))
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            loadAvatar()
        }
    }
    
    private func loadAvatar() {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let avatarURL = documentsDirectory.appendingPathComponent("\(characterId).jpg")
        
        // 检查文件是否存在
        guard fileManager.fileExists(atPath: avatarURL.path) else {
            #if DEBUG
            print("⚠️ [头像显示] 头像文件不存在: \(avatarURL.path)")
            #endif
            return
        }
        
        // 读取图片数据
        guard let imageData = try? Data(contentsOf: avatarURL),
              let image = UIImage(data: imageData) else {
            #if DEBUG
            print("⚠️ [头像显示] 无法加载头像图片: \(avatarURL.path)")
            #endif
            return
        }
        
        DispatchQueue.main.async {
            self.avatarImage = image
        }
    }
}

// MARK: - 自定义角色预览卡片

struct CustomCharactersPreviewCard: View {
    let characters: [[String: Any]]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("我的自定义角色")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 10) {
                ForEach(Array(characters.prefix(5).enumerated()), id: \.offset) { _, character in
                    CustomCharacterRow(character: character)
                }
                
                if characters.count > 5 {
                    HStack {
                        Text("还有 \(characters.count - 5) 个角色…")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        NavigationLink(destination: DataCustomCharactersListView(characters: characters)) {
                            HStack(spacing: 4) {
                                Text("查看全部角色")
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                            }
                        }
                        .font(.caption)
                    }
                    .padding(.top, 4)
                } else {
                    HStack {
                        Spacer()
                        NavigationLink(destination: DataCustomCharactersListView(characters: characters)) {
                            HStack(spacing: 4) {
                                Text("查看全部角色")
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                            }
                        }
                        .font(.caption)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct CustomCharacterRow: View {
    let character: [String: Any]
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // 角色头像（从本地文件系统加载）
            if let characterId = character["id"] as? String {
                BackupCharacterAvatarView(characterId: characterId, size: 40)
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // 角色名称
                if let name = character["name"] as? String {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                // 角色描述
                if let description = character["description"] as? String, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else if let personality = character["personality"] as? String, !personality.isEmpty {
                    Text(personality)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // 创建日期
                if let createdDate = character["createdDate"] as? String {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(createdDate)
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

// 全量自定义角色列表
struct DataCustomCharactersListView: View {
    let characters: [[String: Any]]
    
    var body: some View {
        List {
            Section(header: Text("我的自定义角色（\(characters.count)）").textCase(nil)) {
                ForEach(Array(characters.enumerated()), id: \.offset) { _, character in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            // 角色头像（从本地文件系统加载）
                            if let characterId = character["id"] as? String {
                                BackupCharacterAvatarView(characterId: characterId, size: 50)
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                // 角色名称
                                if let name = character["name"] as? String {
                                    Text(name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                
                                // 创建日期
                                if let createdDate = character["createdDate"] as? String {
                                    Label(createdDate, systemImage: "calendar")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        // 角色描述
                        if let description = character["description"] as? String, !description.isEmpty {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        
                        // 性格特点
                        if let personality = character["personality"] as? String, !personality.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("性格特点")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                Text(personality)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                            .padding(.top, 4)
                        }
                        
                        // 成就
                        if let achievements = character["achievements"] as? [String], !achievements.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("成就")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                ForEach(achievements, id: \.self) { achievement in
                                    Text("• \(achievement)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 4)
                        }
                        
                        // 主要作品
                        if let mainWorks = character["mainWorks"] as? [String], !mainWorks.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("主要作品")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                ForEach(mainWorks, id: \.self) { work in
                                    Text("• \(work)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("我的自定义角色")
    }
}

// MARK: - 私聊对话预览卡片

struct ConversationsPreviewCard: View {
    let conversations: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("私聊对话")
                .font(.headline)
                .foregroundColor(.primary)
            
            // 统计信息
            HStack(spacing: 20) {
                if let totalConversations = conversations["totalConversations"] as? Int {
                    StatItem(
                        icon: "message.circle.fill",
                        title: "对话数",
                        value: "\(totalConversations)",
                        color: .blue
                    )
                }
                
                if let totalMessages = conversations["totalMessages"] as? Int {
                    StatItem(
                        icon: "bubble.left.and.bubble.right.fill",
                        title: "消息数",
                        value: "\(totalMessages)",
                        color: .green
                    )
                }
            }
            
            // 对话列表预览（显示前3个）
            if let conversationsList = conversations["conversations"] as? [[String: Any]], !conversationsList.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("最近对话")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    ForEach(Array(conversationsList.prefix(3).enumerated()), id: \.offset) { _, conversation in
                        NavigationLink(destination: BackupConversationDetailView(conversation: conversation)) {
                            BackupConversationRow(conversation: conversation)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if conversationsList.count > 3 {
                        HStack {
                            Text("还有 \(conversationsList.count - 3) 个对话...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                            Spacer()
                            NavigationLink(destination: BackupConversationsListView(conversations: conversationsList)) {
                                HStack(spacing: 4) {
                                    Text("查看全部对话")
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                }
                            }
                            .font(.caption)
                        }
                    } else {
                        HStack {
                            Spacer()
                            NavigationLink(destination: BackupConversationsListView(conversations: conversationsList)) {
                                HStack(spacing: 4) {
                                    Text("查看全部对话")
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                }
                            }
                            .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct BackupConversationRow: View {
    let conversation: [String: Any]
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.circle.fill")
                .font(.title3)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                // 角色名称
                if let characterName = conversation["characterName"] as? String {
                    Text(characterName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                // 最后一条消息
                if let lastMessage = conversation["lastMessageContent"] as? String {
                    Text(lastMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // 消息数量和时间
                HStack(spacing: 8) {
                    if let messageCount = conversation["messageCount"] as? Int {
                        Text("\(messageCount)条消息")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if let lastMessageTime = conversation["lastMessageTime"] as? String {
                        Text(lastMessageTime)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 多人对话预览卡片

struct MultiPersonChatPreviewCard: View {
    let multiPersonChats: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("多人对话")
                .font(.headline)
                .foregroundColor(.primary)
            
            // 统计信息
            HStack(spacing: 20) {
                if let totalSessions = multiPersonChats["totalSessions"] as? Int {
                    StatItem(
                        icon: "person.3.fill",
                        title: "会话数",
                        value: "\(totalSessions)",
                        color: .purple
                    )
                }
                
                if let totalMessages = multiPersonChats["totalMessages"] as? Int {
                    StatItem(
                        icon: "bubble.left.and.bubble.right.fill",
                        title: "消息数",
                        value: "\(totalMessages)",
                        color: .orange
                    )
                }
            }
            
            // 会话列表预览（显示前3个）
            if let sessionsList = multiPersonChats["sessions"] as? [[String: Any]], !sessionsList.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("最近会话")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    ForEach(Array(sessionsList.prefix(3).enumerated()), id: \.offset) { _, session in
                        NavigationLink(destination: BackupMultiPersonChatDetailView(session: session)) {
                            MultiPersonChatRow(session: session)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if sessionsList.count > 3 {
                        HStack {
                            Text("还有 \(sessionsList.count - 3) 个会话...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                            Spacer()
                            NavigationLink(destination: BackupMultiPersonChatsListView(sessions: sessionsList)) {
                                HStack(spacing: 4) {
                                    Text("查看全部会话")
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                }
                            }
                            .font(.caption)
                        }
                    } else {
                        HStack {
                            Spacer()
                            NavigationLink(destination: BackupMultiPersonChatsListView(sessions: sessionsList)) {
                                HStack(spacing: 4) {
                                    Text("查看全部会话")
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                }
                            }
                            .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct MultiPersonChatRow: View {
    let session: [String: Any]
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.3.fill")
                .font(.title3)
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 4) {
                // 会话主题
                if let topic = session["topic"] as? String {
                    Text(topic)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                // 参与者
                if let participantNames = session["participantNames"] as? [String] {
                    Text(participantNames.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // 消息数量和时间
                HStack(spacing: 8) {
                    if let messageCount = session["messageCount"] as? Int {
                        Text("\(messageCount)条消息")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if let lastActiveTime = session["lastActiveTime"] as? String {
                        Text(lastActiveTime)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 次元足迹卡片

struct FootprintCard: View {
    let highlights: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("次元足迹总览")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                if let dialogueCount = highlights["dialogueCount"] as? Int {
                    StatItem(
                        icon: "message.circle.fill",
                        title: "次元对话",
                        value: "\(dialogueCount)次",
                        color: .blue
                    )
                }
                
                if let explorationDays = highlights["explorationDays"] as? Int {
                    StatItem(
                        icon: "calendar.circle.fill",
                        title: "探索天数",
                        value: "\(explorationDays)天",
                        color: .orange
                    )
                }
            }
            
            VStack(spacing: 8) {
                if let totalPosts = highlights["totalPosts"] as? Int {
                    DetailStatRow(label: "总帖子数", value: "\(totalPosts) 篇")
                }
                if let totalComments = highlights["totalComments"] as? Int {
                    DetailStatRow(label: "总评论数", value: "\(totalComments) 条")
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - 成就展示卡片

struct AchievementsPreviewCard: View {
    let achievements: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成就展示")
                .font(.headline)
                .foregroundColor(.primary)
            
            // 统计信息
            HStack(spacing: 20) {
                if let totalCount = achievements["totalCount"] as? Int {
                    StatItem(
                        icon: "trophy.circle.fill",
                        title: "总成就",
                        value: "\(totalCount)",
                        color: .yellow
                    )
                }
                
                if let unlockedCount = achievements["unlockedCount"] as? Int {
                    StatItem(
                        icon: "checkmark.circle.fill",
                        title: "已解锁",
                        value: "\(unlockedCount)",
                        color: .green
                    )
                }
                
                if let pinnedCount = achievements["pinnedCount"] as? Int {
                    StatItem(
                        icon: "pin.circle.fill",
                        title: "已固定",
                        value: "\(pinnedCount)",
                        color: .purple
                    )
                }
            }
            
            // 成就列表预览（显示前3个已解锁的成就）
            if let achievementsList = achievements["achievements"] as? [[String: Any]] {
                let unlockedAchievements = achievementsList.filter { ($0["isUnlocked"] as? Bool) == true }
                let previewAchievements = Array(unlockedAchievements.prefix(3))
                
                if !previewAchievements.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("已解锁成就")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        
                        ForEach(Array(previewAchievements.enumerated()), id: \.offset) { _, achievement in
                            DataAchievementRow(achievement: achievement)
                        }
                        
                        if unlockedAchievements.count > 3 {
                            Text("还有 \(unlockedAchievements.count - 3) 个已解锁成就...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - 关注角色预览卡片

struct FollowedCharactersPreviewCard: View {
    let characters: [[String: Any]]
    let count: Int
    
    private var previewNames: [String] {
        let names = characters.compactMap { $0["name"] as? String }
        return Array(names.prefix(6))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("关注的角色")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                StatItem(
                    icon: "heart.circle.fill",
                    title: "关注总数",
                    value: "\(count)",
                    color: Color(hex: "E67E22")
                )
            }
            
            if !previewNames.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("最近关注")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    FlowLayout(alignment: .leading, spacing: 8, lineSpacing: 8) {
                        ForEach(previewNames, id: \.self) { name in
                            Text(name)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(16)
                        }
                    }
                    
                    if count > previewNames.count {
                        Text("还有 \(count - previewNames.count) 位角色已关注...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else if count > 0 {
                Text("已关注 \(count) 位角色")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("尚未关注任何角色")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - 备份对话详情视图

struct BackupConversationDetailView: View {
    let conversation: [String: Any]
    
    var body: some View {
        List {
            Section(header: Text("对话信息").textCase(nil)) {
                if let characterName = conversation["characterName"] as? String {
                    HStack {
                        Text("角色")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(characterName)
                            .fontWeight(.medium)
                    }
                }
                
                if let messageCount = conversation["messageCount"] as? Int {
                    HStack {
                        Text("消息数")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(messageCount) 条")
                    }
                }
                
                if let createdAt = conversation["createdAt"] as? String {
                    HStack {
                        Text("创建时间")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(createdAt)
                    }
                }
            }
            
            if let messages = conversation["messages"] as? [[String: Any]], !messages.isEmpty {
                Section(header: Text("消息记录（\(messages.count)）").textCase(nil)) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { _, message in
                        BackupMessageRow(message: message)
                    }
                }
            }
        }
        .navigationTitle(conversation["characterName"] as? String ?? "对话详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 备份帖子图片视图

struct BackupPostImagesView: View {
    let imageIds: [String]
    let postImages: [[String: Any]]?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(imageIds, id: \.self) { imageId in
                    BackupPostImageView(imageId: imageId, postImages: postImages)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct BackupPostImageView: View {
    let imageId: String
    let postImages: [[String: Any]]?
    
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        #if DEBUG
        print("🖼️ [显示] 开始加载帖子图片: \(imageId)")
        #endif
        
        // 方法1: 从备份数据中加载（base64）
        if let postImages = postImages {
            #if DEBUG
            print("🖼️ [显示] 备份数据中有 \(postImages.count) 张图片")
            #endif
            if let imageData = postImages.first(where: { ($0["id"] as? String) == imageId }),
               let base64Data = imageData["imageData"] as? String {
                #if DEBUG
                print("🖼️ [显示] 找到图片数据，base64长度: \(base64Data.count)")
                #endif
                if let imageData = Data(base64Encoded: base64Data),
                   let uiImage = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.image = uiImage
                        #if DEBUG
                        print("✅ [显示] 成功从备份数据加载图片: \(imageId)")
                        #endif
                    }
                    return
                } else {
                    #if DEBUG
                    print("⚠️ [显示] base64解码失败: \(imageId)")
                    #endif
                }
            } else {
                #if DEBUG
                print("⚠️ [显示] 在备份数据中未找到图片: \(imageId), 可用ID: \(postImages.compactMap { $0["id"] as? String })")
                #endif
            }
        } else {
            #if DEBUG
            print("⚠️ [显示] 备份数据中没有postImages")
            #endif
        }
        
        // 方法2: 从本地文件系统加载（使用与ImageManager相同的逻辑）
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            #if DEBUG
            print("⚠️ [显示] 无法获取Documents目录")
            #endif
            return
        }
        
        // 图片保存在 PostImages/ 子目录中（与ImageManager保持一致）
        // 路径格式：Documents/PostImages/{id}.jpg
        let imagePath = documentsDirectory.appendingPathComponent("PostImages/\(imageId).jpg")
        
        if fileManager.fileExists(atPath: imagePath.path) {
            #if DEBUG
            print("🖼️ [显示] 找到文件: PostImages/\(imageId).jpg")
            #endif
            if let imageData = try? Data(contentsOf: imagePath),
               let uiImage = UIImage(data: imageData) {
                DispatchQueue.main.async {
                    self.image = uiImage
                    #if DEBUG
                    print("✅ [显示] 成功从文件系统加载图片: PostImages/\(imageId).jpg")
                    #endif
                }
                return
            }
        }
        
        // 如果PostImages目录下没有，尝试直接在Documents目录下查找（兼容旧格式）
        let alternativePath = documentsDirectory.appendingPathComponent("\(imageId).jpg")
        if fileManager.fileExists(atPath: alternativePath.path) {
            #if DEBUG
            print("🖼️ [显示] 找到文件（旧格式）: \(imageId).jpg")
            #endif
            if let imageData = try? Data(contentsOf: alternativePath),
               let uiImage = UIImage(data: imageData) {
                DispatchQueue.main.async {
                    self.image = uiImage
                    #if DEBUG
                    print("✅ [显示] 成功从文件系统加载图片（旧格式）: \(imageId).jpg")
                    #endif
                }
                return
            }
        }
        
        #if DEBUG
        print("⚠️ [显示] 无法从任何位置加载图片: \(imageId)")
        #endif
    }
}

struct BackupMessageRow: View {
    let message: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if let isFromUser = message["isFromUser"] as? Bool {
                    Text(isFromUser ? "我" : "角色")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isFromUser ? .blue : .purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(isFromUser ? Color.blue.opacity(0.1) : Color.purple.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                if let timestamp = message["timestamp"] as? String {
                    Text(timestamp)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if let content = message["content"] as? String {
                Text(content)
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct BackupConversationsListView: View {
    let conversations: [[String: Any]]
    
    var body: some View {
        List {
            Section(header: Text("所有私聊对话（\(conversations.count)）").textCase(nil)) {
                ForEach(Array(conversations.enumerated()), id: \.offset) { _, conversation in
                    NavigationLink(destination: BackupConversationDetailView(conversation: conversation)) {
                        BackupConversationRow(conversation: conversation)
                    }
                }
            }
        }
        .navigationTitle("私聊对话")
    }
}

struct BackupMultiPersonChatDetailView: View {
    let session: [String: Any]
    
    var body: some View {
        List {
            Section(header: Text("会话信息").textCase(nil)) {
                if let topic = session["topic"] as? String {
                    HStack {
                        Text("主题")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(topic)
                            .fontWeight(.medium)
                    }
                }
                
                if let participantNames = session["participantNames"] as? [String] {
                    HStack {
                        Text("参与者")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(participantNames.joined(separator: ", "))
                    }
                }
                
                if let messageCount = session["messageCount"] as? Int {
                    HStack {
                        Text("消息数")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(messageCount) 条")
                    }
                }
                
                if let createdAt = session["createdAt"] as? String {
                    HStack {
                        Text("创建时间")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(createdAt)
                    }
                }
            }
            
            if let messages = session["messages"] as? [[String: Any]], !messages.isEmpty {
                Section(header: Text("消息记录（\(messages.count)）").textCase(nil)) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { _, message in
                        BackupMultiPersonMessageRow(message: message)
                    }
                }
            }
        }
        .navigationTitle(session["topic"] as? String ?? "会话详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BackupMultiPersonMessageRow: View {
    let message: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if let characterName = message["characterName"] as? String {
                    Text(characterName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(4)
                } else if let isUserMessage = message["isUserMessage"] as? Bool, isUserMessage {
                    Text("我")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                if let timestamp = message["timestamp"] as? String {
                    Text(timestamp)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if let content = message["content"] as? String {
                Text(content)
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct BackupMultiPersonChatsListView: View {
    let sessions: [[String: Any]]
    
    var body: some View {
        List {
            Section(header: Text("所有多人对话（\(sessions.count)）").textCase(nil)) {
                ForEach(Array(sessions.enumerated()), id: \.offset) { _, session in
                    NavigationLink(destination: BackupMultiPersonChatDetailView(session: session)) {
                        MultiPersonChatRow(session: session)
                    }
                }
            }
        }
        .navigationTitle("多人对话")
    }
}

struct DataAchievementRow: View {
    let achievement: [String: Any]
    
    var body: some View {
        HStack(spacing: 10) {
            // 成就图标
            if let icon = achievement["icon"] as? String {
                Text(icon)
                    .font(.title3)
            } else {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                // 成就名称
                if let name = achievement["name"] as? String {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                // 进度信息
                HStack(spacing: 6) {
                    if let currentProgress = achievement["currentProgress"] as? Int,
                       let targetProgress = achievement["targetProgress"] as? Int {
                        Text("\(currentProgress)/\(targetProgress)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let level = achievement["level"] as? String {
                        Text(level)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(levelColor(level))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            // 解锁状态
            if let isUnlocked = achievement["isUnlocked"] as? Bool, isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func levelColor(_ level: String) -> Color {
        switch level {
        case "黄金": return Color(red: 0.95, green: 0.75, blue: 0.20)
        case "白银": return Color(red: 0.75, green: 0.82, blue: 0.95)
        case "青铜": return Color(red: 0.80, green: 0.52, blue: 0.25)
        default: return .gray
        }
    }
}

// MARK: - 分享组件

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 备份历史视图

struct BackupHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var backupService = iCloudBackupService.shared
    @StateObject private var dataManager = UserDataManager.shared
    @State private var backups: [BackupFile] = []
    @State private var showingDeleteAlert = false
    @State private var backupToDelete: BackupFile?
    @State private var showingRestoreAlert = false
    @State private var backupToRestore: BackupFile?
    @State private var isRestoring = false
    @State private var showingRestoreSuccess = false
    @State private var showingRestoreError = false
    @State private var restoreErrorMessage = ""
    @State private var selectedBackupForPreview: BackupFile?
    @State private var showingBackupPreview = false
    
    private var primaryAccentColor: Color {
        Color(hex: "9A8BB0")
    }
    
    var body: some View {
        List {
            if backups.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "icloud.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("暂无备份")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("您的备份文件将显示在这里")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            } else {
                Section {
                    ForEach(backups, id: \.url) { backup in
                        BackupRow(
                            backup: backup,
                            onDelete: {
                                backupToDelete = backup
                                showingDeleteAlert = true
                            },
                            onRestore: {
                                restoreBackup(backup)
                            },
                            onPreview: {
                                selectedBackupForPreview = backup
                                showingBackupPreview = true
                            }
                        )
                    }
                } header: {
                    Text("备份文件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.none)
                } footer: {
                    Text("备份文件保存在 iCloud Drive → 虫遇备份\n保留最新2个备份，防止换设备时丢失数据")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.background)
        .navigationTitle("备份历史")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .medium))
                    Text("账号管理")
                        .font(.system(size: 16, weight: .regular))
                }
                .foregroundColor(primaryAccentColor)
            }
        )
        .onAppear {
            loadBackups()
        }
        .refreshable {
            loadBackups()
        }
        .alert("删除备份", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {
                backupToDelete = nil
            }
            Button("删除", role: .destructive) {
                if let backup = backupToDelete {
                    deleteBackup(backup)
                }
            }
        } message: {
            if let backup = backupToDelete {
                Text("确定要删除备份文件「\(backup.fileName)」吗？\n\n⚠️ 重要提示：\n• 删除操作会从本地和 iCloud 云端同时删除\n• 此操作无法撤销，所有设备都将无法访问此备份\n• 建议在删除前确认不再需要此备份")
            }
        }
        .alert("恢复备份", isPresented: $showingRestoreAlert) {
            Button("取消", role: .cancel) {
                backupToRestore = nil
            }
            Button("恢复", role: .destructive) {
                if let backup = backupToRestore {
                    performRestore(backup)
                }
            }
        } message: {
            if let backup = backupToRestore {
                Text("确定要恢复备份文件「\(backup.fileName)」吗？\n\n⚠️ 注意：恢复操作会覆盖当前数据，请确保已备份当前数据。")
            }
        }
        .alert("恢复成功", isPresented: $showingRestoreSuccess) {
            Button("确定") {
                // 刷新数据
                NotificationCenter.default.post(name: NSNotification.Name("DataRestored"), object: nil)
            }
        } message: {
            Text("数据已成功恢复！\n\n请重启应用以确保所有数据正确显示。")
        }
        .alert("恢复失败", isPresented: $showingRestoreError) {
            Button("确定") {
                restoreErrorMessage = ""
            }
        } message: {
            Text(restoreErrorMessage)
        }
        .sheet(isPresented: $showingBackupPreview) {
            if let backup = selectedBackupForPreview {
                BackupPreviewView(backup: backup)
            }
        }
    }
    
    private func loadBackups() {
        backups = backupService.getAllBackups()
    }
    
    private func deleteBackup(_ backup: BackupFile) {
        do {
            try backupService.deleteBackup(at: backup.url)
            loadBackups()
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            print("删除备份失败: \(error)")
        }
    }
    
    private func restoreBackup(_ backup: BackupFile) {
        backupToRestore = backup
        showingRestoreAlert = true
    }
    
    private func performRestore(_ backup: BackupFile) {
        guard let backupData = backupService.loadBackup(from: backup) else {
            restoreErrorMessage = "无法读取备份文件，请检查文件是否损坏。"
            showingRestoreError = true
            return
        }
        
        isRestoring = true
        
        // 在后台线程执行恢复操作
        DispatchQueue.global(qos: .userInitiated).async {
            // 在主线程访问ModelContext（因为ModelContext是线程相关的）
            DispatchQueue.main.async {
                let success = self.dataManager.restoreUserData(from: backupData, modelContext: self.modelContext)
                
                self.isRestoring = false
                
                if success {
                    self.showingRestoreSuccess = true
                } else {
                    self.restoreErrorMessage = "恢复失败，请检查备份文件格式是否正确。"
                    self.showingRestoreError = true
                }
            }
        }
    }
}

struct BackupRow: View {
    let backup: BackupFile
    let onDelete: () -> Void
    let onRestore: () -> Void
    let onPreview: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(backup.fileName)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Label(backup.formattedDate, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(backup.formattedSize, systemImage: "doc")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onPreview) {
                    Image(systemName: "eye")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                        .frame(minWidth: 32, minHeight: 32)
                }
                .buttonStyle(.bordered)
                
                Button(action: onRestore) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("恢复")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .frame(minHeight: 32)
                }
                .buttonStyle(.bordered)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .frame(minWidth: 32, minHeight: 32)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 预览

struct AccountManagementView_Previews: PreviewProvider {
    static var previews: some View {
        AccountManagementView()
    }
} 