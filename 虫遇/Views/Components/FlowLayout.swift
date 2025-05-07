import SwiftUI

/**
 * 流式布局视图
 * 用于自动换行排列子视图，支持水平对齐方式
 * 
 * 示例:
 * ```
 * FlowLayout(alignment: .center, spacing: 8) {
 *     ForEach(tags, id: \.self) { tag in
 *         TagView(text: tag)
 *     }
 * }
 * ```
 */
public struct FlowLayout: Layout {
    /// 水平对齐方式
    public var alignment: HorizontalAlignment
    /// 项目间的水平和垂直间距
    public var spacing: CGFloat
    /// 各行之间的额外垂直间距
    public var lineSpacing: CGFloat
    /// 使用相同的行高，默认为false（根据每行内容自动计算）
    public var useUniformRowHeight: Bool
    
    /**
     * 初始化流式布局
     * @param alignment 水平对齐方式
     * @param spacing 项目间的间距
     * @param lineSpacing 行间额外间距
     * @param useUniformRowHeight 是否使用统一行高
     */
    public init(
        alignment: HorizontalAlignment = .leading,
        spacing: CGFloat = 8,
        lineSpacing: CGFloat = 0,
        useUniformRowHeight: Bool = false
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.useUniformRowHeight = useUniformRowHeight
    }
    
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let proposalWidth = proposal.width ?? .infinity
        
        var height: CGFloat = 0
        var maxWidth: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        var uniformRowHeight: CGFloat = 0
        
        // 计算每个子视图的尺寸和排列
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if useUniformRowHeight {
                uniformRowHeight = max(uniformRowHeight, size.height)
            }
            
            // 如果当前行宽度加上新视图宽度超过容器宽度，开始新行
            if lineWidth + size.width + (lineWidth > 0 ? spacing : 0) > proposalWidth {
                // 记录最大宽度
                maxWidth = max(maxWidth, lineWidth)
                // 添加行高和行间距
                height += lineHeight + (height > 0 ? lineSpacing : 0)
                // 新行从该子视图开始
                lineWidth = size.width
                lineHeight = size.height
            } else {
                // 继续在当前行添加
                lineWidth += size.width + (lineWidth > 0 ? spacing : 0)
                lineHeight = max(lineHeight, size.height)
            }
        }
        
        // 添加最后一行
        maxWidth = max(maxWidth, lineWidth)
        height += lineHeight
        
        // 如果使用统一行高，重新计算总高度
        if useUniformRowHeight && !subviews.isEmpty {
            let totalRows = height > 0 ? ceil(height / uniformRowHeight) : 0
            height = totalRows * uniformRowHeight + max(0, totalRows - 1) * lineSpacing
        }
        
        return CGSize(width: maxWidth, height: height)
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        guard !subviews.isEmpty else { return }
        
        let proposalWidth = proposal.width ?? bounds.width
        
        var lineX = bounds.minX
        var lineY = bounds.minY
        var lineHeight: CGFloat = 0
        var uniformRowHeight: CGFloat = 0
        var rowSubviews: [(subview: LayoutSubview, width: CGFloat, height: CGFloat, x: CGFloat)] = []
        
        // 如果使用统一行高，先计算
        if useUniformRowHeight {
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                uniformRowHeight = max(uniformRowHeight, size.height)
            }
        }
        
        // 第一遍：将子视图划分到不同行，并应用水平对齐
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            // 检查是否需要开始新行
            if lineX + size.width > bounds.minX + proposalWidth {
                // 在放置行内视图前，根据对齐方式调整位置
                placeRowSubviews(rowSubviews: &rowSubviews, lineY: lineY, bounds: bounds, rowHeight: useUniformRowHeight ? uniformRowHeight : lineHeight)
                
                // 清空行缓存，为新行做准备
                rowSubviews.removeAll(keepingCapacity: true)
                lineX = bounds.minX
                lineY += (useUniformRowHeight ? uniformRowHeight : lineHeight) + lineSpacing
                lineHeight = 0
            }
            
            // 添加到当前行
            rowSubviews.append((subview, size.width, size.height, lineX))
            lineHeight = max(lineHeight, size.height)
            lineX += size.width + spacing
        }
        
        // 处理最后一行
        placeRowSubviews(rowSubviews: &rowSubviews, lineY: lineY, bounds: bounds, rowHeight: useUniformRowHeight ? uniformRowHeight : lineHeight)
    }
    
    // 根据对齐方式放置一行内的子视图
    private func placeRowSubviews(rowSubviews: inout [(subview: LayoutSubview, width: CGFloat, height: CGFloat, x: CGFloat)], lineY: CGFloat, bounds: CGRect, rowHeight: CGFloat) {
        guard !rowSubviews.isEmpty else { return }
        
        // 计算当前行所有子视图的总宽度
        let rowWidth = rowSubviews.last!.x + rowSubviews.last!.width - rowSubviews.first!.x
        
        // 根据对齐方式计算起始位置的额外偏移量
        var xOffset: CGFloat = 0
        switch alignment {
        case .center:
            xOffset = (bounds.width - rowWidth) / 2
        case .trailing:
            xOffset = bounds.width - rowWidth
        default:
            xOffset = 0
        }
        
        // 放置每个子视图
        for (subview, width, height, x) in rowSubviews {
            // 垂直居中
            let yPos = lineY + (rowHeight - height) / 2
            
            // 应用水平偏移量
            let xPos = x + xOffset
            
            // 放置子视图
            subview.place(
                at: CGPoint(x: xPos, y: yPos),
                proposal: ProposedViewSize(width: width, height: height)
            )
        }
    }
}

