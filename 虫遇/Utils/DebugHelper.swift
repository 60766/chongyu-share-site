import SwiftUI
import UIKit

/**
 * 调试助手类
 * 提供全局调试窗口显示和管理功能
 */
public class DebugHelper {
    /// 单例实例
    public static let shared = DebugHelper()
    
    /// 私有初始化方法
    private init() {
        #if DEBUG
        print("DebugHelper初始化")
        #endif
    }
    
    /// 显示调试窗口
    public func showDebugWindow() {
        DispatchQueue.main.async {
            // 查找顶层视图控制器
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                #if DEBUG
                print("无法找到根视图控制器")
                #endif
                return
            }
            
            // 获取最顶层的视图控制器
            let topViewController = rootViewController.topMostViewController
            
            // 创建调试菜单视图
            let debugMenuView = DebugMenuView()
            let hostingController = UIHostingController(rootView: debugMenuView)
            hostingController.modalPresentationStyle = .formSheet
            
            // 显示调试窗口
            topViewController.present(hostingController, animated: true) {
                #if DEBUG
                print("调试窗口已显示")
                #endif
            }
        }
    }
} 