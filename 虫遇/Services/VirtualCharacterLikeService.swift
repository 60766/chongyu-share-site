import Foundation
import SwiftUI
import Combine

/**
 * 虚拟角色点赞服务
 * 处理虚拟角色的点赞行为，包括更新帖子点赞数和发送通知
 */
class VirtualCharacterLikeService {
    static let shared = VirtualCharacterLikeService()
    
    private init() {}
    
    /**
     * 处理虚拟角色对评论的点赞
     * @param characterId 角色ID
     * @param postId 帖子ID
     * @param commentId 评论ID
     * @param userComment 用户的评论内容（用于通知）
     */
    func processCharacterLike(characterId: String, postId: String, commentId: String, userComment: String? = nil) {
        #if DEBUG
        debugLog("🔧 VirtualCharacterLikeService.processCharacterLike 开始（评论点赞）")
        #endif
        #if DEBUG
        debugLog("🔧 参数 - 角色:\(characterId), 帖子:\(postId), 评论:\(commentId)")
        #endif
        DispatchQueue.main.async {
            // 1. 更新评论的点赞数
            self.updateCommentLikeCount(postId: postId, commentId: commentId)
            
            // 2. 发送点赞通知到虫洞
            self.sendLikeNotification(characterId: characterId, postId: postId, userComment: userComment)
        }
    }
    
    /**
     * 处理虚拟角色对帖子的点赞
     * @param characterId 角色ID  
     * @param postId 帖子ID
     * @param userPostContent 用户的帖子内容（用于通知）
     */
    func processPostLike(characterId: String, postId: String, userPostContent: String? = nil) {
        DispatchQueue.main.async {
            // 1. 更新帖子的点赞数
            self.updatePostLikeCount(postId: postId)
            
            // 2. 发送点赞通知到虫洞
            self.sendPostLikeNotification(characterId: characterId, postId: postId, userPostContent: userPostContent)
        }
    }
    
