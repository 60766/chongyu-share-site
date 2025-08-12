import SwiftUI

/// 对话开场卡片组件
struct ChatIntroCard: View {
    let theme: String
    let participants: [CharacterModel]
    let chatMode: ChatMode
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            VStack(spacing: 6) {
                Text(theme.isEmpty ? "自由对话" : theme)
                    .font(.system(size: 19, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Text(chatMode.rawValue)
                    .font(.system(size: 14))
                    .foregroundColor(Color.secondary)
            }
            
            // 参与者
            VStack(spacing: 14) {
                Text("参与者")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "8C69BF"))
                
                HStack(spacing: 22) {
                    ForEach(participants) { character in
                        VStack(spacing: 8) {
                            Image(character.avatar)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            
                            Text(character.name)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "F7F2FF"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "E5DDFF"), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct ChatIntroCard_Previews: PreviewProvider {
    static var previews: some View {
        ChatIntroCard(
            theme: "探讨人性的本质",
            participants: [
                CharacterModel.sampleCharacters[0],
                CharacterModel.sampleCharacters[1],
                CharacterModel.sampleCharacters[2]
            ],
            chatMode: .themedDiscussion
        )
        .previewLayout(.sizeThatFits)
    }
} 