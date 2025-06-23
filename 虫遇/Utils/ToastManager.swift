import SwiftUI
import Combine

/**
 * Toast消息管理器
 * 提供全局Toast消息显示功能
 */
class ToastManager: ObservableObject {
    /// 单例实例
    static let shared = ToastManager()
    
    /// 当前消息
    @Published var currentMessage: String = ""
    
    /// 是否显示Toast
    @Published var isVisible: Bool = false
    
    /// Toast持续时间（秒）
    private let displayDuration: TimeInterval = 2.0
    
    /// 工作队列
    private var workItem: DispatchWorkItem?
    
    /// 私有初始化函数
    private init() {}
    
    /**
     * 显示Toast消息
     * @param message 要显示的消息
     */
    func showToast(message: String) {
        // 取消之前的计时器
        workItem?.cancel()
        
        // 在主线程更新UI
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 更新消息和显示状态
            self.currentMessage = message
            
            // 如果当前可见，先隐藏再显示，创造刷新效果
            if self.isVisible {
                withAnimation {
                    self.isVisible = false
                }
                
                // 100ms后重新显示
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        self.isVisible = true
                    }
                }
            } else {
                // 直接显示
                withAnimation {
                    self.isVisible = true
                }
            }
            
            // 设置自动隐藏
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                withAnimation {
                    self.isVisible = false
                }
            }
            self.workItem = workItem
            
            DispatchQueue.main.asyncAfter(deadline: .now() + self.displayDuration, execute: workItem)
        }
    }
    
    /**
     * 手动隐藏Toast
     */
    func hideToast() {
        workItem?.cancel()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            withAnimation {
                self.isVisible = false
            }
        }
    }
}

/**
 * Toast视图
 * 用于在应用中显示Toast消息
 */
struct ToastView: View {
    @ObservedObject private var toastManager = ToastManager.shared
    
    var body: some View {
        ZStack {
            if toastManager.isVisible {
                VStack {
                    Spacer()
                    
                    Text(toastManager.currentMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                        )
                        .padding(.bottom, 50)
                        .transition(.move(edge: .bottom))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: toastManager.isVisible)
    }
} 