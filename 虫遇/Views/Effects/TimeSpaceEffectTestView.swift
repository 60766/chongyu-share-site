import SwiftUI

/**
 * 时空特效测试视图
 * 用于测试时空特效组件
 */
struct TimeSpaceEffectTestView: View {
    @State private var showEffect = false
    @State private var effectCount = 0
    
    var body: some View {
        ZStack {
            // 背景
            Color(.systemBackground).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Text("虫洞捕捉特效测试")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("触发次数: \(effectCount)")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                
                // 触发按钮
                Button(action: {
                    // 触发触觉反馈
                    let feedback = UIImpactFeedbackGenerator(style: .medium)
                    feedback.impactOccurred()
                    
                    // 显示特效
                    showEffect = true
                    
                    // 增加计数
                    effectCount += 1
                }) {
                    Text("启动虫洞捕捉")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 36)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.4, green: 0.2, blue: 0.6),
                                            Color(red: 0.5, green: 0.3, blue: 0.7)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                                )
                        )
                        .shadow(color: Color(red: 0.5, green: 0.3, blue: 0.7).opacity(0.5), radius: 10, x: 0, y: 4)
                }
            }
            
            // 显示时空特效
            if showEffect {
                TimeSpaceEffectView(isActive: $showEffect) {
                    // 特效完成后的回调
                    #if DEBUG
                    print("特效完成")
                    #endif
                }
                .edgesIgnoringSafeArea(.all)
            }
        }
    }
}

// 预览
struct TimeSpaceEffectTestView_Previews: PreviewProvider {
    static var previews: some View {
        TimeSpaceEffectTestView()
    }
} 