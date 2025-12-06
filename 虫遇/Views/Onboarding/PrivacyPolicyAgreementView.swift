import SwiftUI

/**
 * 隐私政策同意视图
 * 首次启动时显示，要求用户同意隐私政策和用户协议
 */
struct PrivacyPolicyAgreementView: View {
    @State private var hasAcceptedPrivacy = false
    @State private var hasAcceptedAgreement = false
    @State private var showingDocument: DocumentType? = nil
    
    enum DocumentType: Identifiable {
        case privacyPolicy
        case userAgreement
        
        var id: String {
            switch self {
            case .privacyPolicy: return "privacy"
            case .userAgreement: return "agreement"
            }
        }
    }
    
    // 主题颜色
    private var primaryAccentColor: Color {
        Color(hex: "9A8BB0")
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 背景
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部装饰区域
                topSection
                
                // 主要内容区域（可滚动）
                ScrollView {
                    contentSection
                        .padding(.bottom, 180) // 为底部按钮留出足够空间
                }
            }
            
            // 底部按钮区域（固定在底部，紧贴屏幕底部）
            bottomSection
        }
        .sheet(item: $showingDocument) { documentType in
            NavigationView {
                Group {
                    switch documentType {
                    case .privacyPolicy:
                        PolicyDocumentView(title: "隐私政策", documentText: PolicyDocument.privacyPolicy)
                    case .userAgreement:
                        PolicyDocumentView(title: "用户协议", documentText: PolicyDocument.userAgreement)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完成") {
                            showingDocument = nil
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 顶部区域
    
    private var topSection: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 60)
            
            // 应用图标或Logo
            Image(systemName: "shield.checkered")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(primaryAccentColor)
                .padding(.bottom, 8)
            
            Text("欢迎使用虫遇")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("在使用前，请阅读并同意我们的隐私政策和用户协议")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
                .frame(height: 20)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 内容区域
    
    private var contentSection: some View {
        VStack(spacing: 24) {
            // 隐私政策
            agreementCard(
                icon: "doc.text.fill",
                title: "隐私政策",
                description: "了解我们如何处理与保护您的数据",
                isAccepted: $hasAcceptedPrivacy,
                documentType: .privacyPolicy
            )
            
            // 用户协议
            agreementCard(
                icon: "book.closed.fill",
                title: "用户协议",
                description: "阅读服务条款与行为规范",
                isAccepted: $hasAcceptedAgreement,
                documentType: .userAgreement
            )
            
            // 说明文字
            VStack(spacing: 8) {
                Text("• 我们承诺保护您的隐私和数据安全")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("• 所有数据传输均经过加密处理")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("• 您可以随时在设置中查看完整的隐私政策")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
            .padding(.horizontal, 32)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
    }
    
    // MARK: - 协议卡片
    
    private func agreementCard(
        icon: String,
        title: String,
        description: String,
        isAccepted: Binding<Bool>,
        documentType: DocumentType
    ) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // 图标
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(primaryAccentColor)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(primaryAccentColor.opacity(0.1))
                    )
                
                // 文字内容
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 同意复选框
                Button(action: {
                    withAnimation {
                        isAccepted.wrappedValue.toggle()
                    }
                }) {
                    Image(systemName: isAccepted.wrappedValue ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isAccepted.wrappedValue ? primaryAccentColor : .gray)
                }
            }
            
            // 查看详情按钮
            Button(action: {
                showingDocument = documentType
            }) {
                HStack {
                    Text("查看详情")
                        .font(.caption)
                        .foregroundColor(primaryAccentColor)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(primaryAccentColor)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - 底部按钮
    
    private var bottomSection: some View {
        VStack(spacing: 16) {
            // 同意并继续按钮
            Button(action: {
                acceptAndContinue()
            }) {
                Text("同意并继续")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(hasAcceptedPrivacy && hasAcceptedAgreement ? primaryAccentColor : Color.gray)
                    )
            }
            .disabled(!hasAcceptedPrivacy || !hasAcceptedAgreement)
            
            // 不同意并退出按钮
            Button(action: {
                exitApp()
            }) {
                Text("不同意并退出")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .bottom)
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .overlay(alignment: .top) {
            // 顶部阴影线
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)
        }
        .background(DesignSystem.Colors.background)
        .ignoresSafeArea(edges: .bottom) // 让按钮可以延伸到安全区域，紧贴屏幕底部
    }
    
    // MARK: - 操作方法
    
    private func acceptAndContinue() {
        // 记录同意状态
        PrivacyPolicyManager.shared.acceptPrivacyPolicy()
        
        // 触发应用重新加载（通过通知）
        NotificationCenter.default.post(name: NSNotification.Name("PrivacyPolicyAccepted"), object: nil)
    }
    
    private func exitApp() {
        // 退出应用
        exit(0)
    }
}

// MARK: - 隐私政策管理器

class PrivacyPolicyManager {
    static let shared = PrivacyPolicyManager()
    
    private let hasAcceptedKey = "HasAcceptedPrivacyPolicy"
    private let acceptedVersionKey = "AcceptedPrivacyPolicyVersion"
    private let currentVersion = "1.0" // 如果隐私政策更新，可以增加版本号
    
    private init() {}
    
    /// 检查是否已同意隐私政策
    func hasAccepted() -> Bool {
        return UserDefaults.standard.bool(forKey: hasAcceptedKey)
    }
    
    /// 同意隐私政策
    func acceptPrivacyPolicy() {
        UserDefaults.standard.set(true, forKey: hasAcceptedKey)
        UserDefaults.standard.set(currentVersion, forKey: acceptedVersionKey)
        UserDefaults.standard.synchronize()
    }
    
    /// 检查是否需要重新同意（如果隐私政策版本更新）
    func needsReacceptance() -> Bool {
        let acceptedVersion = UserDefaults.standard.string(forKey: acceptedVersionKey) ?? "0.0"
        return acceptedVersion != currentVersion
    }
    
    /// 重置同意状态（用于测试）
    func resetAcceptance() {
        UserDefaults.standard.removeObject(forKey: hasAcceptedKey)
        UserDefaults.standard.removeObject(forKey: acceptedVersionKey)
        UserDefaults.standard.synchronize()
    }
}

// MARK: - 预览

struct PrivacyPolicyAgreementView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyAgreementView()
    }
}

