import SwiftUI

/**
 * 虫洞探索应用程序入口
 * 这是虫遇应用的一个子模块视图
 */
struct WormholeExplorationApp: App {
    // 是否显示调试菜单
    @State private var showDebugMenu = false
    
    // 应用初始化
    init() {
        print("🚀 应用启动 - 初始化资源")
        // 复制历史人物图片到运行时目录
        HistoricalFigureImageCopier.shared.copyAllImages()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                WormholeExplorationView()
                
                // 添加调试按钮
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showDebugMenu.toggle()
                        }) {
                            Image(systemName: "ladybug.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                                .shadow(radius: 3)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .sheet(isPresented: $showDebugMenu) {
                DebugMenuView()
            }
            .provideBottomSafeAreaHeight() // 提供底部安全区域高度
            .provideSafeAreaInsets() // 提供全部安全区域尺寸
        }
    }
} 