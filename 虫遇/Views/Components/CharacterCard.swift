import SwiftUI

/**
 * 角色卡片组件
 * 用于显示角色简要信息
 */
struct CharacterCard: View {
    /// 角色数据
    var character: Character
    /// 卡片类型（大卡、小卡）
    var type: CharacterCardType = .small
    /// 点击事件
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // 角色头像
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: character.avatarUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.2))
                    }
                    .frame(width: type == .large ? 160 : 110, height: type == .large ? 160 : 110)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // 时代标签
                    if let eraTag = character.eraTag {
                        Text(eraTag)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primaryColor)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .padding(8)
                    }
                }
                
                // 角色信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(character.name)
                        .font(.system(size: type == .large ? 16 : 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("\(character.field) · \(character.birthYear)-\(character.deathYear ?? "现在")")
                        .font(.system(size: type == .large ? 14 : 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.top, 8)
                .padding(.horizontal, 4)
            }
            .frame(width: type == .large ? 160 : 110)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/**
 * 角色卡片类型
 */
enum CharacterCardType {
    /// 小卡片（用于网格展示）
    case small
    /// 大卡片（用于推荐展示）
    case large
}

/**
 * 角色卡片预览
 */
struct CharacterCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 小卡片预览
            CharacterCard(
                character: Character(
                    name: "阿尔伯特·爱因斯坦",
                    introduction: "现代物理学最重要的科学家之一，相对论的创立者",
                    field: "物理学家",
                    birthYear: "1879",
                    deathYear: "1955",
                    avatarUrl: "https://example.com/einstein.jpg",
                    eraTag: "1900s",
                    achievements: ["相对论", "光电效应", "质能方程"],
                    mainWorks: ["相对论：广义和狭义"],
                    keyThoughts: ["时间和空间是相对的", "质量可以转化为能量"]
                ),
                type: .small,
                onTap: {}
            )
            .padding()
            .previewLayout(.sizeThatFits)
            
            // 大卡片预览
            CharacterCard(
                character: Character(
                    name: "苏格拉底",
                    introduction: "古希腊哲学家，西方哲学的奠基人之一",
                    field: "哲学家",
                    birthYear: "公元前469年",
                    deathYear: "公元前399年",
                    avatarUrl: "https://example.com/socrates.jpg",
                    eraTag: "古希腊",
                    achievements: ["苏格拉底方法", "道德哲学"],
                    mainWorks: ["柏拉图对话录中记载"],
                    keyThoughts: ["未经审视的生活不值得过", "认识你自己"]
                ),
                type: .large,
                onTap: {}
            )
            .padding()
            .previewLayout(.sizeThatFits)
        }
    }
} 