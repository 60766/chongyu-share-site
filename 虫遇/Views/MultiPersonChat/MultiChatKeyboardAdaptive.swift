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
                .onReceive(MultiChatKeyboardHeightPublisher()) { height in
                    print("MultiChatKeyboardAdaptive - 收到键盘高度: \(height)")
                    
                    withAnimation(animation) {
                        previousKeyboardHeight = keyboardHeight
                        
                        // 如果收到的高度为0且之前键盘是显示的，使用默认高度
                        if height == 0 && previousKeyboardHeight > 0 && !hasManuallySetKeyboardHeight {
                            print("MultiChatKeyboardAdaptive - 键盘高度为0，使用默认高度")
                            keyboardHeight = UIScreen.main.bounds.height * 0.35
                            hasManuallySetKeyboardHeight = true
                        } else {
                            keyboardHeight = height
                            hasManuallySetKeyboardHeight = false
                        }
                    }
                }
                .onAppear {
                    // 监听自定义通知
                    NotificationCenter.default.addObserver(forName: Notification.Name("MultiChatForceShowKeyboard"), object: nil, queue: .main) { notification in
                        if let height = notification.userInfo?["height"] as? CGFloat {
                            print("MultiChatKeyboardAdaptive - 收到强制显示键盘通知，高度: \(height)")
                            withAnimation(animation) {
                                keyboardHeight = height
                                hasManuallySetKeyboardHeight = true
                            }
                        }
                    }
                    
                    NotificationCenter.default.addObserver(forName: Notification.Name("MultiChatForceHideKeyboard"), object: nil, queue: .main) { _ in
                        print("MultiChatKeyboardAdaptive - 收到强制隐藏键盘通知")
                        withAnimation(animation) {
                            keyboardHeight = 0
                            hasManuallySetKeyboardHeight = false
                        }
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
                            print("MultiChatKeyboardAdaptive - 点击空白区域，关闭键盘")
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
        
        // 监听键盘显示通知
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification -> CGFloat? in
                print("MultiChatKeyboardHeightSubscription - 收到键盘显示通知")
                let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                let height = keyboardFrame?.height ?? 0
                
                // 如果高度为0，使用默认高度
                return height > 0 ? height : UIScreen.main.bounds.height * 0.35
            }
            .sink { [weak self] height in
                print("MultiChatKeyboardHeightSubscription - 发送键盘高度: \(height)")
                _ = self?.subscriber?.receive(height)
            }
            .store(in: &cancellables)
        
        // 监听键盘隐藏通知
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                print("MultiChatKeyboardHeightSubscription - 收到键盘隐藏通知")
                _ = self?.subscriber?.receive(0)
            }
            .store(in: &cancellables)
        
        // 监听自定义通知
        NotificationCenter.default
            .publisher(for: Notification.Name("MultiChatForceShowKeyboard"))
            .compactMap { notification -> CGFloat? in
                print("MultiChatKeyboardHeightSubscription - 收到强制显示键盘通知")
                return notification.userInfo?["height"] as? CGFloat ?? UIScreen.main.bounds.height * 0.35
            }
            .sink { [weak self] height in
                _ = self?.subscriber?.receive(height)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default
            .publisher(for: Notification.Name("MultiChatForceHideKeyboard"))
            .sink { [weak self] _ in
                print("MultiChatKeyboardHeightSubscription - 收到强制隐藏键盘通知")
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