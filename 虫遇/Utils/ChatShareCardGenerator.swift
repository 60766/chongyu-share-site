import SwiftUI
import UIKit


/**
 * 聊天分享卡片生成器
 * 用于生成精美的聊天消息分享卡片
 */
class ChatShareCardGenerator {
    
    /// 生成分享卡片图片（返回预览版和保存版，与多人对话保持一致）
    static func generateCard(
        message: Message,
        character: CYChatCharacter,
        characterThemeColor: Color
    ) -> ShareCardResult {
        
        // 预览版（带阴影）
        let previewCardView = ChatShareCardView(
            message: message,
            character: character,
            characterThemeColor: characterThemeColor,
            showShadow: true
        )
        
        let cardHeight = previewCardView.calculateOptimalHeight()
        
        // 🎨 预览版：直接渲染卡片，应用圆角
        let previewImageRaw = renderViewAsImage(previewCardView, size: CGSize(width: 350, height: cardHeight), opaque: false) ?? previewCardView.asUIImage(size: CGSize(width: 350, height: cardHeight))
        let previewImage = previewImageRaw.withRoundedCorners(radius: 24, addGradientBackground: false)
        
        // 💾 保存版：彩色渐变背景渲染管线（与多人对话完全一致）
        let saveCardView = ChatShareCardView(
            message: message,
            character: character,
            characterThemeColor: characterThemeColor,
            showShadow: true,
            showBackground: false  // 使用透明背景，让底层渐变显示
        )
        
        // 计算扩大的背景尺寸
        let backgroundPadding: CGFloat = 40  // 背景比卡片大40pt
        let backgroundWidth = 350 + backgroundPadding * 2
        let backgroundHeight = cardHeight + backgroundPadding * 2
        
        // 定义彩色渐变描边颜色 - 与多人对话保持一致
        let borderColors = [
            Color(red: 0.8, green: 0.6, blue: 1.0),   // 淡紫色
            Color(red: 1.0, green: 0.5, blue: 0.8),   // 粉色
            Color(red: 0.2, green: 0.7, blue: 1.0),   // 蓝色
            Color(red: 1.0, green: 0.6, blue: 0.2)    // 橙色
        ]
        
        let gradientCanvas = ZStack {
            // 底层渐变背景 - 使用与主页面完全一致的梦幻渐变
            ZStack {
                // 主渐变（从上到下）
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "FFF0F5"),  // 更亮的粉白色
                        Color(hex: "FFE8F0"),  // 亮粉色
                        Color(hex: "F0E8FF"),  // 亮紫色
                        Color(hex: "E8F4FF"),  // 亮蓝色
                        Color(hex: "FFE8D4")   // 淡橙色
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // 顶部水平渐变层
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "FFE8F0").opacity(0.4),  // 左侧粉色
                        Color(hex: "FFD4E5").opacity(0.3),  // 粉红色
                        Color.clear,                         // 中间透明
                        Color(hex: "E8F4FF").opacity(0.3),  // 淡蓝色
                        Color(hex: "F0E8FF").opacity(0.4)   // 右侧紫色
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: backgroundHeight * 0.6)
                .frame(maxHeight: .infinity, alignment: .top)
                
