import SwiftUI

/**
 * 头像视图组件
 * 用于显示用户头像，支持图像和占位符
 */
struct AvatarView: View {
    // 头像图像名称或URL
    var imageName: String
    // 头像尺寸
    var size: CGFloat = 48
    // 是否显示在线状态
    var isOnline: Bool = false
    // 在线标记的颜色
    var onlineColor: Color = .primaryColor
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 头像图像或占位符
            Group {
                if UIImage(named: imageName) != nil {
                    // 如果有图像，显示图像
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                } else {
                    // 否则显示占位符
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                        
                        Text(String(imageName.prefix(1).uppercased()))
                            .font(.system(size: size * 0.4, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            
            // 在线状态标记
            if isOnline {
                Circle()
                    .fill(onlineColor)
                    .frame(width: size * 0.25, height: size * 0.25)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
        }
    }
}

#Preview("头像预览") {
    VStack(spacing: 20) {
        AvatarView(imageName: "avatar1", isOnline: true)
        AvatarView(imageName: "noExistingImage", size: 60)
        AvatarView(imageName: "A", size: 40, isOnline: true, onlineColor: .green)
    }
    .padding()
} 