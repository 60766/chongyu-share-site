import SwiftUI
import UIKit
// 引用具体文件更加明确
// import 虫遇

struct MainView: View {
    // 添加必要的状态变量
    @State private var selectedTab = 0
    @ObservedObject private var tabBarManager = TabBarManager.shared
    @State private var hideAllUI = false
    
    // 获取安全区域
    var safeAreaInsets: EdgeInsets {
        if #available(iOS 15.0, *) {
            // iOS 15及以上使用UIWindowScene.windows
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                return EdgeInsets()
            }
            let insets = window.safeAreaInsets
            return EdgeInsets(
                top: insets.top,
                leading: insets.left,
                bottom: insets.bottom,
                trailing: insets.right
            )
        } else {
            // iOS 15以下使用旧API
            let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
            let insets = window?.safeAreaInsets ?? UIEdgeInsets()
            return EdgeInsets(
                top: insets.top,
                leading: insets.left,
                bottom: insets.bottom,
                trailing: insets.right
            )
        }
    }
    
    // 自定义标签栏视图
    var customTabBar: some View {
        HStack(spacing: 0) {
            // 标签按钮
            Button(action: { selectedTab = 0 }) {
                VStack {
                    Image(systemName: "house.fill")
                    Text("首页")
                }
            }
            .frame(maxWidth: .infinity)
            
            Button(action: { selectedTab = 1 }) {
                VStack {
                    Image(systemName: "magnifyingglass")
                    Text("探索")
                }
            }
            .frame(maxWidth: .infinity)
            
            Button(action: { selectedTab = 2 }) {
                VStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40))
                }
            }
            .frame(maxWidth: .infinity)
            
            Button(action: { selectedTab = 3 }) {
                VStack {
                    Image(systemName: "bell.fill")
                    Text("通知")
                }
            }
            .frame(maxWidth: .infinity)
            
            Button(action: { selectedTab = 4 }) {
                VStack {
                    Image(systemName: "person.fill")
                    Text("我的")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 10)
        .background(
            MainBlurView(style: .systemMaterial)
        )
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 主标签视图
            TabView(selection: $selectedTab) {
                // 首页视图
                Text("首页内容")
                    .tag(0)
                
                // 探索视图
                Text("探索内容")
                    .tag(1)
                
                // 发布视图
                Text("发布内容")
                    .tag(2)
                
                // 通知视图
                Text("通知内容")
                    .tag(3)
                
                // 我的视图
                Text("我的内容")
                    .tag(4)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(nil, value: UUID()) // 使用value参数来满足iOS 15要求
            .transition(AnyTransition.identity)

            // 底部导航栏
            customTabBar
                .padding(.bottom, safeAreaInsets.bottom)
                .opacity(tabBarManager.isVisible ? 1 : 0)
                .opacity(hideAllUI ? 0 : 1)
                .animation(.easeInOut(duration: 0.2), value: tabBarManager.isVisible)
                .animation(.easeInOut(duration: 0.2), value: hideAllUI)
            
            // 全局Toast视图
            ToastView()
                .edgesIgnoringSafeArea(.bottom)
                .zIndex(100) // 确保Toast显示在最上层
        }
    }
    
    // 自定义模糊视图以避免名称冲突
    struct MainBlurView: UIViewRepresentable {
        var style: UIBlurEffect.Style
        
        func makeUIView(context: Context) -> UIVisualEffectView {
            let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
            return view
        }
        
        func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
            uiView.effect = UIBlurEffect(style: style)
        }
    }
}

// 从项目中已存在的BlurView中导入，不再重复定义 