import SwiftUI

/**
 * 角色关系卡片组件
 * 用于显示用户与历史人物的关系
 */
struct CharacterRelationCardView: View {
    // 角色名称
    let characterName: String
    // 角色头像
    let characterAvatar: String
    // 关系类型名称
    let relationTypeName: String
    // 关系颜色
    let relationColor: Color
    // 点击操作
    var onTap: () -> Void = {}
    
    // 通过关系模型初始化
    init(relation: CharacterRelationModel, onTap: @escaping () -> Void = {}) {
        self.characterName = relation.character.name
        self.characterAvatar = relation.character.avatar
        self.relationTypeName = relation.relationType.rawValue
        self.relationColor = relation.relationColor
        self.onTap = onTap
    }
    
    // 直接通过参数初始化
    init(characterName: String, characterAvatar: String, relationTypeName: String, relationColor: Color, onTap: @escaping () -> Void = {}) {
        self.characterName = characterName
        self.characterAvatar = characterAvatar
        self.relationTypeName = relationTypeName
        self.relationColor = relationColor
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // 角色头像
                if UIImage(named: characterAvatar) != nil {
                    Image(characterAvatar)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .padding(.top, 12)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Text(String(characterName.prefix(1)))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                        )
                        .padding(.top, 12)
                }
                
                // 角色名称
                Text(characterName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .padding(.top, 8)
                    .padding(.bottom, 2)
                
                // 分隔线
                Divider()
                    .frame(width: 24)
                    .padding(.vertical, 4)
                    .overlay(
                        relationColor
                    )
                
                // 关系类型
                Text(relationTypeName)
                    .font(.system(size: 12))
                    .foregroundColor(relationColor)
                    .padding(.bottom, 8)
            }
            .frame(width: 100)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview("角色关系卡片") {
    HStack(spacing: 16) {
        ForEach(CharacterRelationModel.sampleRelations) { relation in
            CharacterRelationCardView(relation: relation)
        }
        
        CharacterRelationCardView(
            characterName: "达芬奇",
            characterAvatar: "avatar_davinci",
            relationTypeName: "崇拜",
            relationColor: .orange
        )
    }
    .padding()
    .background(Color(red: 246/255, green: 248/255, blue: 250/255))
} 