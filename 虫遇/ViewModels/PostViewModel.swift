import Foundation
import Combine
import SwiftUI

/**
 * 帖子视图模型
 * 处理帖子数据和用户交互
 */
class PostViewModel: ObservableObject {
    // 单例实例 - 在应用内共享帖子数据
    static let shared = PostViewModel()
    
    // 帖子数据
    @Published var posts: [UserPostModel] = []
    
    // 用户交互状态
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // 服务依赖
    private let virtualCharacterService = VirtualCharacterService.shared
    
    // 取消令牌
    private var cancellables = Set<AnyCancellable>()
    
    /**
     * 初始化视图模型
     * 加载示例帖子数据
     */
    init() {
        loadSamplePosts()
    }
    
    /**
     * 加载示例帖子
     */
    private func loadSamplePosts() {
        self.posts = ModelData.samplePosts
    }
    
    /**
     * 点赞帖子
     * @param post 帖子对象
     */
    func likePost(_ post: UserPostModel) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            // 切换点赞状态
            let isLiked = !posts[index].isLikedByCurrentUser
            // 更新点赞状态和点赞数
            var updatedPost = posts[index].toggleLike(isLiked: isLiked)
            
            // 更新点赞数（点赞+1，取消点赞-1）
            if isLiked {
                updatedPost = updatedPost.updateLikes(delta: 1)
            } else {
                updatedPost = updatedPost.updateLikes(delta: -1)
            }
            
            posts[index] = updatedPost
            
