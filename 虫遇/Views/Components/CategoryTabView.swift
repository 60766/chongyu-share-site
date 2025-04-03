import SwiftUI

/**
 * 分类标签选择组件
 * 用于在探索页面筛选不同类型的内容
 */
struct CategoryTabView: View {
    // 当前选中的分类
    @Binding var selectedCategory: CharacterCategory
    // 标签样式（是否使用圆角矩形样式）
    var isRoundedStyle: Bool = true
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CharacterCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        if isRoundedStyle {
                            // 圆角矩形样式
                            Text(category.rawValue)
                                .font(.system(size: 16, weight: selectedCategory == category ? .semibold : .regular))
                                .foregroundColor(selectedCategory == category ? .white : .secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    selectedCategory == category ?
                                    Color.primaryColor :
                                    Color.white
                                )
                                .cornerRadius(18)
                                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                        } else {
                            // 简单文本样式
                            Text(category.rawValue)
                                .font(.system(size: 16, weight: selectedCategory == category ? .semibold : .regular))
                                .foregroundColor(selectedCategory == category ? .primary : .secondary)
                                .padding(.vertical, 8)
                                .overlay(
                                    selectedCategory == category ?
                                    Rectangle()
                                        .frame(height: 2)
                                        .foregroundColor(.primaryColor)
                                        .offset(y: 12)
                                    : nil
                                )
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.white)
    }
}

#Preview("分类标签") {
    VStack {
        CategoryTabView(selectedCategory: .constant(.all))
        
        Divider()
        
        CategoryTabView(selectedCategory: .constant(.scientist), isRoundedStyle: false)
    }
} 