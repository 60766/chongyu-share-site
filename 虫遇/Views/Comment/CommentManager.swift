import SwiftUI
import UIKit
import Combine
import Foundation

/**
 * 评论管理器
 * 
 * 负责处理评论的提交、回复和显示逻辑
 * 处理用户评论和虚拟角色回复
 */
class CommentManager: ObservableObject {
    // 当前帖子
    @Published var currentPost: UserPostModel
    // 所有评论（包括回复）
    @Published var allComments: [UserCommentModel] = []
    // 只包含顶级评论
    @Published var topLevelComments: [UserCommentModel] = []
    // 当前被回复的评论
    @Published var replyingToComment: UserCommentModel? = nil
    // 输入框内容
    @Published var commentText: String = ""
    
    // 用户信息
    private let currentUsername: String
    private let currentUserAvatar: String
    
    // 取消订阅标记
    private var cancellables = Set<AnyCancellable>()
    
    /**
     * 初始化评论管理器
     * @param post 当前帖子
     * @param username 当前用户名
     * @param userAvatar 当前用户头像
     */
    init(post: UserPostModel, username: String = "当前用户", userAvatar: String = "user_avatar") {
        self.currentPost = post
        self.currentUsername = username
        self.currentUserAvatar = userAvatar
        
        // 初始化评论列表
                updateCommentLists()
    }
    
    /**
     * 更新评论列表
     * 分离顶级评论和所有回复，并按小红书风格处理评论层级
     */
    func updateCommentLists() {
        // 获取所有顶级评论（不包含回复）
        var topLevelResults: [UserCommentModel] = []
        
        // 创建一个字典，用于将回复分组到各自的主评论下
        var commentMap: [UUID: UserCommentModel] = [:]
        
        // 先找出所有主评论
        for comment in currentPost.comments {
            if comment.parentCommentId == nil {
                var commentCopy = comment
                commentCopy.replies = [] // 清空回复列表，后面重新组织
                commentMap[comment.id] = commentCopy
                topLevelResults.append(commentCopy)
            }
        }
        
        // 将所有回复添加到对应的主评论下
        // 小红书风格：所有回复都作为一级回复，通过replyToUsername标记回复关系
        for comment in currentPost.comments {
            if let parentId = comment.parentCommentId {
                // 找到顶级父评论
                if let rootComment = findRootComment(for: comment, in: currentPost.comments) {
                    if let index = topLevelResults.firstIndex(where: { $0.id == rootComment.id }) {
                        topLevelResults[index].replies.append(comment)
                    }
                }
            }
        }
        
        // 排序回复（按时间先后）
        for i in 0..<topLevelResults.count {
            topLevelResults[i].replies.sort { $0.datePosted < $1.datePosted }
        }
        
        // 更新顶级评论列表（按时间倒序）
        self.topLevelComments = topLevelResults.sorted { $0.datePosted > $1.datePosted }
        
        // 创建包含所有评论和回复的扁平列表
        self.allComments = getAllCommentsFlattened()
    }
    
    /**
     * 查找评论的根评论（顶级评论）
     * 用于将多层嵌套的回复组织到正确的顶级评论下
     */
    private func findRootComment(for comment: UserCommentModel, in allComments: [UserCommentModel]) -> UserCommentModel? {
        // 如果没有父评论ID，则自身就是根评论
        if comment.parentCommentId == nil {
            return comment
        }
        
        // 查找父评论
        if let parentComment = allComments.first(where: { $0.id == comment.parentCommentId }) {
            // 递归查找根评论
            return findRootComment(for: parentComment, in: allComments)
        }
        
        return nil
    }
    
    /**
     * 获取所有评论和回复的扁平列表
     */
    private func getAllCommentsFlattened() -> [UserCommentModel] {
        var result: [UserCommentModel] = []
        
        // 添加所有顶级评论
        for comment in topLevelComments {
            result.append(comment)
            // 递归添加所有回复
            result.append(contentsOf: flattenReplies(comment.replies))
        }
        
        return result
    }
    