            // 模拟网络请求更新点赞状态
            // 在实际应用中，应该调用API更新服务器数据
        }
    }
    
    /**
     * 收藏帖子
     * @param post 帖子对象
     */
    func bookmarkPost(_ post: UserPostModel) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            // 切换收藏状态
            let isBookmarked = !posts[index].isBookmarkedByCurrentUser
            posts[index] = posts[index].toggleBookmark(isBookmarked: isBookmarked)
            
            // 模拟网络请求更新收藏状态
            // 在实际应用中，应该调用API更新服务器数据
        }
    }
    
    /**
     * 添加用户评论
     * @param post 帖子对象
     * @param content 评论内容
     * @param replyToCommentID 回复的评论ID（可选）
     */
    func addUserComment(to post: UserPostModel, content: String, replyToCommentID: UUID? = nil) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // 格式化评论内容，确保文本格式正确
        let formattedContent = UserPostModel.formatContent(content)
        
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            // 如果有父评论ID（回复），使用带parentCommentId参数的方法
            if let parentId = replyToCommentID {
                posts[index].addComment(
                    username: "当前用户",
                    userAvatar: "current_user_avatar",
                    content: formattedContent,
                    parentCommentId: parentId
                )
            } else {
                // 直接添加评论
                posts[index].addComment(
                    username: "当前用户",
                    userAvatar: "current_user_avatar",
                    content: formattedContent
                )
            }
            
            // 检查帖子是否有关联的历史人物（例如，通过帖子内容或评论对象）
            // 注意：由于UserPostModel没有characterID属性，我们需要通过其他方式确定
            // 可能的解决方案：检查帖子内容是否包含有关历史人物的关键词
            
            // 示例：假设我们可以通过帖子内容中是否包含人物名字来确定关联的历史人物
            let historicalFigures = [
                "爱因斯坦": "einstein",
                "莎士比亚": "shakespeare",
                "达芬奇": "davinci",
                "孔子": "confucius"
            ]
            
            // 查找帖子内容中是否包含历史人物名称
            for (figureName, figureID) in historicalFigures {
                if post.content.contains(figureName) {
                    // 找到相关的历史人物，触发虚拟角色回复
                    self.generateVirtualCharacterReply(
                        characterID: figureID,
                        to: formattedContent,
                        in: post.content,
                        postIndex: index
                    )
                    break // 只让一个角色回复
                }
            }
        }
    }
    
    /**
     * 点赞评论
     * @param post 帖子对象
     * @param comment 评论对象
     */
    func likeComment(in post: UserPostModel, comment: UserCommentModel) {
        if let postIndex = posts.firstIndex(where: { $0.id == post.id }),
           let commentIndex = posts[postIndex].comments.firstIndex(where: { $0.id == comment.id }) {
            // 更新评论点赞数
            // 在实际应用中，应该实现切换点赞状态的逻辑
            let updatedComment = posts[postIndex].comments[commentIndex].updatedLikes()
            
            // 创建新的评论数组
            var newComments = posts[postIndex].comments
            newComments[commentIndex] = updatedComment
            
            // 创建新的帖子对象并替换原帖子
            let updatedPost = UserPostModel(
                id: posts[postIndex].id,
                username: posts[postIndex].username,
                userAvatar: posts[postIndex].userAvatar,
                content: posts[postIndex].content,
                images: posts[postIndex].images,
                datePosted: posts[postIndex].datePosted,
                likes: posts[postIndex].likes,
                comments: newComments,
                isLikedByCurrentUser: posts[postIndex].isLikedByCurrentUser,
                isBookmarkedByCurrentUser: posts[postIndex].isBookmarkedByCurrentUser
            )
            
            // 更新帖子数组
            posts[postIndex] = updatedPost
        }
    }
    
    /**
     * 生成虚拟角色回复
     * @param characterID 角色ID
     * @param userComment 用户评论
     * @param postContent 帖子内容
     * @param postIndex 帖子索引
     */
    private func generateVirtualCharacterReply(characterID: String, to userComment: String, in postContent: String, postIndex: Int) {
        // 设置加载状态
        self.isLoading = true
        
        // 调用虚拟角色服务生成回复
        virtualCharacterService.getCharacterReply(
            characterID: characterID,
            to: userComment,
            in: postContent
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            self?.isLoading = false
            
            if case .failure(let error) = completion {
                self?.errorMessage = "生成回复失败: \(error.localizedDescription)"
            }
        } receiveValue: { [weak self] replyContent in
            guard let self = self else { return }
            
            // 创建虚拟角色评论
            let _ = UserCommentModel(
                username: self.getCharacterName(for: characterID),
                userAvatar: "avatar_\(characterID)",
                content: replyContent,
                datePosted: Date(),
                likes: 0,
                isVirtualCharacter: true,
                characterID: characterID
            )
            
            // 添加评论到帖子
            self.posts[postIndex].addComment(
                username: self.getCharacterName(for: characterID),
                userAvatar: "avatar_\(characterID)",
                content: replyContent,
                isVirtualCharacter: true,
                characterID: characterID
            )
        }
        .store(in: &cancellables)
    }
    
    /**
     * 生成虚拟角色评论
     * @param post 帖子
     * @param character 角色
     */
    func generateVirtualCharacterComment(for post: UserPostModel, from character: PHCharacterModel) {
        // 使用现有方法并基于角色ID调用
        let characterID = character.name.lowercased() // 使用角色名作为ID
        
        // 生成一个模拟评论（实际应用中应该通过AI服务生成）
        var commentContent = "这是来自\(character.name)的评论，在真实应用中会通过AI服务生成符合角色特点的内容。"
        
        // 格式化评论内容，确保文本格式正确
        commentContent = UserPostModel.formatContent(commentContent)
        
        // 创建虚拟角色评论
        let _ = UserCommentModel(
            username: character.name,
            userAvatar: "avatar_default",
            content: commentContent,
            datePosted: Date(),
            likes: Int.random(in: 20...100),
            isVirtualCharacter: true,
            characterID: characterID
        )
        
        // 更新视图模型中的帖子（这里只是模拟，实际应用中需要更新后端数据）
        if let postIndex = posts.firstIndex(where: { $0.id == post.id }) {
            posts[postIndex].addComment(
                username: character.name,
                userAvatar: "avatar_default",
                content: commentContent,
                isVirtualCharacter: true,
                characterID: characterID
            )
        }
    }
    
    /**
     * 获取角色名称
     * @param characterID 角色ID
     * @return 角色名称
     */
    private func getCharacterName(for characterID: String) -> String {
        switch characterID {
        case "einstein":
            return "爱因斯坦"
        case "shakespeare":
            return "莎士比亚"
        case "davinci":
            return "达芬奇"
        case "goku":
            return "孙悟空"
        case "holmes":
            return "福尔摩斯"
        case "naruto":
            return "漩涡鸣人"
        default:
            return "虚拟角色"
        }
    }
    
    /**
     * 根据用户评论自动触发虚拟角色的回复
     * @param postIndex 帖子索引
     * @param content 用户评论内容
     */
    func autoGenerateVirtualReplies(postIndex: Int, to content: String) {
        // 在实际应用中，这里可以实现更复杂的逻辑：
        // 1. 分析用户评论内容，确定应该由哪个角色回复
        // 2. 使用NLP技术确定评论的主题和情感
        // 3. 根据评论与角色专业领域的相关度选择响应的角色
        
        // 此处简单实现：随机选择1-2个角色回复
        let characters = ["einstein", "shakespeare", "davinci", "goku", "holmes", "naruto"]
        let randomCharacters = Array(characters.shuffled().prefix(Int.random(in: 1...2)))
        
        for characterID in randomCharacters {
            // 避免重复回复（这里我们不再使用characterID属性，因为UserPostModel没有此属性）
            // 延迟1-3秒后回复，模拟真实场景
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1...3)) {
                self.generateVirtualCharacterReply(
                    characterID: characterID,
                    to: content,
                    in: self.posts[postIndex].content,
                    postIndex: postIndex
                )
            }
        }
    }
    
    /**
     * 获取历史人物列表
     * @return 历史人物列表
     */
    func getHistoricalCharacters() -> [PHCharacterModel] {
        return PHCharacterModel.samples
    }
    
    /**
     * 添加评论
     * @param post 帖子
     * @param content 评论内容
     * @param replyTo 回复的评论（可选）
     */
    func addComment(to post: UserPostModel, content: String, replyTo: UserCommentModel? = nil) {
        // 格式化评论内容，确保文本格式正确
        let formattedContent = UserPostModel.formatContent(content)
        
        // 获取帖子索引
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        // 如果有回复的对象
        if let replyTo = replyTo {
            posts[index].addComment(
                username: "当前用户",
                userAvatar: "current_user_avatar",
                content: formattedContent,
                parentCommentId: replyTo.id,
                replyToUsername: replyTo.username
            )
        } else {
            // 直接添加评论
            posts[index].addComment(
                username: "当前用户",
                userAvatar: "current_user_avatar",
                content: formattedContent
            )
        }
    }
    
    /**
     * 点赞评论
     * @param post 帖子
     * @param comment 评论
     */
    func likeComment(post: UserPostModel, comment: UserCommentModel) {
        likeComment(in: post, comment: comment)
    }
    
    /**
     * 切换点赞状态
     * @param post 要点赞的帖子
     */
    func toggleLike(post: UserPostModel) {
        // 找到帖子在数组中的索引
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            // 使用已实现的toggleLike方法创建更新后的帖子
            var updatedPost = posts[index].toggleLike(isLiked: !posts[index].isLikedByCurrentUser)
            
            // 更新点赞数
            if updatedPost.isLikedByCurrentUser {
                updatedPost = updatedPost.updateLikes(delta: 1)
            } else {
                updatedPost = updatedPost.updateLikes(delta: -1)
            }
            
            // 更新数组中的帖子
            posts[index] = updatedPost
            
            // 这里可以添加网络请求，将点赞状态保存到服务器
            // apiService.updateLikeStatus(postId: post.id, isLiked: post.isLikedByCurrentUser)
        }
    }
    
    /**
     * 根据创作类型生成帖子
     * @param typeIndex 创作类型索引
     * @return 生成的帖子数组
     */
    func generatePostsByCreationType(typeIndex: Int) -> [UserPostModel] {
        let types = CreationTypeManager.shared.types
        let typeName = types[typeIndex]
        var generatedPosts: [UserPostModel] = []
        
        // 根据不同创作类型生成不同内容
        switch typeIndex {
        case 0: // 随机漫游
            // 随机漫游类型的帖子内容
            let randomContents = [
                "在虫洞中随机漫游时，我偶遇了一个奇妙的平行宇宙，那里的科技与我们完全不同。他们通过思维就能控制机器，没有任何物理界面。",
                "今天的随机漫游让我见到了一个和地球几乎相同的世界，但所有的颜色都是互补色！蓝天是橙色的，绿草是紫红色的，太奇妙了。",
                "随机漫游时遇到了一个由数学公式构成的维度，那里的一切都遵循严格的数学规律，连情感都可以用方程式表达。",
                "在虫洞随机跳跃中，我发现了一个只有声音没有影像的世界。所有的交流、表达和艺术都是通过声波完成的。",
                "随机漫游带我到了一个时间倒流的宇宙，那里的人从死亡开始生活，走向出生。他们知道自己的未来，却无法知晓过去。"
            ]
            
            // 生成5个随机漫游类型的帖子
            for i in 0..<5 {
                let content = randomContents[i % randomContents.count]
                let characterIndex = Int.random(in: 0...5)
                let characterNames = ["爱因斯坦", "莎士比亚", "达芬奇", "孔子", "牛顿", "李白"]
                let characterIDs = ["einstein", "shakespeare", "davinci", "confucius", "newton", "libai"]
                
                // 创建一条随机生成的评论
                let randomComment = UserCommentModel(
                    username: characterNames[characterIndex],
                    userAvatar: "person.fill", // 使用系统SF Symbol
                    content: "这个维度很有趣，让我想到了\(characterNames[characterIndex])的理论。",
                    datePosted: Date().addingTimeInterval(-Double.random(in: 0...36000)),
                    likes: Int.random(in: 5...50),
                    isVirtualCharacter: true,
                    characterID: characterIDs[characterIndex]
                )
                
                // 创建帖子 - 不使用图片
                let post = UserPostModel(
                    username: "虫遇探索者",
                    userAvatar: "person.circle.fill", // 使用系统SF Symbol
                    content: content,
                    images: [], // 不使用图片
                    datePosted: Date(),
                    likes: Int.random(in: 0...20),
                    comments: [randomComment],
                    isLikedByCurrentUser: false,
                    isBookmarkedByCurrentUser: false
                )
                
                generatedPosts.append(post)
            }
            
        case 1: // 日常心情
            // 日常心情类型的帖子内容
            let moodContents = [
                "今天在公园散步时，一片落叶轻轻飘落在我肩上，仿佛是自然给我的一个温柔问候。这小小的瞬间让我整天心情舒畅。",
                "工作压力大的时候，我喜欢泡一杯茶，静静地看窗外的云卷云舒。这样的片刻宁静总能让我重新找回平衡。",
                "雨后的空气特别清新，街上的灯光倒映在湿漉漉的地面上，像是另一个世界。这样的夜晚总让我感到莫名的感动。",
                "今天遇到了一位老奶奶，她对我微笑的样子让我想起了外婆。有时候幸福就藏在这些小小的相遇里。",
                "清晨第一缕阳光透过窗帘洒在书桌上的那一刻，感觉一天的可能性都在眼前展开。这种新的开始总是充满希望。"
            ]
            
            // 生成5个日常心情类型的帖子
            for i in 0..<5 {
                let content = moodContents[i % moodContents.count]
                
                // 创建帖子 - 不使用图片
                let post = UserPostModel(
                    username: "心情记录者",
                    userAvatar: "heart.fill", // 使用系统SF Symbol
                    content: content,
                    images: [], // 不使用图片
                    datePosted: Date().addingTimeInterval(-Double.random(in: 0...7200)),
                    likes: Int.random(in: 10...60),
                    comments: [],
                    isLikedByCurrentUser: false,
                    isBookmarkedByCurrentUser: false
                )
                
                generatedPosts.append(post)
            }
            
        case 2: // 古今对望
            // 古今对望类型的帖子内容
            let historicalContents = [
                "假如爱因斯坦活在互联网时代，他会如何看待信息爆炸？他曾说过想象力比知识更重要，在这个知识触手可得的时代，或许创新思维更加珍贵。",
                "莎士比亚如果使用现代社交媒体，会创造出怎样的内容？他的戏剧性叙事和对人性的洞察，可能会让他成为最火的内容创作者。",
                "达芬奇生活在当今社会，会对AI绘画有什么看法？作为一位横跨艺术与科学的天才，他可能会将技术视为扩展创造力的工具，而非替代品。",
                "孔子面对现代教育体系，会提出怎样的改革？他强调的因材施教和终身学习理念，在今天看来依然具有重要意义。",
                "李白如果乘坐宇宙飞船遨游太空，会写出怎样的诗句？他的浪漫主义和对自由的向往，或许会在星际旅行中找到更广阔的表达空间。"
            ]
            
            // 对应的历史人物
            let historicalFigures = ["爱因斯坦", "莎士比亚", "达芬奇", "孔子", "李白"]
            let characterIDs = ["einstein", "shakespeare", "davinci", "confucius", "libai"]
            let avatarSymbols = ["atom", "book.fill", "paintpalette.fill", "scroll.fill", "text.book.closed.fill"]
            
            // 生成5个古今对望类型的帖子
            for i in 0..<5 {
                let content = historicalContents[i % historicalContents.count]
                let figureIndex = i % historicalFigures.count
                
                // 创建历史人物评论 - 使用系统图标
                let historicalComment = UserCommentModel(
                    username: historicalFigures[figureIndex],
                    userAvatar: avatarSymbols[figureIndex], // 使用系统SF Symbol
                    content: "看到现代人对我的解读很有趣。技术虽然变了，但人性的本质还是相通的。",
                    datePosted: Date().addingTimeInterval(-Double.random(in: 0...3600)),
                    likes: Int.random(in: 30...100),
                    isVirtualCharacter: true,
                    characterID: characterIDs[figureIndex]
                )
                
                // 创建帖子 - 不使用图片
                let post = UserPostModel(
                    username: "时空对话者",
                    userAvatar: "hourglass", // 使用系统SF Symbol
                    content: content,
                    images: [], // 不使用图片
                    datePosted: Date().addingTimeInterval(-Double.random(in: 0...14400)),
                    likes: Int.random(in: 50...150),
                    comments: [historicalComment],
                    isLikedByCurrentUser: false,
                    isBookmarkedByCurrentUser: false
                )
                
                generatedPosts.append(post)
            }
            
        case 3: // 奇思妙想
            // 奇思妙想类型的帖子内容
            let creativeContents = [
                "如果我们能够通过梦境连接到集体潜意识，会不会创造出一种全新的社交网络？在梦中与世界各地的人交流，共享创意和灵感。",
                "想象未来的城市是立体的，不仅向上生长，还向下延伸。地下城市与地上城市形成互补，利用地热能源，创造全新的生活空间。",
                "如果植物能够像使用互联网一样通过菌根网络共享信息和资源，那么森林是否就是地球上最古老的社交网络？",
                "海洋占地球表面积的71%，但我们对它的了解少于月球表面。如果我们建立水下城市，会不会发现全新的生活方式和资源利用模式？",
                "时间可能不是线性的，而是像树一样分叉。每个决定创造一个新的时间线，这意味着可能存在无数个版本的你，过着不同的生活。"
            ]
            
            // 生成5个奇思妙想类型的帖子
            for i in 0..<5 {
                let content = creativeContents[i % creativeContents.count]
                
                // 随机评论
                let randomName = ["思想实验家", "未来学者", "创意探索者", "概念设计师", "哲学思考者"][i % 5]
                let randomComment = UserCommentModel(
                    username: randomName,
                    userAvatar: "lightbulb.fill", // 使用系统SF Symbol
                    content: "这个想法很有深度！让我想到了另一个角度：如果...",
                    datePosted: Date().addingTimeInterval(-Double.random(in: 0...7200)),
                    likes: Int.random(in: 15...45),
                    isVirtualCharacter: false,
                    characterID: nil
                )
                
                // 创建帖子 - 不使用图片
                let post = UserPostModel(
                    username: "创想家",
                    userAvatar: "brain.fill", // 使用系统SF Symbol
                    content: content,
                    images: [], // 不使用图片
                    datePosted: Date().addingTimeInterval(-Double.random(in: 0...21600)),
                    likes: Int.random(in: 30...120),
                    comments: [randomComment],
                    isLikedByCurrentUser: false,
                    isBookmarkedByCurrentUser: false
                )
                
                generatedPosts.append(post)
            }
            
        case 4: // 时空记事
            // 时空记事类型的帖子内容
            let timeContents = [
                "2023年11月，全球第一个量子互联网节点成功连接，这可能是继互联网之后最重要的通信革命，为未来的信息安全奠定基础。",
                "回顾1969年人类首次登月，阿姆斯特朗的一小步是如何改变了人类对宇宙探索的理解和想象？这一壮举开启了太空时代。",
                "公元前500年，古希腊哲学的黄金时代，苏格拉底、柏拉图和亚里士多德如何塑造了西方思想的基础？他们的智慧跨越时空仍然影响着我们。",
                "1440年古腾堡印刷机的发明，是如何彻底改变知识传播方式的？这一技术创新使知识不再局限于精英阶层，为文艺复兴和启蒙运动铺平了道路。",
                "2045年，技术奇点可能到来，人工智能将超越人类智能。这一假设性事件会如何重新定义人类的角色和价值？我们需要开始思考这些问题。"
            ]
            
            // 时间点
            let timePeriods = ["2023年", "1969年", "公元前500年", "1440年", "2045年"]
            
            // 生成5个时空记事类型的帖子
            for i in 0..<5 {
                let content = timeContents[i % timeContents.count]
                let timePeriod = timePeriods[i % timePeriods.count]
                
                // 创建帖子 - 不使用图片，添加时间标记到内容
                let post = UserPostModel(
                    username: "时间记录者",
                    userAvatar: "clock.fill", // 使用系统SF Symbol
                    content: "[\(timePeriod)] " + content,
                    images: [], // 不使用图片
                    datePosted: Date().addingTimeInterval(-Double.random(in: 0...28800)),
                    likes: Int.random(in: 40...180),
                    comments: [],
                    isLikedByCurrentUser: false,
                    isBookmarkedByCurrentUser: false
                )
                
                generatedPosts.append(post)
            }
            
        default:
            // 默认情况下返回空数组
            return []
        }
        
        print("已根据创作类型「\(typeName)」生成 \(generatedPosts.count) 个帖子")
        return generatedPosts
    }
    
    /// 添加一组帖子到列表前端
    /// - Parameter newPosts: 要添加的帖子数组
    func addPosts(_ newPosts: [UserPostModel]) {
        // 将新帖子添加到列表前面
        posts.insert(contentsOf: newPosts, at: 0)
        
        // 发送通知，通知订阅者帖子列表已更新
        NotificationCenter.default.post(
            name: NSNotification.Name("PostsUpdated"),
            object: nil, 
            userInfo: ["newPostsCount": newPosts.count]
        )
        
        print("📱 PostViewModel: 添加了 \(newPosts.count) 个新帖子，当前总数: \(posts.count)")
    }
} 