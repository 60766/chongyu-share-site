import SwiftUI

/**
 * 环境值键：底部安全区域高度
 * 用于全局传递底部安全区域高度值
 */
private struct BottomSafeAreaHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

/**
 * 扩展环境值以支持底部安全区域高度
 */
extension EnvironmentValues {
    var bottomSafeAreaHeight: CGFloat {
        get { self[BottomSafeAreaHeightKey.self] }
        set { self[BottomSafeAreaHeightKey.self] = newValue }
    }
}

/**
 * 扩展View提供底部安全区域处理方法
 */
extension View {
    /**
     * 提供底部安全区域高度到环境中
     */
    func provideBottomSafeAreaHeight() -> some View {
        self.modifier(BottomSafeAreaHeightProvider())
    }
    
    /**
     * 完全扩展视图到屏幕底部，消除所有安全区域间距
     */
    func extendToScreenBottom() -> some View {
        self.modifier(ScreenBottomExtender())
    }
    
    /**
     * 修复可能出现的底部空白问题
     */
    func fixBottomSpace() -> some View {
        self.modifier(BottomSpaceFixer())
    }
    
    /**
     * 添加TabBar安全区域填充
     * 确保内容不被TabBar遮挡
     */
    func withTabBarSafeArea() -> some View {
        self.modifier(TabBarSafeAreaPadding())
    }
}

/**
 * 底部安全区域高度提供器
 */
struct BottomSafeAreaHeightProvider: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .environment(\.bottomSafeAreaHeight, geometry.safeAreaInsets.bottom)
                .onAppear {
                    // 调试信息：打印底部安全区域高度
                    #if DEBUG
                    print("底部安全区域高度: \(geometry.safeAreaInsets.bottom)px")
                    #endif
                }
        }
    }
}

/**
 * 屏幕底部扩展修饰器
 */
struct ScreenBottomExtender: ViewModifier {
    @Environment(\.bottomSafeAreaHeight) var bottomSafeAreaHeight
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .edgesIgnoringSafeArea(.bottom)
            .padding(.bottom, -bottomSafeAreaHeight) // 抵消底部安全区域
            .background(
                Color.clear // 使用完全透明的背景
                    .edgesIgnoringSafeArea(.all)
            )
    }
}

/**
 * 底部空间修复器
 */
struct BottomSpaceFixer: ViewModifier {
    func body(content: Content) -> some View {
        content
            .edgesIgnoringSafeArea(.bottom)
            .padding(.bottom, 0) // 确保没有底部内边距
    }
}

/**
 * TabBar安全区域填充修饰符
 * 为内容视图添加底部填充，确保内容不被TabBar遮挡
 */
struct TabBarSafeAreaPadding: ViewModifier {
    // 使用共享的TabBarManager
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            // 仅当TabBar可见时才添加底部填充
            if tabBarManager.isVisible && !tabBarManager.isFullyHidden {
                VStack {
                    Spacer()
                    // 底部填充 - 使用最小必要高度，并确保完全透明
                    Color.clear
                        .frame(height: max(0, tabBarManager.tabBarHeight - 5)) // 减少5点高度，防止额外间距
                }
                .allowsHitTesting(false) // 允许点击事件穿透
            }
        }
    }
}

/**
 * 安全区域插入键
 */
struct SafeAreaInsetsKey: PreferenceKey {
    static var defaultValue: EdgeInsets = EdgeInsets()
    
    static func reduce(value: inout EdgeInsets, nextValue: () -> EdgeInsets) {
        value = nextValue()
    }
}