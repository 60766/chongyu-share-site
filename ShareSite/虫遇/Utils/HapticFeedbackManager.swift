import UIKit

/**
 * 触觉反馈管理类
 * 提供统一的触觉反馈方法，提高用户交互体验
 */
class HapticFeedbackManager {
    
    // 单例模式
    static let shared = HapticFeedbackManager()
    
    // 防止外部创建实例
    private init() {}
    
    // 不同类型的触觉引擎
    private lazy var impactLight = UIImpactFeedbackGenerator(style: .light)
    private lazy var impactMedium = UIImpactFeedbackGenerator(style: .medium) 
    private lazy var impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private lazy var selection = UISelectionFeedbackGenerator()
    private lazy var notification = UINotificationFeedbackGenerator()
    
    // 准备触觉引擎（可在即将需要时提前调用以减少延迟）
    func prepare(style: FeedbackStyle = .medium) {
        switch style {
        case .light:
            impactLight.prepare()
        case .medium: 
            impactMedium.prepare()
        case .heavy:
            impactHeavy.prepare()
        case .selection:
            selection.prepare()
        case .notification:
            notification.prepare()
        }
    }
    
    /**
     * 触发轻微触觉反馈
     * 适合于轻微的UI交互，如点击按钮
     * @param intensity 强度，范围0.0-1.0
     */
    func lightImpact(intensity: CGFloat = 1.0) {
        impactLight.impactOccurred(intensity: intensity)
    }
    
    /**
     * 触发中等触觉反馈
     * 适合于一般的UI交互，如打开菜单
     * @param intensity 强度，范围0.0-1.0
     */
    func mediumImpact(intensity: CGFloat = 1.0) {
        impactMedium.impactOccurred(intensity: intensity)
    }
    
    /**
     * 触发强烈触觉反馈
     * 适合于重要的UI交互，如确认操作
     * @param intensity 强度，范围0.0-1.0
     */
    func heavyImpact(intensity: CGFloat = 1.0) {
        impactHeavy.impactOccurred(intensity: intensity)
    }
    
    /**
     * 触发选择触觉反馈
     * 适合于UI选择变化，如滑动到新选项
     */
    func selectionChanged() {
        selection.selectionChanged()
    }
    
    /**
     * 触发成功通知触觉反馈
     * 适合于操作成功时的提示
     */
    func notifySuccess() {
        notification.notificationOccurred(.success)
    }
    
    /**
     * 触发警告通知触觉反馈
     * 适合于需要用户注意的情况
     */
    func notifyWarning() {
        notification.notificationOccurred(.warning)
    }
    
    /**
     * 触发错误通知触觉反馈
     * 适合于操作失败或错误
     */
    func notifyError() {
        notification.notificationOccurred(.error)
    }
    
    /**
     * 触发菜单项触觉反馈
     * 适合于菜单项点击
     */
    func menuSelection() {
        impactMedium.impactOccurred(intensity: 0.5)
    }
    
    /**
     * 按钮点击反馈
     * 适合于一般按钮点击反馈
     */
    func buttonTap() {
        impactLight.impactOccurred(intensity: 0.5)
    }
    
    // 反馈样式枚举
    enum FeedbackStyle {
        case light, medium, heavy, selection, notification
    }
}

/**
 * 触感反馈工具类
 * 提供静态方法，方便直接调用
 */
struct HapticFeedback {
    /**
     * 轻度触感
     */
    static func light() {
        HapticFeedbackManager.shared.lightImpact()
    }
    
    /**
     * 中度触感
     */
    static func medium() {
        HapticFeedbackManager.shared.mediumImpact()
    }
    
    /**
     * 重度触感
     */
    static func heavy() {
        HapticFeedbackManager.shared.heavyImpact()
    }
    
    /**
     * 成功触感
     */
    static func success() {
        HapticFeedbackManager.shared.notifySuccess()
    }
    
    /**
     * 错误触感
     */
    static func error() {
        HapticFeedbackManager.shared.notifyError()
    }
}

