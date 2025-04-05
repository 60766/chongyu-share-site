import Foundation

/**
 * 关注列表类型枚举
 * 用于区分显示关注的人还是粉丝列表
 */
enum FollowListType {
    case following   // 我关注的人
    case followers   // 关注我的人
} 