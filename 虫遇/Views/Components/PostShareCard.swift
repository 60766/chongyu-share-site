import SwiftUI
import UIKit

/**
 * 主页面帖子卡片分享版本
 * 完全复制主页面PostCardView的视觉效果，确保每个细节都一致
 * 产品级优化：响应式尺寸、内容截断、视觉效果、多套色彩方案
 */

// MARK: - 色彩方案枚举
enum ShareCardColorScheme: CaseIterable {
    case vibrantPurple    // 鲜艳紫粉色系
    case oceanBlue        // 海洋蓝绿色系  
    case sunsetOrange     // 日落橙红色系
    
    var name: String {
        switch self {
        case .vibrantPurple: return "梦幻紫粉"
        case .oceanBlue: return "海洋蓝绿"
        case .sunsetOrange: return "日落橙红"
        }
    }
}

struct PostShareCard: View {
    let post: UserPostModel
    let includeFirstComment: Bool
    let colorScheme: ShareCardColorScheme
    
    // 分享卡片的最佳尺寸（适合社交平台分享）
    private let cardWidth: CGFloat = 375
    private let maxContentLines: Int = 8 // 内容最大行数，避免过长
    private let maxCommentLines: Int = 3 // 评论最大行数
    
    // MARK: - 色彩方案配置
    private var colorConfig: ColorConfiguration {
        switch colorScheme {
        case .vibrantPurple:
            return ColorConfiguration(
                gradientColors: [
                    Color(red: 0.6, green: 0.4, blue: 1.0),        // 鲜艳紫色
                    Color(red: 1.0, green: 0.3, blue: 0.7),        // 鲜艳粉色
                    Color(red: 0.2, green: 0.7, blue: 1.0),        // 鲜艳蓝色
                    Color(red: 1.0, green: 0.6, blue: 0.2)         // 鲜艳橙色
                ],
                borderColors: [
                    Color(red: 0.8, green: 0.6, blue: 1.0),
                    Color(red: 1.0, green: 0.5, blue: 0.8),
                    Color(red: 0.2, green: 0.7, blue: 1.0),
                    Color(red: 1.0, green: 0.6, blue: 0.2)
                ],
                shadowColors: [
                    Color(red: 0.6, green: 0.4, blue: 1.0),
                    Color(red: 1.0, green: 0.3, blue: 0.7),
                    Color(red: 0.2, green: 0.7, blue: 1.0)
                ],
                commentGradient: [
                    Color(red: 0.8, green: 0.6, blue: 1.0).opacity(0.15),
                    Color(red: 1.0, green: 0.5, blue: 0.8).opacity(0.12)
                ],
                brandColor: Color(red: 0.5, green: 0.3, blue: 0.9)
            )
            
        case .oceanBlue:
            return ColorConfiguration(
                gradientColors: [
                    Color(red: 0.0, green: 0.48, blue: 1.0),       // iOS系统蓝 (SF Blue)
                    Color(red: 0.2, green: 0.78, blue: 0.95),      // 青色 (SF Cyan) 
                    Color(red: 0.18, green: 0.82, blue: 0.35),     // 绿色 (SF Green)
                    Color(red: 0.0, green: 0.64, blue: 0.89)       // 青蓝色 (SF Teal)
                ],
                borderColors: [
                    Color(red: 0.2, green: 0.58, blue: 1.0),
                    Color(red: 0.3, green: 0.85, blue: 0.98),
                    Color(red: 0.28, green: 0.88, blue: 0.45),
                    Color(red: 0.1, green: 0.74, blue: 0.95)
                ],
                shadowColors: [
                    Color(red: 0.0, green: 0.48, blue: 1.0),
                    Color(red: 0.2, green: 0.78, blue: 0.95),
                    Color(red: 0.0, green: 0.64, blue: 0.89)
                ],
                commentGradient: [
                    Color(red: 0.2, green: 0.78, blue: 0.95).opacity(0.12),
                    Color(red: 0.18, green: 0.82, blue: 0.35).opacity(0.10)
                ],
                brandColor: Color(red: 0.0, green: 0.48, blue: 1.0)
            )
            
        case .sunsetOrange:
            return ColorConfiguration(
                gradientColors: [
                    Color(red: 1.0, green: 0.58, blue: 0.0),       // iOS橙色 (SF Orange)
                    Color(red: 1.0, green: 0.8, blue: 0.0),        // iOS黄色 (SF Yellow)
                    Color(red: 1.0, green: 0.27, blue: 0.23),      // iOS红色 (SF Red)
                    Color(red: 0.98, green: 0.39, blue: 0.76)      // iOS粉色 (SF Pink)
                ],
                borderColors: [
                    Color(red: 1.0, green: 0.68, blue: 0.1),
                    Color(red: 1.0, green: 0.88, blue: 0.1),
                    Color(red: 1.0, green: 0.37, blue: 0.33),
                    Color(red: 1.0, green: 0.49, blue: 0.83)
                ],
                shadowColors: [
                    Color(red: 1.0, green: 0.58, blue: 0.0),
                    Color(red: 1.0, green: 0.8, blue: 0.0),
                    Color(red: 1.0, green: 0.27, blue: 0.23)
                ],
                commentGradient: [
                    Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.12),
                    Color(red: 0.98, green: 0.39, blue: 0.76).opacity(0.10)
                ],
                brandColor: Color(red: 1.0, green: 0.58, blue: 0.0)
            )
        }
    }
    
    // MARK: - 色彩配置结构
    private struct ColorConfiguration {
        let gradientColors: [Color]
        let borderColors: [Color]
        let shadowColors: [Color]
        let commentGradient: [Color]
        let brandColor: Color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            // 用户信息部分
            userInfoSection
            
            // 内容部分
            contentSection
            
            // 评论预览部分 - 与主页面PostCardView完全一致
            if !post.comments.isEmpty && includeFirstComment {
                virtualCommentPreviewSection
                    .padding(.top, -6) // 与PostCardView一致的间距调整
            }
            
            // 轻量品牌标识 - 调整颜色与渐变背景和谐
            HStack {
                Spacer()
                Text("虫遇App · 穿越时空的社交")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(colorConfig.brandColor)
                Spacer()
            }
            .padding(.top, DesignSystem.Spacing.xs)
        }
        .padding(.top, 12) // 与PostCardView一致：减少顶部内边距
        .padding([.bottom, .horizontal], DesignSystem.Spacing.l) // 使用DesignSystem值
        .background(
            // 多层次渐变背景 - 增强视觉吸引力
            ZStack {
                // 主渐变背景 - 动态色彩方案
                LinearGradient(
                    gradient: Gradient(colors: colorConfig.gradientColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // 叠加层 - 保持内容可读性
                LinearGradient(
                    gradient: Gradient(colors: [
                        DesignSystem.Colors.background.opacity(0.9),
                        Color.white.opacity(0.85),
                        Color.white.opacity(0.92)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .cornerRadius(DesignSystem.Radius.card) // 使用DesignSystem值
        .overlay(
            // 外层精致边框 - 渐变色
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: colorConfig.borderColors.map { $0.opacity(0.8) }),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3.0
                )
        )
        .overlay(
            // 内层精致边框 - 白色高光
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card - 1)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
                .padding(1.5)
        )
        .shadow(
            color: Color.black.opacity(0.12), // 稍微减淡阴影强度
            radius: 12,
            x: 0,
            y: 0  // ✅ 关键修改：y=0 让阴影上下对称，便于精确裁剪
        )
        .frame(width: cardWidth) // ✅ 保留固定宽度，确保布局一致性
    }
    
    // MARK: - 用户信息区域（完全复制PostCardView）
    private var userInfoSection: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.m) {
            // 用户头像 - 使用真实的Avatar组件
            Avatar(
                url: post.userAvatar,
                name: post.username,
                category: post.username.contains("探索") ? "历史爱好者" : "",
                size: 46.0
            )
            .overlay(
                Circle()
                    .stroke(DesignSystem.Colors.border, lineWidth: DesignSystem.Borders.standard.width)
            )
            
            // 用户信息 - 更紧凑的布局
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    // 用户名 - 增加字体粗细区分
                    Text(post.username)
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .lineLimit(1) // 防止用户名过长
                    
                    // 用户标签 - 根据角色动态显示
                    if let tag = getUserTag(for: post.username) {
                        Text(tag)
                            .font(DesignSystem.Typography.caption2.weight(.medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(getTagColor(for: post.username))
                            )
                    }
                    
                    Spacer()
                
                    // 更多按钮
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16.0))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .padding(6.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // 发布时间与内容类型简化为一行
                HStack(spacing: 6) {
                    Text(post.getFormattedTimeAgo())
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text("•")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    // AI生成的帖子只显示"AI生成"
                    Text("AI生成")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
        .padding(.bottom, 6.0) // 与PostCardView一致
    }
    
    // MARK: - 内容区域（完全复制PostCardView + 优化截断）
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text(post.content)
                .font(DesignSystem.Typography.postContent)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineSpacing(6.0)
                .multilineTextAlignment(.leading)
                .lineLimit(maxContentLines) // 限制最大行数，避免内容过长
                .fixedSize(horizontal: false, vertical: true) // 确保文本正确换行
        }
    }
    
    // MARK: - 评论预览区域（增强视觉分离）
    private var virtualCommentPreviewSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            // 历史人物参与提示
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.orange)
                
                Text("\(post.comments.count)位历史人物参与")
                    .font(DesignSystem.Typography.caption.weight(.medium))
                    .foregroundColor(.orange)
            }
            .padding(.bottom, 4)
            
            // 显示第一条评论 - 添加背景和边框增强视觉分离
            if let firstComment = post.comments.first {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 10) {
                        // 评论者头像
                        Avatar(
                            url: firstComment.userAvatar,
                            name: firstComment.username,
                            category: "",
                            size: 32.0
                        )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            // 评论者信息
                            HStack(spacing: 6) {
                                Text(firstComment.username)
                                    .font(DesignSystem.Typography.subheadline.weight(.medium))
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                    .lineLimit(1) // 防止用户名过长
                                
                                // 角色标签
                                if let tag = getUserTag(for: firstComment.username) {
                                    Text(tag)
                                        .font(DesignSystem.Typography.caption2.weight(.medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(getTagColor(for: firstComment.username))
                                        )
                                }
                            }
                            
                            // 评论内容
                            Text(firstComment.content)
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                                .lineSpacing(5)
                                .lineLimit(maxCommentLines) // 限制评论行数
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                    }
                    
                    // 评论互动数据
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart")
                                .font(.system(size: 13))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            Text("\(firstComment.likes)")
                                .font(.system(size: 13))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "message")
                                .font(.system(size: 13))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            Text("1回复")
                                .font(.system(size: 13))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        // 历史人物标签
                        Text("历史人物")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(.orange.opacity(0.1))
                            )
                    }
                }
                .padding(12) // 内边距
                .background(
                    // 评论区域的鲜艳渐变背景
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        colorConfig.commentGradient[0],
                                        colorConfig.commentGradient[1],
                                        Color.white.opacity(0.95)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    colorConfig.borderColors[0].opacity(0.4),
                                    colorConfig.borderColors[1].opacity(0.35)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                )
                .shadow(
                    color: colorConfig.shadowColors[0].opacity(0.25),
                    radius: 6,
                    x: 0,
                    y: 3
                )
            }
        }
    }
    

    
    // MARK: - 辅助方法
    
    // 提取标题（如果内容以【】开头）
    private func extractTitle(from content: String) -> String? {
        if content.hasPrefix("【"), let endIndex = content.firstIndex(of: "】") {
            let titleEndIndex = content.index(after: endIndex)
            return String(content[content.startIndex..<titleEndIndex])
        }
        return nil
    }
    
    // 获取用户标签（与主页面PostCardView逻辑一致）
    private func getUserTag(for username: String) -> String? {
        if username.contains("探索") {
            return "历史爱好者"
        } else if username.contains("艾莎") || username == "艾莎女王" {
            return "冰雪女王"
        } else if username.contains("马尔克斯") {
            return "作家"
        } else if username.contains("杰洛特") {
            return "猎魔人"
        } else if username.contains("丹妮莉丝") {
            return "龙母"
        }
        return nil
    }
    
    // 获取标签颜色
    private func getTagColor(for username: String) -> Color {
        if username.contains("探索") {
            return .orange
        } else if username.contains("艾莎") || username == "艾莎女王" {
            return .blue
        } else if username.contains("马尔克斯") {
            return .green
        } else if username.contains("杰洛特") {
            return .brown
        } else if username.contains("丹妮莉丝") {
            return .red
        }
        return .purple
    }
}

