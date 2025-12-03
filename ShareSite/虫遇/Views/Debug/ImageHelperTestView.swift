import SwiftUI

/**
 * ImageHelper测试视图
 * 用于测试ImageHelper类的效果
 */
struct ImageHelperTestView: View {
    let characterIds = [
        "einstein", "shakespeare", "davinci", "kongzi", "newton",
        "libai", "holmes", "curie", "socrates", "plato"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("ImageHelper测试").font(.title)
                    
                    // 测试CharacterAvatarSimple
                    Group {
                        Text("使用CharacterAvatarSimple").font(.headline)
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
                    
                    // 测试ImageHelper.loadCharacterAvatar
                    Group {
                        Text("使用ImageHelper.loadCharacterAvatar").font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                            ForEach(characterIds, id: \.self) { id in
                                VStack {
                                    ImageHelper.loadCharacterAvatar(id, size: 60)
                                    Text(id).font(.caption)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("头像测试")
        }
    }
}

struct ImageHelperTestView_Previews: PreviewProvider {
    static var previews: some View {
        ImageHelperTestView()
    }
}
