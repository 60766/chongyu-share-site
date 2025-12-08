import Foundation

/**
 * 内容变化追踪器
 * 用于检测帖子/评论内容是否真正发生变化，避免不必要的UI刷新
 */
class ContentChangeTracker {
    static let shared = ContentChangeTracker()
    
    // 存储每个帖子的内容哈希值
    private var postContentHashes: [UUID: String] = [:]
    private let hashQueue = DispatchQueue(label: "ContentChangeTracker", attributes: .concurrent)
    
    private init() {}
    
    /**
     * 计算帖子的内容哈希值
     * 包括：内容、评论数量、点赞数等关键信息
     */
    func computePostHash(_ post: UserPostModel) -> String {
        // 构建用于哈希的字符串
        var hashString = "\(post.id.uuidString)"
        hashString += "|\(post.content)"
        hashString += "|\(post.likes)"
        hashString += "|\(post.comments.count)"
        hashString += "|\(post.images.joined(separator: ","))"
        
        // 计算评论的哈希（包括评论内容和点赞数）
        let commentsHash = post.comments.map { comment in
            "\(comment.id.uuidString)|\(comment.content)|\(comment.likes)|\(comment.replies.count)"
        }.joined(separator: ";")
        hashString += "|\(commentsHash)"
        
        // 使用简单的哈希算法
        return String(hashString.hashValue)
    }
    
    /**
     * 检查帖子内容是否发生变化
     * @return true 如果内容发生变化，false 如果没有变化
     */
    func hasPostChanged(_ post: UserPostModel) -> Bool {
        return hashQueue.sync {
            let currentHash = computePostHash(post)
            let previousHash = postContentHashes[post.id]
            
            if previousHash != currentHash {
                // 内容发生变化，更新哈希值
                postContentHashes[post.id] = currentHash
                return true
            }
            
            // 内容没有变化
            return false
        }
    }
    
    /**
     * 更新帖子的哈希值（用于初始化）
     */
    func updatePostHash(_ post: UserPostModel) {
        hashQueue.async(flags: .barrier) {
            self.postContentHashes[post.id] = self.computePostHash(post)
        }
    }
    
    /**
     * 批量更新多个帖子的哈希值
     */
    func updatePostHashes(_ posts: [UserPostModel]) {
        hashQueue.async(flags: .barrier) {
            for post in posts {
                self.postContentHashes[post.id] = self.computePostHash(post)
            }
        }
    }
    
    /**
     * 清除指定帖子的哈希值
     */
    func clearPostHash(_ postId: UUID) {
        hashQueue.async(flags: .barrier) {
            self.postContentHashes.removeValue(forKey: postId)
        }
    }
    
    /**
     * 清除所有哈希值（用于重置）
     */
    func clearAll() {
        hashQueue.async(flags: .barrier) {
            self.postContentHashes.removeAll()
        }
    }
}

