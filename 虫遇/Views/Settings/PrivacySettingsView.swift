import SwiftUI

/// 隐私设置界面
/// 提供数据使用、分析统计等隐私相关设置
struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var accountManager = AppAccountManager.shared
    
    // 隐私设置状态
    @AppStorage("privacy_data_analytics") private var enableDataAnalytics = true
    @AppStorage("privacy_crash_reports") private var enableCrashReports = true
    @AppStorage("privacy_usage_stats") private var enableUsageStats = false
    @AppStorage("privacy_personalized_ads") private var enablePersonalizedAds = false
    @AppStorage("privacy_location_services") private var enableLocationServices = false
    
    // 主题颜色
    private var primaryAccentColor: Color {
        Color(hex: "9A8BB0")
    }
    
    var body: some View {
        List {
            // 数据收集设置
            dataCollectionSection
            
            // 账号隐私设置
            accountPrivacySection
            
            // 第三方服务
            thirdPartyServicesSection
            
            // 数据权限说明
            dataRightsSection
        }
        .listStyle(InsetGroupedListStyle())
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.background)
        .navigationTitle("隐私设置")
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
    
    // MARK: - 数据收集设置
    
    private var dataCollectionSection: some View {
        Section("数据收集") {
            
            // 数据分析
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("数据分析")
                        .font(.body)
                    Text("帮助改进应用功能和性能")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $enableDataAnalytics)
                    .labelsHidden()
            }
            .padding(.vertical, 4)
            
            // 崩溃报告
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("崩溃报告")
                        .font(.body)
                    Text("自动发送崩溃信息以修复问题")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $enableCrashReports)
                    .labelsHidden()
            }
            .padding(.vertical, 4)
            
            // 使用统计
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("使用统计")
                        .font(.body)
                    Text("收集功能使用频率和偏好")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $enableUsageStats)
                    .labelsHidden()
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - 账号隐私设置
    
    private var accountPrivacySection: some View {
        Section("账号隐私") {
            
            // 账号信息展示
            HStack {
                Image(systemName: "person.circle")
                    .foregroundColor(.primaryColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("账号标识")
                        .font(.body)
                    Text("ID: \(accountManager.accountDisplayId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("匿名")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            }
            .padding(.vertical, 4)
            
            // 个性化广告
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("个性化广告")
                        .font(.body)
                    Text("基于使用习惯显示相关广告")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $enablePersonalizedAds)
                    .labelsHidden()
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - 第三方服务
    
    private var thirdPartyServicesSection: some View {
        Section("第三方服务") {
            
            // 位置服务
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("位置服务")
                        .font(.body)
                    Text("用于天文观测功能（可选）")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $enableLocationServices)
                    .labelsHidden()
            }
            .padding(.vertical, 4)
            
            // AI服务说明
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("AI服务")
                        .font(.body)
                    
                    Spacer()
                    
                    Text("已启用")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Spacer().frame(width: 32)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• 对话内容仅用于生成回复")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• 不会存储或分享个人对话")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• 所有数据传输均已加密")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - 数据权限说明
    
    private var dataRightsSection: some View {
        Section("您的数据权利") {
            
            // 数据查看
            NavigationLink(destination: DataOverviewView()) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("查看我的数据")
                            .foregroundColor(.primary)
                        Text("查看应用收集的数据")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            
            // 数据导出
            NavigationLink(destination: AccountManagementView()) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("导出我的数据")
                            .foregroundColor(.primary)
                        Text("下载个人数据副本")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            
            // 隐私政策
            Button(action: {
                // 打开隐私政策
                if let url = URL(string: "https://chongyu.app/privacy") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("隐私政策")
                            .foregroundColor(.primary)
                        Text("了解我们如何保护您的隐私")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - 数据概览界面

struct DataOverviewView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataManager = UserDataManager.shared
    @StateObject private var accountManager = AppAccountManager.shared
    @StateObject private var profileManager = UserProfileManager.shared
    
    var body: some View {
        List {
            // 账号数据
            accountDataSection
            
            // 用户资料数据
            profileDataSection
            
            // 技术数据
            technicalDataSection
        }
        .listStyle(InsetGroupedListStyle())
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.background)
        .navigationTitle("我的数据")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: Button("完成") {
                dismiss()
            }
            .foregroundColor(.primaryColor)
        )
    }
    
    private var accountDataSection: some View {
        Section("账号数据") {
            dataRow(title: "账号ID", value: accountManager.accountDisplayId, isSecure: false)
            dataRow(title: "创建时间", value: formatDate(accountManager.accountCreationDate), isSecure: false)
            dataRow(title: "账号类型", value: "匿名账号", isSecure: false)
        }
    }
    
    private var profileDataSection: some View {
        Section("用户资料") {
            dataRow(title: "用户昵称", value: profileManager.username, isSecure: false)
            dataRow(title: "个人签名", value: profileManager.personalSignature, isSecure: false)
            dataRow(title: "用户等级", value: "Lv.\(profileManager.userLevel)", isSecure: false)
            dataRow(title: "头像设置", value: profileManager.avatarImageName, isSecure: false)
        }
    }
    

    
    private var technicalDataSection: some View {
        Section("技术数据") {
            dataRow(title: "设备型号", value: UIDevice.current.model, isSecure: false)
            dataRow(title: "系统版本", value: UIDevice.current.systemVersion, isSecure: false)
            dataRow(title: "应用版本", value: getAppVersion(), isSecure: false)
            dataRow(title: "使用语言", value: Locale.current.identifier, isSecure: false)
        }
    }
    
    private func dataRow(title: String, value: String, isSecure: Bool) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(isSecure ? "••••••" : value)
                .foregroundColor(.secondary)
                .font(.caption)
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        return "未知"
    }
}

// MARK: - 预览

struct PrivacySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacySettingsView()
    }
} 