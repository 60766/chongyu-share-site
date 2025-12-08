import SwiftUI

/**
 * 水平模态转场测试视图
 * 用于测试和演示水平滑动模式的效果
 */
struct HorizontalModalTestView: View {
    @State private var showModal = false
    @State private var selectedItem: TestItem? = nil
    
    struct TestItem: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let color: Color
        
        static func == (lhs: TestItem, rhs: TestItem) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    let testItems = [
        TestItem(title: "红色视图", color: .red),
        TestItem(title: "蓝色视图", color: .blue),
        TestItem(title: "绿色视图", color: .green)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("水平模态转场测试")
                .font(.title)
                .fontWeight(.bold)
            
            // 使用布尔值绑定的模态视图
            Button("显示基于布尔值的模态视图") {
                showModal = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            // 使用项目绑定的模态视图
            ForEach(testItems) { item in
                Button(item.title) {
                    selectedItem = item
                }
                .padding()
                .background(item.color.opacity(0.3))
                .foregroundColor(item.color)
                .cornerRadius(10)
            }
            
            Text("提示：在模态视图中，向右滑动可以关闭视图")
                .font(.footnote)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        // 基于布尔值的模态视图
        .horizontalModal(
            isPresented: $showModal,
            direction: .fromRight,
            onDismiss: {
                #if DEBUG
                debugLog("模态视图已关闭")
                #endif
            }
        ) {
            ModalContentView(
                title: "布尔值模态",
                color: .purple,
                onDismiss: {
                    showModal = false
                }
            )
        }
        // 基于项目的模态视图
        .horizontalModal(
            item: $selectedItem,
            direction: .fromRight,
            onDismiss: {
                #if DEBUG
                debugLog("项目模态视图已关闭")
                #endif
            }
        ) { item in
            ModalContentView(
                title: item.title,
                color: item.color,
                onDismiss: {
                    selectedItem = nil
                }
            )
        }
    }
}

/**
 * 模态内容视图
 */
struct ModalContentView: View {
    let title: String
    let color: Color
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // 背景
            color.opacity(0.2)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // 标题
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("这是一个水平滑动模态视图演示")
                    .font(.headline)
                
                Text("向右滑动或点击下方按钮关闭")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // 关闭按钮
                Button("关闭") {
                    onDismiss()
                }
                .padding()
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Spacer()
            }
            .padding(.top, 60)
            .padding(.horizontal, 20)
        }
        // 添加右滑关闭手势
        .gesture(
            DragGesture()
                .onEnded { value in
                    // 如果右滑足够距离，关闭模态视图
                    if value.translation.width > 100 {
                        onDismiss()
                    }
                }
        )
    }
}

/**
 * 预览
 */
#Preview {
    HorizontalModalTestView()
} 