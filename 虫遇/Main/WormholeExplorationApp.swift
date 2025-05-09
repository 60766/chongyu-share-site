import SwiftUI
// 移除对模块自身的导入，添加必要的模块导入
// import 虫遇

/**
 * 虫洞探索应用程序入口
 */
// 移除@main属性
struct WormholeExplorationApp: App {
    var body: some Scene {
        WindowGroup {
            WormholeExplorationView()
        }
    }
} 