import SwiftUI

/**
 * 关注列表视图
 * 展示用户的关注者或粉丝列表
 */
struct FollowListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var followManager = FollowManager.shared
    var type: FollowListType
    
    // 计算属性：根据关注列表生成用户信息
    private var followedUsers: [UserFollowInfo] {
        return followManager.followedUsers.map { username in
            UserFollowInfo(
                id: username,
                name: username,
                avatar: "person.circle",
                level: "角色"
            )
        }
    }
    
    // 模拟粉丝数据（暂时保留）
    private var followers: [UserFollowInfo] {
        return [
        UserFollowInfo(id: "1", name: "时空探索者", avatar: "person.circle", level: "Lv.5"),
        UserFollowInfo(id: "2", name: "历史研究员", avatar: "person.circle", level: "Lv.7"),
        UserFollowInfo(id: "3", name: "文艺复兴者", avatar: "person.circle", level: "Lv.4")
    ]
    }
    
    // 初始化方法
    init(type: FollowListType) {
        self.type = type
    }
    
    var body: some View {
        NavigationView {
            Group {
                if type == .following && followedUsers.isEmpty {
                    // 空状态视图
                    VStack(spacing: 20) {
                        Image(systemName: "heart")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        VStack(spacing: 8) {
                            Text("还没有关注任何角色")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("在帖子中点击关注按钮\n关注你感兴趣的角色吧")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                // 列表内容
                List {
                        ForEach(type == .following ? followedUsers : followers) { user in
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
                            if type == .following {
                            Button(action: {
                                    // 取消关注操作
                                    FollowManager.shared.unfollowUser(user.name)
                            }) {
                                    Text("已关注")
                                    .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                                .fill(Color.gray.opacity(0.1))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            } else {
                                Button(action: {
                                    // 关注操作
                                    FollowManager.shared.followUser(user.name)
                                }) {
                                    Text("关注")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(Color.primaryColor)
                                        )
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(PlainListStyle())
                }
            }
            .navigationTitle(type == .following ? "我的关注" : "我的粉丝")
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FollowStatusChanged"))) { _ in
                // 关注状态变化时刷新视图
                // followManager是@StateObject，会自动触发视图更新
            }
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