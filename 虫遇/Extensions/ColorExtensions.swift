import SwiftUI

/**
 * 颜色扩展，定义应用中使用的主题颜色
 */
extension Color {
    /// 从十六进制字符串初始化颜色
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// 主色调 - 紫色
    static let primaryColor = Color(hex: "8C699E")
    
    /// 次要色调 - 淡棕色
    static let secondaryColor = Color(hex: "A890B8")
    
    /// 强调色调 - 橙色
    static let accentColor = Color.orange
    
    /// 背景色 - 浅灰色
    static let backgroundPrimary = Color(.systemBackground)
    
    /// 背景色 - 深灰色
    static let backgroundSecondary = Color(.secondarySystemBackground)
    
    /// 标签背景色 - 主色调的浅色版本
    static let tagBackgroundColor = Color(red: 99/255, green: 102/255, blue: 241/255).opacity(0.1)
    
    /// 成功色 - 绿色
    static let successColor = Color(red: 34/255, green: 197/255, blue: 94/255)
    
    /// 警告色 - 橙色
    static let warningColor = Color(red: 249/255, green: 115/255, blue: 22/255)
    
    /// 错误色 - 红色
    static let errorColor = Color(red: 239/255, green: 68/255, blue: 68/255)
    
    /// 信息色 - 蓝色
    static let infoColor = Color(red: 59/255, green: 130/255, blue: 246/255)
    
    /// 文本主色
    static let textPrimary = Color.primary
    
    /// 文本次要色
    static let textSecondary = Color.secondary
    
    // 角色主题色调
    static func characterTheme(for id: String) -> Color {
        switch id {
        case "einstein": return .blue
        case "shakespeare": return .purple
        case "davinci": return .green
        case "goku": return .orange
        case "naruto": return .orange
        case "holmes": return .indigo
        default: return .teal
        }
    }
    
    // 角色主题渐变
    static func characterGradient(for id: String) -> LinearGradient {
        switch id {
        case "einstein":
            return LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "shakespeare":
            return LinearGradient(
                gradient: Gradient(colors: [Color.purple, Color.red.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "davinci":
            return LinearGradient(
                gradient: Gradient(colors: [Color.green, Color.yellow.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "goku":
            return LinearGradient(
                gradient: Gradient(colors: [Color.orange, Color.red.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "naruto":
            return LinearGradient(
                gradient: Gradient(colors: [Color.orange, Color.blue.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "holmes":
            return LinearGradient(
                gradient: Gradient(colors: [Color.indigo, Color.blue.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                gradient: Gradient(colors: [Color.teal, Color.blue.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // 新增：温暖米色主题系列
    
    /// 米色背景 - 页面主背景色
    static let warmBackground = Color(hex: "F7F6F0")
    
    /// 米色卡片背景 - 卡片/内容区域背景色
    static let warmCardBackground = Color(hex: "F5F2EA")
    
    /// 米色嵌套背景 - 嵌套内容（如评论）背景色
    static let warmNestedBackground = Color(hex: "F9F7F4")
    
    /// 米色深色背景 - 用于与卡片形成对比的背景
    static let warmDarkBackground = Color(hex: "F0EDE4")
    
    /// 米色高亮背景 - 用于轻微强调的区域
    static let warmHighlightBackground = Color(hex: "FBF8F1")
    
    /// 主题强调色 - 优雅的紫色，与米色背景和谐搭配
    static let warmAccent = Color(hex: "8C699E")
    
    /// 主题次要强调色 - 浅紫色
    static let warmAccentSecondary = Color(hex: "A890B8")
    
    /// 点赞颜色 - 符合用户心理预期的红色
    static let likeColor = Color(hex: "E05252")
    
    /// 收藏颜色 - 温暖的金色
    static let bookmarkColor = Color(hex: "D4AF37")
    
    /// 评论颜色 - 淡雅的蓝灰色，保持与紫色主题的和谐
    static let commentColor = Color(hex: "7D90AC")
    
    /// 柔和的深灰色 - 主要文本颜色
    static let warmTextPrimary = Color(hex: "333333").opacity(0.9)
    
    /// 柔和的中灰色 - 次要文本颜色
    static let warmTextSecondary = Color(hex: "666666").opacity(0.85)
    
    /// 柔和的浅灰色 - 辅助文本颜色
    static let warmTextTertiary = Color(hex: "999999").opacity(0.8)
    
    /// 温暖的边框色 - 用于分割线和边框
    static let warmBorder = Color(hex: "DDDDDD").opacity(0.6)
}

/**
 * UIColor扩展
 * 定义与SwiftUI颜色对应的UIKit颜色
 */
import UIKit

extension UIColor {
    /// 主色调 - 紫色
    static let primaryUIColor = UIColor(red: 140/255, green: 105/255, blue: 158/255, alpha: 1.0)
    
    /// 次要色调 - 淡棕色
    static let secondaryColor = UIColor(red: 168/255, green: 144/255, blue: 184/255, alpha: 1.0)
    
    /// 强调色调 - 粉色
    static let accentColor = UIColor(red: 244/255, green: 114/255, blue: 182/255, alpha: 1.0)
    
    /// 背景色 - 浅灰色
    static let backgroundColor = UIColor(red: 246/255, green: 248/255, blue: 250/255, alpha: 1.0)
    
    /// 标签背景色 - 主色调的浅色版本
    static let tagBackgroundColor = UIColor(red: 99/255, green: 102/255, blue: 241/255, alpha: 0.1)
    
    /// 成功色 - 绿色
    static let successColor = UIColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1.0)
    
    /// 警告色 - 橙色
    static let warningColor = UIColor(red: 249/255, green: 115/255, blue: 22/255, alpha: 1.0)
    
    /// 错误色 - 红色
    static let errorColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
    
    /// 信息色 - 蓝色
    static let infoColor = UIColor(red: 59/255, green: 130/255, blue: 246/255, alpha: 1.0)
    
    // 新增：温暖米色主题系列对应的UIColor
    
    /// 米色背景 - 页面主背景色
    static let warmBackground = UIColor(red: 247/255, green: 246/255, blue: 240/255, alpha: 1.0)
    
    /// 米色卡片背景 - 卡片/内容区域背景色
    static let warmCardBackground = UIColor(red: 245/255, green: 242/255, blue: 234/255, alpha: 1.0)
    
    /// 温暖强调色 - 紫色
    static let warmAccent = UIColor(red: 140/255, green: 105/255, blue: 158/255, alpha: 1.0)
    
    /// 点赞颜色 - 红色
    static let likeColor = UIColor(red: 224/255, green: 82/255, blue: 82/255, alpha: 1.0)
    
    /// 收藏颜色 - 金色
    static let bookmarkColor = UIColor(red: 212/255, green: 175/255, blue: 55/255, alpha: 1.0)
} 