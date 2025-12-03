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
        // 🔍 诊断模式：逐个测试每个Model类
        #if DEBUG
        print("🔍 [SwiftData] 开始诊断Model类...")
        
        // 测试每个Model类是否能被正确识别
        let modelClasses: [(String, Any.Type)] = [
            ("Character", Character.self),
            ("User", User.self),
            ("Message", Message.self),
            ("SDConversation", SDConversation.self),
            ("Post", Post.self),
            ("Comment", Comment.self),
            ("MultiPersonChatSession", MultiPersonChatSession.self),
            ("MultiPersonChatMessage", MultiPersonChatMessage.self),
            ("CharacterChatInsightCache", CharacterChatInsightCache.self)
        ]
        
        for (name, type) in modelClasses {
            print("   ✅ \(name): \(type)")
        }
        #endif
        
        // 分阶段构建Schema，找出问题Model
        var schemaModels: [any PersistentModel.Type] = []
        
        // 阶段1：基础模型（无关系）
        schemaModels.append(Character.self)
        schemaModels.append(User.self)
        schemaModels.append(Message.self)
        schemaModels.append(SDConversation.self)
        
        // 阶段2：有关系的模型
        schemaModels.append(Post.self)
        schemaModels.append(Comment.self)
        
        // 阶段3：多人聊天模型
        schemaModels.append(MultiPersonChatSession.self)
        schemaModels.append(MultiPersonChatMessage.self)
        
        // 阶段4：缓存模型
        schemaModels.append(CharacterChatInsightCache.self)
        
        let schema = Schema(schemaModels)
        
        // 创建配置，禁用CloudKit（我们只需要本地存储）
        // 使用cloudKitDatabase: .none 来禁用CloudKit集成
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none  // 禁用CloudKit，只使用本地SQLite
        )

        // 🔍 详细诊断：逐个测试每个Model类
        #if DEBUG
        print("🔍 [SwiftData] 测试每个Model类...")
        for modelType in schemaModels {
            let typeName = String(describing: modelType)
            print("   📦 测试: \(typeName)")
            
            // 尝试创建Schema只包含这个Model
            do {
                let testSchema = Schema([modelType])
                let testConfig = ModelConfiguration(schema: testSchema, isStoredInMemoryOnly: true)
                let _ = try ModelContainer(for: testSchema, configurations: [testConfig])
                print("      ✅ \(typeName) 通过")
            } catch {
                print("      ❌ \(typeName) 失败: \(error)")
            }
        }
        #endif

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("❌ [SwiftData] ModelContainer创建失败: \(error)")
            print("   错误类型: \(type(of: error))")
            print("   错误详情: \(error.localizedDescription)")
            
            // 尝试删除损坏的数据库文件
            let fileManager = FileManager.default
            if let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                let dbPath = documentsPath.appendingPathComponent("default.store")
                let dbShmPath = documentsPath.appendingPathComponent("default.store-shm")
                let dbWalPath = documentsPath.appendingPathComponent("default.store-wal")
                
                // 备份并删除旧数据库文件
                for dbFile in [dbPath, dbShmPath, dbWalPath] {
                    if fileManager.fileExists(atPath: dbFile.path) {
                        let backupPath = dbFile.appendingPathExtension("backup")
                        // 尝试备份，如果失败则直接删除
                        if (try? fileManager.moveItem(at: dbFile, to: backupPath)) != nil {
                            print("   📦 已备份: \(dbFile.lastPathComponent)")
                        } else {
                            // 如果备份失败，直接删除
                            try? fileManager.removeItem(at: dbFile)
                            print("   🗑️ 已删除: \(dbFile.lastPathComponent)")
                        }
                    }
                }
                
                // 尝试重新创建
                do {
                    let retryContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                    print("   ✅ 删除旧数据库后重新创建成功")
                    return retryContainer
                } catch {
                    print("   ⚠️ 重新创建仍然失败: \(error)")
                }
            }
            
            // 最后的fallback：使用内存模式（数据不会持久化，但至少应用可以启动）
            print("   🔄 尝试使用内存模式作为fallback...")
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                let fallbackContainer = try ModelContainer(for: schema, configurations: [memoryConfig])
                print("   ✅ 使用内存模式（数据不会持久化，重启后丢失）")
                print("   ⚠️ 建议：删除应用重新安装以恢复持久化存储")
                return fallbackContainer
            } catch {
                // 如果连内存模式都失败，说明Schema定义有问题
                #if DEBUG
                print("   ❌ 内存模式创建也失败，Schema可能有问题")
                print("   错误详情: \(error)")
                #endif
                
                // 记录错误到日志系统
                Logger.error("无法创建ModelContainer（包括内存模式）", error: error, log: Logger.data)
                
                // 尝试创建一个最小可用的容器（只包含基础模型）
                do {
                    #if DEBUG
                    print("   🔄 尝试创建最小可用容器（仅基础模型）...")
                    #endif
                    
                    // 只使用最基础的模型，避免复杂关系导致的问题
                    let minimalSchema = Schema([
                        Character.self,
                        User.self,
                        Message.self
                    ])
                    let minimalConfig = ModelConfiguration(
                        schema: minimalSchema,
                        isStoredInMemoryOnly: true
                    )
                    let minimalContainer = try ModelContainer(for: minimalSchema, configurations: [minimalConfig])
                    
                    #if DEBUG
                    print("   ✅ 创建最小可用容器成功（功能受限）")
                    print("   ⚠️ 警告：部分功能可能不可用，建议删除应用重新安装")
                    #endif
                    
                    // 在主线程显示错误提示（延迟执行，确保UI已初始化）
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        // 发送通知，让UI层显示错误提示
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ModelContainerCreationFailed"),
                            object: nil,
                            userInfo: [
                                "error": error.localizedDescription,
                                "suggestion": "数据初始化失败，部分功能可能不可用。建议删除应用重新安装。"
                            ]
                        )
                    }
                    
                    return minimalContainer
                } catch {
                    // 如果连最小容器都创建失败，记录错误但继续运行
                    #if DEBUG
                    print("   ❌ 最小容器创建也失败: \(error)")
                    #endif
                    Logger.error("最小容器创建失败", error: error, log: Logger.data)
                    
                    // 创建一个完全空的容器，至少让应用可以启动
                    // 这会导致数据功能完全不可用，但应用不会崩溃
                    do {
                        let emptySchema = Schema([])
                        let emptyConfig = ModelConfiguration(schema: emptySchema, isStoredInMemoryOnly: true)
                        let emptyContainer = try ModelContainer(for: emptySchema, configurations: [emptyConfig])
                        
                        #if DEBUG
                        print("   ⚠️ 使用空容器（数据功能完全不可用）")
                        #endif
                        
                        // 显示严重错误提示
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ModelContainerCreationFailed"),
                                object: nil,
                                userInfo: [
                                    "error": error.localizedDescription,
                                    "suggestion": "数据系统初始化失败，请删除应用重新安装。",
                                    "severity": "critical"
                                ]
                            )
                        }
                        
                        return emptyContainer
                    } catch {
                        // 最后的最后，如果连空容器都创建失败，使用系统默认处理
                        // 这应该永远不会发生，但如果发生了，至少不会崩溃
                        #if DEBUG
                        print("   🚨 所有容器创建方案都失败，使用系统默认处理")
                        #endif
                        Logger.error("所有容器创建方案都失败", error: error, log: Logger.data)
                        
                        // 返回一个临时的内存容器，至少让应用可以启动
                        // 注意：这会导致SwiftData功能完全不可用
                        return try! ModelContainer(for: Schema([]), configurations: [
                            ModelConfiguration(schema: Schema([]), isStoredInMemoryOnly: true)
                        ])
                    }
                }
            }
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
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TriggerAutoBackup"))) { _ in
                    // 延迟执行，确保 ModelContext 已准备好
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        performAutoBackupIfNeeded()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    /// 执行自动备份（如果需要）
    private func performAutoBackupIfNeeded() {
        // 检查自动备份是否开启
        guard UserDefaults.standard.bool(forKey: "iCloudAutoBackupEnabled") else {
            return
        }
        
        // 检查是否需要备份
        guard iCloudBackupService.shared.shouldAutoBackup() else {
            return
        }
        
        // 在主线程发送通知，确保接收方也在主线程处理
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("PerformAutoBackup"),
                object: nil
            )
        }
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
