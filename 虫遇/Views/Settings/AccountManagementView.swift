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
    @StateObject private var securityManager = SecurityManager.shared
    @StateObject private var appleSignInManager = AppleSignInManager.shared
    
    @State private var showingLogoutAlert = false
    @State private var showingCreateNewAccountAlert = false
    @State private var showingSecurityAlert = false
    @State private var isLoggingOut = false
    @State private var exportPayload: ExportPayload?
    @State private var securityAlertMessage = ""
    @State private var showingDebugToken = false
    @State private var copiedToken = false
    
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
            // 账号信息区块
            accountInfoSection
            
            // Apple ID 登录区块
            appleSignInSection
            
            // 安全状态区块
            securityStatusSection
            
            // 数据管理区块
            dataManagementSection
            
            // 危险操作区块
            dangerZoneSection
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
        .alert("确认退出登录", isPresented: $showingLogoutAlert) {
            Button("取消", role: .cancel) { }
            Button("退出", role: .destructive) {
                performLogout()
            }
        } message: {
            Text("退出登录将清除所有本地数据，包括用户资料、自定义角色等。此操作不可恢复。")
        }
        .alert("创建新账号", isPresented: $showingCreateNewAccountAlert) {
            Button("取消", role: .cancel) { }
            Button("创建", role: .destructive) {
                createNewAccount()
            }
        } message: {
            Text("创建新账号将清除当前所有数据并生成新的账号ID。此操作不可恢复。")
        }
        .sheet(item: $exportPayload) { payload in
            DataExportView(exportedData: payload.data)
        }
        .alert("安全提示", isPresented: $showingSecurityAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(securityAlertMessage)
        }
    }
    
    // MARK: - 账号信息区块
    
    private var accountInfoSection: some View {
        Section {
            // 账号ID
            AccountInfoRow(
                icon: "person.circle.fill",
                title: "账号ID",
                value: formatAccountID(accountManager.accountDisplayId),
                iconColor: statusColors["info"]!,
                trailing: {
                    if accountManager.isNewAccount {
                        NewAccountBadge()
                    }
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
            
            #if DEBUG
            // 调试：显示真实 Token
            Button(action: {
                showingDebugToken = true
            }) {
                HStack {
                    Image(systemName: "ladybug.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("开发者选项")
                            .font(.body)
                            .foregroundColor(.primary)
                        Text("查看账号 Token")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            #endif
        } header: {
            Text("账号信息")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.none)
        } footer: {
            Text("您的账号信息由系统自动生成并安全存储")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .alert("账号 Token", isPresented: $showingDebugToken) {
            Button("复制") {
                UIPasteboard.general.string = accountManager.appAccountToken
                copiedToken = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    copiedToken = false
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text(accountManager.appAccountToken)
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
                    subtitle: appleSignInManager.userEmail ?? "邮箱未提供",
                    iconColor: Color.black,
                    trailing: {
                        Button("解绑") {
                            appleSignInManager.signOut()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                )
            } else {
                // Apple ID 登录按钮
                VStack(spacing: 12) {
                    AppleSignInButton(
                        buttonType: .signIn,
                        buttonStyle: colorScheme == .dark ? .white : .black
                    )
                    
                    Text("使用 Apple ID 登录可以更好地保护您的账号安全，并享受跨设备同步功能。")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
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
                Text("您的账号已与 Apple ID 关联，享受更高级别的安全保护")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.8))
            } else {
                Text("推荐使用 Apple ID 登录以获得更好的账号安全保障")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.8))
            }
        }
    }
    
    // MARK: - 安全状态区块
    
    private var securityStatusSection: some View {
        Section {
            // 设备安全
            Button(action: {
                securityManager.checkSecurityStatus()
                showSecurityDetails()
            }) {
                SecurityStatusRow(
                    icon: "shield.checkerboard",
                    title: "设备安全",
                    status: getSecurityStatusText(),
                    statusColor: getSecurityStatusColor(),
                    trailing: {
                        Text("检查")
                            .font(.caption)
                            .foregroundColor(primaryAccentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(primaryAccentColor.opacity(0.1))
                            .cornerRadius(4)
                    }
                )
            }
            .foregroundColor(.primary)
            
            // 生物识别
            SecurityStatusRow(
                icon: "touchid",
                title: "生物识别",
                status: securityManager.checkBiometricAvailability() == .none ? "不可用" : 
                       (securityManager.isBiometricEnabled ? "已启用" : "未启用"),
                statusColor: securityManager.checkBiometricAvailability() == .none ? statusColors["neutral"]! :
                           (securityManager.isBiometricEnabled ? statusColors["safe"]! : statusColors["warning"]!)
            )
            
            // 设备指纹
            SecurityStatusRow(
                icon: "laptopcomputer.and.iphone",
                title: "设备指纹",
                status: String(securityManager.generateDeviceFingerprint().prefix(16)) + "...",
                statusColor: statusColors["info"]!
            )
        } header: {
            Text("安全状态")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.none)
        }
    }
    
    // MARK: - 数据管理区块
    
    private var dataManagementSection: some View {
        Section {
            // 备份码管理
            NavigationLink(destination: BackupCodeView()) {
                DataManagementRow(
                    icon: "key.fill",
                    title: "找回码管理",
                    subtitle: "已设置找回码",
                    iconColor: statusColors["safe"]!,
                    trailing: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(statusColors["safe"]!)
                            .font(.system(size: 16))
                    }
                )
            }
            
            // 导出数据
            Button(action: exportUserData) {
                DataManagementRow(
                    icon: "square.and.arrow.up",
                    title: "导出数据",
                    subtitle: "备份您的用户资料和自定义角色",
                    iconColor: statusColors["info"]!
                )
            }
            .foregroundColor(.primary)
        } header: {
            Text("数据管理")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.none)
        } footer: {
            Text("定期备份数据可以保护您的个人资料和设置")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.8))
        }
    }
    
    // MARK: - 危险操作区块
    
    private var dangerZoneSection: some View {
        Section {
            // 创建新账号
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                showingCreateNewAccountAlert = true
            }) {
                DangerActionRow(
                    icon: "person.badge.plus",
                    title: "创建新账号",
                    subtitle: "将清除当前数据并生成新账号",
                    iconColor: statusColors["warning"]!
                )
            }
            
            // 退出登录
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
                showingLogoutAlert = true
            }) {
                DangerActionRow(
                    icon: "power",
                    title: "退出登录",
                    subtitle: "清除所有本地数据",
                    iconColor: statusColors["danger"]!,
                    trailing: {
                        if isLoggingOut {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: statusColors["danger"]!))
                                .scaleEffect(0.8)
                        }
                    }
                )
            }
            .disabled(isLoggingOut)
        } header: {
            Text("危险操作")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.none)
        } footer: {
            Text("这些操作将永久删除数据，请谨慎操作")
                .font(.caption2)
                .foregroundColor(statusColors["danger"]!.opacity(0.8))
        }
    }
    
    // MARK: - 操作方法
    
    private func performLogout() {
        isLoggingOut = true
        
        accountManager.logout { success in
            DispatchQueue.main.async {
                isLoggingOut = false
                if success {
                    dismiss()
                    NotificationCenter.default.post(
                        name: NSNotification.Name("AppShouldResetToInitialState"),
                        object: nil
                    )
                } else {
                    print("退出登录失败")
                }
            }
        }
    }
    
    private func createNewAccount() {
        accountManager.createNewAccount { newToken in
            DispatchQueue.main.async {
                print("新账号创建成功: \(String(newToken.prefix(8)))...")
                dismiss()
            }
        }
    }
    
    private func exportUserData() {
        let data = dataManager.exportUserData()
        
        DispatchQueue.main.async {
            self.exportPayload = ExportPayload(data: data)
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
    
    private func formatAccountID(_ id: String) -> String {
        let prefix = String(id.prefix(8))
        return "\(prefix)..."
    }
    
    private func formatCreationDate() -> String {
        return formatDate(accountManager.accountCreationDate)
    }
    
    private func getAccountAgeText() -> String {
        let days = accountManager.getAccountStats()["daysSinceCreation"] as? Int ?? 0
        return "\(days)天"
    }
    
    private func getSecurityStatusText() -> String {
        return securityManager.securityStatus.description
    }
    
    private func getSecurityStatusColor() -> Color {
        return Color(securityManager.securityStatus.color)
    }
    
    private func showSecurityDetails() {
        let message = securityManager.securityStatus.description
        securityAlertMessage = message
        showingSecurityAlert = true
    }
}

// MARK: - 账号管理专用组件

/// 账号信息行组件
struct AccountInfoRow<Trailing: View>: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String?
    let iconColor: Color
    let trailing: () -> Trailing
    
    init(
        icon: String,
        title: String,
        value: String,
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
                
                Text(value)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
                
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

/// 新账号标识
struct NewAccountBadge: View {
    var body: some View {
        Text("新账号")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "27AE60").opacity(0.15))
            )
            .foregroundColor(Color(hex: "27AE60"))
    }
}

