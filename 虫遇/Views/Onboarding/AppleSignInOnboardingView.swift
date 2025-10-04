import SwiftUI
import AuthenticationServices

struct AppleSignInOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appleSignInManager = AppleSignInManager.shared
    @State private var isSigningIn = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部装饰
                topDecoration
                
                // 主要内容
                mainContent
                
                // 底部按钮区域
                bottomActions
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "667eea").opacity(0.1),
                        Color(hex: "764ba2").opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationBarHidden(true)
        }
        .onChange(of: appleSignInManager.isSignedIn) { _, isSignedIn in
            if isSignedIn {
                dismiss()
            }
        }
    }
    
    private var topDecoration: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 60)
            
            // 应用图标
            Image(systemName: "applelogo")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.primary)
                .padding(.bottom, 8)
            
            Text("虫遇")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
    
    private var mainContent: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("欢迎使用虫遇")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("为了给您提供更好的服务体验，\n推荐使用 Apple ID 登录")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            // 功能特点
            VStack(spacing: 16) {
                FeatureRow(
                    icon: "shield.fill",
                    title: "隐私保护",
                    description: "Apple 级别的隐私保护"
                )
                
                FeatureRow(
                    icon: "icloud.fill",
                    title: "跨设备同步",
                    description: "数据在您的设备间安全同步"
                )
                
                FeatureRow(
                    icon: "creditcard.fill",
                    title: "便捷支付",
                    description: "与内购系统无缝集成"
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    private var bottomActions: some View {
        VStack(spacing: 16) {
            // Apple ID 登录按钮
            if isSigningIn {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("正在登录...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            } else {
                AppleSignInButton(
                    buttonType: .signIn,
                    buttonStyle: .black
                )
                .onTapGesture {
                    isSigningIn = true
                    appleSignInManager.signInWithApple()
                }
                .disabled(isSigningIn)
            }
            
            // 跳过按钮
            Button("暂时跳过") {
                dismiss()
            }
            .font(.body)
            .foregroundColor(.secondary)
            .padding(.vertical, 8)
            
            // 底部说明文字
            Text("您可以稍后在设置中绑定 Apple ID")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - 预览

struct AppleSignInOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        AppleSignInOnboardingView()
            .preferredColorScheme(.light)
        
        AppleSignInOnboardingView()
            .preferredColorScheme(.dark)
    }
} 