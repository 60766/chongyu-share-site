import Foundation
import SwiftUI

/**
 * 通知数据模型
 * 用于管理应用中的通知数据
 */
struct NotificationModel: Identifiable {
    let id = UUID()
    let type: NotificationType
    let avatar: String
    let username: String
    let content: String?
    let time: String
    let isOnline: Bool
    let actionText: String?
    // 新增关联角色类别
    var character: CharacterInfo
    // 新增内容预览
    var previewContent: String?
    
    struct CharacterInfo {
        let name: String
        let era: String
        let category: CharacterCategory
        let image: String
        
        // 判断是否为虚构角色
        var isVirtual: Bool {
            return [CharacterCategory.animeCharacter, 
                   CharacterCategory.gameCharacter, 
                   CharacterCategory.fictionCharacter].contains(category)
        }
        
        // 判断是否为历史人物
        var isHistorical: Bool {
            return [CharacterCategory.scientist, 
                   CharacterCategory.philosopher, 
                   CharacterCategory.writer, 
                   CharacterCategory.artist].contains(category)
        }
        
        // 根据角色类别获取背景纹理
        var backgroundPattern: String {
            switch category {
            case .scientist: return "pattern_science"
            case .artist: return "pattern_art"
            case .philosopher: return "pattern_philosophy"
            case .writer: return "pattern_literary"
            case .animeCharacter: return "pattern_anime"
            case .gameCharacter: return "pattern_game"
            case .fictionCharacter: return "pattern_fiction"
            case .all: return "pattern_default"
            }
        }
        
        // 角色专属字体
        var fontStyle: Font {
            switch category {
            case .scientist: return .system(.body, design: .serif)
            case .philosopher: return .system(.body, design: .serif).weight(.light)
            case .writer: return .system(.body, design: .serif).weight(.medium)
            case .artist: return .system(.body, design: .rounded)
            default: return .system(.body)
            }
        }
        
        // 角色语言风格
        var speechStyle: String {
            switch category {
            case .scientist: return "以科学严谨的态度"
            case .philosopher: return "以哲学思辨的视角"
            case .writer: return "以文学家的笔触"
            case .artist: return "以艺术家的眼光"
            default: return ""
            }
        }
    }
    
    enum NotificationType {
        case comment     // 评论通知
        case like        // 点赞通知
        case follow      // 关注通知
        case system      // 系统通知
    }
    
    // 根据通知类型获取相应颜色
    var typeColor: Color {
        switch self.type {
        case .comment:
            return .blue
        case .like:
            return .pink
        case .follow:
            return .orange
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
        case .comment: return "评论"
        case .like: return "点赞"
        case .follow: return "关注"
        case .system: return ""
        }
    }
    
    // 预设的通知数据
    static let sampleNotifications: [NotificationModel] = [
        // 评论通知
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
                category: .scientist,
                image: "einstein"
            ),
            previewContent: "我认为宇宙是一个巨大的谜题，每发现一个规律，就会带来更多的问题。"
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
            )
        ),
        
        // 点赞通知
        NotificationModel(
            type: .like,
            avatar: "avatar3",
            username: "达芬奇",
            content: "你分享的照片构图精妙，光影层次分明，有一种文艺复兴时期的美感...",
            time: "5小时前",
            isOnline: true,
            actionText: "点赞",
            character: CharacterInfo(
                name: "达芬奇",
                era: "文艺复兴",
                category: .artist,
                image: "davinci"
            ),
            previewContent: "这幅作品的构图和用色让我想起了文艺复兴时期的经典风格。"
        ),
        
        // 系统通知
        NotificationModel(
            type: .system,
            avatar: "system",
            username: "系统通知 有新的时空旅者加入平台",
            content: "玛丽·居里 已穿越虫洞来",
            time: "1天前",
            isOnline: false,
            actionText: nil,
            character: CharacterInfo(
                name: "玛丽·居里",
                era: "20世纪初",
                category: .scientist,
                image: "curie"
            )
        )
    ]
} 