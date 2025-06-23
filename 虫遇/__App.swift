//
//  __App.swift
//  虫遇
//
//  Created by 李世龙 on 2025/3/18.
//

import SwiftUI
import SwiftData
import UIKit

// AppDelegate已经存在，不再重复声明

@main
struct ChongYuApp: App {
    // 添加AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Character.self,
            User.self,
            Message.self,
            SDConversation.self,
            Post.self,
            Comment.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("无法创建ModelContainer: \(error)")
        }
    }()

    init() {
        // 设置应用外观
        setupAppearance()
        
        // 初始化API配置
        setupAPIConfig()
        
        // 测试API调用 - 已禁用自动测试以节省API调用费用
        /*
        #if DEBUG
        // 在应用启动后进行API诊断
        DispatchQueue.global(qos: .background).async {
            // 延迟3秒，确保应用完全初始化
            Thread.sleep(forTimeInterval: 3)
            
            // 执行API测试
            print("\n========== API 诊断开始 ==========")
            print("🔑 API密钥：\(APIConfigManager.shared.apiKey ?? "未设置")")
            print("🌐 当前端点：\(APIConfigManager.shared.deepSeekEndpoint)")
            print("🤖 测试模型：\(APIConfigManager.shared.modelName)")
            
            // 测试生成虚拟角色评论
            VirtualCharacterService.shared.testGenerateCharacterComment()
        }
        #endif
        */
        
        print("应用启动完成")
    }

    var body: some Scene {
        WindowGroup {
            AppTabView()
                .environmentObject(CreationTypeManager.shared)
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func setupAppearance() {
        // 配置导航栏外观
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // 设置导航栏标题颜色
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)]
    }
    
    private func setupAPIConfig() {
        // 直接设置ARK API密钥
        let arkApiKey = "5ec25df2-f799-4fc0-8ee2-ac13d473131b"
        
        print("🔑 正在设置ARK格式API密钥...")
        APIConfigManager.shared.setAPIKey(arkApiKey)
        print("✅ API密钥已设置: \(arkApiKey.prefix(8))...")
        
        // 自动API测试已删除以节省API调用费用
    }
}
