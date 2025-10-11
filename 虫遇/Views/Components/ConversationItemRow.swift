/**
 * ConversationItemRow.swift
 * 虫遇 App
 * 
 * 会话列表项组件
 * 在角色详情页的互动记录标签页中显示历史会话
 */

import SwiftUI

/**
 * 会话列表项
 * 显示一条历史会话的信息，包括最后一条消息内容、时间和消息数量
 */
struct ConversationItemRow: View {
    /// 会话数据
    var conversation: DisplayConversation
    
    /// 会话主题颜色
    var theme: Color {
        // 根据会话内容或角色ID生成一个主题色
        // 这里简单实现，可以根据需求调整
        let seed = conversation.characterId.hash % 5
        switch seed {
        case 0:
            return Color.blue.opacity(0.8)
        case 1:
            return Color.purple.opacity(0.8)
        case 2:
            return Color.green.opacity(0.8)
        case 3:
            return Color(red: 0.9, green: 0.5, blue: 0.3)
        default:
            return Color(red: 0.6, green: 0.4, blue: 0.8)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 会话图标
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 20))
                .foregroundColor(theme)
                .frame(width: 40, height: 40)
                .background(theme.opacity(0.1))
                .clipShape(Circle())
            
            // 会话信息
            VStack(alignment: .leading, spacing: 4) {
                // 最后一条消息
                Text(conversation.lastMessageContent)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // 时间和消息数量
                HStack {
                    Text(formatTime(conversation.lastMessageTime))
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("\(conversation.messageCount)条消息")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(DesignSystem.Colors.background)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /**
     * 格式化时间为易读形式
     */
    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // 如果是今天
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "今天 " + formatter.string(from: date)
        }
        
        // 如果是昨天
        if calendar.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "昨天 " + formatter.string(from: date)
        }
        
        // 如果是最近七天
        let components = calendar.dateComponents([.day], from: date, to: now)
        if let day = components.day, day < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter.string(from: date)
        }
        
        // 其他日期
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// 预览
#Preview {
    VStack(spacing: 12) {
        ConversationItemRow(
            conversation: DisplayConversation(
                id: "1",
                characterId: "character1",
                userId: "user1",
                lastMessageContent: "这是一条测试消息，讨论了一些历史问题。",
                lastMessageTime: Date().addingTimeInterval(-3600 * 2),
                messageCount: 12
            )
        )
        
        ConversationItemRow(
            conversation: DisplayConversation(
                id: "2",
                characterId: "character2",
                userId: "user1",
                lastMessageContent: "能否详细解释一下您对这个问题的看法？",
                lastMessageTime: Date().addingTimeInterval(-3600 * 24),
                messageCount: 5
            )
        )
    }
    .padding()
    .background(Color(.systemGray6))
} 