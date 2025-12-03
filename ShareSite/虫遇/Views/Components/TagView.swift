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
    
    // 触觉反馈生成器
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    // 动画状态
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            // 触觉反馈
            feedbackGenerator.impactOccurred(intensity: 0.5)
            
            // 按压动画
            withAnimation(.spring(response: 0.2)) {
                isPressed = true
            }
            
            // 延迟复原
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2)) {
                    isPressed = false
                }
                onTap()
            }
        }) {
            HStack(spacing: 3) {
                Text(prefix)
                    .font(.system(size: 14, weight: .bold))
                
                Text(text)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.primaryColor)
                            .shadow(color: Color.primaryColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.12))
                    }
                }
            )
            .foregroundColor(isSelected ? .white : .primary)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // 预先准备触觉反馈
            feedbackGenerator.prepare()
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
        FlowLayout(alignment: .leading, spacing: 10) {
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