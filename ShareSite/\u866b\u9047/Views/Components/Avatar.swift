import SwiftUI

/**
 * 头像组件
 * 统一处理用户和历史人物头像的显示
 */
struct Avatar: View {
    // 头像URL或名称
    var url: String?
    // 头像尺寸
    var size: CGFloat = 40
    // 背景颜色
    var backgroundColor: Color = DesignSystem.Colors.secondaryBackground
    // 文字颜色
    var textColor: Color = DesignSystem.Colors.secondary
    // 占位符文本
    var placeholder: String = "U"
    
    // 判断是否为系统符号（SF Symbol）
    private var isSystemSymbol: Bool {
        guard let url = url else { return false }
        return url.hasSuffix(".fill") || url.hasSuffix(".circle") || url.contains(".and.") || url.contains(".fill.") || url.contains("person") || url.contains("brain")
    }
    
    var body: some View {
        Group {
            if let url = url, !url.isEmpty {
                if isSystemSymbol {
                    // 如果是系统符号，使用 systemName
                    Image(systemName: url)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(size * 0.2)
                        .frame(width: size, height: size)
                        .foregroundColor(textColor)
                        .background(backgroundColor)
                        .clipShape(Circle())
                } else if UIImage(named: url) != nil {
                    // 如果有URL并且图像存在，显示图像
                    Image(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else {
                    // 占位符
                    fallbackPlaceholder
                }
            } else {
                // 否则显示占位符
                fallbackPlaceholder
            }
        }
    }
    
    // 提取占位符视图
    private var fallbackPlaceholder: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
            
            Text(placeholder)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(textColor)
        }
        .frame(width: size, height: size)
    }
}

#Preview("头像预览") {
    VStack(spacing: 20) {
        Avatar(url: "avatar1", size: 40)
        Avatar(url: "person.fill", size: 60) // 测试系统符号
        Avatar(url: nil, size: 60, backgroundColor: Color.blue.opacity(0.1), textColor: .blue, placeholder: "L")
        Avatar(url: "noExistingImage", size: 50, placeholder: "A")
    }
    .padding()
} 