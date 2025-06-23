import Foundation

/**
 * 应用启动器
 * 用于在应用启动时执行一些初始化任务
 */
class AppLauncher {
    private static var hasLaunched = false
    
    /**
     * 在应用启动时调用此方法
     * 可以在应用的AppDelegate或者SwiftUI App的init方法中调用
     */
    static func onAppLaunch() {
        guard !hasLaunched else { return }
        hasLaunched = true
        
        print("🚀 应用启动初始化...")
        
        // 测试API配置 - 已禁用以节省API调用费用
        // VirtualCharacterService.testAPIOnStartup()
    }
} 