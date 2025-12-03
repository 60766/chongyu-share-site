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
            // Apple 标准分割线
            Divider()
            
            HStack(spacing: 0) {
                // 取消按钮 - 品牌紫色
                Button(action: onCancel) {
                    Text("取消")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "9A8BB0"))
                }
                .frame(width: 70, alignment: .leading)
                
                Spacer()
                
                // 中间状态文字 - SF Pro 排版
                Group {
                    if selectedCount == 0 {
                        Text("选择项目")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                    } else {
                        Text("已选择 \(selectedCount) 项")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: selectedCount)
                
                Spacer()
                
                // 生成按钮 - 品牌紫色加大版
                Button(action: onShare) {
                    Text("生成")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(selectedCount > 0 ? .white : .secondary)
                        .frame(minWidth: 80)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(selectedCount > 0 ? Color(hex: "9A8BB0") : Color.gray.opacity(0.2))
                        )
                }
                .disabled(selectedCount == 0)
                .animation(.easeInOut(duration: 0.2), value: selectedCount)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(
            // iOS 标准毛玻璃材质
            VisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
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
