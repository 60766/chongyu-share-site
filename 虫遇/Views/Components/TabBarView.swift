import SwiftUI

/**
 * 自定义底部导航栏组件
 * 设计符合"虫遇"应用时空穿越主题的导航图标
 */
struct TabBarView: View {
    @Binding var selectedTab: Int
    
    // 定义导航项
    private let tabItems = [
        TabItem(title: "虫遇", icon: "portal.fill", selectedIcon: "portal.fill"),
        TabItem(title: "探索", icon: "telescope", selectedIcon: "telescope.fill"),
        TabItem(title: "穿越", icon: "sparkles.wormhole", selectedIcon: "sparkles.wormhole"),
        TabItem(title: "动态", icon: "timeline.selection", selectedIcon: "timeline.selection"),
        TabItem(title: "空间", icon: "person.crop.circle", selectedIcon: "person.crop.circle.fill")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabItems.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring()) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        // 图标
                        Image(systemName: selectedTab == index ? tabItems[index].selectedIcon : tabItems[index].icon)
                            .font(.system(size: 22))
                            .foregroundColor(selectedTab == index ? .primaryColor : .gray)
                        
                        // 标题
                        Text(tabItems[index].title)
                            .font(.system(size: 10))
                            .foregroundColor(selectedTab == index ? .primaryColor : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        // 选中项的背景效果
                        selectedTab == index ?
                            LinearGradient(
                                gradient: Gradient(colors: [.primaryColor.opacity(0.1), .clear]),
                                startPoint: .top,
                                endPoint: .bottom
                            ) : nil
                    )
                }
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .top
        )
    }
}

/**
 * 导航项模型
 */
struct TabItem {
    let title: String
    let icon: String
    let selectedIcon: String
}

/**
 * 自定义SF Symbol图标
 * 注意：这些是自定义图标名称，需要在实际项目中创建对应的图标资源
 */
struct CustomTabIcons: View {
    var body: some View {
        VStack(spacing: 20) {
            // 虫遇图标 - 虫洞门户
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.7), .purple.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Circle()
                    .fill(.white)
                    .frame(width: 15, height: 15)
                
                Circle()
                    .stroke(.white, lineWidth: 2)
                    .frame(width: 30, height: 30)
            }
            .overlay(
                Text("虫遇")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.top, 45)
            )
            
            // 探索图标 - 望远镜
            Image(systemName: "telescope")
                .font(.system(size: 30))
                .foregroundColor(.gray)
                .overlay(
                    Text("探索")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.top, 35)
                )
            
            // 穿越图标 - 时空门户
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 30, height: 30)
                
                ForEach(0..<5) { i in
                    Circle()
                        .fill(.white)
                        .frame(width: 3, height: 3)
                        .offset(x: CGFloat.random(in: -10...10), y: CGFloat.random(in: -10...10))
                }
            }
            .overlay(
                Text("穿越")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.top, 35)
            )
            
            // 动态图标 - 时间线
            VStack(spacing: 3) {
                ForEach(0..<3) { i in
                    HStack(spacing: 3) {
                        Circle()
                            .fill(.gray)
                            .frame(width: 5, height: 5)
                        
                        Rectangle()
                            .fill(.gray)
                            .frame(width: 20, height: 2)
                    }
                }
            }
            .overlay(
                Text("动态")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.top, 35)
            )
            
            // 空间图标 - 用户空间
            Image(systemName: "person.crop.circle")
                .font(.system(size: 30))
                .foregroundColor(.gray)
                .overlay(
                    Text("空间")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.top, 35)
                )
        }
    }
} 