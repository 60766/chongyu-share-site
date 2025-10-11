import SwiftUI

/**
 * 内容标签页视图
 * 提供优雅的标签切换效果和内容展示
 */
struct ContentTabView: View {
    let tabs: [String]
    @Binding var selectedTab: Int
    @State private var tabOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 标签栏
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 32) {
                    ForEach(Array(tabs.enumerated()), id: \.element) { index, tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = index
                            }
                        }) {
                            VStack {
                                Text(tab)
                                    .font(.system(size: 16, weight: selectedTab == index ? .semibold : .regular))
                                    .foregroundColor(selectedTab == index ? Color(hex: "4371E5") : .secondary)
                                    .padding(.vertical, 12)
                                
                                // 选中状态指示线
                                Rectangle()
                                    .fill(selectedTab == index ? Color(hex: "4371E5") : Color.clear)
                                    .frame(height: 3)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: 80)
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(DesignSystem.Colors.background)
            .overlay(
                // 底部阴影
                Rectangle()
                    .fill(Color.black.opacity(0.05))
                    .frame(height: 1)
                    .offset(y: 1)
            )
        }
    }
}

/**
 * 标签页内容容器
 */
struct TabContentView<Content: View>: View {
    let content: Content
    let isSelected: Bool
    
    init(isSelected: Bool, @ViewBuilder content: () -> Content) {
        self.isSelected = isSelected
        self.content = content()
    }
    
    var body: some View {
        Group {
            if isSelected {
                content
            } else {
                EmptyView()
            }
        }
    }
}

#Preview("内容标签页") {
    VStack {
        ContentTabView(
            tabs: ["角色关系", "我的动态", "我的点赞"],
            selectedTab: .constant(0)
        )
        
        Spacer()
    }
    .background(Color(red: 246/255, green: 248/255, blue: 250/255))
} 