/// 安全状态行组件
struct SecurityStatusRow<Trailing: View>: View {
    let icon: String
    let title: String
    let status: String
    let statusColor: Color
    let trailing: () -> Trailing
    
    init(
        icon: String,
        title: String,
        status: String,
        statusColor: Color,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.icon = icon
        self.title = title
        self.status = status
        self.statusColor = statusColor
        self.trailing = trailing
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(statusColor.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(statusColor)
            }
            
            // 内容
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)
                
                Text(status)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(statusColor)
            }
            
            Spacer()
            
            trailing()
        }
        .padding(.vertical, 2)
    }
}

/// 数据管理行组件
struct DataManagementRow<Trailing: View>: View {
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
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)
                
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
    
    @State private var showingShareSheet = false
    @State private var jsonString = ""
    @State private var showingCopySuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let data = exportedData {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 成功提示
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.green)
                                
                                Text("数据导出成功")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text("您的数据已准备好导出")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 20)
                            
                            // 成长记录卡片
                            if let highlights = data["highlights"] as? [String: Any] {
                                HighlightsCard(highlights: highlights)
                            }
                            
                            // 数据内容预览
                            DataPreviewCard(data: data)
                            
                            // 我的帖子预览
                            if let myCreations = data["myCreations"] as? [String: Any],
                               let posts = myCreations["posts"] as? [[String: Any]],
                               !posts.isEmpty {
                                PostsPreviewCard(posts: posts)
                            }
                            
                            // 操作按钮
                            VStack(spacing: 12) {
                                Button(action: shareData) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("分享数据文件")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                
                                Button(action: copyToClipboard) {
                                    HStack {
                                        Image(systemName: "doc.on.clipboard")
                                        Text("复制到剪贴板")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
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
            .navigationTitle("数据导出")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("关闭") {
                    dismiss()
                }
            )
            .onAppear {
                if let data = exportedData {
                    generateJSONString(from: data)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [jsonString])
            }
            .alert("复制成功", isPresented: $showingCopySuccess) {
                Button("确定") { }
            } message: {
                Text("数据已复制到剪贴板")
            }
        }
    }
    
    private func generateJSONString(from data: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            print("JSON序列化失败: \(error)")
            jsonString = "数据序列化失败"
        }
    }
    
    private func shareData() {
        showingShareSheet = true
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = jsonString
        showingCopySuccess = true
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
            
            VStack(alignment: .leading, spacing: 4) {
                Text(extractContent(from: post))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
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
                    VStack(alignment: .leading, spacing: 6) {
                        Text(extractContent(from: post))
                            .font(.body)
                            .foregroundColor(.primary)
                        
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
                    .padding(.vertical, 6)
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

// MARK: - 分享组件

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 预览

struct AccountManagementView_Previews: PreviewProvider {
    static var previews: some View {
        AccountManagementView()
    }
} 