                // 左上角明亮色彩点缀
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.8),
                        Color(hex: "FFFEF5").opacity(0.7),
                        Color(hex: "FFF9E6").opacity(0.5),
                        Color(hex: "FFE8CC").opacity(0.3),
                        Color.clear
                    ]),
                    center: .topLeading,
                    startRadius: 5,
                    endRadius: backgroundWidth * 0.8
                )
                
                // 右下角柔和色彩点缀
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "F0E8FF").opacity(0.4),
                        Color(hex: "E8F4FF").opacity(0.3),
                        Color(hex: "FFE8D4").opacity(0.2),
                        Color.clear
                    ]),
                    center: .bottomTrailing,
                    startRadius: 10,
                    endRadius: backgroundWidth * 0.5
                )
            }
            .frame(width: backgroundWidth, height: backgroundHeight)
            // 保存版不使用圆角，让背景完全铺满四个角
            
            // 上层透明卡片 - 居中对齐，添加描边
            saveCardView
                .frame(width: 350, height: cardHeight)
                .overlay(
                    // 外层精致边框 - 彩色渐变描边
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: borderColors.map { $0.opacity(0.8) }),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3.0
                        )
                )
                .overlay(
                    // 内层精致边框 - 白色高光
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                        .padding(1.5)
                )
        }
        
        // 渲染到足够大的彩色画布（高度 = 卡片高度 + 阴影空间 + buffer）
        guard let fullImage = renderViewAsImage(
            gradientCanvas,
            size: CGSize(width: backgroundWidth + 60, height: backgroundHeight + 60),
            opaque: false
        ) else {
            // 如果渲染失败，fallback 到简单方案
            let fallbackImage = previewImageRaw.withRoundedCorners(radius: 24)
            return ShareCardResult(previewImage: previewImage, saveImage: fallbackImage)
        }
        
        // 像素裁剪，删除左右和上面的白色空隙，只保留底部少量边距
        let saveImage = cropImageWithColoredPadding(fullImage, targetPadding: 0) ?? fullImage
        
        return ShareCardResult(previewImage: previewImage, saveImage: saveImage)
    }
    
    /// 批量生成分享卡片（返回预览版和保存版）
    static func generateCards(
        messages: [Message],
        character: CYChatCharacter,
        characterThemeColor: Color
    ) -> [ShareCardResult] {
        
        return messages.enumerated().map { index, message in
            let previewCardView = ChatShareCardView(
                message: message,
                character: character,
                characterThemeColor: characterThemeColor,
                cardIndex: index + 1,
                totalCards: messages.count,
                showShadow: true
            )
            
            let cardHeight = previewCardView.calculateOptimalHeight()
            
            // 🎨 预览版：直接渲染卡片，应用圆角
            let previewImageRaw = renderViewAsImage(previewCardView, size: CGSize(width: 350, height: cardHeight), opaque: false) ?? previewCardView.asUIImage(size: CGSize(width: 350, height: cardHeight))
            let previewImage = previewImageRaw.withRoundedCorners(radius: 24, addGradientBackground: false)
            
            // 💾 保存版：彩色渐变背景渲染管线
            let saveCardView = ChatShareCardView(
                message: message,
                character: character,
                characterThemeColor: characterThemeColor,
                cardIndex: index + 1,
                totalCards: messages.count,
                showShadow: true,
                showBackground: false  // 使用透明背景，让底层渐变显示
            )
            
            // 计算扩大的背景尺寸
            let backgroundPadding: CGFloat = 40  // 背景比卡片大40pt
            let backgroundWidth = 350 + backgroundPadding * 2
            let backgroundHeight = cardHeight + backgroundPadding * 2
            
            // 定义彩色渐变描边颜色 - 与多人对话保持一致
            let borderColors = [
                Color(red: 0.8, green: 0.6, blue: 1.0),   // 淡紫色
                Color(red: 1.0, green: 0.5, blue: 0.8),   // 粉色
                Color(red: 0.2, green: 0.7, blue: 1.0),   // 蓝色
                Color(red: 1.0, green: 0.6, blue: 0.2)    // 橙色
            ]
            
            let gradientCanvas = ZStack {
                // 底层渐变背景 - 扩大范围
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.85, blue: 1.0),  // 淡紫色
                        Color(red: 0.85, green: 0.95, blue: 1.0)   // 淡蓝色
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: backgroundWidth, height: backgroundHeight)
                // 保存版不使用圆角，让背景完全铺满四个角
                
                // 上层透明卡片 - 居中对齐，添加描边
                saveCardView
                    .frame(width: 350, height: cardHeight)
                    .overlay(
                        // 外层精致边框 - 彩色渐变描边
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: borderColors.map { $0.opacity(0.8) }),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3.0
                            )
                    )
                    .overlay(
                        // 内层精致边框 - 白色高光
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                            .padding(1.5)
                    )
            }
            
            guard let fullImage = renderViewAsImage(
                gradientCanvas,
                size: CGSize(width: backgroundWidth + 60, height: backgroundHeight + 60),
                opaque: false
            ) else {
                let fallbackImage = previewImageRaw.withRoundedCorners(radius: 24)
                return ShareCardResult(previewImage: previewImage, saveImage: fallbackImage)
            }
            
            let saveImage = cropImageWithColoredPadding(fullImage, targetPadding: 0) ?? fullImage
            
            return ShareCardResult(previewImage: previewImage, saveImage: saveImage)
        }
    }
    
    /// 生成合并对话卡片（将多条消息合并到一张卡片上，返回预览版和保存版）
    static func generateMergedCard(
        messages: [Message],
        character: CYChatCharacter,
        characterThemeColor: Color
    ) -> ShareCardResult {
        
        let previewCardView = ChatMergedCardView(
            messages: messages,
            character: character,
            characterThemeColor: characterThemeColor,
            showShadow: true
        )
        
        let cardHeight = previewCardView.calculateOptimalHeight()
        
        // 🎨 预览版：直接渲染卡片，应用圆角
        let previewImageRaw = renderViewAsImage(previewCardView, size: CGSize(width: 350, height: cardHeight), opaque: false) ?? previewCardView.asUIImage(size: CGSize(width: 350, height: cardHeight))
        let previewImage = previewImageRaw.withRoundedCorners(radius: 24, addGradientBackground: false)
        
        // 💾 保存版：彩色渐变背景渲染管线
        let saveCardView = ChatMergedCardView(
            messages: messages,
            character: character,
            characterThemeColor: characterThemeColor,
            showShadow: true,
            showBackground: false  // 使用透明背景，让底层渐变显示
        )
        
        // 计算扩大的背景尺寸
        let backgroundPadding: CGFloat = 40  // 背景比卡片大40pt
        let backgroundWidth = 350 + backgroundPadding * 2
        let backgroundHeight = cardHeight + backgroundPadding * 2
        
        // 定义彩色渐变描边颜色 - 与多人对话保持一致
        let borderColors = [
            Color(red: 0.8, green: 0.6, blue: 1.0),   // 淡紫色
            Color(red: 1.0, green: 0.5, blue: 0.8),   // 粉色
            Color(red: 0.2, green: 0.7, blue: 1.0),   // 蓝色
            Color(red: 1.0, green: 0.6, blue: 0.2)    // 橙色
        ]
        
        let gradientCanvas = ZStack {
            // 底层渐变背景 - 使用与主页面完全一致的梦幻渐变
            ZStack {
                // 主渐变（从上到下）
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "FFF0F5"),  // 更亮的粉白色
                        Color(hex: "FFE8F0"),  // 亮粉色
                        Color(hex: "F0E8FF"),  // 亮紫色
                        Color(hex: "E8F4FF"),  // 亮蓝色
                        Color(hex: "FFE8D4")   // 淡橙色
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // 顶部水平渐变层
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "FFE8F0").opacity(0.4),  // 左侧粉色
                        Color(hex: "FFD4E5").opacity(0.3),  // 粉红色
                        Color.clear,                         // 中间透明
                        Color(hex: "E8F4FF").opacity(0.3),  // 淡蓝色
                        Color(hex: "F0E8FF").opacity(0.4)   // 右侧紫色
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: backgroundHeight * 0.6)
                .frame(maxHeight: .infinity, alignment: .top)
                
                // 左上角明亮色彩点缀
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.8),
                        Color(hex: "FFFEF5").opacity(0.7),
                        Color(hex: "FFF9E6").opacity(0.5),
                        Color(hex: "FFE8CC").opacity(0.3),
                        Color.clear
                    ]),
                    center: .topLeading,
                    startRadius: 5,
                    endRadius: backgroundWidth * 0.8
                )
                
                // 右下角柔和色彩点缀
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "F0E8FF").opacity(0.4),
                        Color(hex: "E8F4FF").opacity(0.3),
                        Color(hex: "FFE8D4").opacity(0.2),
                        Color.clear
                    ]),
                    center: .bottomTrailing,
                    startRadius: 10,
                    endRadius: backgroundWidth * 0.5
                )
            }
            .frame(width: backgroundWidth, height: backgroundHeight)
            // 保存版不使用圆角，让背景完全铺满四个角
            
            // 上层透明卡片 - 居中对齐，添加描边
            saveCardView
                .frame(width: 350, height: cardHeight)
                .overlay(
                    // 外层精致边框 - 彩色渐变描边
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: borderColors.map { $0.opacity(0.8) }),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3.0
                        )
                )
                .overlay(
                    // 内层精致边框 - 白色高光
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                        .padding(1.5)
                )
        }
        
        guard let fullImage = renderViewAsImage(
            gradientCanvas,
            size: CGSize(width: backgroundWidth + 60, height: backgroundHeight + 60),
            opaque: false
        ) else {
            let fallbackImage = previewImageRaw.withRoundedCorners(radius: 24)
            return ShareCardResult(previewImage: previewImage, saveImage: fallbackImage)
        }
        
        let saveImage = cropImageWithColoredPadding(fullImage, targetPadding: 0) ?? fullImage
        
        return ShareCardResult(previewImage: previewImage, saveImage: saveImage)
    }
    
    // MARK: - 像素级精确裁剪（与MultiChatShareCardGenerator保持一致）
    
    /// 彩色背景的像素级精确裁剪，通过检测阴影边界来定位卡片
    private static func cropImageWithColoredPadding(_ image: UIImage, targetPadding: CGFloat) -> UIImage? {
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
        
        // 获取画布的背景色（采样左上角）
        let bgR = data[0]
        let bgG = data[1]
        let bgB = data[2]
        
        // 判断像素是否为背景色（包括轻微渐变）
        // 允许一定的色差以适应渐变背景
        func isBackgroundPixel(r: UInt8, g: UInt8, b: UInt8) -> Bool {
            let threshold: Int = 40  // 色差阈值
            return abs(Int(r) - Int(bgR)) < threshold &&
                   abs(Int(g) - Int(bgG)) < threshold &&
                   abs(Int(b) - Int(bgB)) < threshold
        }
        
        // 找到内容的边界（非背景像素的最小最大坐标）
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
                
                if !isBackgroundPixel(r: r, g: g, b: b) {
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                }
            }
        }
        
        // 如果没找到内容，返回原图
        guard minX < maxX && minY < maxY else {
            return image
        }
        
        // 计算裁剪区域：左右上贴边，只在底部保留少量边距
        let bottomPaddingPixels = Int(8 * scale)  // 底部保留8pt边距
        let cropX = minX  // 左边贴边
        let cropY = minY  // 上边贴边
        let cropWidth = maxX - minX + 1  // 右边贴边
        let cropHeight = min(height - cropY, maxY - minY + 1 + bottomPaddingPixels)  // 只在底部加边距
        
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
}

