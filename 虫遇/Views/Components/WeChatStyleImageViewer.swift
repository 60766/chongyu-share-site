import SwiftUI
import UIKit
import Photos

/**
 * 微信风格图片查看器
 * 支持平滑转场动画、向下滑动关闭和简洁UI
 */
struct WeChatStyleImageViewer: View {
    // 输入参数
    let images: [String]  // 可以是资源名称或图片ID
    let initialIndex: Int
    @Binding var isPresented: Bool
    
    // 状态变量
    @State private var currentIndex: Int
    @State private var loadedImages: [Int: UIImage] = [:]
    @State private var isLoading: [Int: Bool] = [:]
    @State private var loadingError: [Int: Bool] = [:]
    @State private var showControls: Bool = true
    @State private var dragOffset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var animationProgress: Double = 0.0
    @State private var dismissProgress: Double = 0.0
    @State private var isDismissing: Bool = false
    
    // 触觉反馈生成器
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // 命名空间用于匹配几何效果
    @Namespace private var animation
    
    // 拖动状态枚举
    enum DragState {
        case inactive
        case dragging
        case closing
    }
    
    // 初始化
    init(images: [String], initialIndex: Int = 0, isPresented: Binding<Bool>) {
        self.images = images
        self.initialIndex = initialIndex
        self._currentIndex = State(initialValue: initialIndex)
        self._isPresented = isPresented
        self._animationProgress = State(initialValue: 0.0)
    }
    
    // 设置自定义全屏呈现方式
    static func modalPresentation() -> some ViewModifier {
        return AnyViewModifier(EmptyView())
    }
    
