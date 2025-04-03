import SwiftUI

/**
 * 基于布尔值的水平滑动模态呈现修饰符
 * 用于替换默认的从下往上的模态呈现方式，实现更自然的横向导航体验
 */
struct HorizontalModalBoolTransition<ContentView: View>: ViewModifier {
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    let direction: ModalDirection
    let modalContent: () -> ContentView
    
    // 滑动方向枚举
    enum ModalDirection {
        case fromRight
        case fromLeft
    }
    
    // 内部状态
    @State private var slideInPosition = CGSize.zero
    @State private var internalIsPresented = false
    
    init(isPresented: Binding<Bool>, direction: ModalDirection = .fromRight, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> ContentView) {
        self._isPresented = isPresented
        self.onDismiss = onDismiss
        self.direction = direction
        self.modalContent = content
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .onChange(of: isPresented) { oldValue, newValue in
                    if newValue && !internalIsPresented {
                        // 根据方向从侧面滑入
                        let screenWidth = UIScreen.main.bounds.width
                        slideInPosition = CGSize(
                            width: direction == .fromRight ? screenWidth : -screenWidth, 
                            height: 0
                        )
                        withAnimation(.linear(duration: 0.01)) {
                            internalIsPresented = true
                        }
                        
                        // 在下一帧执行滑入动画
                        DispatchQueue.main.async {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                slideInPosition = .zero
                            }
                        }
                    } else if !newValue && internalIsPresented {
                        // 向侧面滑出
                        let screenWidth = UIScreen.main.bounds.width
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            slideInPosition = CGSize(
                                width: direction == .fromRight ? screenWidth : -screenWidth, 
                                height: 0
                            )
                        }
                        
                        // 动画完成后关闭
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            internalIsPresented = false
                            onDismiss?()
                        }
                    }
                }
            
            if internalIsPresented {
                self.modalContent()
                    .edgesIgnoringSafeArea(.all)
                    .offset(x: slideInPosition.width, y: 0)
                    .transition(.identity)
                    .zIndex(999)
            }
        }
    }
}

// 扩展 View 以添加自定义模态呈现修饰符
extension View {
    func horizontalModal<ContentView: View>(
        isPresented: Binding<Bool>,
        direction: HorizontalModalBoolTransition<ContentView>.ModalDirection = .fromRight,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> ContentView
    ) -> some View {
        modifier(HorizontalModalBoolTransition(isPresented: isPresented, direction: direction, onDismiss: onDismiss, content: content))
    }
} 