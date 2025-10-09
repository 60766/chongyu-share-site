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
    static let primaryColor = Color(hex: "9A8BB0")
    
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
    
    // 新增：舒适温暖主题系列 - 基于参考图片的配色方案
    
    /// 温暖米白色背景 - 页面主背景色，参考图片的优雅浅粉米色调
    static let warmBackground = Color(hex: "F7F5F3")
    
    /// 温暖卡片背景 - 参考图片的优雅浅粉米色，更加温暖舒适
    static let warmCardBackground = Color(hex: "FBF9F7")
    
    /// 温暖嵌套背景 - 嵌套内容（如评论）背景色，淡米色
    static let warmNestedBackground = Color(hex: "EFEEE8")
    
    /// 温暖深色背景 - 用于与卡片形成对比的背景
    static let warmDarkBackground = Color(hex: "F8F8F6")
    
    /// 评论背景色 - 温暖柔和的米色背景，与整体温暖色调和谐统一
    static let commentBackground = Color(hex: "F5F4EE")
    
    /// 评论描边色 - 温暖的浅棕灰色描边，与温暖背景完美融合
    static let commentBorder = Color(hex: "E8E5E0")
    
    /// 评论悬停背景色 - 轻微强调时的背景色
    static let commentHoverBackground = Color(hex: "F6F4F1")
    
    /// 评论文本颜色 - 温暖的深灰色，确保良好的可读性
    static let commentTextColor = Color(hex: "2A2A2A")
    
    /// 评论次要文本颜色 - 用于时间戳、作者等信息
    static let commentSecondaryTextColor = Color(hex: "6B6B6B")
    
    /// 评论主要文本颜色 - 用于评论内容的主要文本
    static let commentPrimaryText = Color(hex: "6f6e68")
    
    /// 温暖高亮背景 - 用于轻微强调的区域
    static let warmHighlightBackground = Color(hex: "FEFEFC")
    
    /// 温暖强调色 - 橙金色，参考图片中的温暖橙金色
    static let warmAccent = Color(hex: "E8A87C")
    
    /// 温暖次要强调色 - 浅橙金色
    static let warmAccentSecondary = Color(hex: "F2B896")
    
    /// 点赞颜色 - 温暖的红色，参考图片中的红色
    static let likeColor = Color(hex: "E53935")
    
    /// 收藏颜色 - 温暖的金色
    static let bookmarkColor = Color(hex: "D4AF37")
    
    /// 评论颜色 - 温暖的中性灰色，与整体色调协调
    static let commentColor = Color(hex: "8A8A8A")
    
    /// 深灰色主文本 - 主要文本颜色，参考图片中的深灰色
    static let warmTextPrimary = Color(hex: "1A1A1A")
    
    /// 中灰色次要文本 - 次要文本颜色
    static let warmTextSecondary = Color(hex: "4A4A4A")
    
    /// 浅灰色辅助文本 - 辅助文本颜色
    static let warmTextTertiary = Color(hex: "8A8A8A")
    
    /// 温暖边框色 - 用于分割线和边框
    static let warmBorder = Color(hex: "E0E0E0").opacity(0.6)

    func getCharacterColor(for characterID: String?) -> Color {
        guard let characterID = characterID?.lowercased() else {
            return .gray
        }
        
        switch characterID {
        case "einstein": return .blue
        case "newton": return .purple
        case "feynman": return .red
        case "curie": return .pink
        case "tesla": return .indigo
        case "davinci": return .green
        case "shakespeare": return .purple
        case "confucius": return .brown
        case "plato": return .blue
        case "socrates": return .cyan
        case "aristotle": return .indigo
        case "goku", "sunwukong": return .orange
        case "naruto": return .orange
        case "sherlock", "holmes": return .blue
        case "watson": return .green
        default: return .gray
        }
    }
    
    // 获取角色辅助颜色
    func getCharacterSecondaryColor(for characterID: String?) -> Color {
        guard let characterID = characterID?.lowercased() else {
            return .gray.opacity(0.3)
        }
        
        switch characterID {
        case "einstein": return .blue.opacity(0.3)
        case "newton": return .purple.opacity(0.3)
        case "feynman": return .red.opacity(0.3)
        case "curie": return .pink.opacity(0.3)
        case "tesla": return .indigo.opacity(0.3)
        case "davinci": return .green.opacity(0.3)
        case "shakespeare": return .purple.opacity(0.3)
        case "confucius": return .brown.opacity(0.3)
        case "plato": return .blue.opacity(0.3)
        case "socrates": return .cyan.opacity(0.3)
        case "aristotle": return .indigo.opacity(0.3)
        case "goku", "sunwukong":
            return .orange.opacity(0.3)
        case "naruto":
            return .orange.opacity(0.3)
        case "sherlock", "holmes":
            return .blue.opacity(0.3)
        case "watson":
            return .green.opacity(0.3)
        default: return .gray.opacity(0.3)
        }
    }
}

/**
 * UIColor扩展
 * 定义与SwiftUI颜色对应的UIKit颜色
 */
import UIKit

extension UIColor {
    /// 主色调 - 紫色
    static let primaryUIColor = UIColor(red: 154/255, green: 139/255, blue: 176/255, alpha: 1.0)
    
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
    
    // 新增：舒适温暖主题系列对应的UIColor - 基于参考图片的配色方案
    
    /// 温暖米白色背景 - 页面主背景色，参考图片的优雅浅粉米色调
    static let warmBackground = UIColor(red: 247/255, green: 245/255, blue: 243/255, alpha: 1.0)
    
    /// 温暖卡片背景 - 参考图片的优雅浅粉米色，更加温暖舒适
    static let warmCardBackground = UIColor(red: 250/255, green: 249/255, blue: 247/255, alpha: 1.0)
    
    /// 温暖强调色 - 橙金色
    static let warmAccent = UIColor(red: 232/255, green: 168/255, blue: 124/255, alpha: 1.0)
    
    /// 点赞颜色 - 温暖的红色
    static let likeColor = UIColor(red: 229/255, green: 57/255, blue: 53/255, alpha: 1.0)
    
    /// 收藏颜色 - 金色
    static let bookmarkColor = UIColor(red: 212/255, green: 175/255, blue: 55/255, alpha: 1.0)
} 