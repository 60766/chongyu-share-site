import SwiftUI

// 为避免重复声明错误，使用命名空间包装这些扩展
enum EdgeFixNamespace {
    // 为SwiftUI.Edge.Set提供静态属性，使用不同的命名以避免冲突
    static let topEdge: Edge.Set = .top
    static let bottomEdge: Edge.Set = .bottom
    static let leadingEdge: Edge.Set = .leading
    static let trailingEdge: Edge.Set = .trailing
    static let horizontalEdges: Edge.Set = .horizontal
    static let verticalEdges: Edge.Set = .vertical
    static let allEdges: Edge.Set = .all
}

// 如果需要保持原API的便利性，可以提供这样的包装函数
extension View {
    /// 应用边缘内边距，避免与系统API冲突
    func applyEdgePadding(_ edges: Edge.Set, _ length: CGFloat) -> some View {
        self.padding(edges, length)
    }
}

// 如果DetailDisplayConversation被重复声明，请改用一个不同的名称
struct ConversationDisplayDetail: Identifiable, Hashable {
    let id: UUID
    let title: String
    let lastMessage: String
    let date: Date
    let unreadCount: Int
    
    // Hashable实现
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ConversationDisplayDetail, rhs: ConversationDisplayDetail) -> Bool {
        return lhs.id == rhs.id
    }
} 