    var body: some View {
        ZStack {
            // 永久黑色背景，不添加动画
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            // 图片查看器
            TabView(selection: $currentIndex) {
                ForEach(0..<images.count, id: \.self) { index in
                    imageView(for: index)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .onChange(of: currentIndex) { oldValue, newValue in
                // 保留必要的图片加载逻辑
                loadImage(at: newValue)
                
                // 预加载前后图片，提高浏览流畅度
                if newValue > 0 {
                    loadImage(at: newValue - 1)
                }
                if newValue < images.count - 1 {
                    loadImage(at: newValue + 1)
                }
                
                // 轻微反馈
                feedbackGenerator.impactOccurred(intensity: 0.3)
            }
            
            // 底部指示器 - 简化条件
            VStack {
                Spacer()
                
                if images.count > 1 {
                    HStack(spacing: 4) {
                        ForEach(0..<min(images.count, 10), id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 5, height: 5)
                                .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)
                    .padding(.bottom, 20)
                    .opacity(scale > 1.0 ? 0 : 1) // 仅在放大时隐藏指示器
                }
            }
            
            // Toast消息
            if showToast {
                VStack {
                    Spacer()
                    Text(toastMessage)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                    Spacer()
                }
                .zIndex(100)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            // 准备触觉反馈
            feedbackGenerator.prepare()
            
            // 加载图片
            loadImage(at: currentIndex)
            
            // 预加载前后图片
            if currentIndex > 0 {
                loadImage(at: currentIndex - 1)
            }
            if currentIndex < images.count - 1 {
                loadImage(at: currentIndex + 1)
            }
        }
    }
    
    // 图片视图构建函数，分离复杂性
    @ViewBuilder
    private func imageView(for index: Int) -> some View {
        GeometryReader { geometry in
            ZStack {
                // 加载指示器 - 使用更微信风格的加载指示器
                if isLoading[index] == true {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        
                        Text("加载中...")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // 错误提示
                if loadingError[index] == true {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                        Text("图片加载失败")
                            .foregroundColor(.white)
                        Button("重试") {
                            loadImage(at: index)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(20)
                    }
                }
                
                // 图片显示 - 简化动画和过渡效果
                if let image = loadedImages[index] {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .scaleEffect(scale)
                        .offset(index == currentIndex ? dragOffset : .zero)
                        // 移除复杂的条件动画
                        .contentShape(Rectangle())
                        .gesture(
                            // 双击缩放手势
                            TapGesture(count: 2).onEnded { _ in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if scale > 1.0 {
                                        scale = 1.0
                                    } else {
                                        scale = 2.5
                                    }
                                    dragOffset = .zero
                                }
                                feedbackGenerator.impactOccurred(intensity: 0.6)
                            }
                        )
                        .simultaneousGesture(
                            // 缩放手势
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    
                                    // 限制最小和最大缩放
                                    let newScale = scale * delta
                                    scale = min(max(newScale, 0.8), 4.0)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    
                                    if scale < 1.0 {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            scale = 1.0
                                        }
                                    }
                                    
                                    if scale > 4.0 {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            scale = 4.0
                                        }
                                    }
                                }
                        )
                        .simultaneousGesture(
                            // 拖动手势 - 简化关闭检测
                            DragGesture()
                                .onChanged { gesture in
                                    if scale > 1.0 {
                                        dragOffset = gesture.translation
                                    } else {
                                        dragOffset = CGSize(
                                            width: gesture.translation.width * 0.5,
                                            height: gesture.translation.height
                                        )
                                        
                                        // 更新关闭进度简化
                                        dismissProgress = min(abs(gesture.translation.height) / CGFloat(300), 1.0) * 0.6
                                    }
                                }
                                .onEnded { gesture in
                                    if scale <= 1.0 && abs(gesture.translation.height) > 100 {
                                        // 直接关闭，不使用动画
                                        isPresented = false
                                    } else if scale <= 1.0 {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            dragOffset = .zero
                                            dismissProgress = 0.0
                                        }
                                    } else {
                                        // 在放大状态下，限制拖动范围
                                        let maxOffsetX = (geometry.size.width * (scale - 1)) / 2
                                        let maxOffsetY = (geometry.size.height * (scale - 1)) / 2
                                        
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            dragOffset = CGSize(
                                                width: max(min(dragOffset.width, maxOffsetX), -maxOffsetX),
                                                height: max(min(dragOffset.height, maxOffsetY), -maxOffsetY)
                                            )
                                        }
                                    }
                                }
                        )
                        // 单击关闭，直接调用isPresented = false
                        .onTapGesture(count: 1) {
                            if scale <= 1.0 {
                                isPresented = false
                            }
                        }
                        .contextMenu {
                            Button(action: {
                                saveCurrentImage()
                            }) {
                                Label("保存图片", systemImage: "square.and.arrow.down")
                            }
                        }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
    }
    
    // 加载图片
    private func loadImage(at index: Int) {
        // 如果图片已加载或正在加载，则跳过
        if loadedImages[index] != nil || isLoading[index] == true {
            return
        }
        
        // 标记为加载中
        isLoading[index] = true
        
        let imageName = images[index]
        
        // 检查是否是用户上传的图片
        if imageName.contains("_image_") {
            // 使用ImageManager加载用户上传的图片
            DispatchQueue.global(qos: .userInitiated).async {
                let loadedImage = ImageManager.shared.getImage(withId: imageName)
                
                // 在主线程更新UI
                DispatchQueue.main.async {
                    if let image = loadedImage {
                        self.loadedImages[index] = image
                        self.isLoading[index] = false
                    } else {
                        self.loadingError[index] = true
                        self.isLoading[index] = false
                        
                        // 尝试使用占位图
                        if let placeholderImage = UIImage(systemName: "photo") {
                            self.loadedImages[index] = placeholderImage
                            self.loadingError[index] = false
                        }
                    }
                }
            }
        } else {
            // 加载内置图片资源
            if let image = UIImage(named: imageName) {
                loadedImages[index] = image
                isLoading[index] = false
            } else {
                loadingError[index] = true
                isLoading[index] = false
                
                // 尝试使用占位图
                if let placeholderImage = UIImage(systemName: "photo") {
                    self.loadedImages[index] = placeholderImage
                    self.loadingError[index] = false
                }
            }
        }
    }
    
    // 保存当前图片到相册
    private func saveCurrentImage() {
        guard let image = loadedImages[currentIndex] else {
            showToastMessage("无法保存图片")
            return
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                showToastMessage("已保存到相册")
                
                // 微信风格的保存成功触觉反馈
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } else {
                showToastMessage("没有权限保存图片")
            }
        }
    }
    
    // 显示Toast消息
    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
        
        // 1.5秒后自动隐藏，更接近微信的体验
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showToast = false
            }
        }
    }
}

// 扩展CGSize以检查是否为零
extension CGSize {
    var isZero: Bool {
        return width == 0 && height == 0
    }
}

// 修饰符扩展，方便在任何视图中使用
extension View {
    func wechatStyleImageViewer(
        isPresented: Binding<Bool>,
        images: [String],
        initialIndex: Int = 0
    ) -> some View {
        self.fullScreenCover(
            isPresented: isPresented,
            content: {
                WeChatStyleImageViewer(
                    images: images,
                    initialIndex: initialIndex,
                    isPresented: isPresented
                )
                .background(Color.black)
                .edgesIgnoringSafeArea(.all)
                // 移除状态栏隐藏修饰符，避免状态栏变化造成的闪烁
            }
        )
    }
}

// 空视图修饰符，用于类型擦除
struct AnyViewModifier: ViewModifier {
    private let view: AnyView
    
    init<V: View>(_ view: V) {
        self.view = AnyView(view)
    }
    
    func body(content: Content) -> some View {
        content
    }
} 