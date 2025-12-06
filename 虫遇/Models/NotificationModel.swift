import Foundation
import SwiftUI

/**
 * 通知数据模型
 * 用于管理应用中的通知数据
 */
struct NotificationModel: Identifiable, Codable {
    let id: UUID
    let type: NotificationType
    let avatar: String
    let username: String
    let content: String?
    let time: String
    let createdAt: Date  // 添加创建时间字段用于精确筛选
    let isOnline: Bool
    let actionText: String?
    // 新增关联角色类别
    var character: CharacterInfo?
    // 新增内容预览
    var previewContent: String?
    
    // 新增关联信息（用于精确对应用户行为）
    var relatedPostId: String?
    var relatedCommentId: String?
    var triggeredByAction: String?
    var isGenerated: Bool
    
    // 新增：用户触发内容（语境信息）
    var userComment: String?        // 用户的评论内容
    var userPost: String?           // 用户的帖子内容  
    var originalPost: String?       // 原帖内容（如果是评论他人帖子的场景）
    var originalPostAuthor: String? // 原帖作者（如果是评论他人帖子的场景）
    
    // 构造函数
    init(
        id: UUID = UUID(),
        type: NotificationType,
        avatar: String,
        username: String,
        content: String? = nil,
        time: String,
        createdAt: Date = Date(),
        isOnline: Bool,
        actionText: String? = nil,
        character: CharacterInfo? = nil,
        previewContent: String? = nil,
        relatedPostId: String? = nil,
        relatedCommentId: String? = nil,
        triggeredByAction: String? = nil,
        isGenerated: Bool = false,
        userComment: String? = nil,
        userPost: String? = nil,
        originalPost: String? = nil,
        originalPostAuthor: String? = nil
    ) {
        self.id = id
        self.type = type
        self.avatar = avatar
        self.username = username
        self.content = content
        self.time = time
        self.createdAt = createdAt
        self.isOnline = isOnline
        self.actionText = actionText
        self.character = character
        self.previewContent = previewContent
        // 新增关联信息赋值
        self.relatedPostId = relatedPostId
        self.relatedCommentId = relatedCommentId
        self.triggeredByAction = triggeredByAction
        self.isGenerated = isGenerated
        // 新增用户触发内容赋值
        self.userComment = userComment
        self.userPost = userPost
        self.originalPost = originalPost
        self.originalPostAuthor = originalPostAuthor
    }
    
    struct CharacterInfo: Codable {
        let name: String
        let era: String
        let category: CharacterCategory
        let image: String
        
        // 判断是否为虚构角色
        var isVirtual: Bool {
            return [CharacterCategory.animeCharacter, 
                   CharacterCategory.gameCharacter, 
                   CharacterCategory.filmCharacter].contains(category)
        }
        
        // 判断是否为历史人物
        var isHistorical: Bool {
            return [CharacterCategory.historical,
                   CharacterCategory.philosopher, 
                   CharacterCategory.writer].contains(category)
        }
        
        // 根据角色类别获取背景纹理
        var backgroundPattern: String {
            switch category {
            case .historical: return "pattern_history"
            case .philosopher: return "pattern_philosophy"
            case .writer: return "pattern_literary"
            case .animeCharacter: return "pattern_anime"
            case .gameCharacter: return "pattern_game"
            case .filmCharacter: return "pattern_movie"
            case .mythCharacter: return "pattern_myth"
            case .myCreation: return "pattern_default" // 用户创建的角色使用默认纹理
            case .all: return "pattern_default"
            }
        }
        
        // 角色专属字体格式 - 参考主页帖子正文样式
        var fontStyle: Font {
            switch category {
            case .historical: return .system(size: 16, weight: .regular, design: .serif)
            case .philosopher: return .system(size: 16, weight: .regular, design: .serif)
            case .writer: return .system(size: 16, weight: .regular, design: .serif)
            case .animeCharacter: return .system(size: 16, weight: .regular, design: .rounded)
            case .gameCharacter: return .system(size: 16, weight: .regular, design: .rounded)
            case .filmCharacter: return .system(size: 16, weight: .regular, design: .rounded)
            case .mythCharacter: return .system(size: 16, weight: .regular, design: .serif)
            default: return .system(size: 16, weight: .regular, design: .rounded)
            }
        }
        
        // 角色专属字体格式（支持自定义字重）
        func fontStyle(weight: Font.Weight = .regular) -> Font {
            switch category {
            case .historical: return .system(size: 16, weight: weight, design: .serif)
            case .philosopher: return .system(size: 16, weight: weight, design: .serif)
            case .writer: return .system(size: 16, weight: weight, design: .serif)
            case .animeCharacter: return .system(size: 16, weight: weight, design: .rounded)
            case .gameCharacter: return .system(size: 16, weight: weight, design: .rounded)
            case .filmCharacter: return .system(size: 16, weight: weight, design: .rounded)
            case .mythCharacter: return .system(size: 16, weight: weight, design: .serif)
            default: return .system(size: 16, weight: weight, design: .rounded)
            }
        }
        
