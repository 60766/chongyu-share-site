import SwiftUI

/**
 * 个人中心标签选择组件
 * 用于在个人中心页面中切换不同内容
 */
struct ProfileTabView: View {
    // 标签列表
    var tabs: [String]
    // 当前选中标签
    @Binding var selectedTab: Int
    // 是否使用填充背景
    var useFilledBackground: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation {
                        selectedTab = index
                    }
                }) {
                    Text(tabs[index])
                        .font(.system(size: 16, weight: selectedTab == index ? .semibold : .regular))
                        .foregroundColor(selectedTab == index ? (useFilledBackground ? .white : .primaryColor) : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedTab == index && useFilledBackground ? 
                                Color.primaryColor : 
                                Color.clear
                        )
                        .cornerRadius(useFilledBackground ? 20 : 0)
                        .overlay(
                            selectedTab == index && !useFilledBackground ?
                                Rectangle()
                                    .frame(height: 3)
                                    .foregroundColor(.primaryColor)
                                    .offset(y: 15)
                                : nil,
                            alignment: .bottom
                        )
                        .padding(.horizontal, useFilledBackground ? 4 : 0)
                }
            }
        }
        .padding(.horizontal, useFilledBackground ? 16 : 0)
        .background(useFilledBackground ? Color.white.opacity(0.05) : Color.clear)
        .cornerRadius(useFilledBackground ? 20 : 0)
    }
}

#Preview("个人中心标签") {
    VStack(spacing: 20) {
        ProfileTabView(
            tabs: ["角色关系", "我的动态", "我的点赞"],
            selectedTab: .constant(0)
        )
        
        ProfileTabView(
            tabs: ["角色关系", "我的动态", "我的点赞"],
            selectedTab: .constant(1),
            useFilledBackground: true
        )
    }
    .padding()
    .background(Color(red: 246/255, green: 248/255, blue: 250/255))
} 