import SwiftUI

/**
 * 分类标签栏组件
 * 用于探索页面的分类筛选
 */
struct CategoryTabs: View {
    /// 所有分类
    var categories: [String]
    /// 选中的分类索引
    @Binding var selectedIndex: Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<categories.count, id: \.self) { index in
                    Button(action: {
                        withAnimation {
                            selectedIndex = index
                        }
                    }) {
                        Text(categories[index])
                            .font(.system(size: 14, weight: selectedIndex == index ? .semibold : .regular))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .foregroundColor(selectedIndex == index ? .white : .primary)
                            .background(selectedIndex == index ? Color.primaryColor : Color.clear)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedIndex == index ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

/**
 * 分类标签栏预览
 */
struct CategoryTabs_Previews: PreviewProvider {
    static var previews: some View {
        CategoryTabs(
            categories: ["全部", "科学家", "艺术家", "哲学家", "政治家", "军事家"],
            selectedIndex: .constant(0)
        )
        .previewLayout(.sizeThatFits)
    }
} 