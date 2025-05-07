import SwiftUI
import UIKit

/**
 * 分享管理器
 * 处理应用内所有类型的分享功能
 */
class ShareManager {
    // 单例实例
    static let shared = ShareManager()
    
    // 依赖服务
    private let themeManager = ThemeManager.shared
    private let qrCodeGenerator = QRCodeGenerator.shared
    
    private init() {}
    
    /**
     * 分享角色信息
     * @param character 要分享的角色
     * @param viewController 当前视图控制器
     */
    func shareCharacter(_ character: Character, from viewController: UIViewController) {
        // 生成分享文本
        let shareText = "我在虫遇App中发现了一位穿越时空的对话者【\(character.name)】，\(character.introduction.prefix(100))..."
        
        // 生成分享图像
        let shareImage = generateCharacterShareImage(character)
        
        // 构建分享项目
        var items: [Any] = [shareText]
        if let image = shareImage {
            items.append(image)
        }
        
        // 显示系统分享菜单
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        viewController.present(activityVC, animated: true)
    }
    
    /**
     * 生成角色分享图像
     * @param character 角色信息
     * @return 返回可用于分享的UI图像
     */
    func generateCharacterShareImage(_ character: Character) -> UIImage? {
        // 获取角色主题
        let theme = themeManager.getCharacterTheme(for: character.id)
        
        // 创建分享卡片视图
        let shareCardView = CharacterShareCard(character: character, theme: theme)
        
        // 生成卡片图像
        return renderViewAsImage(shareCardView, size: CGSize(width: 375, height: 600))
    }
    
    /**
     * 分享对话记录
     * @param conversation 对话记录信息
     * @param characterName 角色名称
     * @param viewController 当前视图控制器
     */
    func shareConversation(_ conversation: Conversation, characterName: String, from viewController: UIViewController) {
        // 提取对话内容
        let messages = conversation.messages.prefix(5)
        
        // 生成分享文本
        var shareText = "我与【\(characterName)】的精彩对话：\n\n"
        
        for message in messages {
            let role = message.isUserMessage ? "我" : characterName
            shareText += "\(role): \(message.content)\n\n"
        }
        
        shareText += "\n来自虫遇App - 穿越时空的对话"
        
        // 生成分享图像
        let shareImage = generateConversationShareImage(conversation, characterName: characterName)
        
        // 构建分享项目
        var items: [Any] = [shareText]
        if let image = shareImage {
            items.append(image)
        }
        
        // 显示系统分享菜单
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        viewController.present(activityVC, animated: true)
    }
    
    /**
     * 生成对话记录分享图像
     * @param conversation 对话记录
     * @param characterName 角色名称
     * @return 返回可用于分享的UI图像
     */
    func generateConversationShareImage(_ conversation: Conversation, characterName: String) -> UIImage? {
        // 获取角色主题
        let theme = themeManager.getCharacterTheme(for: conversation.characterId)
        
        // 创建对话分享卡片视图
        let conversationShareView = ConversationShareCard(
            conversation: conversation,
            characterName: characterName,
            theme: theme
        )
        
        // 生成卡片图像
        return renderViewAsImage(conversationShareView, size: CGSize(width: 375, height: 650))
    }
    
    /**
     * 分享文章
     * @param article 文章内容
     * @param viewController 当前视图控制器
     */
    func shareArticle(_ article: Article, from viewController: UIViewController) {
        // 生成分享文本
        let shareText = "【\(article.title)】\n\n\(article.summary)\n\n来自虫遇App - 穿越时空的社交"
        
        // 生成分享图像
        let shareImage = generateArticleShareImage(article)
        
        // 构建分享项目
        var items: [Any] = [shareText]
        if let image = shareImage {
            items.append(image)
        }
        
        // 显示系统分享菜单
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        viewController.present(activityVC, animated: true)
    }
    
    /**
     * 生成文章分享图像
     * @param article 文章内容
     * @return 返回可用于分享的UI图像
     */
    func generateArticleShareImage(_ article: Article) -> UIImage? {
        // 获取默认主题
        let theme = themeManager.currentTheme
        
        // 创建文章分享卡片视图
        let articleShareView = ArticleShareCard(article: article, theme: theme)
        
        // 生成卡片图像
        return renderViewAsImage(articleShareView, size: CGSize(width: 375, height: 550))
    }
    
