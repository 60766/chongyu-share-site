import SwiftUI

/**
 * 测试全屏水平模态过渡和手势交互
 * 这个视图用于演示和检测新实现的全屏水平模态过渡效果
 */
struct FullscreenHorizontalModalTest: View {
    @State private var showModal = false
    @State private var currentIndex = 0
    @State private var posts = [
        TestPost(id: UUID(), title: "测试帖子1"),
        TestPost(id: UUID(), title: "测试帖子2"),
        TestPost(id: UUID(), title: "测试帖子3")
    ]
    
    var body: some View {
        VStack {
            Text("点击测试全屏水平模态")
                .padding()
                .onTapGesture {
                    showModal = true
                }
            
            Text("当前索引: \(currentIndex)")
        }
        .fullscreenHorizontalModal(
            isPresented: $showModal,
            direction: .fromRight
        ) {
            TestModalContent(
                post: posts[currentIndex],
                onDismiss: {
                    showModal = false
                },
                onNext: {
                    if currentIndex < posts.count - 1 {
                        currentIndex += 1
                    }
                },
                onPrevious: {
                    if currentIndex > 0 {
                        currentIndex -= 1
                    }
                }
            )
        }
    }
}

/**
 * 测试帖子模型
 */
struct TestPost: Identifiable {
    let id: UUID
    let title: String
}

/**
 * 测试模态内容
 */
struct TestModalContent: View {
    let post: TestPost
    let onDismiss: () -> Void
    let onNext: () -> Void
    let onPrevious: () -> Void
    
    @State private var offset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .padding()
                    }
                    
                    Spacer()
                    
                    Text(post.title)
                        .font(.headline)
                    
                    Spacer()
                }
                .padding(.top, 50)
                
                Spacer()
                
                Text("左右滑动切换帖子")
                    .padding()
                
                HStack {
                    Button("上一个") {
                        onPrevious()
                    }
                    .padding()
                    
                    Button("下一个") {
                        onNext()
                    }
                    .padding()
                }
                
                Spacer()
            }
            .offset(x: offset.width)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                    }
                    .onEnded { value in
                        if value.translation.width > 100 {
                            onPrevious()
                        } else if value.translation.width < -100 {
                            onNext()
                        }
                        
                        withAnimation {
                            offset = .zero
                        }
                    }
            )
        }
    }
}

#Preview {
    FullscreenHorizontalModalTest()
} 