        // 角色语言风格
        var speechStyle: String {
            switch category {
            case .historical: return "以历史的角度"
            case .philosopher: return "以哲学思辨的视角"
            case .writer: return "以文学世界的笔触"
            default: return ""
            }
        }
    }
    
    enum NotificationType: Codable {
        case comment     // 评论通知
        case like        // 点赞通知
        case follow      // 关注通知
        case system      // 系统通知
    }
    
    // 根据通知类型获取相应颜色
    var typeColor: Color {
        switch self.type {
        case .comment:
            return .primaryColor
        case .like:
            return .pink
        case .follow:
            return .primaryColor
        case .system:
            return .purple
        }
    }
    
    // 根据通知类型获取图标
    var typeIcon: String {
        switch self.type {
        case .comment:
            return "bubble.left.fill"
        case .like:
            return "heart.fill"
        case .follow:
            return "person.badge.plus.fill"
        case .system:
            return "bell.fill"
        }
    }
    
    // 是否可以响应
    var canRespond: Bool {
        return type != .system
    }
    
    // 响应按钮文字
    var responseButtonText: String {
        switch type {
        case .comment: return "回复"
        case .like: return "点赞"
        case .follow: return "关注"
        case .system: return ""
        }
    }
    
    // 预设的通知数据
    static let sampleNotifications: [NotificationModel] = [
        // 评论通知 - 角色回复用户评论
        NotificationModel(
            type: .comment,
            avatar: "avatar1",
            username: "爱因斯坦",
            content: "\"你对宇宙的思考很有意思。我认为，宇宙不仅比我们想象的更奇妙，甚至比我们能够想象的还要奇妙...\"",
            time: "10分钟前",
            isOnline: true,
            actionText: "评论",
            character: CharacterInfo(
                name: "爱因斯坦",
                era: "20世纪",
                category: .historical,
                image: "einstein"
            ),
            previewContent: nil,
            relatedPostId: "sample_post_1",
            relatedCommentId: nil,
            triggeredByAction: "comment",
            isGenerated: false,
            userComment: "你好，对时间旅行很感兴趣",
            userPost: nil,
            originalPost: "在雅典卫城坍塌的拱门下发现螺旋状铭文时，我意识到自己或许才是被寻找的对象。那些被暴雨冲刷三千年的符号，最终指向的是深险者手掌的伤口形状。我们总在寻找答案，却忘了答案需要特定角度的裂痕才能显形——就像玛雅水晶头骨必须摔碎才能释放星图。",
            originalPostAuthor: "劳拉·克罗夫特"
        ),
        
        // 关注通知
        NotificationModel(
            type: .follow,
            avatar: "avatar2",
            username: "莎士比亚",
            content: nil,
            time: "2小时前",
            isOnline: false,
            actionText: "关注",
            character: CharacterInfo(
                name: "莎士比亚",
                era: "16-17世纪",
                category: .writer,
                image: "shakespeare"
            ),
            previewContent: nil,
            relatedPostId: nil,
            relatedCommentId: nil,
            triggeredByAction: "interaction",
            isGenerated: false,
            userComment: nil,
            userPost: nil,
            originalPost: nil,
            originalPostAuthor: nil
        ),
        
        // 点赞通知 - 角色评论用户帖子
        NotificationModel(
            type: .comment,
            avatar: "avatar3",
            username: "达芬奇",
            content: "你分享的照片构图精妙，光影层次分明，有一种文艺复兴时期的美感...",
            time: "5小时前",
            isOnline: true,
            actionText: "评论",
            character: CharacterInfo(
                name: "达芬奇",
                era: "文艺复兴",
                category: .historical,
                image: "davinci"
            ),
            previewContent: nil,
            relatedPostId: "sample_post_2",
            relatedCommentId: nil,
            triggeredByAction: "comment",
            isGenerated: false,
            userComment: nil,
            userPost: "当双耳化作沉默的深渊，我在斑驳的墙影下聆听时间的回响",
            originalPost: nil,
            originalPostAuthor: nil
        ),
        
        // 系统通知
        NotificationModel(
            type: .system,
            avatar: "assistant_avatar",
            username: "虫遇小助手",
            content: "玛丽·居里 已穿越虫洞来",
            time: "1天前",
            isOnline: false,
            actionText: nil,
            character: CharacterInfo(
                name: "虫遇小助手",
                era: "现代",
                category: .all,
                image: "assistant_avatar"
            ),
            previewContent: nil,
            relatedPostId: nil,
            relatedCommentId: nil,
            triggeredByAction: "system",
            isGenerated: false,
            userComment: nil,
            userPost: nil,
            originalPost: nil,
            originalPostAuthor: nil
        )
    ]
} 