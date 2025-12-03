import SwiftUI

/**
 * 头像测试视图
 * 用于测试不同角色头像的加载效果
 */
struct AvatarTestView: View {
    let characterIds = [
        "einstein", "shakespeare", "davinci", "kongzi", "newton",
        "libai", "holmes", "curie", "socrates", "plato"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("角色头像测试").font(.title)
                
                // 测试直接使用Image
                Group {
                    Text("方法1: 直接使用Image").font(.headline)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                        ForEach(characterIds, id: \.self) { id in
                            VStack {
                                Image(id)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                                Text(id).font(.caption)
                            }
                        }
                    }
                }
                
                Divider()
                
                // 测试使用ImageHelper
                Group {
                    Text("方法2: 使用ImageHelper").font(.headline)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                        ForEach(characterIds, id: \.self) { id in
                            VStack {
                                CharacterAvatarSimple(id, size: 60)
                                Text(id).font(.caption)
                            }
                        }
                    }
                }
                
                Divider()
                
                // 测试使用完整路径
                Group {
                    Text("方法3: 使用完整路径").font(.headline)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                        ForEach(characterIds, id: \.self) { id in
                            VStack {
                                if let image = UIImage(named: "HistoricalFigures/\(id)") {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                                } else {
                                    Circle()
                                        .fill(Color.red.opacity(0.3))
                                        .frame(width: 60, height: 60)
                                }
                                Text(id).font(.caption)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}
