import SwiftUI

/**
 * 互动记录类型
 */
enum InteractionType: String, CaseIterable {
    case chat = "聊天"
    case like = "点赞"
    case comment = "评论"
    
    var iconName: String {
        switch self {
        case .chat:
            return "bubble.left.and.bubble.right"
        case .like:
            return "heart"
        case .comment:
            return "text.bubble"
        }
    }
    
    var color: Color {
        switch self {
        case .chat:
            return Color.blue
        case .like:
            return Color.red
        case .comment:
            return Color.green
        }
    }
}

/**
 * 互动记录模型
 */
struct InteractionRecord: Identifiable {
    let id = UUID()
    let characterName: String
    let characterAvatar: String
    let type: InteractionType
    let content: String
    let timestamp: Date
    
    // 示例数据
    static let samples: [InteractionRecord] = [
        InteractionRecord(
            characterName: "爱因斯坦",
            characterAvatar: "avatar_einstein",
            type: .chat,
            content: "讨论了相对论的基本原理和宇宙膨胀理论",
            timestamp: Date().addingTimeInterval(-3600 * 24 * 2)
        ),
        InteractionRecord(
            characterName: "莎士比亚",
            characterAvatar: "avatar_shakespeare",
            type: .like,
            content: "点赞了你的《哈姆雷特》解读",
            timestamp: Date().addingTimeInterval(-3600 * 12)
        ),
        InteractionRecord(
            characterName: "达芬奇",
            characterAvatar: "avatar_davinci",
            type: .comment,
            content: "评论了你的观点：'这个视角非常独特，让我想到了...'",
            timestamp: Date().addingTimeInterval(-3600 * 5)
        ),
        InteractionRecord(
            characterName: "苏格拉底",
            characterAvatar: "avatar_socrates",
            type: .chat,
            content: "探讨了真理与知识的本质",
            timestamp: Date().addingTimeInterval(-3600 * 72)
        ),
        InteractionRecord(
            characterName: "居里夫人",
            characterAvatar: "avatar_curie",
            type: .comment,
            content: "回复了你的问题：'放射性物质确实具有...'",
            timestamp: Date().addingTimeInterval(-3600 * 36)
        )
    ]
}

/**
 * 互动记录卡片
 */
struct InteractionRecordCardView: View {
    let record: InteractionRecord
    var onTap: () -> Void = {}
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 角色头像
                if UIImage(named: record.characterAvatar) != nil {
                    Image(record.characterAvatar)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(String(record.characterName.prefix(1)))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // 角色名称和互动类型
                    HStack {
                        Text(record.characterName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: record.type.iconName)
                                .font(.system(size: 12))
                                .foregroundColor(record.type.color)
                            
                            Text(record.type.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(record.type.color)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(record.type.color.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // 互动内容
                    Text(record.content)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // 时间戳
                    Text(formatDate(record.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 箭头图标
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

/**
 * 互动记录列表
 */
struct InteractionRecordListView: View {
    let records: [InteractionRecord]
    var onRecordTap: (InteractionRecord) -> Void = { _ in }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(records) { record in
                InteractionRecordCardView(record: record) {
                    onRecordTap(record)
                }
            }
        }
    }
}

#Preview("互动记录") {
    ScrollView {
        InteractionRecordListView(records: InteractionRecord.samples)
            .padding(16)
    }
    .background(Color(red: 246/255, green: 248/255, blue: 250/255))
} 