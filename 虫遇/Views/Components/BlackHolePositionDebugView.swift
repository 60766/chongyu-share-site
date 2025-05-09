import SwiftUI

/**
 * 黑洞位置调试视图
 * 用于开发过程中显示黑洞中心按钮的准确位置
 * 仅在DEBUG模式下可用
 */
struct BlackHolePositionDebugView: View {
    @State private var centerPosition: CGPoint?
    @State private var showIndicator = false
    
    var body: some View {
        ZStack {
            // 全屏透明层，用于接收点击事件
            Color.clear
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    withAnimation {
                        showIndicator.toggle()
                    }
                }
            
            if showIndicator, let position = centerPosition {
                // 位置指示器 - 十字准线和坐标标签
                ZStack {
                    // 垂直线
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 1, height: 40)
                    
                    // 水平线
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 40, height: 1)
                    
                    // 中心点
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    
                    // 坐标标签
                    Text("(\(Int(position.x)), \(Int(position.y)))")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                        .padding(4)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(4)
                        .offset(y: 25)
                }
                .position(position)
                .transition(.opacity)
            }
        }
        .onAppear {
            setupObserver()
        }
        .onDisappear {
            removeObserver()
        }
    }
    
    private func setupObserver() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("BlackHoleCenterPositionUpdated"),
            object: nil,
            queue: .main
        ) { notification in
            if let position = notification.object as? CGPoint {
                self.centerPosition = position
            }
        }
    }
    
    private func removeObserver() {
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name("BlackHoleCenterPositionUpdated"),
            object: nil
        )
    }
}

#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        BlackHolePositionDebugView()
    }
} 