import SwiftUI

/**
 * 时空效果中心测试视图
 * 用于测试时空效果在屏幕中心的展示
 */
public struct TimeSpaceEffectCenterTestView: View {
    @State private var isShowingEffect = false
    @State private var activationCount = 0
    @State private var blackHoleCenterPosition: CGPoint? = nil
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color.black.edgesIgnoringSafeArea(.all)
                
                // 简单的星空背景
                ForEach(0..<100, id: \.self) { _ in
                    Circle()
                        .fill(Color.white)
                        .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                            y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                        )
                        .opacity(Double.random(in: 0.3...1.0))
                }
                
                // 简化的黑洞表示
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [Color.black, Color.black.opacity(0.5)]),
                                center: .center,
                                startRadius: 10,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    // 黑洞中心 - 触发按钮
                    Button(action: {
                        // 触发触觉反馈
                        let impactMed = UIImpactFeedbackGenerator(style: .medium)
                        impactMed.impactOccurred()
                        
                        // 触发特效
                        activationCount += 1
                        
                        // 计算黑洞中心位置 - 就是屏幕中心位置
                        let centerX = geometry.size.width / 2
                        let centerY = geometry.size.height / 2
                        blackHoleCenterPosition = CGPoint(x: centerX, y: centerY)
                        
                        withAnimation {
                            isShowingEffect = true
                        }
                    }) {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.7), Color.white.opacity(0.3)]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 20
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                            .shadow(color: Color.white.opacity(0.5), radius: 5)
                    }
                }
                
                // 计数文本
                VStack {
                    Spacer()
                    Text("激活次数: \(activationCount)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 40)
                }
                
                // 时空效果 - 使用新的TimeSpaceEffectView
                if isShowingEffect, let centerPosition = blackHoleCenterPosition {
                    TimeSpaceEffectView(isActive: $isShowingEffect, centerPosition: centerPosition) {
                        print("特效播放完成")
                    }
                    .edgesIgnoringSafeArea(.all)
                    .zIndex(100)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                let centerX = geometry.size.width / 2
                let centerY = geometry.size.height / 2
                blackHoleCenterPosition = CGPoint(x: centerX, y: centerY)
            }
        }
    }
    
    public init() {}
}

// 预览
struct TimeSpaceEffectCenterTestView_Previews: PreviewProvider {
    static var previews: some View {
        TimeSpaceEffectCenterTestView()
    }
} 