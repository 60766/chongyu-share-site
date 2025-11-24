import SwiftUI

/// 账号找回视图
/// 提供通过 Apple ID 或 Token 找回账号的功能
struct AccountRestoreView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var accountManager = AppAccountManager.shared
    @StateObject private var appleSignInManager = AppleSignInManager.shared
    
    @State private var restoreToken: String = ""
    @State private var isRestoring = false
    @State private var restoreError: TokenRestoreError?
    @State private var showingSuccessAlert = false
    @State private var restoredToken: String?
    
    var body: some View {
        List {
            // 找回方式说明
            restoreMethodsSection
            
            // Apple ID 找回
            appleIDRestoreSection
            
            // Token 找回
            tokenRestoreSection
        }
        .listStyle(InsetGroupedListStyle())
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.background)
        .navigationTitle("找回账号")
        .navigationBarTitleDisplayMode(.inline)
        .alert("找回成功", isPresented: $showingSuccessAlert) {
            Button("确定") {
                dismiss()
            }
        } message: {
            if let token = restoredToken {
                Text("账号已成功找回！\n账号标识: \(String(token.prefix(8)))...")
            } else {
                Text("账号已成功找回！")
            }
        }
        .alert("找回失败", isPresented: Binding(
            get: { restoreError != nil },
            set: { if !$0 { restoreError = nil } }
        )) {
            Button("确定") {
                restoreError = nil
            }
        } message: {
            if let error = restoreError {
                Text(error.localizedDescription)
            }
        }
    }
    
    // MARK: - 找回方式说明
    
    private var restoreMethodsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("找回账号方式")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "applelogo")
                            .foregroundColor(.black)
                            .font(.system(size: 16))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Apple ID 找回（推荐）")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("如果您之前绑定了 Apple ID，直接登录即可自动找回账号和余额")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "key.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("账号标识找回")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("如果您保存了账号标识（UUID），可以输入完整标识来找回账号")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Apple ID 找回
    
    private var appleIDRestoreSection: some View {
        Section {
            if appleSignInManager.isSignedIn {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("已通过 Apple ID 登录，账号已自动找回")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 12) {
                    AppleSignInButton(
                        buttonType: .signIn,
                        buttonStyle: .black
                    )
                    
                    Text("使用 Apple ID 登录后，系统会自动查找并恢复您的账号")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("Apple ID 找回")
        }
    }
    
    // MARK: - Token 找回
    
    private var tokenRestoreSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("请输入您的完整账号标识（UUID）")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("例如: 550e8400-e29b-41d4-a716-446655440000", text: $restoreToken)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .disabled(isRestoring)
                
                HStack {
                    Button(action: {
                        // 从剪贴板粘贴
                        if let clipboard = UIPasteboard.general.string {
                            restoreToken = clipboard
                        }
                    }) {
                        HStack {
                            Image(systemName: "doc.on.clipboard")
                            Text("从剪贴板粘贴")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button(action: {
                        // 复制当前账号标识（如果已登录）
                        let currentIdentifier = accountManager.fullAccountIdentifier
                        if !currentIdentifier.contains("@") {
                            // 如果是 token，复制它
                            UIPasteboard.general.string = accountManager.appAccountToken
                        } else {
                            // 如果是邮箱，提示用户
                            UIPasteboard.general.string = accountManager.appAccountToken
                        }
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("复制当前标识")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
                
                Button(action: {
                    restoreAccount()
                }) {
                    HStack {
                        if isRestoring {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(isRestoring ? "找回中..." : "找回账号")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRestoring || restoreToken.isEmpty)
            }
            .padding(.vertical, 8)
        } header: {
            Text("账号标识找回")
        } footer: {
            Text("账号标识是一个 36 位的 UUID，格式如：550e8400-e29b-41d4-a716-446655440000\n\n您可以在账号管理页面复制完整的账号标识。")
                .font(.caption2)
        }
    }
    
    // MARK: - 操作方法
    
    private func restoreAccount() {
        guard !restoreToken.isEmpty else { return }
        
        isRestoring = true
        restoreError = nil
        
        accountManager.restoreAccountWithToken(restoreToken) { result in
            isRestoring = false
            
            switch result {
            case .success(let token):
                restoredToken = token
                showingSuccessAlert = true
                // 延迟关闭页面，让用户看到成功提示
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            case .failure(let error):
                restoreError = error
            }
        }
    }
}

// MARK: - 预览

struct AccountRestoreView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccountRestoreView()
        }
    }
}