/**
 * 修饰符扩展
 * 方便在视图中应用流式布局
 */
public extension View {
    /**
     * 将子视图排列成流式布局
     */
    func flowLayout(
        alignment: HorizontalAlignment = .leading,
        spacing: CGFloat = 8,
        lineSpacing: CGFloat = 0,
        useUniformRowHeight: Bool = false
    ) -> some View {
        return self
            .environment(\.flowLayoutAlignment, alignment)
            .environment(\.flowLayoutSpacing, spacing)
            .environment(\.flowLayoutLineSpacing, lineSpacing)
            .environment(\.flowLayoutUseUniformRowHeight, useUniformRowHeight)
    }
}

/**
 * 环境键扩展
 * 为流式布局提供环境值
 */
private struct FlowLayoutAlignmentKey: EnvironmentKey {
    static let defaultValue: HorizontalAlignment = .leading
}

private struct FlowLayoutSpacingKey: EnvironmentKey {
    static let defaultValue: CGFloat = 8
}

private struct FlowLayoutLineSpacingKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

private struct FlowLayoutUseUniformRowHeightKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

/**
 * 环境值扩展
 */
public extension EnvironmentValues {
    var flowLayoutAlignment: HorizontalAlignment {
        get { self[FlowLayoutAlignmentKey.self] }
        set { self[FlowLayoutAlignmentKey.self] = newValue }
    }
    
    var flowLayoutSpacing: CGFloat {
        get { self[FlowLayoutSpacingKey.self] }
        set { self[FlowLayoutSpacingKey.self] = newValue }
    }
    
    var flowLayoutLineSpacing: CGFloat {
        get { self[FlowLayoutLineSpacingKey.self] }
        set { self[FlowLayoutLineSpacingKey.self] = newValue }
    }
    
    var flowLayoutUseUniformRowHeight: Bool {
        get { self[FlowLayoutUseUniformRowHeightKey.self] }
        set { self[FlowLayoutUseUniformRowHeightKey.self] = newValue }
    }
}

/**
 * 流式布局预览
 */
#Preview("流式布局") {
    VStack(spacing: 20) {
        // 默认左对齐
        VStack(alignment: .leading, spacing: 4) {
            Text("左对齐 (默认)")
                .font(.headline)
                .padding(.bottom, 4)
                
            FlowLayout(alignment: .leading, spacing: 8) {
                ForEach(1...15, id: \.self) { index in
                    Text("项目\(index)")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        
        // 居中对齐
        VStack(alignment: .leading, spacing: 4) {
            Text("居中对齐")
                .font(.headline)
                .padding(.bottom, 4)
                
            FlowLayout(alignment: .center, spacing: 8) {
                ForEach(1...15, id: \.self) { index in
                    Text("项目\(index)")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        
        // 右对齐
        VStack(alignment: .leading, spacing: 4) {
            Text("右对齐")
                .font(.headline)
                .padding(.bottom, 4)
                
            FlowLayout(alignment: .trailing, spacing: 8) {
                ForEach(1...15, id: \.self) { index in
                    Text("项目\(index)")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        
        // 统一行高示例
        VStack(alignment: .leading, spacing: 4) {
            Text("统一行高")
                .font(.headline)
                .padding(.bottom, 4)
                
            FlowLayout(alignment: .leading, spacing: 8, useUniformRowHeight: true) {
                ForEach(1...12, id: \.self) { index in
                    Text("项目\(index)")
                        .padding(.horizontal, 12)
                        .padding(.vertical, index % 3 == 0 ? 12 : 6) // 有意使高度不同
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    .padding()
} 