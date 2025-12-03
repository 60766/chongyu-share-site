import SwiftUI

/**
 * 用户数据统计视图
 * 展示用户的活动数据和成就
 */
struct UserStatsView: View {
    let stats: UserModel.UserStats
    @State private var selectedStat: StatType = .posts
    
    enum StatType: String, CaseIterable {
        case posts = "动态"
        case likes = "获赞"
        case friends = "好友"
        case comments = "评论"
        
        var icon: String {
            switch self {
            case .posts: return "square.text.square"
            case .likes: return "heart.fill"
            case .friends: return "person.2.fill"
            case .comments: return "bubble.left.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .posts: return Color(hex: "4371E5")
            case .likes: return Color(hex: "FF6B6B")
            case .friends: return Color(hex: "4CAF50")
            case .comments: return Color(hex: "FFA726")
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 数据卡片
            HStack(spacing: 0) {
                ForEach(StatType.allCases, id: \.self) { type in
                    StatCard(
                        type: type,
                        value: getValue(for: type),
                        isSelected: selectedStat == type
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedStat = type
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            
            // 选中数据详情
            if selectedStat != .posts {
                StatDetailView(type: selectedStat, value: getValue(for: selectedStat))
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private func getValue(for type: StatType) -> Int {
        switch type {
        case .posts: return stats.posts
        case .likes: return stats.likes
        case .friends: return stats.friends
        case .comments: return stats.comments
        }
    }
}

/**
 * 数据卡片组件
 */
struct StatCard: View {
    let type: UserStatsView.StatType
    let value: Int
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // 图标
            ZStack {
                Circle()
                    .fill(type.color.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(type.color)
            }
            
            // 数值
            Text(formatNumber(value))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(isSelected ? type.color : .primary)
            
            // 标签
            Text(type.rawValue)
                .font(.system(size: 12))
                .foregroundColor(isSelected ? type.color : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? type.color.opacity(0.05) : Color.clear)
        )
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            let formattedNumber = Double(number) / 1000.0
            return String(format: "%.1fK", formattedNumber)
        } else {
            return "\(number)"
        }
    }
}

/**
 * 数据详情视图
 */
struct StatDetailView: View {
    let type: UserStatsView.StatType
    let value: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Image(systemName: type.icon)
                    .font(.system(size: 16))
                    .foregroundColor(type.color)
                
                Text("\(type.rawValue)详情")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            // 数据趋势
            HStack(spacing: 16) {
                StatTrendItem(
                    title: "本周",
                    value: value / 4,
                    trend: "+12%"
                )
                
                StatTrendItem(
                    title: "本月",
                    value: value,
                    trend: "+28%"
                )
                
                StatTrendItem(
                    title: "总计",
                    value: value * 3,
                    trend: "+156%"
                )
            }
            
            // 成就提示
            if type == .friends {
                Text("已结识\(value)位历史人物，继续探索更多精彩对话！")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

/**
 * 数据趋势项
 */
struct StatTrendItem: View {
    let title: String
    let value: Int
    let trend: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Text("\(value)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(trend)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "4CAF50"))
        }
    }
}

#Preview("用户数据统计") {
    VStack {
        UserStatsView(stats: UserModel.sampleUser.stats)
        Spacer()
    }
    .padding(.top, 20)
    .background(Color(red: 246/255, green: 248/255, blue: 250/255))
} 