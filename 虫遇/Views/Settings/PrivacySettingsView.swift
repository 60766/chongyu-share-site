import SwiftUI

/// 隐私设置界面
/// 提供AI服务说明、数据权利和隐私政策访问
struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingPrivacyPolicyAlert = false
    
    // 主题颜色
    private var primaryAccentColor: Color {
        Color(hex: "9A8BB0")
    }
    
    var body: some View {
        List {
            // AI服务说明
            thirdPartyServicesSection
            
            // 隐私政策
            privacyPolicySection
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
    
    // MARK: - 隐私政策
    
    private var privacyPolicySection: some View {
        Section {
            Button(action: {
                showingPrivacyPolicyAlert = true
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
        .alert("隐私政策", isPresented: $showingPrivacyPolicyAlert) {
            Button("通过邮件获取") {
                // 打开邮件应用
                if let url = URL(string: "mailto:li2410669277@gmail.com?subject=虫遇隐私政策请求") {
                    UIApplication.shared.open(url)
        }
    }
            Button("取消", role: .cancel) { }
        } message: {
            Text("隐私政策页面正在准备中。如需查看隐私政策，请通过邮件联系我们，我们会尽快为您提供。")
        }
    }
}

// MARK: - 预览

struct PrivacySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacySettingsView()
    }
} 