// 通用的高质量渲染函数（与MultiChatShareCardGenerator保持一致）
private func renderViewAsImage<T: View>(_ view: T, size: CGSize, opaque: Bool) -> UIImage? {
    let controller = UIHostingController(rootView: view)
    controller.view.frame = CGRect(origin: .zero, size: size)
    controller.view.bounds = CGRect(origin: .zero, size: size)
    controller.view.backgroundColor = opaque ? .white : .clear
    
    let window = UIWindow(frame: CGRect(origin: .zero, size: size))
    window.rootViewController = controller
    window.backgroundColor = opaque ? .white : .clear
    window.isHidden = false
    
    controller.view.setNeedsLayout()
    controller.view.layoutIfNeeded()
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.02))
    controller.view.setNeedsLayout()
    controller.view.layoutIfNeeded()
    
    let format = UIGraphicsImageRendererFormat()
    format.scale = 3.0
    format.opaque = opaque
    format.preferredRange = .standard
    
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    let image = renderer.image { _ in
        controller.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
    }
    
    window.isHidden = true
    window.rootViewController = nil
    
    return image
}

/**
 * 聊天分享卡片视图（与多人聊天样式完全一致）
 */
struct ChatShareCardView: View {
    let message: Message
    let character: CYChatCharacter
    let characterThemeColor: Color
    let cardIndex: Int?
    let totalCards: Int?
    let showShadow: Bool
    let showBackground: Bool
    
