import SwiftUI
import Combine

/**
 * MultiChatKeyboardAdaptive 是专门为梦幻联动设计的键盘适配修饰器，
 * 基于 KeyboardAdaptive 但添加了更多的调试和手动键盘高度处理逻辑。
 */
struct MultiChatKeyboardAdaptive: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    @State private var previousKeyboardHeight: CGFloat = 0
    @State private var hasManuallySetKeyboardHeight: Bool = false
    
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
                // 直接监听键盘通知，获取系统动画参数，确保与键盘动画完全同步
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                    guard let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                        return
                    }
                    
                    // 获取系统键盘的动画参数
                    let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
                    let curveValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 7
                    
                    // 计算键盘高度
                    let screenHeight = UIScreen.main.bounds.height
                    let height: CGFloat
                    if endFrame.origin.y >= screenHeight {
                        height = 0
                    } else {
                        height = max(0, screenHeight - endFrame.origin.y)
                    }
                    
                    #if DEBUG
                    print("MultiChatKeyboardAdaptive - 键盘 frame 变化，高度: \(height), 动画时长: \(duration)")
                    #endif
                    
                        previousKeyboardHeight = keyboardHeight
                    
                    // 将 UIView 动画曲线转换为 SwiftUI Animation
                    // UIView.AnimationCurve 7 = easeInOut
                    let swiftUIAnimation: Animation
                    switch curveValue {
                    case 6: // easeIn
                        swiftUIAnimation = .easeIn(duration: duration)
                    case 7: // easeInOut
                        swiftUIAnimation = .easeInOut(duration: duration)
                    case 8: // easeOut
                        swiftUIAnimation = .easeOut(duration: duration)
                    default:
                        swiftUIAnimation = .easeInOut(duration: duration)
                    }
                        
                        // 只在模拟器环境下使用默认高度，真机直接使用系统提供的高度
                        #if targetEnvironment(simulator)
                        // 如果收到的高度为0且之前键盘是显示的，使用默认高度（仅模拟器）
                        if height == 0 && previousKeyboardHeight > 0 && !hasManuallySetKeyboardHeight {
                            #if DEBUG
                            print("MultiChatKeyboardAdaptive - 模拟器环境，键盘高度为0，使用默认高度")
                            #endif
                        withAnimation(swiftUIAnimation) {
                            keyboardHeight = UIScreen.main.bounds.height * 0.35
                        }
                            hasManuallySetKeyboardHeight = true
                        } else {
                        // 使用系统键盘的动画参数更新高度，确保完全同步
                        withAnimation(swiftUIAnimation) {
                            keyboardHeight = height
                        }
                            hasManuallySetKeyboardHeight = false
                        }
                        #else
                    // 真机环境直接使用系统提供的键盘高度，使用系统键盘的动画参数确保完全同步
                    withAnimation(swiftUIAnimation) {
                        keyboardHeight = height
                    }
                    hasManuallySetKeyboardHeight = false
                    #endif
                }
                .onAppear {
                    #if DEBUG
                    print("MultiChatKeyboardAdaptive - 视图出现，准备监听键盘通知")
                    #endif
                    
                    // 监听自定义通知
                    NotificationCenter.default.addObserver(forName: Notification.Name("MultiChatForceShowKeyboard"), object: nil, queue: .main) { notification in
                        if let height = notification.userInfo?["height"] as? CGFloat {
                            #if DEBUG
                            print("MultiChatKeyboardAdaptive - 收到强制显示键盘通知，高度: \(height)")
                            #endif
                            // 立即更新，不使用动画，确保第一次打开时也能正确贴合
                                keyboardHeight = height
                                hasManuallySetKeyboardHeight = true
                        }
                    }
                    
                    NotificationCenter.default.addObserver(forName: Notification.Name("MultiChatForceHideKeyboard"), object: nil, queue: .main) { _ in
                        #if DEBUG
                        print("MultiChatKeyboardAdaptive - 收到强制隐藏键盘通知")
                        #endif
                        // 立即更新，不使用动画
                            keyboardHeight = 0
                            hasManuallySetKeyboardHeight = false
                    }
                }
                .onDisappear {
                    // 移除自定义通知观察者
                    NotificationCenter.default.removeObserver(self, name: Notification.Name("MultiChatForceShowKeyboard"), object: nil)
                    NotificationCenter.default.removeObserver(self, name: Notification.Name("MultiChatForceHideKeyboard"), object: nil)
                }
            
            // 仅当启用dismissOnTap且键盘可见时添加全屏覆盖层用于点击关闭键盘
            if dismissOnTap && keyboardHeight > 0 {
                GeometryReader { geometry in
                    Color.black.opacity(0.001) // 几乎完全透明
                        .contentShape(Rectangle())
                        .onTapGesture {
                            #if DEBUG
                            print("MultiChatKeyboardAdaptive - 点击空白区域，关闭键盘")
                            #endif
                            // 关闭键盘
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            
                            // 发送自定义通知
                            NotificationCenter.default.post(name: Notification.Name("MultiChatForceHideKeyboard"), object: nil)
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
     * 使视图适配梦幻联动的键盘高度
     */
    func multiChatKeyboardAdaptive(
        enabled: Bool = true,
        adjustLayout: Bool = true,
        dismissOnTap: Bool = false,
        animation: Animation? = .easeInOut(duration: 0.25),
        safeArea: CGFloat = 16
    ) -> some View {
        modifier(MultiChatKeyboardAdaptive(
            enabled: enabled,
            adjustLayout: adjustLayout,
            dismissOnTap: dismissOnTap,
            animation: animation,
            safeArea: safeArea
        ))
    }
}

/// 专门为梦幻联动设计的键盘高度发布器
class MultiChatKeyboardHeightPublisher: Publisher {
    typealias Output = CGFloat
    typealias Failure = Never
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = MultiChatKeyboardHeightSubscription(subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
}

class MultiChatKeyboardHeightSubscription<S: Subscriber>: Subscription where S.Input == CGFloat, S.Failure == Never {
    var subscriber: S?
    var cancellables = Set<AnyCancellable>()
    
    init(subscriber: S) {
        self.subscriber = subscriber
        
        // 监听键盘 frame 变化，兼容 iOS 16+ 的"下滑收起键盘"等交互，更可靠
        // 使用 keyboardWillChangeFrameNotification 确保第一次打开时也能立即获取高度
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .compactMap { notification -> CGFloat? in
                guard let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return nil
                }
                
                // keyboard frame 是屏幕坐标系，y >= 屏幕高度表示完全隐藏
                let screenHeight = UIScreen.main.bounds.height
                let height: CGFloat
                if endFrame.origin.y >= screenHeight {
                    height = 0
                } else {
                    // 键盘高度 = 屏幕底部到键盘顶端的距离
                    height = max(0, screenHeight - endFrame.origin.y)
                }
                
                #if DEBUG
                print("MultiChatKeyboardHeightSubscription - 键盘 frame 变化，高度: \(height)")
                #endif
                return height
            }
            .sink { [weak self] height in
                #if DEBUG
                print("MultiChatKeyboardHeightSubscription - 发送键盘高度: \(height)")
                #endif
                _ = self?.subscriber?.receive(height)
            }
            .store(in: &cancellables)
        
        // 监听键盘隐藏通知
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                #if DEBUG
                print("MultiChatKeyboardHeightSubscription - 收到键盘隐藏通知")
                #endif
                _ = self?.subscriber?.receive(0)
            }
            .store(in: &cancellables)
        
        // 监听自定义通知
        NotificationCenter.default
            .publisher(for: Notification.Name("MultiChatForceShowKeyboard"))
            .compactMap { notification -> CGFloat? in
                #if DEBUG
                print("MultiChatKeyboardHeightSubscription - 收到强制显示键盘通知")
                #endif
                return notification.userInfo?["height"] as? CGFloat ?? UIScreen.main.bounds.height * 0.35
            }
            .sink { [weak self] height in
                _ = self?.subscriber?.receive(height)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default
            .publisher(for: Notification.Name("MultiChatForceHideKeyboard"))
            .sink { [weak self] _ in
                #if DEBUG
                print("MultiChatKeyboardHeightSubscription - 收到强制隐藏键盘通知")
                #endif
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