    /**
     * 更新评论的点赞数
     * @param postId 帖子ID
     * @param commentId 评论ID - 虚拟角色要点赞的具体评论ID
     */
    private func updateCommentLikeCount(postId: String, commentId: String) {
        let viewModel = PostViewModel.shared
        
        if let postIndex = viewModel.posts.firstIndex(where: { $0.id.uuidString == postId }) {
            let currentPost = viewModel.posts[postIndex]
            
            #if DEBUG
            debugLog("🎯 虚拟角色点赞目标评论ID: \(commentId)")
            #endif
            
            // 🔧 DEBUG: 显示帖子中所有评论的信息
            #if DEBUG
            debugLog("🔧 DEBUG: 帖子中所有评论:")
            #endif
            for (index, comment) in currentPost.comments.enumerated() {
                #if DEBUG
                debugLog("  [\(index)] ID: \(comment.id.uuidString.prefix(8))..., 用户: \(comment.username), 内容: \"\(comment.content.prefix(20))...\", 虚拟角色: \(comment.isVirtualCharacter)")
                #endif
            }
            
            // 首先尝试使用传入的commentId查找具体的评论
            if let commentIndex = currentPost.comments.firstIndex(where: { $0.id.uuidString == commentId }) {
                let targetComment = currentPost.comments[commentIndex]
                #if DEBUG
                debugLog("🎯 DEBUG: 找到目标评论! 索引: \(commentIndex), 用户: \(targetComment.username), 内容: \"\(targetComment.content.prefix(20))...\"")
                #endif
                
                // 验证这是一条用户评论（不是虚拟角色评论）
                if !targetComment.isVirtualCharacter {
                    
                    // 更新这条评论的点赞数
                    let currentComment = currentPost.comments[commentIndex]
                    
                    // 创建更新后的评论实例
                    let updatedComment = DetailedCommentModel(
                        id: currentComment.id,
                        username: currentComment.username,
                        userAvatar: currentComment.userAvatar,
                        content: currentComment.content,
                        datePosted: currentComment.datePosted,
                        userId: currentComment.userId,
                        isCurrentUser: currentComment.isCurrentUser,
                        isVirtualCharacter: currentComment.isVirtualCharacter,
                        characterID: currentComment.characterID,
                        parentCommentId: currentComment.parentCommentId,
                        replyToUsername: currentComment.replyToUsername,
                        replies: currentComment.replies,
                        likes: currentComment.likes + 1, // 增加点赞数
                        isLikedByCurrentUser: currentComment.isLikedByCurrentUser
                    )
                    
                    // 更新评论
                    currentPost.comments[commentIndex] = updatedComment
                    
                    // 更新帖子
                    viewModel.posts[postIndex] = currentPost
                    
                    // 发送UI更新通知
                    NotificationCenter.default.post(
                        name: NSNotification.Name("CommentLikeUpdated"),
                        object: nil,
                        userInfo: [
                            "postID": postId,
                            "commentID": targetComment.id.uuidString // 使用实际被点赞的评论ID
                        ]
                    )
                    
                    #if DEBUG
                    debugLog("📈 评论\(targetComment.id)点赞数已更新: \(currentComment.likes) -> \(updatedComment.likes)")
                    #endif
                } else {
                    #if DEBUG
                    debugLog("⚠️ 指定的评论ID \(commentId) 对应的是虚拟角色评论，不能点赞")
                    #endif
                }
            } else {
                // 如果找不到指定的评论ID，作为备用方案，查找最新的用户评论
                #if DEBUG
                debugLog("⚠️ 未找到指定的评论ID \(commentId)，作为备用方案查找最新用户评论")
                #endif
                
                let userComments = currentPost.comments.filter { !$0.isVirtualCharacter }
                guard let latestUserComment = userComments.max(by: { $0.datePosted < $1.datePosted }) else {
                    #if DEBUG
                    debugLog("❌ 在帖子\(postId)中未找到任何用户评论，无法点赞")
                    #endif
                    return
                }
                
                if let fallbackCommentIndex = currentPost.comments.firstIndex(where: { $0.id == latestUserComment.id }) {
                    let currentComment = currentPost.comments[fallbackCommentIndex]
                    
                    // 创建更新后的评论实例
                    let updatedComment = DetailedCommentModel(
                        id: currentComment.id,
                        username: currentComment.username,
                        userAvatar: currentComment.userAvatar,
                        content: currentComment.content,
                        datePosted: currentComment.datePosted,
                        userId: currentComment.userId,
                        isCurrentUser: currentComment.isCurrentUser,
                        isVirtualCharacter: currentComment.isVirtualCharacter,
                        characterID: currentComment.characterID,
                        parentCommentId: currentComment.parentCommentId,
                        replyToUsername: currentComment.replyToUsername,
                        replies: currentComment.replies,
                        likes: currentComment.likes + 1, // 增加点赞数
                        isLikedByCurrentUser: currentComment.isLikedByCurrentUser
                    )
                    
                    // 更新评论
                    currentPost.comments[fallbackCommentIndex] = updatedComment
                    
                    // 更新帖子
                    viewModel.posts[postIndex] = currentPost
                    
                    // 发送UI更新通知
                    NotificationCenter.default.post(
                        name: NSNotification.Name("CommentLikeUpdated"),
                        object: nil,
                        userInfo: [
                            "postID": postId,
                            "commentID": latestUserComment.id.uuidString
                        ]
                    )
                    
                    #if DEBUG
                    debugLog("📈 备用方案：评论\(latestUserComment.id)点赞数已更新: \(currentComment.likes) -> \(updatedComment.likes)")
                    #endif
                }
            }
        } else {
            #if DEBUG
            debugLog("❌ 未找到帖子\(postId)，无法更新评论点赞数")
            #endif
        }
    }
    
