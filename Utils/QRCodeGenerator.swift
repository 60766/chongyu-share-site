import SwiftUI
import CoreImage.CIFilterBuiltins

/**
 * QR码生成器
 * 用于生成带有自定义样式的二维码图像
 */
class QRCodeGenerator {
    // 单例实例，便于全局访问
    static let shared = QRCodeGenerator()
    
    // CoreImage上下文
    private let context = CIContext()
    
    // 过滤器实例
    private let filter = CIFilter.qrCodeGenerator()
    
    private init() {}
    
    /**
     * 生成基础二维码图像
     * @param string 要编码到二维码中的字符串
     * @param correctionLevel 纠错级别，默认为"M"(中等)
     * @return 返回UIImage类型的二维码图像
     */
    func generateQRCode(from string: String, correctionLevel: String = "M") -> UIImage? {
        // 设置输入数据
        let data = string.data(using: .utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        // 设置纠错级别 (L:7%, M:15%, Q:25%, H:30%)
        filter.setValue(correctionLevel, forKey: "inputCorrectionLevel")
        
        // 获取生成的图像
        guard let ciImage = filter.outputImage else { return nil }
        
        // 将CIImage转换为UIImage
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCIImage = ciImage.transformed(by: transform)
        
        guard let cgImage = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /**
     * 生成带有自定义样式的二维码
     * @param string 要编码的字符串
     * @param size 二维码尺寸
     * @param foregroundColor 前景色
     * @param backgroundColor 背景色
     * @param logo 中间的Logo图片(可选)
     * @param logoSize Logo的尺寸比例(0-1之间)
     * @return 返回自定义样式的二维码图像
     */
    func generateStyledQRCode(
        from string: String,
        size: CGSize = CGSize(width: 200, height: 200),
        foregroundColor: UIColor = .black,
        backgroundColor: UIColor = .white,
        logo: UIImage? = nil,
        logoSize: CGFloat = 0.2,
        logoCornerRadius: CGFloat = 8
    ) -> UIImage? {
        // 基本二维码生成
        guard let qrImage = generateQRCode(from: string) else { return nil }
        
        // 开始自定义渲染
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 填充背景
        context.setFillColor(backgroundColor.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // 绘制二维码
        let rect = CGRect(origin: .zero, size: size)
        
        // 设置二维码颜色
        UIGraphicsGetCurrentContext()?.saveGState()
        UIGraphicsGetCurrentContext()?.setBlendMode(.normal)
        
        // 着色处理
        let tintedImage = tintImage(qrImage, with: foregroundColor)
        tintedImage.draw(in: rect)
        
        // 中心添加Logo(如果有)
        if let logo = logo {
            let logoWidth = size.width * logoSize
            let logoHeight = size.height * logoSize
            let logoX = (size.width - logoWidth) / 2
            let logoY = (size.height - logoHeight) / 2
            let logoRect = CGRect(x: logoX, y: logoY, width: logoWidth, height: logoHeight)
            
            // 绘制白色背景
            UIBezierPath(roundedRect: logoRect, cornerRadius: logoCornerRadius).fill()
            
            // 绘制Logo
            drawRoundedImage(logo, in: logoRect, radius: logoCornerRadius)
        }
        
        // 获取结果图像
        guard let resultImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        return resultImage
    }
    
    /**
     * 生成角色专属二维码
     * @param string 要编码的字符串(通常是角色ID或深链接)
     * @param character 角色信息
     * @param theme 角色主题
     * @return 返回具有角色主题风格的二维码
     */
    func generateCharacterQRCode(
        from string: String,
        characterId: String,
        themeManager: ThemeManager = ThemeManager.shared,
        size: CGSize = CGSize(width: 200, height: 200),
        logo: UIImage? = nil
    ) -> UIImage? {
        // 获取角色主题
        let theme = themeManager.getCharacterTheme(for: characterId)
        
        // 将SwiftUI颜色转换为UIColor
        let primaryUIColor = UIColor(theme.primary)
        let backgroundUIColor = UIColor(theme.background)
        
        // 生成自定义二维码
        return generateStyledQRCode(
            from: string,
            size: size,
            foregroundColor: primaryUIColor,
            backgroundColor: backgroundUIColor,
            logo: logo,
            logoSize: 0.22,
            logoCornerRadius: 8
        )
    }
    
    // 辅助方法 - 为图像着色
    private func tintImage(_ image: UIImage, with color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        let rect = CGRect(origin: .zero, size: image.size)
        color.set()
        
        UIRectFill(rect)
        
        image.draw(in: rect, blendMode: .destinationIn, alpha: 1.0)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    
    // 辅助方法 - 绘制圆角图像
    private func drawRoundedImage(_ image: UIImage, in rect: CGRect, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        path.addClip()
        image.draw(in: rect)
    }
} 