import Foundation
import SwiftUI

/**
 * 角色分类枚举
 * 用于对历史人物和虚构角色进行分类
 */
enum CharacterCategory: String, CaseIterable {
    case all = "全部"
    // 历史人物分类
    case scientist = "科学家"
    case artist = "艺术家"
    case philosopher = "哲学家"
    case writer = "文学家"
    
    // 虚构角色分类
    case animeCharacter = "动漫角色"
    case gameCharacter = "游戏角色"
    case fictionCharacter = "虚构人物"  // 涵盖文学、电影等虚构角色
    
    /// 类别显示名称
    var displayName: String {
        switch self {
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
        case .fictionCharacter:
            return "虚构人物"
        case .all:
            return "全部"
        }
    }
    
    var color: Color {
        switch self {
        case .all:
            return .primaryColor
        case .scientist:
            return Color(red: 76/255, green: 175/255, blue: 142/255)  // 绿色
        case .artist:
            return Color(red: 238/255, green: 131/255, blue: 54/255)  // 橙色
        case .philosopher:
            return Color(red: 244/255, green: 183/255, blue: 63/255)  // 黄色
        case .writer:
            return Color(red: 130/255, green: 115/255, blue: 230/255)  // 紫色
        case .animeCharacter:
            return Color(red: 239/255, green: 118/255, blue: 182/255)  // 粉色
        case .gameCharacter:
            return Color(red: 58/255, green: 176/255, blue: 186/255)  // 青色
        case .fictionCharacter:
            return Color(red: 102/255, green: 94/255, blue: 204/255)  // 靛蓝色
        }
    }
    
    // 分类对应的图标
    var icon: String {
        switch self {
        case .all:
            return "person.3.fill"
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
        }
    }
    
    // 判断是否为虚构角色
    var isVirtual: Bool {
        return [.animeCharacter, .gameCharacter, .fictionCharacter].contains(self)
    }
    
    /// 判断是否为历史人物
    var isHistorical: Bool {
        switch self {
        case .scientist, .philosopher, .writer, .artist:
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