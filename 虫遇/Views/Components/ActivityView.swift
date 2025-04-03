import SwiftUI
import UIKit

/**
 * 系统分享活动视图
 * 用于显示系统标准分享菜单
 */
struct ActivityView: UIViewControllerRepresentable {
    // 要分享的内容
    let activityItems: [Any]
    // 可选的应用程序活动
    var applicationActivities: [UIActivity]? = nil
    // 要排除的活动类型
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil
    // 完成回调
    var completion: UIActivityViewController.CompletionWithItemsHandler? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        // 创建标准系统分享控制器
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        
        // 设置排除的活动类型
        controller.excludedActivityTypes = excludedActivityTypes
        
        // 设置完成回调
        controller.completionWithItemsHandler = completion
        
        // 在iPad上设置弹出源以避免崩溃
        if let popoverController = controller.popoverPresentationController {
            // 获取当前活动窗口（iOS 15+）
            if #available(iOS 15, *) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    popoverController.sourceView = window
                    popoverController.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                }
            } else {
                // 旧版API（iOS 14及以下）
                if let window = UIApplication.shared.windows.first {
                    popoverController.sourceView = window
                    popoverController.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                }
            }
            // 禁用箭头方向，使弹出菜单居中显示
            popoverController.permittedArrowDirections = []
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // 视图控制器不需要更新
    }
}

// 预览示例
struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        // 由于UIViewControllerRepresentable不能直接预览，
        // 我们显示一个按钮，点击后显示ActivityView
        Button("分享") {
            // 在预览中点击无效
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
} 