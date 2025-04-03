import SwiftUI

/**
 * 等级特权行组件
 * 用于在等级详情视图中显示特权信息，包括图标、标题和所需等级
 */
struct LevelPrivilegeRow: View {
    let icon: String           // 特权图标名称
    let title: String          // 特权标题
    let level: String          // 所需等级
    let isUnlocked: Bool       // 是否已解锁
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标容器
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.primaryColor : Color.gray.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isUnlocked ? .white : .gray)
            }
            
            // 特权标题
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(isUnlocked ? .primary : .secondary)
            
            Spacer()
            
            // 等级要求
            Text(level)
                .font(.system(size: 14, weight: isUnlocked ? .semibold : .regular))
                .foregroundColor(isUnlocked ? .primaryColor : .gray)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isUnlocked ? Color.primaryColor.opacity(0.1) : Color.gray.opacity(0.1))
                )
        }
        .padding(.vertical, 12)
    }
} 