    /**
     * 将SwiftUI视图渲染为UIImage
     * @param view 要渲染的SwiftUI视图
     * @param size 渲染尺寸
     * @return 返回渲染后的UIImage
     */
    private func renderViewAsImage<T: View>(_ view: T, size: CGSize) -> UIImage? {
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: size)
        
        // 确保视图已布局
        controller.view.layoutIfNeeded()
        
        // 创建渲染上下文
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 渲染视图
        controller.view.layer.render(in: context)
        
        // 获取图像并结束上下文
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}

// 示例数据结构，根据实际项目结构修改或删除
struct Conversation {
    let id: String
    let characterId: String
    let messages: [Message]
    let createdAt: Date
}

struct Message {
    let content: String
    let isUserMessage: Bool
    let timestamp: Date
}

struct Article {
    let id: String
    let title: String
    let author: String
    let summary: String
    let content: String
    let coverImage: String?
    let publishDate: Date
}

struct Character: Identifiable {
    let id: String
    let name: String
    let avatarUrl: String
    let introduction: String
    let field: String
    let birthYear: String
    let deathYear: String?
    let achievements: [String]
    let keyThoughts: [String]
    let followerCount: Int
    let interactionCount: Int
    let rating: Double
}

// 角色分享卡片视图
private struct CharacterShareCard: View {
    let character: Character
    let theme: CharacterTheme
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题栏
            HStack {
                Text("虫遇·穿越时空对话")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.primary)
                
                Spacer()
                
                Text(formatDate(Date()))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // 角色信息
            HStack(alignment: .top, spacing: 15) {
                // 角色头像
                Image(character.avatarUrl)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(theme.primary.opacity(0.3), lineWidth: 2)
                    )
                
                // 角色基本信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(character.name)
                        .font(.system(size: 18, weight: .bold))
                    
                    Text("\(character.field) | \(character.birthYear)-\(character.deathYear ?? "现在")")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text(character.introduction.prefix(100) + "...")
                        .font(.system(size: 13))
                        .lineLimit(3)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // 底部二维码区域
            HStack {
                Text("扫码与\(character.name)对话")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 二维码预留位置
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "qrcode")
                        .font(.system(size: 24))
                        .foregroundColor(theme.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            // 水印
            Text("来自虫遇App·穿越时空的社交")
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.6))
                .padding(.bottom, 12)
        }
        .frame(width: 375, height: 600)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}

// 对话分享卡片视图
private struct ConversationShareCard: View {
    let conversation: Conversation
    let characterName: String
    let theme: CharacterTheme
    
    var body: some View {
        VStack(spacing: 12) {
            // 标题栏
            HStack {
                Text("与\(characterName)的对话")
                    .font(.system(size: 16, weight: .medium))
                
                Spacer()
                
                Text(formatDate(conversation.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // 对话消息列表
            VStack(spacing: 12) {
                ForEach(Array(conversation.messages.prefix(5).enumerated()), id: \.element.content) { index, message in
                    MessageBubble(
                        content: message.content,
                        isUser: message.isUserMessage,
                        theme: theme
                    )
                }
            }
            .padding(.horizontal, 15)
            
            Spacer()
            
            // 底部信息
            Text("来自虫遇App·穿越时空的对话")
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.6))
                .padding(.bottom, 15)
        }
        .frame(width: 375, height: 650)
        .background(Color(.systemBackground))
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter.string(from: date)
    }
}

// 消息气泡组件
private struct MessageBubble: View {
    let content: String
    let isUser: Bool
    let theme: CharacterTheme
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            Text(content)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isUser ? theme.primary.opacity(0.8) : Color(.systemGray5)
                )
                .foregroundColor(isUser ? .white : .primary)
                .cornerRadius(16)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 270, alignment: isUser ? .trailing : .leading)
            
            if !isUser { Spacer() }
        }
    }
}

// 文章分享卡片视图
private struct ArticleShareCard: View {
    let article: Article
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题栏
            HStack {
                Text("虫遇·文章分享")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.primaryColor)
                
                Spacer()
                
                Text(formatDate(article.publishDate))
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
            
            // 文章摘要
            Text(article.summary)
                .font(.system(size: 15))
                .lineSpacing(4)
                .padding(.horizontal, 20)
                .padding(.top, 8)
            
            Spacer()
            
            // 底部信息
            Text("来自虫遇App·穿越时空的社交")
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.6))
                .padding(.bottom, 15)
        }
        .frame(width: 375, height: 550)
        .background(Color(.systemBackground))
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
} 