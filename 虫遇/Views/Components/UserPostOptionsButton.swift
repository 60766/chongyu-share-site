import SwiftUI

/**
 * 用户自己发布帖子的选项按钮组件
 * 提供编辑、删除和置顶功能
 */
struct UserPostOptionsButton: View {
    var post: UserPostModel? // 当前帖子
    var onEdit: () -> Void // 编辑回调
    var onDelete: () -> Void // 删除回调
    var onPin: (Bool) -> Void // 置顶/取消置顶回调
    
    @State private var isPressed: Bool = false
    @State private var showMenu: Bool = false
    @State private var isPinned: Bool = false // 是否已置顶
    
    // 触感反馈生成器
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2)) {
                isPressed = true
                feedbackGenerator.impactOccurred(intensity: 0.2)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.15)) {
                    isPressed = false
                }
                showMenu = true
            }
        }) {
            ZStack {
                if isPressed {
                    Circle()
                        .fill(Color(.systemGray5).opacity(0.6))
                        .frame(width: 36, height: 36)
                }
                
                Image(systemName: "ellipsis")
                    .font(.system(size: 16.0, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .frame(width: 36, height: 36)
            .contentShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $showMenu, arrowEdge: .top) {
            VStack(spacing: 0) {
                // 编辑按钮
                Button(action: {
                    showMenu = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // 调用编辑回调
                        onEdit()
                        HapticFeedbackManager.shared.menuSelection()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(Color.primaryColor)
                            .frame(width: 20, alignment: .center)
                        
                        Text("编辑")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .padding(.horizontal, 8)
                
                // 置顶/取消置顶按钮
                Button(action: {
                    showMenu = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // 切换置顶状态
                        isPinned.toggle()
                        HapticFeedbackManager.shared.menuSelection()
                        
                        // 调用置顶/取消置顶回调
                        onPin(isPinned)
                        
                        // 显示操作反馈
                        ToastManager.shared.showToast(
                            message: isPinned ? "已将帖子置顶" : "已取消置顶"
                        )
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: isPinned ? "pin.slash" : "pin")
                            .font(.system(size: 14))
                            .foregroundColor(isPinned ? Color.orange.opacity(0.8) : Color.primaryColor)
                            .frame(width: 20, alignment: .center)
                        
                        Text(isPinned ? "取消置顶" : "置顶")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .padding(.horizontal, 8)
                
                // 删除按钮
                Button(action: {
                    showMenu = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // 调用删除回调
                        onDelete()
                        HapticFeedbackManager.shared.menuSelection()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(Color.red.opacity(0.8))
                            .frame(width: 20, alignment: .center)
                        
                        Text("删除")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Color.red.opacity(0.8))
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(width: 180)
            .background(
                ZStack {
                    // 磨砂玻璃背景
                    if #available(iOS 15.0, *) {
                        UltraVisualEffectView(blurStyle: .systemMaterial)
                    } else {
                        Color(.systemBackground)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            .if16Available {
                $0.presentationCompactAdaptation(.none)
                   .presentationBackgroundInteraction(.enabled)
                   .presentationCornerRadius(12)
                   .shadowVisibility(.hidden)
            }
            .onAppear {
                // 检查是否已置顶
                checkIfPinned()
            }
        }
    }
    
    // 检查帖子是否已置顶
    private func checkIfPinned() {
        guard let post = post else { return }
        
        // 从UserDefaults获取已置顶帖子的ID列表
        let pinnedPosts = UserDefaults.standard.stringArray(forKey: "PinnedPosts") ?? []
        
        // 更新置顶状态
        isPinned = pinnedPosts.contains(post.id.uuidString)
    }
}

#Preview("用户帖子选项") {
    UserPostOptionsButton(
        post: ModelData.samplePosts[0],
        onEdit: {},
        onDelete: {},
        onPin: { _ in }
    )
    .padding()
    .background(Color.white)
} 