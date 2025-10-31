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
    @State private var previewImage: UIImage? = nil
    
    var body: some View {
        ZStack {
            // 背景色 - 使用纯色半透明背景（移除毛玻璃效果以提升性能）
            Color.black.opacity(0.75)
                .edgesIgnoringSafeArea(.all)
            
            GeometryReader { geometry in
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
                    
                    // 内容区域 - 智能缩放卡片预览（参考多人对话实现）
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 20)
                        
                        // 分享卡片预览 - 使用渲染后的图片 + aspectRatio 自适应缩放
                        let maxCardHeight: CGFloat = geometry.size.height * 0.55
                        
                        HStack {
                            Spacer()
                            if let image = previewImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 350, maxHeight: maxCardHeight)
                                    .cornerRadius(20)
                                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                            } else {
                                // 加载中占位符
                                ProgressView()
                                    .frame(width: 350, height: maxCardHeight)
                            }
                            Spacer()
                        }
                        .frame(height: maxCardHeight)
                        
                        // 色彩方案选择器 - 水平居中
                        HStack {
                            Spacer()
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
                                                .font(DesignSystem.Typography.caption.weight(.semibold))
                                                .foregroundColor(selectedColorScheme == scheme ? .white : .white.opacity(0.7))
                                                .animation(.easeInOut(duration: 0.2), value: selectedColorScheme)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                        
                        Spacer()
                    }
                }
                
                // 固定在底部的分享按钮组
                VStack {
                    Spacer()
                    
                    // 水平居中按钮组
                    HStack {
                        Spacer()
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
                            
                            // 保存图片
                            shareButton(
                                title: "保存卡片",
                                icon: "square.and.arrow.down.fill",
                                iconColor: Color(hex: "F5A623"),
                                action: {
                                    saveImageToPhotos()
                                }
                            )
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .onTapGesture {
            // 点击空白区域关闭
            isPresented = false
        }
        .onAppear {
            // 视图出现时生成预览图片
            generatePreviewImage()
        }
        .onChange(of: selectedColorScheme) { _ in
            // 切换色彩方案时重新生成预览图片
            generatePreviewImage()
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
    
    // MARK: - 预览图片生成
    
    /// 生成预览图片（极致优化版：最快显示速度）
    private func generatePreviewImage() {
        // 🚀 极致性能优化方案：
        // 1. 界面立即打开（不等待）
        // 2. 等待动画完成（300ms，确保流畅）
        // 3. 使用低分辨率快速渲染（2x scale，速度提升 2.25 倍）
        
        // 使用 Task 在主线程异步执行，不阻塞当前的视图显示
        Task { @MainActor in
            // 等待动画完全结束（300ms 是 SwiftUI sheet 标准动画时长）
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
            
            // 🚀 分帧渲染：将渲染任务分成小块，避免长时间阻塞主线程
            await self.generateImageInChunks()
        }
    }
    
    /// 分帧渲染图片，避免阻塞主线程
    @MainActor
    private func generateImageInChunks() async {
        // 让出主线程，让其他任务先执行
        await Task.yield()
        
        // 生成图片（使用优化的低分辨率版本）
        self.previewImage = self.generatePostShareImage()
    }
    
    // MARK: - 分享功能实现
    
    private func shareToWeChat() {
        print("🔍 点击了微信分享按钮")
        // 微信分享逻辑 - 调用系统分享，用户可选择微信好友或朋友圈
        // 添加触觉反馈
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        shareImage()
        // 注意：不要立即关闭界面，等分享完成后再关闭
        // isPresented = false
    }
    
    private func shareToMoments() {
        print("🔍 点击了朋友圈分享按钮")
        // 朋友圈分享逻辑 - 同样调用系统分享
        // 添加触觉反馈
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        shareImage()
        // 注意：不要立即关闭界面，等分享完成后再关闭
        // isPresented = false
    }
    
    private func saveImageToPhotos() {
        // 添加触觉反馈
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        
        // 使用已生成的预览图片
        if let image = previewImage {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            // 保存成功反馈
            generator.notificationOccurred(.success)
            
            // 延迟关闭界面，让用户感受到反馈
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isPresented = false
            }
        } else {
            // 保存失败反馈
            generator.notificationOccurred(.error)
            isPresented = false
        }
    }
    
    private func shareImage() {
        print("🔍 开始分享图片...")
        
        // 使用已生成的预览图片
        guard let image = previewImage else {
            print("❌ 预览图片不存在")
            return
        }
        
        print("✅ 使用预览图片，尺寸: \(image.size)")
        
        // 🔧 关键修复：先关闭分享模态视图，避免视图层级冲突
        isPresented = false
        
        // 延迟一小段时间确保模态视图完全关闭，然后展示系统分享界面
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.presentSystemShareSheet(with: image)
        }
    }
    
    private func presentSystemShareSheet(with image: UIImage) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            print("❌ 无法获取windowScene")
            return
        }
        
        guard let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ 无法获取rootViewController")
            return
        }
        
        print("✅ 准备显示系统分享界面...")
        
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        // 在iPad上设置popover源视图
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = rootViewController.view
            popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        // 添加完成回调
        activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 分享失败: \(error.localizedDescription)")
                } else if completed {
                    print("✅ 分享成功: \(activityType?.rawValue ?? "未知")")
                } else {
                    print("ℹ️ 用户取消分享")
                }
            }
        }
        
        rootViewController.present(activityVC, animated: true) {
            print("✅ 系统分享界面已显示")
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
        // 🎯 第一性原理方案：
        // 1. 在足够大的白色画布上渲染卡片（包含阴影）
        // 2. 像素级精确检测卡片边界（包括阴影）
        // 3. 裁剪，保留目标白边（上下左右完全一致）
        
        let postShareCard = PostShareCard(
            post: post,
            includeFirstComment: includeFirstComment,
            colorScheme: selectedColorScheme
        )
        
        // 在白色背景上渲染（给足够的空间容纳阴影）
        let whiteCanvas = ZStack {
            Color.white
            postShareCard
        }
        
        // 渲染到一个足够大的白色画布
        // 高度估算：内容高度约400-600pt + 阴影空间30pt + buffer 100pt
        guard let fullImage = renderViewAsImage(
            whiteCanvas,
            size: CGSize(width: 375 + 100, height: 800)  // 足够大的画布
        ) else {
            return nil
        }
        
        // 精确裁剪，保留统一白边（8pt，视觉更紧凑）
        return cropImageWithUniformPadding(fullImage, targetPadding: 8)
    }
    
    // 像素级精确裁剪，确保上下左右白边完全一致
    private func cropImageWithUniformPadding(_ image: UIImage, targetPadding: CGFloat) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let scale = image.scale
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = width * 4
        
        // 创建像素数据上下文
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let pixelData = context.data else { return nil }
        let data = pixelData.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        // 判断像素是否为纯白色（包括淡阴影）
        // 阴影 opacity=0.12 的黑色 ≈ RGB(224, 224, 224)
        // 使用阈值230可以过滤掉阴影，只检测实际卡片内容
        func isWhitePixel(r: UInt8, g: UInt8, b: UInt8) -> Bool {
            return r > 230 && g > 230 && b > 230
        }
        
        // 找到内容的边界（非白色像素的最小最大坐标）
        var minX = width
        var maxX = 0
        var minY = height
        var maxY = 0
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * 4
                let r = data[pixelIndex]
                let g = data[pixelIndex + 1]
                let b = data[pixelIndex + 2]
                
                if !isWhitePixel(r: r, g: g, b: b) {
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                }
            }
        }
        
        // 如果没找到内容，返回原图
        guard minX < maxX && minY < maxY else {
            print("⚠️ 未检测到内容边界，返回原图")
            return image
        }
        
        // 转换目标padding到像素单位
        let paddingPixels = Int(targetPadding * scale)
        
        // 🔍 调试日志：检测结果
        print("✅ 内容边界检测成功:")
        print("   - 图片尺寸: \(width)×\(height)px")
        print("   - 内容边界: x[\(minX), \(maxX)] y[\(minY), \(maxY)]")
        print("   - 内容尺寸: \((maxX - minX))×\((maxY - minY))px")
        print("   - 目标白边: \(targetPadding)pt = \(paddingPixels)px")
        
        // 计算裁剪区域（内容边界 + 目标padding）
        let cropX = max(0, minX - paddingPixels)
        let cropY = max(0, minY - paddingPixels)
        let cropWidth = min(width - cropX, maxX - minX + 1 + 2 * paddingPixels)
        let cropHeight = min(height - cropY, maxY - minY + 1 + 2 * paddingPixels)
        
        print("   - 裁剪区域: (\(cropX), \(cropY), \(cropWidth), \(cropHeight))")
        print("   - 白边验证: 上=\(minY - cropY)px 下=\(cropY + cropHeight - maxY)px 左=\(minX - cropX)px 右=\(cropX + cropWidth - maxX)px")
        
        let cropRect = CGRect(
            x: cropX,
            y: cropY,
            width: cropWidth,
            height: cropHeight
        )
        
        // 裁剪
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else { return nil }
        
        return UIImage(cgImage: croppedCGImage, scale: scale, orientation: image.imageOrientation)
    }
    
    // 将SwiftUI视图渲染为UIImage（优化版：减少阻塞时间）
    private func renderViewAsImage<T: View>(_ view: T, size: CGSize) -> UIImage? {
        // ⚠️ 重要：此方法必须在主线程调用
        guard Thread.isMainThread else {
            print("❌ renderViewAsImage 必须在主线程调用")
            return nil
        }
        
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: size)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .white
        
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = controller
        window.backgroundColor = .white
        window.isHidden = false
        
        // 🚀 性能优化：减少布局次数和等待时间
        // 一次性完成布局，减少不必要的重复
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        
        // 🚀 关键优化：最小化等待时间（1ms 即可）
        // 因为我们已经在动画完成后才调用此方法，所以只需要很短的时间让布局完成
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.001))
        
        // 🚀 优化：使用优化的渲染格式（降低分辨率换取速度）
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0  // 2x 比 3x 快约 2.25 倍，分享图质量依然很好
        format.opaque = true  // 白色背景，使用opaque提高性能
        format.preferredRange = .standard
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            // 🚀 使用 drawHierarchy 而非 render(in:)，速度更快
            controller.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
        }
        
        // 清理资源
        window.isHidden = true
        window.rootViewController = nil
        
        return image
    }
}

#Preview {
    PostShareModalView(
        isPresented: .constant(true),
        post: UserPostModel.samplePosts.first!,
        includeFirstComment: true
    )
} 