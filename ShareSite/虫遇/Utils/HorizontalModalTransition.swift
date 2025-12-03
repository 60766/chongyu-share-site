import SwiftUI

/**
 * 水平滑动模态呈现修饰符
 * 用于替换默认的从下往上的模态呈现方式
 */
struct HorizontalModalTransition<Item: Identifiable & Equatable, ModalContent: View>: ViewModifier {
    let item: Binding<Item?>
    let onDismiss: (() -> Void)?
    let direction: ModalDirection
    let modalContent: (Item) -> ModalContent
    
    enum ModalDirection {
        case fromRight
        case fromLeft
    }
    
    @State private var slideInPosition = CGSize.zero
    @State private var activeItem: Item? = nil
    
    init(item: Binding<Item?>, direction: ModalDirection = .fromRight, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping (Item) -> ModalContent) {
        self.item = item
        self.onDismiss = onDismiss
        self.direction = direction
        self.modalContent = content
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .onChange(of: item.wrappedValue) { oldValue, newValue in
                    if let newItem = newValue, oldValue == nil {
                        // 显示模态视图
                        activeItem = newItem
                        
                        // 初始位置在屏幕外侧
                        let screenWidth = UIScreen.main.bounds.width
                        slideInPosition = CGSize(
                            width: direction == .fromRight ? screenWidth : -screenWidth,
                            height: 0
                        )
                        
                        // 执行滑入动画
                        DispatchQueue.main.async {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                slideInPosition = .zero
                            }
                        }
                    } else if newValue == nil, oldValue != nil {
                        // 执行滑出动画
                        let screenWidth = UIScreen.main.bounds.width
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            slideInPosition = CGSize(
                                width: direction == .fromRight ? screenWidth : -screenWidth,
                                height: 0
                            )
                        }
                        
                        // 动画完成后关闭视图
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            activeItem = nil
                            onDismiss?()
                        }
                    }
                }
            
            if let activeItem = activeItem {
                self.modalContent(activeItem)
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
    func horizontalModal<Item: Identifiable & Equatable, ModalContent: View>(
        item: Binding<Item?>,
        direction: HorizontalModalTransition<Item, ModalContent>.ModalDirection = .fromRight,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> ModalContent
    ) -> some View {
        modifier(HorizontalModalTransition(item: item, direction: direction, onDismiss: onDismiss, content: content))
    }
} 