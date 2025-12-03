import SwiftUI
import UIKit

/**
 * 分享卡片结果
 * 包含预览版和保存版两个图片
 */
struct ShareCardResult {
    let previewImage: UIImage  // 预览版（无白边，用于界面显示）
    let saveImage: UIImage     // 保存版（带白边，用于保存和分享）
}

/**
 * 多人聊天分享卡片生成器
 * 用于生成多人对话的精美分享卡片
 */
class MultiChatShareCardGenerator {
    
    /// 生成分享卡片图片（返回预览版和保存版）
    static func generateCard(
        message: ChatMessage,
        character: CharacterModel,
        theme: String
    ) -> ShareCardResult {
        
        // 预览版（带阴影）
        let previewCardView = MultiChatShareCardView(
            message: message,
            character: character,
            theme: theme,
            showShadow: true
        )
        
        let cardHeight = previewCardView.calculateOptimalHeight()
        
        // 🎨 预览版：直接渲染卡片，应用圆角
        let previewImageRaw = renderViewAsImage(previewCardView, size: CGSize(width: 320, height: cardHeight), opaque: false) ?? previewCardView.asUIImage(size: CGSize(width: 320, height: cardHeight))
        let previewImage = previewImageRaw.withRoundedCorners(radius: 24, addGradientBackground: false)
        
        // 💾 保存版：彩色渐变背景渲染管线
        let saveCardView = MultiChatShareCardView(
            message: message,
            character: character,
            theme: theme,
            showShadow: true,
            showBackground: false  // 使用透明背景，让底层渐变显示
        )
        
        // 计算扩大的背景尺寸
        let backgroundPadding: CGFloat = 40  // 背景比卡片大40pt
        let backgroundWidth = 320 + backgroundPadding * 2
        let backgroundHeight = cardHeight + backgroundPadding * 2
        
        // 定义彩色渐变描边颜色 - 参考主页面帖子分享卡片
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
                .frame(width: 320, height: cardHeight)
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
        messages: [ChatMessage],
        characters: [CharacterModel],
        theme: String
    ) -> [ShareCardResult] {
        
        return messages.enumerated().map { index, message in
            let character = characters.first(where: { $0.id == message.characterId }) ?? characters.first!
            
            let previewCardView = MultiChatShareCardView(
                message: message,
                character: character,
                theme: theme,
                cardIndex: index + 1,
                totalCards: messages.count,
                showShadow: true
            )
            
            let cardHeight = previewCardView.calculateOptimalHeight()
            
            // 🎨 预览版：直接渲染卡片，应用圆角
            let previewImageRaw = renderViewAsImage(previewCardView, size: CGSize(width: 320, height: cardHeight), opaque: false) ?? previewCardView.asUIImage(size: CGSize(width: 320, height: cardHeight))
            let previewImage = previewImageRaw.withRoundedCorners(radius: 24, addGradientBackground: false)
            
            // 💾 保存版：彩色渐变背景渲染管线
            let saveCardView = MultiChatShareCardView(
                message: message,
                character: character,
                theme: theme,
                cardIndex: index + 1,
                totalCards: messages.count,
                showShadow: true,
                showBackground: false  // 使用透明背景，让底层渐变显示
            )
            
            // 计算扩大的背景尺寸
            let backgroundPadding: CGFloat = 40  // 背景比卡片大40pt
            let backgroundWidth = 320 + backgroundPadding * 2
            let backgroundHeight = cardHeight + backgroundPadding * 2
            
            // 定义彩色渐变描边颜色 - 参考主页面帖子分享卡片
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
                    .frame(width: 320, height: cardHeight)
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
        messages: [ChatMessage],
        characters: [CharacterModel],
        theme: String
    ) -> ShareCardResult {
        
        let previewCardView = MultiChatMergedCardView(
            messages: messages,
            characters: characters,
            theme: theme,
            showShadow: true
        )
        
        let cardHeight = previewCardView.calculateOptimalHeight()
        
        // 🎨 预览版：直接渲染卡片，应用圆角
        let previewImageRaw = renderViewAsImage(previewCardView, size: CGSize(width: 320, height: cardHeight), opaque: false) ?? previewCardView.asUIImage(size: CGSize(width: 320, height: cardHeight))
        let previewImage = previewImageRaw.withRoundedCorners(radius: 24, addGradientBackground: false)
        
        // 💾 保存版：彩色渐变背景渲染管线
        let saveCardView = MultiChatMergedCardView(
            messages: messages,
            characters: characters,
            theme: theme,
            showShadow: true,
            showBackground: false  // 使用透明背景，让底层渐变显示
        )
        
        // 计算扩大的背景尺寸
        let backgroundPadding: CGFloat = 40  // 背景比卡片大40pt
        let backgroundWidth = 320 + backgroundPadding * 2
        let backgroundHeight = cardHeight + backgroundPadding * 2
        
        // 定义彩色渐变描边颜色 - 参考主页面帖子分享卡片
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
                .frame(width: 320, height: cardHeight)
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
    
    // MARK: - 像素级精确裁剪（与PostShareModalView保持一致）
    
    /// 像素级精确裁剪，确保上下左右白边完全一致
    private static func cropImageWithUniformPadding(_ image: UIImage, targetPadding: CGFloat) -> UIImage? {
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
            return image
        }
        
        // 转换目标padding到像素单位
        let paddingPixels = Int(targetPadding * scale)
        
        // 🔍 调试日志
        print("🔍 MultiChat边界检测:")
        print("   画布: \(width)×\(height)px (scale=\(scale))")
        print("   内容边界: x[\(minX), \(maxX)] y[\(minY), \(maxY)]")
        print("   内容尺寸: \((maxX - minX + 1))×\((maxY - minY + 1))px")
        print("   目标padding: \(targetPadding)pt = \(paddingPixels)px")
        
        // 计算裁剪区域（内容边界 + 目标padding）
        let cropX = max(0, minX - paddingPixels)
        let cropY = max(0, minY - paddingPixels)
        let cropWidth = min(width - cropX, maxX - minX + 1 + 2 * paddingPixels)
        let cropHeight = min(height - cropY, maxY - minY + 1 + 2 * paddingPixels)
        
        print("   裁剪区域: (\(cropX), \(cropY), \(cropWidth), \(cropHeight))")
        print("   实际白边: 左=\(minX - cropX)px 右=\(cropX + cropWidth - maxX - 1)px 上=\(minY - cropY)px 下=\(cropY + cropHeight - maxY - 1)px")
        
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

/**
 * 多人聊天合并卡片视图（显示多条消息的对话）
 */
struct MultiChatMergedCardView: View {
    let messages: [ChatMessage]
    let characters: [CharacterModel]
    let theme: String
    let showShadow: Bool
    let showBackground: Bool
    
    init(
        messages: [ChatMessage],
        characters: [CharacterModel],
        theme: String,
        showShadow: Bool = true,
        showBackground: Bool = true
    ) {
        self.messages = messages
        self.characters = characters
        self.theme = theme
        self.showShadow = showShadow
        self.showBackground = showBackground
    }
    
    // 当消息数量较少时，头部需要更紧凑
    private var isSparseMessages: Bool { messages.count <= 2 }
    
    // 计算最佳高度 - 基于实际UI组件的精确计算
    func calculateOptimalHeight() -> CGFloat {
        // 精确计算各个区域的实际高度
        // 少量消息时收紧头部高度，避免上半部分留白过多
        let _ = messages.count <= 2  // 未使用的变量，用 _ 替代
        let headerHeight: CGFloat = 32  // 简化头部：主题文本 + 分割线 + padding (更紧凑)
        let footerHeight: CGFloat = 60  // 底部水印区域（减少高度，更紧凑）
        let contentVerticalPadding: CGFloat = 24 // 内容区域上下padding（12+12）
        
        // 精确计算每条消息的实际高度
        var totalMessageHeight: CGFloat = 0
        
        for message in messages {
            // 1. 头像区域高度（固定35px）
            let avatarHeight: CGFloat = 35
            
            // 2. 名称标签高度（如果不是用户消息）
            let nameHeight: CGFloat = message.isUserMessage ? 16 : 16 // 用户消息也有"引导者"标签
            
            // 3. 精确计算文本区域高度
            let textLength = message.content.count
            // 更保守的每行字符数估算（考虑中文字符宽度）
            let charactersPerLine: CGFloat = 20
            let estimatedLines = max(2, ceil(CGFloat(textLength) / charactersPerLine))
            // 考虑字体大小(13pt) + 行间距(2pt) + 文本padding(12pt垂直)
            let textHeight = estimatedLines * 17 + 12 // 17 = 13pt字体 + 2pt行间距 + 2pt额外空间
            
            // 4. VStack间距（名称和文本之间）
            let vStackSpacing: CGFloat = 4
            
            // 5. 消息行的实际高度取最大值（头像高度 vs 文本总高度）
            let contentHeight = nameHeight + vStackSpacing + textHeight
            let messageHeight = max(avatarHeight, contentHeight) + 8 // 8px额外缓冲
            
            totalMessageHeight += messageHeight
        }
        
        // 消息间距（VStack spacing: 8）
        let messageSpacing: CGFloat = 8
        let spacingHeight = CGFloat(max(0, messages.count - 1)) * messageSpacing
        
        // 计算总高度
        let totalHeight = headerHeight + footerHeight + contentVerticalPadding + totalMessageHeight + spacingHeight
        
        // 降低最小高度限制，让卡片能适应少量内容
        let minHeight: CGFloat = 180 // 从400降低到180，适应短对话
        let maxHeight: CGFloat = 3000 // 大幅提高上限
        
        let finalHeight = max(minHeight, min(maxHeight, totalHeight))
        
        print("[MultiChatCard] 消息数量: \(messages.count), 计算高度: \(finalHeight), 消息总高度: \(totalMessageHeight)")
        
        return finalHeight
    }
    
    var body: some View {
        let totalHeight = calculateOptimalHeight()
        let headerHeight: CGFloat = 32
        let footerHeight: CGFloat = 60
        let contentHeight = totalHeight - headerHeight - footerHeight
        
        return VStack(spacing: 0) {
            // 简化的顶部区域 - 固定高度
            simplifiedHeaderSection
                .frame(height: headerHeight)
            
            // 主要内容区域 - 明确设置高度，确保填充剩余空间
            contentSection
                .frame(height: contentHeight, alignment: .top)
            
            // 底部水印区域 - 固定高度
            footerSection
                .frame(height: footerHeight)
        }
        .frame(width: 320, height: totalHeight)
        .background(
            ZStack {
                // 主渐变（从上到下）- 参考主页面的梦幻渐变
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
                
                // 顶部水平渐变层（从左到右的色彩变化）
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
                
                // 左上角明亮色彩点缀
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.6),           // 亮白色中心
                        Color(hex: "FFFEF5").opacity(0.5),  // 极淡的奶白色
                        Color(hex: "FFF9E6").opacity(0.3),  // 非常淡的奶白色
                        Color.clear
                    ]),
                    center: .topLeading,
                    startRadius: 5,
                    endRadius: 200
                )
            }
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
    
    // 简化的顶部区域
    private var simplifiedHeaderSection: some View {
        VStack(spacing: 2) {  // 减少内部间距
            // 对话主题（如果有）- 弱化显示效果
            if !theme.isEmpty {
                Text(theme)
                    .font(.system(size: 15, weight: .medium))  // 字体稍小
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)  // 限制一行，避免撑高
                    .padding(.horizontal, 20)
                    .padding(.top, 6)  // 顶部间距减少
            }
            
            Spacer(minLength: 0)
            
            // 简单分割线
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(height: 0.5)
                .padding(.horizontal, 20)
                .padding(.bottom, 2)  // 底部间距减少
        }
    }
    
