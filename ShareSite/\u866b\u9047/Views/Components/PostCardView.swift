private var userInfoSection: some View {
    HStack(alignment: .center, spacing: 12) {
        // 用户头像 - 使用 Avatar 组件，支持系统符号
        Avatar(url: post.userAvatar, size: 46.0)
            .overlay(
                Circle()
                    .stroke(DesignSystem.Colors.divider, lineWidth: 0.5)
            )
        
        // 用户信息 - 更紧凑的布局
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                // 用户名 - 增加字体粗细区分
                Text(post.username)
                    .font(.system(size: 16.0, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                // 用户标签 - 统一标签样式
                if post.username.contains("探索") {
                    userTagView("历史爱好者")
                }
                
                Spacer()
            
                // 菜单按钮移至用户信息行内，更加整洁
                Button(action: {
                    feedbackGenerator.impactOccurred(intensity: 0.4)
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16.0))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .padding(6.0)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 发布时间与内容类型简化为一行，字体更小但确保可读性
            HStack(spacing: 6) {
                Text(post.getFormattedTimeAgo())
                    .font(.system(size: 13.0, weight: .regular))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                
                if !isDetailView {
                    // 内容类型指示器
                    Text("•")
                        .font(.system(size: 13.0))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    
                    // 注意：这个文件看起来是代码片段，如果需要区分AI生成和用户生成，请参考主PostCardView文件
                    Text(post.images.isEmpty ? "文字" : "图文")
                        .font(.system(size: 13.0, weight: .regular))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
        }
    }
    .padding(.bottom, 10.0)
} 