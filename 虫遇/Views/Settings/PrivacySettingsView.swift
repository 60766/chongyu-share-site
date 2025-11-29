import SwiftUI

/// 隐私设置界面
/// 提供AI服务说明、数据权利和隐私政策访问
struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // 主题颜色
    private var primaryAccentColor: Color {
        Color(hex: "9A8BB0")
    }
    
    var body: some View {
        List {
            thirdPartyServicesSection
            legalDocumentsSection
            contactSection
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
    
    // MARK: - AI服务说明
    
    private var thirdPartyServicesSection: some View {
        Section("服务说明") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("AI服务")
                        .font(.body)
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
    
    // MARK: - 法律文档
    
    private var legalDocumentsSection: some View {
        Section("法律与文档") {
            NavigationLink {
                PolicyDocumentView(title: "隐私政策", documentText: PolicyDocument.privacyPolicy)
            } label: {
                documentRow(icon: "doc.text", title: "隐私政策", subtitle: "了解我们如何处理与保护数据")
            }
            
            NavigationLink {
                PolicyDocumentView(title: "用户协议", documentText: PolicyDocument.userAgreement)
            } label: {
                documentRow(icon: "book.closed", title: "用户协议", subtitle: "阅读服务条款与行为规范")
            }
        }
    }
    
    private func documentRow(icon: String, title: String, subtitle: String) -> some View {
                HStack {
            Image(systemName: icon)
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                Text(title)
                            .foregroundColor(.primary)
                Text(subtitle)
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
    
    // MARK: - 联系方式
    
    private var contactSection: some View {
        Section("联系我们") {
            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(.green)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("客服邮箱")
                        .foregroundColor(.primary)
                    Text("support@chongyuai.com")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("写信") {
                    if let url = URL(string: "mailto:support@chongyuai.com") {
                    UIApplication.shared.open(url)
        }
    }
                .font(.footnote.weight(.semibold))
            }
        }
    }
}

// MARK: - 预览

struct PrivacySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacySettingsView()
    }
} 