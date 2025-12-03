import SwiftUI
import UIKit

/**
 * 调试按钮视图
 * 可以添加到任何SwiftUI视图中，长按触发调试功能
 */
struct DebugButton: View {
    // 长按计时器状态
    @State private var debugTimer: Timer? = nil
    @State private var debugPressStarted = false
    @State private var pressProgress: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 透明背景按钮
            Rectangle()
                .frame(width: 60, height: 60)
                .opacity(0.001)
                .gesture(
                    LongPressGesture(minimumDuration: 3.0)
                        .onEnded { _ in
                            showDebugWindow()
                        }
                        .simultaneously(with: 
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !debugPressStarted {
                                        debugPressStarted = true
                                        startDebugTimer()
                                    }
                                }
                                .onEnded { _ in
                                    cancelDebugTimer()
                                }
                        )
                )
            
            // 仅在测试和开发环境显示的指示器
            #if DEBUG
            Circle()
                .trim(from: 0, to: pressProgress)
                .stroke(Color.blue.opacity(0.5), lineWidth: 3)
                .frame(width: 30, height: 30)
                .rotationEffect(Angle(degrees: -90))
                .opacity(debugPressStarted ? 1.0 : 0.0)
            #endif
        }
    }
    
    // 开始调试计时器
    private func startDebugTimer() {
        // 重置进度
        pressProgress = 0
        
        // 取消之前的计时器
        debugTimer?.invalidate()
        
        // 创建更新进度的计时器
        debugTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            DispatchQueue.main.async {
                pressProgress += 0.033  // 3秒完成
                
                if pressProgress >= 1.0 {
                    showDebugWindow()
                    cancelDebugTimer()
                }
            }
        }
    }
    
    // 取消调试计时器
    private func cancelDebugTimer() {
        debugTimer?.invalidate()
        debugTimer = nil
        debugPressStarted = false
        pressProgress = 0
    }
    
    // 显示调试窗口
    private func showDebugWindow() {
        // 震动反馈
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // 显示调试窗口
        DispatchQueue.main.async {
            DebugHelper.shared.showDebugWindow()
        }
    }
} 