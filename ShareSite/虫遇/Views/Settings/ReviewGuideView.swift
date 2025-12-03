import SwiftUI

struct ReviewGuideView: View {
    private let sections: [ReviewSection] = [
        ReviewSection(
            title: "测试账号",
            items: [
                "Apple ID：reviewer@chongyuai.com",
                "密码：Chongyu2025!",
                "如需验证码，请联系 support@chongyuai.com"
            ],
            icon: "person.badge.key.fill",
            tint: Color(hex: "8E44AD")
        ),
        ReviewSection(
            title: "登录步骤",
            items: [
                "启动 App 后点击“使用 Apple 登录”。",
                "如提示绑定手机号，可跳过直接使用测试账号。"
            ],
            icon: "arrow.turn.down.right",
            tint: Color(hex: "5C9BD5")
        ),
        ReviewSection(
            title: "充值与虫洞币体验",
            items: [
                "进入“我的 > 钱包”查看当前余额。",
                "点击“充值”任意档位进行沙盒购买，流程包含 Apple 收据验证与后台确认。",
                "支付成功后可在同一界面查看成功提示与订单号。"
            ],
            icon: "diamond.fill",
            tint: Color(hex: "E67E22")
        ),
        ReviewSection(
            title: "核心功能路径",
            items: [
                "首页浏览角色列表，点击任意角色进入对话。",
                "在对话界面发送消息或使用底部快捷指令，体验 AI 回复。",
                "进入“发现”可查看虫洞动态与生成贴文的入口。"
            ],
            icon: "sparkles",
            tint: Color(hex: "27AE60")
        ),
        ReviewSection(
            title: "问题与支持",
            items: [
                "如遇闪退或无法登录，请在应用内“设置 > 联系我们”发送日志。",
                "也可以直接邮件至 support@chongyuai.com，团队会在 24 小时内响应。"
            ],
            icon: "questionmark.circle.fill",
            tint: Color(hex: "F39C12")
        )
    ]
    
    var body: some View {
        List {
            ForEach(sections) { section in
                Section {
                    ReviewSectionView(section: section)
                } header: {
                    Text(section.title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.none)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.background)
        .navigationTitle("审核使用说明")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ReviewSection: Identifiable {
    let id = UUID()
    let title: String
    let items: [String]
    let icon: String
    let tint: Color
}

private struct ReviewSectionView: View {
    let section: ReviewSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: section.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(section.tint.opacity(0.9))
                    )
                Text(section.title)
                    .font(.headline)
            }
            
            ForEach(section.items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(section.tint)
                    Text(item)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationView {
        ReviewGuideView()
    }
}

