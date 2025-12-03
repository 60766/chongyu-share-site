import SwiftUI

/**
 * 分类过滤器组件，用于按类别筛选内容
 */
struct CategoryFilter: View {
    /// 所有可选分类
    var categories: [String]
    /// 当前选中的分类
    @Binding var selectedCategory: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        Text(category)
                            .font(.system(size: 14, weight: selectedCategory == category ? .semibold : .regular))
                            .foregroundColor(selectedCategory == category ? .white : .primaryColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == category ? Color.primaryColor : Color.white)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.primaryColor, lineWidth: selectedCategory == category ? 0 : 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
} 
 