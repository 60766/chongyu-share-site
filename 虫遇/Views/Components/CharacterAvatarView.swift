import SwiftUI

/**
 * 历史人物圆形头像组件
 * 用于在顶部横向滚动栏中显示历史人物头像
 * 优化设计：减小尺寸，轻量化标签设计
 */
struct CharacterAvatarView: View {
    // 角色数据
    let character: CharacterModel
    // 头像尺寸 - 默认值从60减小为50
    var size: CGFloat = 50
    // 是否显示名称
    var showName: Bool = true
    // 点击事件
    var onTap: () -> Void = {}
    
    // 角色颜色 - 预计算提高性能
    private var characterColor: Color {
        character.category.color
    }
    
    // 触觉反馈生成器
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        Button(action: {
            // 触发反馈并执行点击事件
            feedbackGenerator.impactOccurred(intensity: 0.5)
            onTap()
        }) {
            VStack(spacing: DesignSystem.Spacing.xxs) { // 减小间距
                // 头像和时代标签
                ZStack(alignment: .bottomTrailing) {
                    // 背景渐变 - 简化渐变减少绘制负担
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    characterColor.opacity(0.15),
                                    characterColor.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size + 4, height: size + 4) // 减小外圈尺寸
                    
                    // 头像
                    if UIImage(named: character.avatar) != nil {
                        Image(character.avatar)
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        characterColor.opacity(0.5), // 降低边框透明度
                                        lineWidth: 1.5 // 减小边框宽度
                                    )
                            )
                    } else {
                        // 占位图标 - 简化结构以提高性能
                        ZStack {
                            Circle()
                                .fill(characterColor.opacity(0.1))
                                .frame(width: size, height: size)
                            
                            // 历史人物图标
                            Image(systemName: character.category.icon)
                                .font(.system(size: size * 0.4))
                                .foregroundColor(characterColor)
                        }
                        .overlay(
                            Circle()
                                .stroke(
                                    characterColor.opacity(0.5), // 降低边框透明度
                                    lineWidth: 1.5 // 减小边框宽度
                                )
                        )
                    }
                    
                    // 类别标识 - 减小尺寸
                    Circle()
                        .fill(characterColor)
                        .frame(width: size * 0.22, height: size * 0.22) // 减小类别图标尺寸
                        .overlay(
                            Image(systemName: character.category.icon)
                                .font(.system(size: size * 0.11))
                                .foregroundColor(.white)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                    
                    // 时代标签 - 优化为更简洁的标签
                    Text(getEraTag(era: character.era))
                        .font(.system(size: 9)) // 减小字体
                        .fontWeight(.medium) // 减少字重
                        .foregroundColor(.white)
                        .padding(.horizontal, size * 0.12)
                        .padding(.vertical, size * 0.04)
                        .background(
                            Capsule()
                                .fill(characterColor.opacity(0.85)) // 降低不透明度
                        )
                        .offset(y: size * 0.35)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(character.name)，\(character.category.displayName)，\(getEraTag(era: character.era))时代")
                
                // 角色名称和标签
                if showName {
                    VStack(spacing: 2) { // 减小名称和标签之间的间距
                        Text(character.name)
                            .font(.system(size: 13)) // 减小字体
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .lineLimit(1)
                        
                        // 轻量级标签设计
                        Text(character.category.displayName)
                            .font(.system(size: 10)) // 更小的字体
                            .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.7)) // 降低对比度
                            .lineLimit(1)
                    }
                }
            }
            .frame(width: size + 16) // 限制整体宽度
            .contentShape(Rectangle()) // 确保整个区域可点击
        }
        .buttonStyle(ScaleButtonStyle())
        .onAppear {
            // 准备触觉反馈
            feedbackGenerator.prepare()
        }
    }
    
    // 根据年代范围获取时代标签
    private func getEraTag(era: String) -> String {
        // 解析年代范围
        let components = era.components(separatedBy: "-")
        if components.count > 0 {
            let firstYear = components[0]
            
            // 处理公元前年份
            if firstYear.contains("前") {
                return "古代"
            }
            
            // 处理数字年份
            if let year = Int(firstYear.trimmingCharacters(in: .letters)) {
                // 根据世纪分类
                if year < 0 {
                    return "古代"
                } else if year < 1000 {
                    return "中古"
                } else if year < 1800 {
                    return "文艺"
                } else if year < 1900 {
                    return "近代"
                } else {
                    return "现代"
                }
            }
        }
        
        // 默认返回
        return "未知"
    }
}

#Preview("历史人物头像") {
    HStack(spacing: 20) {
        CharacterAvatarView(character: CharacterModel.sampleCharacters[0])
        CharacterAvatarView(character: CharacterModel.sampleCharacters[1])
    }
    .padding()
    .background(DesignSystem.Colors.background)
}