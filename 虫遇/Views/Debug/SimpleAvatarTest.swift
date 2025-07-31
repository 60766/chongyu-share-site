import SwiftUI

/**
 * 简单头像测试视图
 * 用于快速测试头像加载效果
 */
struct SimpleAvatarTest: View {
    let avatars = ["einstein", "shakespeare", "davinci", "kongzi", "newton"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("头像测试").font(.title)
            
            ForEach(avatars, id: \.self) { id in
                HStack(spacing: 20) {
                    // 使用CharacterAvatarSimple
                    CharacterAvatarSimple(id, size: 60)
                    
                    // 显示ID
                    Text(id).font(.headline)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct SimpleAvatarTest_Previews: PreviewProvider {
    static var previews: some View {
        SimpleAvatarTest()
    }
}
