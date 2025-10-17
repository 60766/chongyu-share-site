import SwiftUI

/**
 * 分享模式底部操作栏
 * 显示选择数量和操作按钮
 */
struct ShareModeBottomBar: View {
    let selectedCount: Int
    let onCancel: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部分割线
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)
            
            HStack(spacing: 16) {
                // 取消按钮
                Button(action: onCancel) {
                    Text("取消")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.gray.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // 选择提示文字
                VStack(spacing: 2) {
                    if selectedCount == 0 {
                        Text("选择要分享的内容")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    } else {
                        Text("已选择 \(selectedCount) 条消息")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                // 生成卡片按钮
                Button(action: onShare) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                        
                        Text(selectedCount > 1 ? "生成卡片 (\(selectedCount))" : "生成卡片")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                selectedCount > 0 
                                ? LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "B8B5FF"),
                                        Color(hex: "9A8BB0")
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.3),
                                        Color.gray.opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(selectedCount == 0)
                .scaleEffect(selectedCount > 0 ? 1.0 : 0.95)
                .animation(.spring(response: 0.3), value: selectedCount)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(
            // 磨砂玻璃背景
            VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        )
    }
}

// VisualEffectView已在CustomTabBarView中定义，这里不需要重复定义

#Preview {
    VStack(spacing: 20) {
        Spacer()
        
        // 未选择状态
        ShareModeBottomBar(
            selectedCount: 0,
            onCancel: {},
            onShare: {}
        )
        
        // 选择了1条消息
        ShareModeBottomBar(
            selectedCount: 1,
            onCancel: {},
            onShare: {}
        )
        
        // 选择了多条消息
        ShareModeBottomBar(
            selectedCount: 3,
            onCancel: {},
            onShare: {}
        )
    }
    .background(Color.gray.opacity(0.1))
}
