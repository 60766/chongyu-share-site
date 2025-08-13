import Foundation
import SwiftUI

/**
 * 角色分类枚举
 * 用于对历史人物和虚构角色进行分类
 */
enum CharacterCategory: String, CaseIterable, Codable {
    case all = "全部"
    // 历史人物分类
    case historical = "历史人物"
    case scientist = "科学家"
    case artist = "艺术家"
    case philosopher = "哲学家"
    case writer = "文学家"
    
    // 虚构角色分类
    case animeCharacter = "动漫角色"
    case gameCharacter = "游戏角色"
    case movieCharacter = "电影角色"
    case tvCharacter = "电视剧角色"
    case mythCharacter = "神话角色"
    case fictionCharacter = "虚构人物"  // 涵盖文学、电影等虚构角色
    case vtuber = "虚拟主播"
    
    /// 类别显示名称
    var displayName: String {
        switch self {
        case .historical:
            return "历史人物"
        case .scientist:
            return "科学家"
        case .philosopher:
            return "哲学家"
        case .writer:
            return "文学家"
        case .artist:
            return "艺术家"
        case .animeCharacter:
            return "动漫角色"
        case .gameCharacter:
            return "游戏角色"
        case .movieCharacter:
            return "电影角色"
        case .tvCharacter:
            return "电视剧角色"
        case .mythCharacter:
            return "神话角色"
        case .fictionCharacter:
            return "虚构人物"
        case .vtuber:
            return "虚拟主播"
        case .all:
            return "全部"
        }
    }
    
    var color: Color {
        switch self {
        case .all:
            return Color(red: 95/255, green: 92/255, blue: 230/255)  // 稍微增强的蓝紫色
        case .historical:
            return Color(red: 132/255, green: 132/255, blue: 142/255)  // 稍微增强的石墨色
        case .scientist:
            return Color(red: 83/255, green: 182/255, blue: 150/255)  // 稍微增强的绿色
        case .artist:
            return Color(red: 227/255, green: 142/255, blue: 78/255)  // 稍微增强的橙色
        case .philosopher:
            return Color(red: 222/255, green: 175/255, blue: 75/255)  // 稍微增强的黄色
        case .writer:
            return Color(red: 148/255, green: 128/255, blue: 220/255)  // 稍微增强的紫色
        case .animeCharacter:
            return Color(red: 225/255, green: 140/255, blue: 185/255)  // 稍微增强的粉色
        case .gameCharacter:
            return Color(red: 78/255, green: 180/255, blue: 185/255)  // 稍微增强的青色
        case .fictionCharacter:
            return Color(red: 128/255, green: 119/255, blue: 205/255)  // 稍微增强的靛蓝色
        case .movieCharacter:
            return Color(red: 205/255, green: 128/255, blue: 123/255)  // 稍微增强的红色
        case .tvCharacter:
            return Color(red: 114/255, green: 158/255, blue: 215/255)  // 稍微增强的蓝色
        case .mythCharacter:
            return Color(red: 178/255, green: 135/255, blue: 210/255)  // 稍微增强的紫罗兰
        case .vtuber:
            return Color(red: 235/255, green: 160/255, blue: 200/255)  // 稍微增强的粉红
        }
    }
    
    // 分类对应的图标
    var icon: String {
        switch self {
        case .all:
            return "person.3.fill"
        case .historical:
            return "clock.arrow.circlepath"
        case .scientist:
            return "atom"
        case .artist:
            return "paintbrush.fill"
        case .philosopher:
            return "brain"
        case .writer:
            return "book.fill"
        case .animeCharacter:
            return "tv.fill"
        case .gameCharacter:
            return "gamecontroller.fill"
        case .fictionCharacter:
            return "film.fill"
        case .movieCharacter:
            return "film.circle"
        case .tvCharacter:
            return "tv.and.mediabox"
        case .mythCharacter:
            return "sparkles"
        case .vtuber:
            return "person.crop.rectangle"
        }
    }
    
    // 判断是否为虚构角色
    var isVirtual: Bool {
        return [.animeCharacter, .gameCharacter, .fictionCharacter, .movieCharacter, .tvCharacter, .mythCharacter, .vtuber].contains(self)
    }
    
    /// 判断是否为历史人物
    var isHistorical: Bool {
        switch self {
        case .historical, .scientist, .philosopher, .writer, .artist:
            return true
        default:
            return false
        }
    }
} 

// 添加静态方法以通过名称获取默认分类
extension CharacterCategory {
    static func getDefaultForName(_ name: String) -> CharacterCategory {
        let lowercasedName = name.lowercased()
        if lowercasedName.contains("爱因斯坦") || lowercasedName.contains("居里") {
            return .scientist
        } else if lowercasedName.contains("莎士比亚") || lowercasedName.contains("文学") {
            return .writer
        } else if lowercasedName.contains("孔子") || lowercasedName.contains("哲学") {
            return .philosopher
        } else if lowercasedName.contains("达芬奇") || lowercasedName.contains("艺术") {
            return .artist
        } else {
            return .all
        }
    }
}