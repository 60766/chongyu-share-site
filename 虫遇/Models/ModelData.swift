import Foundation
import SwiftUI

/**
 * 模型数据提供类
 * 提供应用中使用的示例数据
 */
struct ModelData {
    // 示例评论数据
    static let sampleComments: [UserCommentModel] = [
        UserCommentModel(
            username: "李白",
            userAvatar: "person.fill",
            content: "青山遮不住，毕竟东流去。江湖几度夕阳红。",
            datePosted: Date().addingTimeInterval(-3600 * 24 * 3),
            likes: 42,
            isVirtualCharacter: true,
            characterID: "libai"
        ),
        UserCommentModel(
            username: "爱因斯坦",
            userAvatar: "atom",
            content: "想象力比知识更重要。知识是有限的，而想象力概括着世界上的一切。",
            datePosted: Date().addingTimeInterval(-3600 * 12),
            likes: 38,
            isVirtualCharacter: true,
            characterID: "einstein"
        ),
        UserCommentModel(
            username: "用户123",
            userAvatar: "person.circle",
            content: "这篇文章写得太好了，我获得了很多启发！",
            datePosted: Date().addingTimeInterval(-3600 * 5),
            likes: 15,
            isVirtualCharacter: false,
            characterID: nil
        ),
        UserCommentModel(
            username: "莎士比亚",
            userAvatar: "book.fill",
            content: "生活中最重要的事情是要有爱人的能力和被爱的能力。",
            datePosted: Date().addingTimeInterval(-3600 * 2),
            likes: 27,
            isVirtualCharacter: true,
            characterID: "shakespeare"
        ),
        UserCommentModel(
            username: "用户456",
            userAvatar: "person.2.circle",
            content: "感谢分享这么有价值的内容！",
            datePosted: Date().addingTimeInterval(-1800),
            likes: 8,
            isVirtualCharacter: false,
            characterID: nil
        ),
        UserCommentModel(
            username: "牛顿",
            userAvatar: "appletv.fill",
            content: "如果我比别人看得更远，那是因为我站在巨人的肩膀上。",
            datePosted: Date().addingTimeInterval(-3600 * 8),
            likes: 31,
            isVirtualCharacter: true,
            characterID: "newton"
        ),
        UserCommentModel(
            username: "用户789",
            userAvatar: "person.3.fill",
            content: "这个观点非常有见地，让我思考了很多。",
            datePosted: Date().addingTimeInterval(-900),
            likes: 5,
            isVirtualCharacter: false,
            characterID: nil
        ),
        UserCommentModel(
            username: "孔子",
            userAvatar: "scroll.fill",
            content: "学而不思则罔，思而不学则殆。",
            datePosted: Date().addingTimeInterval(-3600 * 36),
            likes: 48,
            isVirtualCharacter: true,
            characterID: "confucius"
        ),
        UserCommentModel(
            username: "用户101112",
            userAvatar: "person.fill.questionmark",
            content: "我对这个话题很感兴趣，有没有更多资料推荐？",
            datePosted: Date().addingTimeInterval(-300),
            likes: 2,
            isVirtualCharacter: false,
            characterID: nil
        ),
        UserCommentModel(
            username: "达芬奇",
            userAvatar: "paintpalette.fill",
            content: "简单是终极的复杂。",
            datePosted: Date().addingTimeInterval(-3600 * 18),
            likes: 36,
            isVirtualCharacter: true,
            characterID: "davinci"
        )
    ]

    // 模拟图片资源
    static let sampleImages: [String: String] = [
        // 爱因斯坦相关图片
        "einstein_portrait": "爱因斯坦肖像",
        "relativity_formula": "相对论公式图",
        "princeton_office": "普林斯顿办公室",
        
        // 达芬奇相关图片
        "davinci_workshop": "达芬奇工作室",
        "vitruvian_man": "维特鲁威人",
        "anatomical_studies": "解剖学研究",
        
        // 李白相关图片
        "libai_drinking": "李白饮酒图",
        "mountain_river": "山水画卷",
        "ancient_poem": "古诗手稿",
        "calligraphy": "书法作品"
    ]

