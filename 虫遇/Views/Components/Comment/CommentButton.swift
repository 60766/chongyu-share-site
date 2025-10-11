import SwiftUI

/**
 * 评论管理器视图
 * 包装 CommentManager 对象并提供UI界面
 */
struct CommentManagerView: View {
    @StateObject private var manager: CommentManager
    @Environment(\.dismiss) private var dismiss
    
    // 用于记录已点赞的评论ID
    @State private var likedComments = Set<UUID>()
    
    init(post: UserPostModel) {
        self._manager = StateObject(wrappedValue: CommentManager(post: post))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
                Button("取消") {
                    dismiss()
                }
                .padding(.horizontal)
                
                Spacer()
                
                Text("评论")
                    .font(.headline)
                
                Spacer()
                
                Button("完成") {
                    dismiss()
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
            .background(Color(UIColor.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .bottom
            )
            
            // 评论列表
            ScrollView {
                CommentsListView(
                    comments: manager.topLevelComments,
                    onReply: { comment in
                        manager.replyTo(comment: comment)
                    },
                    onLike: { comment in
                        // 切换点赞状态
                        if likedComments.contains(comment.id) {
                            likedComments.remove(comment.id)
                        } else {
                            likedComments.insert(comment.id)
                        }
                        // 调用管理器的点赞方法（如果有）
                        manager.currentPost.likeComment(commentId: comment.id)
                    }
                )
                
                // 添加底部空间，避免评论被输入框遮挡
                Spacer(minLength: 70)
            }
            
            Spacer(minLength: 0)
        }
        .overlay(
            // 评论输入区 - 作为覆盖层显示在底部
            VStack(spacing: 0) {
                // 显示正在回复的状态
                if let replyingTo = manager.replyingToComment {
                    HStack {
                        Text("回复：")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                        
                        Text(replyingTo.username)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            manager.cancelReply()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.05))
                }
                
                // 输入框和发送按钮
                HStack(alignment: .bottom, spacing: 12) {
                    // 评论输入框
                    TextField("跨越时空的对话...", text: $manager.commentText)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(20)
                    
                    // 发送按钮
                    Button(action: {
                        if !manager.commentText.isEmpty {
                            manager.submitComment()
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(manager.commentText.isEmpty ? .gray : .blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(DesignSystem.Colors.background)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
            }
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Colors.background)
            .alignmentGuide(.bottom) { _ in 0 },
            alignment: .bottom
        )
        .ignoresSafeArea(.keyboard)
    }
}

/**
 * 评论按钮组件
 * 封装了评论按钮及其点击后的操作菜单
 */
struct CommentButton: View {
    // 评论数量
    let commentCount: Int
    
    // 帖子对象
    @Binding var post: UserPostModel
    
    // 回调函数
    var onAddComment: () -> Void
    var onViewAllComments: () -> Void
    var onInviteCharacter: () -> Void
    
    // 状态
    @State private var showCommentManager: Bool = false
    
    // 构造函数 - 支持非绑定版本
    init(commentCount: Int, post: UserPostModel, onAddComment: @escaping () -> Void, onViewAllComments: @escaping () -> Void, onInviteCharacter: @escaping () -> Void) {
        self.commentCount = commentCount
        self._post = Binding.constant(post)
        self.onAddComment = onAddComment
        self.onViewAllComments = onViewAllComments
        self.onInviteCharacter = onInviteCharacter
    }
    
    // 构造函数 - 支持绑定版本
    init(commentCount: Int, post: Binding<UserPostModel>, onAddComment: @escaping () -> Void = {}, onViewAllComments: @escaping () -> Void = {}, onInviteCharacter: @escaping () -> Void = {}) {
        self.commentCount = commentCount
        self._post = post
        self.onAddComment = onAddComment
        self.onViewAllComments = onViewAllComments
        self.onInviteCharacter = onInviteCharacter
    }
    
    var body: some View {
        Button(action: {
            // 使用新的评论管理器
            let impactMed = UIImpactFeedbackGenerator(style: .medium); impactMed.impactOccurred(); showCommentManager = true
        }) {
            HStack(spacing: 6) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                
                Text("\(commentCount)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .sheet(isPresented: $showCommentManager) {
            CommentManagerView(post: post)
        }
    }
    
    /**
     * 显示原生操作表单
     * 使用UIKit实现更可靠的操作表单
     */
    private func showNativeActionSheet() {
        // 生成触感反馈
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // 创建操作表单
        let actionSheet = UIAlertController(
            title: "评论操作",
            message: "请选择您想要的操作",
            preferredStyle: .actionSheet
        )
        
        // 添加评论选项
        actionSheet.addAction(UIAlertAction(
            title: "发表评论",
            style: .default,
            handler: { _ in
                onAddComment()
            }
        ))
        
        // 查看所有评论
        actionSheet.addAction(UIAlertAction(
            title: "查看全部评论(\(commentCount))",
            style: .default,
            handler: { _ in
                onViewAllComments()
            }
        ))
        
        // 邀请历史人物
        actionSheet.addAction(UIAlertAction(
            title: "邀请历史人物参与",
            style: .default,
            handler: { _ in
                onInviteCharacter()
            }
        ))
        
        // 取消选项
        actionSheet.addAction(UIAlertAction(
            title: "取消",
            style: .cancel,
            handler: nil
        ))
        
        // 获取当前控制器并显示操作表单
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            var currentController = rootViewController
            while let presented = currentController.presentedViewController {
                currentController = presented
            }
            currentController.present(actionSheet, animated: true)
        }
    }
}

/**
 * 评论按钮(底部操作栏版本)
 * 样式与底部操作栏一致
 */
struct BottomBarCommentButton: View {
    // 评论数量
    let commentCount: Int
    
    // 帖子对象
    @Binding var post: UserPostModel
    
    // 回调函数
    var onAddComment: () -> Void
    var onViewAllComments: () -> Void
    var onInviteCharacter: () -> Void
    
    // 状态
    @State private var showCommentManager: Bool = false
    
    // 构造函数 - 支持非绑定版本
    init(commentCount: Int, post: UserPostModel, onAddComment: @escaping () -> Void, onViewAllComments: @escaping () -> Void, onInviteCharacter: @escaping () -> Void) {
        self.commentCount = commentCount
        self._post = Binding.constant(post)
        self.onAddComment = onAddComment
        self.onViewAllComments = onViewAllComments
        self.onInviteCharacter = onInviteCharacter
    }
    
    // 构造函数 - 支持绑定版本
    init(commentCount: Int, post: Binding<UserPostModel>, onAddComment: @escaping () -> Void = {}, onViewAllComments: @escaping () -> Void = {}, onInviteCharacter: @escaping () -> Void = {}) {
        self.commentCount = commentCount
        self._post = post
        self.onAddComment = onAddComment
        self.onViewAllComments = onViewAllComments
        self.onInviteCharacter = onInviteCharacter
    }
    
    var body: some View {
        Button(action: {
            // 使用新的评论管理器
            let impactMed = UIImpactFeedbackGenerator(style: .medium); impactMed.impactOccurred(); showCommentManager = true
        }) {
            HStack(spacing: 6) {
                Image(systemName: "bubble.right")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                Text("\(commentCount)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showCommentManager) {
            CommentManagerView(post: post)
        }
    }
}

/**
 * 预览
 */
struct CommentButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CommentButton(
                commentCount: 42,
                post: ModelData.samplePosts[0],
                onAddComment: {},
                onViewAllComments: {},
                onInviteCharacter: {}
            )
            
            BottomBarCommentButton(
                commentCount: 42,
                post: ModelData.samplePosts[0],
                onAddComment: {},
                onViewAllComments: {},
                onInviteCharacter: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}