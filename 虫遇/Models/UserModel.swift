import Foundation
import SwiftUI

/**
 * 用户数据模型
 * 用于管理应用中的用户信息
 */
struct UserModel: Identifiable {
    let id = UUID()
    let username: String        // 用户名
    let avatar: String          // 头像
    let level: Int              // 奇遇等级
    let stats: UserStats        // 用户统计数据
    
    // 用户统计数据
    struct UserStats {
        var posts: Int          // 动态数
        var likes: Int          // 获赞数
        var friends: Int        // 虚拟好友数
        var comments: Int       // 评论数
    }
    
    // 示例用户数据
    static let sampleUser = UserModel(
        username: "历史探索者",
        avatar: "user_avatar",
        level: 8,
        stats: UserStats(
            posts: 128,
            likes: 1200,
            friends: 12,
            comments: 368
        )
    )
}

/**
 * 角色互动关系模型
 * 描述用户与历史人物的互动关系
 */
struct CharacterRelationModel: Identifiable {
    let id = UUID()
    let character: CharacterModel   // 历史人物
    let relationType: RelationType  // 关系类型
    let lastInteractTime: Date      // 最后互动时间
    
    // 关系类型
    enum RelationType: String {
        case favorite = "亲密"      // 亲密关系
        case friend = "友好"        // 友好关系
        case curious = "熟悉"       // 好奇/熟悉关系
        case admire = "崇拜"        // 崇拜关系
    }
    
    // 关系类型颜色
    var relationColor: Color {
        switch relationType {
        case .favorite:
            return .blue
        case .friend:
            return .purple
        case .curious:
            return .pink
        case .admire:
            return .orange
        }
    }
    
    // 示例角色关系数据
    static let sampleRelations: [CharacterRelationModel] = [
        CharacterRelationModel(
            character: CharacterModel.sampleCharacters[0],
            relationType: .curious,
            lastInteractTime: Date().addingTimeInterval(-86400)
        ),
        CharacterRelationModel(
            character: CharacterModel.sampleCharacters[1],
            relationType: .friend,
            lastInteractTime: Date().addingTimeInterval(-172800)
        ),
        CharacterRelationModel(
            character: CharacterModel.sampleCharacters[3],
            relationType: .favorite,
            lastInteractTime: Date().addingTimeInterval(-259200)
        )
    ]
} 