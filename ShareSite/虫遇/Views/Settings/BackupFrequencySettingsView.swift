import SwiftUI

/// 备份频率设置视图
struct BackupFrequencySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFrequency: Int
    
    private let frequencyOptions = [
        (days: 1, title: "每天", description: "最频繁，确保数据最新"),
        (days: 3, title: "每3天", description: "默认推荐，平衡安全性和性能"),
        (days: 7, title: "每7天", description: "适合偶尔使用"),
        (days: 14, title: "每14天", description: "节省空间"),
        (days: 30, title: "每月", description: "最省空间")
    ]
    
    init() {
        let currentFrequency = iCloudBackupService.shared.backupFrequencyDays
        _selectedFrequency = State(initialValue: currentFrequency)
    }
    
    var body: some View {
        List {
            ForEach(frequencyOptions, id: \.days) { option in
                Button(action: {
                    selectedFrequency = option.days
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.title)
                                .font(.body)
                                .foregroundColor(.primary)
                            Text(option.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedFrequency == option.days {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("备份频率")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            // 保存设置
            iCloudBackupService.shared.setBackupFrequency(days: selectedFrequency)
        }
    }
}

