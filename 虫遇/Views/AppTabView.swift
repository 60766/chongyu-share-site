import SwiftUI

/**
 * 应用主标签视图
 * 负责协调不同标签页之间的切换
 * 优化设计：高透明度底部导航栏，更轻量化中央按钮
 */
struct AppTabView: View {
    @State private var selectedTab = 0
    
    // 用于控制发布面板显示
    @State private var isPublishButtonPressed = false
    @State private var showPublishPanel = false
    // 调试模式
    @State private var showDebugView = false
    // TabBar可见性管理器
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    var body: some View {
        // 主容器
        ZStack(alignment: .bottom) {
            // 主内容区域 - 使用修改过的TabView确保内容能延伸到底部
            TabView(selection: $selectedTab) {
                // 首页 - 虫遇主界面
                HomeView()
                    .tag(0)
                    .onAppear {
                        if selectedTab == 0 {
                            ensureTabBarVisible()
                        }
                    }
                
                // 探索页
                ExploreView()
                    .tag(1)
                    .onAppear {
                        // 确保TabBar可见
                        ensureTabBarVisible()
                    }
                
                // 占位符视图 (不显示，仅为中间按钮预留空间)
                // 移除这个标签页，避免点击中间区域导致显示空白页面
                
                // 通知页
                NotificationView()
                    .tag(3)
                    .onAppear {
                        // 确保TabBar可见
                        ensureTabBarVisible()
                    }
                
                // 用户空间页
                ProfileView()
                    .tag(4)
                    .onAppear {
                        // 确保TabBar可见
                        ensureTabBarVisible()
                        
                        // ProfileView在onAppear中自行重置状态
                    }
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                // 特殊处理：当切换回首页时，确保数据恢复
                if newValue == 0 {
                    // HomeView将自行在onAppear中处理刷新
                }
                
                // 特殊处理：如果尝试选择中间标签(2)，则不执行任何操作
                if newValue == 2 {
                    // 恢复到之前的标签
                    selectedTab = oldValue
                }
                
                // 确保TabBar可见
                ensureTabBarVisible()
            }
            // 改用TabViewStyle禁用水平滑动翻页功能
            .tabViewStyle(.automatic)
            // 确保内容区域无白线分割
            .background(Color.clear)
            
        }
        // 将TabBar作为overlay添加
        .overlay(alignment: .bottom) {
            if !tabBarManager.isFullyHidden {
                // 使用ZStack实现磨砂玻璃效果，确保内容能够透过显示
                ZStack(alignment: .bottom) {
                    // 导航栏包装器 - 使用真正的磨砂玻璃效果模糊下方内容
                    ZStack(alignment: .center) {
                        // 底部导航栏 - 使用优化后的模糊效果
                        CustomTabBarView(selectedTab: $selectedTab)
                            .frame(height: tabBarManager.tabBarHeight) // 使用管理器中的高度
                            .opacity(tabBarManager.isVisible ? 1 : 0)
                        
                        // 虫洞发布按钮 - 位置微调，更轻量化
                        CosmicPublishButton(isPressed: $isPublishButtonPressed) {
                            // 移除动画效果，直接显示
                            showPublishPanel = true
                        }
                        .scaleEffect(0.45) // 保持减小的比例
                        .offset(y: -6) // 保持位置
                        .shadow(color: Color.primaryColor.opacity(0.4), radius: 12, x: 0, y: 0) // 减轻阴影
                        .environment(\.colorScheme, .dark) // 确保在深色模式下发光效果更明显
                        .opacity(tabBarManager.isVisible && tabBarManager.showFloatingButtons ? 1 : 0) // 与导航栏和浮动按钮状态关联
                    }
                }
                // 将导航栏层级提高，但保持下方内容可见
                .zIndex(1)
            }
        }
        .overlay(
            PublishPanelView(isVisible: $showPublishPanel)
                .environment(\.colorScheme, .light) // 显式设置亮色模式
        )
        // 调试入口 - 长按顶部区域可以打开调试视图
        .overlay(alignment: .top) {
            Color.clear
                .frame(height: 60)
                .contentShape(Rectangle())
                .allowsHitTesting(false) // 确保不阻止点击事件传递到下层视图
                .onLongPressGesture(minimumDuration: 2) {
                    showDebugView = true
                }
        }
        // 调试视图弹窗
        .sheet(isPresented: $showDebugView) {
            NavigationView {
                DebugTestView()
                    .navigationTitle("调试")
                    .navigationBarItems(trailing: Button("关闭") {
                        showDebugView = false
                    })
            }
        }
        // 统一的安全区域设置 - 只设置一次，移除所有重复设置
        .ignoresSafeArea(.all, edges: .bottom)
        .environmentObject(tabBarManager) // 确保TabBarManager在所有子视图中可用
        .onAppear {
            // 🚀 性能优化：直接设置TabBarController引用，避免递归搜索
            setupTabBarControllerReference()
            
            // 添加通知监听，处理返回首页的请求
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("NavigateToHomeTab"),
                object: nil,
                queue: .main
            ) { _ in
                // 切换到首页标签
                withAnimation {
                    selectedTab = 0
                }
            }
            
            // 确保TabBar可见
            ensureTabBarVisible()
            
            // 启用调试模式
            #if DEBUG
            tabBarManager.enableDebugMode()
            #endif
        }
    }
    
    /// 🚀 性能优化：设置TabBarController直接引用
    private func setupTabBarControllerReference() {
        // 延迟一点时间确保视图层次已经建立
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 获取当前窗口的TabBarController
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let tabBarController = self.findTabBarControllerInHierarchy(from: window.rootViewController) {
                
                // 直接设置引用，避免后续所有递归搜索
                self.tabBarManager.setTabBarController(tabBarController)
                
                #if DEBUG
                print("🚀 性能优化生效：TabBarController直接引用已建立")
                #endif
            }
        }
    }
    
    /// 🚀 性能优化：一次性搜索TabBarController（仅在设置时使用）
    private func findTabBarControllerInHierarchy(from viewController: UIViewController?) -> UITabBarController? {
        guard let viewController = viewController else { return nil }
        
        if let tabBarController = viewController as? UITabBarController {
            return tabBarController
        }
        
        for child in viewController.children {
            if let found = findTabBarControllerInHierarchy(from: child) {
                return found
            }
        }
        
        if let presentedVC = viewController.presentedViewController {
            return findTabBarControllerInHierarchy(from: presentedVC)
        }
        
        return nil
    }
    
    /// 确保TabBar可见的辅助方法
    private func ensureTabBarVisible() {
        // 立即强制显示TabBar，不使用任何延迟
        if !tabBarManager.isVisible || tabBarManager.isFullyHidden {
            tabBarManager.showImmediately()
        }
    }
}

/**
 * 预览提供者
 */
struct AppTabView_Previews: PreviewProvider {
    static var previews: some View {
        AppTabView()
    }
} 
