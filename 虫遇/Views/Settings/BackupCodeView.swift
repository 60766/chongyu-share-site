import SwiftUI

/// 找回码管理视图
/// 提供查看、生成和使用找回码找回余额的功能
struct BackupCodeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var accountManager = AppAccountManager.shared
    
    // 主题颜色
    private var primaryAccentColor: Color {
        Color(hex: "9A8BB0")
    }
    
    @State private var showingBackupCode = false
    @State private var showingRestoreSheet = false
    @State private var showingRegenerateAlert = false
    @State private var showingUpgradeAlert = false
    @State private var restoreInput = ""
    @State private var isRestoring = false
    @State private var restoreError: BackupCodeError?
    @State private var showingRestoreSuccess = false
    @State private var restoreOutcome: RestoreOutcome? = nil
    @State private var showingLocalConfirm = false
    @State private var pendingLocalToken: String? = nil
    private var successMessage: String {
        guard let outcome = restoreOutcome else { return "" }
        switch outcome {
        case .serverHit:
            return "余额已找回，已同步您的账户余额与已购权益。昵称头像不随本次操作自动恢复，可在资料页自行调整。"
        case .localDerived:
            return "未找回余额：未在云端找到此找回码。已创建本地占位账号，可继续使用但不含历史余额。"
        }
    }
    
    var body: some View {
        List {
            // 找回码说明
            explanationSection
            
            // 当前找回码
            currentBackupCodeSection
            
            // 操作选项
            actionsSection
            
            // 余额找回
            restoreSection
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("找回码管理")
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
        .sheet(isPresented: $showingRestoreSheet) {
            RestoreAccountSheet(
                restoreInput: $restoreInput,
                isRestoring: $isRestoring,
                restoreError: $restoreError,
                onRestore: performRestore
            )
        }
        .alert("重新生成找回码", isPresented: $showingRegenerateAlert) {
            Button("取消", role: .cancel) { }
            Button("确认", role: .destructive) {
                regenerateBackupCode()
            }
        } message: {
            Text("重新生成找回码将使旧的找回码失效。请确保您已安全保存新的找回码。")
        }
        .alert("余额找回结果", isPresented: $showingRestoreSuccess) {
            Button("前往钱包") {
                dismiss()
            }
        } message: {
            Text(successMessage)
        }
        .alert("升级找回码格式", isPresented: $showingUpgradeAlert) {
            Button("取消", role: .cancel) { }
            Button("升级", role: .destructive) {
                upgradeBackupCodeFormat()
            }
        } message: {
            Text("检测到您使用的是旧格式找回码。建议升级为更易记忆的数字格式，原找回码将失效。")
        }
        .alert("未找回余额", isPresented: $showingLocalConfirm) {
            Button("取消", role: .cancel) {
                pendingLocalToken = nil
            }
            Button("创建并切换", role: .destructive) {
                if let token = pendingLocalToken {
                    let cleaned = restoreInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    accountManager.adoptLocalDerivedAccount(token: token, backupCode: cleaned)
                    showingRestoreSheet = false
                    restoreOutcome = .localDerived(token: token)
                    showingRestoreSuccess = true
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                    restoreInput = ""
                    pendingLocalToken = nil
                }
            }
        } message: {
            Text("未在云端找到此找回码。您可以创建一个本地占位账号继续使用（不含历史余额与权益）。是否继续？")
        }
    }
    
    // MARK: - 找回码说明
    
    private var explanationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("什么是找回码？")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Text("找回码是由12位数字组成的安全码，用于在设备丢失或更换设备时找回余额与已购权益。")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text("• 请将找回码保存在安全的地方\n• 不要与他人分享您的找回码\n• 如果找回码泄露，请立即重新生成")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - 当前找回码
    
    private var currentBackupCodeSection: some View {
        Section(header: Text("当前找回码")) {
            if let backupCode = accountManager.currentBackupCode {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(accountManager.needsBackupCodeUpgrade ? .orange : .green)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("您的找回码")
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            if accountManager.needsBackupCodeUpgrade {
                                Text("检测到旧格式，建议升级")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Spacer()
                        
                        if accountManager.needsBackupCodeUpgrade {
                            Button("升级") {
                                showingUpgradeAlert = true
                            }
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                        }
                        
                        Button(showingBackupCode ? "隐藏" : "显示") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingBackupCode.toggle()
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    if showingBackupCode {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(backupCode)
                                .font(.system(.title2, design: .monospaced))
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            
                            Button(action: {
                                UIPasteboard.general.string = backupCode
                            }) {
                                HStack {
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption)
                                    Text("复制找回码")
                                        .font(.caption)
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .padding(.vertical, 4)
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("未设置找回码")
                            .font(.body)
                            .foregroundColor(.primary)
                        Text("建议生成找回码以保护您的账号")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - 操作选项
    
    private var actionsSection: some View {
        Section(header: Text("管理选项")) {
            if accountManager.currentBackupCode == nil {
                // 生成找回码
                Button(action: generateBackupCode) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("生成找回码")
                                .foregroundColor(.primary)
                            Text("为您的账号生成安全找回码")
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
            } else {
                // 重新生成找回码
                Button(action: {
                    showingRegenerateAlert = true
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("重新生成找回码")
                                .foregroundColor(.primary)
                            Text("生成新的找回码并替换当前找回码")
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
            }
        }
    }
    
    // MARK: - 余额找回
    
    private var restoreSection: some View {
        Section(header: Text("余额找回")) {
            Button(action: {
                showingRestoreSheet = true
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("使用找回码找回余额")
                            .foregroundColor(.primary)
                        Text("验证并找回与找回码绑定的余额与权益")
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
        }
    }
    
    // MARK: - 操作方法
    
    private func generateBackupCode() {
        let newCode = accountManager.generateBackupCode()
        showingBackupCode = true
        
        // 提供触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("✅ 找回码已生成: \(newCode)")
    }
    
    private func regenerateBackupCode() {
        let newCode = accountManager.generateBackupCode()
        showingBackupCode = true
        
        // 提供触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("🔄 找回码已重新生成: \(newCode)")
    }
    
    private func upgradeBackupCodeFormat() {
        let newCode = accountManager.generateBackupCode()
        showingBackupCode = true
        
        // 强制刷新界面
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showingBackupCode = false
            self.showingBackupCode = true
        }
        
        // 提供触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("⬆️ 找回码格式已升级: \(newCode)")
    }
    
    private func performRestore() {
        guard !restoreInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isRestoring = true
        restoreError = nil
        
        accountManager.restoreAccountWithBackupCode(restoreInput.trimmingCharacters(in: .whitespacesAndNewlines)) { result in
            isRestoring = false
            
            switch result {
            case .success(let outcome):
                switch outcome {
                case .serverHit:
                    showingRestoreSheet = false
                    restoreInput = ""
                    restoreOutcome = outcome
                    showingRestoreSuccess = true
                    // 命中云端时刷新余额
                    Task { await WalletManager.shared.refreshBalance() }
                    // 提供成功反馈
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                case .localDerived(let token):
                    pendingLocalToken = token
                    showingLocalConfirm = true
                }
            case .failure(let error):
                restoreError = error
                
                // 提供错误反馈
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
            }
        }
    }
}

// MARK: - 余额找回弹窗

struct RestoreAccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var restoreInput: String
    @Binding var isRestoring: Bool
    @Binding var restoreError: BackupCodeError?
    let onRestore: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题和说明
                VStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    
                    Text("找回余额")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("请输入您的12位数字找回码，用短横线连接。该操作仅用于找回余额与已购权益，昵称头像等资料不会自动恢复。")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // 输入框
                VStack(alignment: .leading, spacing: 8) {
                    Text("找回码")
                        .font(.headline)
                    
                    TextField("例如: 123-456-789-012", text: $restoreInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .font(.system(.body, design: .monospaced))
                    
                    if let error = restoreError {
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // 操作按钮
                VStack(spacing: 12) {
                    Button(action: onRestore) {
                        HStack {
                            if isRestoring {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            Text(isRestoring ? "验证中..." : "找回余额")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canRestore ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!canRestore || isRestoring)
                    
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    private var canRestore: Bool {
        !restoreInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - 预览
struct BackupCodeView_Previews: PreviewProvider {
    static var previews: some View {
        BackupCodeView()
    }
} 