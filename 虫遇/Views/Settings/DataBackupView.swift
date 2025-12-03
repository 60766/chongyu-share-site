import SwiftUI
import SwiftData

/// 数据备份视图
/// 提供数据备份、恢复、历史查看等功能
struct DataBackupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var backupService = iCloudBackupService.shared
    @StateObject private var dataManager = UserDataManager.shared
    
    @State private var exportPayload: ExportPayload?
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
    
    /// 安全获取状态颜色，如果不存在则返回默认颜色
    private func getStatusColor(_ key: String) -> Color {
        return statusColors[key] ?? statusColors["neutral"] ?? primaryAccentColor
    }
    
    var body: some View {
        List {
            // 立即备份
            Section {
                Button(action: exportUserData) {
                    DataManagementRow(
                        icon: "icloud.and.arrow.up.fill",
                        title: "立即备份",
                        subtitle: "保存当前数据状态到 iCloud Drive",
                        iconColor: getStatusColor("info")
                    )
                }
                .foregroundColor(.primary)
            } header: {
                Text("手动备份")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.none)
            }
            
            // 备份历史
            Section {
                NavigationLink(destination: BackupHistoryView()) {
                    DataManagementRow(
                        icon: "clock.arrow.circlepath",
                        title: "备份历史",
                        subtitle: getBackupHistorySubtitle(),
                        iconColor: getStatusColor("info")
                    )
                }
            } header: {
                Text("备份管理")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.none)
            } footer: {
                Text("备份保存在 iCloud Drive，保留最新2个备份")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.8))
            }
            
            // iCloud自动备份开关
            if backupService.isiCloudAvailable {
                Section {
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
                                if let lastBackup = backupService.lastBackupDate {
                                    Text("上次备份：\(formatBackupDate(lastBackup))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary.opacity(0.8))
                                } else {
                                    Text("尚未进行过备份")
                                        .font(.caption2)
                                        .foregroundColor(.secondary.opacity(0.8))
                                }
                                
                                if let nextBackup = backupService.nextBackupDate {
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
                                        Text("备份频率：每\(backupService.backupFrequencyDays)天")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("自动备份")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.none)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.background)
        .navigationTitle("数据备份")
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
                    Text("设置")
                        .font(.system(size: 16, weight: .regular))
                }
                .foregroundColor(primaryAccentColor)
            }
        )
        .sheet(item: $exportPayload) { payload in
            DataExportView(exportedData: payload.data)
        }
        .alert("开启自动备份", isPresented: $showingFirstBackupGuide) {
            Button("开启备份") {
                UserDefaults.standard.set(true, forKey: "iCloudAutoBackupEnabled")
                UserDefaults.standard.set(true, forKey: "HasSeenFirstBackupGuide")
                // 立即触发一次备份
                NotificationCenter.default.post(name: NSNotification.Name("PerformAutoBackup"), object: nil)
            }
            Button("稍后提醒") {
                UserDefaults.standard.set(true, forKey: "HasSeenFirstBackupGuide")
            }
        } message: {
            Text("检测到您已创建内容，建议开启自动备份以保护您的数据。备份将自动保存到iCloud Drive，换设备时也能恢复。")
        }
        .onAppear {
            // 检查是否需要显示首次备份引导
            checkAndShowFirstBackupGuide()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PerformAutoBackup"))) { _ in
            // 执行自动备份（在后台线程）
            performAutoBackupInBackground()
        }
    }
    
    // MARK: - 辅助方法
    
    private func getBackupHistorySubtitle() -> String {
        let backups = backupService.getAllBackups()
        if backups.isEmpty {
            return "暂无备份"
        } else {
            return "\(backups.count) 个备份"
        }
    }
    
    private func getBackupStatusSubtitle() -> String {
        let frequency = backupService.backupFrequencyDays
        return "每\(frequency)天自动备份"
    }
    
    private func getBackupStatusText() -> String {
        let status = backupService.backupStatus
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
        let status = backupService.backupStatus
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
        
        if hasContent && !backupEnabled && !hasSeenGuide && backupService.isiCloudAvailable {
            // 延迟显示，不打断用户当前操作
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showingFirstBackupGuide = true
            }
        }
    }
    
    // MARK: - 操作方法
    
    private func exportUserData() {
        let data = dataManager.exportUserData(modelContext: modelContext)
        
        // 检查是否需要自动备份
        if UserDefaults.standard.bool(forKey: "iCloudAutoBackupEnabled"),
           backupService.shouldAutoBackup() {
            backupService.performAutoBackup(data: data) { result in
                switch result {
                case .success:
                    #if DEBUG
                    print("✅ 自动备份成功")
                    #endif
                case .failure(let error):
                    #if DEBUG
                    print("❌ 自动备份失败: \(error.localizedDescription)")
                    #endif
                }
            }
        }
        
        exportPayload = ExportPayload(data: data)
    }
    
    private func performAutoBackupInBackground() {
        // 在后台线程执行数据导出
        DispatchQueue.global(qos: .utility).async {
            // 在主线程访问ModelContext（因为ModelContext是线程相关的）
            DispatchQueue.main.async {
                let data = self.dataManager.exportUserData(modelContext: self.modelContext)
                
                // 在后台线程执行iCloud保存
                DispatchQueue.global(qos: .utility).async {
                    self.backupService.performAutoBackup(data: data) { result in
                        switch result {
                        case .success:
                            #if DEBUG
                            print("✅ 自动备份成功")
                            #endif
                        case .failure(let error):
                            #if DEBUG
                            print("❌ 自动备份失败: \(error.localizedDescription)")
                            #endif
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 数据管理行组件

struct DataManagementRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

