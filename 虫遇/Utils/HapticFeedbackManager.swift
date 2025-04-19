import UIKit

/**
 * 触感反馈管理器
 * 提供跨应用使用的触感反馈功能
 */
class HapticFeedbackManager {
    /// 单例实例
    static let shared = HapticFeedbackManager()
    
    /// 私有初始化函数
    private init() {}
    
    /**
     * 触发轻度触感
     */
    func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /**
     * 触发中度触感
     */
    func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /**
     * 触发重度触感
     */
    func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /**
     * 触发成功触感
     */
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /**
     * 触发错误触感
     */
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
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
        HapticFeedbackManager.shared.light()
    }
    
    /**
     * 中度触感
     */
    static func medium() {
        HapticFeedbackManager.shared.medium()
    }
    
    /**
     * 重度触感
     */
    static func heavy() {
        HapticFeedbackManager.shared.heavy()
    }
    
    /**
     * 成功触感
     */
    static func success() {
        HapticFeedbackManager.shared.success()
    }
    
    /**
     * 错误触感
     */
    static func error() {
        HapticFeedbackManager.shared.error()
    }
}

