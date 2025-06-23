import SwiftUI

struct ContentView: View {
    // 添加长按计时器状态
    @State private var debugTimer: Timer? = nil
    @State private var debugPressStarted = false
    
    var body: some View {
        ZStack {
            // 原有视图保持不变
            // ... 原有代码 ...
            
            // 添加隐藏的调试触发区域
            VStack {
                Spacer()
                HStack {
                    // 左下角隐形调试按钮区域
                    Rectangle()
                        .frame(width: 50, height: 50)
                        .opacity(0.001)
                        .gesture(
                            LongPressGesture(minimumDuration: 5.0)
                                .onEnded { _ in
                                    // 长按5秒后触发调试模式
                                    showDebugWindow()
                                }
                                .simultaneously(with: 
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            if !debugPressStarted {
                                                debugPressStarted = true
                                                // 开始计时
                                                startDebugTimer()
                                            }
                                        }
                                        .onEnded { _ in
                                            // 取消计时
                                            debugTimer?.invalidate()
                                            debugTimer = nil
                                            debugPressStarted = false
                                        }
                                )
                        )
                    Spacer()
                }
            }
        }
    }
    
    // 开始调试计时器
    private func startDebugTimer() {
        debugTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            showDebugWindow()
        }
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