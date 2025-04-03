import SwiftUI

/**
 * 次要按钮组件，用于应用中次要操作
 */
struct SecondaryButton: View {
    /// 按钮文本
    var text: String
    /// 按钮图标（可选）
    var icon: String?
    /// 按钮宽度（可选，默认自适应）
    var width: CGFloat?
    /// 按钮高度（默认48）
    var height: CGFloat = 48
    /// 点击动作
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(text)
                    .font(.system(size: 16, weight: .medium))
            }
            .frame(width: width, height: height)
            .foregroundColor(Color.primaryColor)
            .background(Color.white)
            .cornerRadius(height / 2)
            .overlay(
                RoundedRectangle(cornerRadius: height / 2)
                    .stroke(Color.primaryColor, lineWidth: 1.5)
            )
        }
    }
} 