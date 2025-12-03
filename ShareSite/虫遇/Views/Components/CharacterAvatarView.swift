import SwiftUI

struct CharacterAvatarView: View {
    var character: CharacterModel
    var size: CGFloat = 40
    var showBorder: Bool = true
    var showBackground: Bool = false
    var showName: Bool = false
    var namePosition: NamePosition = .bottom
    var nameFont: Font = .caption
    var namePadding: CGFloat = 4
    
    enum NamePosition {
        case top, bottom, trailing
    }
    
    // 根据角色类别获取颜色
    private var characterColor: Color {
        return character.category.color
    }
    
    var body: some View {
        VStack(spacing: namePadding) {
            if namePosition == .top && showName {
                characterNameView
            }
            
            ZStack {
                // 背景
                if showBackground {
                    Circle()
                        .fill(characterColor.opacity(0.1))
                }
                
                // 头像
                CharacterAvatarSimple(character.characterID ?? character.name, size: size)
                    .overlay(
                        showBorder ? Circle()
                            .stroke(
                                characterColor.opacity(0.5),
                                lineWidth: 1.5
                            ) : nil
                    )
            }
            
            if namePosition == .bottom && showName {
                characterNameView
            }
        }
        .frame(maxWidth: showName && namePosition != .trailing ? .infinity : nil)
        .padding(.horizontal, showName && namePosition != .trailing ? 4 : 0)
    }
    
    // 角色名称视图
    private var characterNameView: some View {
        Text(character.name)
            .font(nameFont)
            .foregroundColor(.primary)
            .lineLimit(1)
            .truncationMode(.tail)
    }
}
