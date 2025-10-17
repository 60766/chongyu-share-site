import SwiftUI

/// 对话页面的顶部信息区组件
struct ChatHeader: View {
    let chatTheme: String
    let participants: [CharacterModel]
    var onBackTapped: () -> Void
    var onShareTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 导航栏
            ZStack {
                // 中间标题 - 绝对居中
                Text(chatTheme.isEmpty ? "自由对话" : chatTheme)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                
                HStack {
                    // 左侧返回按钮
                    Button(action: onBackTapped) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color.warmAccent)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    
                    Spacer()
                    
                    // 右侧分享按钮
                    Button(action: onShareTapped) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundColor(Color.warmAccent)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
            }
            .frame(height: 44)
            
            // 参与者指示器 - 更紧凑的布局
            participantsView
        }
        .background(DesignSystem.Colors.background.opacity(0.98))
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.warmAccent.opacity(0.01),
                            Color.warmAccent.opacity(0.005)
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
            .padding(.vertical, 6)
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