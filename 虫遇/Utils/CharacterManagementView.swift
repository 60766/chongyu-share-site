import SwiftUI

/**
 * 角色管理视图
 * 在管理模式下显示角色卡片，包括删除/隐藏和置顶按钮
 */
struct CharacterManagementView: View {
    let character: CharacterModel
    let isUserCreated: Bool
    let onDeleteOrHide: () -> Void
    
    var body: some View {
        ZStack {
            // 底层使用原有的角色卡片视图
            ImprovedCharacterCardView(character: character)
                .allowsHitTesting(false) // 禁用点击事件
            
            // 覆盖按钮
            VStack {
                HStack {
                    // 左上角的置顶按钮
                    PinButton(characterId: character.id, characterName: character.name)
                        .padding(EdgeInsets(top: 8, leading: 4, bottom: 0, trailing: 0))

                    Spacer()
                    
                    // 右上角的删除/隐藏按钮
                    Button(action: onDeleteOrHide) {
                        ZStack {
                            Circle()
                                .fill(isUserCreated ? Color.red : Color.orange)
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: isUserCreated ? "xmark" : "eye.slash")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 4))
                }
                
                Spacer()
            }
        }
    }
}

// 预览提供器
struct CharacterManagementView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // 用户创建的角色
            CharacterManagementView(
                character: CharacterModel(
                    id: "custom_1",
                    name: "自定义角色",
                    avatar: "default_avatar",
                    era: "现代",
                    profession: "程序员",
                    bio: "这是一个自定义角色",
                    category: .fictionCharacter
                ),
                isUserCreated: true,
                onDeleteOrHide: {}
            )
            .frame(width: 160, height: 200)
            .padding()
            
            // 预设角色
            CharacterManagementView(
                character: CharacterModel(
                    id: "preset_1",
                    name: "预设角色",
                    avatar: "davinci",
                    era: "文艺复兴",
                    profession: "艺术家",
                    bio: "这是一个预设角色",
                    category: .artist
                ),
                isUserCreated: false,
                onDeleteOrHide: {}
            )
            .frame(width: 160, height: 200)
            .padding()
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color(.systemBackground))
    }
} 