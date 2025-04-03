import SwiftUI

/**
 * 全屏水平滑动模态呈现修饰符
 * 专门优化用于详情页的模态呈现，解决手势冲突问题
 */
struct FullscreenHorizontalModalTransition<ModalContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    let modalContent: () -> ModalContent
    let direction: ModalDirection
    
    enum ModalDirection {
        case fromRight
        case fromLeft
    }
    
    @State private var internalIsPresented = false
    @State private var slideInPosition = CGSize.zero
    
    init(isPresented: Binding<Bool>, direction: ModalDirection = .fromRight, onDismiss: (() -> Void)? = nil, @ViewBuilder modalContent: @escaping () -> ModalContent) {
        self._isPresented = isPresented
        self.onDismiss = onDismiss
        self.modalContent = modalContent
        self.direction = direction
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
                // 使用ZStack和ignoresSafeArea确保内容能够全屏显示
                ZStack {
                    // 添加一个全屏背景来捕获并阻止可能传递到下层视图的手势
                    Color.black.opacity(0.001)
                        .edgesIgnoringSafeArea(.all)
                        .contentShape(Rectangle())
                        .gesture(
                            // 消费所有可能传递到下层TabView的手势
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in }
                        )
                    
                    self.modalContent()
                }
                .edgesIgnoringSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(x: slideInPosition.width, y: 0)
                .transition(.identity)
                .zIndex(999)
                // 禁用水平模态的边缘右滑关闭手势，完全依靠内部FullscreenPostDetailView的手势
                // 这样可以解决手势冲突问题
            }
        }
    }
}

// 扩展 View 以添加自定义模态呈现修饰符
extension View {
    func fullscreenHorizontalModal<ModalContent: View>(
        isPresented: Binding<Bool>,
        direction: FullscreenHorizontalModalTransition<ModalContent>.ModalDirection = .fromRight,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> ModalContent
    ) -> some View {
        modifier(FullscreenHorizontalModalTransition(
            isPresented: isPresented,
            direction: direction,
            onDismiss: onDismiss,
            modalContent: content
        ))
    }
} 