import SwiftUI

/**
 * 时空特效中心测试视图
 * 用于测试时空特效在屏幕中央（黑洞位置）的效果
 */
public struct TimeSpaceEffectCenterTestView: View {
    @State private var showEffect = false
    @State private var effectCount = 0
    @State private var blackHoleCenterPosition: CGPoint? = nil
    
    public var body: some View {
        ZStack {
            // 背景 - 模拟虫洞探索页面的背景
            Color.black.edgesIgnoringSafeArea(.all)
            
            // 简化版黑洞视图 - 仅用于显示位置参考
            ZStack {
                // 黑洞模拟视图
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.15, green: 0.1, blue: 0.25),
                                Color(red: 0.05, green: 0.02, blue: 0.1),
                                Color.black
                            ]),
                            center: .center,
                            startRadius: 1,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .opacity(showEffect ? 0 : 1) // 特效出现时隐藏黑洞
                
                // 在黑洞中心位置添加"随机漫游"标签，模拟实际情况
                Text("随机漫游")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .opacity(showEffect ? 0 : 0.8)
                
                // 位置获取器 - 用于精确定位黑洞中心点
                GeometryReader { geometry in
                    // 获取整个ZStack在全局坐标系中的位置
                    let blackHoleFrame = geometry.frame(in: .global)
                    
                    // 在黑洞中心放置一个透明的标记点
                    Color.clear
                        .frame(width: 1, height: 1)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .onAppear {
                            // 计算黑洞正中心位置
                            let centerX = blackHoleFrame.midX
                            let centerY = blackHoleFrame.midY
                            
                            // 更新黑洞中心位置状态
                            blackHoleCenterPosition = CGPoint(x: centerX, y: centerY)
                            
                            // 打印位置信息，用于调试
                            print("测试视图 - 黑洞中心位置: \(CGPoint(x: centerX, y: centerY))")
                        }
                }
                .allowsHitTesting(false) // 不干扰用户交互
            }
            .frame(width: 200, height: 200)
            .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
            
            // 调试标记点 - 可视化黑洞中心位置
            if let centerPosition = blackHoleCenterPosition {
                // 原始中心位置 - 红色
                Circle()
                    .fill(Color.red)
                    .frame(width: 4, height: 4)
                    .position(centerPosition)
                    .opacity(showEffect ? 0 : 0.7)
                
                // 向上偏移40像素的位置 - 绿色
                Circle()
                    .fill(Color.green)
                    .frame(width: 4, height: 4)
                    .position(CGPoint(x: centerPosition.x, y: centerPosition.y - 40))
                    .opacity(showEffect ? 0 : 0.7)
                
                // 显示偏移信息
                Text("原始中心 → 偏移中心")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
                    .position(CGPoint(x: centerPosition.x + 50, y: centerPosition.y - 20))
                    .opacity(showEffect ? 0 : 0.7)
            }
            
            // 星星背景
            ForEach(0..<50, id: \.self) { _ in
                Circle()
                    .fill(Color.white)
                    .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .opacity(Double.random(in: 0.4...1.0))
            }
            
            // 控制视图
            VStack {
                Spacer()
                
                Text("特效中心测试")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                
                Text("触发次数: \(effectCount)")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 2)
                
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
                    Text("开始特效")
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
                .padding(.vertical, 40)
            }
            .padding(.bottom, 20)
            
            // 显示时空特效
            if showEffect {
                if let centerPosition = blackHoleCenterPosition {
                    // 使用黑洞中心位置作为特效中心
                    // 注意：特效视图内部已经实现向上偏移40像素
                    TimeSpaceEffectView(isActive: $showEffect, centerPosition: centerPosition) {
                        // 特效完成后的回调
                        print("特效完成")
                    }
                    .edgesIgnoringSafeArea(.all)
                    // 确保特效位于最顶层且全屏显示
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(100) // 确保在最上层显示
                } else {
                    // 默认使用屏幕中心
                    TimeSpaceEffectView(isActive: $showEffect) {
                        // 特效完成后的回调
                        print("特效完成")
                    }
                    .edgesIgnoringSafeArea(.all)
                    // 确保特效位于最顶层且全屏显示
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(100) // 确保在最上层显示
                }
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