    /**
     * 递归扁平化回复列表
     */
    private func flattenReplies(_ replies: [UserCommentModel]) -> [UserCommentModel] {
        var result: [UserCommentModel] = []
        
        for reply in replies {
            result.append(reply)
            result.append(contentsOf: flattenReplies(reply.replies))
        }
        
        return result
    }
    
    /**
     * 提交评论
     * 处理新评论或回复的添加
     */
    func submitComment() {
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // 处理评论内容
        let processedContent = commentText
        
        if let replyTo = replyingToComment {
            // 添加回复 - 如果有回复对象，直接使用replyToUsername参数，不需要在内容中添加@
            currentPost.addComment(
                username: currentUsername,
                userAvatar: currentUserAvatar,
                content: processedContent, // 不需要显式添加@前缀
                parentCommentId: replyTo.id,
                replyToUsername: replyTo.username // 使用回复对象的用户名
            )
        } else {
            // 添加顶级评论 - 无需特殊处理
            currentPost.addComment(
                username: currentUsername,
                userAvatar: currentUserAvatar,
                content: processedContent
            )
        }
        
        // 重置状态
        commentText = ""
        replyingToComment = nil
        
        // 更新评论列表
        updateCommentLists()
        
        // 生成虚拟角色回复
        Task {
            await generateVirtualReply()
        }
    }
    
    /**
     * 设置回复目标
     * @param comment 要回复的评论
     */
    func replyTo(comment: UserCommentModel) {
        self.replyingToComment = comment
        self.commentText = ""
    }
    
    /**
     * 取消回复
     * 清除当前回复目标
     */
    func cancelReply() {
        self.replyingToComment = nil
    }
    
