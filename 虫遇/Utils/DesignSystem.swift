import SwiftUI

/**
 * 虫遇应用设计系统
 * 统一颜色、间距、字体、阴影等视觉元素
 */
struct DesignSystem {
    // MARK: - 颜色系统
    struct Colors {
        // 主题色
        static let primary = Color.primaryColor
        static let secondary = Color.secondaryColor
        
        // 交互色
        static let like = Color.likeColor  // 使用专门的点赞红色
        static let bookmark = Color.bookmarkColor  // 使用温暖的金色
        static let comment = Color.commentColor  // 使用淡雅的蓝灰色
        
        // 背景色 - 基于参考图片的舒适配色方案
        static let background = Color.warmBackground
        static let cardBackground = Color.warmCardBackground  // 使用温暖的卡片背景色
        static let secondaryBackground = Color.warmDarkBackground  // 次级卡片背景色
        static let warmNestedBackground = Color.warmNestedBackground  // 嵌套内容（如评论）背景色
        
        // 评论相关颜色 - 温暖和谐的评论配色方案
        static let commentBackground = Color.commentBackground  // 温暖柔和的评论背景色
        static let commentBorder = Color.commentBorder  // 温暖的浅棕灰色描边
        static let commentHoverBackground = Color.commentHoverBackground  // 评论悬停背景色
        static let commentText = Color.commentTextColor  // 评论文本颜色
        static let commentSecondaryText = Color.commentSecondaryTextColor  // 评论次要文本颜色
        
        // 文本色
        static let primaryText = Color.warmTextPrimary
        static let secondaryText = Color.warmTextSecondary
        static let tertiaryText = Color.warmTextTertiary
        
        // 评论专用文本颜色
        static let commentPrimaryText = Color.commentPrimaryText
        
        // 分割线
        static let divider = Color.warmBorder
        
        // 边框色 - 基于参考图片的柔和边框
        static let border = Color.warmBorder  // 使用温暖的边框颜色，与舒适背景协调
    }
    
    // MARK: - 间距系统
    struct Spacing {
        // 基础间距
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        
        // 卡片内边距
        static let cardPadding = l
        static let cardSpacing = m
        
        // 内容间距
        static let contentSpacing = m
        static let sectionSpacing = xl
    }
    
    // MARK: - 圆角系统
    struct Radius {
        static let s: CGFloat = 4
        static let m: CGFloat = 8
        static let l: CGFloat = 12
        static let xl: CGFloat = 16
        static let xxl: CGFloat = 24
        
        // 卡片圆角
        static let card = l // 12pt圆角，符合图片中的设计风格
        
        // 内嵌卡片圆角
        static let innerCard = 10 // 10pt圆角用于内嵌卡片
        
        // 按钮圆角
        static let button = m
        
        // 输入框圆角
        static let input = m
        
        // 图片圆角
        static let image = l // 12pt圆角，与卡片保持一致
    }
    
    // MARK: - 阴影系统
    struct Shadows {
        // 卡片阴影
        static let cardShadow = Shadow(
            color: Color.black.opacity(0.04),
            radius: 6,
            x: 0,
            y: 2
        )
        
        // 卡片内部元素阴影
        static let innerElementShadow = Shadow(
            color: Color.black.opacity(0.03),
            radius: 4,
            x: 0,
            y: 1
        )
        
        // 浮动按钮阴影
        static let floatingShadow = Shadow(
            color: Color.black.opacity(0.12),
            radius: 15,
            x: 0,
            y: 4
        )
        
        // 轻微阴影
        static let lightShadow = Shadow(
            color: Color.black.opacity(0.04),
            radius: 6,
            x: 0,
            y: 1
        )
    }
    
    // MARK: - 边框系统
    struct Borders {
        // 标准边框
        static let standard = Border(
            color: Colors.border,
            width: 0.5
        )
        
        // 强调边框
        static let accent = Border(
            color: Colors.primary.opacity(0.1),
            width: 1.0
        )
    }
    
