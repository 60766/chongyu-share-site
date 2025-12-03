import SwiftUI

struct ImageHelper {
    // 加载角色头像
    static func loadCharacterAvatar(_ id: String, size: CGFloat = 40) -> some View {
        // 尝试多种路径加载图片
        if let image = UIImage(named: id) {
            return AnyView(
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            )
        } else if let image = UIImage(named: "HistoricalFigures/\(id)") {
            return AnyView(
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            )
        } else {
            // 使用占位图
            return AnyView(
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(
                        Text(String(id.prefix(1)).uppercased())
                            .font(.system(size: size * 0.4))
                            .foregroundColor(.gray)
                    )
            )
        }
    }
    
    // 检查角色头像是否可用
    static func isCharacterAvatarAvailable(_ id: String) -> Bool {
        return UIImage(named: id) != nil || UIImage(named: "HistoricalFigures/\(id)") != nil
    }
}

// 角色头像简单视图
struct CharacterAvatarSimple: View {
    let characterId: String
    let size: CGFloat
    
    init(_ characterId: String, size: CGFloat = 40) {
        self.characterId = characterId
        self.size = size
    }
    
    var body: some View {
        ImageHelper.loadCharacterAvatar(characterId, size: size)
    }
}
