//
//  __App.swift
//  虫遇
//
//  Created by 李世龙 on 2025/3/18.
//

import SwiftUI
import SwiftData
import UIKit
import StoreKit

// AppDelegate已经存在，不再重复声明

@main
struct ChongYuApp: App {
    // 添加AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // 添加 StoreKit 管理器
    @StateObject private var storeKitManager = StoreKitManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Character.self,
            User.self,
            Message.self,
            SDConversation.self,
            Post.self,
            Comment.self,
            MultiPersonChatSession.self,
            MultiPersonChatMessage.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("无法创建ModelContainer: \(error)")
        }
    }()

    init() {
        let initStartTime = CFAbsoluteTimeGetCurrent()
        
        // 设置应用外观
        setupAppearance()
        
        // 初始化API配置
        setupAPIConfig()
        
        // 执行关注数据迁移
        if FollowDataMigration.shared.shouldMigrate() {
            FollowDataMigration.shared.migrateFollowData()
        }
        
        // 初始化用户点赞服务
        _ = UserLikeService.shared
        
        // 初始化全局点赞状态管理器
        _ = LikeStateManager.shared
        
        // ⚡️ 优化：异步执行历史人物图片复制，不阻塞启动
        DispatchQueue.global(qos: .utility).async {
            HistoricalFigureImageCopier.shared.copyAllImages()
        }
        
        #if DEBUG
        let initTime = (CFAbsoluteTimeGetCurrent() - initStartTime) * 1000
        let totalTime = (CFAbsoluteTimeGetCurrent() - AppDelegate.appStartTime) * 1000
        print("⚡️ 应用启动完成")
        print("📊 性能统计:")
        print("   - init()耗时: \(String(format: "%.0f", initTime))ms")
        print("   - 总启动耗时: \(String(format: "%.0f", totalTime))ms")
        #endif
    }
    var body: some Scene {
        WindowGroup {
            AppTabView()
                .environmentObject(CreationTypeManager.shared)
                .environmentObject(storeKitManager)
                .task {
                    // StoreKit 测试
                    #if DEBUG
                    print("[APP] 开始加载 StoreKit 产品...")
                    #endif
                    await storeKitManager.loadProducts()
                    #if DEBUG
                    print("[APP] StoreKit 产品加载完成: \(storeKitManager.products.count) 个")
                    #endif
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func setupAppearance() {
        // 配置导航栏外观 - 使用透明配置避免白色背景遮盖
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground() // 改用透明背景配置
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // 设置导航栏标题颜色
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)]
        
        // 设置窗口背景为透明，解决底部白色区域问题
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.backgroundColor = .clear
        }
        
        // 全局设置TabBar背景为透明
        UITabBar.appearance().backgroundColor = .clear
        UITabBar.appearance().barTintColor = .clear
        UITabBar.appearance().isTranslucent = true
    }
    
    private func setupAPIConfig() {
        // API配置管理器已自动处理密钥设置
        #if DEBUG
        print("🔑 API配置管理器已自动初始化")
        #endif
        
        // 自动API测试已删除以节省API调用费用
    }
}
