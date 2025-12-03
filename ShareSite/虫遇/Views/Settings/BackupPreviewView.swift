import SwiftUI

/// 备份内容预览视图
/// 显示备份文件的摘要信息，不显示完整内容
struct BackupPreviewView: View {
    let backup: BackupFile
    @Environment(\.dismiss) private var dismiss
    @State private var backupData: [String: Any]?
    @State private var isLoading = true
    @State private var loadError: String?
    
    private var primaryAccentColor: Color {
        Color(hex: "9A8BB0")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = loadError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("加载失败")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if let data = backupData {
                    List {
                        // 备份基本信息
                        Section(header: Text("备份信息").textCase(nil)) {
                            BackupInfoRow(label: "文件名", value: backup.fileName)
                            BackupInfoRow(label: "创建时间", value: backup.formattedDate)
                            BackupInfoRow(label: "文件大小", value: backup.formattedSize)
                            
                            if let exportInfo = data["exportInfo"] as? [String: Any],
                               let version = exportInfo["version"] as? String {
                                BackupInfoRow(label: "备份版本", value: "v\(version)")
                            }
                        }
                        
                        // 用户资料
                        if let profile = data["profile"] as? [String: Any] {
                            Section(header: Text("用户资料").textCase(nil)) {
                                if let nickname = profile["nickname"] as? String {
                                    BackupInfoRow(label: "昵称", value: nickname)
                                }
                                if let level = profile["level"] as? Int {
                                    BackupInfoRow(label: "等级", value: "Lv.\(level)")
                                }
                                if let levelTitle = profile["levelTitle"] as? String {
                                    BackupInfoRow(label: "称号", value: levelTitle)
                                }
                            }
                        }
                        
                        // 数据统计
                        Section(header: Text("数据统计").textCase(nil)) {
                            // 帖子统计（从 highlights 获取）
                            if let highlights = data["highlights"] as? [String: Any] {
                                if let totalPosts = highlights["totalPosts"] as? Int {
                                    BackupInfoRow(label: "帖子总数", value: "\(totalPosts) 条")
                                }
                                if let userPosts = highlights["userPosts"] as? Int {
                                    BackupInfoRow(label: "用户帖子", value: "\(userPosts) 条")
                                }
                                if let aiPosts = highlights["aiPosts"] as? Int {
                                    BackupInfoRow(label: "AI帖子", value: "\(aiPosts) 条")
                                }
                                if let totalComments = highlights["totalComments"] as? Int {
                                    BackupInfoRow(label: "评论总数", value: "\(totalComments) 条")
                                }
                            }
                            
                            // 自定义角色（从 myCreations 或 highlights 获取）
                            if let myCreations = data["myCreations"] as? [String: Any],
                               let customCharacters = myCreations["customCharacters"] as? [[String: Any]] {
                                BackupInfoRow(label: "自定义角色", value: "\(customCharacters.count) 个")
                            } else if let highlights = data["highlights"] as? [String: Any],
                                      let count = highlights["totalCustomCharacters"] as? Int {
                                BackupInfoRow(label: "自定义角色", value: "\(count) 个")
                            }
                            
                            // 私聊对话
                            if let conversations = data["conversations"] as? [String: Any] {
                                if let count = conversations["totalConversations"] as? Int {
                                    BackupInfoRow(label: "私聊对话", value: "\(count) 个")
                                }
                                if let messageCount = conversations["totalMessages"] as? Int {
                                    BackupInfoRow(label: "私聊消息", value: "\(messageCount) 条")
                                }
                            }
                            
                            // 多人对话（注意字段名是 multiPersonChats）
                            if let multiChat = data["multiPersonChats"] as? [String: Any] {
                                if let count = multiChat["totalSessions"] as? Int {
                                    BackupInfoRow(label: "多人对话", value: "\(count) 个")
                                }
                                if let messageCount = multiChat["totalMessages"] as? Int {
                                    BackupInfoRow(label: "多人消息", value: "\(messageCount) 条")
                                }
                            }
                            
                            // 成就
                            if let achievements = data["achievements"] as? [String: Any] {
                                if let totalCount = achievements["totalCount"] as? Int {
                                    BackupInfoRow(label: "成就总数", value: "\(totalCount) 个")
                                }
                                if let unlockedCount = achievements["unlockedCount"] as? Int {
                                    BackupInfoRow(label: "已解锁成就", value: "\(unlockedCount) 个")
                                }
                                if let pinnedCount = achievements["pinnedCount"] as? Int, pinnedCount > 0 {
                                    BackupInfoRow(label: "固定成就", value: "\(pinnedCount) 个")
                                }
                            }
                            
                            // 点赞记录（likes 是数组，不是字典）
                            if let likes = data["likes"] as? [[String: Any]], !likes.isEmpty {
                                BackupInfoRow(label: "点赞记录", value: "\(likes.count) 条")
                            }
                            
                            // 关注角色
                            if let followed = data["followedCharacters"] as? [String: Any] {
                                if let count = followed["count"] as? Int, count > 0 {
                                    BackupInfoRow(label: "关注角色", value: "\(count) 个")
                                }
                            }
                        }
                        
                        // 次元足迹
                        if let highlights = data["highlights"] as? [String: Any] {
                            Section(header: Text("次元足迹").textCase(nil)) {
                                if let dialogueCount = highlights["dialogueCount"] as? Int {
                                    BackupInfoRow(label: "对话次数", value: "\(dialogueCount) 次")
                                }
                                if let explorationDays = highlights["explorationDays"] as? Int {
                                    BackupInfoRow(label: "探索天数", value: "\(explorationDays) 天")
                                }
                                if let memberDays = highlights["memberDays"] as? Int {
                                    BackupInfoRow(label: "会员天数", value: "\(memberDays) 天")
                                }
                                if let experience = highlights["experience"] as? Int {
                                    BackupInfoRow(label: "当前经验", value: "\(experience) EXP")
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("备份详情")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("完成") {
                    dismiss()
                }
                .foregroundColor(primaryAccentColor)
            )
        }
        .onAppear {
            loadBackupData()
        }
    }
    
    private func loadBackupData() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = iCloudBackupService.shared.loadBackup(from: backup) {
                DispatchQueue.main.async {
                    self.backupData = data
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.loadError = "无法读取备份文件，文件可能已损坏。"
                    self.isLoading = false
                }
            }
        }
    }
}

/// 备份信息行组件
struct BackupInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
                .fontWeight(.medium)
        }
    }
}

