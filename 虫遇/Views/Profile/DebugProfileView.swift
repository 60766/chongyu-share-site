import SwiftUI

/**
 * 调试版个人空间页
 * 用于开发时调试布局和渲染问题
 */
struct DebugProfileView: View {
    @State private var selectedTabIndex = 0
    private let tabOptions = ["角色关系", "我的动态", "互动记录"]
    
    var body: some View {
        // 移除NavigationView，直接使用ScrollView
        ScrollView {
            VStack(spacing: 16) {
                // 调试信息标题
                Text("调试模式")
                    .font(.system(size: 16, weight: .bold))
                    .padding(8)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                
                // 简化的用户信息
                VStack(spacing: 8) {
                    // 用户头像
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text("头像")
                                .foregroundColor(.gray)
                        )
                    
                    // 用户名
                    Text("调试用户")
                        .font(.headline)
                    
                    // 等级和简介
                    Text("Lv.0 - 调试模式")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // 简化的内容区域
                VStack {
                    // 标签选择器
                    HStack {
                        ForEach(tabOptions, id: \.self) { tab in
                            Text(tab)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    
                    // 调试内容区
                    VStack {
                        Text("调试内容区")
                            .padding()
                        
                        ForEach(1...5, id: \.self) { i in
                            HStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 30, height: 30)
                                
                                VStack(alignment: .leading) {
                                    Text("调试项 \(i)")
                                        .font(.caption)
                                    Text("描述信息")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            }
            .padding()
        }
        .background(Color(red: 246/255, green: 248/255, blue: 250/255))
    }
}

#Preview("调试版个人空间") {
    DebugProfileView()
} 