// MARK: - 预览
struct PostShareCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 梦幻紫粉色系
            PostShareCard(
                post: UserPostModel.samplePosts.first ?? UserPostModel(
                    username: "杰洛特",
                    userAvatar: "geralt",
                    content: "【1275年，威伦沼泽】任务结束后的篝火旁，剑刃残留的腐肉味混合着沼泽瘴气。水鬼黏液在银剑上凝结成珠，滴落时发出灼烧草叶的嘶嘶声。二十步外，农妇递来的面包还在鞍袋里发硬——他们始终不敢靠近猎魔人的营火。今夜月光是淳油的琥珀色，让我想起所有没能收取的报酬。凯尔莫罕的老家伙们总说'剑油比信任更可靠'，可没人教过我们如何擦拭盔甲上凝固的恐惧。",
                    images: [],
                    datePosted: Date(),
                    likes: 148,
                    comments: [
                        DetailedCommentModel(
                            id: UUID(),
                            username: "星之卡比",
                            userAvatar: "kirby",
                            content: "哇哇哇！（甩动短手）吸入敌人的恐惧粘液沾满身体，下次试试用火魔法烤干！不过硬面包可以分我半块吗？（'ω'）",
                            datePosted: Date(),
                            isVirtualCharacter: true,
                            characterID: "kirby",
                            likes: 23
                        )
                    ],
                    isLikedByCurrentUser: false,
                    isBookmarkedByCurrentUser: false
                ),
                includeFirstComment: true,
                colorScheme: .vibrantPurple
            )
            .previewDisplayName("梦幻紫粉")
            
            // 海洋蓝绿色系
            PostShareCard(
                post: UserPostModel(
                    username: "海王波塞冬",
                    userAvatar: "poseidon",
                    content: "【深海宫殿，亚特兰蒂斯】海底的珊瑚花园在月光下闪闪发光，三叉戟的力量让海浪为我的意志而舞。今夜，我将唤醒沉睡在马里亚纳海沟的古老海兽，让它们守护这片蔚蓝的领域。",
                    images: [],
                    datePosted: Date(),
                    likes: 256,
                    comments: [
                        DetailedCommentModel(
                            id: UUID(),
                            username: "美人鱼爱丽儿",
                            userAvatar: "ariel",
                            content: "波塞冬陛下！海底世界的歌声如此美妙，请允许我为您歌唱一首赞美海洋的颂歌！🧜‍♀️🌊",
                            datePosted: Date(),
                            isVirtualCharacter: true,
                            characterID: "ariel",
                            likes: 89
                        )
                    ],
                    isLikedByCurrentUser: false,
                    isBookmarkedByCurrentUser: false
                ),
                includeFirstComment: true,
                colorScheme: .oceanBlue
            )
            .previewDisplayName("海洋蓝绿")
            
            // 日落橙红色系
            PostShareCard(
                post: UserPostModel(
                    username: "凤凰涅槃",
                    userAvatar: "phoenix",
                    content: "【火焰山巅，涅槃之夜】当夕阳西下，万里霞光如我羽翼般绚烂。今夜将是我第九十九次涅槃重生，烈火中诞生的不是毁灭，而是永恒的新生。让这橙红色的火焰，点燃每一个渴望重生的灵魂！",
                    images: [],
                    datePosted: Date(),
                    likes: 999,
                    comments: [
                        DetailedCommentModel(
                            id: UUID(),
                            username: "火神祝融",
                            userAvatar: "zhurong",
                            content: "凤凰姐姐威武！🔥 这火焰的温度刚好可以烤制天庭最美味的仙桃！下次涅槃记得通知我，我来助你一臂之力！",
                            datePosted: Date(),
                            isVirtualCharacter: true,
                            characterID: "zhurong",
                            likes: 188
                        )
                    ],
                    isLikedByCurrentUser: false,
                    isBookmarkedByCurrentUser: false
                ),
                includeFirstComment: true,
                colorScheme: .sunsetOrange
            )
            .previewDisplayName("日落橙红")
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.gray.opacity(0.1))
    }
} 