    /**
     * 发送点赞通知到虫洞
     * @param characterId 角色ID
     * @param postId 帖子ID
     * @param userComment 用户评论内容
     */
    private func sendLikeNotification(characterId: String, postId: String, userComment: String? = nil) {
        // 🔧 检查帖子是否是虚拟角色发布的
        // 如果是虚拟角色发布的帖子，且是邀请角色评论后的点赞，则不发送通知
        if let post = PostViewModel.shared.posts.first(where: { $0.id.uuidString == postId }) {
            // 判断帖子是否是虚拟角色发布的（characterID != nil 且 username 不是"当前用户"）
            let isVirtualCharacterPost = post.characterID != nil && post.username != "当前用户"
            
            if isVirtualCharacterPost {
                #if DEBUG
                debugLog("🚫 帖子\(postId)是虚拟角色发布的，邀请角色评论后的点赞不发送通知")
                #endif
                return
            }
        }
        
        // 🔧 修复：获取角色信息，优先从CharacterSystem获取用户创建的角色名称
        let characterName: String
        if characterId.hasPrefix("custom_") {
            // 用户创建的角色：从CharacterSystem获取
            let allCharacters = CharacterSystem.shared.getAllCharacters()
            if let customCharacter = allCharacters.first(where: { $0.id.lowercased() == characterId.lowercased() }) {
                characterName = customCharacter.name
            } else {
                // 如果CharacterSystem中没有，尝试从UserDefaults获取
                if let data = UserDefaults.standard.data(forKey: "CustomCharactersData"),
                   let characterDicts = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let characterDict = characterDicts.first(where: {
                       let id = ($0["id"] as? String ?? "").lowercased()
                       return id == characterId.lowercased() || id == characterId.lowercased().replacingOccurrences(of: "custom_", with: "")
                   }),
                   let name = characterDict["name"] as? String {
                    characterName = name
                } else {
                    #if DEBUG
                    debugLog("❌ 无法获取角色\(characterId)的名称")
                    #endif
                    return
                }
            }
        } else {
            // 预设角色：使用CharacterDataManager
            guard let name = CharacterDataManager.shared.getName(for: characterId) else {
            #if DEBUG
            debugLog("❌ 无法获取角色\(characterId)的名称")
            #endif
            return
            }
            characterName = name
        }
        
        let characterAvatar = CharacterAvatarService.shared.getAvatarName(for: characterId)
        
        // 获取帖子标题（取帖子内容的前面部分作为标题）
        var postTitle = "您的内容"
        if let post = PostViewModel.shared.posts.first(where: { $0.id.uuidString == postId }) {
            postTitle = String(post.content.prefix(42))
        }
        
        // 创建点赞通知（只有用户自己的帖子被点赞才通知）
        NotificationService.shared.createLikeNotification(
            characterId: characterId,
            characterName: characterName,
            characterAvatar: characterAvatar,
            postId: postId,
            postTitle: postTitle,
            userComment: userComment
        )
        
        #if DEBUG
        debugLog("📨 已发送点赞通知: \(characterName)点赞了您的内容")
        #endif
    }
    
    /**
     * 更新帖子的点赞数
     * @param postId 帖子ID
     */
    private func updatePostLikeCount(postId: String) {
        let viewModel = PostViewModel.shared
        
        if let postIndex = viewModel.posts.firstIndex(where: { $0.id.uuidString == postId }) {
            let currentPost = viewModel.posts[postIndex]
            
            #if DEBUG
            debugLog("🎯 虚拟角色点赞目标帖子ID: \(postId)")
            #endif
            #if DEBUG
            debugLog("🎯 帖子当前点赞数: \(currentPost.likes)")
            #endif
            
            // 检查帖子是否为用户发布的帖子
            if currentPost.username == "当前用户" || currentPost.characterID == nil {
                #if DEBUG
                debugLog("✅ 找到目标用户帖子 - ID: \(currentPost.id), 作者: \(currentPost.username)")
                #endif
                
                // 更新帖子点赞数
                let updatedPost = currentPost.updateLikes(delta: 1)
                
                // 更新帖子
                viewModel.posts[postIndex] = updatedPost
                
                // 🎯 关键节点4：虚拟角色点赞后保存
                viewModel.saveAtCriticalPoint(reason: "虚拟角色点赞")
                
                // 发送UI更新通知
                NotificationCenter.default.post(
                    name: NSNotification.Name("PostLikeUpdated"),
                    object: nil,
                    userInfo: [
                        "postID": postId
                    ]
                )
                
            } else {
                #if DEBUG
                debugLog("⚠️ 指定的帖子ID \(postId) 对应的是虚拟角色帖子，不能点赞")
                #endif
            }
        } else {
            #if DEBUG
            debugLog("❌ 未找到帖子\(postId)，无法更新帖子点赞数")
            #endif
        }
    }
    
