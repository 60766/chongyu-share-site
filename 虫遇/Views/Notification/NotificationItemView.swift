import SwiftUI

/**
 * 通知项组件
 * 用于显示单个通知项，支持评论、点赞、关注、系统通知等类型
 */
struct NotificationItemView: View {
    // 通知模型
    var notification: NotificationModel
    // 动画状态
    @State private var animateContent = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // 使用角色专属头像效果
                NotificationCharacterView(
                    character: notification.character,
                    isOnline: notification.isOnline
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        // 角色名称使用专属字体
                        Text(notification.character.name)
                            .font(notification.character.fontStyle.bold())
                            .foregroundColor(.primary)
                        
                        // 角色时代标签
                        Text(notification.character.era)
                            .font(.system(size: 12))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(notification.character.category.color.opacity(0.15))
                            .foregroundColor(notification.character.category.color)
                            .cornerRadius(8)
                        
                        Spacer()
                        
                        // 通知时间
                        Text(notification.time)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    // 通知内容 - 使用角色专属语气
                    HStack {
                        Image(systemName: notification.typeIcon)
                            .foregroundColor(notification.typeColor)
                            .font(.system(size: 14))
                        
                        // 添加角色专属语言风格
                        switch notification.type {
                        case .comment:
                            Text("\(notification.character.speechStyle)评论了你的动态")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        case .like:
                            Text("\(notification.character.speechStyle)喜欢了你的作品")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        case .follow:
                            Text("通过时空虫洞关注了你")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        case .system:
                            Text("")
                        }
                        
                        Spacer()
                        
                        // 互动按钮 - 提供更具视觉吸引力的设计
                        if notification.canRespond {
                            Button(action: {
                                // 操作交互
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: notification.type == .comment ? "arrowshape.turn.up.left.fill" : 
                                                    notification.type == .like ? "heart.fill" : "person.badge.plus")
                                        .font(.system(size: 12))
                                    
                                    Text(notification.responseButtonText)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(notification.typeColor.opacity(0.1))
                                .foregroundColor(notification.typeColor)
                                .cornerRadius(16)
                            }
                            .buttonStyle(NotificationScaleButtonStyle())
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // 通知内容 - 使用带有时代特色的背景样式
            if let content = notification.content {
                VStack(alignment: .leading, spacing: 8) {
                    Text(content)
                        .font(notification.character.fontStyle)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(16)
                        .background(
                            ZStack {
                                // 基础背景
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(notification.character.category.color.opacity(0.05))
                                
                                // 时代纹理背景 (仅在Assets中有对应资源时显示)
                                if UIImage(named: notification.character.backgroundPattern) != nil {
                                    Image(notification.character.backgroundPattern)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .opacity(0.1)
                                        .blendMode(.overlay)
                                }
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(notification.character.category.color.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .scaleEffect(animateContent ? 1.0 : 0.95)
                .opacity(animateContent ? 1.0 : 0.8)
                .onAppear {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        animateContent = true
                    }
                }
            }
            
            // 原内容预览
            if let previewContent = notification.previewContent {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 3)
                        .cornerRadius(1.5)
                    
                    Text(previewContent)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 12)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .padding(.top, notification.content == nil ? 8 : 0)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            // 通知类型指示器
            VStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(notification.typeColor)
                    .frame(width: 50, height: 4)
                    .padding(.top, 4)
                Spacer()
            }
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

/**
 * 通知角色头像视图
 * 适配器模式：将NotificationModel.CharacterInfo转换为适合CharacterAvatarView的视图
 */
struct NotificationCharacterView: View {
    var character: NotificationModel.CharacterInfo
    var isOnline: Bool
    
    var body: some View {
        ZStack {
            // 背景圆形
            Circle()
                .fill(character.category.color.opacity(0.15))
                .frame(width: 48, height: 48)
            
            // 角色头像图片或占位符
            if UIImage(named: character.image) != nil {
                Image(character.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                    
                    Text(String(character.name.prefix(1)))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(character.category.color)
                }
            }
            
            // 类别图标
            Circle()
                .fill(character.category.color)
                .frame(width: 16, height: 16)
                .overlay(
                    Image(systemName: character.category.icon)
                        .font(.system(size: 8))
                        .foregroundColor(.white)
                )
                .offset(x: 16, y: 16)
            
            // 在线状态指示器
            if isOnline {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .offset(x: -16, y: -16)
            }
        }
        .frame(width: 48, height: 48)
    }
}

/**
 * 系统通知视图
 * 专门用于显示系统通知
 */
struct SystemNotificationView: View {
    var notification: NotificationModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // 系统通知图标
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "clock.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.purple.opacity(0.8))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("虫洞通知")
                            .font(.system(size: 16, weight: .medium))
                        
                        Spacer()
                        
                        Text("系统")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    Text(notification.time)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Text("有新的时空旅者加入平台")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            // 新角色信息
            HStack(spacing: 12) {
                NotificationCharacterView(character: notification.character, isOnline: false)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(notification.character.name)
                        .font(.system(size: 14, weight: .semibold))
                    
                    HStack(spacing: 8) {
                        Text(notification.character.era)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text(notification.character.category.displayName)
                            .font(.system(size: 12))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(notification.character.category.color.opacity(0.1))
                            .foregroundColor(notification.character.category.color)
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    // 查看角色
                }) {
                    Text("探索")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .buttonStyle(NotificationScaleButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

/**
 * 通知项目的缩放按钮样式
 */
struct NotificationScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(), value: configuration.isPressed)
    }
}

// 预览
#Preview {
    VStack {
        NotificationItemView(
            notification: NotificationModel.sampleNotifications[0]
        )
        
        NotificationItemView(
            notification: NotificationModel.sampleNotifications[1]
        )
        
        NotificationItemView(
            notification: NotificationModel.sampleNotifications[2]
        )
        
        SystemNotificationView(
            notification: NotificationModel.sampleNotifications[3]
        )
    }
    .background(Color(red: 246/255, green: 248/255, blue: 250/255))
    .padding(.vertical)
} 