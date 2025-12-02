import SwiftUI

/// 对话页面的顶部信息区组件
struct ChatHeader: View {
    let chatTheme: String
    let participants: [CharacterModel]
    var onBackTapped: () -> Void
    var onShareTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 导航栏 - 添加顶部安全区域padding，与其他页面统一
            ZStack {
                // 中间标题 - 与返回按钮绝对位置高度一致（返回按钮中心在 topPadding + 25）
                Text(chatTheme.isEmpty ? "自由对话" : chatTheme)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .offset(y: -10) // 增大offset，使标题中心与返回按钮中心绝对对齐（topPadding + 25）
                
                // 按钮已移至系统级UIWindow，这里只保留占位空间
                HStack(spacing: 0) {
                    // 左侧占位 - 系统级返回按钮会覆盖这里
                    Color.clear
                        .frame(width: 50, height: 44)
                        .padding(.leading, 16)
                    
                    Spacer()
                    
                    // 右侧占位 - 系统级分享按钮会覆盖这里
                    Color.clear
                        .frame(width: 55, height: 44)
                        .padding(.trailing, 16)
                }
            }
            .frame(height: 44)
            .padding(.top) // 添加顶部安全区域padding，与其他页面统一
            
            // 参与者指示器 - 紧贴标题下方
            participantsView
                .offset(y: -8) // 向上移动，紧紧靠着标题下方
        }
        .background(Color.clear)
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.warmAccent.opacity(0.008),
                            Color.warmAccent.opacity(0.003)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.15),
            alignment: .bottom
        )
        .shadow(color: Color.black.opacity(0.01), radius: 1, x: 0, y: 1)
    }
    
    // 参与者视图
    private var participantsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(participants) { character in
                    HStack(spacing: 6) {
                        // 使用CharacterAvatarService支持首字母显示
                        CharacterAvatarService.shared.getAvatarView(
                            for: character.id,
                            name: character.name,
                            category: character.category.rawValue,
                            size: 24,
                            useCaching: true
                        )
                        
                        Text(character.name)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        Capsule()
                            .fill(Color.white)
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 0) // 移除顶部padding，让头像紧贴标题
            .padding(.bottom, 0) // 底部间距为0
        }
    }
}

struct ChatHeader_Previews: PreviewProvider {
    static var previews: some View {
        ChatHeader(
            chatTheme: "探讨人性的本质",
            participants: [
                CharacterModel.sampleCharacters[0],
                CharacterModel.sampleCharacters[1]
            ],
            onBackTapped: {},
            onShareTapped: {}
        )
        .previewLayout(.sizeThatFits)
    }
} 