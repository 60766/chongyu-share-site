import SwiftUI

/// iCloud 同步信息视图
/// 帮助用户了解自动同步功能
struct iCloudSyncInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 标题和图标
                    VStack(spacing: 16) {
                        Image(systemName: "icloud.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("iCloud 自动同步")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("您的账号信息已自动同步到 iCloud 钥匙串")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // 功能说明
                    VStack(spacing: 20) {
                        FeatureItem(
                            icon: "key.fill",
                            color: .green,
                            title: "账号令牌同步",
                            description: "您的账号令牌会自动同步到所有登录了相同 Apple ID 的设备"
                        )
                        
                        FeatureItem(
                            icon: "shield.fill",
                            color: .blue,
                            title: "找回码同步",
                            description: "找回码也会通过 iCloud 钥匙串安全同步，无需手动转移"
                        )
                        
                        FeatureItem(
                            icon: "arrow.clockwise",
                            color: .orange,
                            title: "自动恢复",
                            description: "在新设备上登录 iCloud 后，账号信息会自动恢复"
                        )
                        
                        FeatureItem(
                            icon: "lock.fill",
                            color: .purple,
                            title: "安全加密",
                            description: "所有数据都经过端到端加密，只有您可以访问"
                        )
                    }
                    
                    // 使用说明
                    VStack(alignment: .leading, spacing: 12) {
                        Text("使用条件")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            CheckItem(text: "在设备上登录 Apple ID")
                            CheckItem(text: "开启 iCloud 钥匙串同步")
                            CheckItem(text: "确保网络连接正常")
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                    
                    // 设置指导
                    VStack(alignment: .leading, spacing: 12) {
                        Text("如何开启 iCloud 钥匙串")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            StepItem(number: 1, text: "打开「设置」应用")
                            StepItem(number: 2, text: "点击您的姓名")
                            StepItem(number: 3, text: "选择「iCloud」")
                            StepItem(number: 4, text: "开启「钥匙串」")
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                    
                    // 底部按钮
                    VStack(spacing: 12) {
                        Button("前往设置") {
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                        Button("我知道了") {
                            dismiss()
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - 辅助视图组件

struct FeatureItem: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct CheckItem: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct StepItem: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - 预览
struct iCloudSyncInfoView_Previews: PreviewProvider {
    static var previews: some View {
        iCloudSyncInfoView()
    }
} 