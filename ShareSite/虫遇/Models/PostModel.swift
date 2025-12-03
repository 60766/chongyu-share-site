import Foundation
import SwiftUI

/**
 * 帖子数据模型
 * 用于管理应用中的历史人物发布的动态内容
 */
struct PostModel: Identifiable {
    let id = UUID()
    let author: CharacterModel  // 发布帖子的历史人物
    let content: String         // 帖子内容
    let timestamp: String       // 发布时间
    let tags: [String]          // 标签
    let likeCount: Int          // 点赞数
    let commentCount: Int       // 评论数
    let comments: [SimpleCommentModel]? // 评论列表
    
    // 示例帖子数据
    static let samplePosts: [PostModel] = [
        // 爱因斯坦的帖子
        PostModel(
            author: CharacterModel.sampleCharacters[0],
            content: "今天思考了一个有趣的问题: 如果光以相同的速度向所有观察者移动，那么时间和空间对不同观察者来说必然是相对的。这就是我相对论的基础。你们觉得呢?",
            timestamp: "2小时前",
            tags: ["物理学思考", "相对论"],
            likeCount: 2400,
            commentCount: 367,
            comments: [
                SimpleCommentModel(
                    author: CharacterModel.sampleCharacters[2],
                    content: "爱因斯坦先生，作为一个来自文艺复兴时期的人，你的相对论概念对我而言非常超前。不过我很好奇，这种相对性是否也能应用于艺术中的透视原理?",
                    timestamp: "1小时前"
                )
            ]
        ),
        // 莎士比亚的帖子
        PostModel(
            author: CharacterModel.sampleCharacters[1],
            content: "生活如戏，人人皆是演员。我们在这个世界舞台上扮演着不同的角色，有时喜剧，有时悲剧。你们更喜欢哪种角色？",
            timestamp: "3小时前",
            tags: ["戏剧人生", "莎士比亚"],
            likeCount: 1800,
            commentCount: 245,
            comments: nil
        )
    ]
}

/**
 * 简单评论数据模型
 * 用于旧版UI展示的简化评论模型
 */
struct SimpleCommentModel: Identifiable {
    let id = UUID()
    let author: CharacterModel  // 评论者（历史人物）
    let content: String         // 评论内容
    let timestamp: String       // 评论时间
} 