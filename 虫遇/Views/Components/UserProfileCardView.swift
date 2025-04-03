import SwiftUI

/**
 * 用户资料卡片组件
 * 用于显示用户基本信息和统计数据
 */
struct UserProfileCardView: View {
    // 用户数据
    let user: UserModel
    // 设置按钮点击事件
    var onSettingsTap: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部区域：设置按钮
            HStack {
                Text("个人空间")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primaryColor)
                
                Spacer()
                
                Button(action: onSettingsTap) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                        .frame(width: 40, height: 40)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
            
            // 主要资料卡
            VStack(spacing: 0) {
                // 头像和等级标签
                ZStack(alignment: .topTrailing) {
                    // 用户头像
                    if UIImage(named: user.avatar) != nil {
                        Image(user.avatar)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(String(user.username.prefix(1)))
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.primary)
                            )
                    }
                    
                    // 等级标签
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                        
                        Text("奇遇等级\(user.level)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.primaryColor)
                    .cornerRadius(16)
                    .offset(x: 20, y: -10)
                }
                .padding(.bottom, 20)
                
                // 统计数据
                HStack(spacing: 0) {
                    // 动态数
                    Spacer()
                    VStack(spacing: 4) {
                        Text("\(user.stats.posts)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primaryColor)
                        
                        Text("动态")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    // 获赞数
                    Spacer()
                    VStack(spacing: 4) {
                        Text(formatNumber(user.stats.likes))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primaryColor)
                        
                        Text("获赞")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    // 虚拟好友数
                    Spacer()
                    VStack(spacing: 4) {
                        Text("\(user.stats.friends)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primaryColor)
                        
                        Text("虚拟好友")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    // 评论数
                    Spacer()
                    VStack(spacing: 4) {
                        Text("\(user.stats.comments)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primaryColor)
                        
                        Text("评论")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 16)
        }
    }
    
    // 格式化大数字（如点赞数）
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            let formattedNumber = Double(number) / 1000.0
            return String(format: "%.1fK", formattedNumber)
        } else {
            return "\(number)"
        }
    }
}

#Preview("用户资料卡片") {
    UserProfileCardView(user: UserModel.sampleUser)
        .padding(.vertical, 20)
        .background(Color(red: 246/255, green: 248/255, blue: 250/255))
} 