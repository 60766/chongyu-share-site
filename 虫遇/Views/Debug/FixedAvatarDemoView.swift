import SwiftUI

/**
 * 修复后的头像演示视图
 * 展示使用ImageHelper加载头像的效果
 */
struct FixedAvatarDemoView: View {
    let characters = ["einstein", "shakespeare", "davinci", "kongzi", "newton"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("头像修复演示").font(.title)
                    
                    // 展示修复后的头像
                    ForEach(characters, id: \.self) { id in
                        HStack(spacing: 20) {
                            // 使用CharacterAvatarSimple
                            VStack {
                                CharacterAvatarSimple(id, size: 60)
                                Text("CharacterAvatarSimple")
                                    .font(.caption)
                            }
                            
                            // 使用ImageHelper
                            VStack {
                                ImageHelper.loadCharacterAvatar(id, size: 60)
                                Text("ImageHelper")
                                    .font(.caption)
                            }
                            
                            // 显示角色ID
                            Text(id)
                                .font(.headline)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("头像修复演示")
        }
    }
}

struct FixedAvatarDemoView_Previews: PreviewProvider {
    static var previews: some View {
        FixedAvatarDemoView()
    }
}
