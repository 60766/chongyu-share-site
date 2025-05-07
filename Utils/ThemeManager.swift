import SwiftUI
import Combine

/**
 * ThemeManager - 应用主题管理器
 * 负责管理应用全局主题和角色相关的主题设置
 */
class ThemeManager: ObservableObject {
    // 单例模式，确保整个应用使用同一个主题管理器
    static let shared = ThemeManager()
    
    // 全局应用主题，可根据用户设置或系统设置动态变化
    @Published var currentTheme: AppTheme = .defaultLight
    
    // 用户偏好设置的主题模式
    @Published var userPreferredThemeMode: ThemeMode = .system {
        didSet {
            updateThemeBasedOnPreferences()
        }
    }
    
    // 是否使用系统深色模式
    @Published var isSystemInDarkMode: Bool = false {
        didSet {
            if userPreferredThemeMode == .system {
                updateThemeBasedOnPreferences()
            }
        }
    }
    
    // 主题颜色设置
    @Published var primaryColor: Color = .blue
    @Published var secondaryColor: Color = .purple
    @Published var accentColor: Color = .orange
    
    // 角色主题映射表
    private var characterThemes: [String: CharacterTheme] = [:]
    
    private init() {
        // 监听系统外观模式变化
        monitorSystemAppearance()
        // 加载保存的用户偏好
        loadSavedPreferences()
    }
    
    // 根据用户偏好设置和系统模式更新主题
    private func updateThemeBasedOnPreferences() {
        switch userPreferredThemeMode {
        case .light:
            currentTheme = .defaultLight
        case .dark:
            currentTheme = .defaultDark
        case .system:
            currentTheme = isSystemInDarkMode ? .defaultDark : .defaultLight
        }
    }
    
    // 监听系统外观模式变化
    private func monitorSystemAppearance() {
        // 在实际应用中，这里应该使用UITraitCollection监听系统外观变化
        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemAppearanceChanged),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        #endif
    }
    
    @objc private func systemAppearanceChanged() {
        #if os(iOS)
        // 检测系统是否处于深色模式
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            isSystemInDarkMode = window.traitCollection.userInterfaceStyle == .dark
        }
        #endif
    }
    
    // 加载保存的用户偏好设置
    private func loadSavedPreferences() {
        // 这里应该从UserDefaults或其他持久化存储中加载用户偏好
        // 示例代码:
        if let savedThemeMode = UserDefaults.standard.string(forKey: "userPreferredThemeMode"),
           let themeMode = ThemeMode(rawValue: savedThemeMode) {
            userPreferredThemeMode = themeMode
        }
    }
    
    // 保存用户偏好设置
    func savePreferences() {
        // 这里应该将用户偏好保存到UserDefaults或其他持久化存储
        UserDefaults.standard.set(userPreferredThemeMode.rawValue, forKey: "userPreferredThemeMode")
    }
    
    // 通过ID获取角色主题
    func getCharacterTheme(for characterId: String) -> CharacterTheme {
        if let theme = characterThemes[characterId] {
            return theme
        }
        // 如果没有为该角色设置主题，则创建一个新的主题
        let newTheme = CharacterTheme(
            primary: .blue,
            secondary: .purple,
            background: Color(UIColor.systemBackground),
            contentBackground: Color(UIColor.secondarySystemBackground)
        )
        characterThemes[characterId] = newTheme
        return newTheme
    }
    
    // 设置角色主题
    func setCharacterTheme(for characterId: String, theme: CharacterTheme) {
        characterThemes[characterId] = theme
    }
    
    // 通过颜色生成一个角色主题
    func generateCharacterTheme(from color: Color) -> CharacterTheme {
        let primary = color
        let secondary = shiftHue(color: color, by: 0.3)
        let background = currentTheme == .defaultLight ?
            Color(UIColor.systemBackground) : Color(UIColor.systemBackground)
        let contentBackground = currentTheme == .defaultLight ?
            Color(UIColor.secondarySystemBackground) : Color(UIColor.secondarySystemBackground)
        
        return CharacterTheme(
            primary: primary,
            secondary: secondary,
            background: background,
            contentBackground: contentBackground
        )
    }
    
    // 辅助函数 - 调整颜色色相
    private func shiftHue(color: Color, by amount: CGFloat) -> Color {
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        let newHue = (hue + amount).truncatingRemainder(dividingBy: 1.0)
        return Color(UIColor(hue: newHue, saturation: saturation, brightness: brightness, alpha: alpha))
    }
}

// 应用主题枚举
enum AppTheme {
    case defaultLight
    case defaultDark
    case custom(primary: Color, secondary: Color, background: Color)
    
    var primaryColor: Color {
        switch self {
        case .defaultLight:
            return Color.blue
        case .defaultDark:
            return Color.blue.opacity(0.8)
        case .custom(let primary, _, _):
            return primary
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .defaultLight:
            return Color.purple
        case .defaultDark:
            return Color.purple.opacity(0.8)
        case .custom(_, let secondary, _):
            return secondary
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .defaultLight:
            return Color(UIColor.systemBackground)
        case .defaultDark:
            return Color(UIColor.systemBackground)
        case .custom(_, _, let background):
            return background
        }
    }
}

// 主题模式枚举
enum ThemeMode: String {
    case light = "light"
    case dark = "dark"
    case system = "system"
}

// 角色主题结构
struct CharacterTheme {
    let primary: Color
    let secondary: Color
    let background: Color
    let contentBackground: Color
    
    // 辅助计算属性
    var primaryLight: Color {
        return primary.opacity(0.8)
    }
    
    var primaryDark: Color {
        return primary.opacity(0.6)
    }
    
    var secondaryLight: Color {
        return secondary.opacity(0.8)
    }
} 