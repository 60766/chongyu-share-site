import SwiftUI

/**
 * 联系我们页面
 * 提供联系方式和反馈渠道
 */
struct ContactUsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // 统一的主题颜色
    private let primaryColor = Color(hex: "9A8BB0")
    
    var body: some View {
        ScrollView {
                VStack(spacing: 24) {
                    // 顶部图标
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(primaryColor)
                        
                        Text("联系我们")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("我们很乐意听取您的意见和建议")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // 联系方式卡片
                    VStack(spacing: 16) {
                        contactCard(
                            icon: "envelope.fill",
                            title: "邮箱反馈",
                            subtitle: "feedback@chongyu.app",
                            description: "发送邮件给我们，我们会在24小时内回复"
                        )
                        
                        contactCard(
                            icon: "message.fill",
                            title: "意见建议",
                            subtitle: "点击反馈问题",
                            description: "告诉我们您遇到的问题或改进建议"
                        )
                        
                        contactCard(
                            icon: "star.fill",
                            title: "应用评分",
                            subtitle: "App Store 评分",
                            description: "在应用商店为我们评分和评论"
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // 底部信息
                    VStack(spacing: 12) {
                        Divider()
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 8) {
                            Text("虫遇 - 穿越时空的对话")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("版本 1.0.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("感谢您使用虫遇，让历史人物与现代生活碰撞出精彩火花")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitle("联系我们", displayMode: .inline)
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
                    .foregroundColor(primaryColor)
                }
            )
    }
    
    // 联系方式卡片
    private func contactCard(icon: String, title: String, subtitle: String, description: String) -> some View {
        VStack(spacing: 0) {
            Button(action: {
                handleContactAction(for: title)
            }) {
                HStack(spacing: 16) {
                    // 图标
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(primaryColor)
                        .frame(width: 24, height: 24)
                    
                    // 内容
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(primaryColor)
                    }
                    
                    Spacer()
                    
                    // 箭头
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(20)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 描述文字
            HStack {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                Spacer()
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // 处理联系动作
    private func handleContactAction(for type: String) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        switch type {
        case "邮箱反馈":
            // 打开邮件应用
            if let url = URL(string: "mailto:feedback@chongyu.app?subject=虫遇应用反馈") {
                UIApplication.shared.open(url)
            }
        case "意见建议":
            // 这里可以打开应用内反馈页面或者外部反馈表单
            break
        case "应用评分":
            // 打开App Store评分页面
            if let url = URL(string: "https://apps.apple.com/app/idXXXXXXXXXX?action=write-review") {
                UIApplication.shared.open(url)
            }
        default:
            break
        }
    }
}

#Preview {
    ContactUsView()
} 