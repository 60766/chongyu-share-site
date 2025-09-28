import SwiftUI
import UIKit

/**
 * 帖子分享模态视图
 * 全屏展示帖子分享卡片和分享选项，参考角色详情页面的分享设计
 */
struct PostShareModalView: View {
    @Binding var isPresented: Bool
    let post: UserPostModel
    let includeFirstComment: Bool
    
    @State private var selectedColorScheme: ShareCardColorScheme = .vibrantPurple
    
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
                    
                    Text("分享")
                        .font(.system(size: 17, weight: .semibold))
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
                                            // 分享卡片
                    PostShareCard(
                        post: post,
                        includeFirstComment: includeFirstComment,
                        colorScheme: selectedColorScheme
                    )
                                            .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // 色彩方案选择器
                    VStack(spacing: 0) {
                        HStack(spacing: 16) {
                            ForEach(ShareCardColorScheme.allCases, id: \.self) { scheme in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedColorScheme = scheme
                                    }
                                }) {
                                    VStack(spacing: 6) {
                                        // 色彩预览圆圈 - 完整四色渐变
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: getPreviewColors(for: scheme)),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: selectedColorScheme == scheme ? 4 : 2)
                                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                            )
                                            .overlay(
                                                // 内层高光效果
                                                Circle()
                                                    .stroke(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                Color.white.opacity(0.6),
                                                                Color.white.opacity(0.1)
                                                            ]),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                        lineWidth: 1
                                                    )
                                                    .padding(2)
                                            )
                                            .scaleEffect(selectedColorScheme == scheme ? 1.1 : 1.0)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedColorScheme)
                                        
                                        Text(scheme.name)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(selectedColorScheme == scheme ? .white : .white.opacity(0.7))
                                            .animation(.easeInOut(duration: 0.2), value: selectedColorScheme)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                                        }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    
                    // 分享按钮组
                    HStack(spacing: 35) {
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
                            
                            // 图片分享
                            shareButton(
                                title: "图片",
                                icon: "photo.fill",
                                iconColor: Color(hex: "F5A623"),
                                action: {
                                    saveImageToPhotos()
                                }
                            )
                            
                            // 链接分享
                            shareButton(
                                title: "链接",
                                icon: "link",
                                iconColor: Color(hex: "007AFF"),
                                action: {
                                    shareAsText()
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
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - 分享功能实现
    
    private func shareToWeChat() {
        // 微信分享逻辑
        shareImage()
        isPresented = false
    }
    
    private func shareToMoments() {
        // 朋友圈分享逻辑
        shareImage()
        isPresented = false
    }
    
    private func saveImageToPhotos() {
        // 保存图片到相册 - 添加短暂延迟确保视图渲染完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let image = self.generatePostShareImage() {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
        }
        isPresented = false
    }
    
    private func shareAsText() {
        // 文本分享
        let shareText = generatePostShareText()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
            
            // 在iPad上设置popover源视图
            if let popoverController = activityVC.popoverPresentationController {
                popoverController.sourceView = rootViewController.view
                popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            rootViewController.present(activityVC, animated: true)
        }
        isPresented = false
    }
    
    private func shareImage() {
        // 图片分享 - 添加短暂延迟确保视图渲染完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let image = self.generatePostShareImage() {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    
                    let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                
                // 在iPad上设置popover源视图
                if let popoverController = activityVC.popoverPresentationController {
                    popoverController.sourceView = rootViewController.view
                    popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = []
                }
                
                    rootViewController.present(activityVC, animated: true)
                }
            }
        }
    }
    
    // MARK: - 色彩方案辅助方法
    
    /// 获取色彩方案的完整渐变颜色
    private func getPreviewColors(for scheme: ShareCardColorScheme) -> [Color] {
        switch scheme {
        case .vibrantPurple:
            return [
                Color(red: 0.6, green: 0.4, blue: 1.0),        // 鲜艳紫色
                Color(red: 1.0, green: 0.3, blue: 0.7),        // 鲜艳粉色
                Color(red: 0.2, green: 0.7, blue: 1.0),        // 鲜艳蓝色
                Color(red: 1.0, green: 0.6, blue: 0.2)         // 鲜艳橙色
            ]
        case .oceanBlue:
            return [
                Color(red: 0.0, green: 0.48, blue: 1.0),       // iOS系统蓝 (SF Blue)
                Color(red: 0.2, green: 0.78, blue: 0.95),      // 青色 (SF Cyan) 
                Color(red: 0.18, green: 0.82, blue: 0.35),     // 绿色 (SF Green)
                Color(red: 0.0, green: 0.64, blue: 0.89)       // 青蓝色 (SF Teal)
            ]
        case .sunsetOrange:
            return [
                Color(red: 1.0, green: 0.58, blue: 0.0),       // iOS橙色 (SF Orange)
                Color(red: 1.0, green: 0.8, blue: 0.0),        // iOS黄色 (SF Yellow)
                Color(red: 1.0, green: 0.27, blue: 0.23),      // iOS红色 (SF Red)
                Color(red: 0.98, green: 0.39, blue: 0.76)      // iOS粉色 (SF Pink)
            ]
        }
    }
    
    // MARK: - 内容生成
    
    private func generatePostShareImage() -> UIImage? {
        let postShareCard = PostShareCard(
            post: post,
            includeFirstComment: includeFirstComment,
            colorScheme: selectedColorScheme
        )
        
        return renderViewAsImage(postShareCard, size: CGSize(width: 375, height: 600))
    }
    
    private func generatePostShareText() -> String {
        let contentPreview = post.content.prefix(100)
        let ellipsis = post.content.count > 100 ? "..." : ""
        
        return """
        【\(post.username)的虫遇动态】
        
        \(contentPreview)\(ellipsis)
        
        来自虫遇App - 穿越时空的对话
        """
    }
    
    // 将SwiftUI视图渲染为UIImage
    private func renderViewAsImage<T: View>(_ view: T, size: CGSize) -> UIImage? {
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: size)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = UIColor.clear
        
        // 添加到窗口层次结构中，确保视图完全初始化
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(controller.view)
            controller.view.alpha = 0 // 设为透明，不影响用户界面
            
            // 强制布局更新和渲染
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
            
            // 确保所有子视图都完成布局
            controller.view.subviews.forEach { subview in
                subview.setNeedsLayout()
                subview.layoutIfNeeded()
            }
            
            // 使用更高质量的渲染
            let format = UIGraphicsImageRendererFormat()
            format.scale = UIScreen.main.scale
            format.opaque = false
            
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            let image = renderer.image { context in
                controller.view.layer.render(in: context.cgContext)
            }
            
            // 清理：从窗口中移除视图
            controller.view.removeFromSuperview()
            
            return image
        }
        
        // 备用方案：如果无法获取窗口，使用原来的方法
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            controller.view.layer.render(in: context.cgContext)
        }
    }
}

#Preview {
    PostShareModalView(
        isPresented: .constant(true),
        post: UserPostModel.samplePosts.first!,
        includeFirstComment: true
    )
} 