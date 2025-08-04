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
        
        // 复制历史人物图片到运行时目录和Documents目录
        HistoricalFigureImageCopier.shared.copyAllImages()
        
        // 手动注册图片到运行时
        HistoricalFigureImageCopier.shared.registerImagesManually()
        
        // 验证图片是否成功复制
        verifyHistoricalFigureImages()
        
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
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func setupAppearance() {
        // 配置导航栏外观
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .clear // 改为透明背景，解决白色遮挡问题
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