    /**
     * 发送帖子点赞通知到虫洞
     * @param characterId 角色ID
     * @param postId 帖子ID
     * @param userPostContent 用户帖子内容
     */
    private func sendPostLikeNotification(characterId: String, postId: String, userPostContent: String? = nil) {
        // 🔧 检查帖子是否是虚拟角色发布的
        // 只有用户自己的帖子被点赞才通知，虚拟角色发布的帖子被点赞不通知
        if let post = PostViewModel.shared.posts.first(where: { $0.id.uuidString == postId }) {
            // 判断帖子是否是虚拟角色发布的（characterID != nil 且 username 不是"当前用户"）
            let isVirtualCharacterPost = post.characterID != nil && post.username != "当前用户"
            
            if isVirtualCharacterPost {
                #if DEBUG
                debugLog("🚫 帖子\(postId)是虚拟角色发布的，虚拟角色点赞不发送通知")
                #endif
                return
            }
        }
        
        // 🔧 修复：获取角色信息，优先从CharacterSystem获取用户创建的角色名称
        let characterName: String
        if characterId.hasPrefix("custom_") {
            // 用户创建的角色：从CharacterSystem获取
            let allCharacters = CharacterSystem.shared.getAllCharacters()
            if let customCharacter = allCharacters.first(where: { $0.id.lowercased() == characterId.lowercased() }) {
                characterName = customCharacter.name
            } else {
                // 如果CharacterSystem中没有，尝试从UserDefaults获取
                if let data = UserDefaults.standard.data(forKey: "CustomCharactersData"),
                   let characterDicts = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let characterDict = characterDicts.first(where: {
                       let id = ($0["id"] as? String ?? "").lowercased()
                       return id == characterId.lowercased() || id == characterId.lowercased().replacingOccurrences(of: "custom_", with: "")
                   }),
                   let name = characterDict["name"] as? String {
                    characterName = name
                } else {
                    #if DEBUG
                    debugLog("❌ 无法获取角色\(characterId)的名称")
                    #endif
                    return
                }
            }
        } else {
            // 预设角色：使用CharacterDataManager
            guard let name = CharacterDataManager.shared.getName(for: characterId) else {
            #if DEBUG
            debugLog("❌ 无法获取角色\(characterId)的名称")
            #endif
            return
            }
            characterName = name
        }
        
        let characterAvatar = CharacterAvatarService.shared.getAvatarName(for: characterId)
        
        // 获取帖子标题（取帖子内容的前面部分作为标题）
        var postTitle = "您的帖子"
        if let userPostContent = userPostContent {
            postTitle = String(userPostContent.prefix(42))
        } else if let post = PostViewModel.shared.posts.first(where: { $0.id.uuidString == postId }) {
            postTitle = String(post.content.prefix(42))
        }
        
        // 创建帖子点赞通知（只有用户自己的帖子被点赞才通知）
        NotificationService.shared.createLikeNotification(
            characterId: characterId,
            characterName: characterName,
            characterAvatar: characterAvatar,
            postId: postId,
            postTitle: postTitle,
            userComment: nil // 帖子点赞不需要评论内容
        )
        
        #if DEBUG
        debugLog("📨 已发送帖子点赞通知: \(characterName)点赞了您的帖子")
        #endif
    }
}

/*
 * === 修复说明：解决虚拟角色点赞错误关联到最新评论的问题 ===
 * 
 * 问题描述：
 * 当用户连续发送多条评论时，虚拟角色的点赞会错误地关联到正在加载中的最新评论，
 * 而不是它们实际回复的那条用户评论。
 * 
 * 具体场景：
 * 1. 用户发送评论A → 虚拟角色开始为评论A生成回复
 * 2. 用户快速发送评论B → 此时评论A的虚拟角色回复还在生成中
 * 3. 虚拟角色回复评论A时，由于评论B已经成为"最新评论"，点赞就错误地给了评论B
 * 4. 导致评论A没有获得应有的点赞，而评论B获得了不属于它的点赞
 * 
 * 问题根源：
 * 之前的修复方案错误地总是查找"最新的用户评论"进行点赞，但这不是我们想要的。
 * 我们需要的是：每个虚拟角色回复都应该点赞**它实际回复的那条用户评论**。
 * 
 * 正确的修复方案：
 * 1. 使用 MultiCharacterCommentService 传入的具体 commentId（userCommentId）
 * 2. 这个 commentId 是虚拟角色实际回复的那条用户评论的ID
 * 3. 首先尝试根据传入的 commentId 精确查找并点赞对应的评论
 * 4. 如果找不到（异常情况），则作为备用方案查找最新用户评论
 * 5. 验证评论确实是用户评论（不是虚拟角色评论）才进行点赞
 * 
 * 修复后的流程：
 * 1. 用户发送评论A → 虚拟角色回复评论A → 点赞评论A ✓
 * 2. 用户发送评论B → 虚拟角色回复评论B → 点赞评论B ✓
 * 3. 用户发送评论C → 虚拟角色回复评论C → 点赞评论C ✓
 * 
 * 每个虚拟角色回复都会准确点赞它实际回复的那条用户评论，
 * 不再出现点赞错误关联到其他评论的情况。
 */ 