    init(
        message: Message,
        character: CYChatCharacter,
        characterThemeColor: Color,
        cardIndex: Int? = nil,
        totalCards: Int? = nil,
        showShadow: Bool = true,
        showBackground: Bool = true
    ) {
        self.message = message
        self.character = character
        self.characterThemeColor = characterThemeColor
        self.cardIndex = cardIndex
        self.totalCards = totalCards
        self.showShadow = showShadow
        self.showBackground = showBackground
    }
    
    // 计算最佳高度（针对单条消息优化，更加紧凑）
    func calculateOptimalHeight() -> CGFloat {
        // 1. 固定高度部分
        let headerHeight: CGFloat = 36  // 顶部固定高度
        let footerHeight: CGFloat = 70  // 底部固定高度
        let contentVerticalPadding: CGFloat = 24 // 内容区域上下padding（从16增加到24）
        
        // 2. 单条消息的精确高度计算
        let avatarHeight: CGFloat = 42 // 头像高度（从35增加到42）
        let nameHeight: CGFloat = 18   // 名称标签高度（从16增加到18，适配14pt字体）
        
        // 3. 估算文本高度
        let textLength = message.content.count
        let charactersPerLine: CGFloat = 18 // 每行约18个字符（字体变大后每行字符数减少）
        let estimatedLines = max(2, ceil(CGFloat(textLength) / charactersPerLine))
        let textHeight = estimatedLines * 20 + 14 // 20 = 15pt字体 + 4pt行间距 + 1pt额外空间，+14为文本padding（从12增加到14）
        
        // 4. VStack间距（名称和文本之间）
        let vStackSpacing: CGFloat = 6 // 实际代码中的spacing（从5增加到6）
        
        // 5. 消息内容区域高度（取头像和内容的最大值）
        let contentHeight = nameHeight + vStackSpacing + textHeight
        let messageContentHeight = max(avatarHeight, contentHeight)
        
        // 6. 计算总高度
        let totalHeight = headerHeight + 
                         footerHeight + 
                         contentVerticalPadding + 
                         messageContentHeight
        
        // 7. 设置合理的高度范围（单条消息更紧凑）
        let minHeight: CGFloat = 260  // 降低最小高度
        let maxHeight: CGFloat = 800  // 单条消息不会太长
        
        return max(minHeight, min(maxHeight, totalHeight))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 简化的顶部区域 - 固定高度
            headerSection
                .frame(height: 36)  // 固定顶部高度
            
            // 主要内容区域 - 对话消息（动态高度）
            contentSection
            
            // 底部水印区域 - 固定高度
            footerSection
                .frame(height: 70)  // 固定底部高度
        }
        .frame(width: 350, height: calculateOptimalHeight())
        .background(
            showBackground ? AnyView(
            ZStack {
                    // 主渐变（从上到下）- 完全参考主页面的梦幻渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "FFF0F5"),  // 更亮的粉白色
                        Color(hex: "FFE8F0"),  // 亮粉色
                        Color(hex: "F0E8FF"),  // 亮紫色
                        Color(hex: "E8F4FF"),  // 亮蓝色
                        Color(hex: "FFE8D4")   // 淡橙色
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                    // 顶部水平渐变层（从左到右的色彩变化）- 与主页面完全一致
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "FFE8F0").opacity(0.4),  // 左侧粉色
                        Color(hex: "FFD4E5").opacity(0.3),  // 粉红色
                        Color.clear,                         // 中间透明
                        Color(hex: "E8F4FF").opacity(0.3),  // 淡蓝色
                        Color(hex: "F0E8FF").opacity(0.4)   // 右侧紫色
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                    .frame(height: 150)  // 只影响上半部分
                    .frame(maxHeight: .infinity, alignment: .top)
                
                    // 左上角明亮色彩点缀 - 与主页面完全一致
                RadialGradient(
                    gradient: Gradient(colors: [
                            Color.white.opacity(0.8),           // 更亮的白色中心
                            Color(hex: "FFFEF5").opacity(0.7),  // 极淡的奶白色
                            Color(hex: "FFF9E6").opacity(0.5),  // 非常淡的奶白色
                            Color(hex: "FFE8CC").opacity(0.3),  // 淡暖白色
                        Color.clear
                    ]),
                    center: .topLeading,
                    startRadius: 5,
                    endRadius: 200
                )
                    .frame(maxHeight: .infinity, alignment: .top)
                    
                    // 右下角柔和色彩点缀 - 增加平衡感
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "F0E8FF").opacity(0.4),  // 淡紫色中心
                            Color(hex: "E8F4FF").opacity(0.3),  // 淡蓝色
                            Color(hex: "FFE8D4").opacity(0.2),  // 淡橙色
                            Color.clear
                        ]),
                        center: .bottomTrailing,
                        startRadius: 10,
                        endRadius: 120
                    )
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            ) : AnyView(Color.clear)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(
            color: showShadow ? Color(hex: "9A8BB0").opacity(0.12) : .clear,
            radius: showShadow ? 12 : 0,
            x: 0,
            y: 0
        )
        .shadow(
            color: showShadow ? Color.black.opacity(0.05) : .clear,
            radius: showShadow ? 8 : 0,
            x: 0,
            y: 0
        )
    }
    
    // 简化的顶部区域（与MultiChatShareCardView保持一致）
    private var headerSection: some View {
        VStack(spacing: 4) {
            // 对话主题 - 显示角色名称
            Text("与\(character.name)的对话")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)  // 限制一行，避免撑高
                .padding(.horizontal, 20)
                .padding(.top, 8)  // 顶部固定间距
            
            Spacer(minLength: 0)
            
            // 简单分割线
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(height: 0.5)
                .padding(.horizontal, 20)
                .padding(.bottom, 4)  // 底部固定间距
        }
    }
    
    // 主要内容区域（与MultiChatShareCardView保持一致）
    private var contentSection: some View {
        HStack(alignment: .top, spacing: 12) {
            if !message.isFromUser {
                // 角色头像 - 使用CharacterAvatarService确保头像正确渲染
                CharacterAvatarService.shared.getAvatarView(
                    for: character.id,
                    name: character.name,
                    size: 42,  // 从35增加到42
                    useCaching: true
                )
                .overlay(
                    Circle()
                        .stroke(characterThemeColor.opacity(0.3), lineWidth: 1.5)
                )
            } else {
                // 用户消息：显示真实用户头像
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 6) {
                // 发送者名称
                if !message.isFromUser {
                    Text(character.name)
                        .font(.system(size: 14, weight: .semibold))  // 从12增加到14
                        .foregroundColor(characterThemeColor)
                        .padding(.bottom, 2)
                } else {
                    // 用户消息：显示真实用户名
                    HStack {
                        Spacer()
                        Text(UserProfileManager.shared.getCurrentUsername())
                            .font(.system(size: 14, weight: .semibold))  // 从12增加到14
                            .foregroundColor(Color(hex: "B8B5FF"))
                            .padding(.bottom, 2)
                    }
                }
                
                // 消息内容
                Text(formatMessageContent(message.content))
                    .font(.system(size: 15, weight: .medium))  // 从13增加到15
                    .lineSpacing(4)  // 从3增加到4
                    .padding(.horizontal, 14)  // 从12增加到14
                    .padding(.vertical, 10)  // 从8增加到10
                    .background(
                        ZStack {
                            // 主背景
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    message.isFromUser
                                    ? LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "B8B5FF"),
                                            Color(hex: "A8A5FF"),
                                            Color(hex: "9B98FF")
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white,
                                            Color(hex: "FAFBFF"),
                                            Color(hex: "F5F7FF")
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            // 装饰性边框
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    message.isFromUser
                                    ? LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        gradient: Gradient(colors: [
                                            characterThemeColor.opacity(0.2),
                                            characterThemeColor.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(
                            color: message.isFromUser 
                            ? Color(hex: "B8B5FF").opacity(0.25)
                            : characterThemeColor.opacity(0.15),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    )
                    .foregroundColor(message.isFromUser ? .white : .primary)
            }
            
            if message.isFromUser {
                // 用户消息：显示真实用户头像
                Group {
                    if let userAvatar = UserProfileManager.shared.getCurrentAvatarImage() {
                        Image(uiImage: userAvatar)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 42, height: 42)  // 从35增加到42
                            .clipShape(Circle())
                    } else {
                        // 如果没有自定义头像，尝试加载默认头像
                        let avatarName = UserProfileManager.shared.getCurrentAvatarName()
                        if let defaultAvatar = UIImage(named: avatarName) {
                            Image(uiImage: defaultAvatar)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 42, height: 42)  // 从35增加到42
                                .clipShape(Circle())
                        } else {
                            // 如果都没有，显示默认图标
                            Circle()
                                .fill(Color(hex: "B8B5FF"))
                                .frame(width: 42, height: 42)  // 从35增加到42
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 18))  // 从16增加到18
                                        .foregroundColor(.white)
                                )
                        }
                    }
                }
                .overlay(
                    Circle()
                        .stroke(Color(hex: "B8B5FF").opacity(0.3), lineWidth: 1.5)
                )
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)  // 从8增加到12，让内容更宽松
    }
    
    // 底部信息区域（与MultiChatShareCardView保持一致）
    private var footerSection: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            
            // 品牌标识（移除时间显示）
            HStack(spacing: 0) {
                Text("虫遇APP")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "9A8BB0"))
                
                Text(" - 打破次元壁，与万千角色对话")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 16)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
    }
    
    // 格式化消息内容
    private func formatMessageContent(_ content: String) -> String {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 大幅放宽单条消息的长度限制
        if trimmedContent.count > 500 {
            let truncated = String(trimmedContent.prefix(480))
            return truncated + "..."
        }
        
        return trimmedContent
    }
    
    // 格式化时间
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// SwiftUI View 转 UIImage 扩展（支持动态尺寸）
extension View {
    func asUIImage(size: CGSize) -> UIImage {
        let controller = UIHostingController(rootView: self)
        
        // 使用传入的动态尺寸
        controller.view.frame = CGRect(origin: .zero, size: size)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = UIColor.clear
        
        // 强制布局
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        
        // 使用高质量渲染
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

// 添加String扩展来估算文本高度
extension String {
    func estimatedTextHeight(width: CGFloat, font: UIFont, lineSpacing: CGFloat) -> CGFloat {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedString = NSAttributedString(string: self, attributes: attributes)
        let boundingRect = attributedString.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        
        return ceil(boundingRect.height)
    }
}

/**
 * 单人聊天合并卡片视图（显示多条消息的对话）
 */
struct ChatMergedCardView: View {
    let messages: [Message]
    let character: CYChatCharacter
    let characterThemeColor: Color
    let showShadow: Bool
    let showBackground: Bool
    
    init(
        messages: [Message],
        character: CYChatCharacter,
        characterThemeColor: Color,
        showShadow: Bool = true,
        showBackground: Bool = true
    ) {
        self.messages = messages
        self.character = character
        self.characterThemeColor = characterThemeColor
        self.showShadow = showShadow
        self.showBackground = showBackground
    }
    
    // 计算最佳高度
    func calculateOptimalHeight() -> CGFloat {
        let headerHeight: CGFloat = 32
        let footerHeight: CGFloat = 60
        let contentVerticalPadding: CGFloat = 24
        
        var totalMessageHeight: CGFloat = 0
        
        for message in messages {
            let avatarHeight: CGFloat = 35
            let nameHeight: CGFloat = 16
            
            let textLength = message.content.count
            let charactersPerLine: CGFloat = 20
            let estimatedLines = max(2, ceil(CGFloat(textLength) / charactersPerLine))
            let textHeight = estimatedLines * 17 + 12
            
            let vStackSpacing: CGFloat = 4
            let contentHeight = nameHeight + vStackSpacing + textHeight
            let messageHeight = max(avatarHeight, contentHeight) + 8
            
            totalMessageHeight += messageHeight
        }
        
        let messageSpacing: CGFloat = 8
        let spacingHeight = CGFloat(max(0, messages.count - 1)) * messageSpacing
        
        let totalHeight = headerHeight + footerHeight + contentVerticalPadding + totalMessageHeight + spacingHeight
        
        let minHeight: CGFloat = 180
        let maxHeight: CGFloat = 3000
        
        return max(minHeight, min(maxHeight, totalHeight))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            simplifiedHeaderSection
                .frame(height: 32)
            
            contentSection
            
            footerSection
                .frame(height: 60)
        }
        .frame(width: 350, height: calculateOptimalHeight())
        .background(
            showBackground ? AnyView(
            ZStack {
                    // 主渐变（从上到下）- 完全参考主页面的梦幻渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                            Color(hex: "FFF0F5"),  // 更亮的粉白色
                            Color(hex: "FFE8F0"),  // 亮粉色
                            Color(hex: "F0E8FF"),  // 亮紫色
                            Color(hex: "E8F4FF"),  // 亮蓝色
                            Color(hex: "FFE8D4")   // 淡橙色
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                    // 顶部水平渐变层（从左到右的色彩变化）- 与主页面完全一致
                LinearGradient(
                    gradient: Gradient(colors: [
                            Color(hex: "FFE8F0").opacity(0.4),  // 左侧粉色
                            Color(hex: "FFD4E5").opacity(0.3),  // 粉红色
                            Color.clear,                         // 中间透明
                            Color(hex: "E8F4FF").opacity(0.3),  // 淡蓝色
                            Color(hex: "F0E8FF").opacity(0.4)   // 右侧紫色
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                    .frame(height: 200)  // 合并卡片更高，影响更多区域
                    .frame(maxHeight: .infinity, alignment: .top)
                
                    // 左上角明亮色彩点缀 - 与主页面完全一致
                RadialGradient(
                    gradient: Gradient(colors: [
                            Color.white.opacity(0.8),           // 更亮的白色中心
                            Color(hex: "FFFEF5").opacity(0.7),  // 极淡的奶白色
                            Color(hex: "FFF9E6").opacity(0.5),  // 非常淡的奶白色
                            Color(hex: "FFE8CC").opacity(0.3),  // 淡暖白色
                        Color.clear
                    ]),
                    center: .topLeading,
                    startRadius: 5,
                        endRadius: 250
                    )
                    .frame(maxHeight: .infinity, alignment: .top)
                    
                    // 右下角柔和色彩点缀 - 增加平衡感
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "F0E8FF").opacity(0.4),  // 淡紫色中心
                            Color(hex: "E8F4FF").opacity(0.3),  // 淡蓝色
                            Color(hex: "FFE8D4").opacity(0.2),  // 淡橙色
                            Color.clear
                        ]),
                        center: .bottomTrailing,
                        startRadius: 15,
                        endRadius: 150
                    )
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            ) : AnyView(Color.clear)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(
            color: showShadow ? Color(hex: "9A8BB0").opacity(0.12) : .clear,
            radius: showShadow ? 12 : 0,
            x: 0,
            y: 0
        )
        .shadow(
            color: showShadow ? Color.black.opacity(0.05) : .clear,
            radius: showShadow ? 8 : 0,
            x: 0,
            y: 0
        )
    }
    
    private var simplifiedHeaderSection: some View {
        VStack(spacing: 2) {
            // 对话主题 - 显示角色名称
            Text("与\(character.name)的对话")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .padding(.horizontal, 20)
                .padding(.top, 6)
            
            Spacer(minLength: 0)
            
            // 简单分割线
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(height: 0.5)
                .padding(.horizontal, 20)
                .padding(.bottom, 2)
        }
    }
    
    private var contentSection: some View {
        VStack(spacing: 8) {
            ForEach(messages, id: \.id) { message in
                messageRow(message)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private func messageRow(_ message: Message) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if !message.isFromUser {
                // 角色头像（左侧）- 使用CharacterAvatarService确保头像正确渲染
                CharacterAvatarService.shared.getAvatarView(
                    for: character.id,
                    name: character.name,
                    size: 35,
                    useCaching: true
                )
                .overlay(
                    Circle()
                        .stroke(characterThemeColor.opacity(0.3), lineWidth: 1.5)
                )
            } else {
                // 用户消息：头像在右侧，先留空
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 5) {
                // 发送者名称
                if !message.isFromUser {
                    Text(character.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(characterThemeColor)
                        .padding(.bottom, 2)
                } else {
                    // 用户消息：显示真实用户名
                    HStack {
                        Spacer()
                        Text(UserProfileManager.shared.getCurrentUsername())
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "B8B5FF"))
                            .padding(.bottom, 2)
                    }
                }
                
                // 消息内容（带气泡）
                Text(formatMessageContent(message.content))
                    .font(.system(size: 13, weight: .medium))
                    .lineSpacing(3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            // 主背景
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    message.isFromUser
                                    ? LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "B8B5FF"),
                                            Color(hex: "A8A5FF"),
                                            Color(hex: "9B98FF")
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white,
                                            Color(hex: "FAFBFF"),
                                            Color(hex: "F5F7FF")
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            // 装饰性边框
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    message.isFromUser
                                    ? LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        gradient: Gradient(colors: [
                                            characterThemeColor.opacity(0.2),
                                            characterThemeColor.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(
                            color: message.isFromUser 
                            ? Color(hex: "B8B5FF").opacity(0.25)
                            : characterThemeColor.opacity(0.15),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    )
                    .foregroundColor(message.isFromUser ? .white : .primary)
            }
            
            if message.isFromUser {
                // 用户消息：显示真实用户头像（右侧）
                Group {
                    if let userAvatar = UserProfileManager.shared.getCurrentAvatarImage() {
                        Image(uiImage: userAvatar)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 35, height: 35)
                            .clipShape(Circle())
                    } else {
                        // 如果没有自定义头像，尝试加载默认头像
                        let avatarName = UserProfileManager.shared.getCurrentAvatarName()
                        if let defaultAvatar = UIImage(named: avatarName) {
                            Image(uiImage: defaultAvatar)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 35, height: 35)
                                .clipShape(Circle())
                        } else {
                            // 如果都没有，显示默认图标
                            Circle()
                                .fill(Color(hex: "B8B5FF"))
                                .frame(width: 35, height: 35)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                }
                .overlay(
                    Circle()
                        .stroke(Color(hex: "B8B5FF").opacity(0.3), lineWidth: 1.5)
                )
            } else {
                Spacer()
            }
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 0) {
            // 上方较小的spacer，让文字靠上
            Spacer(minLength: 4)
                .frame(maxHeight: 8)
            
            // 品牌标识（移除时间显示）
            HStack(spacing: 0) {
                Text("虫遇APP")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(hex: "9A8BB0"))
                
                Text(" - 打破次元壁，与万千角色对话")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)
            
            // 下方较大的spacer，让底部空间更大
            Spacer(minLength: 12)
        }
        .padding(.horizontal, 20)
    }
    
    private func formatMessageContent(_ content: String) -> String {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 对于合并卡片，大幅放宽长度限制
        if trimmedContent.count > 300 {
            let truncated = String(trimmedContent.prefix(280))
            return truncated + "..."
        }
        
        return trimmedContent
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    let sampleMessage = Message(
        conversationId: "test",
        senderId: "einstein",
        receiverId: "user",
        content: "你以为相对论是灵光乍现？那个追着光奔跑的邮局小职员，在伯尔尼的阁楼里啃了八年发霉面包才抓住时空的衣角。",
        isFromUser: false
    )
    
    let sampleCharacter = CYChatCharacter(
        id: "einstein",
        name: "爱因斯坦",
        introduction: "理论物理学家",
        field: "物理学",
        birthYear: "1879",
        deathYear: "1955",
        avatarUrl: "",
        eraTag: "现代",
        achievements: [],
        mainWorks: [],
        keyThoughts: []
    )
    
    return ChatShareCardView(
        message: sampleMessage,
        character: sampleCharacter,
        characterThemeColor: .blue,
        cardIndex: 1,
        totalCards: 3
    )
}
