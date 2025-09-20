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
        // 设置应用外观
        setupAppearance()
        
        // 初始化API配置
        setupAPIConfig()
        
        // 初始化用户点赞服务
        _ = UserLikeService.shared
        
        // 初始化全局点赞状态管理器
        _ = LikeStateManager.shared
        
        #if DEBUG
        print("🖼️ 初始化历史人物图片资源...")
        print("📱 应用路径: \(Bundle.main.bundlePath)")
        if let resourcePath = Bundle.main.resourcePath {
            print("📂 资源路径: \(resourcePath)")
            
            // 检查孔子头像是否存在于资源包中
            let kongziPaths = [
                resourcePath + "/kongzi.png",
                resourcePath + "/HistoricalFigures/kongzi.png",
                resourcePath + "/Assets.xcassets/HistoricalFigures/kongzi.imageset/kongzi.png"
            ]
            
            print("🔍 检查孔子头像在资源包中的位置:")
            for path in kongziPaths {
                if FileManager.default.fileExists(atPath: path) {
                    print("✅ 孔子头像存在于: \(path)")
                    if let image = UIImage(contentsOfFile: path) {
                        print("  - 图片尺寸: \(image.size)")
                    }
                } else {
                    print("❌ 孔子头像不存在于: \(path)")
                }
            }
        }
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path {
            print("📂 文档路径: \(documentsPath)")
        }
        #endif
        
        // 复制历史人物图片到运行时目录和Documents目录（功能保留）
        HistoricalFigureImageCopier.shared.copyAllImages()
        
        // 手动注册图片到运行时（仅调试时执行）
        #if DEBUG
        HistoricalFigureImageCopier.shared.registerImagesManually()
        #endif
        
        // 验证图片是否成功复制（改到视图出现后异步执行）
        
        #if DEBUG
        print("应用启动完成")
        #endif
    }
    
    /// 验证历史人物图片是否成功复制到运行时目录
    private func verifyHistoricalFigureImages() {
        if let resourcePath = Bundle.main.resourcePath {
            let historicalDir = resourcePath + "/HistoricalFigures"
            let fileManager = FileManager.default
            
            if fileManager.fileExists(atPath: historicalDir) {
                print("✅ HistoricalFigures目录存在")
                
                // 尝试列出目录内容
                do {
                    let files = try fileManager.contentsOfDirectory(atPath: historicalDir)
                    print("📋 HistoricalFigures目录内容: \(files)")
                    
                    // 检查关键角色图片
                    let keyCharacters = ["kongzi", "einstein", "shakespeare"]
                    for character in keyCharacters {
                        let imagePath = historicalDir + "/\(character).png"
                        if fileManager.fileExists(atPath: imagePath) {
                            print("✅ \(character)图片存在: \(imagePath)")
                            
                            // 尝试加载图片
                            if let _ = UIImage(contentsOfFile: imagePath) {
                                print("✅ 可以加载\(character)图片")
                            } else {
                                print("❌ 无法加载\(character)图片，虽然文件存在")
                            }
                        } else {
                            print("❌ \(character)图片不存在: \(imagePath)")
                        }
                    }
                } catch {
                    print("❌ 无法列出HistoricalFigures目录内容: \(error)")
                }
            } else {
                print("❌ HistoricalFigures目录不存在，图片复制可能失败")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            AppTabView()
                .environmentObject(CreationTypeManager.shared)
                .environmentObject(storeKitManager)
                .task {
                    #if DEBUG
                    // 在视图出现后异步验证，避免阻塞启动
                    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) {
                        verifyHistoricalFigureImages()
                    }
                    #endif
                    
                    // StoreKit 测试
                    print("[APP] 应用启动，开始测试 StoreKit...")
                    await storeKitManager.loadProducts()
                    print("[APP] StoreKit 测试完成，产品数量: \(storeKitManager.products.count)")
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
