import SwiftUI

/**
 * @description 滚动偏移量偏好键，用于跟踪ScrollView的滚动位置
 */
struct AppScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/**
 * @description 内容宽度偏好键，用于测量ScrollView内容的总宽度
 */
struct ContentWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/**
 * @description 可见宽度偏好键，用于测量ScrollView可见区域的宽度
 */
struct ViewportWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
} 

/**
 * @description 安全区域插入键，用于获取视图的安全区域值
 */
struct AppSafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets? = nil
}

// 添加环境值扩展
extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets? {
        get { self[AppSafeAreaInsetsKey.self] }
        set { self[AppSafeAreaInsetsKey.self] = newValue }
    }
}

// 添加视图扩展，提供安全区域值
extension View {
    func provideSafeAreaInsets() -> some View {
        modifier(SafeAreaInsetsModifier())
    }
}

// 安全区域修饰器
struct SafeAreaInsetsModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ViewSafeAreaInsetsPreferenceKey.self,
                    value: geometry.safeAreaInsets
                )
            }
        )
        .onPreferenceChange(ViewSafeAreaInsetsPreferenceKey.self) { insets in
            DispatchQueue.main.async {
                SafeAreaInsetsManager.shared.update(insets: insets)
            }
        }
        .environment(\.safeAreaInsets, SafeAreaInsetsManager.shared.insets)
    }
}

// 安全区域偏好键
struct ViewSafeAreaInsetsPreferenceKey: PreferenceKey {
    static var defaultValue = EdgeInsets()
    
    static func reduce(value: inout EdgeInsets, nextValue: () -> EdgeInsets) {
        value = nextValue()
    }
}

// 安全区域管理器
class SafeAreaInsetsManager: ObservableObject {
    static let shared = SafeAreaInsetsManager()
    
    @Published var insets: EdgeInsets = EdgeInsets()
    
    func update(insets: EdgeInsets) {
        self.insets = insets
    }
} 