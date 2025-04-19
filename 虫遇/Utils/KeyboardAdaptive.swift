import SwiftUI
import Combine

/**
 * KeyboardAdaptive是一个视图修饰器，用于自动调整视图以适应键盘的显示和隐藏。
 * 
 * @param enabled - 是否启用键盘适应，默认为true
 * @param adjustLayout - 是否调整内容布局（上移），默认为true
 * @param dismissOnTap - 是否在点击空白处时关闭键盘，默认为false
 * @param animation - 键盘高度变化时的动画，默认为easeInOut
 * @param safeArea - 点击关闭键盘时的安全区域，防止误触，默认为16pt
 */
struct KeyboardAdaptive: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    @State private var previousKeyboardHeight: CGFloat = 0
    
    /**
     * enabled：是否启用键盘适配功能
     * adjustLayout：是否根据键盘高度调整布局（当为false时，只是记录键盘状态但不会影响布局）
     * dismissOnTap：是否在点击空白处时关闭键盘
     * animation：键盘高度变化时的动画
     * safeArea：点击关闭键盘时的安全区域，防止误触
     */
    let enabled: Bool
    let adjustLayout: Bool
    let dismissOnTap: Bool
    let animation: Animation?
    let safeArea: CGFloat
    
    init(
        enabled: Bool = true, 
        adjustLayout: Bool = true,
        dismissOnTap: Bool = false,
        animation: Animation? = .easeInOut(duration: 0.25),
        safeArea: CGFloat = 16
    ) {
        self.enabled = enabled
        self.adjustLayout = adjustLayout
        self.dismissOnTap = dismissOnTap
        self.animation = animation
        self.safeArea = safeArea
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .padding(.bottom, enabled && adjustLayout ? keyboardHeight : 0)
                .onReceive(KeyboardHeightPublisher()) { height in
                    withAnimation(animation) {
                        previousKeyboardHeight = keyboardHeight
                        keyboardHeight = height
                    }
                }
            
            // 仅当启用dismissOnTap且键盘可见时添加全屏覆盖层用于点击关闭键盘
            if dismissOnTap && keyboardHeight > 0 {
                GeometryReader { geometry in
                    Color.black.opacity(0.001) // 几乎完全透明
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // 关闭键盘
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        // 设置安全区域，避免点击到主要内容
                        .padding(.all, safeArea)
                        // 确保覆盖层位于键盘上方
                        .frame(height: geometry.size.height - keyboardHeight)
                }
                .edgesIgnoringSafeArea(.all)
            }
        }
    }
}

extension View {
    /**
     * 使视图适配键盘高度
     * - Parameters:
     *   - enabled: 是否启用键盘适配功能
     *   - adjustLayout: 是否根据键盘高度调整布局
     *   - dismissOnTap: 是否在点击空白处时关闭键盘
     *   - animation: 键盘高度变化时的动画
     *   - safeArea: 点击关闭键盘时的安全区域，防止误触
     */
    func keyboardAdaptive(
        enabled: Bool = true,
        adjustLayout: Bool = true,
        dismissOnTap: Bool = false,
        animation: Animation? = .easeInOut(duration: 0.25),
        safeArea: CGFloat = 16
    ) -> some View {
        modifier(KeyboardAdaptive(
            enabled: enabled,
            adjustLayout: adjustLayout,
            dismissOnTap: dismissOnTap,
            animation: animation,
            safeArea: safeArea
        ))
    }
}

/// 发布键盘高度变化的Publisher
class KeyboardHeightPublisher: Publisher {
    typealias Output = CGFloat
    typealias Failure = Never
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = KeyboardHeightSubscription(subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
}

class KeyboardHeightSubscription<S: Subscriber>: Subscription where S.Input == CGFloat, S.Failure == Never {
    var subscriber: S?
    var cancellables = Set<AnyCancellable>()
    
    init(subscriber: S) {
        self.subscriber = subscriber
        
        // 监听键盘显示通知
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification -> CGFloat? in
                let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                return keyboardFrame?.height
            }
            .sink { [weak self] height in
                _ = self?.subscriber?.receive(height)
            }
            .store(in: &cancellables)
        
        // 监听键盘隐藏通知
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                _ = self?.subscriber?.receive(0)
            }
            .store(in: &cancellables)
    }
    
    func request(_ demand: Subscribers.Demand) {}
    
    func cancel() {
        subscriber = nil
        cancellables = []
    }
}

// MARK: - 添加键盘工具扩展

extension Publishers {
    /// 键盘高度变化的Publisher
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        KeyboardHeightPublisher()
            .eraseToAnyPublisher()
    }
    
    /// 键盘是否可见的Publisher
    static var keyboardVisible: AnyPublisher<Bool, Never> {
        KeyboardHeightPublisher()
            .map { $0 > 0 }
            .eraseToAnyPublisher()
    }
}