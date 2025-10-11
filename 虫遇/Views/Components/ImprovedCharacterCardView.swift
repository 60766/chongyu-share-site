import SwiftUI

/**
 * 改进的历史人物卡片视图
 * 优化设计以符合iOS设计标准，简化信息展示
 */
struct ImprovedCharacterCardView: View {
    // 角色数据
    var character: CharacterModel
    // 点击卡片图片区域事件 - 进入角色详情
    var onTap: () -> Void = {}
    // 点击聊天按钮事件 - 进入聊天页面
    var onChatTap: () -> Void = {}
    // 自定义头像
    @State private var customImage: UIImage? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 角色头像区域 - 优化尺寸和圆角，可点击进入角色详情页
            Button(action: onTap) {
                ZStack(alignment: .bottomTrailing) {
                    // 背景渐变作为基础
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    character.category.color.opacity(0.5),
                                    character.category.color.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(1.0, contentMode: .fit) // 保持正方形比例
                    
                    // 先尝试加载自定义头像
                    if let customImage = customImage {
                        Image(uiImage: customImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .aspectRatio(1.0, contentMode: .fill) // 保持正方形比例
                            .clipped()
                            .overlay(
                                ZStack {
                                    // 全图渐变
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.black.opacity(0.0),
                                            Color.black.opacity(0.1),
                                            Color.black.opacity(0.3)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    
                                    // 右下角额外渐变
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Rectangle()
                                                .fill(
                                                    RadialGradient(
                                                        gradient: Gradient(colors: [
                                                            Color.black.opacity(0.4),
                                                            Color.clear
                                                        ]),
                                                        center: .bottomTrailing,
                                                        startRadius: 5,
                                                        endRadius: 60
                                                    )
                                                )
                                                .frame(width: 80, height: 50)
                                        }
                                    }
                                }
                            )
                    }
                    // 然后尝试加载系统头像
                    else if let image = UIImage(named: character.avatar) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .aspectRatio(1.0, contentMode: .fill) // 保持正方形比例
                            .clipped()
                            .overlay(
                                ZStack {
                                    // 全图渐变
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.black.opacity(0.0),
                                            Color.black.opacity(0.1),
                                            Color.black.opacity(0.3)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    
                                    // 右下角额外渐变
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Rectangle()
                                                .fill(
                                                    RadialGradient(
                                                        gradient: Gradient(colors: [
                                                            Color.black.opacity(0.4),
                                                            Color.clear
                                                        ]),
                                                        center: .bottomTrailing,
                                                        startRadius: 5,
                                                        endRadius: 60
                                                    )
                                                )
                                                .frame(width: 80, height: 50)
                                        }
                                    }
                                }
                            )
                    } else {
                        // 找不到图片时显示占位符和文字
                        Text(String(character.name.prefix(1)))
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .clipShape(
                RoundedCornerShape(
                    radius: 10,
                    corners: [.topLeft, .topRight]
                )
            )
            
            // 聊天按钮与名称整合区域 - 更加简约美观，可点击进入聊天页面
            Button(action: onChatTap) {
                ZStack(alignment: .leading) {
                    // 背景 - 添加基于角色类型的微妙色彩
                    Rectangle()
                        .fill(Color(UIColor.systemBackground))
                    Rectangle()
                        .fill(character.category.color.opacity(0.08)) // 降低透明度，使颜色更淡

                    // 内容 - 优化布局，名字左对齐但从头部截断
                    HStack(spacing: 8) {
                        // 聊天图标 - 放在左侧
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 10))
                            .foregroundColor(character.category.color.opacity(0.8))
                            .padding(.leading, 10)
                        
                        // 角色名称 - 给予更多空间，从头部截断但保持左对齐
                        Text(character.name)
                            .font(.system(size: 13.5, weight: .regular))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.head) // 从头部开始截断，优先显示名字后面部分
                            .frame(maxWidth: .infinity, alignment: .leading) // 左对齐，但依然显示后部
                            .padding(.trailing, 10) // 添加右侧内边距
                    }
                    .padding(.vertical, 6)
                }
                .frame(height: 42) // 保持42px高度
            }
            .buttonStyle(PlainButtonStyle())
            .clipShape(
                RoundedCornerShape(
                    radius: 10,
                    corners: [.bottomLeft, .bottomRight]
                )
            )
        }
        .background(DesignSystem.Colors.background)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1.5)
        .padding(.vertical, 5)
        .onAppear {
            // 尝试加载自定义头像
            loadCustomAvatar()
        }
    }
    
    // 加载自定义头像
    private func loadCustomAvatar() {
        if let image = CustomAvatarLoader.shared.loadCustomAvatar(characterId: character.id, avatarName: character.avatar) {
            self.customImage = image
        }
    }
}

// 扩展视图修饰器，使调用更加流畅
extension ImprovedCharacterCardView {
    func onTap(_ action: @escaping () -> Void) -> ImprovedCharacterCardView {
        ImprovedCharacterCardView(
            character: self.character,
            onTap: action,
            onChatTap: self.onChatTap
        )
    }
    
    func onChatTap(_ action: @escaping () -> Void) -> ImprovedCharacterCardView {
        ImprovedCharacterCardView(
            character: self.character,
            onTap: self.onTap,
            onChatTap: action
        )
    }
}

// 自定义形状以实现特定角落的圆角效果
struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// 预览
struct ImprovedCharacterCardView_Previews: PreviewProvider {
    static var previews: some View {
        ImprovedCharacterCardView(
            character: CharacterModel.sampleCharacters[0],
            onTap: {},
            onChatTap: {}
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.gray.opacity(0.1))
    }
} 