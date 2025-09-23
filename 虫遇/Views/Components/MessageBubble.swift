import SwiftUI

/**
 * 消息气泡组件，用于展示对话消息
 */
struct MessageBubble: View {
    /// 消息内容
    var message: Message
    /// 角色头像URL
    var characterAvatarUrl: String
    /// 用户头像URL
    var userAvatarUrl: String
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // 如果不是用户发送的消息，则显示角色头像
            if !message.isFromUser {
                AsyncImage(url: URL(string: characterAvatarUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray.opacity(0.3))
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    // 消息内容
                    Text(message.content.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.backgroundPrimary)
                        .cornerRadius(18)
                    
                    // 时间
                    Text(formatTime(message.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
                
                Spacer()
            } else {
                // 用户发送的消息靠右显示
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // 消息内容
                    Text(message.content.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.primaryColor)
                        .cornerRadius(18)
                    
                    // 时间
                    Text(formatTime(message.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.trailing, 8)
                }
                
                // 用户头像
                AsyncImage(url: URL(string: userAvatarUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray.opacity(0.3))
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    /**
     * 格式化消息时间
     * @param date - 日期时间
     * @return 格式化后的时间字符串
     */
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 