import SwiftUI

// 简单的条件修饰符，便于按需添加阴影等效果
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
import SwiftUI

/**
 * 分享相关UI组件
 * 提供各种与分享功能相关的UI组件和辅助函数
 */

// 分享按钮组件
struct ShareButton: View {
    let title: String
    let icon: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
            }
        }
    }
}

// 角色分享卡片组件
struct CharacterShareCardView: View {
    var character: Character
    var theme: CharacterTheme
    var themeManager: ThemeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // 顶部标题栏
            HStack {
                Text("虫遇·穿越时空对话")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(theme.primary.opacity(0.1))
                    )
                
                Spacer()
                
                // 时间戳
                Text(formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            
            // 角色信息区
            HStack(spacing: 16) {
                // 角色头像
                characterAvatar
                
                VStack(alignment: .leading, spacing: 5) {
                    // 角色名称
                    Text(character.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    // 角色描述
                    Text(characterDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    // 标签
                    if !character.keyThoughts.isEmpty {
                        Text(character.keyThoughts[0].prefix(15) + (character.keyThoughts[0].count > 15 ? "..." : ""))
                            .font(.system(size: 12))
                            .foregroundColor(theme.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(theme.primary.opacity(0.1))
                            )
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // 分割线
            Divider()
                .padding(.horizontal, 20)
            
            // 简介内容
            VStack(alignment: .leading, spacing: 10) {
                Text("简介")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(character.introduction.prefix(120) + (character.introduction.count > 120 ? "..." : ""))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 20)
            
            // 数据统计
            HStack(spacing: 20) {
                // 粉丝数
                DataStatItem(
                    value: formatNumber(character.followerCount),
                    label: "粉丝",
                    color: theme.primary
                )
                
                // 互动量
                DataStatItem(
                    value: formatNumber(character.interactionCount),
                    label: "互动",
                    color: theme.primary
                )
                
                // 评分
                DataStatItem(
                    value: String(format: "%.1f", character.rating),
                    label: "评分",
                    color: theme.primary
                )
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(Color.gray.opacity(0.05))
            
            // 二维码区域
            HStack {
                // 文本提示
                VStack(alignment: .leading, spacing: 4) {
                    Text("扫码穿越时空")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("与\(character.name)对话")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 二维码
                QRCodePlaceholder(theme: theme)
            }
            .padding(.horizontal, 20)
            
            // 底部水印
            Text("来自虫遇App·穿越时空的社交")
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                .padding(.top, 5)
        }
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.07), radius: 15, x: 0, y: 5)
        )
    }
    
    // 格式化日期
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: Date())
    }
    
    // 格式化角色描述
    private var characterDescription: String {
        return "\(character.field) | \(character.birthYear)-\(character.deathYear ?? "现在")"
    }
    
    // 格式化数字显示
    private func formatNumber(_ number: Int) -> String {
        if number < 1000 {
            return "\(number)"
        } else if number < 10000 {
            let thousands = Double(number) / 1000.0
            return String(format: "%.1fK", thousands)
        } else {
            let tenThousands = Double(number) / 10000.0
            return String(format: "%.1f万", tenThousands)
        }
    }
    
    // 角色头像视图
    private var characterAvatar: some View {
        Group {
            if let _ = UIImage(named: character.avatarUrl) {
                Image(character.avatarUrl)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(theme.primary.opacity(0.3), lineWidth: 2)
                    )
            } else {
                Circle()
                    .fill(theme.primary.opacity(0.1))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Text(String(character.name.prefix(1)))
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(theme.primary)
                    )
            }
        }
    }
}

// 会话分享卡片组件
struct ConversationShareCardView: View {
    var conversation: Conversation
    var character: Character
    var theme: CharacterTheme
    var themeManager: ThemeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // 顶部标题栏
            HStack {
                Text("与\(character.name)的对话")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 时间戳
                Text(formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // 对话内容
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(conversation.messages.prefix(5).enumerated()), id: \.element.timestamp) { _, message in
                        MessageBubbleView(
                            content: message.content,
                            isUser: message.isUserMessage,
                            theme: theme
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 350)
            
            // 二维码和提示
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("扫码继续对话")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("与来自\(character.birthYear)年的\(character.name)交流")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 二维码
                QRCodePlaceholder(theme: theme)
                    .frame(width: 60, height: 60)
            }
            .padding(.horizontal, 20)
            
            // 水印
            Text("来自虫遇App·穿越时空的对话")
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20)
                .padding(.bottom, 15)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.07), radius: 15, x: 0, y: 5)
    }
    
    // 格式化日期
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter.string(from: conversation.createdAt)
    }
}

// 文章分享卡片组件
struct ArticleShareCardView: View {
    var article: Article
    var theme: AppTheme
    var themeManager: ThemeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // 顶部标题栏
            HStack {
                Text("虫遇·文章分享")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.primaryColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(theme.primaryColor.opacity(0.1))
                    )
                
                Spacer()
                
                // 日期
                Text(formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // 文章标题
            Text(article.title)
                .font(.system(size: 20, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // 作者信息
            Text("作者: \(article.author)")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            // 文章封面
            if let coverImage = article.coverImage, let _ = UIImage(named: coverImage) {
                Image(coverImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 160)
                    .clipped()
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
            }
            
            // 文章摘要
            Text(article.summary)
                .font(.system(size: 15))
                .lineSpacing(4)
                .padding(.horizontal, 20)
                .padding(.top, article.coverImage == nil ? 10 : 5)
            
            Spacer()
            
            // 二维码区域
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("扫码阅读全文")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // 二维码
                QRCodePlaceholder(theme: CharacterTheme(
                    primary: theme.primaryColor,
                    secondary: theme.secondaryColor,
                    background: theme.backgroundColor,
                    contentBackground: Color(.secondarySystemBackground)
                ))
                .frame(width: 60, height: 60)
            }
            .padding(.horizontal, 20)
            
            // 水印
            Text("来自虫遇App·穿越时空的社交")
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20)
                .padding(.bottom, 15)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.07), radius: 15, x: 0, y: 5)
    }
    
    // 格式化日期
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: article.publishDate)
    }
}

// 消息气泡视图
struct MessageBubbleView: View {
    let content: String
    let isUser: Bool
    let theme: CharacterTheme
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            Text(content)
                .font(.system(size: 15))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isUser ? theme.primary.opacity(0.9) : Color(.systemGray5)
                )
                .foregroundColor(isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .frame(maxWidth: 260, alignment: isUser ? .trailing : .leading)
            
            if !isUser { Spacer() }
        }
    }
}

// 数据统计项
struct DataStatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// 二维码占位符
struct QRCodePlaceholder: View {
    let theme: CharacterTheme
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.05))
                .frame(width: 64, height: 64)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.primary.opacity(0.2), lineWidth: 1)
                )
            
            // 简易二维码图案
            VStack(spacing: 2) {
                ForEach(0..<3) { _ in
                    HStack(spacing: 2) {
                        ForEach(0..<3) { _ in
                            Rectangle()
                                .fill(theme.primary.opacity(0.3))
                                .frame(width: 5, height: 5)
                        }
                    }
                }
            }
            
            // 中心Logo
            Image(systemName: "atom")
                .font(.system(size: 14))
                .foregroundColor(theme.primary)
        }
    }
} 