import SwiftUI

/**
 * 主要按钮组件
 * 用于应用中的主要操作
 */
struct PrimaryButton: View {
    /// 按钮文本
    var text: String
    /// 图标名称（SF Symbols）
    var iconName: String? = nil
    /// 点击操作
    var action: () -> Void
    /// 是否全宽显示
    var isFullWidth: Bool = false
    /// 是否禁用
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(text)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(isDisabled ? Color.gray.opacity(0.3) : Color.primaryColor)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .disabled(isDisabled)
    }
}

/**
 * 主要按钮预览
 */
struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PrimaryButton(text: "开始对话", action: {})
            
            PrimaryButton(text: "发布", iconName: "paperplane", action: {})
            
            PrimaryButton(text: "确认", action: {}, isFullWidth: true)
            
            PrimaryButton(text: "禁用按钮", action: {}, isDisabled: true)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 