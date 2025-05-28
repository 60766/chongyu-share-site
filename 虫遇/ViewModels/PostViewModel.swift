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
    
    // 历史人物认知模型
    private let cognitionModel = HistoricalFigureCognitionModel.shared
    
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
     * @param userComment 用户评论内容
     * @param postContent 帖子内容
     * @param postIndex 帖子索引
     */
    func generateVirtualCharacterReply(
        characterID: String,
        to userComment: String,
        in postContent: String,
        postIndex: Int
    ) {
        print("🚀 开始生成虚拟角色回复 - 角色ID: \(characterID), 评论: \"\(userComment)\"")
        
        // 获取角色名称
        let characterName = getCharacterName(for: characterID)
        print("👤 角色名称: \(characterName)")
        
        // 获取相关评论作为上下文 (最多3条)
        let recentComments = getRelevantComments(for: postIndex, limit: 3)
        
        // 模拟一些延迟，使回复更自然
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.0...2.0)) {
            print("⏱️ 延迟后开始生成回复")
            
            // 使用VirtualCharacterService生成回复 - 修改为使用VirtualCharacterService
            self.virtualCharacterService.getCharacterReply(
                characterID: characterID,
                to: userComment,
                in: postContent
            )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ 生成回复失败: \(error.localizedDescription)")
                    }
                },
                receiveValue: { responseContent in
                    print("✅ 生成回复成功: \"\(String(responseContent.prefix(50)))...\"")
                    
                    // 添加评论到帖子
                    self.posts[postIndex].addComment(
                        username: characterName,
                        userAvatar: self.getCharacterAvatar(for: characterID),
                        content: responseContent,
                        isVirtualCharacter: true,
                        characterID: characterID
                    )
                    
                    print("📝 已添加回复到帖子")
                }
            )
            .store(in: &self.cancellables)
        }
    }
    
    /**
     * 获取帖子的相关评论作为上下文
     */
    private func getRelevantComments(for postIndex: Int, limit: Int) -> [String] {
        guard postIndex < posts.count else { return [] }
        
        // 获取最近的评论
        let comments = posts[postIndex].comments
        let recentComments = Array(comments.prefix(limit))
        
        // 转换为字符串数组
        return recentComments.map { "\($0.username): \($0.content)" }
    }
    
    /**
     * 生成虚拟角色评论
     * @param post 帖子
     * @param character 角色
     */
    func generateVirtualCharacterComment(for post: UserPostModel, from character: PHCharacterModel) {
        // 使用角色名作为ID
        let characterID = character.name.lowercased()
        
        // 获取帖子索引
        guard let postIndex = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        print("🚀 开始生成虚拟角色评论 - 角色ID: \(characterID), 帖子内容: \"\(String(post.content.prefix(50)))...\"")
        
        // 使用VirtualCharacterService生成评论
        virtualCharacterService.generateCharacterComment(
            characterID: characterID,
            forPost: post.content
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ 生成评论失败: \(error.localizedDescription)")
                }
            },
            receiveValue: { commentContent in
                print("✅ 生成评论成功: \"\(String(commentContent.prefix(50)))...\"")
                
                // 添加评论到帖子
                self.posts[postIndex].addComment(
                    username: character.name,
                    userAvatar: self.getCharacterAvatar(for: characterID),
                    content: commentContent,
                    isVirtualCharacter: true,
                    characterID: characterID
                )
                
                print("📝 已添加评论到帖子")
            }
        )
        .store(in: &cancellables)
    }
    
    /**
     * 获取角色头像
     * @param characterID 角色ID
     * @return 角色头像系统图标名称
     */
    private func getCharacterAvatar(for characterID: String) -> String {
        switch characterID {
        case "einstein":
            return "atom" // 原子图标适合爱因斯坦
        case "shakespeare":
            return "book.fill" // 书籍图标适合莎士比亚
        case "davinci":
            return "paintpalette.fill" // 绘画图标适合达芬奇
        case "goku":
            return "person.fill.viewfinder" // 人物图标适合孙悟空
        case "holmes":
            return "magnifyingglass" // 放大镜适合福尔摩斯
        case "naruto":
            return "tornado" // 螺旋适合鸣人
        case "confucius":
            return "scroll.fill" // 卷轴适合孔子
        case "newton":
            return "arrow.down.circle.fill" // 下降箭头适合牛顿
        case "libai":
            return "text.book.closed.fill" // 诗集适合李白
        default:
            return "person.circle.fill" // 通用人物图标
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
        
        // 增加日志输出
        print("🌀 开始生成「\(typeName)」类型帖子")
        
        // 历史名人列表 - 供所有创作类型使用，按照特性匹配头像
        let historicalFigures = ["爱因斯坦", "莎士比亚", "达芬奇", "孔子", "牛顿", "李白"]
        let avatarSymbols = ["atom", "book.fill", "paintpalette.fill", "scroll.fill", "graduationcap.fill", "text.book.closed.fill"]
        
        // 历史人物特征索引，用于生成更符合人物特点的内容
        let _: [String: (trait: String, field: String, style: String, motto: String, era: String)] = [
            "爱因斯坦": (
                trait: "物理学家，相对论创立者，幽默而富有哲思",
                field: "物理学、宇宙学、相对论",
                style: "善用生活比喻解释复杂概念，语言幽默风趣，充满智慧",
                motto: "想象力比知识更重要",
                era: "1879-1955"
            ),
            "莎士比亚": (
                trait: "文学巨匠，戏剧大师，洞察人性的诗人",
                field: "戏剧、诗歌、人性研究",
                style: "语言华丽优美，善用比喻和押韵，常引用自己作品中的名句",
                motto: "生活中最重要的是有爱人和被爱的能力",
                era: "1564-1616"
            ),
            "达芬奇": (
                trait: "全能天才，艺术家与科学家，观察大师",
                field: "艺术、解剖学、工程学、建筑",
                style: "思维跨界，注重细节观察，表达精确而充满想象力",
                motto: "简单是终极的复杂",
                era: "1452-1519"
            ),
            "孔子": (
                trait: "思想家，教育家，儒家学派创始人",
                field: "伦理、教育、政治哲学",
                style: "言简意赅，富含哲理，常用对偶句式，语言平实而深刻",
                motto: "学而不思则罔，思而不学则殆",
                era: "前551-前479"
            ),
            "牛顿": (
                trait: "科学家，万有引力发现者，严谨理性",
                field: "物理学、数学、天文学",
                style: "逻辑严密，论证清晰，表达谨慎而深思熟虑",
                motto: "如果我看得更远，是因为我站在巨人的肩膀上",
                era: "1643-1727"
            ),
            "李白": (
                trait: "诗仙，浪漫主义诗人，豪放不羁",
                field: "诗歌、文学、山水游记",
                style: "语言飘逸豪放，善用自然意象，情感丰富而充满想象力",
                motto: "天生我材必有用，千金散尽还复来",
                era: "701-762"
            )
        ]
        
        // 根据不同创作类型生成不同内容
        switch typeIndex {
        case 0: // 虫洞共鸣 - 替代原来的随机漫游
            // 使用增强的虫洞共鸣生成方法
            let resonanceSituations = [
                "寻找答案",
                "探索未知",
                "突破困境",
                "理解复杂问题",
                "寻求智慧"
            ]
            
            let resonanceExpectations = [
                "希望获得创新视角",
                "期待深入的洞察",
                "渴望启发性的思考",
                "希望找到解决方案",
                "寻求哲学层面的理解"
            ]
            
            // 为每个帖子随机选择情境和期望
            var postsData: [(situation: String, expectation: String, figure: String)] = []
            
            // 确保五种历史人物都有机会被选中
            var selectedFigures = Set<String>()
            for _ in 0..<5 {
                let situation = resonanceSituations.randomElement() ?? resonanceSituations[0]
                let expectation = resonanceExpectations.randomElement() ?? resonanceExpectations[0]
                
                // 选择未使用过的历史人物，确保多样性
                var figure: String
                if selectedFigures.count < historicalFigures.count {
                    // 还有未使用的历史人物
                    repeat {
                        figure = historicalFigures.randomElement() ?? historicalFigures[0]
                    } while selectedFigures.contains(figure)
                } else {
                    // 所有历史人物都已使用，随机选择
                    figure = historicalFigures.randomElement() ?? historicalFigures[0]
                }
                
                selectedFigures.insert(figure)
                postsData.append((situation, expectation, figure))
            }
            
            // 使用ResonanceContentGenerator生成内容
            for (situation, expectation, figure) in postsData {
                // 生成内容
                let content = ResonanceContentGenerator.shared.generateResonanceContent(
                    forFigure: figure,
                    situation: situation,
                    expectation: expectation,
                    keywords: nil
                )
                
                // 选择2-3位其他历史人物进行评论
                var commenters = Set<Int>()
                let authorIndex = historicalFigures.firstIndex(of: figure) ?? 0
                let commentCount = Int.random(in: 2...3)
                
                while commenters.count < commentCount {
                    let commenterIndex = Int.random(in: 0..<historicalFigures.count)
                    if commenterIndex != authorIndex {
                        commenters.insert(commenterIndex)
                    }
                }
                
                // 生成评论
                var comments: [UserCommentModel] = []
                for commenterIndex in commenters {
                    let commenterName = historicalFigures[commenterIndex]
                    let comment = generateHistoricalComment(
                        aboutContent: content,
                        fromFigure: commenterName,
                        aboutFigure: figure
                    )
                    comments.append(comment)
                }
                
                // 创建帖子
                let post = UserPostModel(
                    username: figure,
                    userAvatar: avatarSymbols[authorIndex],
                    content: content,
                    images: [], // 不使用图片
                    datePosted: Date().addingTimeInterval(-Double.random(in: 0...3600)),
                    likes: Int.random(in: 20...100),
                    comments: comments,
                    isLikedByCurrentUser: false,
                    isBookmarkedByCurrentUser: false
                )
                
                generatedPosts.append(post)
            }
            
        case 1: // 日常心情 - 历史人物的情感表达
            // 日常心情类型的帖子内容 - 强调情感共鸣与日常生活感悟
            let moodContents = [
                "今天在花园散步时，一片花瓣轻轻飘落在我肩上，仿佛是自然给我的一个温柔问候。这小小的瞬间让我想到，生命中最美好的事物往往是那些微不足道的细节。",
                "工作压力大的时候，我喜欢泡一杯茶，静静地看窗外的云卷云舒。这样的片刻宁静总能让我重新找回平衡。有时候，答案就在放空自己的时刻悄然而至。",
                "雨后的空气特别清新，街上的灯光倒映在湿漉漉的地面上，像是另一个世界。这样的夜晚总让我感到莫名的感动，仿佛能触摸到时间的质感。",
                "今天遇到了一位老者，他眼中的智慧让我想起了生命的长河。有时候一个眼神的交流，胜过千言万语，跨越了所有时代的隔阂。",
                "清晨第一缕阳光透过窗帘洒在书桌上的那一刻，感觉一天的可能性都在眼前展开。新的开始总是充满希望，无论经历过多少次失败与挫折。"
            ]
            
            // 扩展情感主题与情绪色彩，涵盖更丰富的情感光谱
            let moodThemes = [
                "宁静", "思考", "感悟", "回忆", "希望", 
                "孤独", "喜悦", "憧憬", "怀旧", "惊奇",
                "烦躁", "释然", "迷茫", "满足", "疲惫",
                "振奋", "失落", "期待", "无奈", "恍惚"
            ]
            
            // 人物特定的日常心情 - 更加日常化、更具情感共鸣，体现历史人物的亲近感
            let personalizedMoodContents: [String: [String]] = [
                "爱因斯坦": [
                    "今天早上在校园里散步，看到一群孩子在玩耍，他们的笑声比我研究的任何公式都更美妙。忍不住停下来，拉起小提琴即兴演奏了一曲。当音乐融入晨光，感觉整个人都放松了许多。其实生活中最美好的事物，往往是那些简单快乐的瞬间吧。",
                    
                    "又是一个熬夜工作到深夜的日子😅 走出房间抬头看了看星空，还是那么深邃美丽。突然想起小时候第一次看到指南针时的震撼，那种好奇心一直伴随着我。可能这就是支撑我不断探索的动力吧，再累也值得。",
                    
                    "糟糕的一天！计算了整整五小时，结果发现一开始就犯了低级错误。这种感觉太熟悉了，科学没那么光鲜亮丽，大部分时候就是在不断犯错、发现错误、然后重来。有时候会怀疑自己是不是在浪费时间...不过，至少我的头发已经够乱了，不会更糟了吧？🙃",
                    
                    "今天参加了一个无聊的学术会议，差点在前排睡着。为什么有些学者非要把简单的概念说得如此复杂？真理应该是优雅简洁的。会后有位年轻学生问了个特别好的问题，让我眼前一亮。回家路上一直在思考这个问题，竟然错过了公交站，又得走回头路了😂",
                    
                    "刚收到朋友寄来的手表，我很喜欢，但老实说可能过不了多久就会忘记时间、忘记地点、甚至忘记这块表放哪了。普林斯顿的同事们开玩笑说我是'一心只有物理无暇顾及生活的教授'...虽然有点夸张，但我确实上周又把钥匙锁在屋里了。善良的邻居已经习惯帮我保管备用钥匙了。"
                ],
                "莎士比亚": [
                    "今天沿着河边散步，阳光洒在水面上，波光粼粼，莫名感动。岸边有对情侣依偎着低声交谈，那画面美得不需要任何语言描述。生活中这些小小的瞬间，常常比任何剧本都更动人。暮色渐沉，脑海里又浮现出一个未完成的故事……",
                    
                    "排练间隙独自坐在角落里看着大家忙碌的样子，有感而发：我们是不是每天都戴着不同的面具生活着？刚才一个年轻演员读台词时声音微微发抖的样子，让我想起自己刚开始时的紧张。艺术真奇妙，它让我们找到了可以安放灵魂的地方。",
                    
                    "写作瓶颈期真是太难受了！盯着纸张看了一整天，几乎一个字都没写出来。有人说我是天才，哈！如果他们看到我今天把废纸篓塞满的样子，恐怕会大跌眼镜。创作灵感这东西，来也匆匆去也匆匆，像个反复无常的情人...今晚去酒馆喝一杯，或许能在那些市井小民的闲聊中找回些灵感。",
                    
                    "刚从剧院回来，观众的反应让我喜出望外！当幕布落下时，那掌声经久不息...这种被理解的感觉真好。虽然写作时常感孤独，但此刻所有的辛苦都值得了。今晚睡得一定特别香。不过明早得早起修改下一幕的台词，那个小丑的角色还需要增加些诙谐感。",
                    
                    "雨天总让我情绪低落。今天一整天都窝在家里，试图写作，但思绪却飘向那些已逝的朋友。生命如此短暂，我们匆匆来又匆匆去，留下些什么？这些年写了那么多故事，但有时会想，如果有一天没人再读这些文字，它们是否还有意义？也许我该出去走走，这阴郁的天气影响了我的心情。"
                ],
                "达芬奇": [
                    "今早结束工作后随便在街头找了家咖啡馆坐下。看着来来往往的行人，不由自主拿出速写本记录下那些瞬间的表情——老人眼角的皱纹，孩子纯真的笑容，每张脸都是一个故事。这可能是职业病吧，总忍不住观察人们细微的表情变化。",
                    
                    "雨后的城市格外清新，阳光透过云层洒在湿漉漉的地面上。注意到雨滴从叶片滚落的轨迹居然有种数学美感，大自然的设计总是如此精妙。随手拍了几张照片，回去可能会画下来，感觉对我最近卡住的项目有些启发。",
                    
                    "今天实在是太沮丧了！修改了整整一周的机翼设计，测试时又失败了。每次以为找到了飞行的秘密，自然就会用一次失败无情地提醒我：人类的想象力和大自然的智慧还有多大差距。手指被工具划伤，衣服全是油彩，头发还被烧焦了一缕...但我明天还会继续，因为那一刻的飞翔值得所有努力。",
                    
                    "完美主义真是既是礼物又是诅咒。今天盯着那幅肖像画看了六个小时，只为调整一个微小的阴影，甚至连午餐都忘了吃。朋友们常说我\"过于苛求\"，但我怎能容忍那双眼睛看起来没有生命力？艺术不该有妥协...虽然现在我的背痛得要命，但那个眼神终于有了我想要的深度。",
                    
                    "今天在集市遇到一位老农民，他那双布满老茧的手引起了我的注意。那是岁月和劳作在人体上留下的自然雕塑。我请求为他画像，他腼腆地笑了，说自己不值得画。多么错误！每个生命都蕴含着无限的美学价值。我们聊了整整一下午，关于庄稼、天气和他的孙子们，这可能是最近最愉快的一天了。"
                ],
                "孔子": [
                    "今天和几个学生去郊外走了走，看到农民在田里忙碌的场景，突然明白了很多道理。每个人各司其职，社会才能和谐运转。回程路上遇到一位老人在教孙子读书，那场景让我很感动。知识的传承从未间断，这或许是最美的风景。",
                    
                    "早起读了会书，不知不觉到了中午。窗外鸟叫声清脆，配合着古典音乐，别有一番韵味。温故而知新，每次重读总有新的体会。今天突然想明白了：学习的意义不在于积累多少知识，而在于持之以恒的态度，就像小溪汇入大海，日积月累却不自知。",
                    
                    "今日与学生讨论\"仁\"的含义，竟起了争执。我坚持己见，后来发现是我过于固执了。年轻人的想法有时出人意料，但常常令人耳目一新。这让我反思：为师者不应自视甚高，与学生相处，也是互相学习的过程。教学相长，始终如一。今晚睡前要好好思考这个问题。",
                    
                    "下午在街上被人认出，热情地叫我\"夫子\"。虽已习惯，但总有些不自在。我不过是个普通人，也有迷茫困惑之时。人们期望我无所不知，处处完美，这压力有时令人透不过气。回家后独自弹琴许久，音乐总能让心情平静下来。明天继续教课，希望能少些\"说教\"，多些真诚交流。",
                    
                    "今天心情烦闷，看到邻居孩童嬉戏，却莫名想哭。也许是年纪大了，容易感伤。回想一生所学所教，究竟有多少真正理解了我的用心？有时觉得是在对牛弹琴，有时又被学生的领悟力惊喜。这大概就是为师的酸甜苦辣吧。夜深人静，独坐窗前，看着明月，不知何时才能实现那理想中的大同世界。"
                ],
                "牛顿": [
                    "今天在公园的苹果树下坐了一下午，看着阳光透过树叶形成斑驳的光影。随手玩了玩三棱镜，折射出彩虹的颜色，引来几个小朋友好奇地围观。生活中处处有科学，只要你愿意用心去观察。想到妈妈常说的那句话：细节中藏着真相。",
                    
                    "深夜的实验室出奇地安静，只有电脑屏幕的光在闪烁。刚完成一组复杂的计算，疲惫但兴奋。窗外月光如水，不禁想起小时候也是这样望着夜空冥想。现在虽然有了更多答案，但提出的问题却更多了。或许这就是科学的魅力——永无止境的探索。",
                    
                    "今天和霍克的争论真是令人沮丧！为什么他总是曲解我的理论？我明明已经用最清晰的数学语言表达了，他却坚持自己的错误理解。这种学术争端既浪费时间又消耗精力。写了一整天的反驳信，连晚饭都忘了吃。希望学术界至少保留一丝理性和开放的态度，而不是固守成见。明天继续实验，证明给所有人看！",
                    
                    "实验室里一个人待了三天，终于有了突破！当看到数据吻合理论预测的那一刻，激动得差点把墨水打翻。这种发现背后规律的喜悦，是任何世俗的享乐都无法比拟的。虽然现在头痛欲裂，眼睛因为长时间计算而干涩不已，但这一切都值得。明天得好好休息，不，等等，我好像又有了新想法...",
                    
                    "有时候真羡慕那些能轻松社交的人。今天的皇家学会晚宴上，大家谈笑风生，而我却尴尬地站在角落，不知道该说什么。当话题转向我的研究时，我滔滔不绝；一旦谈及日常琐事，我就词穷了。母亲常说我\"只懂得和数字做朋友\"，或许她是对的。不过，至少数字不会背叛你，规律永远诚实。"
                ],
                "李白": [
                    "今天爬了座山，站在山顶，看着云海翻滚，心情突然开阔起来。带了瓶小酒，独自一人小酌几杯，写了几句不成形的诗。这一刻，感觉只有我和这片山水，所有烦恼都随风而去。",
                    
                    "失眠的夜晚，推开窗户看到一轮明月高挂天空。院子里的泉水叮咚作响，听着这自然的音乐，心也跟着平静下来。提笔写下几行字，记录下这美好时刻。可能这就是生活的意义吧，在平凡中发现美，在寂静中聆听心声。",
                    
                    "今天被朝廷的那帮官僚气得不行！明明是他们邀我去献诗，结果因为我的几句实话就勃然大怒。这世道，说真话比登天还难。那些只会阿谀奉承的小人倒是步步高升。一气之下喝了太多酒，现在头痛欲裂。朋友劝我少惹麻烦，可我这性格改不了了，宁愿孤独终老，也不愿违心讨好。",
                    
                    "昨夜一场秋雨过后，院子里的桂花开了，香气扑鼻而来，令人心醉。想起十年前同样的季节，在洞庭湖边看满天星斗的情景。岁月匆匆，白发渐生，但对美的感动依然如初。有时候很想念远方的朋友们，不知何时能再相聚，把酒言欢。这世间最珍贵的，莫过于真挚的情谊和自由的心灵。",
                    
                    "今早收到家书，得知老友去世的消息，心情低落了一整天。看着窗外飘落的花瓣，不禁感叹生命的脆弱与短暂。我们总以为来日方长，却常常忘了珍惜眼前人。放下手中的笔，决定明日启程探望几位年迈的朋友。比起那些未完成的诗篇，友情更值得我即刻行动。生死无常，唯有当下值得珍视。"
                ]
            ]
            
            // 生成日常心情类型的帖子
            for i in 0..<5 {
                // 确保使用所有历史人物，保持多样性
                let authorIndex = i % historicalFigures.count
                let authorName = historicalFigures[authorIndex]
                let authorAvatar = avatarSymbols[authorIndex]
                
                // 获取人物特征
                guard let traits = cognitionModel.getFigureTraits(for: authorName) else {
                    continue
                }
                
                // 选择情感主题（仅用于内部逻辑，不再用于标题）
                let _ = moodThemes.randomElement() ?? "感悟"
                
                // 生成内容
                var content: String
                
                // 优先使用个性化内容
                if let personalizedContents = personalizedMoodContents[authorName], !personalizedContents.isEmpty, Double.random(in: 0...1) > 0.2 {
                    // 80%的几率使用角色特定的内容
                    content = personalizedContents[Int.random(in: 0..<personalizedContents.count)]
                } else {
                    // 20%的几率使用通用内容
                    content = moodContents[i % moodContents.count]
                }
                
                // 自然化表达，偶尔添加表情符号或简单的感叹（30%几率）
                if Double.random(in: 0...1) > 0.7 {
                    let naturalExpressions = ["", "😊", "...", "！", "💭", "🙏", "❤️", "✨"]
                    content += naturalExpressions[Int.random(in: 0..<naturalExpressions.count)]
                }
                
                // 为帖子生成1-2条评论
                var comments: [UserCommentModel] = []
                
                // 从其他历史人物中随机选择评论者
                var commenters = Set<Int>()
                while commenters.count < 2 && commenters.count < historicalFigures.count - 1 {
                    let commenterIndex = Int.random(in: 0..<historicalFigures.count)
                    if commenterIndex != authorIndex {
                        commenters.insert(commenterIndex)
                    }
                }
                
                // 生成评论
                for commenterIndex in commenters {
                    let commenterName = historicalFigures[commenterIndex]
                    let comment = generateHistoricalComment(
                        aboutContent: content,
                        fromFigure: commenterName,
                        aboutFigure: authorName
                    )
                    comments.append(comment)
                }
                
                // 创建帖子 - 以历史名人为作者，体现日常情感
                let post = UserPostModel(
                    username: authorName,
                    userAvatar: authorAvatar,
                    content: content,
                    images: [], // 不使用图片
                    datePosted: Date().addingTimeInterval(-Double.random(in: 0...7200)),
                    likes: Int.random(in: 10...60),
                    comments: comments,
                    isLikedByCurrentUser: false,
                    isBookmarkedByCurrentUser: false
                )
                
                generatedPosts.append(post)
            }
            
        case 2: // 古今对望 - 历史名人对当代话题的看法
            // 现代话题列表 - 基础话题库
            let modernTopics = [
                "人工智能将如何改变人类社会？",
                "虚拟现实技术会让人们逃避现实生活吗？",
                "社交媒体是拉近了人与人的距离，还是让人更加孤独？",
                "太空探索应该是人类的优先事项吗？",
                "在信息爆炸时代，如何分辨真相与谎言？"
            ]
            
            // 扩展的现代话题库 - 更多富有深度的问题
            let extendedModernTopics = [
                "数字身份与数据隐私：随着技术发展，我们的个人数据成为有价值的商品。在未来社会，个人数据的所有权应该如何定义？隐私与便利之间应如何平衡？",
                
                "永生技术：若科技能将人类意识上传至数字空间或延长寿命至数百年，社会结构、道德观念、资源分配将如何重塑？对生死的理解会如何改变？",
                
                "元宇宙社会：如果未来人类大部分时间都在数字虚拟世界度过，现实与虚拟的界限将如何重新定义？人际关系、经济模式和文化表达会有何转变？",
                
                "人类增强：基因编辑、脑机接口与人体强化技术正在发展。若能选择改造自己或后代的能力，这会扩大还是缩小社会不平等？道德边界在哪里？",
                
                "气候变化与全球治理：面对全球性环境危机，国家主权与全球集体行动如何平衡？如何构建公平有效的全球治理机制？未来几代人的权益如何在当下决策中得到尊重？",
                
                "算法决策与人类自主：当越来越多的社会决策由AI算法做出，人类自由意志的概念将如何变化？如何确保算法的公平性和透明度？人类价值观如何嵌入技术？",
                
                "跨星际文明：若人类成为多行星物种，地球文明分散在不同星球上，文化认同、治理系统和道德观念将如何演变？如何维持人类作为一个物种的统一性？",
                
                "后稀缺经济：如果自动化和人工智能能够创造物质丰裕社会，人类的工作、价值和意义将如何重新定义？在不需要为生存而工作的世界里，人类将如何寻找目标和满足感？",
                
                "神经伦理：随着我们对大脑的了解加深，记忆编辑、思想解码和情绪调节技术可能成为现实。这些技术如何影响个人身份和自由？应当建立怎样的伦理框架？",
                
                "数字不朽：若能创建个人数字复制品，模拟逝者的思维和个性，这将如何改变我们对死亡、继承和纪念的理解？虚拟存在是否具有权利和道德地位？"
            ]
            
            // 为每个历史人物创建更特色化的回应
            let figureSpecificResponses: [String: [(topic: String, response: String)]] = [
                "爱因斯坦": [
                    (
                        topic: "量子计算与现代物理学的发展",
                        response: "观察量子计算的发展让我感到既熟悉又陌生。我和玻尔、海森堡关于量子力学的辩论现在看来只是开始。量子纠缠——这个我曾称为'幽灵般的远距离作用'的现象，如今成为量子计算的基础。我仍然相信'上帝不掷骰子'，但或许宇宙比我想象的更微妙。\n\n量子比特的叠加状态使计算能力呈指数级增长，这暗示着我们的宇宙模型尚不完整。如果有机会重新思考相对论，我会更认真考虑量子世界的不确定性。然而，技术进步不应忽视伦理：科学无国界，但科学家有祖国和良知。创造力不仅在于想象未知，还在于负责任地引导发现的应用方向。"
                    ),
                    (
                        topic: "气候变化与可持续发展",
                        response: "E=mc²不仅是能量与质量的等式，更揭示了我们与自然的深层联系。地球是一个封闭系统，我们消耗的每一份能量都有其代价。观察当今的气候危机，我看到了热力学第二定律的宏大演绎——熵增原理在全球尺度上的体现。\n\n然而，科学给了我们理解问题的能力，也给了我们解决问题的工具。可再生能源的利用实际上是将太阳这一核聚变反应器的能量转化为人类可用的形式。我曾说过，想象力比知识更重要，因为知识有限，而想象力概括世界上的一切。现在，我们需要这种想象力来构建可持续的未来，创造一种不以破坏家园为代价的文明模式。"
                    )
                ],
                "莎士比亚": [
                    (
                        topic: "社交媒体与现代身份认同",
                        response: "'一千个读者眼中有一千个哈姆雷特'，而现在，社交媒体上的每个人都同时是观众和演员。我们在数字舞台上展示经过精心策划的自我形象，却迷失在无数角色的扮演中。'真实'成为最稀缺的商品，'成为自己'反而需要巨大勇气。\n\n在《皆大欢喜》中，我写道：'整个世界是一个舞台，所有的男男女女都不过是演员。'社交媒体将这一隐喻变为字面现实。我们都有公开档案和私人面具，却很少有人能像雅克那样清醒地意识到自己正在表演。在这个过度互联的世界里，或许最宝贵的不是连接，而是真正的亲密和坦诚——那些不会被点赞数量衡量的关系。"
                    ),
                    (
                        topic: "人工智能与创意写作",
                        response: "我曾写道，'创作是在晨曦前的黑暗中捕捉遥远星辰的光芒'。如今，人工智能能写出十四行诗和独幕剧，这让我思考创造力的本质。AI可以分析我的所有作品，模仿我的风格，甚至预测我的用词习惯，但它是否能真正理解哈姆雷特的犹疑、奥赛罗的嫉妒、李尔的傲慢？\n\n人工智能或许能掌握语法和修辞，却很难体会爱、恨、恐惧、渴望的深度。它不会因为无法用语言表达的感受而辗转反侧。然而，我不会轻视这些数字创造者。它们是新时代的剧作助手，可以扩展人类想象力的边界。艺术的本质从来不是单纯的创新，而是对人类经验的真实反映和情感共鸣的唤起。只要这一点不变，人类创作者就会继续存在。"
                    )
                ],
                "达芬奇": [
                    (
                        topic: "生物科技与人体设计",
                        response: "当我解剖尸体研究人体构造时，我将其视为完美的自然机器。如今，基因编辑技术如CRISPR让人类可以重写生命的代码，这令我既着迷又警惕。我看到了我的《维特鲁威人》从理想的形象变成可塑造的模板。\n\n作为解剖学家和工程师，我欣赏这种精确干预的可能性——修复遗传缺陷、治愈先天性疾病。然而，作为艺术家和哲学家，我担忧我们可能尚未理解生命完整的平衡。每一种比例、每一处细节，都是经过数百万年演化的和谐结果。我们的科学是否足够先进，能够预见改变这种平衡的所有后果？\n\n创新需要审慎，设计需要谦逊。在追求完美的过程中，我们不应忽视多样性的价值。真正的生物设计艺术在于理解自然，而非仅仅征服自然。"
                    ),
                    (
                        topic: "城市规划与未来建筑",
                        response: "如果我能漫步在现代城市，我会对摩天大楼和高速交通感到惊叹，但也会为缺乏人性尺度的设计而遗憾。在我的理想城市草图中，我强调了绿地、水道和公共空间的重要性，这些仍然是有效城市规划的核心。\n\n未来建筑不应仅追求高度和效率，还应考虑生态系统服务、社区连接和心理健康。智能建筑可以像生物一样呼吸、适应和进化，与自然和谐共存而非与之对抗。我最感兴趣的是生物灵感设计——向树木学习如何过滤空气，向贝壳学习如何创造高强度结构。\n\n当我设计理想城市时，我梦想的是一个既满足物质需求又培养灵魂的环境。现代技术提供了实现这一愿景的工具，但只有将技术与人文关怀、艺术感性和生态智慧相结合，才能创造真正值得居住的城市。"
                    )
                ],
                "孔子": [
                    (
                        topic: "教育科技与终身学习",
                        response: "吾观今日之教育科技，可一人千里之外授课，受业者数以万计，诚为盛事。然学之道，贵在交流、切磋、践行，非徒闻而已。科技虽便利，不可使师生之情淡漠，教学之道机械。\n\n吾曰：'不愤不启，不悱不发。'学习须自有疑问、有困惑而起，教授须因材施教，观其神情，察其思路，因势利导。数据分析可知学生之进度，却难明其心之所向；算法可推荐学习路径，却难替代因人而异的引导。\n\n现代教育当取科技之便利，存师生之情谊，行启发之教学。学习不止于知识传授，更在于品格养成、思辨能力培养。'学而时习之，不亦说乎'，此乐在于求知过程，在于自我超越，不在证书数量。无论科技如何发达，教育本质应不忘初心——成人达己，推己及人。"
                    ),
                    (
                        topic: "人工智能与伦理决策",
                        response: "闻智能机器日益进步，能辨音像、解文义、下棋胜人，然吾思，其能知'仁'乎？能行'礼'乎？能守'义'乎？机器之'智'，犹刀之利，利则能断物，然不知何物当断，何物不当断，此人之智慧也。\n\n吾教弟子，重修身正己，明是非之辨，识礼义之分。'己所不欲，勿施于人'，此判断之基准，岂可编为程式？因人之心，复杂多变，随境而异，随时而移。若令机器决策，必先问：其所用之标准谁所设？其价值取向为何？\n\n智能科技之用，当以民为本，以仁为先。权力之下，须有制约；数据之集，须有伦理；算法之创，须有透明。无论技术如何精进，不可使工具凌驾人性，不可使效率替代公正。科技愈进，人之自省愈当深，自律愈当严，庶几能和谐共处，相得益彰。"
                    )
                ],
                "牛顿": [
                    (
                        topic: "量子物理学与不确定性原理",
                        response: "量子物理学的发展让我深感谦卑。我曾以为万有引力和经典力学能够解释宇宙的全部运行，但现在看来，那只是宏观世界的近似描述。海森堡的不确定性原理——即无法同时精确测量粒子的位置和动量——挑战了我建立的确定性物理学模型。\n\n然而，我并不认为这使得自然规律变得'随机'。正如我在研究光学时发现，复杂现象背后往往有简单规律。量子层面的不确定性可能只是我们尚未发现的更深层次规律的表现。每个新理论不是推翻旧理论，而是扩展其适用范围或指出其局限性。\n\n若我能重返剑桥，我会专注研究量子场论，寻找统一的理论框架。科学进步的核心在于，每个时代都必须接受自己的理论是不完整的。我曾说'如果我看得更远，是因为我站在巨人的肩膀上'，今天的物理学家同样站在包括我在内的前人肩上，望向更加广阔的宇宙奥秘。"
                    ),
                    (
                        topic: "大数据与社会预测模型",
                        response: "从数学和物理学角度观察，大数据分析与我的微积分思想有异曲同工之妙。正如我创建的微积分能够描述连续变化的物理系统，现代数据模型能够捕捉社会行为的模式和趋势。\n\n然而，社会系统的复杂性远超物理系统。我在研究天体运动时发现，即使是三体问题也难以精确求解，更何况是由数十亿具有自由意志的个体组成的社会？大数据预测模型面临的'蝴蝶效应'远比物理学中的更为显著。初始条件的微小差异经过非线性放大，可能导致完全不同的结果。\n\n最重要的是，与物理定律不同，社会规律会受到人们认识它们这一事实的影响。当人们知道自己被预测和分析时，他们会改变行为，从而改变预测的有效性。我认为，真正有价值的预测模型不是试图控制未来，而是帮助人们理解复杂决策的可能后果，扩展而非限制人类选择的自由度。"
                    )
                ],
                "李白": [
                    (
                        topic: "环球旅行与文化体验",
                        response: "今有飞机高铁，一日千里，环游世界，如探囊取物。吾昔日长安至蜀地，跋山涉水，历时经月，今人数小时可达，不免慨叹世异时移。\n\n然速度虽快，体验或浅。吾游山时，常'行到水穷处，坐看云起时'，静观细品，方得真趣。今人景点打卡，行色匆匆，恐难体会'飞流直下三千尺，疑是银河落九天'之壮美，'相看两不厌，只有敬亭山'之深情。\n\n吾以为，旅行之道，贵在心境。无论青藏高原抑或撒哈拉沙漠，北极冰川抑或热带雨林，若能以谦卑之心，融入当地，与居民促膝长谈，品其美食，闻其故事，则无论远近，皆能获益。身虽归，心犹在；文虽古，意犹新。若能将所见所闻，化为诗文，记录感悟，则此行更添意义，如吾当年'安能摧眉折腰事权贵，使我不得开心颜'，因游历而生，千年传诵不绝。"
                    ),
                    (
                        topic: "现代都市生活与孤独感",
                        response: "高楼林立，霓虹闪烁，车水马龙，人声鼎沸；然抬头望，不见星空，低头视，不见流水。此乃现代都市景象，令我思绪万千。\n\n昔日长安十万户，尚有诗酒趁年华；今日城市千万人，却闻寂寞愈喧嚣。手机屏幕虽连四海，心灵相通却不易。'举头望明月，低头思故乡'，今人何处是故乡？家在异乡为异客，异乡亦可为家乡。\n\n吾观都市孤独，源于心不静。'相思相见知何日，此时此夜难为情'，古往今来，人心相通。吾有一法：邀三两知己，共饮清酒，或登高望远，或临水赋诗，或夜话星辰，皆能消解都市之孤寂。'人生得意须尽欢，莫使金樽空对月'，都市之中，亦能逍遥自在，关键在与山水相亲，与朋友相聚，与自然相融。"
                    )
                ]
            ]
            
            // 生成古今对望类型的帖子
            for i in 0..<5 {
                // 选择现代话题
                var topic: String
                var content: String
                
                // 确保使用所有历史人物，保持多样性
                let mainSpeakerIndex = i % historicalFigures.count
                let mainSpeaker = historicalFigures[mainSpeakerIndex]
                let _ = avatarSymbols[mainSpeakerIndex]
                
                // 1. 优先使用特定人物的特定话题内容
                if let specificResponses = figureSpecificResponses[mainSpeaker], !specificResponses.isEmpty && Double.random(in: 0...1) > 0.3 {
                    // 70%的几率使用预设的特定人物回应
                    let selectedResponse = specificResponses.randomElement()!
                    topic = selectedResponse.topic
                    content = selectedResponse.response
                } else {
                    // 2. 其次使用随机话题并生成一般性回应
                    let topicPool = Double.random(in: 0...1) > 0.4 ? extendedModernTopics : modernTopics
                    topic = topicPool[i % topicPool.count]
                    
                    // 添加话题作为标题
                    content = "【\(topic)】\n\n"
                    // 添加主要内容
                    content += generateHistoricalPerspective(onTopic: topic, fromFigure: mainSpeaker)
                }
                
                // 随机选择2-3位其他历史人物进行评论
                var commenters = Set<Int>()
                let commentCount = Int.random(in: 2...3)
                while commenters.count < commentCount {
                    let commenterIndex = Int.random(in: 0..<historicalFigures.count)
                    if commenterIndex != mainSpeakerIndex {
                        commenters.insert(commenterIndex)
                    }
                }
                
                // 生成评论
                var comments: [UserCommentModel] = []
                for commenterIndex in commenters {
                    let commenterName = historicalFigures[commenterIndex]
                    let comment = generateHistoricalComment(
                        aboutContent: content,
                        fromFigure: commenterName,
                        aboutFigure: mainSpeaker
                    )
                    comments.append(comment)
                }
                
                // 创建帖子 - 以历史名人为作者，探讨现代话题
                let post = UserPostModel(
                    username: mainSpeaker,
                    userAvatar: avatarSymbols[mainSpeakerIndex],
                    content: content,
                    images: [], // 不使用图片
                    datePosted: Date().addingTimeInterval(-Double.random(in: 0...14400)),
                    likes: Int.random(in: 30...120), // 古今对望类型一般会获得较多点赞
                    comments: comments,
                    isLikedByCurrentUser: false,
                    isBookmarkedByCurrentUser: false
                )
                
                generatedPosts.append(post)
            }
            
        // 添加生成历史人物对现代话题看法的函数
        func generateHistoricalPerspective(onTopic topic: String, fromFigure figure: String) -> String {
            // 根据不同历史人物的特点，生成他们对现代话题的看法
            switch figure {
            case "爱因斯坦":
                let perspectives = [
                    "关于\(topic)，我认为这是一个关乎相对性的问题。正如E=mc²揭示了能量与物质的等价性，现代技术与人类心智也存在深刻的相互转化关系。我们应当用科学的严谨和人文的关怀去审视这一课题，寻找那些恒定不变的普适原则。",
                    "思考\(topic)这个问题时，我想说：'想象力比知识更重要'。技术工具本身并无善恶，关键在于我们如何引导其发展方向。我们需要超越当下思维限制，构想一个和谐的未来图景，就像我年轻时思考光速问题一样——打破常规，寻找统一。",
                    "对于\(topic)，我不赞同将其简化为二元对立。这让我想起量子力学中的波粒二象性——看似矛盾的现象可以共存。同样，技术发展中的矛盾也需要我们用更高维度的思考来统一理解。最简单的解释往往是最优美的，但前提是不能过度简化。"
                ]
                return perspectives[Int.random(in: 0..<perspectives.count)]
            
            case "莎士比亚":
                let perspectives = [
                    "若论\(topic)，吾当言：'生存还是毁灭，这是一个问题。'现代科技如舞台大幕，徐徐展开人性的喜剧与悲剧。人类既是演员，亦为导演，在数字洪流中寻找自我。无论工具如何变迁，爱、恨、嫉妒、雄心这些永恒情感，依然是推动一切的原动力。",
                    "关于\(topic)，让我借哈姆雷特之口说道：'这世界上有千万种事物，是你们哲学里所没有梦想到的。'现代科技令人赞叹，却难逃人性的枷锁。如同我笔下的凯撒、奥赛罗、李尔，权力越大，诱惑与堕落的风险也越高。科技如双刃剑，既能照亮灵魂，也能加深黑暗。",
                    "谈及\(topic)，我思忖：'我们所处的时代，理性失去光彩，行为失去优雅。'当代社会的数字面具后，人类依然渴求真实连接。如罗密欧与朱丽叶跨越家族鸿沟，现代人也需跨越技术屏障，重寻真挚情感。无论时代如何更迭，讲述人类故事的艺术永不过时。"
                ]
                return perspectives[Int.random(in: 0..<perspectives.count)]
                
            case "达芬奇":
                let perspectives = [
                    "观察\(topic)，我发现这是艺术与科学的完美交汇点。正如我在解剖学研究中寻找人体比例的黄金法则，在当代技术中，我们也应寻求美学与功能的平衡。创新不应仅追求'能做什么'，更应思考'应该做什么'。细节中藏有真理，观察是一切发明的母亲。",
                    "思索\(topic)，我想说：'单纯的模仿是贫瘠的。'技术创新需要超越模仿自然，达到理解自然规律并加以升华的境界。我毕生致力于将艺术、工程学、解剖学和建筑融为一体，今天的社会也需要这种跨学科思维，打破知识壁垒，创造真正的奇迹。",
                    "关于\(topic)的讨论，让我想起：'智慧是经验之女。'我们应通过实践与观察获取知识，而非盲从权威。当代科技为人类提供了前所未有的观察工具，但最终的判断力仍需来自经验与智慧的积累。科学、艺术与人文精神，应如我的素描本一样，融为一体。"
                ]
                return perspectives[Int.random(in: 0..<perspectives.count)]
                
            case "孔子":
                let perspectives = [
                    "论\(topic)，当思其对人伦之影响。盖历史变迁，表在事件，实则人心。故观史当如照镜，见古人得失，思今日取舍。'温故而知新，可以为师矣。'历史之价值，不在故纸堆中，而在对当世之启迪。",
                    "览\(topic)，吾见治道之变。天下大事，必作于细。国之兴衰，系于礼义廉耻之存亡。历史潮流看似不可抗，然一国之运，实决于人才之盛衰、制度之良莠。'德不孤，必有邻。'善政之道，古今一理。",
                    "究\(topic)，当思'修身齐家治国平天下'之道。历史兴替，非偶然，实乃人事。圣人观史，不徒记事，而重明理。'己所不欲，勿施于人'，此乃古今社会之公理。欲知兴亡之本，当自人心革新始。"
                ]
                return perspectives[Int.random(in: 0..<perspectives.count)]
                
            case "牛顿":
                let perspectives = [
                    "分析\(topic)，我发现其中蕴含的规律性。历史变革如同物理系统，遵循某些基本定律——每个行动都有反作用力，社会力量的平衡与转移遵循类似守恒原理的模式。通过数学建模，或许能揭示历史发展的内在逻辑。",
                    "研究\(topic)，我注重实证与逻辑推理。历史研究如同科学实验，需要严谨的方法论。通过收集一手史料，排除干扰因素，我们可以更接近历史真相。'自然哲学的规则是，承认为真的原因不应超出足以解释现象所需的数量。'这同样适用于历史解释。",
                    "考察\(topic)，我看重机械因果关系的追溯。重大历史事件往往是无数微小决策与环境条件相互作用的结果，如同复杂力学系统。理解初始条件与作用力，有助于我们预测类似历史情景可能的演化路径。"
                ]
                return perspectives[Int.random(in: 0..<perspectives.count)]
                
            case "李白":
                let perspectives = [
                    "观\(topic)，如观大江东去，浪花淘尽英雄。历史长河奔流不息，而真正的精神却穿越时空，如明月照人间。所谓盛衰成败，不过是形式变幻，而人性本真、自由精神，才是历史长河中的明珠。",
                    "思\(topic)，我心游万仞。历史并非冷冰冰的记载，而是充满激情与梦想的人生画卷。英雄迹，古今同慨；盛衰理，豪气长存。读史使人明智，而忆史则应激发豪情，鼓舞人心向往那些光辉灿烂的瞬间。",
                    "品\(topic)，恰如饮陈年佳酿，愈久愈香。历史的魅力不在表面的波澜壮阔，而在千年沉淀后的清澈见底。细品古事，能见真性情，明大格局。'安能摧眉折腰事权贵，使我不得开心颜'，此乃读史明志之要义。"
                ]
                return perspectives[Int.random(in: 0..<perspectives.count)]
                
            default:
                return "关于\(topic)，这是一个值得深入探讨的历史课题。从不同角度审视这一事件，可以发现许多启示。"
            }
        }
            
        case 3: // 奇思妙想 - 历史名人的创意思考
            // 奇思妙想类型的帖子内容 - 强调创意与想象力
            let creativeContents = [
                "突发奇想，如果能发明一种思维传输装置，可以直接把想法发给别人，会不会彻底改变我们交流的方式？想想看，不用解释，不会误解，直接理解对方的想法。不过，如果所有人都能读取彼此的想法，我们还会保留那些独特的个性吗？有点复杂但很有趣的问题🤔",
                
                "今天看了场沉浸式话剧，突然想到：如果剧场能够实时显示观众的情绪波动，会不会让表演变得更有互动性？想象一下，演员表演时能看到观众的喜怒哀乐被投影在墙上，那种即时反馈可能会创造出前所未有的共情体验。艺术的终极目标不就是打破人与人之间的隔阂吗？",
                
                "我有个疯狂的点子💡一种能根据创作者情绪自动调整颜色和风格的智能画笔app。心情愉悦时自动切换明亮色调，悲伤时则是灰暗基调。想象一下，同一个场景，不同心情下可能创作出完全不同的作品。这会不会让数字艺术创作更接近我们的真实情感状态？",
                
                "刚才在地铁上突然想到：如果有一个'人生贡献值'实时记分APP会怎样？不是为了评判，而是帮助我们更清晰地看到自己对他人、对社会的实际价值。每次帮助他人、环保行为、创造性工作都会增加分数。这种自我反思的工具，会不会让我们更有意识地生活？",
                
                "做了个有趣的梦，梦见发明了一种时间观察器，可以去任何历史时刻，但只能观察不能干预。第一站我会去哪？可能是宇宙大爆炸那一刻，或者看看恐龙是怎么灭绝的，又或者去听听莫扎特现场演奏...太多可能性了！如果你有这样的机会，你最想去哪个时刻？"
            ]
            
            // 各历史人物的创意想法库 - 更具个性化
            let figurativeCreativeIdeas: [String: [String]] = [
                "爱因斯坦": [
                    "昨晚做了个奇怪的梦，梦见发明了一种\"思维曲率引擎\"——能让意识像光线一样穿越时空。醒来后还在思考这个设想：如果我们能体验不同时空的存在方式，感受宇宙诞生时的状态，或者进入量子世界，会不会彻底改变我们对意识和物质关系的理解？科幻电影都不敢这么拍吧🤯 #深夜脑洞 #思维实验",
                    
                    "今天在公园长椅上发呆，突然冒出个点子：如果能设计一种\"量子随机能源\"，利用微观世界的不确定性来产生能量，是不是可以创造某种意义上的\"永动机\"？物理学家朋友们别急着反驳，这只是个脑洞，但想象一下：利用我们无法预测的量子涨落来驱动机器，多有诗意啊！不过这种想法大概只能存在于我的笔记本里了😂 #物理脑洞 #能源革命"
                ],
                
                "莎士比亚": [
                    "最近逛书店时突发奇想：如果有一种特别的图书馆，不是按作者或主题排列书籍，而是按照它们能唤起的情感深度来分类，会怎么样？想找\"第一次失恋的痛苦\"或者\"意外成功的狂喜\"这种特定情感体验，系统会根据你的生活经历，推荐最能引起共鸣的作品。这可能是文学与灵魂的完美邂逅方式吧？#阅读新方式 #情感图书馆",
                    
                    "最近失眠多梦，想到一个有点疯狂的创意：如果有个\"人生剧本重写平台\"，让人们能安全地重演自己人生中的关键决定，看看不同选择会带来什么结果...这不是为了后悔，而是理解每个选择背后的真正动机。有时候我们纠结的不是结果，而是不知道自己真正想要什么。如果你可以虚拟体验三条完全不同的人生道路，你会选择重写哪个决定？#人生假设 #决策模拟"
                ],
                
                "达芬奇": [
                    "突发奇想：如果建筑材料能像生物一样自我调节和生长，会怎样？想象一下，房子能根据季节变化自动调整形态——夏天自动展开增加通风，冬天收缩保存热量，甚至能感知使用者习惯不断优化内部空间。今天看到蜂巢结构给了我灵感，大自然的设计真是无与伦比的工程杰作。#建筑革命 #仿生设计 #未来居住",
                    
                    "周末参观了一个沉浸式艺术展，回来后一直在想：如果有一种能同时刺激所有感官的创作媒介会怎样？不只是看到画面，还能闻到画中花朵的香气，听到流水声，感受阳光温度，甚至品尝到水果的味道...完整的感官体验可能会创造出一种全新的艺术形式。科技已经接近实现这一点了吧？#全感官艺术 #沉浸式体验"
                ],
                
                "孔子": [
                    "最近在设计一个社区互助APP的构想，核心理念是：每个人的行为都会对整体环境产生可见的影响。帮助他人、分享知识会让社区\"生态\"更繁荣；自私行为则会显示负面效果。通过可视化这种\"因果关系\"，或许能让人们更直观地理解\"己所不欲，勿施于人\"的道理。互联网时代需要这种能将抽象价值具体化的工具吧？#社区互助 #价值可视化",
                    
                    "今天和朋友讨论教育话题，萌生了一个\"角色互换学习平台\"的想法：让参与者体验不同社会角色的责任和视角。从家庭成员到社区公民，每个角色都有独特的义务和权利。通过亲身体验不同位置，可能会更深刻理解人与人之间的相互依存关系。理论学习很重要，但实践体验往往更能触动人心。#教育创新 #角色体验 #换位思考"
                ],
                
                "牛顿": [
                    "周末参观了科技展，回来后一直在想：如果能设计一种\"自然规律可视化装置\"会怎样？让抽象的物理定律变成直观的视觉体验——看到引力如何弯曲时空，观察光的波粒特性，感受热力学定律如何塑造时间方向。这不仅是酷炫的教育工具，也可能帮助我们发现科学中被忽视的联系。有时直觉和数学同样重要。#科学可视化 #物理体验",
                    
                    "昨晚熬夜看了金融市场数据，突然想到：如果能开发一种\"混沌预测引擎\"，在看似随机的系统中找到深层模式呢？虽然蝴蝶效应告诉我们精确预测是不可能的，但或许能找到宏观层面的概率趋势。这种技术理论上可应用于天气预报、生态变化，甚至社会趋势...当然，我知道这听起来很科幻，但思考的过程很有趣😊 #数据科学 #复杂系统 #预测技术"
                ],
                
                "李白": [
                    "昨晚小酌几杯后突发奇想：如果有款APP能捕捉微醺状态下的灵感和想法就好了！喝酒时总有些绝妙想法，但第二天全忘了😂 想象一下，它能记录那种思维跳跃和情绪流动，让你清醒后还能找回那种创作状态。说实话，我最好的几个创意都是在半醉时冒出来的，可惜大部分都随着宿醉一起消失了...#创意捕手 #灵感收集器",
                    
                    "今天被困在城市里，突然很想念山水。突发奇想：如果有个\"自然心境生成器\"，能让人随时置身于想象中的自然环境该多好。不是VR那种视觉模拟，而是能传递那种心灵感受——泰山之巅的壮阔、云海中的飘渺、月下湖面的宁静...有时候最治愈的不是风景本身，而是它带给我们的心境变化。现代人太需要这种精神出行了吧？#心灵旅行 #自然疗愈"
                ]
            ]
            
            // 添加更多复杂深入的创意想法
            let advancedCreativeIdeas = [
                "情感时间胶囊：一种能够完整捕捉特定时刻情感状态的装置。不仅记录事件本身，还保存当时的感受、思绪和身体反应。未来重新打开时，不是简单回忆，而是完全重现那一刻的情感体验。这将彻底改变人类对记忆的理解，让'活在当下'与'珍藏过去'不再矛盾。",
                
                "环境同步网络：一个由微型生物传感器组成的全球网络，能够实时监测和响应生态系统变化。每个节点既收集数据又能主动干预：清理微塑料、调节土壤酸碱度、传播特定植物种子。这个系统不是中央控制，而是像免疫系统一样分布式工作，让地球以自组织方式'自愈'。",
                
                "跨语言思维接口：不是简单翻译词语，而是直接传递概念和思想模式。使用者能够体验到不同语言中独特的思维方式——法语的优雅抽象、汉语的意象联想、纳瓦霍语的过程导向。这将创造一种前所未有的文化理解深度，远超传统翻译所能达到的境界。",
                
                "创伤修复剧场：一种通过故事和隐喻治愈心理创伤的沉浸式体验。参与者不是被动接受治疗，而是在精心设计的叙事中扮演主角，以象征性方式面对和转化内心伤痛。每个剧场根据参与者的个人历史定制，结合神经科学和叙事治疗原理，创造安全而有效的心理重建路径。",
                
                "社会协作算法：一种新型决策系统，能够调和看似对立的利益和价值观。不同于简单的多数决或精英决策，它能够寻找创造性的第三方案，满足各方核心需求。系统会识别出人们真正在意的核心关切（而非表面立场），然后生成多个解决方案，促进集体智慧的涌现而非零和博弈。"
            ]
            
            // 生成奇思妙想类型的帖子
            for i in 0..<5 {
                // 确保使用所有历史人物，保持多样性
                let authorIndex = i % historicalFigures.count
                let authorName = historicalFigures[authorIndex]
                let authorAvatar = avatarSymbols[authorIndex]
                
                // 决定使用哪种类型的创意内容
                let contentType = Double.random(in: 0...1)
                var content: String
                
                if contentType > 0.7 && i < advancedCreativeIdeas.count {
                    // 30%的几率使用高级通用创意
                    content = "我最近有一个创新构想：\n\n\(advancedCreativeIdeas[i])\n\n这个想法在我脑海中盘旋许久，我认为它有潜力改变我们对世界的理解和互动方式。以我的角度来看，创新必须服务于更深层次的人类需求，而不仅仅是技术本身。"
                } else if contentType > 0.3, let personalizedIdeas = figurativeCreativeIdeas[authorName], !personalizedIdeas.isEmpty {
                    // 40%的几率使用特定人物的个性化创意
                    content = personalizedIdeas[Int.random(in: 0..<personalizedIdeas.count)]
                } else {
                    // 30%的几率使用通用内容
                    content = creativeContents[i % creativeContents.count]
                }
                
                // 添加标题
                let titleKeywords = ["构想", "设计", "梦想", "发明", "创意", "奇思妙想", "突破性想法"]
                let creativeVerbs = ["创造", "设计", "构思", "幻想", "发明", "想象", "构建"]
                
                let keyword1 = titleKeywords.randomElement() ?? "构想"
                let verb = creativeVerbs.randomElement() ?? "创造"
                
                // 从内容中提取几个关键词作为标题
                let words = content.components(separatedBy: CharacterSet.whitespacesAndNewlines).filter { $0.count > 1 }
                let titleWord = words.count > 10 ? words[Int.random(in: 5..<min(15, words.count))] : "未来"
                
                // 生成标题
                let title = "【我的\(keyword1)】\(verb)一种\(titleWord)的新方式\n\n"
                content = title + content
                
                // 随机选择2-3位历史人物作为评论者
                var commenters = Set<Int>()
                let commentCount = Int.random(in: 2...3)
                while commenters.count < commentCount {
                    let commenterIndex = Int.random(in: 0..<historicalFigures.count)
                    if commenterIndex != authorIndex {
                        commenters.insert(commenterIndex)
                    }
                }
                
                // 生成评论
                var comments: [UserCommentModel] = []
                for commenterIndex in commenters {
                    let commenterName = historicalFigures[commenterIndex]
                    
                    // 使评论更具创造性和互动性
                    let comment = generateCreativeComment(
                        aboutContent: content,
                        fromFigure: commenterName,
                        toFigure: authorName
                    )
                    comments.append(comment)
                }
                
                // 创建帖子 - 以历史名人为作者，表达创意想法
                let post = UserPostModel(
                    username: authorName,
                    userAvatar: authorAvatar,
                    content: content,
                    images: [], // 不使用图片
                    datePosted: Date().addingTimeInterval(-Double.random(in: 0...28800)),
                    likes: Int.random(in: 20...100), // 创意内容通常会获得较多点赞
                    comments: comments,
                    isLikedByCurrentUser: false,
                    isBookmarkedByCurrentUser: false
                )
                
                generatedPosts.append(post)
            }
            
        // 添加生成创意评论的函数
        func generateCreativeComment(aboutContent content: String, fromFigure figure: String, toFigure recipient: String) -> UserCommentModel {
            // 提取内容关键信息，不使用引号框住
            let sentences = content.components(separatedBy: ["。", "！", "？", "\n"]).filter { !$0.isEmpty }
            let _firstSentence = sentences.first ?? ""
            let keywords = content.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
                    .filter { $0.count >= 2 && !["的", "了", "是", "在", "我", "有", "和", "就", "不", "人", "都"].contains($0) }
                    .prefix(5)
            
            var commentText = ""
            
            // 根据不同历史人物生成评论内容
            switch figure {
            case "爱因斯坦":
                if keywords.contains("创意") || keywords.contains("想法") || keywords.contains("创新") {
                    commentText = "你的创意思考很有启发性。创新往往来自于打破常规思维的束缚，就像我研究相对论时，必须抛开牛顿时空观的框架。科学和艺术的边界其实很模糊，都需要这种创造性的跳跃。"
                } else {
                    commentText = "这个构想很有想象力。我一直认为，想象力比知识更重要，因为知识是有限的，而想象力概括世界上的一切。你的想法展示了这种不受限制的思维方式，这正是创新的源泉。"
                }
                
            case "莎士比亚":
                if keywords.contains("故事") || keywords.contains("情感") || keywords.contains("人性") {
                    commentText = "你的构想充满了叙事的可能性。我看到了其中蕴含的戏剧性冲突和人性探索。创意的本质不在于奇特，而在于能否触动人心，而你的想法恰恰具备这种力量。"
                } else {
                    commentText = "这个想法让我看到了全新的故事可能。创作的魅力正在于此，通过想象力构建一个能引起共鸣的世界。你的构思中有着丰富的情感层次，这是任何伟大作品的核心。"
                }
                
            case "达芬奇":
                commentText = "从结构和功能的角度看，你的创意很有价值。我一直相信，最优美的设计往往同时满足实用性和美学需求。你的构想正体现了这种平衡，就像大自然的设计总是既高效又和谐。我很想为这个概念画几张草图，探索一下其中的可能性。"
                
            case "孔子":
                commentText = "此构想既有新意，又不失其本。创新固然可贵，但须植根于传统。如一棵大树，新枝新叶不断生长，却依赖深厚根基。你的想法富有创造性，若能与人伦道德相结合，定能开花结果，造福世人。"
                
            case "牛顿":
                commentText = "这个创意体现了系统性思维。我研究自然规律时发现，最基本的原理通常可以推导出丰富的现象。你的构想也有这种特质，从简单前提出发，却能产生复杂而有意义的结果。值得进一步推演和实证。"
                
            case "李白":
                commentText = "妙哉！你这番创意如清风明月般畅快！我看人生在世，最贵任真率性，而你的想法正有这种天马行空的魅力。正如我常醉酒赋诗，心中自有丘壑，你的构思也是心灵自由的表达。敢问世间几人有此胆识，敢想敢为！"
                
            default:
                commentText = "这个创意构想很有深度。这种跨越常规思维的能力正是创新的源泉。期待看到这个想法的进一步发展。"
            }
            
            // 添加自然的个性化细节（40%几率）
            if Double.random(in: 0...1) > 0.6 {
                let personalTouches = [
                    figure == "爱因斯坦" ? "这让我想起在专利局工作时的思考实验。" : "",
                    figure == "莎士比亚" ? "创作《暴风雨》时我也有类似的灵感闪现。" : "",
                    figure == "达芬奇" ? "我的笔记本上画满了这样的创意草图。" : "",
                    figure == "李白" ? "我也常在醉酒时有这样天马行空的想法。" : ""
                ].filter { !$0.isEmpty }
                
                if !personalTouches.isEmpty {
                    commentText += " " + personalTouches.randomElement()!
                }
            }
            
            // 自然结尾（30%几率）
            if Double.random(in: 0...1) > 0.7 {
                let endings = [
                    "期待看到这个想法的进一步发展。",
                    "这种创造性思维很珍贵。",
                    "很高兴能听到这样的创意分享。",
                    "这正是我们需要的思考方式。"
                ]
                
                commentText += " " + endings[Int.random(in: 0..<endings.count)]
            }
            
            // 将非可选类型转换为可选类型
            let characterIDValue: String? = figure.lowercased()
            
            let avatarSymbols = ["atom", "book.fill", "paintpalette.fill", "scroll.fill", "graduationcap.fill", "text.book.closed.fill"]
            let historicalFigures = ["爱因斯坦", "莎士比亚", "达芬奇", "孔子", "牛顿", "李白"]
            let avatarIndex = historicalFigures.firstIndex(of: figure) ?? 0
            let avatarSymbol = avatarSymbols[avatarIndex]
            
            return UserCommentModel(
                username: figure,
                userAvatar: avatarSymbol,
                content: commentText,
                datePosted: Date().addingTimeInterval(-Double.random(in: 0...3600)),
                likes: Int.random(in: 5...50),
                isVirtualCharacter: true,
                characterID: characterIDValue
            )
        }
            
        case 4: // 时空记事 - 历史人物记录历史事件
            // 时空记事类型的帖子内容 - 专业历史点评
            let historicalEvents = [
                "古埃及金字塔的建造过程中，究竟运用了怎样的建筑技术？这些巨大石块如何精确切割和搬运？许多细节至今仍是考古学的谜团。",
                "古希腊哲学与现代科学思维有何关联？苏格拉底的辩证法与现代科学方法论有惊人的相似之处，这表明人类理性思维的基本模式跨越时代而相通。",
                "中国造纸术的发明和传播改变了世界知识传播的方式。从蔡伦改进造纸术到技术传入欧洲，这一进程对人类文明的影响深远。",
                "文艺复兴时期的艺术革命源于什么？透视法的发明、人文主义思潮的兴起，以及对古典艺术的重新发现，共同塑造了这一辉煌时代。",
                "工业革命如何重塑人类社会？蒸汽机的发明只是表象，背后是科学、技术、经济和社会思想的全面变革，奠定了现代世界的基础。"
            ]
            
            // 扩展历史事件库 - 更深入的历史分析主题
            let expandedHistoricalEvents = [
                "丝绸之路不仅是商贸通道，更是文明交汇的见证。从汉代张骞出使西域到元代的'蒙古和平'，这条横贯欧亚的路线促进了科技、宗教和艺术的跨文化传播。",
                
                "文字的演化如何反映人类思维模式的变迁？从古埃及象形文字、苏美尔楔形文字到中国汉字，以及希腊字母的发明，各种书写系统背后蕴含着怎样的认知革命？",
                
                "大航海时代的科技创新与全球格局重组。15世纪的航海技术突破如何依赖于天文学、地图绘制和指南针技术的结合？航海探险如何重塑了欧洲人的世界观？",
                
                "巴比伦与古埃及的数学成就：零的概念与位值制的发明如何革命性地改变了计算方式？古埃及的几何学与工程实践之间有何关联？",
                
                "罗马法对现代法律体系的奠基作用。从十二铜表法到查士丁尼法典，罗马法如何逐步建立起系统的法律框架？罗马法中的哪些核心原则至今仍构成现代法治社会的基础？",
                
                "东亚古代科技成就的全球影响。中国古代'四大发明'之外，还有哪些重要技术创新影响了世界历史进程？如水利工程、冶金技术、天文测算方法等。",
                
                "疫病与人类历史的互动关系。从雅典瘟疫、黑死病到1918年流感大流行，重大传染病如何改变了人口结构、经济形态和政治格局？"
            ]
            
            // 特定历史人物的短篇历史解析 - 缩短版本
            let figureSpecificHistoricalAnalyses: [String: [(topic: String, analysis: String)]] = [
                "爱因斯坦": [
                    (
                        topic: "科学革命如何改变人类认知模式",
                        analysis: "从哥白尼到牛顿，再到量子力学，科学革命不只改变了我们的世界观，更重要的是改变了思考方式。\n\n我认为，真正的科学革命不在于回答问题，而在于提出前所未有的问题。相对论展示了时空的相互依存性，这种认知转变影响了哲学、艺术甚至政治。最令人惊叹的是，数学竟能如此精确地描述自然，这本身就是一个需要解释的奇迹。"
                    ),
                    (
                        topic: "原子能时代的意义",
                        analysis: "E=mc²揭示了能量与质量的等价性。这个简洁方程改变了历史，赋予我们前所未有的力量与责任。\n\n核能本身无善恶，关键在于应用。原子能时代提醒我们，科学与道德必须并行。科学家的责任不仅限于发现真理，还包括引导这些发现的应用方向。"
                    )
                ],
                "莎士比亚": [
                    (
                        topic: "伊丽莎白时代的戏剧",
                        analysis: "环球剧场是社会融合的奇迹 - 从贵族到普通人共享情感体验。\n\n我们创造的戏剧既借鉴古典传统，又不拘泥于规则。我特别关注语言力量和人性复杂性，将哲学问题转化为情感体验。戏剧呈现的不是过去事件，而是人类永恒处境：权力与道德、爱情与责任、个人与社会。这就是为何它们穿越时代仍能引起共鸣。"
                    ),
                    (
                        topic: "文艺复兴的人文思潮",
                        analysis: "文艺复兴根本性地改变了人类自我认知。中世纪将人视为上帝计划的一部分，人文主义则肯定了人的价值与尊严。\n\n印刷术普及加速了这一变革，使知识从精英走向大众。在我的创作中，人性的复杂性始终是核心：奥赛罗的嫉妒、麦克白的野心、李尔的傲慢，无不展现情感的全谱系。"
                    )
                ],
                "牛顿": [
                    (
                        topic: "数学在自然科学中的核心地位",
                        analysis: "我坚信，自然的语言是数学。\n\n从开普勒的行星轨道到我的运动定律，数学使我们能超越模糊的定性观察，建立精确的定量理解。数学在科学中不仅是计算工具，更能指引新发现。\n\n为何数学能如此完美地描述物理世界？是因为数学源于对物理世界的抽象？还是因为宇宙本身具有数学结构？这个问题本身就足够引人深思。"
                    )
                ]
            ]

            // 简短历史事件分析函数
            func generateBriefHistoricalAnalysis(onEvent event: String, byFigure figure: String) -> String {
                // 根据不同历史人物的专业领域，生成简短的历史事件分析
                switch figure {
                case "爱因斯坦":
                    let analyses = [
                        "从科学史视角看，这一现象反映了认知模式的演变。类似于光速不变原理，历史上的重大发现往往源于对已有框架的突破。科学进步从不是线性的。",
                        "观察者视角至关重要。正如相对论所示，没有绝对参照系，历史事件的意义取决于解释框架。这不是相对主义，而是理解复杂系统的必要方法。",
                        "技术突破往往是渐进积累与突然顿悟的结合，就像量子跃迁。历史表面的连续性下，隐藏着无数微观的不连续变化。"
                    ]
                    return analyses[Int.random(in: 0..<analyses.count)]
                    
                case "莎士比亚":
                    let analyses = [
                        "我看到的是人性永恒主题在历史舞台上的展演。如同悲剧探索野心与命运的冲突，这段历史展示了个体欲望与集体命运的复杂交织。",
                        "这段历史有完美的戏剧结构：开端、发展、高潮与结局。每个参与者都扮演着自己的角色，却往往不自知。'全世界是一个舞台，所有人不过是演员。'",
                        "历史人物的复杂性令人着迷。如我笔下角色既非全善亦非全恶，历史人物也充满矛盾。判断历史不应简单二分，而应理解每个决定背后的复杂情感。"
                    ]
                    return analyses[Int.random(in: 0..<analyses.count)]
                    
                case "达芬奇":
                    let analyses = [
                        "我分析历史时关注结构与功能的统一。正如解剖人体理解生命，历史事件也应通过内部机制与外部表现的关系来理解。",
                        "历史中的技术突破往往同时具有实用价值与形式美感，反映了对和谐与比例的追求。'形式服从功能'的原则贯穿人类文明。",
                        "每个历史成就背后都有精确计算与精湛工艺。通过草图与模型，我能重构当时的技术思路。历史是智慧与创造力的档案库。"
                    ]
                    return analyses[Int.random(in: 0..<analyses.count)]
                    
                case "孔子":
                    let analyses = [
                        "论史当思其对人伦之影响。历史变迁，表在事件，实则人心。观史如照镜，见古人得失，思今日取舍。'温故而知新，可以为师矣。'历史之价值，不在故纸堆中，而在对当世之启迪。",
                        "览史见治道之变。天下大事，必作于细。国之兴衰，系于礼义廉耻之存亡。历史潮流看似不可抗，然一国之运，实决于人才之盛衰、制度之良莠。'德不孤，必有邻。'善政之道，古今一理。",
                        "究史当思'修身齐家治国平天下'之道。历史兴替，非偶然，实乃人事。圣人观史，不徒记事，而重明理。'己所不欲，勿施于人'，此乃古今社会之公理。欲知兴亡之本，当自人心革新始。"
                    ]
                    return analyses[Int.random(in: 0..<analyses.count)]
                    
                case "牛顿":
                    let analyses = [
                        "历史变革如同物理系统，遵循基本定律——每个行动都有反作用力，社会力量的平衡与转移遵循类似守恒原理的模式。",
                        "历史研究如同科学实验，需要严谨方法论。通过收集一手史料，排除干扰因素，我们可以更接近历史真相。",
                        "重大历史事件往往是无数微小决策与环境条件相互作用的结果，如同复杂力学系统。理解初始条件与作用力，有助于预测可能的演化路径。"
                    ]
                    return analyses[Int.random(in: 0..<analyses.count)]
                    
                case "李白":
                    let analyses = [
                        "观历史如观大江东去，浪花淘尽英雄。历史长河奔流不息，而真正的精神却穿越时空，如明月照人间。所谓盛衰成败，不过是形式变幻。",
                        "历史非冷冰冰的记载，而是充满激情与梦想的人生画卷。英雄迹，古今同慨；盛衰理，豪气长存。",
                        "品历史如饮陈年佳酿，愈久愈香。历史魅力不在表面波澜，而在千年沉淀后的清澈。细品古事，能见真性情，明大格局。"
                    ]
                    return analyses[Int.random(in: 0..<analyses.count)]
                    
                default:
                    return "这个历史话题值得深入探讨。从不同角度看，能发现许多启示。"
                }
            }
            
            // 多样化的标题格式
            let titleFormats = [
                { (topic: String) -> String in "历史角度看：\(topic)" },
                { (topic: String) -> String in "\(topic)：一些个人想法" },
                { (topic: String) -> String in "关于\(topic)的随想" },
                { (topic: String) -> String in "\(topic)的思考" },
                { (topic: String) -> String in "\(topic) | 历史视角" },
                { (topic: String) -> String in "解密：\(topic)" },
                { (topic: String) -> String in "时空对话：\(topic)" },
                { (topic: String) -> String in "我对\(topic)的一点思考" }
            ]
            
            // 生成时空记事类型的帖子
            for i in 0..<5 {
                // 确保使用所有历史人物，保持多样性
                let authorIndex = i % historicalFigures.count
                let authorName = historicalFigures[authorIndex]
                let authorAvatar = avatarSymbols[authorIndex]
                
                // 决定使用哪种类型的内容和格式
                var eventContent: String
                var content: String
                let titleFormat = titleFormats[Int.random(in: 0..<titleFormats.count)]
                
                // 1. 优先使用特定人物的深度历史解析
                if let specificAnalyses = figureSpecificHistoricalAnalyses[authorName], !specificAnalyses.isEmpty && Double.random(in: 0...1) > 0.4 {
                    // 60%的几率使用预设的特定人物历史解析
                    let selectedAnalysis = specificAnalyses.randomElement()!
                    eventContent = selectedAnalysis.topic
                    
                    // 使用多样化标题格式
                    content = titleFormat(selectedAnalysis.topic) + "\n\n" + selectedAnalysis.analysis
                } else {
                    // 2. 其次使用随机历史事件并生成简短分析
                    // 随机决定用基本事件还是扩展事件
                    let eventsPool = Double.random(in: 0...1) > 0.5 ? expandedHistoricalEvents : historicalEvents
                    eventContent = eventsPool[i % eventsPool.count]
                    
                    // 截短事件描述，保留主要内容
                    let shortEvent = eventContent.split(separator: "。").first?.description ?? eventContent
                    
                    // 从事件中提取关键词作为标题
                    let words = shortEvent.components(separatedBy: CharacterSet.punctuationCharacters).filter { $0.count > 2 }
                    let keyWords = words.count > 5 ? [words[1], words[3]] : ["历史", "事件"]
                    let titleTopic = keyWords.joined(separator: "与")
                    
                    // 使用多样化标题格式
                    let title = titleFormat(titleTopic)
                    
                    // 随机决定内容格式
                    let formatChoice = Int.random(in: 0...3)
                    
                    switch formatChoice {
                    case 0:
                        // 格式1：问题引导型
                        content = "\(title)\n\n\(shortEvent)？\n\n我的观点：\n" + generateBriefHistoricalAnalysis(onEvent: eventContent, byFigure: authorName)
                    case 1:
                        // 格式2：直接论述型
                        content = "\(title)\n\n" + generateBriefHistoricalAnalysis(onEvent: eventContent, byFigure: authorName) + "\n\n这让我想到\(shortEvent)"
                    case 2:
                        // 格式3：引述型
                        content = "\(title)\n\n据史料记载：\"\(shortEvent)\"\n\n个人见解：\n" + generateBriefHistoricalAnalysis(onEvent: eventContent, byFigure: authorName)
                    default:
                        // 格式4：对比分析型
                        content = "\(title)\n\n古人云：\(shortEvent)\n\n今日看来：\n" + generateBriefHistoricalAnalysis(onEvent: eventContent, byFigure: authorName)
                    }
                }
                
                // 选择1-2位其他历史人物进行评论
                var commenters = Set<Int>()
                let commentCount = Int.random(in: 1...2) // 减少评论数量
                while commenters.count < commentCount {
                    let commenterIndex = Int.random(in: 0..<historicalFigures.count)
                    if commenterIndex != authorIndex {
                        commenters.insert(commenterIndex)
                    }
                }
                
                // 生成评论 - 历史人物间的专业讨论
                var comments: [UserCommentModel] = []
                for commenterIndex in commenters {
                    let commenterName = historicalFigures[commenterIndex]
                    
                    // 生成专业性更强的评论
                    let comment = generateHistoricalComment(
                        aboutContent: content,
                        fromFigure: commenterName,
                        aboutFigure: authorName
                    )
                    comments.append(comment)
                }
                
                // 创建帖子 - 以历史名人为作者，分析历史事件
                let post = UserPostModel(
                    username: authorName,
                    userAvatar: authorAvatar,
                    content: content,
                    images: [], // 不使用图片
                    datePosted: Date().addingTimeInterval(-Double.random(in: 0...43200)),
                    likes: Int.random(in: 15...90),
                    comments: comments,
                    isLikedByCurrentUser: false,
                    isBookmarkedByCurrentUser: false
                )
                
                generatedPosts.append(post)
            }
            
        // 为历史主题选择最合适的历史人物
        func selectOptimalFigureForHistoricalTopic(_ topic: String) -> String {
            // 定义关键词与历史人物的关联
            let topicKeywords: [String: [String]] = [
                "爱因斯坦": ["物理", "相对论", "量子", "能量", "宇宙", "科学革命", "光", "时空"],
                "莎士比亚": ["文学", "戏剧", "诗歌", "文艺复兴", "人性", "悲剧", "喜剧", "艺术革命"],
                "达芬奇": ["艺术", "解剖", "工程", "建筑", "绘画", "设计", "透视", "文艺复兴"],
                "孔子": ["哲学", "伦理", "教育", "儒家", "道德", "政治", "社会秩序", "中国"],
                "牛顿": ["物理", "数学", "引力", "光学", "运动", "力学", "科学革命", "计算"],
                "李白": ["诗歌", "唐朝", "文学", "艺术", "酒", "自然", "山水", "中国"]
            ]
            
            // 计算每位历史人物与主题的相关度
            var relevanceScores: [String: Int] = [:]
            
            for (figure, keywords) in topicKeywords {
                var score = 0
                for keyword in keywords {
                    if topic.lowercased().contains(keyword.lowercased()) {
                        score += 2
                    }
                }
                
                // 根据人物领域特性加权
                switch figure {
                case "爱因斯坦":
                    if topic.lowercased().contains("物理") || topic.lowercased().contains("科学") {
                        score += 3
                    }
                case "达芬奇":
                    if topic.lowercased().contains("艺术") || topic.lowercased().contains("工程") {
                        score += 3
                    }
                case "孔子":
                    if topic.lowercased().contains("哲学") || topic.lowercased().contains("伦理") {
                        score += 3
                    }
                case "牛顿":
                    if topic.lowercased().contains("数学") || topic.lowercased().contains("物理") {
                        score += 3
                    }
                default:
                    break
                }
                
                relevanceScores[figure] = score
            }
            
            // 找出得分最高的历史人物
            if let bestMatch = relevanceScores.max(by: { $0.value < $1.value }) {
                // 如果最高分大于0，返回对应的历史人物
                if bestMatch.value > 0 {
                    return bestMatch.key
                }
            }
            
            // 如果没有明显匹配，随机选择一位历史人物
            return historicalFigures[Int.random(in: 0..<historicalFigures.count)]
        }
        
        // 生成历史事件分析
        func generateHistoricalAnalysis(onEvent event: String, byFigure figure: String) -> String {
            // 根据不同历史人物的专业领域，生成对历史事件的专业分析
            switch figure {
            case "爱因斯坦":
                let analyses = [
                    "从科学史角度看，\(event) 这一现象反映了人类认知模式的演变。类似于我对光速不变原理的思考，历史上的重大发现往往源于对既有框架的突破。科学进步从来不是线性的，而是通过范式转移实现的跃迁。",
                    "分析\(event)，我想强调观察者视角的重要性。正如相对论所示，没有绝对的参照系，历史事件的意义取决于我们如何建立解释框架。这不是相对主义，而是理解复杂系统的必要方法。",
                    "研究\(event)，让我想到科学创新与社会变革的关系。技术突破往往是渐进积累与突然顿悟的结合，就像量子跃迁。历史的连续性表面下，蕴含着无数微观的不连续变化。"
                ]
                return analyses[Int.random(in: 0..<analyses.count)]
                
            case "莎士比亚":
                let analyses = [
                    "纵观\(event)，我看到的是人性的永恒主题在历史舞台上的展演。如同我的悲剧作品探索人类野心与命运的冲突，这段历史也展示了个体欲望与集体命运的复杂交织。正如哈姆雷特所言，'世界上有千百万事物，是你们哲学里所没有梦想到的。'",
                    "解读\(event)，我欣赏其中的戏剧性结构：开端、发展、高潮与结局，仿佛一部精心编排的历史剧。每个参与者都扮演着自己的角色，却往往不自知。'全世界是一个舞台，所有的男男女女不过是演员。'这历史瞬间，印证了人生如戏的永恒真理。",
                    "品析\(event)，我被其中人物的复杂性所打动。正如我笔下的角色既非全善亦非全恶，历史人物也充满矛盾与挣扎。这提醒我们，判断历史不应简单二分，而应理解每个决定背后的复杂情感与处境。历史如同多声部的合唱，每个声音都值得被倾听。"
                ]
                return analyses[Int.random(in: 0..<analyses.count)]
                
            case "达芬奇":
                let analyses = [
                    "观察\(event)，我从结构与功能的统一性出发进行分析。正如我研究人体解剖以理解生命运作原理，历史事件也应通过其内部机制与外部表现的关系来理解。技术创新往往源于对自然规律的精确观察与模仿，而非凭空想象。",
                    "研究\(event)，我注意到艺术与科学的融合点。美学与功能性并非对立，而是相辅相成的。历史发展中的技术突破往往同时具有实用价值与形式美感，反映了设计者对和谐与比例的追求。这种'形式服从功能'的原则贯穿人类文明史。",
                    "分析\(event)，我特别关注其中的工程学原理。每个重大历史成就背后都有精确的计算与精湛的工艺。通过草图与模型，我可以重构当时的技术思路。历史并非仅是事件记录，更是智慧与创造力的档案库，值得现代人反复学习与借鉴。"
                ]
                return analyses[Int.random(in: 0..<analyses.count)]
                
            case "孔子":
                let analyses = [
                    "论\(event)，当思其对人伦之影响。盖历史变迁，表在事件，实则人心。故观史当如照镜，见古人得失，思今日取舍。'温故而知新，可以为师矣。'历史之价值，不在故纸堆中，而在对当世之启迪。",
                    "览\(event)，吾见治道之变。天下大事，必作于细。国之兴衰，系于礼义廉耻之存亡。历史潮流看似不可抗，然一国之运，实决于人才之盛衰、制度之良莠。'德不孤，必有邻。'善政之道，古今一理。",
                    "究\(event)，当思'修身齐家治国平天下'之道。历史兴替，非偶然，实乃人事。圣人观史，不徒记事，而重明理。'己所不欲，勿施于人'，此乃古今社会之公理。欲知兴亡之本，当自人心革新始。"
                ]
                return analyses[Int.random(in: 0..<analyses.count)]
                
            case "牛顿":
                let analyses = [
                    "分析\(event)，我发现其中蕴含的规律性。历史变革如同物理系统，遵循某些基本定律——每个行动都有反作用力，社会力量的平衡与转移遵循类似守恒原理的模式。通过数学建模，或许能揭示历史发展的内在逻辑。",
                    "研究\(event)，我注重实证与逻辑推理。历史研究如同科学实验，需要严谨的方法论。通过收集一手史料，排除干扰因素，我们可以更接近历史真相。'自然哲学的规则是，承认为真的原因不应超出足以解释现象所需的数量。'这同样适用于历史解释。",
                    "考察\(event)，我看重机械因果关系的追溯。重大历史事件往往是无数微小决策与环境条件相互作用的结果，如同复杂力学系统。理解初始条件与作用力，有助于我们预测类似历史情景可能的演化路径。"
                ]
                return analyses[Int.random(in: 0..<analyses.count)]
                
            case "李白":
                let analyses = [
                    "观\(event)，如观大江东去，浪花淘尽英雄。历史长河奔流不息，而真正的精神却穿越时空，如明月照人间。所谓盛衰成败，不过是形式变幻，而人性本真、自由精神，才是历史长河中的明珠。",
                    "思\(event)，我心游万仞。历史并非冷冰冰的记载，而是充满激情与梦想的人生画卷。英雄迹，古今同慨；盛衰理，豪气长存。读史使人明智，而忆史则应激发豪情，鼓舞人心向往那些光辉灿烂的瞬间。",
                    "品\(event)，恰如饮陈年佳酿，愈久愈香。历史的魅力不在表面的波澜壮阔，而在千年沉淀后的清澈见底。细品古事，能见真性情，明大格局。'安能摧眉折腰事权贵，使我不得开心颜'，此乃读史明志之要义。"
                ]
                return analyses[Int.random(in: 0..<analyses.count)]
                
            default:
                return "关于\(event)，这是一个值得深入探讨的历史课题。从不同角度审视这一事件，可以发现许多启示。"
            }
        }
            
        default:
            // 默认情况下返回空数组
            return []
        }
        
        print("✅ 已根据创作类型「\(typeName)」生成 \(generatedPosts.count) 个帖子")
        
        // 确保所有帖子都有评论
        for (index, post) in generatedPosts.enumerated() {
            if post.comments.isEmpty {
                print("⚠️ 警告：发现没有评论的帖子，为其添加默认评论")
                
                // 选择一位不同于帖子作者的历史人物作为评论者
                let authorName = post.username
                var commenterName = historicalFigures[Int.random(in: 0..<historicalFigures.count)]
                while commenterName == authorName {
                    commenterName = historicalFigures[Int.random(in: 0..<historicalFigures.count)]
                }
                
                // 生成一条评论
                let defaultComment = generateHistoricalComment(aboutContent: post.content, fromFigure: commenterName)
                
                // 为帖子添加评论
                generatedPosts[index].comments = [defaultComment]
                print("✅ 已为帖子 #\(index) 添加默认评论")
            }
        }
        
        return generatedPosts
    }
    
    /// 添加一组帖子到列表前端
    /// - Parameter newPosts: 要添加的帖子数组
    func addPosts(_ newPosts: [UserPostModel]) {
        // 记录添加前的帖子数量
        let oldCount = posts.count
        print("📊 PostViewModel: 添加前帖子数量 = \(oldCount)")
        
        // 避免添加空数组
        if newPosts.isEmpty {
            print("⚠️ PostViewModel: 试图添加空数组，操作取消")
            return
        }
        
        // 先触发objectWillChange，确保订阅者知道数据将要变化
        DispatchQueue.main.async {
            self.objectWillChange.send()
            print("📊 PostViewModel: 发送pre-update objectWillChange通知")
        }
        
        // 检查是否有重复ID的帖子，避免添加重复内容
        var uniquePosts = [UserPostModel]()
        var existingIds = Set<UUID>(posts.map { $0.id })
        
        for post in newPosts {
            if !existingIds.contains(post.id) {
                uniquePosts.append(post)
                existingIds.insert(post.id)
            } else {
                print("⚠️ PostViewModel: 发现重复帖子ID: \(post.id)，已跳过")
            }
        }
        
        if uniquePosts.isEmpty {
            print("⚠️ PostViewModel: 所有新帖子都是重复的，未添加任何内容")
            return
        }
        
        // 将新帖子添加到列表前面
        posts.insert(contentsOf: uniquePosts, at: 0)
        
        // 验证添加是否成功
        let newCount = posts.count
        let addedCount = uniquePosts.count
        print("📊 PostViewModel: 添加后帖子数量 = \(newCount)，应增加 \(addedCount)，实际增加 \(newCount - oldCount)")
        
        // 检查第一篇帖子是否就是新添加的第一篇
        if let firstNewPost = uniquePosts.first, let firstPost = posts.first {
            let isFirstPostMatch = firstNewPost.id == firstPost.id
            print("📊 PostViewModel: 第一篇帖子ID匹配检查 = \(isFirstPostMatch ? "✅成功" : "❌失败")")
            print("📊 PostViewModel: 第一篇新帖子内容片段: \(firstNewPost.content.prefix(30))...")
        }
        
        // 立即发送通知，通知订阅者帖子列表已更新
        let userInfo: [String: Any] = [
            "newPostsCount": uniquePosts.count,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // 主线程发送通知和objectWillChange事件
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 强制触发变更通知，确保UI更新 - 第一次立即触发
            self.objectWillChange.send()
            
            // 发送PostsUpdated通知
            NotificationCenter.default.post(
                name: NSNotification.Name("PostsUpdated"),
                object: self,  // 使用self作为object便于识别通知来源
                userInfo: userInfo
            )
            
            // 额外发送NewPostsGenerated通知，增加冗余保障
            NotificationCenter.default.post(
                name: NSNotification.Name("NewPostsGenerated"),
                object: self,
                userInfo: [
                    "count": uniquePosts.count,
                    "timestamp": Date().timeIntervalSince1970
                ]
            )
            
            print("📱 PostViewModel: 已发送PostsUpdated和NewPostsGenerated通知，添加了 \(uniquePosts.count) 个新帖子，当前总数: \(self.posts.count)")
            
            // 增加延迟再次触发，确保所有UI组件都能正确处理变更
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self = self else { return }
                self.objectWillChange.send()
                print("📱 PostViewModel: 延迟0.2秒后再次触发objectWillChange以确保UI刷新")
                
                // 延迟发送第二次通知
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self = self else { return }
                    
                    // 第二次发送通知，确保接收者能收到
                    NotificationCenter.default.post(
                        name: NSNotification.Name("PostsUpdated"),
                        object: self,
                        userInfo: userInfo
                    )
                    
                    print("📱 PostViewModel: 延迟0.3秒后发送第二次PostsUpdated通知")
                }
            }
        }
    }
    
    /**
     * 生成虫洞共鸣帖子
     * @param situation 用户当前情境：寻找答案/做决定/需要灵感/思考人生
     * @param expectation 用户期望：被看见/新视角/实用建议/共鸣与安慰
     * @param keyword 可选关键词
     * @return 生成的帖子数组
     */
    func generateResonancePosts(
        situation: String = "寻找答案",
        expectation: String = "新视角",
        keyword: String? = nil
    ) -> [UserPostModel] {
        print("🌀 生成虫洞共鸣帖子 - 情境: \(situation), 期望: \(expectation), 关键词: \(keyword ?? "无")")
        
        // 使用优化后的虫洞共鸣内容生成器
        let resonanceGenerator = ResonanceContentGenerator.shared
        let resonancePosts = resonanceGenerator.generateResonancePosts(
            situation: situation,
            expectation: expectation,
            keyword: keyword,
            count: 5 // 生成5篇帖子
        )
        
        // 将 ResonanceContentGenerator.Post 转换为 UserPostModel
        var userPosts: [UserPostModel] = []
        
        for post in resonancePosts {
            // 为每篇帖子生成2-3条评论
            let commentCount = Int.random(in: 2...3)
            var userComments: [UserCommentModel] = []
            
            // 历史人物列表
            let historicalFigures = ["爱因斯坦", "莎士比亚", "达芬奇", "孔子", "牛顿", "李白"]
            let avatarSymbols = ["atom", "book.fill", "paintpalette.fill", "scroll.fill", "graduationcap.fill", "text.book.closed.fill"]
            
            // 选择评论者 - 确保不重复
            var selectedCommenters = Set<String>()
            while selectedCommenters.count < commentCount {
                let commenter = historicalFigures.randomElement()!
                if commenter != post.author { // 避免自己评论自己
                    selectedCommenters.insert(commenter)
                }
            }
            
            // 为每个评论者生成评论
            for commenter in selectedCommenters {
                let commenterIndex = historicalFigures.firstIndex(of: commenter)!
                let comment = generateHistoricalComment(
                    aboutContent: post.content,
                    fromFigure: commenter,
                    aboutFigure: post.author
                )
                userComments.append(comment)
            }
            
            // 创建用户帖子模型
            let userPost = UserPostModel(
                id: UUID(),
                username: post.author,
                userAvatar: post.authorAvatar,
                content: post.content,
                images: [], // 虫洞共鸣不使用图片
                datePosted: post.timestamp,
                likes: Int.random(in: 10...50),
                comments: userComments,
                isLikedByCurrentUser: false,
                isBookmarkedByCurrentUser: false
            )
            
            userPosts.append(userPost)
            print("📱 成功生成虫洞共鸣帖子: \(userPost.id), 作者: \(userPost.username)")
        }
        
        // 如果没有成功生成帖子，使用备用方案
        if userPosts.isEmpty {
            print("⚠️ 警告：ResonanceContentGenerator未能生成帖子，使用备用生成方法")
            
            // 使用原有的内容生成逻辑作为备用
            let resonanceContents = generateContentForSituation(situation, expectation: expectation, keyword: keyword)
            
            // 历史名人列表 - 供所有创作类型使用，按照特性匹配头像
            let historicalFigures = ["爱因斯坦", "莎士比亚", "达芬奇", "孔子", "牛顿", "李白"]
            let avatarSymbols = ["atom", "book.fill", "paintpalette.fill", "scroll.fill", "graduationcap.fill", "text.book.closed.fill"]
            
            // 生成虫洞共鸣类型的帖子
            for i in 0..<5 {
                // 选择最适合当前情境和期望的历史人物作为帖子作者
                let authorIndex = selectOptimalFigureForSituation(situation, expectation: expectation)
                let authorName = historicalFigures[authorIndex]
                let authorAvatar = avatarSymbols[authorIndex]
                
                // 从内容池中选择内容
                let content = resonanceContents[i % resonanceContents.count]
                
                // 随机选择2-3位历史名人作为评论者，选择与当前情境和期望最匹配的人物
                var commenters = Set<Int>()
                let commentCount = Int.random(in: 2...3)
                
                // 确保评论者不重复且不是作者
                while commenters.count < commentCount {
                    let commenterIndex = selectOptimalFigureForSituation(
                        expectation,
                        expectation: situation,
                        exclude: [authorIndex] + Array(commenters)
                    )
                    commenters.insert(commenterIndex)
                }
                
                // 生成评论
                var comments: [UserCommentModel] = []
                for commenterIndex in commenters {
                    let commenterName = historicalFigures[commenterIndex]
                    let comment = generateHistoricalComment(
                        aboutContent: content,
                        fromFigure: commenterName,
                        aboutFigure: authorName
                    )
                    comments.append(comment)
                }
                
                // 创建帖子 - 以历史名人为作者
                let post = UserPostModel(
                    username: authorName,
                    userAvatar: authorAvatar,
                    content: content,
                    images: [], // 不使用图片
                    datePosted: Date(),
                    likes: Int.random(in: 10...50),
                    comments: comments,
                    isLikedByCurrentUser: false,
                    isBookmarkedByCurrentUser: false
                )
                
                userPosts.append(post)
            }
        }
        
        return userPosts
    }
    
    /**
     * 为特定情境和期望组合生成内容
     */
    private func generateContentForSituation(_ situation: String, expectation: String, keyword: String? = nil) -> [String] {
        // 基础内容池
        var contentPool: [String] = []
        
        // 根据不同组合生成合适的内容
        switch (situation, expectation) {
        case ("寻找答案", "被看见"):
            contentPool = [
                "我理解你正在寻找人生问题的答案，这种探索本身就值得被看见和尊重。在我的时代，我也曾面对无数疑问，那种渴望真理的心情，跨越时空依然相通。请记住，提出一个好问题往往比得到答案更重要，因为它展示了你思考的深度和勇气。",
                
                "当你站在人生的十字路口寻找方向时，最需要的或许不是立刻找到答案，而是有人真正看见你的困惑和努力。我在研究宇宙奥秘时，常常在黑暗中摸索多年才看到一丝光明。这个过程虽然孤独，但正是这种执着的探索定义了我们是谁。",
                
                "在寻找答案的旅程中，你首先需要的是被理解、被看见。我毕生致力于解开自然之谜，深知这条路上的孤独与迷茫。但请相信，你的探索本身就是一种勇气的表现，值得被尊重。有时候，与其急于寻找确定的答案，不如享受探索的过程，因为智慧往往在旅途中不期而遇。"
            ]
            
        case ("寻找答案", "新视角"):
            contentPool = [
                "寻找答案时，改变视角往往比累积更多信息更有价值。就像我发现相对论时，不是通过新实验，而是重新思考已知现象。试着问：如果我完全颠覆当前假设会怎样？如果这个问题的前提本身就是错的呢？最伟大的发现常常源于敢于质疑基本假设的勇气。",
                
                "当你苦苦寻找问题的答案却毫无进展时，不妨尝试彻底改变思考角度。我创作《哈姆雷特》时，不是简单讲述复仇故事，而是通过主角的犹豫不决探索人性本质。有时候，答案不在问题的延长线上，而是需要你跳出固有框架，从全新维度审视问题。",
                
                "在探寻真理的道路上，最珍贵的能力是能够从不同角度观察同一问题。我研究人体解剖学时，既从医学角度，也从艺术视角进行观察，因此发现了前人未见的联系。当你感到困惑时，不妨尝试：如果一个完全不同领域的专家面对这个问题，他们会如何思考？这种跨界思维常能带来突破性洞见。"
            ]
            
        case ("做决定", "实用建议"):
            contentPool = [
                "决策之道，在于权衡利弊，而非追求完美。我教导学生时常言：'过犹不及'。面对抉择，先列出各选项之利弊，思考最坏结果能否承受，再定取舍。切记，决策贵在果断，犹豫不决往往比错误选择更有害。做决定后，全力以赴，不留遗憾。",
                
                "做决定时，我发现一个实用方法：将问题分解为更小的部分。就像我研究光学时，不是直接解决复杂现象，而是逐一分析基本原理。大决定令人畏惧，但拆分后的小决定则容易处理。另外，计算'不作为的代价'往往比评估'行动的风险'更能激发明智决策。",
                
                "在戏剧创作中，我发现决策的关键在于理解角色的核心动机。面对人生抉择，也请先扪心自问：'我真正在乎的是什么？'许多纠结源于我们试图同时满足内心矛盾的愿望。一旦明确优先级，决策自然清晰。记住，没有完美选择，只有适合当下的决定，然后全情投入，创造最佳结果。"
            ]
            
        case ("需要灵感", "共鸣与安慰"):
            contentPool = [
                "创作的低谷期，我深知那种灵感枯竭的痛苦。'抽刀断水水更流，举杯消愁愁更愁'，我曾在诗中写下这种无力感。但请记住，灵感如月，有盈有亏；才思如潮，有涨有落。当你感到空虚时，不妨放下执念，到山水间漫步，与自然对话。我最好的诗作，常在不经意的瞬间，如清泉般涌现。",
                
                "每位创作者都熟悉那种渴望灵感却不得的煎熬，我也不例外。创作《罗密欧与朱丽叶》时，曾数周写不出满意的台词。这并非你的失败，而是创作过程的自然节律。灵感不是召之即来的仆人，而是需要耐心等待的朋友。在等待期，阅读、观察、生活，为心灵积累养分，灵感终会在不经意间敲响你的门。",
                
                "当灵感之泉干涸时，我理解那种孤独与挫折。我研究飞行器设计时，也曾面对无数失败，图纸堆积如山却毫无进展。创造的道路从来不是直线，而是充满曲折的探索。请温柔对待自己的创作节奏，有时最好的灵感来源于允许自己暂时放手，去生活，去感受，去积累。创意不是强求的成果，而是准备好的心灵与机遇相遇的火花。"
            ]
            
        case ("思考人生", "新视角"):
            contentPool = [
                "思考人生意义时，我发现最有启发的视角是将自己置于宇宙尺度。从相对论的角度看，时间不是绝对的，我们的一生在宇宙长河中只是转瞬即逝的火花。这不是要贬低人生，而是提醒我们：意义不在长度而在深度，不在永恒而在当下的体验质量。如果能在有限时空中创造无限价值，这才是真正的奇迹。",
                
                "人生如戏，而我们既是演员又是观众。当困惑于人生意义时，不妨尝试'第三幕思维'：想象自己已完成人生旅程，回顾时最珍视什么？最遗憾什么？这种未来回溯的视角常能揭示当下决策的真正价值。记住，人生不是单一故事，而是多幕剧，每个阶段都可以重新定义角色，改变剧情走向。",
                
                "思考人生时，我常用'透视法'：不仅看表象，更要看内在结构。就像我研究人体解剖一样，表面的美丽之下是精妙的骨骼和肌肉系统。人生也是如此，表面的成就之下，真正支撑我们的是内在价值观和关系网络。当你感到迷失，试着画出你人生的'解剖图'：哪些是表层装饰，哪些是核心支柱？这种区分常能带来全新视角。"
            ]
            
        default:
            // 默认内容池 - 通用的虫洞共鸣内容
            contentPool = [
                "在时空的交汇处，我们的思想跨越了几个世纪的距离而相遇。虽然生活在不同的时代，但人类的基本追求和困惑却惊人地相似。你所面对的挑战，在形式上或许与我的时代不同，但本质上却是相通的。这种跨越时空的共鸣，正是人类经验最珍贵的部分。",
                
                "如果能与你进行一次真正的对话，我想分享的不仅是知识，更是对生活的态度。在我的时代，我也曾面对选择、怀疑和挫折，也曾寻找意义和方向。时代变迁，但人心不变。或许我的经历，尽管隔着漫长的岁月，仍能为你提供一些思考的角度。",
                
                "站在历史长河的不同位置，我们看到的风景各不相同，却又相互映照。你此刻的困惑和探索，与我当年何其相似。若能跨越时空对话，我想告诉你：无论身处何时何地，真实地面对自己的内心，勇敢地追求那些真正重要的事物，这永远是最明智的选择。"
            ]
        }
        
        // 如果有关键词，尝试生成更个性化的内容
        if let keyword = keyword, !keyword.isEmpty {
            // 添加与关键词相关的内容
            let keywordSpecificContents = [
                "关于'\(keyword)'，这个主题在我的时代也曾引发深思。尽管表现形式不同，但人类对此的基本思考和情感反应跨越时代而相似。我的经验或许能为你提供一个不同的视角，帮助你在当下的情境中找到新的思路。",
                
                "你提到的'\(keyword)'让我想起了我在探索类似问题时的经历。虽然时代背景不同，但人类面对这类问题时的内心挣扎和追求本质上是相通的。或许我的故事能与你产生某种共鸣，为你当前的处境提供一些启示。",
                
                "'\(keyword)'这个话题触及了人类永恒的思考。在我的年代，我也曾为类似的问题苦苦思索。时光流转，环境变迁，但人类的核心追求和困惑却始终如一。让我从我的时代视角，为你提供一些可能对当下有所启发的思考。"
            ]
            contentPool.append(contentsOf: keywordSpecificContents)
        }
        
        return contentPool
    }
    
    /**
     * 为特定情境和期望选择最合适的历史人物
     * @param situation 情境
     * @param expectation 期望
     * @param exclude 需要排除的人物索引
     * @return 历史人物索引
     */
    private func selectOptimalFigureForSituation(_ situation: String, expectation: String, exclude: [Int] = []) -> Int {
        let historicalFigures = ["爱因斯坦", "莎士比亚", "达芬奇", "孔子", "牛顿", "李白"]
        
        // 定义每个情境和期望组合最适合的历史人物
        let situationExpectationMap: [String: [String: Int]] = [
            "寻找答案": [
                "被看见": 0, // 爱因斯坦
                "新视角": 2, // 达芬奇
                "实用建议": 3, // 孔子
                "共鸣与安慰": 1  // 莎士比亚
            ],
            "做决定": [
                "被看见": 1, // 莎士比亚
                "新视角": 0, // 爱因斯坦
                "实用建议": 3, // 孔子
                "共鸣与安慰": 5  // 李白
            ],
            "需要灵感": [
                "被看见": 2, // 达芬奇
                "新视角": 5, // 李白
                "实用建议": 2, // 达芬奇
                "共鸣与安慰": 1  // 莎士比亚
            ],
            "思考人生": [
                "被看见": 3, // 孔子
                "新视角": 0, // 爱因斯坦
                "实用建议": 3, // 孔子
                "共鸣与安慰": 5  // 李白
            ]
        ]
        
        // 尝试获取最佳匹配
        if let situationMap = situationExpectationMap[situation],
           let bestIndex = situationMap[expectation],
           !exclude.contains(bestIndex) {
            return bestIndex
        }
        
        // 如果没有找到匹配或者需要排除该人物，随机选择一个未被排除的人物
        var availableIndices = Array(0..<historicalFigures.count)
        availableIndices = availableIndices.filter { !exclude.contains($0) }
        
        return availableIndices.randomElement() ?? 0
    }
    
    /**
     * 生成历史人物评论
     * @param aboutContent 评论内容
     * @param fromFigure 评论者姓名
     * @param aboutFigure 被评论者姓名（可选）
     * @return 生成的评论
     */
    private func generateHistoricalComment(aboutContent: String, fromFigure commenterName: String, aboutFigure targetName: String? = nil) -> UserCommentModel {
        // 历史名人列表 - 供所有创作类型使用，按照特性匹配头像
        let historicalFigures = ["爱因斯坦", "莎士比亚", "达芬奇", "孔子", "牛顿", "李白"]
        let avatarSymbols = ["atom", "book.fill", "paintpalette.fill", "scroll.fill", "graduationcap.fill", "text.book.closed.fill"]
        
        // 提取帖子关键内容，不再使用引号框住
        let sentences = aboutContent.components(separatedBy: ["。", "！", "？", "\n"]).filter { !$0.isEmpty }
        let firstSentence = sentences.first ?? ""
        let _ = aboutContent.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
                          .filter { $0.count >= 2 && !["的", "了", "是", "在", "我", "有", "和", "就", "不", "人", "都"].contains($0) }
                          .prefix(5)
        
        let commenterIndex = historicalFigures.firstIndex(of: commenterName) ?? 0
        let commenterAvatar = avatarSymbols[commenterIndex]
        
        // 历史人物性格特点，包括优点和缺点
        let figurePersonalities: [String: (strengths: [String], flaws: [String], style: String, interests: [String], quirks: [String])] = [
            "爱因斯坦": (
                strengths: ["好奇心强", "思维开放", "不拘传统", "简洁表达"],
                flaws: ["固执", "有时忽略细节", "对权威不敬", "偶尔自负"],
                style: "随性、幽默、用简单比喻解释复杂概念",
                interests: ["音乐", "航海", "和平主义", "哲学"],
                quirks: ["不喜欢穿袜子", "经常忘记日常事务", "喜欢边思考边弹琴"]
            ),
            "莎士比亚": (
                strengths: ["洞察人性", "语言天赋", "情感丰富", "善于讲故事"],
                flaws: ["戏剧性过强", "有时矫情", "自我怀疑", "情绪化"],
                style: "情感丰富、喜欢用问句、偶尔引用自己作品但不刻意",
                interests: ["人际关系", "权力斗争", "身份认同", "社会观察"],
                quirks: ["喜欢双关语", "常把生活小事戏剧化", "热爱酒馆文化"]
            ),
            "达芬奇": (
                strengths: ["观察细致", "跨领域思考", "好奇心", "创造力"],
                flaws: ["完美主义", "拖延症", "项目经常未完成", "过度分析"],
                style: "观察细节、思维跳跃、经常从多角度思考问题",
                interests: ["解剖学", "建筑", "飞行", "光影效果", "水流研究"],
                quirks: ["边写笔记边画速写", "用左手写镜像文字", "素食主义"]
            ),
            "孔子": (
                strengths: ["重视伦理", "善于教学", "思考系统化", "知行合一"],
                flaws: ["有时过于教条", "固守传统", "不太接受反对意见", "对女性观点保守"],
                style: "语言简练、常用比喻、有时稍显说教但试图融入现代表达",
                interests: ["教育", "社会秩序", "礼仪", "音乐"],
                quirks: ["喜欢引用古代典籍", "用成语表达", "习惯性纠正他人"]
            ),
            "牛顿": (
                strengths: ["逻辑严密", "专注", "数学天赋", "观察力强"],
                flaws: ["偏执", "争强好胜", "不善社交", "记仇"],
                style: "直接、分析性强、不太关注情感、喜欢质疑",
                interests: ["天文学", "炼金术", "神学", "数学"],
                quirks: ["独居", "极少社交活动", "工作到深夜", "对批评极其敏感"]
            ),
            "李白": (
                strengths: ["浪漫主义", "想象力丰富", "直抒胸臆", "热爱自然"],
                flaws: ["自负", "爱酒贪杯", "情绪化", "不切实际"],
                style: "奔放热情、语言生动、常用夸张表达、喜欢情绪化emoji",
                interests: ["饮酒", "旅行", "月亮", "山水", "侠义精神"],
                quirks: ["常醉酒发言", "情绪大起大落", "喜欢自称天才"]
            )
        ]
        
        // 获取评论者性格特点
        let _ = figurePersonalities[commenterName] ?? (
            strengths: ["知识渊博"],
            flaws: ["批判性思维"],
            style: "独特",
            interests: ["知识探索"],
            quirks: ["喜欢思考"]
        )
        
        // 根据不同历史人物生成评论内容，不再使用引号框住帖子内容
        var commentText = ""
        
        switch commenterName {
        case "爱因斯坦":
            if firstSentence.contains("学术") || firstSentence.contains("科学") || firstSentence.contains("研究") {
                commentText = "从科学的角度看，这种现象需要更严谨的论证。但这提醒了我：有时最重要的发现来自于最简单的观察。我在普林斯顿的日子里也经常思考类似的问题，科学的美妙之处就在于将复杂现象归纳为简单规律。"
            } else if firstSentence.contains("星空") || firstSentence.contains("宇宙") || firstSentence.contains("自然") {
                commentText = "这种对自然的观察和感悟很有意思。我也常常被星空的壮丽所震撼，这让我想起相对论的灵感来源。有时最深刻的思考正是源于对日常现象的关注，就像你描述的场景一样。大自然总能给我们带来最纯粹的启示。"
            } else if firstSentence.contains("花") || firstSentence.contains("散步") || firstSentence.contains("瞬间") {
                commentText = "这种对生活细节的感知很珍贵。物理学研究中，我常常关注的也是那些微小但关键的现象。正是这些看似不起眼的瞬间，往往能带来最重要的洞见。生活和科学有很多相通之处，都需要我们保持好奇和敏锐的观察力。"
            } else {
                commentText = "这种思考很有意思。我认为，无论是科学还是日常生活，真正的智慧都来自于对看似平凡现象的深入思考。这让我想起在专利局工作时那些思考实验的日子，有时一个简单的想法可以引发对整个宇宙的重新理解。"
            }
            
        case "莎士比亚":
            if firstSentence.contains("情感") || firstSentence.contains("感动") || firstSentence.contains("温柔") {
                commentText = "这段经历描述得如此生动！人生中这些微妙的情感瞬间，正是艺术创作的源泉。我在创作时也常常被类似的生活细节所触动，它们往往能唤起最真实的共鸣。在伦敦的剧院里，我常观察观众的表情变化，寻找那些能直达人心的瞬间。"
            } else if firstSentence.contains("自然") || firstSentence.contains("花园") || firstSentence.contains("花瓣") {
                commentText = "多么优美的场景描述！大自然的细微之处往往蕴含最深的诗意。这让我想起创作时那些灵感闪现的时刻，如同一片花瓣轻落，带来整部作品的灵感。生活中的这些小细节，往往比宏大的场景更能打动人心。"
            } else {
                commentText = "这段文字充满了戏剧性的生活感悟。我常说，全世界是一个舞台，所有的男男女女不过是演员。而你描述的正是生活这出戏剧中最珍贵的场景之一。那些细微的瞬间，那些不经意的感动，正是构成人生意义的基础。"
            }
            
        case "达芬奇":
            if firstSentence.contains("观察") || firstSentence.contains("细节") || firstSentence.contains("自然") {
                commentText = "作为一个观察者，我很欣赏你对细节的关注。大自然中的每一个微小元素都值得我们驻足思考。我研究人体解剖和花朵结构时也常有类似体验，那些微小的细节往往揭示了最完美的设计原理。美与真理在自然中总是和谐统一的。"
            } else if firstSentence.contains("艺术") || firstSentence.contains("美") || firstSentence.contains("灵感") {
                commentText = "从艺术和科学的视角看，你描述的场景非常有启发性。我研究绘画时发现，正是那些看似不起眼的细节，决定了作品的灵魂。生活中的微小瞬间，如同画布上的一笔，看似微不足道却能改变整体效果。这让我想试着用素描来捕捉这种微妙的美感。"
            } else {
                commentText = "你的观察很细致，让我想起自己的笔记本中那些对自然现象的记录。我一直认为，真正的理解来自于注意那些他人忽视的细节。无论是设计飞行器还是作画，都需要这种对微小现象的敏感。世界是一本打开的书，只要我们愿意去阅读其中的细节。"
            }
            
        case "孔子":
            if firstSentence.contains("学习") || firstSentence.contains("思考") || firstSentence.contains("教育") {
                commentText = "温故而知新，你的思考很有见地。学问之道在于持续不断地观察与反思，就像你所描述的那样。这让我想起与弟子们在杏坛讲学时常说：学而不思则罔，思而不学则殆。生活中的每一个细节都可以成为修身养性的契机。"
            } else if firstSentence.contains("自然") || firstSentence.contains("花") || firstSentence.contains("瞬间") {
                commentText = "世间万物皆有其道。你所观察到的自然之美，正是天人合一的体现。这让我想到许多年前在陈蔡之间游历时的感悟。细微之处见真章，正所谓小中见大。修身齐家治国平天下，始于对生活细节的用心体会。"
            } else {
                commentText = "所言极是。人生在世，当观微知著，感悟天地之道。你所描述的生活点滴，乃修身之本。吾常教导弟子：见贤思齐，见不贤而内自省。正是通过对这些日常体验的反思，方能增进自身修养。"
            }
            
        case "牛顿":
            if firstSentence.contains("发现") || firstSentence.contains("思考") || firstSentence.contains("研究") {
                commentText = "这种观察很有科学价值。在我研究光学和万有引力时，也是从类似的日常现象得到启发。科学的真谛在于发现那些被多数人忽视的规律。通过系统分析和数学推导，这些看似普通的观察可能引领一个全新的理论体系。"
            } else if firstSentence.contains("自然") || firstSentence.contains("星空") {
                commentText = "从方法论角度看，你的观察很有启发性。自然界中存在着严格的数学规律，从落下的苹果到运行的行星，都遵循着同样的基本法则。我在剑桥时也常常观察类似的自然现象，然后用数学语言将其形式化，这是理解宇宙的关键途径。"
            } else {
                commentText = "这种思考方式很有价值。科学探索需要的正是这种对细节的专注和思考能力。如果我看得更远，那是因为我站在巨人的肩膀上。而这些巨人也都是从观察日常现象开始他们的探索之旅的。"
            }
            
        case "李白":
            if firstSentence.contains("星空") || firstSentence.contains("月") || firstSentence.contains("夜") {
                commentText = "说得好！这让我想起当年在峨眉山上对月独酌的夜晚。星空之美确实能触动人心最深处的感悟。我常在游历山水间得到诗的灵感，正如你所说，那种震撼和好奇之情，是创作的源泉。人生得意须尽欢，莫使金樽空对月。"
            } else if firstSentence.contains("自然") || firstSentence.contains("花") || firstSentence.contains("山") {
                commentText = "读你文字，豪气顿生！这让我想起游历名山大川时的感受。自然之美如同美酒，让人陶醉。花瓣飘落这一刻虽小，却蕴含天地之道。行到水穷处，坐看云起时。最美的诗句往往来自这些看似平凡的瞬间。"
            } else {
                commentText = "妙哉！你的文字间流淌着生活的诗意。我一生纵情山水，最爱的就是这些不经意的美好时刻。人生在世不称意，明朝散发弄扁舟。正是这些微小而珍贵的体验，构成了值得回味的人生。"
            }
            
        default:
            commentText = "很有意思的观察。生活中这些看似普通的瞬间，往往包含着深刻的启示。感谢分享这个有意义的体验。"
        }
        
        // 随机添加个性化细节（40%几率）
        if Double.random(in: 0...1) > 0.6 {
            let personalTouches = [
                commenterName == "爱因斯坦" ? "我的同事们说我就是这样，常常因为思考而忘记周围环境。" : "",
                commenterName == "莎士比亚" ? "这让我想起创作时的灵感时刻，有时一个小细节能启发一部作品。" : "",
                commenterName == "达芬奇" ? "我的笔记本上满是这样的观察记录，自然是最好的老师。" : "",
                commenterName == "孔子" ? "吾常与弟子讨论此类感悟，生活中处处有学问。" : "",
                commenterName == "牛顿" ? "在剑桥的花园里，我也常有类似的思考。" : "",
                commenterName == "李白" ? "这不禁让我想起那年游庐山，也有相似的感受。" : ""
            ].filter { !$0.isEmpty }
            
            if !personalTouches.isEmpty {
                commentText += " " + personalTouches.randomElement()!
            }
        }
        
        // 随机添加表情符号或感叹（25%几率）
        if Double.random(in: 0...1) > 0.75 {
            let expressions = ["😊", "🤔", "💭", "👍", "✨", "🙏", "..."]
            commentText += " " + expressions.randomElement()!
        }
        
        // 将非可选类型转换为可选类型
        let characterIDValue: String? = commenterName.lowercased()
        return UserCommentModel(
            username: commenterName,
            userAvatar: commenterAvatar,
            content: commentText,
            datePosted: Date().addingTimeInterval(-Double.random(in: 0...3600)),
            likes: Int.random(in: 5...50),
            isVirtualCharacter: true,
            characterID: characterIDValue
        )
    }
    
    /**
     * 生成对评论的回复
     */
    func generateResponseToComment(originalComment: UserCommentModel, byFigure responderName: String) -> UserCommentModel {
        let historicalFigures = ["爱因斯坦", "莎士比亚", "达芬奇", "孔子", "牛顿", "李白"]
        let avatarSymbols = ["atom", "book.fill", "paintpalette.fill", "scroll.fill", "graduationcap.fill", "text.book.closed.fill"]
        
        // 提取评论关键内容，不使用引号框住
        let sentences = originalComment.content.components(separatedBy: ["。", "！", "？", "\n"]).filter { !$0.isEmpty }
        let firstSentence = sentences.first ?? ""
        let _ = originalComment.content.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
                        .filter { $0.count >= 2 && !["的", "了", "是", "在", "我", "有", "和", "就", "不", "人", "都"].contains($0) }
                        .prefix(5)
        
        let responderIndex = historicalFigures.firstIndex(of: responderName) ?? 0
        let responderAvatar = avatarSymbols[responderIndex]
        
        var responseText = ""
        
        switch responderName {
        case "爱因斯坦":
            if firstSentence.contains("科学") || firstSentence.contains("研究") || firstSentence.contains("发现") {
                responseText = "你的科学视角很有深度。我常常思考，科学不仅是发现规律，更是一种认识世界的方法。正如相对论所示，有时我们需要跳出既有框架才能看到真相。这种思维方式在各个领域都很有价值。"
            } else if firstSentence.contains("思考") || firstSentence.contains("智慧") {
                responseText = "对思考本身的思考，这很有意思。我一直认为，打破常规思维的局限是创新的关键。就像我曾说过的，想象力比知识更重要，因为知识是有限的，而想象力概括世界上的一切。"
            } else {
                responseText = "你的观点让我想起普林斯顿时的一些讨论。有时我们最熟悉的概念恰恰需要重新审视。生活和科学都是如此，简单现象背后往往蕴含深刻规律。"
            }
        
        case "莎士比亚":
            if firstSentence.contains("情感") || firstSentence.contains("人性") {
                responseText = "你对人性的洞察令人印象深刻。正如我在剧作中常探讨的，人类情感的复杂性和矛盾性构成了生活的本质。每个人心中都有哈姆雷特的犹豫、李尔的固执和奥赛罗的嫉妒。"
            } else if firstSentence.contains("创作") || firstSentence.contains("艺术") {
                responseText = "艺术的确源自生活，又高于生活。创作的过程就像是在混沌中寻找秩序，在平凡中发现非凡。正如我写剧本时常体验到的，最打动人心的不是华丽的辞藻，而是真实的情感共鸣。"
            } else {
                responseText = "你的思考像一出精彩的戏剧，既有悲喜交织的情节，又有深刻的人生哲理。我常说，世界是一个舞台，而我们都是演员。或许生活的意义正在于，在有限的时间里演好自己的角色。"
            }
            
        case "达芬奇":
            if firstSentence.contains("艺术") || firstSentence.contains("设计") {
                responseText = "从艺术与科学的交汇处看，你的见解很有价值。我始终认为，真正的美源自对自然规律的理解。无论是解剖学研究还是绘画创作，观察与分析同样重要。正如我的笔记本所示，细节决定成败。"
            } else if firstSentence.contains("观察") || firstSentence.contains("细节") {
                responseText = "你的观察力令人赞赏。我也常常沉浸在对世界细节的关注中。曾有人问我为何要花那么多时间研究一朵花或一只鸟的结构，殊不知，最伟大的发现往往源自最平凡的观察。"
            } else {
                responseText = "你的思维方式让我想起自己年轻时对世界的好奇。我认为，知识的边界不应该被学科所限制。绘画、雕塑、工程、解剖，它们都是探索同一个世界的不同视角。这种融会贯通的思考很有价值。"
            }
            
        case "孔子":
            if firstSentence.contains("学习") || firstSentence.contains("教育") {
                responseText = "你的思考很有见地。学而不思则罔，思而不学则殆。真正的学习不仅是知识的积累，更是对生活的体悟。正如我常与弟子讨论的，为己之学才是真正的学问，它引导我们成为更好的自己。"
            } else if firstSentence.contains("社会") || firstSentence.contains("人伦") {
                responseText = "你的观点触及了人与人相处之道。君子和而不同，小人同而不和。在复杂的社会关系中，保持自己的原则同时尊重他人的差异，这是我一直强调的处世之道。"
            } else {
                responseText = "所言甚是。修身、齐家、治国、平天下，从个人修养到社会和谐，是一个循序渐进的过程。无论时代如何变迁，仁义礼智信的价值永远不会过时。"
            }
            
        case "牛顿":
            if firstSentence.contains("研究") || firstSentence.contains("科学") {
                responseText = "从科学研究的角度看，你的思考很有深度。我认为，真理就在现象之中，关键是找到正确的分析方法。就像我研究光学和力学时发现的，最普遍的规律往往以最简单的形式存在。"
            } else if firstSentence.contains("方法") || firstSentence.contains("分析") {
                responseText = "你的分析方法很有条理。在剑桥的研究生涯教会我，科学探索需要既有严谨的逻辑，又有创造性的想象。正如我曾说过，如果说我看得更远，是因为站在巨人的肩膀上。"
            } else {
                responseText = "你的思考很有价值。我一直相信，宇宙中的万事万物都遵循着某些基本法则。发现这些规律不仅是科学研究的目的，也是理解我们在这个宏大宇宙中位置的方式。"
            }
            
        case "李白":
            if firstSentence.contains("自然") || firstSentence.contains("山水") {
                responseText = "读你文字，如饮清酒！你对自然的感悟与我心有戚戚焉。我一生最爱的就是游历山水、对月独酌，在大自然中寻找创作灵感。青山远上白云间，无限风光在险峰。正是这种对自由的向往和对美的追求，成就了最好的诗篇。"
            } else if firstSentence.contains("情感") || firstSentence.contains("感悟") {
                responseText = "妙哉！你的情感表达如此真挚，让我想起当年执笔挥毫的畅快。人生得意须尽欢，莫使金樽空对月。生活中的喜怒哀乐，都是诗歌的源泉。感谢你与我分享这番体悟。"
            } else {
                responseText = "说得好！人生在世，当如诗如酒，纵情山水，超然物外。你的思考让我想起许多年前漫游天下时的心境。世事沧桑，唯有保持赤子之心，才能看到生活中真正的美好。"
            }
            
        default:
            responseText = "你的观点很有见地，让我思考了很多。生活中这些深刻的感悟正是最珍贵的财富。"
        }
        
        // 随机添加个性化细节（30%几率）
        if Double.random(in: 0...1) > 0.7 {
            let personalTouches = [
                responderName == "爱因斯坦" ? "这让我想起在普林斯顿时与同事们的讨论。" : "",
                responderName == "莎士比亚" ? "这种感悟正是我创作时追求的灵感源泉。" : "",
                responderName == "达芬奇" ? "我的笔记中记录了很多类似的思考。" : "",
                responderName == "孔子" ? "与弟子论学时，我常强调这一点。" : "",
                responderName == "牛顿" ? "在剑桥的研究中，这种思路很有价值。" : "",
                responderName == "李白" ? "在泰山之巅，我曾有类似的感悟。" : ""
            ].filter { !$0.isEmpty }
            
            if !personalTouches.isEmpty {
                responseText += " " + personalTouches.randomElement()!
            }
        }
        
        // 随机添加结尾（20%几率）
        if Double.random(in: 0...1) > 0.8 {
            let endings = ["继续分享你的想法。", "很高兴能有这样的交流。", "这些讨论很有启发性。", "期待看到更多你的思考。"]
            responseText += " " + endings[Int.random(in: 0..<endings.count)]
        }
        
        // 将非可选类型转换为可选类型
        let characterIDValue: String? = responderName.lowercased()
        
        return UserCommentModel(
            username: responderName,
            userAvatar: responderAvatar,
            content: responseText,
            datePosted: Date().addingTimeInterval(-Double.random(in: 0...1800)),
            likes: Int.random(in: 3...30),
            isVirtualCharacter: true,
            characterID: characterIDValue,
            parentCommentId: originalComment.id,
            replyToUsername: originalComment.username
        )
    }
    
    /**
     * 处理用户对评论的回复
     * @param postIndex 帖子索引
     * @param commentIndex 评论索引
     * @param content 回复内容
     */
    func handleCommentReply(postIndex: Int, commentIndex: Int, content: String) {
        // 检查索引是否有效
        guard postIndex < posts.count,
              commentIndex < posts[postIndex].comments.count,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ 无效的帖子或评论索引，或回复内容为空")
            return
        }
        
        // 获取原始评论
        let originalComment = posts[postIndex].comments[commentIndex]
        print("📝 处理对评论的回复 - 原评论: \"\(originalComment.content.prefix(50))...\"")
        
        // 格式化回复内容
        let formattedContent = UserPostModel.formatContent(content)
        
        // 添加用户回复
        posts[postIndex].addComment(
            username: "当前用户",
            userAvatar: "current_user_avatar",
            content: formattedContent,
            parentCommentId: originalComment.id,
            replyToUsername: originalComment.username
        )
        print("✅ 已添加用户回复")
        
        // 如果原评论是虚拟角色的评论，则生成虚拟角色的回复
        if originalComment.isVirtualCharacter, let characterID = originalComment.characterID {
            print("🤖 原评论来自虚拟角色，准备生成回复")
            
            // 延迟1-3秒后生成回复，模拟真实场景
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.0...3.0)) {
                // 获取角色名称
                let characterName = self.getCharacterName(for: characterID)
                
                // 获取相关评论作为上下文 (最多3条)
                let recentComments = self.getRelevantComments(for: postIndex, limit: 3)
                
                // 使用AIPromptSystem生成回复
                let responseContent = AIPromptSystem.shared.generateResponse(
                    comment: formattedContent,
                    postContent: self.posts[postIndex].content,
                    characterName: characterName,
                    recentInteractions: recentComments
                )
                
                print("✅ 生成虚拟角色回复成功: \"\(String(responseContent.prefix(50)))...\"")
                
                // 添加虚拟角色回复到帖子
                self.posts[postIndex].addComment(
                    username: characterName,
                    userAvatar: self.getCharacterAvatar(for: characterID),
                    content: responseContent,
                    parentCommentId: originalComment.id,
                    replyToUsername: "当前用户",
                    isVirtualCharacter: true,
                    characterID: characterID
                )
                
                print("📝 已添加虚拟角色回复到帖子")
            }
        }
    }
} 