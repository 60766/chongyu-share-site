import SwiftUI
import UIKit

/**
 * 单人聊天分享模态视图
 * 全屏展示单人聊天分享卡片和分享选项
 */
struct ChatShareModalView: View {
    @Binding var isPresented: Bool
    let shareCards: [UIImage]
    let characterName: String
    
    @State private var currentCardIndex: Int = 0
    
    var body: some View {
        ZStack {
            // 背景色 - 使用半透明黑色背景
            Color.black.opacity(0.6)
                .background(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    // 返回按钮
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color(red: 149/255, green: 138/255, blue: 177/255))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .padding(.leading, 12)
                    
                    Spacer()
                    
                    Text("分享对话卡片")
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // 占位按钮，保持布局对称
                    Color.clear
                        .frame(width: 44, height: 44)
                        .padding(.trailing, 12)
                }
                .padding(.top, 12)
                .padding(.bottom, 12)
                
                // 内容区域（可滚动）
                ScrollView {
                    VStack(spacing: 24) {
                        // 分享卡片轮播
                        if !shareCards.isEmpty {
                            VStack(spacing: 16) {
                                // 卡片显示区域
                                TabView(selection: $currentCardIndex) {
                                    ForEach(0..<shareCards.count, id: \.self) { index in
                                        Image(uiImage: shareCards[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: 350, maxHeight: 500)
                                            .cornerRadius(20)
                                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                                            .tag(index)
                                    }
                                }
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                                .frame(height: 520)
                                .padding(.horizontal, 20)
                                
                                // 卡片指示器（如果有多张卡片）
                                if shareCards.count > 1 {
                                    HStack(spacing: 8) {
                                        ForEach(0..<shareCards.count, id: \.self) { index in
                                            Circle()
                                                .fill(currentCardIndex == index ? Color.white : Color.white.opacity(0.4))
                                                .frame(width: 8, height: 8)
                                                .scaleEffect(currentCardIndex == index ? 1.2 : 1.0)
                                                .animation(.easeInOut(duration: 0.2), value: currentCardIndex)
                                        }
                                    }
                                    .padding(.bottom, 8)
                                }
                                
                                // 卡片计数信息
                                if shareCards.count > 1 {
                                    Text("\(currentCardIndex + 1) / \(shareCards.count)")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.bottom, 8)
                                }
                            }
                        }
                        
                        // 分享按钮组 - 与MultiChatShareModalView保持一致
                        HStack(spacing: 40) {
                            // 微信分享
                            shareButton(
                                title: "微信",
                                icon: "message.fill",
                                iconColor: Color(hex: "09B83E"),
                                action: {
                                    shareToWeChat()
                                }
                            )
                            
                            // 朋友圈分享
                            shareButton(
                                title: "朋友圈",
                                icon: "person.2.circle.fill",
                                iconColor: Color(hex: "09B83E"),
                                action: {
                                    shareToMoments()
                                }
                            )
                            
                            // 保存卡片
                            shareButton(
                                title: "保存卡片",
                                icon: "square.and.arrow.down.fill",
                                iconColor: Color(hex: "F5A623"),
                                action: {
                                    saveCurrentImageToPhotos()
                                }
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .onTapGesture {
            // 点击空白区域关闭
            isPresented = false
        }
    }
    
    // MARK: - 分享按钮样式
    @ViewBuilder
    private func shareButton(title: String, icon: String, iconColor: Color, action: @escaping () -> Void) -> some View {
        VStack(spacing: 8) {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(iconColor)
                }
            }
            
            Text(title)
                .font(DesignSystem.Typography.caption.weight(.medium))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - 分享功能实现
    
    private func shareToWeChat() {
        guard currentCardIndex < shareCards.count else { return }
        
        #if DEBUG
        print("🔍 点击了微信分享按钮")
        #endif
        
        // 添加触觉反馈
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        let image = shareCards[currentCardIndex]
        
        // 🔧 关键修复：先关闭分享模态视图，避免视图层级冲突
        isPresented = false
        
        // 🔧 增加延迟时间，确保SwiftUI模态视图完全关闭
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.presentSystemShareSheet(with: image)
        }
    }
    
    private func shareToMoments() {
        guard currentCardIndex < shareCards.count else { return }
        
        // 添加触觉反馈
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        let image = shareCards[currentCardIndex]
        
        // 关闭分享模态视图，避免视图层级冲突
        isPresented = false
        
        // 延迟确保SwiftUI模态视图完全关闭
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.presentSystemShareSheet(with: image)
        }
    }
    
    private func saveCurrentImageToPhotos() {
        guard currentCardIndex < shareCards.count else { return }
        
        // 添加触觉反馈
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        
        let image = shareCards[currentCardIndex]
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // 保存成功反馈
        generator.notificationOccurred(.success)
        
        // 显示保存成功提示
        showSuccessMessage("图片已保存到相册")
        
        // 延迟关闭界面，让用户感受到反馈
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
    
    private func presentSystemShareSheet(with image: UIImage) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        // 递归查找最顶层的视图控制器
        func findTopViewController(_ controller: UIViewController) -> UIViewController {
            if let presented = controller.presentedViewController {
                return findTopViewController(presented)
            }
            if let nav = controller as? UINavigationController {
                return findTopViewController(nav.visibleViewController ?? nav)
            }
            if let tab = controller as? UITabBarController {
                return findTopViewController(tab.selectedViewController ?? tab)
            }
            return controller
        }
        
        let topViewController = findTopViewController(rootViewController)
        
        
        // 如果顶层视图控制器正在展示其他内容，先关闭
        if topViewController.presentedViewController != nil {
            topViewController.dismiss(animated: false) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.showActivityViewController(image: image, from: topViewController)
                }
            }
        } else {
            showActivityViewController(image: image, from: topViewController)
        }
    }
    
    private func showActivityViewController(image: UIImage, from viewController: UIViewController) {
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        // 在iPad上设置popover源视图
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        viewController.present(activityVC, animated: true)
    }
    
    // MARK: - 辅助方法
    
    private func showSuccessMessage(_ message: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        // 递归找到当前最顶层的视图控制器，避免被其他模态覆盖
        func findTopViewController(_ controller: UIViewController) -> UIViewController {
            if let presented = controller.presentedViewController {
                return findTopViewController(presented)
            }
            if let nav = controller as? UINavigationController {
                return findTopViewController(nav.visibleViewController ?? nav)
            }
            if let tab = controller as? UITabBarController {
                return findTopViewController(tab.selectedViewController ?? tab)
            }
            return controller
        }
        
        let topVC = findTopViewController(rootViewController)
        
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        // 轻量提示，不需要按钮，1.2 秒后自动消失
        topVC.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            alert.dismiss(animated: true, completion: nil)
        }
    }
}

#Preview {
    // 创建示例图片
    let sampleImage = UIGraphicsImageRenderer(size: CGSize(width: 350, height: 500)).image { context in
        UIColor.systemBlue.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 350, height: 500))
    }
    
    return ChatShareModalView(
        isPresented: .constant(true),
        shareCards: [sampleImage, sampleImage],
        characterName: "爱因斯坦"
    )
}

