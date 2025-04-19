import Foundation
import Combine
import SwiftUI

/**
 * 帖子视图模型
 * 处理帖子数据和用户交互
 */
class PostViewModel: ObservableObject {
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
} 