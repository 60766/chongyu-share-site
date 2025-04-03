import SwiftUI

/**
 * 话题标签视图
 * 用于显示话题标签，支持可选和已选状态
 */
struct TagView: View {
    /// 标签文本
    var text: String
    /// 前缀符号
    var prefix: String = "#"
    /// 是否已选中
    var isSelected: Bool = false
    /// 点击事件
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 2) {
                Text(prefix)
                    .font(.system(size: 14, weight: .bold))
                
                Text(text)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.primaryColor : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

/**
 * 话题标签集合视图
 * 用于显示一组话题标签
 */
struct TagCollectionView: View {
    /// 所有可用标签
    var tags: [String]
    /// 已选标签
    var selectedTags: [String]
    /// 标签点击回调
    var onTagTap: (String) -> Void
    
    /// 每行最大宽度
    private let maxWidth: CGFloat = UIScreen.main.bounds.width - 32
    
    var body: some View {
        FlowLayout(alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                TagView(
                    text: tag,
                    isSelected: selectedTags.contains(tag),
                    onTap: {
                        onTagTap(tag)
                    }
                )
            }
        }
    }
}

/**
 * 流式布局视图
 * 用于自动换行排列子视图
 */
struct FlowLayout: Layout {
    var alignment: HorizontalAlignment = .leading
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let proposalWidth = proposal.width ?? .infinity
        
        var height: CGFloat = 0
        var maxWidth: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if lineWidth + size.width + (lineWidth > 0 ? spacing : 0) > proposalWidth {
                // 需要换行
                maxWidth = max(maxWidth, lineWidth)
                height += lineHeight + spacing
                lineWidth = size.width
                lineHeight = size.height
            } else {
                // 继续当前行
                lineWidth += size.width + (lineWidth > 0 ? spacing : 0)
                lineHeight = max(lineHeight, size.height)
            }
        }
        
        // 添加最后一行
        maxWidth = max(maxWidth, lineWidth)
        height += lineHeight
        
        return CGSize(width: maxWidth, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var lineX = bounds.minX
        var lineY = bounds.minY
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if lineX + size.width > bounds.maxX {
                // 需要换行
                lineX = bounds.minX
                lineY += lineHeight + spacing
                lineHeight = 0
            }
            
            // 放置视图
            subview.place(
                at: CGPoint(x: lineX, y: lineY),
                proposal: ProposedViewSize(size)
            )
            
            lineHeight = max(lineHeight, size.height)
            lineX += size.width + spacing
        }
    }
}

/**
 * 话题标签视图预览
 */
#Preview("标签视图") {
    VStack(spacing: 20) {
        TagView(text: "日常见闻", isSelected: true, onTap: {})
        
        TagView(text: "思想碰撞", isSelected: false, onTap: {})
        
        TagCollectionView(
            tags: ["日常见闻", "思想碰撞", "美食探索", "旅途风景", "艺术鉴赏", "科技前沿"],
            selectedTags: ["日常见闻"],
            onTagTap: { _ in }
        )
        .padding(.horizontal, 16)
    }
    .padding()
} 