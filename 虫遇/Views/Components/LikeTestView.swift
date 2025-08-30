import SwiftUI

/**
 * 点赞功能测试视图
 * 用于验证UserLikeService的功能是否正常
 */
struct LikeTestView: View {
    @StateObject private var likeService = UserLikeService.shared
    @StateObject private var postViewModel = PostViewModel.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 统计信息
                VStack(spacing: 12) {
                    Text("点赞统计")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 30) {
                        VStack {
                            Text("\(likeService.getUserLikes(type: .post).count)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("帖子点赞")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(likeService.getUserLikes(type: .comment).count)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("评论点赞")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(likeService.getUserLikes().count)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            Text("总计")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // 操作按钮
                VStack(spacing: 12) {
                    Text("测试操作")
                        .font(.headline)
                    
                    Button("模拟点赞第一个帖子") {
                        if let firstPost = postViewModel.posts.first {
                            postViewModel.likePost(firstPost)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("清空所有点赞记录") {
                        likeService.clearAllLikes()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    
                    NavigationLink("查看点赞记录") {
                        MyLikesView()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // 最近的点赞记录
                if !likeService.getUserLikes().isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("最近点赞")
                            .font(.headline)
                        
                        ForEach(likeService.getUserLikes().prefix(3)) { record in
                            HStack {
                                Image(systemName: record.type.iconName)
                                    .foregroundColor(record.type.color)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(record.title.isEmpty ? record.content : record.title)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Text("by \(record.authorName)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(timeAgoString(from: record.timestamp))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("点赞测试")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    LikeTestView()
} 