    // 底部水印区域（保留下方的统一实现，移除此处重复定义）
    // 已合并到文件后半部分的 footerSection 定义中
    
    // 参与角色展示
    private var participantsSection: some View {
        let uniqueCharacters = getUniqueCharacters()
        
        return HStack(spacing: 8) {
            ForEach(Array(uniqueCharacters.enumerated()), id: \.offset) { index, character in
                CharacterAvatarService.shared.getAvatarView(
                    for: character.id,
                    name: character.name,
                    category: character.category.rawValue,
                    size: 30,
                    useCaching: true
                )
                .overlay(
                    Circle()
                        .stroke(getCharacterColor(for: character).opacity(0.3), lineWidth: 1.5)
                )
                
                if index < uniqueCharacters.count - 1 {
                    Text(character.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            if messages.contains(where: { $0.isUserMessage }) {
                Text("引导者")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // 主要内容区域 - 对话列表（移除高度限制）
    private var contentSection: some View {
        VStack(spacing: 8) {  // 减少消息间距从10到8
            ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                messageRow(message: message, index: index)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)  // 增加一点垂直padding，让内容不贴边
    }
    
    // 单条消息行
    private func messageRow(message: ChatMessage, index: Int) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if !message.isUserMessage {
                // 角色头像
                if let character = characters.first(where: { $0.id == message.characterId }) {
                    CharacterAvatarService.shared.getAvatarView(
                        for: character.id,
                        name: character.name,
                        category: character.category.rawValue,
                        size: 35,
                        useCaching: true
                    )
                    .overlay(
                        Circle()
                            .stroke(getCharacterColor(for: character).opacity(0.3), lineWidth: 1.5)
                    )
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 35, height: 35)
                }
            } else {
                // 用户消息：显示真实用户头像
                Spacer()
            }
            
            VStack(alignment: message.isUserMessage ? .trailing : .leading, spacing: 5) {
                // 发送者名称
                if !message.isUserMessage {
                    if let character = characters.first(where: { $0.id == message.characterId }) {
                        Text(character.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "9A8BB0"))
                            .padding(.bottom, 2)
                    }
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
                
                // 消息内容
                Text(formatMessageContent(message.content))
                    .font(.system(size: 13.5, weight: .regular))
                    .lineSpacing(4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            // 主背景
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    message.isUserMessage
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
                                    message.isUserMessage
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
                                            getMessageBackgroundColor(for: message).opacity(0.2),
                                            getMessageBackgroundColor(for: message).opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    .shadow(
                        color: message.isUserMessage 
                        ? Color(hex: "B8B5FF").opacity(0.35)
                        : getMessageBackgroundColor(for: message).opacity(0.18),
                        radius: 10,
                        x: 0,
                        y: 5
                    )
                    )
                    .foregroundColor(message.isUserMessage ? .white : .primary)
            }
            
            if message.isUserMessage {
                // 用户消息：显示真实用户头像
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
    
    // 底部信息区域
    private var footerSection: some View {
        VStack(spacing: 0) {
            // 上方较小的spacer，让文字靠上
            Spacer(minLength: 4)
                .frame(maxHeight: 8)  // 限制上方空间
            
            // 品牌标识（移除时间显示）
            HStack(spacing: 0) {
                Text("虫遇APP")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(hex: "9A8BB0"))
                
                Text(" - 打破次元壁，与万千角色对话")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 4)  // 减少底部padding，优化空隙
            
            // 下方较小的spacer，减少底部空隙
            Spacer(minLength: 4)
        }
        .padding(.horizontal, 20)
    }
    
    // 获取唯一角色列表
    private func getUniqueCharacters() -> [CharacterModel] {
        let characterIds = Set(messages.compactMap { $0.isUserMessage ? nil : $0.characterId })
        return characterIds.compactMap { id in
            characters.first(where: { $0.id == id })
        }
    }
    
    // 获取角色主题色
    private func getCharacterColor(for character: CharacterModel) -> Color {
        switch character.category {
        case .historical:
            return Color(hex: "4A90E2")  // 历史人物（包含科学家、艺术家）
        case .philosopher:
            return Color(hex: "9A8BB0")
        case .writer:
            return Color(hex: "50E3C2")
        case .animeCharacter:
            return Color(hex: "BD10E0")
        case .gameCharacter:
            return Color(hex: "B8E986")
        case .filmCharacter:
            return Color(hex: "7ED321")
        case .mythCharacter:
            return Color(hex: "417505")
        case .historical:
            return Color(hex: "8B4513")
        case .all:
            return Color(hex: "9A8BB0")
        }
    }
    
    // 获取消息背景色
    private func getMessageBackgroundColor(for message: ChatMessage) -> Color {
        if let character = characters.first(where: { $0.id == message.characterId }) {
            return getCharacterColor(for: character)
        }
        return Color(hex: "9A8BB0")
    }
    
    // 格式化消息内容
    private func formatMessageContent(_ content: String) -> String {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 对于合并卡片，大幅放宽长度限制
        if trimmedContent.count > 300 {
            let truncated = String(trimmedContent.prefix(280))
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

/**
 * 多人聊天分享卡片视图
 */
struct MultiChatShareCardView: View {
    let message: ChatMessage
    let character: CharacterModel
    let theme: String
    let cardIndex: Int?
    let totalCards: Int?
    let showShadow: Bool
    let showBackground: Bool
    
    init(
        message: ChatMessage,
        character: CharacterModel,
        theme: String,
        cardIndex: Int? = nil,
        totalCards: Int? = nil,
        showShadow: Bool = true,
        showBackground: Bool = true
    ) {
        self.message = message
        self.character = character
        self.theme = theme
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
        let contentVerticalPadding: CGFloat = 16 // 内容区域上下padding（进一步压缩至8+8）
        
        // 2. 单条消息的精确高度计算
        let avatarHeight: CGFloat = 35 // 头像高度
        let nameHeight: CGFloat = 16   // 名称标签高度
        
        // 3. 估算文本高度
        let textLength = message.content.count
        let charactersPerLine: CGFloat = 20 // 每行约20个字符（考虑中文）
        let estimatedLines = max(2, ceil(CGFloat(textLength) / charactersPerLine))
        let textHeight = estimatedLines * 17 + 12 // 17 = 13pt字体 + 2pt行间距 + 2pt额外空间，+12为文本padding
        
        // 4. VStack间距（名称和文本之间）
        let vStackSpacing: CGFloat = 5 // 实际代码中的spacing
        
        // 5. 消息内容区域高度（取头像和内容的最大值）
        let contentHeight = nameHeight + vStackSpacing + textHeight
        let messageContentHeight = max(avatarHeight, contentHeight)
        
        // 6. 计算总高度
        let totalHeight = headerHeight + 
                         footerHeight + 
                         contentVerticalPadding + 
                         messageContentHeight
        
        // 7. 设置合理的高度范围（单条消息更紧凑）
        let minHeight: CGFloat = 260  // 进一步降低最小高度
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
        .frame(width: 320, height: calculateOptimalHeight())
        .background(
            showBackground ? AnyView(
                ZStack {
                    // 主渐变（从上到下）- 参考主页面的梦幻渐变
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
                    
                    // 顶部水平渐变层（从左到右的色彩变化）
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
                    
                    // 左上角明亮色彩点缀
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.6),           // 亮白色中心
                            Color(hex: "FFFEF5").opacity(0.5),  // 极淡的奶白色
                            Color(hex: "FFF9E6").opacity(0.3),  // 非常淡的奶白色
                            Color.clear
                        ]),
                        center: .topLeading,
                        startRadius: 5,
                        endRadius: 200
                    )
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
    
    // 简化的顶部区域（与MultiChatMergedCardView保持一致）
    private var headerSection: some View {
        VStack(spacing: 4) {
            // 对话主题（如果有）- 弱化显示效果
            if !theme.isEmpty {
                Text(theme)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)  // 限制一行，避免撑高
                    .padding(.horizontal, 20)
                    .padding(.top, 8)  // 顶部固定间距
            }
            
            Spacer(minLength: 0)
            
            // 简单分割线
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(height: 0.5)
                .padding(.horizontal, 20)
                .padding(.bottom, 4)  // 底部固定间距
        }
    }
    
    // 主要内容区域
    private var contentSection: some View {
        HStack(alignment: .top, spacing: 10) {
            if !message.isUserMessage {
                // 角色头像
                CharacterAvatarService.shared.getAvatarView(
                    for: character.id,
                    name: character.name,
                    category: character.category.rawValue,
                    size: 35,
                    useCaching: true
                )
                .overlay(
                    Circle()
                        .stroke(getCharacterColor().opacity(0.3), lineWidth: 1.5)
                )
            } else {
                // 用户消息：显示真实用户头像
                Spacer()
            }
            
            VStack(alignment: message.isUserMessage ? .trailing : .leading, spacing: 5) {
                // 发送者名称
                if !message.isUserMessage {
                    Text(character.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(getCharacterColor())
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
                
                // 消息内容
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
                                    message.isUserMessage
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
                                    message.isUserMessage
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
                                            getCharacterColor().opacity(0.2),
                                            getCharacterColor().opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(
                            color: message.isUserMessage 
                            ? Color(hex: "B8B5FF").opacity(0.25)
                            : getCharacterColor().opacity(0.15),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    )
                    .foregroundColor(message.isUserMessage ? .white : .primary)
            }
            
            if message.isUserMessage {
                // 用户消息：显示真实用户头像
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
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)  // 减少上下padding，让卡片更紧凑
    }
    
    // 底部信息区域（与MultiChatMergedCardView保持一致）
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
            .padding(.bottom, 4)  // 减少底部padding，优化空隙
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
    }
    
    // 获取角色主题色
    private func getCharacterColor() -> Color {
        // 根据角色类别返回不同的主题色
        switch character.category {
        case .historical:
            return Color(hex: "4A90E2")  // 历史人物（包含科学家、艺术家）
        case .philosopher:
            return Color(hex: "9A8BB0")
        case .writer:
            return Color(hex: "50E3C2")
        case .animeCharacter:
            return Color(hex: "BD10E0")
        case .gameCharacter:
            return Color(hex: "B8E986")
        case .filmCharacter:
            return Color(hex: "7ED321")
        case .mythCharacter:
            return Color(hex: "417505")
        case .historical:
            return Color(hex: "8B4513")
        case .all:
            return Color(hex: "9A8BB0")
        }
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

#Preview(traits: .sizeThatFitsLayout) {
    let sampleMessage = ChatMessage(
        characterId: "confucius",
        content: "学而时习之，不亦说乎？有朋自远方来，不亦乐乎？人不知而不愠，不亦君子乎？",
        timestamp: Date()
    )
    
    let sampleCharacter = CharacterModel(
        id: "confucius",
        name: "孔子",
        avatar: "confucius",
        era: "春秋时期",
        profession: "思想家、教育家",
        bio: "中国古代思想家、教育家，儒家学说的创立者",
        category: .philosopher
    )
    
    MultiChatShareCardView(
        message: sampleMessage,
        character: sampleCharacter,
        theme: "探讨教育的本质",
        cardIndex: 1,
        totalCards: 3
    )
    // traits: .sizeThatFitsLayout will handle sizing
}

// UIImage 圆角裁剪扩展
extension UIImage {
    func withRoundedCorners(radius: CGFloat, addGradientBackground: Bool = true) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        
        // 创建圆角路径
        let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        context.addPath(path.cgPath)
        context.clip()
        
        // 只有在需要时才绘制渐变背景
        if addGradientBackground {
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor(red: 0.95, green: 0.85, blue: 1.0, alpha: 1.0).cgColor,  // 淡紫色
                UIColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1.0).cgColor   // 淡蓝色
            ] as CFArray
            
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil) {
                // 绘制渐变背景（从左上到右下）
                context.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: rect.width, y: rect.height),
                    options: []
                )
            }
        }
        
        // 绘制原图片
        draw(in: rect)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

// 通用的高质量渲染函数（与帖子分享一致的窗口渲染法）
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

