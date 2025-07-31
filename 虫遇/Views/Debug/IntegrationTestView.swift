import SwiftUI

/**
 * 集成测试视图
 * 用于测试ImageHelper在实际场景中的效果
 */
struct IntegrationTestView: View {
    // 模拟帖子数据
    let posts = [
        MockPost(id: "1", userAvatar: "einstein", userName: "爱因斯坦", content: "相对论是我的重要发现"),
        MockPost(id: "2", userAvatar: "shakespeare", userName: "莎士比亚", content: "生存还是毁灭，这是个问题"),
        MockPost(id: "3", userAvatar: "davinci", userName: "达芬奇", content: "蒙娜丽莎的微笑是我的杰作"),
        MockPost(id: "4", userAvatar: "kongzi", userName: "孔子", content: "学而不思则罔，思而不学则殆"),
        MockPost(id: "5", userAvatar: "newton", userName: "牛顿", content: "我站在巨人的肩膀上")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(posts) { post in
                    PostRow(post: post)
                }
            }
            .navigationTitle("集成测试")
        }
    }
    
    // 帖子行视图
    struct PostRow: View {
        let post: MockPost
        
        var body: some View {
            HStack(spacing: 12) {
                // 使用CharacterAvatarSimple显示头像
                CharacterAvatarSimple(post.userAvatar, size: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.userName)
                        .font(.headline)
                    
                    Text(post.content)
                        .font(.body)
                        .lineLimit(3)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // 模拟帖子模型
    struct MockPost: Identifiable {
        let id: String
        let userAvatar: String
        let userName: String
        let content: String
    }
}

struct IntegrationTestView_Previews: PreviewProvider {
    static var previews: some View {
        IntegrationTestView()
    }
}
