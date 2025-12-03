import Foundation
import SwiftUI

/**
 * 点赞记录类型
 */
enum LikeRecordType: String, CaseIterable, Codable {
    case post = "帖子"
    case comment = "评论"
    
    var iconName: String {
        switch self {
        case .post:
            return "doc.text"
        case .comment:
            return "text.bubble"
        }
    }
    
    var color: Color {
        switch self {
        case .post:
            return Color.blue
        case .comment:
            return Color.green
        }
    }
}

/**
 * 点赞记录模型
 * 用于记录用户的点赞行为，支持持久化存储
 */
struct LikeRecord: Identifiable, Codable {
    let id: UUID
    let postId: String
    let type: LikeRecordType
    let title: String
    let content: String
    let authorName: String
    let authorAvatar: String
    let characterName: String?  // 相关角色
    let timestamp: Date
    let likeCount: Int
    
    /**
     * 初始化点赞记录
     */
    init(
        id: UUID = UUID(),
        postId: String,
        type: LikeRecordType,
        title: String,
        content: String,
        authorName: String,
        authorAvatar: String,
        characterName: String? = nil,
        timestamp: Date = Date(),
        likeCount: Int = 0
    ) {
        self.id = id
        self.postId = postId
        self.type = type
        self.title = title
        self.content = content
        self.authorName = authorName
        self.authorAvatar = authorAvatar
        self.characterName = characterName
        self.timestamp = timestamp
        self.likeCount = likeCount
    }
    

} 