    // 样本帖子数据 - 使用恰当的嵌套方式构建
    static let samplePosts: [UserPostModel] = {
        // 创建一些顶级评论和对应的回复
        // 示例1: 爱因斯坦的帖子
        var einsteinComment = sampleComments.first(where: { $0.characterID == "einstein" })!
        var shakespeareComment = sampleComments.first(where: { $0.characterID == "shakespeare" })!
        
        // 用户对爱因斯坦的回复
        let replyToEinstein1 = UserCommentModel(
            username: "科学爱好者",
            userAvatar: "person.circle",
            content: "爱因斯坦先生，您能解释一下时间相对性的概念吗？",
            datePosted: Date().addingTimeInterval(-3600 * 10),
            likes: 12,
            isVirtualCharacter: false,
            characterID: nil,
            parentCommentId: einsteinComment.id,
            replyToUsername: "爱因斯坦"
        )
        
        // 爱因斯坦对用户的回复
        let einsteinReply = UserCommentModel(
            username: "爱因斯坦",
            userAvatar: "atom",
            content: "时间相对性可以这样理解：当你坐在美丽姑娘旁边时，两小时感觉只有一分钟；当你坐在热炉子上时，一分钟感觉有两小时那么长。这就是相对论。",
            datePosted: Date().addingTimeInterval(-3600 * 9),
            likes: 28,
            isVirtualCharacter: true,
            characterID: "einstein",
            parentCommentId: replyToEinstein1.id,
            replyToUsername: "科学爱好者"
        )
        
        // 添加回复到评论中
        var modifiedReplyToEinstein1 = replyToEinstein1
        modifiedReplyToEinstein1.replies.append(einsteinReply)
        einsteinComment.replies.append(modifiedReplyToEinstein1)
        
        // 用户对莎士比亚的回复
        let replyToShakespeare = UserCommentModel(
            username: "文学爱好者",
            userAvatar: "person.2.circle",
            content: "莎翁，您认为爱情和理智哪个更重要？",
            datePosted: Date().addingTimeInterval(-3600 * 1),
            likes: 9,
            isVirtualCharacter: false,
            characterID: nil,
            parentCommentId: shakespeareComment.id,
            replyToUsername: "莎士比亚"
        )
        
        // 添加回复到莎士比亚评论中
        shakespeareComment.replies.append(replyToShakespeare)
        
        // 示例2: 达芬奇的帖子
        var davinciComment = sampleComments.first(where: { $0.characterID == "davinci" })!
        var newtonComment = sampleComments.first(where: { $0.characterID == "newton" })!
        
        // 用户对达芬奇的回复
        let replyToDavinci = UserCommentModel(
            username: "艺术学生",
            userAvatar: "person.circle",
            content: "达芬奇大师，能分享一下您的创作灵感来源吗？",
            datePosted: Date().addingTimeInterval(-3600 * 16),
            likes: 18,
            isVirtualCharacter: false,
            characterID: nil,
            parentCommentId: davinciComment.id,
            replyToUsername: "达芬奇"
        )
        
        // 达芬奇的回复
        let davinciReply = UserCommentModel(
            username: "达芬奇",
            userAvatar: "paintpalette.fill",
            content: "灵感来源于观察自然。大自然是最伟大的老师，它包含了一切完美的比例和规则。",
            datePosted: Date().addingTimeInterval(-3600 * 15),
            likes: 25,
            isVirtualCharacter: true,
            characterID: "davinci",
            parentCommentId: replyToDavinci.id,
            replyToUsername: "艺术学生"
        )
        
        // 添加嵌套回复
        var modifiedReplyToDavinci = replyToDavinci
        modifiedReplyToDavinci.replies.append(davinciReply)
        davinciComment.replies.append(modifiedReplyToDavinci)
        
        // 示例3: 李白和孔子的帖子
        var libaiComment = sampleComments.first(where: { $0.characterID == "libai" })!
        var confuciusComment = sampleComments.first(where: { $0.characterID == "confucius" })!
        
        // 用户对李白的回复
        let replyToLibai = UserCommentModel(
            username: "诗歌爱好者",
            userAvatar: "person.3.fill",
            content: "李白先生，您认为写诗最重要的是什么？",
            datePosted: Date().addingTimeInterval(-3600 * 24 * 2),
            likes: 22,
            isVirtualCharacter: false,
            characterID: nil,
            parentCommentId: libaiComment.id,
            replyToUsername: "李白"
        )
        
        // 李白的回复
        let libaiReply = UserCommentModel(
            username: "李白",
            userAvatar: "person.fill",
            content: "诗贵有灵气，要能表达内心真实的情感。'诗仙'之名我不敢当，唯有饮酒赋诗，逍遥人间。",
            datePosted: Date().addingTimeInterval(-3600 * 24 * 2 + 1800),
            likes: 31,
            isVirtualCharacter: true,
            characterID: "libai",
            parentCommentId: replyToLibai.id,
            replyToUsername: "诗歌爱好者"
        )
        
        // 添加嵌套回复
        var modifiedReplyToLibai = replyToLibai
        modifiedReplyToLibai.replies.append(libaiReply)
        libaiComment.replies.append(modifiedReplyToLibai)
        
        // 返回构建好的帖子数组
        return [
            UserPostModel(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
                username: "历史探索者",
                userAvatar: "person.fill",
                content: "今天与爱因斯坦探讨了关于相对论的一些基本原理，他的解释让我对时间和空间有了全新的认识。他说：\n\"想象你坐在一个美丽女孩身边，一小时会感觉像一分钟；但当你坐在一个滚烫的火炉上时，一分钟会感觉像一小时。这就是相对论。\"",
                images: ["einstein_portrait", "relativity_formula"],
                datePosted: Date().addingTimeInterval(-86400),
                likes: 128,
                comments: [einsteinComment, shakespeareComment],
                isLikedByCurrentUser: false,
                isBookmarkedByCurrentUser: false
            ),
            UserPostModel(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID(),
                username: "艺术爱好者",
                userAvatar: "person.2.fill",
                content: "拜访了达芬奇的工作室，他向我展示了他的绘画技巧和对解剖学的深入研究。他的《维特鲁威人》展现了完美的人体比例，体现了他对数学与艺术结合的追求。",
                images: ["davinci_workshop", "vitruvian_man", "anatomical_studies"],
                datePosted: Date().addingTimeInterval(-172800),
                likes: 86,
                comments: [davinciComment, newtonComment],
                isLikedByCurrentUser: true,
                isBookmarkedByCurrentUser: true
            ),
            UserPostModel(
                id: UUID(uuidString: "33333333-3333-3333-3333-333333333333") ?? UUID(),
                username: "诗词鉴赏家",
                userAvatar: "person.3.fill",
                content: "与李白畅饮江边，他即兴作诗：\"抽刀断水水更流，举杯消愁愁更愁。\" 诗仙果然名不虚传，短短数语便道尽人生苦乐。",
                images: ["libai_drinking", "mountain_river", "ancient_poem", "calligraphy"],
                datePosted: Date().addingTimeInterval(-259200),
                likes: 114,
                comments: [libaiComment, confuciusComment],
                isLikedByCurrentUser: false,
                isBookmarkedByCurrentUser: false
            )
        ]
    }()
} 