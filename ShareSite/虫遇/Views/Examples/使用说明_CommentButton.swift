import SwiftUI

/**
 * 如何使用评论按钮组件
 *
 * 在PostCardView中：
 * CommentButton(
 *     commentCount: post.comments.count,
 *     post: post,
 *     onAddComment: { /* 添加评论 */ },
 *     onViewAllComments: { /* 查看全部评论 */ },
 *     onInviteCharacter: { /* 邀请历史人物 */ }
 * )
 *
 * 在PostDetailView中：
 * CommentButton(
 *     commentCount: post.comments.count,
 *     post: 
 * )
 * .sheet(isPresented: ) {
 *     CommentManager(post: )
 * }
 */

