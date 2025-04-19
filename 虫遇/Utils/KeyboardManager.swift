import SwiftUI
import Combine

/**
 * 键盘管理器
 * 提供全局键盘状态管理和控制功能
 */
class KeyboardManager: ObservableObject {
    /// 单例实例
    static let shared = KeyboardManager()
    
    /// 键盘是否可见
    @Published var isVisible: Bool = false
    
    /// 键盘高度
    @Published var height: CGFloat = 0
    
    /// 键盘动画持续时间
    @Published var animationDuration: Double = 0.25
    
    /// 键盘动画曲线
    @Published var animationCurve: Int = UIView.AnimationCurve.easeInOut.rawValue
    
    /// 取消订阅存储
    private var cancellables = Set<AnyCancellable>()
    
    /// 私有初始化方法
    private init() {
        setupKeyboardObservers()
    }
    
    /**
     * 设置键盘观察者
     * 监听键盘显示和隐藏事件
     */
    private func setupKeyboardObservers() {
        // 监听键盘显示
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { [weak self] notification -> Void? in
                self?.handleKeyboardNotification(notification, isShowing: true)
                return ()
            }
            .sink { _ in }
            .store(in: &cancellables)
        
        // 监听键盘隐藏
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .compactMap { [weak self] notification -> Void? in
                self?.handleKeyboardNotification(notification, isShowing: false)
                return ()
            }
            .sink { _ in }
            .store(in: &cancellables)
    }
    
    /**
     * 处理键盘通知
     * @param notification - 键盘通知
     * @param isShowing - 键盘是否正在显示
     */
    private func handleKeyboardNotification(_ notification: Notification, isShowing: Bool) {
        // 获取键盘信息
        let userInfo = notification.userInfo
        
        // 更新键盘高度
        if let keyboardFrame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            height = isShowing ? keyboardFrame.height : 0
        }
        
        // 更新键盘动画信息
        if let animDuration = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
            animationDuration = animDuration
        }
        
        if let animCurve = userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int {
            animationCurve = animCurve
        }
        
        // 更新键盘可见状态
        isVisible = isShowing
    }
    
    /**
     * 关闭键盘
     * 发送resignFirstResponder消息使当前输入控件失去焦点
     */
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    /**
     * 获取键盘动画
     * 根据键盘的动画参数创建SwiftUI动画
     */
    var keyboardAnimation: Animation {
        let curve: Animation
        switch animationCurve {
        case UIView.AnimationCurve.easeIn.rawValue:
            curve = .easeIn
        case UIView.AnimationCurve.easeOut.rawValue:
            curve = .easeOut
        case UIView.AnimationCurve.linear.rawValue:
            curve = .linear
        default:
            curve = .easeInOut
        }
        
        return curve.speed(1.0 / animationDuration)
    }
}

/**
 * 键盘自适应环境对象
 * 用于在SwiftUI视图层次结构中共享键盘状态
 */
struct KeyboardEnvironmentKey: EnvironmentKey {
    static var defaultValue: KeyboardManager = .shared
}

extension EnvironmentValues {
    var keyboardManager: KeyboardManager {
        get { self[KeyboardEnvironmentKey.self] }
        set { self[KeyboardEnvironmentKey.self] = newValue }
    }
}

/**
 * 键盘监听修饰器
 * 用于监听键盘状态变化并执行回调
 */
struct KeyboardAwareModifier: ViewModifier {
    @ObservedObject var manager = KeyboardManager.shared
    var onChangeHeight: (CGFloat, Bool) -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: manager.height) { oldHeight, newHeight in
                onChangeHeight(newHeight, manager.isVisible)
            }
    }
}

extension View {
    /**
     * 监听键盘高度变化
     * @param perform - 键盘高度变化时执行的回调
     */
    func onKeyboardHeightChange(_ perform: @escaping (CGFloat, Bool) -> Void) -> some View {
        self.modifier(KeyboardAwareModifier(onChangeHeight: perform))
    }
    
    /**
     * 环境键盘管理器
     * 提供对键盘管理器的快捷访问
     */
    func environmentKeyboardManager() -> some View {
        self.environment(\.keyboardManager, KeyboardManager.shared)
    }
} 