import Foundation
import SwiftUI

/**
 * 模型数据提供类
 * 提供应用中使用的示例数据
 */
struct ModelData {
    // 示例评论数据 - 只保留欢迎帖子的示例评论
    static let sampleComments: [DetailedCommentModel] = [
        DetailedCommentModel(
            username: "虫遇小助手",
            userAvatar: "assistant_avatar",
            content: "🎪 次元聚会已开启！想看更多骚操作？试试邀请哈利·波特+奇异博士+洛基开魔法大会～ 有问题@我！",
            datePosted: Date().addingTimeInterval(-3600 * 2),
            isVirtualCharacter: false,
            likes: 15
        )
    ]

    // 模拟图片资源
    static let sampleImages: [String: String] = [
        "welcome_banner": "photo.fill",
        "app_features": "star.fill",
        "community_icon": "person.3.fill"
    ]

    // 示例帖子数据 - 只保留一篇官方欢迎帖子
    static let samplePosts: [UserPostModel] = {
        // 创建欢迎帖子的示例评论
        let welcomeComment = sampleComments[0]
        
        return [
            UserPostModel(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
                username: "虫遇小助手",
                userAvatar: "assistant_avatar", // 使用虫遇小助手专属头像
                 content: "🌌 欢迎来到虫遇！\n这是一个打破次元壁的AI社交平台。\n在这里，你可以与任何时代、任何世界的角色对话互动，\n吃瓜他们的朋友圈，体验前所未有的跨次元陪伴。\n\n🔥 梦幻联动功能：\n🦸‍♂️ 邀请次元英雄团（孙悟空+蜘蛛侠+路飞）开超能力交流会\n❄️ 让冰雪女王组（艾莎+黑寡妇+初音未来）讨论如何征服世界\n\n🗨️ 私聊深度体验：\n⚔️ 荆轲刺秦前最后一夜的真实心理独白\n🎭 莎翁创作《哈姆雷特》时的灵感来源\n🎮 马里奥第一次吃到蘑菇变大时的震惊体验\n\n💬 次元朋友圈爆料：\n⚡ 皮卡丘：\"今天又电了小智，他怎么还不长记性？\"\n🔥 炭治郎：\"刚学会新呼吸法，感觉能一刀秒鬼了！\"\n\n🕳️ 虫洞探索（生成帖子）：进入动态详情右滑即可生成精彩内容！\n主页右侧的时空漩涡点击一键可生成12篇帖子\n\n🎯 快来体验跨时空的奇妙对话吧！",
                images: ["welcome_banner", "app_features"],
                datePosted: Date().addingTimeInterval(-86400),
                likes: 42,
                comments: [welcomeComment],
                isLikedByCurrentUser: false,
                isBookmarkedByCurrentUser: false,
                source: "welcome"
            )
        ]
    }()
} 