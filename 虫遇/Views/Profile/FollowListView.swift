import SwiftUI

/**
 * 关注列表视图
 * 展示用户的关注者或粉丝列表
 */
struct FollowListView: View {
    @Environment(\.dismiss) private var dismiss
    var type: FollowListType
    
    // 模拟数据
    var followers = [
        UserFollowInfo(id: "1", name: "时空探索者", avatar: "person.circle", level: "Lv.5"),
        UserFollowInfo(id: "2", name: "历史研究员", avatar: "person.circle", level: "Lv.7"),
        UserFollowInfo(id: "3", name: "文艺复兴者", avatar: "person.circle", level: "Lv.4")
    ]
    
    var following = [
        UserFollowInfo(id: "4", name: "科学先驱", avatar: "person.circle", level: "Lv.6"),
        UserFollowInfo(id: "5", name: "哲学智者", avatar: "person.circle", level: "Lv.8")
    ]
    
    // 预览使用的初始化方法
    init(type: FollowListType) {
        self.type = type
    }
    
    // 自定义初始化方法，允许传入数据
    init(type: FollowListType, followers: [UserFollowInfo] = [], following: [UserFollowInfo] = []) {
        self.type = type
        if !followers.isEmpty {
            self.followers = followers
        }
        if !following.isEmpty {
            self.following = following
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 列表内容
                List {
                    ForEach(type == .following ? following : followers) { user in
                        HStack(spacing: 12) {
                            // 头像
                            Image(systemName: user.avatar)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .foregroundColor(.primaryColor)
                                .background(Color.white)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.primaryColor.opacity(0.2), lineWidth: 1)
                                )
                            
                            // 用户信息
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text(user.level)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // 关注按钮
                            Button(action: {
                                // 关注/取消关注操作
                            }) {
                                Text(type == .following ? "已关注" : "关注")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(type == .following ? .secondary : .white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(type == .following ? Color.gray.opacity(0.1) : Color.primaryColor)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(type == .following ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle(type == .following ? "我的关注" : "我的粉丝")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("返回")
                                .font(.system(size: 17, weight: .regular))
                        }
                        .foregroundColor(.primaryColor)
                    }
                }
            }
        }
    }
}

/**
 * 用户关注信息模型
 */
struct UserFollowInfo: Identifiable {
    var id: String
    var name: String
    var avatar: String
    var level: String
}

#Preview {
    FollowListView(type: .following)
}

#Preview {
    FollowListView(type: .followers)
} 