    /**
     * 生成虚拟角色回复
     * 随机选择一个虚拟角色对最新评论做出回复
     */
    @MainActor
    func generateVirtualReply() async {
        // 获取最新评论
        guard let latestComment = allComments.max(by: { $0.datePosted < $1.datePosted }) else {
            return
        }
        
        // 随机决定是否生成回复 (30%概率)
        guard Double.random(in: 0...1) < 0.3 else {
            return
        }
        
        // 随机选择一个虚拟角色
        let characters = ["einstein", "shakespeare", "davinci", "confucius", "curie", "libai"]
        guard let character = characters.randomElement() else {
            return
        }
        
        // 角色名称映射
        let characterNames: [String: String] = [
            "einstein": "爱因斯坦",
            "shakespeare": "莎士比亚",
            "davinci": "达芬奇",
            "confucius": "孔子",
            "curie": "居里夫人",
            "libai": "李白"
        ]
        
        // 为选定角色生成随机回复内容
        let virtualReply = generateReplyForCharacter(character: character, replyTo: latestComment.content)
        
        // 添加虚拟角色回复
        // 如果回复的是顶级评论，则将虚拟角色回复作为该评论的回复
        // 如果回复的是回复，则将虚拟角色回复作为回复的上级评论的回复
        let parentId = latestComment.parentCommentId ?? latestComment.id
        
        // 延迟1-3秒，模拟打字时间
        try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 1...3) * 1_000_000_000))
        
        // 添加虚拟角色回复
        currentPost.addComment(
            username: characterNames[character] ?? character,
            userAvatar: "avatar_\(character)",
            content: virtualReply,
            parentCommentId: parentId,
            replyToUsername: latestComment.username,
            isVirtualCharacter: true,
            characterID: character
        )
        
        // 更新评论列表
        updateCommentLists()
    }
    
    /**
     * 根据角色生成回复内容
     * @param character 虚拟角色ID
     * @param replyTo 被回复的内容
     * @return 生成的回复内容
     */
    private func generateReplyForCharacter(character: String, replyTo: String) -> String {
        // 根据不同角色特点生成回复
        switch character {
        case "einstein":
            return getRandomEinsteinReply()
        case "shakespeare":
            return getRandomShakespeareReply()
        case "davinci":
            return getRandomDaVinciReply()
        case "confucius":
            return getRandomConfuciusReply()
        case "curie":
            return getRandomCurieReply()
        case "libai":
            return getRandomLibaiReply()
        default:
            return "很有趣的想法！"
        }
    }
    
    // 各角色随机回复内容生成函数
    private func getRandomEinsteinReply() -> String {
        let replies = [
            "科学探索需要好奇心和想象力，你的思考很有启发性。",
            "相对而言，这个观点很有意思，我想进一步探讨。",
            "宇宙之谜永无止境，就像我们的思考一样无限延展。",
            "简单是复杂的最高形式，你的见解很简洁明了。",
            "想象力比知识更重要，你展现了很好的想象力。"
        ]
        return replies.randomElement() ?? replies[0]
    }
    
    private func getRandomShakespeareReply() -> String {
        let replies = [
            "文字如戏剧般展开，你的表达很有魅力！",
            "若要比喻，你的见解如盛夏夜晚的星光般闪耀。",
            "真是妙语连珠，让我想起了我的某个剧本片段。",
            "存在还是不存在，这是个问题。而你的回答很精彩。",
            "言辞如诗，意境如画，甚是精妙。"
        ]
        return replies.randomElement() ?? replies[0]
    }
    
    private func getRandomDaVinciReply() -> String {
        let replies = [
            "艺术与科学的交融，在你的观点中我看到了无限可能。",
            "细节决定成败，你的见解很有深度。",
            "学习永无止境，你的分享让我受益匪浅。",
            "简单中蕴含着最深的智慧，你的表达很有力量。",
            "自然是最伟大的导师，你的灵感来源很棒。"
        ]
        return replies.randomElement() ?? replies[0]
    }
    
    private func getRandomConfuciusReply() -> String {
        let replies = [
            "君子和而不同，你的见解很有价值。",
            "学而不思则罔，思而不学则殆。你的思考很深入。",
            "三人行，必有我师焉。你的观点很值得学习。",
            "知之为知之，不知为不知，是知也。你的坦诚很可贵。",
            "温故而知新，可以为师矣。你的见解融会贯通。"
        ]
        return replies.randomElement() ?? replies[0]
    }
    
    private func getRandomCurieReply() -> String {
        let replies = [
            "科学研究需要坚持不懈的精神，你的坚持很令人敬佩。",
            "我们不应该害怕困难，你的勇气值得赞赏。",
            "生活中没有可怕的东西，只有需要理解的事物。你的理解很深刻。",
            "在科学和生活中，好奇心都是不可或缺的，你的好奇心很可贵。",
            "成功的道路需要时间和耐心，你走在正确的方向上。"
        ]
        return replies.randomElement() ?? replies[0]
    }
    
    private func getRandomLibaiReply() -> String {
        let replies = [
            "举杯邀明月，对影成三人。你的心境如明月般清澈。",
            "人生如梦，一尊还酹江月。你的感悟很有深度。",
            "长风破浪会有时，直挂云帆济沧海。你的志向令人钦佩。",
            "飞流直下三千尺，疑是银河落九天。你的描述如诗如画。",
            "相逢何必曾相识，一笑便是故人心。你的真诚让人感动。"
        ]
        return replies.randomElement() ?? replies[0]
    }
}

/**
 * 预览
 */
struct CommentManager_Previews: PreviewProvider {
    static var previews: some View {
        // 创建一个临时视图来包装CommentManager
        VStack {
            Text("评论管理器预览")
                .font(.headline)
                .padding()
            
            Spacer()
            
            Text("CommentManager不是一个View，但已初始化为：")
                .font(.footnote)
                .foregroundColor(.gray)
            
            Text("CommentManager(post: ModelData.samplePosts[0])")
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
        .frame(height: 200)
        .onAppear {
            // 初始化CommentManager但不显示
            let _ = CommentManager(post: ModelData.samplePosts[0])
        }
    }
}
