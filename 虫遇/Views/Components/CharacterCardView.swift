import SwiftUI

/**
 * 历史人物角色卡片组件
 * 用于在探索页面显示历史人物信息
 */
struct ExploreCharacterCardView: View {
    let character: CharacterModel
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // 角色头像
                ZStack(alignment: .topLeading) {
                    if UIImage(named: character.avatar) != nil {
                        // 如果有图像，显示图像
                        Image(character.avatar)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipped()
                    } else {
                        // 否则显示占位符
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 180)
                    }
                    
                    // 角色分类标签
                    Text(character.category.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(character.category.color)
                        .cornerRadius(12)
                        .padding(8)
                }
                
                // 角色信息
                VStack(alignment: .leading, spacing: 6) {
                    // 角色名称
                    Text(character.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // 角色职业和年代
                    HStack {
                        Text(character.profession)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(character.era)
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                    
                    // 角色简介
                    Text(character.bio)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                    
                    // 标签
                    HStack(spacing: 6) {
                        // 由于CharacterModel中没有tags属性，用空数组替代
                        ForEach([character.category.rawValue], id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 12))
                                .foregroundColor(character.category == .scientist ? .green : .primaryColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    (character.category == .scientist ? Color.green : Color.primaryColor)
                                        .opacity(0.1)
                                )
                                .cornerRadius(12)
                        }
                    }
                    .padding(.top, 6)
                }
                .padding(12)
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 20) {
        ForEach(CharacterModel.sampleCharacters.prefix(2)) { character in
            ExploreCharacterCardView(character: character)
        }
    }
    .padding()
    .background(Color(red: 246/255, green: 248/255, blue: 250/255))
} 