import SwiftUI
import Combine

/**
 * 键盘自适应视图修饰符
 * 用于自动处理键盘弹出和隐藏时的视图调整
 */
struct KeyboardAdaptive: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onAppear {
                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillShowNotification,
                    object: nil,
                    queue: .main
                ) { notification in
                    if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                        // 减去安全区域底部高度，避免重复计算
                        let safeAreaBottom = getSafeAreaBottom()
                        self.keyboardHeight = keyboardFrame.height - safeAreaBottom
                        // 确保键盘高度不为负数
                        self.keyboardHeight = max(0, self.keyboardHeight)
                    }
                }
                
                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillHideNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    self.keyboardHeight = 0
                }
            }
    }
    
    // 获取安全区域底部的高度，兼容iOS 15+
    private func getSafeAreaBottom() -> CGFloat {
        if #available(iOS 15.0, *) {
            // 使用新的API，筛选活跃的窗口场景
            let windowScenes = UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .compactMap { $0 as? UIWindowScene }
            
            if let windowScene = windowScenes.first,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                return window.safeAreaInsets.bottom
            }
        } else {
            // 兼容iOS 15以下版本
            if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                return window.safeAreaInsets.bottom
            }
        }
        return 0
    }
}

// 扩展View，添加键盘自适应修饰符
extension View {
    func keyboardAdaptive() -> some View {
        self.modifier(KeyboardAdaptive())
    }
} 