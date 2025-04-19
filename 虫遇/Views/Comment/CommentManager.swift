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
            if comment.parentCommentId != nil {
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
        
        // 检查评论中是否包含@特定角色
        let mentionedCharacter = checkForMentionedCharacter(in: latestComment.content)
        
        // 默认回复概率
        var replyProbability: Double = 0.3
        var selectedCharacter: String? = nil
        
        if let mentioned = mentionedCharacter {
            // 如果@了特定角色，该角色100%会回复
            replyProbability = 1.0
            selectedCharacter = mentioned
        } else {
            // 如果没有@特定角色，增加回复概率至50%
            replyProbability = 0.5
            // 随机选择一个虚拟角色
            let characters = ["einstein", "shakespeare", "davinci", "confucius", "curie", "libai"]
            selectedCharacter = characters.randomElement()
        }
        
        // 决定是否生成回复
        guard Double.random(in: 0...1) < replyProbability, let character = selectedCharacter else {
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
        
        // 为选定角色生成回复内容
        let virtualReply = generateReplyForCharacter(character: character, replyTo: latestComment.content)
        
        // 延迟1-3秒，模拟打字时间
        try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 1...3) * 1_000_000_000))
        
        // 添加虚拟角色回复
        currentPost.addComment(
            username: characterNames[character] ?? character,
            userAvatar: "avatar_\(character)",
            content: virtualReply,
            parentCommentId: latestComment.id,
            replyToUsername: latestComment.username
        )
        
        // 更新评论列表
        updateCommentLists()
    }
    
    /**
     * 检查评论中是否@了特定的虚拟角色
     * @param content 评论内容
     * @return 被@的角色ID，如果没有则返回nil
     */
    private func checkForMentionedCharacter(in content: String) -> String? {
        // 角色名称及其ID映射
        let characterMapping: [String: String] = [
            "爱因斯坦": "einstein",
            "莎士比亚": "shakespeare",
            "达芬奇": "davinci",
            "孔子": "confucius",
            "居里夫人": "curie",
            "李白": "libai"
        ]
        
        // 检查评论中是否包含@角色名
        for (characterName, characterId) in characterMapping {
            if content.contains("@\(characterName)") {
                return characterId
            }
        }
        
        return nil
    }
    
    /**
     * 根据角色生成回复内容
     * @param character 虚拟角色ID
     * @param replyTo 被回复的内容
     * @return 生成的回复内容
     */
    private func generateReplyForCharacter(character: String, replyTo: String) -> String {
        // 检查是否@了该角色，如果是，生成更个性化的回复
        let isMentioned = replyTo.contains("@\(getCharacterName(for: character))")
        
        // 根据不同角色特点生成回复
        switch character {
        case "einstein":
            return isMentioned ? 
                getPersonalizedEinsteinReply(content: replyTo) :
                getRandomEinsteinReply()
        case "shakespeare":
            return isMentioned ? 
                getPersonalizedShakespeareReply(content: replyTo) :
                getRandomShakespeareReply()
        case "davinci":
            return isMentioned ? 
                getPersonalizedDaVinciReply(content: replyTo) :
                getRandomDaVinciReply()
        case "confucius":
            return isMentioned ? 
                getPersonalizedConfuciusReply(content: replyTo) :
                getRandomConfuciusReply()
        case "curie":
            return isMentioned ? 
                getPersonalizedCurieReply(content: replyTo) :
                getRandomCurieReply()
        case "libai":
            return isMentioned ? 
                getPersonalizedLibaiReply(content: replyTo) :
                getRandomLibaiReply()
        default:
            return "很有趣的想法！"
        }
    }
    
    // 获取角色名称
    private func getCharacterName(for characterId: String) -> String {
        let characterNames: [String: String] = [
            "einstein": "爱因斯坦",
            "shakespeare": "莎士比亚",
            "davinci": "达芬奇",
            "confucius": "孔子",
            "curie": "居里夫人",
            "libai": "李白"
        ]
        
        return characterNames[characterId] ?? characterId
    }
    
    // 针对被@的个性化回复 - 爱因斯坦
    private func getPersonalizedEinsteinReply(content: String) -> String {
        let replies = [
            "感谢你提到我！作为科学家，我认为好奇心是人类最宝贵的品质。你的问题很有深度。",
            "你的消息提醒了我，相对论告诉我们，时间是相对的，但与有思想的人交流的价值是绝对的。",
            "听到你提到我很高兴！想象力比知识更重要，你的思考方式很有创造性。",
            "哦！被你@提到了！科学探索需要勇气质疑权威，包括我的理论。你的观点很有启发性。",
            "正如我常说，只有两件事是无限的：宇宙和人类的想象力。你的提问展示了后者的魅力。"
        ]
        return replies.randomElement() ?? replies[0]
    }
    
    // 针对被@的个性化回复 - 莎士比亚
    private func getPersonalizedShakespeareReply(content: String) -> String {
        let replies = [
            "多谢垂询，亲爱的朋友！正如我在《哈姆雷特》中写道，'存在还是不存在，这是个问题'，而你的思考则是答案的开始。",
            "啊！如沐春风般的@提及！文字乃心灵之窗，你的表达如舞台上最精彩的独白。",
            "谢谢提到我！'我们凭借星光而非命运指引我们的未来'，你的思考正如明亮的北极星。",
            "感谢你的呼唤！如《仲夏夜之梦》所言，'虽然她娇小，却fieree无比'，你的问题虽简短却蕴含深意。",
            "多谢你的提问！生活舞台需要每个人的精彩演出，而你，正是当代的主角！"
        ]
        return replies.randomElement() ?? replies[0]
    }
    
    // 针对被@的个性化回复 - 达芬奇
    private func getPersonalizedDaVinciReply(content: String) -> String {
        let replies = [
            "感谢你的@提及！正如我常说，学习永无止境，你的问题激发了我新的思考。",
            "多谢提到我！艺术与科学从不分离，就像你的思考融合了理性与创造力。",
            "谢谢你提到我！细节决定成败，你的观察角度非常独特，让我想起了《蒙娜丽莎》创作时的灵感。",
            "很高兴收到你的消息！好奇心是人类进步的根源，你的问题展示了这种可贵的品质。",
            "感谢@我！简单中往往蕴含最深的智慧，你的表达方式让我想起了《最后的晚餐》中的构图原理。"
        ]
        return replies.randomElement() ?? replies[0]
    }
    
    // 针对被@的个性化回复 - 孔子
    private func getPersonalizedConfuciusReply(content: String) -> String {
        let replies = [
            "得闻君问，甚感欣慰。正所谓'学而不思则罔，思而不学则殆'，君之问题颇有思考之深度。",
            "感谢提及老夫！'己所不欲，勿施于人'，你的问题体现了对他人的尊重与关怀。",
            "多谢垂询！'三人行，必有我师焉'，从你的提问中，我也有所启发。",
            "谢谢你的@提及！'工欲善其事，必先利其器'，你善于提问的能力将引领你获取更多智慧。",
            "闻君之言，甚是欣慰。'君子和而不同'，你的独立思考正是修身齐家治国平天下之本。"
        ]
        return replies.randomElement() ?? replies[0]
    }
    
    // 针对被@的个性化回复 - 居里夫人
    private func getPersonalizedCurieReply(content: String) -> String {
        let replies = [
            "感谢你提到我！在科学道路上，我们不应害怕任何困难，你的问题展示了勇于探索的精神。",
            "谢谢你的@提及！'我们必须坚信，自己有才能。在一生中必须挥洒自己的才华'，你的思考很有价值。",
            "收到你的消息很高兴！正如我所信仰的，科学与生活中，好奇心都是不可或缺的，你的问题反映了这一点。",
            "多谢提到我！科学研究需要坚持和毅力，就像你一直追求答案的决心一样值得敬佩。",
            "感谢你的提问！'我们要不断地探索和不断地寻找'，你的问题正是科学精神的体现。"
        ]
        return replies.randomElement() ?? replies[0]
    }
    
    // 针对被@的个性化回复 - 李白
    private func getPersonalizedLibaiReply(content: String) -> String {
        let replies = [
            "谢过君提及！'人生得意须尽欢，莫使金樽空对月'，你的问题如明月般照亮了心境。",
            "多谢垂询！'长风破浪会有时，直挂云帆济沧海'，你的思考展现了远大的志向。",
            "感谢君之@！'抽刀断水水更流，举杯销愁愁更愁'，你的问题引发了我的诗兴。",
            "闻君相召，甚是欢喜！'床前明月光，疑是地上霜'，你的表达如明月般清澈明亮。",
            "谢谢你提到我！'千里江陵一日还，两岸猿声啼不住'，你的思考如奔流江水，生生不息。"
        ]
        return replies.randomElement() ?? replies[0]
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