    // MARK: - 字体系统
    struct Typography {
        // 标题
        static let largeTitle = Font.largeTitle
        static let title = Font.title
        static let title2 = Font.title2
        static let title3 = Font.title3
        
        // 主体文本 - 优雅衬线字体
        static let body = Font.system(size: 16, weight: .regular, design: .serif)
        static let bodyBold = Font.system(size: 16, weight: .semibold, design: .serif)
        static let callout = Font.system(size: 15, weight: .regular, design: .serif)
        static let subheadline = Font.system(size: 14, weight: .regular, design: .serif)
        static let footnote = Font.system(size: 13, weight: .regular, design: .serif)
        static let caption = Font.system(size: 12, weight: .regular, design: .serif)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .serif)
        
        // 自定义尺寸
        static func custom(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .serif) -> Font {
            return Font.system(size: size, weight: weight, design: design)
        }
        
        // 帖子正文专用优雅字体
        static let postContent = Font.system(size: 16, weight: .regular, design: .serif)
        static let postContentBold = Font.system(size: 16, weight: .semibold, design: .serif)
        
        // 评论文字专用字体
        static let commentText = Font.system(size: 15, weight: .regular, design: .serif)
        static let commentTextBold = Font.system(size: 15, weight: .semibold, design: .serif)
        
        // 标题字体
        static let headline = Font.system(size: 16, weight: .medium, design: .default)
    }
    
    // MARK: - 动画系统
    struct Animations {
        // 标准动画
        static let standard = Animation.easeInOut(duration: 0.3)
        
        // 快速动画
        static let quick = Animation.easeInOut(duration: 0.2)
        
        // 弹性动画
        static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
        
        // 延迟动画
        static func delay(_ duration: Double) -> Animation {
            return Animation.easeInOut(duration: 0.3).delay(duration)
        }
    }
}

/**
 * 阴影定义结构体
 */
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

/**
 * 边框定义结构体
 */
struct Border {
    let color: Color
    let width: CGFloat
}

/**
 * 视图扩展 - 应用设计系统样式
 */
extension View {
    // 应用卡片样式
    func cardStyle() -> some View {
        self
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.Radius.card)
            .shadow(
                color: DesignSystem.Shadows.cardShadow.color,
                radius: DesignSystem.Shadows.cardShadow.radius,
                x: DesignSystem.Shadows.cardShadow.x,
                y: DesignSystem.Shadows.cardShadow.y
            )
    }
    
    // 应用轻微阴影
    func lightShadow() -> some View {
        self
            .shadow(
                color: DesignSystem.Shadows.lightShadow.color,
                radius: DesignSystem.Shadows.lightShadow.radius,
                x: DesignSystem.Shadows.lightShadow.x,
                y: DesignSystem.Shadows.lightShadow.y
            )
    }
    
    // 应用主按钮样式
    func primaryButtonStyle() -> some View {
        self
            .padding(.vertical, DesignSystem.Spacing.s)
            .padding(.horizontal, DesignSystem.Spacing.l)
            .background(DesignSystem.Colors.primary)
            .foregroundColor(.white)
            .cornerRadius(DesignSystem.Radius.button)
    }
    
    // 应用次要按钮样式
    func secondaryButtonStyle() -> some View {
        self
            .padding(.vertical, DesignSystem.Spacing.s)
            .padding(.horizontal, DesignSystem.Spacing.l)
            .background(DesignSystem.Colors.primary.opacity(0.1))
            .foregroundColor(DesignSystem.Colors.primary)
            .cornerRadius(DesignSystem.Radius.button)
    }
    
    // 温暖风格标签样式
    func warmTagStyle() -> some View {
        self
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
            .background(DesignSystem.Colors.primary.opacity(0.08))
            .foregroundColor(DesignSystem.Colors.primary)
            .cornerRadius(DesignSystem.Radius.s)
    }
}

/**
 * 通用缩放按钮样式
 * 提供轻微的缩放效果，用于创建有触感的按钮交互
 */
struct ScaleButtonStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.95
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(DesignSystem.Animations.quick, value: configuration.isPressed)
    }
} 