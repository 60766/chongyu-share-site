import SwiftUI

/**
 * View扩展 - 评论操作
 * 为视图添加评论相关的功能扩展
 */
extension View {
    /**
     * 显示评论操作菜单
     * @param post 帖子数据
     * @param commentCount 评论数量
     * @param onAddComment 添加评论回调
     * @param onViewAllComments 查看所有评论回调
     * @param onInviteCharacter 邀请历史人物回调
     */
    func showCommentActionSheet(
        for post: UserPostModel,
        commentCount: Int,
        onAddComment: @escaping () -> Void,
        onViewAllComments: @escaping () -> Void,
        onInviteCharacter: @escaping () -> Void
    ) {
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
 * 评论操作按钮
 * 可以在任意位置使用的评论操作按钮
 */
struct CommentActionButton: View {
    // 评论数量
    let commentCount: Int
    
    // 帖子对象
    let post: UserPostModel
    
    // 回调函数
    var onAddComment: () -> Void
    var onViewAllComments: () -> Void
    var onInviteCharacter: () -> Void
    
    // 状态
    @State private var showOptions: Bool = false
    
    var body: some View {
        Button(action: {
            // 显示评论操作菜单
            showCommentActionSheet(
                for: post,
                commentCount: commentCount,
                onAddComment: onAddComment,
                onViewAllComments: onViewAllComments,
                onInviteCharacter: onInviteCharacter
            )
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
    }
}