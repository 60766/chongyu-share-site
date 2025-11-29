import SwiftUI
import Combine
import UIKit

// 添加位置偏好键
struct PublishImagePosition: Equatable {
    let id: Int
    let frame: CGRect
}

struct PublishImagePositionPreferenceKey: PreferenceKey {
    static var defaultValue: [PublishImagePosition] = []
    
    static func reduce(value: inout [PublishImagePosition], nextValue: () -> [PublishImagePosition]) {
        value.append(contentsOf: nextValue())
    }
}

/**
 * 内容发布面板视图
 * 用于发布内容、选择互动角色
 */
struct PublishPanelView: View {
    /// 面板可见性状态
    @Binding var isVisible: Bool
    /// 内容文本
    @State private var contentText: String = ""
    /// 选中的角色
    @State private var selectedCharacters: [CharacterModel] = []
    /// 选中的时代
    @State private var selectedEra: String = "现代"
    /// 是否显示角色选择器
    @State private var showingCharacterSelector = false
    /// 是否显示发布预览
    @State private var showingPublishPreview = false
    /// 发布模式：交流（已简化为只有一种模式）
    @State private var publishMode: PublishMode = .communication
    /// 是否显示键盘 - 仅作为状态标记，不触发UI重排
    @State private var keyboardVisible = false
    /// 键盘高度 - 仅记录高度，不用于动态调整UI
    @State private var keyboardHeight: CGFloat = 0
    /// 角色回复概率设置
    @State private var characterProbabilities: [Double] = []
    /// 是否显示概率设置区域
    @State private var showProbabilitySettings: Bool = false
    /// 选中的图片
    @State private var selectedImages: [UIImage] = []
    /// 是否显示图片选择器
    @State private var showingImagePicker: Bool = false
    /// 是否显示图片全屏预览
    @State private var showingFullScreenImage: Bool = false
    /// 当前预览的图片索引
    @State private var previewingImageIndex: Int = 0
    /// 是否显示发布成功提示
    @State private var isShowingSuccessToast: Bool = false
    /// 潜在回复的角色列表(用于成功提示)
    @State private var potentialRespondingCharacters: [CharacterModel] = []
    /// 是否正在发布中（防止重复发布）
    @State private var isPublishing: Bool = false
    /// 文本编辑器焦点状态
    @FocusState private var isTextEditorFocused: Bool
    
    // Combine相关
    @State private var cancellables = Set<AnyCancellable>()
    
    // 拖拽相关状态
    @State private var isDragging: Bool = false
    @State private var draggedIndex: Int? = nil
    @State private var currentDropIndex: Int? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var imagePositions: [Int: CGRect] = [:] // 存储每个图片的实际位置
    @State private var needsPositionRefresh: Bool = false // 标记是否需要刷新位置
    @State private var showDragHint: Bool = false // 显示拖拽提示
    @State private var dragHintOpacity: Double = 0 // 拖拽提示透明度
    
    // 时代选项
    private let eras = ["现代", "古代", "中世纪", "文艺复兴", "启蒙运动", "未来"]
    

    
    // 虫洞能量指示器
    private var energyIndicatorView: some View {
        WormholeEnergyIndicator(
            contentText: contentText,
            characters: selectedCharacters,
            isAnimating: true // 在发布面板中显示动画
        )
    }
    
    var body: some View {
        ZStack {
            // 背景蒙版 - 现代化渐变设计
            if isVisible {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.25),
                        Color.purple.opacity(0.15)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // 点击背景区域时隐藏键盘并关闭发布面板，但不重置状态
                    hideKeyboard()
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        isVisible = false
                    }
                    // 移除重置面板状态的代码，保留用户输入的内容
                }
                .transition(.opacity)
            }
            
            // 主面板
            VStack(spacing: 0) {
                Spacer()
                
                // 面板内容 - 应用键盘适配
                VStack(spacing: 0) {
                    // 顶部拖拽条 - 现代化设计
                    Capsule()
                        .frame(width: 36, height: 5)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.3),
                                    Color.gray.opacity(0.2)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 1, y: 0.5)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    
                    // 内容输入区域
                    contentInputArea
                    
                    // 角色回复概率设置区域
                    if !selectedCharacters.isEmpty && showProbabilitySettings {
                        characterResponseProbabilityView
                            .padding(.top, 8)
                    }
                    
                    // 底部工具栏 - 上移适当位置
                    bottomToolbar
                        .padding(.bottom, 8) // 增加底部边距，防止按钮太靠近屏幕边缘
                }
                .padding(.horizontal, 12)
                .background(
                    ZStack {
                        // 主背景渐变
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white,
                                Color(red: 0.98, green: 0.98, blue: 1.0),
                                Color(red: 0.95, green: 0.97, blue: 1.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        // 顶部光晕效果
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.08),
                                Color.purple.opacity(0.06),
                                Color.clear
                            ]),
                            center: .topTrailing,
                            startRadius: 0,
                            endRadius: 200
                        )
                        
                        // 底部微妙光晕
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.indigo.opacity(0.04),
                                Color.clear
                            ]),
                            center: .bottomLeading,
                            startRadius: 0,
                            endRadius: 150
                        )
                    }
                    .appCornerRadius(28, corners: [.topLeft, .topRight])
                    .shadow(color: Color.black.opacity(0.08), radius: 20, y: -8)
                    .shadow(color: Color.blue.opacity(0.1), radius: 5, y: -2)
                )
                .keyboardAdaptive(dismissOnTap: false) // 将键盘适配应用到面板内容上
                .offset(y: isVisible ? 0 : UIScreen.main.bounds.height)
                .scaleEffect(isVisible ? 1.0 : 0.95)
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.75, blendDuration: 0), value: isVisible)
                // 简化键盘适配，只观察键盘高度变化，不自动调整视图
                .onReceive(Publishers.keyboardHeight) { height in
                    // 不使用动画改变状态值，避免引起整个视图的动画
                    withAnimation(nil) {
                        keyboardVisible = height > 0
                        keyboardHeight = height
                    }
                    
                    // 键盘弹出时，确保输入框可见
                    if height > 0 && isVisible {
                        // 使用轻微触感反馈提示键盘已显示
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        // 恢复自动聚焦逻辑
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                // 多次尝试聚焦，提高成功率
                activateTextInputWithMultipleAttempts()
            } else {
                // 面板关闭时取消焦点
                isTextEditorFocused = false
            }
        }
        .sheet(isPresented: $showingCharacterSelector) {
            CharacterSelectorView(selectedCharacters: $selectedCharacters)
                .onDisappear {
                    // 更新角色概率
                    updateCharacterProbabilities()
                }
                .presentationDetents([.fraction(0.75)]) // 将高度限制为屏幕的75%
                .presentationDragIndicator(.visible) // 显示拖动指示器
                .presentationBackground(Material.regularMaterial) // 使用磨砂背景
                .presentationCornerRadius(25) // 设置圆角
        }
        .sheet(isPresented: $showingImagePicker) {
            PHImagePicker(selectedImages: $selectedImages, completion: { newImages in
                // 添加图片时的触感反馈
                if !newImages.isEmpty {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            }, maxSelectionCount: 9)
        }
        
        // 全屏图片预览
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            ImageFullScreenViewer(
                images: selectedImages,
                initialIndex: previewingImageIndex,
                isPresented: $showingFullScreenImage
            )
        }
        
        // 发布成功提示 - 移到外部ZStack以确保面板关闭后仍然可见
        .overlay(
            ZStack {
                if isShowingSuccessToast {
                    // 移除半透明背景蒙版，只保留卡片
                        successToastView
                        .transition(.identity) // 完全移除所有过渡动画，极速显示和隐藏
                        .onTapGesture {
                            // 完全移除动画，立即关闭
                            isShowingSuccessToast = false
                        }
                }
            }
            // 完全移除所有动画，极速响应
        )
    }
    
    // 内容输入区域
    private var contentInputArea: some View {
        VStack(spacing: 12) {
            // 输入区域 - 现代化设计
            VStack {
                contentEditorView
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.primaryColor.opacity(0.2),
                                        Color.blue.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                    .shadow(color: Color.primaryColor.opacity(0.1), radius: 3, x: 0, y: 1)
            }
            .frame(height: UIScreen.main.bounds.height * 0.2)
            
            // 功能按钮区 - 极简布局
            HStack(spacing: 10) {
                // 图片选择按钮 - 现代化设计
                Button(action: { 
                    showingImagePicker = true 
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: selectedImages.isEmpty ? "photo" : "photo.fill")
                            .font(.system(size: 14, weight: .medium))
                        
                        if !selectedImages.isEmpty {
                            Text("\(selectedImages.count)")
                                .font(.system(size: 13, weight: .medium))
                        } else {
                            Text("图片")
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            Capsule()
                                .fill(Color.blue.opacity(selectedImages.isEmpty ? 0.06 : 0.1))
                            
                            Capsule()
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        }
                    )
                    .foregroundColor(Color.blue.opacity(0.85))
                    .shadow(color: Color.blue.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(EnhancedBouncyButtonStyle())
                
                Spacer()
                
                // 时代选择按钮 - 现代化设计
                Menu {
                    ForEach(eras, id: \.self) { era in
                        Button(era) {
                            selectedEra = era
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text(selectedEra)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            Capsule()
                                .fill(Color.primaryColor.opacity(0.06))
                            
                            Capsule()
                                .stroke(Color.primaryColor.opacity(0.2), lineWidth: 1)
                        }
                    )
                    .foregroundColor(Color.primaryColor.opacity(0.85))
                    .shadow(color: Color.primaryColor.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
            
            // 图片预览区域
            if !selectedImages.isEmpty {
                imagePreviewArea
            }
            
            energyIndicatorView
                .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedImages.count)
    }
    
    // 内容编辑器视图
    private var contentEditorView: some View {
        EnhancedTextDisplayView(
            text: $contentText,
            placeholder: "写下你想和历史人物交流的内容...",
            minHeight: UIScreen.main.bounds.height * 0.15,
            maxHeight: UIScreen.main.bounds.height * 0.25,
            cornerRadius: 16,
            borderColor: Color.primaryColor,
            backgroundColor: .white,
            showDebugInfo: false
        )
    }
    
    // 图片预览区域
    private var imagePreviewArea: some View {
                VStack(alignment: .leading, spacing: 4) {
                    // 图片预览滚动区 - 极简设计
            ZStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(0..<selectedImages.count, id: \.self) { index in
                            imagePreviewItem(index: index)
                        }
                    }
                    .padding(.vertical, 1)
                }
                .coordinateSpace(name: "dragContainer")
                
                // 拖拽中的图片 - 使用ZStack覆盖
                if isDragging, let draggedIndex = draggedIndex, draggedIndex < selectedImages.count {
                    draggedImageView(index: draggedIndex)
                }
            }
            .frame(height: 65) // 固定高度，防止拖拽时布局变化
            
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .transition(
            AnyTransition.asymmetric(
                insertion: AnyTransition.scale(scale: 0.95, anchor: .center)
                    .combined(with: AnyTransition.opacity),
                removal: AnyTransition.scale(scale: 0.95, anchor: .center)
                    .combined(with: AnyTransition.opacity)
            )
        )
        .onPreferenceChange(PublishImagePositionPreferenceKey.self) { positions in
            // 使用Task避免在视图更新期间修改状态
            Task { @MainActor in
                // 更新所有图片位置
                for position in positions {
                    imagePositions[position.id] = position.frame
                }
                
                // 检查是否所有图片都有位置信息
                var allPositionsCollected = true
                for index in 0..<selectedImages.count {
                    if imagePositions[index] == nil {
                        allPositionsCollected = false
                        break
                    }
                }
                
                if !allPositionsCollected && !needsPositionRefresh {
                    // 如果有缺失的位置，标记需要刷新
                    needsPositionRefresh = true
                }
            }
        }
        .onChange(of: needsPositionRefresh) { _, newValue in
            if newValue {
                // 当标记为需要刷新位置时，使用Task执行刷新
                Task { @MainActor in
                    // 延迟一点时间确保UI已更新
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                    refreshImagePositions()
                }
            }
        }
    }
    
    // 单个图片预览项
    private func imagePreviewItem(index: Int) -> some View {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: selectedImages[index])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 55, height: 55)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    // 拖拽激活时显示的高亮效果
                    ZStack {
                        if isDragging && currentDropIndex == index && draggedIndex != index {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.primaryColor, lineWidth: 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.primaryColor.opacity(0.15))
                                )
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: currentDropIndex)
                )
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: PublishImagePositionPreferenceKey.self, value: [PublishImagePosition(id: index, frame: geometry.frame(in: .named("dragContainer")))])
                    }
                )
                .contentShape(Rectangle())
                .opacity(isDragging && index == draggedIndex ? 0.0 : 1.0) // 拖动时原图透明
                                        .onTapGesture {
                                            previewingImageIndex = index
                                            showingFullScreenImage = true
                                        }
                .onLongPressGesture(minimumDuration: 1.0) {
                    // 长按手势结束时的动作
                    // 为空，因为我们使用onChanged来处理状态变化
                } onPressingChanged: { isPressing in
                    if isPressing {
                        // 长按开始 - 使用Task避免在视图更新期间修改状态
                        Task { @MainActor in
                            self.isDragging = true
                            self.draggedIndex = index
                            
                            // 触觉反馈
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        }
                    }
                }
                                    
                                    // 极简删除按钮
                                    Button(action: {
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                        
                                        _ = withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                            selectedImages.remove(at: index)
                                        }
                                    }) {
                                        Circle()
                                            .fill(Color.black.opacity(0.5))
                                            .frame(width: 16, height: 16)
                                            .overlay(
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundColor(.white)
                                            )
                                    }
                                    .padding(2)
            .opacity(isDragging && index == draggedIndex ? 0.0 : 1.0) // 拖动时隐藏删除按钮
        }
        .id("image-\(index)-\(selectedImages.count)") // 确保在图片数量变化时重新创建视图
    }
    
    // 拖拽中的图片视图
    private func draggedImageView(index: Int) -> some View {
        Image(uiImage: selectedImages[index])
            .resizable()
            .scaledToFill()
            .frame(width: 55, height: 55)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primaryColor, lineWidth: 2)
            )
            .position(
                x: (imagePositions[index]?.midX ?? 0) + dragOffset.width,
                y: (imagePositions[index]?.midY ?? 0) + dragOffset.height
            )
            .gesture(
                DragGesture(minimumDistance: 5, coordinateSpace: .named("dragContainer"))
                    .onChanged { value in
                        // 更新拖拽偏移 - 使用Task避免在视图更新期间修改状态
                        Task { @MainActor in
                            self.dragOffset = value.translation
                            
                            // 使用拖拽位置检测目标
                            findDropTarget(dragPosition: value.location)
                        }
                    }
                    .onEnded { value in
                        // 执行交换
                        performSwap()
                        
                        // 重置拖拽状态 - 使用Task避免在视图更新期间修改状态
                        Task { @MainActor in
                            withAnimation(.spring()) {
                                self.dragOffset = .zero
                                isDragging = false
                                draggedIndex = nil
                                currentDropIndex = nil
                            }
                        }
                    }
            )
            .zIndex(100) // 确保在最上层
    }
    
    // 强制激活文本输入框
    private func forceActivateTextInput() {
        isTextEditorFocused = true
        
        // 使用轻微触感反馈提示用户输入框已激活
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // 尝试使用系统级方法激活第一响应者
        UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // 底部工具栏 - 优化设计
    private var bottomToolbar: some View {
        HStack {
            // 角色选择按钮 - 现代化设计
            Button(action: {
                showingCharacterSelector = true
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: selectedCharacters.isEmpty ? "person.fill" : "person.2.fill")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(selectedCharacters.isEmpty ? "角色" : "角色")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.primaryColor,
                            Color.primaryColor.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    ZStack {
                        Capsule()
                            .fill(Color.primaryColor.opacity(0.08))
                        
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.primaryColor.opacity(0.3),
                                        Color.primaryColor.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .shadow(color: Color.primaryColor.opacity(0.15), radius: 3, x: 0, y: 1)
                .contentShape(Rectangle())
            }
            .buttonStyle(EnhancedBouncyButtonStyle())
            
            // 选中角色数量
            if !selectedCharacters.isEmpty {
                Text("\(selectedCharacters.count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(Color.primaryColor)
                    .clipShape(Circle())
                    .offset(x: -5)
            }
            
            Spacer()
            
            // 发布按钮 - 现代化设计
            Button(action: handlePublishButtonTapped) {
                HStack(spacing: 8) {
                    Text(isPublishing ? "发布中..." : "发布")
                        .font(.system(size: 17, weight: .semibold))
                    
                    if isPublishing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else if hasValidContent {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .offset(x: -1, y: -1)
                            .rotationEffect(.degrees(15))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        // 主背景渐变
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: hasValidContent ? [
                                        Color.primaryColor,
                                        Color.primaryColor.opacity(0.8)
                                    ] : [
                                        Color.gray.opacity(0.3),
                                        Color.gray.opacity(0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // 光晕效果（仅在可用时显示）
                        if hasValidContent {
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        }
                    }
                )
                .foregroundColor(.white)
                .shadow(color: hasValidContent ? Color.primaryColor.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 2)
                .shadow(color: hasValidContent ? Color.primaryColor.opacity(0.2) : Color.clear, radius: 2, x: 0, y: 1)
            }
            .disabled(!hasValidContent || isPublishing)
            .buttonStyle(EnhancedSpringyButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .padding(.bottom, 4) // 减小底部边距，提高位置
    }
    
    // 发布内容判断 - 文本必须不为空，图片可选
    private var hasValidContent: Bool {
        !contentText.isEmpty
    }
    
    // 处理发布按钮点击
    private func handlePublishButtonTapped() {
        // 触感反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        guard hasValidContent else { 
            return 
        }
        guard !isPublishing else { 
            return 
        }
        
        // 🔧 修复：在发布前保存内容，避免被resetPanelState清空
        let contentToPublish = contentText
        let imagesToPublish = selectedImages
        let eraToPublish = selectedEra
        let charactersToPublish = selectedCharacters
        let characterProbabilitiesToPublish = getProbabilityDict()
        let publishModeToPublish = publishMode
        
        // ⚡️ 关键优化：立即清空图片数组，释放内存
        // 图片已经被复制到imagesToPublish，可以安全清空
        selectedImages = []
        
        // 立即关闭发布面板并收起键盘，给用户即时反馈
        withAnimation(.easeOut(duration: 0.05)) {
            isVisible = false
        }
        
        // 确保键盘也一起收起
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // 立即显示成功提示，与面板关闭同时进行
        showSuccessToastImmediately()
        
        // 🔧 优化：调整延迟时间，平衡速度和流畅性，避免卡顿
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            // 异步处理所有发布逻辑，不阻塞UI
            DispatchQueue.global(qos: .userInitiated).async {
                // 如果没有选择角色，自动添加推荐角色
                if charactersToPublish.isEmpty {
                    self.autoSelectCharacters()
                }
                
                self.publishContent(
                    content: contentToPublish,
                    images: imagesToPublish,
                    era: eraToPublish,
                    characters: charactersToPublish,
                    characterProbabilities: characterProbabilitiesToPublish,
                    publishMode: publishModeToPublish
                )
            }
        }
    }
    
    // 自动选择角色 - 简化版本，直接使用随机选择
    private func autoSelectCharacters() {
        // 直接使用随机选择，避免复杂的推荐算法
        selectedCharacters = selectRandomCharacters()
        
        // 更新角色概率
        updateCharacterProbabilities()
    }
    
    /**
     * 将角色的type和subtype映射到CharacterCategory
     */
    private func mapToCharacterCategory(type: String, subtype: String) -> CharacterCategory {
        switch (type, subtype) {
        case ("historical", "scientist"), ("literary", "scientist"), ("movie", "scientist"), ("anime", "scientist"):
            return .scientist
        case ("historical", "writer"), ("literary", "writer"), ("movie", "writer"), ("anime", "writer"):
            return .writer
        case ("historical", "artist"), ("literary", "artist"), ("movie", "artist"), ("anime", "artist"):
            return .artist
        case ("historical", "philosopher"), ("literary", "philosopher"), ("movie", "philosopher"), ("anime", "philosopher"):
            return .philosopher
        case ("historical", "politician"), ("literary", "politician"), ("movie", "politician"), ("anime", "politician"):
            return .historical
        case ("historical", "military"), ("literary", "military"), ("movie", "military"), ("anime", "military"):
            return .historical
        case ("historical", "explorer"), ("literary", "explorer"), ("movie", "explorer"), ("anime", "explorer"):
            return .historical
        case ("historical", "inventor"), ("literary", "inventor"), ("movie", "inventor"), ("anime", "inventor"):
            return .scientist
        case ("historical", "musician"), ("literary", "musician"), ("movie", "musician"), ("anime", "musician"):
            return .artist
        case ("historical", "athlete"), ("literary", "athlete"), ("movie", "athlete"), ("anime", "athlete"):
            return .historical
        case ("historical", "business"), ("literary", "business"), ("movie", "business"), ("anime", "business"):
            return .historical
        case ("historical", "religious"), ("literary", "religious"), ("movie", "religious"), ("anime", "religious"):
            return .historical
        case ("historical", "mythological"), ("literary", "mythological"), ("movie", "mythological"), ("anime", "mythological"):
            return .mythCharacter
        case ("historical", "fictional"), ("literary", "fictional"), ("movie", "fictional"), ("anime", "fictional"):
            return .fictionCharacter
        default:
            // 根据type进行默认分类
            switch type {
            case "historical":
                return .scientist
            case "literary":
                return .writer
            case "movie":
                return .movieCharacter
            case "anime":
                return .animeCharacter
            case "game":
                return .gameCharacter
            default:
                return .scientist
            }
        }
    }
    
    // 随机选择角色 - 使用完整角色库
    private func selectRandomCharacters() -> [CharacterModel] {
        // 从CharacterDataManager获取所有角色信息，转换为CharacterModel
        let allCharacterInfos = CharacterDataManager.shared.getAllCharactersInfo()
        let allCharacters = allCharacterInfos.map { characterInfo in
            CharacterModel(
                id: characterInfo.id,
                name: characterInfo.name,
                avatar: characterInfo.avatar, // 使用真实的头像名称
                era: characterInfo.era, // 使用真实的时代信息
                profession: characterInfo.primaryField, // 使用真实的职业信息
                bio: "暂无描述", // 暂时使用默认值
                category: mapToCharacterCategory(type: characterInfo.type, subtype: characterInfo.subtype), // 使用映射的分类
                famousQuotes: [], // 暂时使用默认值
                characterID: characterInfo.id
            )
        }
        
        var tempSelectedCharacters: [CharacterModel] = []
        
        // 确保选择来自不同类别的角色
        let categories = CharacterCategory.allCases
        for category in categories {
            if let character = allCharacters.filter({ $0.category == category }).randomElement() {
                tempSelectedCharacters.append(character)
                if tempSelectedCharacters.count >= 3 {
                    break
                }
            }
        }
        
        // 如果还不足3个，继续随机添加
        if tempSelectedCharacters.count < 3 {
            let remainingCount = 3 - tempSelectedCharacters.count
            let remainingCharacters = allCharacters.filter { character in
                !tempSelectedCharacters.contains { $0.id == character.id }
            }
            
            for _ in 0..<min(remainingCount, remainingCharacters.count) {
                if let character = remainingCharacters.randomElement() {
                    tempSelectedCharacters.append(character)
                }
            }
        }
        
        return tempSelectedCharacters
    }
    
    // 发布内容
    private func publishContent(
        content: String,
        images: [UIImage],
        era: String,
        characters: [CharacterModel],
        characterProbabilities: [String: Int],
        publishMode: PublishMode
    ) {
        // 防止重复发布
        guard !isPublishing else {
            return
        }
        
        isPublishing = true
        
        // 面板已经在handlePublishButtonTapped中关闭，这里不需要重复关闭
        
        // 🔧 修复：使用更低的优先级，确保不干扰UI
        DispatchQueue.global(qos: .background).async {
        // 确保概率总和为100%
            self.normalizeCharacterProbabilities()
        
        // 创建要发布的内容数据
        let postData = PostData(
                content: content,
                images: images,
                era: era,
                characters: characters,
                characterProbabilities: characterProbabilities,
                publishMode: publishMode
        )
        
        // 将PostData转换为UserPostModel并添加到PostViewModel（支持图片分析）
            self.createUserPostFromPostData(postData) { userPost in
            // 🔧 优化：调整延迟时间，平衡速度和流畅性，避免卡顿
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                // 使用新的增量更新方法，避免全量刷新
                PostViewModel.shared.addSinglePost(userPost)
                
                // 成功提示已经在用户点击时通过showSuccessToastImmediately()显示
                // 后台处理完成后不再重复显示，避免重复提示
                // 此函数保留是为了兼容性，实际不再执行任何操作
                self.isPublishing = false // 重置发布状态
            }
            
                // 只有没有图片的帖子才需要异步生成AI评论
                // 有图片的帖子已经通过通义千问直接生成了评论
                if userPost.images.isEmpty {
            DispatchQueue.global(qos: .utility).async {
                self.generateAICommentsForUserPost(userPost)
                    }
                } else {
                    print("🎭 图片帖子已通过通义千问生成评论，跳过DeepSeek评论生成")
                }
            }
        }
    }
    
    // 立即显示发布成功提示（用于用户点击发布按钮后）
    private func showSuccessToastImmediately() {
        // 获取潜在回复角色（基于当前选中的角色）
        let potentialCharacters = getPotentialRespondingCharactersFromCurrent()
        
        // 立即显示成功提示，与面板关闭同时进行
        self.potentialRespondingCharacters = potentialCharacters
        self.isShowingSuccessToast = true
        
        // 🔧 修复：使用精确的时间控制，确保不被后台处理干扰
        let startTime = Date()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            
            _ = Date().timeIntervalSince(startTime)
            
            if self.isShowingSuccessToast {
                self.isShowingSuccessToast = false
                self.resetPanelState()
            }
        }
    }
    
    // 显示发布成功提示（用于后台处理完成后）
    // 注意：此函数已被废弃，成功提示现在在用户点击时立即显示
    // 保留函数签名以避免编译错误，但内部逻辑已移除
    private func showSuccessToast(_ userPost: UserPostModel) {
        // 成功提示已经在用户点击时通过showSuccessToastImmediately()显示
        // 后台处理完成后不再重复显示，避免重复提示
        // 此函数保留是为了兼容性，实际不再执行任何操作
    }
    
    // 获取潜在回复角色（基于当前选中的角色）
    private func getPotentialRespondingCharactersFromCurrent() -> [CharacterModel] {
        // 从当前选中的角色中随机选择2-3个作为潜在回复角色
        let selectedChars = selectedCharacters
        if selectedChars.isEmpty {
            // 如果没有选中角色，返回空数组
            return []
        }
        
        // 随机选择2-3个角色
        let count = min(Int.random(in: 2...3), selectedChars.count)
        let shuffled = selectedChars.shuffled()
        return Array(shuffled.prefix(count))
    }
    
    // 获取潜在回复角色（基于UserPostModel）
    private func getPotentialRespondingCharacters(for userPost: UserPostModel) -> [CharacterModel] {
        // 从选中的角色中随机选择2-3个作为潜在回复角色
        let selectedChars = selectedCharacters
        if selectedChars.isEmpty {
            // 如果没有选中角色，返回空数组
            return []
        }
        
        // 随机选择2-3个角色
        let count = min(Int.random(in: 2...3), selectedChars.count)
        let shuffled = selectedChars.shuffled()
        return Array(shuffled.prefix(count))
    }
    
    // 将PostData转换为UserPostModel（支持图片分析）
    private func createUserPostFromPostData(_ postData: PostData, completion: @escaping (UserPostModel) -> Void) {
        // 创建用户帖子时不包含任何预设评论，等待AI生成
        let comments: [DetailedCommentModel] = []
        
        // ⚡️ 关键优化：使用自动释放池处理图片数组
        // 处理图片 - 将UIImage转换为图片URL或标识符
        var imageIdentifiers: [String] = []
        for (index, image) in postData.images.enumerated() {
            autoreleasepool {
                // 生成唯一图片标识符
                let imageId = "\(postData.id)_image_\(index)"
                
                // 先添加占位符，异步保存图片
                imageIdentifiers.append(imageId)
                
                // 异步保存图片，不阻塞UI
                DispatchQueue.global(qos: .utility).async {
                    _ = self.saveImage(image, withId: imageId)
                    // 图片保存成功，静默处理
                }
            }
        }
        
        // 🎯 关键优化：不管有没有图片，都先立即创建并显示帖子
        // 这样用户就能立即看到自己发布的内容，不会感到卡顿
        print("📝 立即创建帖子对象，图片数量: \(postData.images.count)")
        createUserPostWithContent(postData, imageIdentifiers: imageIdentifiers, imageDescription: nil, comments: comments, completion: completion)
        
        // 如果有图片，异步调用通义千问视觉API生成评论，完成后动态更新
        if !postData.images.isEmpty {
            print("📸 检测到\(postData.images.count)张图片，异步调用通义千问生成评论...")
            
            // 获取要评论的角色列表
            let selectedCharacterIDs = selectCharactersForResponse()
            
            // 保存帖子ID，用于后续更新
            let postId = UUID(uuidString: postData.id) ?? UUID()
            
            DoubaoVisionService.shared.analyzeImagesAndGenerateComments(
                postData.images,
                postContent: postData.content,
                characters: selectedCharacterIDs
            )
            .sink(
                receiveCompletion: { completionResult in
                    if case .failure(let error) = completionResult {
                        print("❌ 通义千问视觉API调用失败: \(error.localizedDescription)")
                        print("❌ 错误详情: \(error)")
                        
                        // 在主线程显示错误提示
                        DispatchQueue.main.async {
                            // 显示轻量级的通知，不打断用户体验
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ShowToast"),
                                object: nil,
                                userInfo: ["message": "AI评论生成失败，请检查网络连接"]
                            )
                        }
                    } else {
                        print("✅ 通义千问视觉API调用完成")
                    }
                },
                receiveValue: { commentsMap in
                    print("✅ 通义千问生成了\(commentsMap.count)条评论，准备更新帖子...")
                    
                    // 🎯 处理角色点赞（基于AI的点赞判断）
                    DoubaoVisionService.shared.processCharacterLikes(
                        for: postId.uuidString,
                        postContent: postData.content
                    )
                    
                    // 将通义千问生成的评论转换为DetailedCommentModel
                    var generatedComments: [DetailedCommentModel] = []
                    
                    for (characterID, commentContent) in commentsMap {
                        let characterDataManager = CharacterDataManager.shared
                        let characterName = characterDataManager.getName(for: characterID) ?? characterID.capitalized
                        let characterAvatar = CharacterAvatarService.shared.getAvatarName(for: characterID)
                        
                        let comment = DetailedCommentModel(
                            id: UUID(),
                            username: characterName,
                            userAvatar: characterAvatar,
                            content: commentContent,
                            datePosted: Date(),
                            isVirtualCharacter: true,
                            characterID: characterID,
                            likes: 0,
                            isLikedByCurrentUser: false
                        )
                        
                        generatedComments.append(comment)
                    }
                    
                    // 🎯 异步更新帖子的评论
                    DispatchQueue.main.async {
                        // 找到这个帖子并更新评论
                        if let index = PostViewModel.shared.posts.firstIndex(where: { $0.id == postId }) {
                            PostViewModel.shared.posts[index].comments.append(contentsOf: generatedComments)
                            print("🎨 已动态添加\(generatedComments.count)条评论到帖子")
                            
                            // 发送通知刷新UI
                            NotificationCenter.default.post(
                                name: NSNotification.Name("PostCommentsUpdated"),
                                object: nil,
                                userInfo: ["postID": postId.uuidString]
                            )
                            
                            // 发送评论生成通知
                            NotificationCenter.default.post(
                                name: NSNotification.Name("CommentsGenerated"),
                                object: nil,
                                userInfo: [
                                    "postID": postId.uuidString,
                                    "commentsMap": commentsMap,
                                    "isInvited": false
                                ]
                            )
                        } else {
                            print("⚠️ 找不到帖子ID: \(postId)，无法更新评论")
                        }
                    }
                }
            )
            .store(in: &cancellables)
        }
    }
    
    // 创建用户帖子的辅助方法
    private func createUserPostWithContent(
        _ postData: PostData,
        imageIdentifiers: [String],
        imageDescription: String?,
        comments: [DetailedCommentModel],
        completion: @escaping (UserPostModel) -> Void
    ) {
        // 构建增强的内容（原内容 + 图片描述）
        var enhancedContent = postData.content
        
        if let imageDescription = imageDescription, !imageDescription.isEmpty {
            enhancedContent += "\n\n[图片内容]: \(imageDescription)"
            print("📝 帖子内容已增强，添加了图片描述")
        }
        
        // 创建用户帖子
        let userPost = UserPostModel(
            id: UUID(uuidString: postData.id) ?? UUID(),
            username: UserProfileManager.shared.getCurrentUsername(), // 使用当前用户名
            userAvatar: UserProfileManager.shared.getCurrentAvatarURL(), // 使用当前用户头像
            content: enhancedContent, // 使用增强后的内容
            images: imageIdentifiers, // 添加图片标识符
            datePosted: postData.timestamp,
            likes: 0,
            comments: comments, // 空评论数组，等待AI生成
            isLikedByCurrentUser: false,
            isBookmarkedByCurrentUser: false,
            contentType: "user_post", // 用户发布的内容
            source: "user" // 来源为用户
        )
        
        completion(userPost)
    }
    
    // 保存图片并返回标识符
    private func saveImage(_ image: UIImage, withId id: String) -> String? {
        // 创建图片管理器实例
        let imageManager = ImageManager.shared
        
        // 保存图片到临时存储
        if imageManager.saveImage(image, withId: id) {
            return id
        }
        
        return nil
    }
    
    // 将概率转换为字典
    private func getProbabilityDict() -> [String: Int] {
        var dict = [String: Int]()
        for i in 0..<min(selectedCharacters.count, characterProbabilities.count) {
            dict[selectedCharacters[i].id] = Int(characterProbabilities[i])
        }
        return dict
    }
    
    // 归一化概率值确保总和为100
    private func normalizeCharacterProbabilities() {
        guard !characterProbabilities.isEmpty else {
            updateCharacterProbabilities()
            return
        }
        
        let total = characterProbabilities.reduce(0, +)
        if total != 100 && total > 0 {
            // 按比例调整概率
            for i in 0..<characterProbabilities.count {
                characterProbabilities[i] = (characterProbabilities[i] / total) * 100
            }
        }
    }
    
    // ✅ 为用户发布的帖子生成AI评论
    private func generateAICommentsForUserPost(_ userPost: UserPostModel) {
        // 基于概率和智能选择，确定要评论的角色
        let selectedCharacterIDs = selectCharactersForResponse()
        
        guard !selectedCharacterIDs.isEmpty else {
            return
        }
        
        // 创建超时处理
        var hasCompleted = false
        let timeoutWorkItem = DispatchWorkItem {
            if !hasCompleted {
                hasCompleted = true
            }
        }
        
        // 30秒后超时
        DispatchQueue.global().asyncAfter(deadline: .now() + 30, execute: timeoutWorkItem)
        
        // 使用MultiCharacterCommentService生成AI评论
        MultiCharacterCommentService.shared.generateMultiCharacterComments(
            characterIDs: selectedCharacterIDs,
            postId: userPost.id.uuidString,
            postContent: userPost.content,
            postAuthor: userPost.username,
            userComment: nil, // 新发布的帖子，无用户评论
            userCommentId: nil,
            targetUsername: nil,
            authorCharacterId: nil,
            isInvited: false
        ) { result in
            // 检查是否已超时
            guard !hasCompleted else {
                return
            }
            
            hasCompleted = true
            timeoutWorkItem.cancel() // 取消超时任务
            
            DispatchQueue.main.async {
                switch result {
                case .success(let commentsDict):
                    PublishPanelView.handleGeneratedComments(commentsDict, for: userPost)
                case .failure(_):
                    // 即使失败也不影响发布流程
                    break
                }
            }
        }
    }
    
    // 智能选择要评论的角色 - 使用角色轮换系统
    private func selectCharactersForResponse() -> [String] {
        // 使用角色轮换系统开始新的生成会话
        CharacterRotationSystem.shared.beginNewGenerationSession()
        
        // 用户手动选择的角色百分百会评论
        var manuallySelectedCharacters: [String] = []
        
        // 如果用户选择了角色，直接全部添加
        if !selectedCharacters.isEmpty {
            manuallySelectedCharacters = selectedCharacters.map { $0.id }
        }
        
        // 计算需要额外选择的角色数量
        let targetCount = 3 // 目标总数为3个角色
        let additionalNeeded = max(0, targetCount - manuallySelectedCharacters.count)
        
        var finalSelectedCharacters = manuallySelectedCharacters
        
        if additionalNeeded > 0 {
            // 使用角色轮换系统获取额外的角色
            let rotationCharacters = CharacterRotationSystem.shared.getBalancedCharacters(count: additionalNeeded)
            
            // 转换为字符串ID并排除已经手动选择的角色
            let additionalCharacterIds = rotationCharacters
                .map { $0.id }
                .filter { !manuallySelectedCharacters.contains($0) }
                .prefix(additionalNeeded)
            
            finalSelectedCharacters.append(contentsOf: additionalCharacterIds)
            }
            
        // 如果仍然不足（极端情况），使用轮换系统重新选择
        if finalSelectedCharacters.count < 2 {
            let rotationCharacters = CharacterRotationSystem.shared.getBalancedCharacters(count: targetCount)
            finalSelectedCharacters = rotationCharacters.map { $0.id }
        }
        
        // 限制最多3个角色
        let result = Array(finalSelectedCharacters.prefix(3))
        
        return result
    }
    
    // 处理生成的AI评论
    private static func handleGeneratedComments(_ commentsDict: [String: String], for userPost: UserPostModel) {
        var newComments: [DetailedCommentModel] = []
        
        for (characterID, commentContent) in commentsDict {
            // 获取角色信息
            let characterDataManager = CharacterDataManager.shared
            let characterName = characterDataManager.getName(for: characterID) ?? characterID.capitalized
            let characterAvatar = CharacterAvatarService.shared.getAvatarName(for: characterID)
            
            // 创建评论
            let comment = DetailedCommentModel(
                id: UUID(),
                username: characterName,
                userAvatar: characterAvatar,
                content: commentContent,
                datePosted: Date(),
                isVirtualCharacter: true,
                characterID: characterID,
                likes: 0,
                isLikedByCurrentUser: false
            )
            
            newComments.append(comment)
        }
        
        // 添加评论到帖子
        if !newComments.isEmpty {
            DispatchQueue.main.async {
                if let postIndex = PostViewModel.shared.posts.firstIndex(where: { $0.id == userPost.id }) {
                    PostViewModel.shared.posts[postIndex].comments.append(contentsOf: newComments)
                } else {
                    // 未找到对应的帖子进行评论更新
                }
            }
        }
    }
    
    // 重置面板状态
    private func resetPanelState() {
        contentText = ""
        selectedCharacters = []
        selectedImages = []
        selectedEra = "现代"
        showProbabilitySettings = false
        characterProbabilities = []
        publishMode = .communication
        isShowingSuccessToast = false  // 确保重置成功提示状态
    }
    
    // 发布内容的数据结构
    struct PostData {
        let id: String
        let content: String
        let images: [UIImage]
        let era: String
        let characters: [CharacterModel]
        let characterProbabilities: [String: Int]
        let publishMode: PublishMode
        let timestamp: Date
        
        init(content: String, images: [UIImage], era: String, characters: [CharacterModel], characterProbabilities: [String: Int], publishMode: PublishMode) {
            self.id = UUID().uuidString
            self.content = content
            self.images = images
            self.era = era
            self.characters = characters
            self.characterProbabilities = characterProbabilities
            self.publishMode = publishMode
            self.timestamp = Date()
        }
    }
    
    // 隐藏键盘
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // 多次尝试激活文本输入焦点
    private func activateTextInputWithMultipleAttempts() {
        // 尝试多次激活，提高成功率
        forceActivateTextInput()
        
        // 延迟再次尝试（从0.5秒减少到0.2秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.forceActivateTextInput()
        }
    }
    
    // 查找拖拽目标 - 简化逻辑，使用最接近的图片作为目标
    private func findDropTarget(dragPosition: CGPoint) {
        // 使用Task避免在视图更新期间修改状态
        Task { @MainActor in
            // 使用存储的实际图片位置进行碰撞检测
            guard let draggedIndex = self.draggedIndex else { return }
            
            // 如果没有收集到任何图片位置，不进行检测
            if imagePositions.isEmpty {
                return
            }
            
            // 找出最近的图片
            var closestIndex: Int? = nil
            var closestDistance: CGFloat = .infinity
            
            for (index, frame) in imagePositions {
                // 跳过被拖拽的图片
                if index == draggedIndex {
                    continue
                }
                
                // 计算到图片中心的距离
                let centerX = frame.midX
                let centerY = frame.midY
                let distance = sqrt(pow(centerX - dragPosition.x, 2) + pow(centerY - dragPosition.y, 2))
                
                // 更新最近的图片
                if distance < closestDistance {
                    closestDistance = distance
                    closestIndex = index
                }
            }
            
            // 设置距离阈值（图片宽度的1倍）
            let distanceThreshold: CGFloat = 55
            
            // 如果有足够近的图片，更新当前目标
            if let targetIndex = closestIndex, closestDistance < distanceThreshold {
                if currentDropIndex != targetIndex {
                    // 触觉反馈
                    let feedback = UIImpactFeedbackGenerator(style: .light)
                    feedback.impactOccurred()
                    
                    // 更新目标
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.currentDropIndex = targetIndex
                    }
                }
            } else {
                // 如果没有足够近的图片，清除当前目标
                if currentDropIndex != nil {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.currentDropIndex = nil
                    }
                }
            }
        }
    }
    
    // 执行图片交换
    private func performSwap() {
        Task { @MainActor in
            guard let draggedIndex = self.draggedIndex,
                  let dropIndex = self.currentDropIndex,
                  draggedIndex != dropIndex else { 
                return 
            }
            
            // 执行交换 - 只交换两张图片的位置（从0.3秒减少到0.2秒）
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                // 交换图片
                selectedImages.swapAt(draggedIndex, dropIndex)
            }
            
            // 交换成功触觉反馈
            let feedback = UIImpactFeedbackGenerator(style: .heavy)
            feedback.impactOccurred()
            
            // 延迟刷新位置信息，确保UI已更新（从0.3秒减少到0.15秒）
            try? await Task.sleep(nanoseconds: 150_000_000) // 0.15秒
            self.needsPositionRefresh = true
        }
    }
    
    // 刷新所有图片位置
    private func refreshImagePositions() {
        // 使用Task避免在视图更新期间修改状态
        Task { @MainActor in
            // 强制触发布局更新
            self.needsPositionRefresh = false
            
            // 重新收集所有图片位置
            for index in 0..<self.selectedImages.count {
                if self.imagePositions[index] == nil {
                    // 如果有缺失的位置，稍后再次尝试刷新（从0.2秒减少到0.1秒）
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                    self.needsPositionRefresh = true
                    break
                }
            }
        }
    }
    
    // 角色回复概率设置视图
    private var characterResponseProbabilityView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题栏
            HStack {
                Text("角色回复概率")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                // 平均分配按钮
                Button(action: {
                    resetResponseProbabilities()
                }) {
                    Text("平均分配")
                        .font(.system(size: 14))
                        .foregroundColor(Color.primaryColor)
                }
            }
            
            // 角色概率滑块
            ForEach(selectedCharacters.indices, id: \.self) { index in
                if index < characterProbabilities.count {
                    HStack(spacing: 12) {
                        // 角色头像
                        characterAvatar(for: selectedCharacters[index])
                            .frame(width: 36, height: 36)
                        
                        // 角色名称
                        Text(selectedCharacters[index].name)
                            .font(.system(size: 14))
                            .lineLimit(1)
                        
                        // 概率滑块
                        Slider(
                            value: $characterProbabilities[index],
                            in: 0...100,
                            step: 5
                        )
                        .accentColor(probabilityColor(for: characterProbabilities[index]))
                        
                        // 百分比数值
                        Text("\(Int(characterProbabilities[index]))%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(probabilityColor(for: characterProbabilities[index]))
                            .frame(width: 40, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // 总计
            HStack {
                Spacer()
                Text("总计: \(totalProbability)%")
                    .font(.system(size: 14))
                    .foregroundColor(totalProbability == 100 ? .green : .orange)
            }
            .padding(.top, 4)
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
    
    // 计算总概率
    private var totalProbability: Int {
        Int(characterProbabilities.reduce(0, +))
    }
    
    // 根据概率值返回对应颜色
    private func probabilityColor(for value: Double) -> Color {
        if value < 20 {
            return .gray
        } else if value < 40 {
            return .blue
        } else if value < 60 {
            return .green
        } else if value < 80 {
            return .orange
        } else {
            return .red
        }
    }
    
    // 重置概率为平均分配
    private func resetResponseProbabilities() {
        guard !selectedCharacters.isEmpty else { return }
        
        let averageValue = 100 / selectedCharacters.count
        characterProbabilities = selectedCharacters.map { _ in Double(averageValue) }
        
        // 处理不能整除的情况
        if averageValue * selectedCharacters.count < 100 {
            let remainder = 100 - (averageValue * selectedCharacters.count)
            for i in 0..<remainder {
                if i < characterProbabilities.count {
                    characterProbabilities[i] += 1
                }
            }
        }
    }
    
    // 更新角色概率数组
    private func updateCharacterProbabilities() {
        // 如果角色数量变化，重新分配概率
        if characterProbabilities.count != selectedCharacters.count {
            resetResponseProbabilities()
        }
    }
    
    // 角色头像视图
    private func characterAvatar(for character: CharacterModel) -> some View {
        ZStack {
            if UIImage(named: character.avatar) != nil {
                Image(character.avatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(character.category.color.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(character.name.prefix(1)))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(character.category.color)
                    )
            }
        }
    }
    
    // 成功提示视图
    private var successToastView: some View {
        SuccessToastCard(
            contentText: contentText,
            potentialRespondingCharacters: potentialRespondingCharacters
        )
    }
    
    // 将复杂视图拆分为更小的组件
    private struct SuccessToastCard: View {
        let contentText: String
        let potentialRespondingCharacters: [CharacterModel]
        
        var body: some View {
            VStack(spacing: 10) { // 减少整体间距，从12减到10
                // 成功标志与标题
                SuccessHeaderView()
                
                // 内容预览
                ContentPreviewView(text: contentText)
                
                // 移除分隔线和推荐角色显示
                // DividerView()
                //     .padding(.vertical, 1)
                // CharacterResponseView(characters: potentialRespondingCharacters)
            }
            .padding(.vertical, 30) // 进一步增加卡片上下的内边距，从25增加到30
            .padding(.horizontal, 20)
            .frame(width: 220, height: 180) // 减少高度，因为移除了推荐角色部分
            .background(GlassCardBackground())
            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
        }
    }
    
    // 成功标题组件
    private struct SuccessHeaderView: View {
        var body: some View {
            VStack(spacing: 5) { // 进一步减少间距，从6减到5
                ZStack {
                    // 背景圆形
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    // 圆环设计
                    Circle()
                        .stroke(Color.green.opacity(0.9), lineWidth: 2.5)
                        .frame(width: 40, height: 40)
                    
                    // 对号图标 - 稍微调小一点
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.green.opacity(0.9))
                }
                .padding(.bottom, 1) // 微调图标与文字的间距，从2减到1
                
                Text("发布成功！")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.9))
                    .padding(.top, 1) // 微调文字位置，从2减到1
            }
            .padding(.top, 8) // 整体下移一点，从6增加到8
        }
    }
    
    // 角色回复组件
    private struct CharacterResponseView: View {
        let characters: [CharacterModel]
        
        var body: some View {
            VStack(spacing: 6) { // 减少间距，从8减到6
                Text("这些角色可能会回复：")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.7)) // 降低不透明度，使颜色更浅
                    .padding(.top, -3) // 向上移动更多，从-2改为-3
                
                HStack(spacing: 14) {
                    ForEach(characters.prefix(3)) { character in
                        CharacterBubbleView(character: character)
                    }
                }
            }
        }
    }
    
    // 内容预览组件
    private struct ContentPreviewView: View {
        let text: String
        @State private var randomPoetryText: String = ""
        
        // 诗意文本集合
        private let poetryTexts = [
            "这一刻，已穿越时空",
            "期待心灵的对话即将开始...",
            "已将这份心情投入时间长河",
            "思绪如光，穿越时空的边界",
            "心声已启程",
            "一个瞬间，连接过去与未来",
            "此刻的感悟，将与星辰共存",
            "心声已远航",
            "思绪如风，穿梭于古今之间",
            "虫洞相遇",
            "思绪如帆，扬起时空的航程",
            "心念微动，时空已为之共振"
        ]
        
        var body: some View {
            Text(randomPoetryText)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(maxWidth: 160)
                .onAppear {
                    // 在视图出现时随机选择一句诗意文本
                    randomPoetryText = poetryTexts.randomElement() ?? "这一刻，已穿越时空"
                }
        }
    }
    
    // 分隔线组件
    private struct DividerView: View {
        var body: some View {
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(height: 1)
                .padding(.horizontal, 12)
        }
    }
    
    // 角色气泡组件
    private struct CharacterBubbleView: View {
        let character: CharacterModel
        
        var body: some View {
            VStack(spacing: 4) {
                Circle()
                    .fill(character.category.color.opacity(0.2))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Text(String(character.name.prefix(1)))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(character.category.color)
                    )
                
                Text(character.name)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.65)) // 降低不透明度，使颜色更浅
                    .lineLimit(1)
            }
        }
    }
    
    // 玻璃卡片背景
    private struct GlassCardBackground: View {
        var body: some View {
            ZStack {
                // 基础背景 - 磨砂玻璃效果
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6).opacity(0.85))
                
                // 主光谱渐变层 - 精确复刻图二光谱效果
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.white.opacity(0.85), location: 0.0),
                                .init(color: Color.white.opacity(0.75), location: 0.4),
                                .init(color: Color.white.opacity(0.7), location: 0.6),
                                .init(color: Color.white.opacity(0.65), location: 1.0)
                            ]),
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
                
                // 彩虹光谱效果 - 右上方
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    // 右上角彩虹光谱区域 (从右上角向内辐射)
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.76, green: 0.12, blue: 0.96), // 紫色
                                    Color(red: 0.49, green: 0.33, blue: 0.94), // 蓝紫色
                                    Color(red: 0.17, green: 0.52, blue: 0.96), // 蓝色
                                    Color(red: 0.18, green: 0.69, blue: 0.85), // 青色
                                    Color(red: 0.31, green: 0.78, blue: 0.47), // 绿色
                                    Color(red: 0.82, green: 0.72, blue: 0.33), // 黄色
                                    Color(red: 0.96, green: 0.45, blue: 0.33), // 橙色
                                    Color(red: 0.92, green: 0.26, blue: 0.21)  // 红色
                                ]),
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            )
                        )
                        .mask(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.6),
                                    Color.black.opacity(0.0)
                                ]),
                                center: .topTrailing,
                                startRadius: 0,
                                endRadius: width * 0.8
                            )
                        )
                        .blendMode(.overlay)
                        .opacity(0.85)
                
                    // 左下角白光光束 (精确复制图二的白色光线)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: height))
                        path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.6))
                        path.addLine(to: CGPoint(x: width * 0.4 + 1, y: height * 0.6 + 1))
                        path.addLine(to: CGPoint(x: 0, y: height + 1))
                    }
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.95),
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.2)
                            ]),
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
                    .blur(radius: 2)
                    .blendMode(.overlay)
                }
                
                // 边框效果 - 精致的高光边缘
            RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.9),
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
                
                // 顶部微妙高光 - 模拟真实玻璃反光
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.0)
                            ]),
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .mask(
                        RoundedRectangle(cornerRadius: 16)
                    )
            }
        }
    }
    
    /**
     * 时代选择区域
     * 通过改进的布局和动画增强用户体验
     */
    func eraSelectionArea() -> some View {
        EnhancedScrollView(title: "选择时代") {
            HStack(spacing: 8) {
                ForEach(eras, id: \.self) { era in
                    Button(action: {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                            selectedEra = era
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }) {
                        // 精简样式
                        let isSelected = era == selectedEra
                        let textFont = Font.system(size: 14, weight: isSelected ? .semibold : .regular)
                        let textColor = isSelected ? Color.white : Color.primary.opacity(0.7)
                        
                        Text(era)
                            .font(textFont)
                            .foregroundColor(textColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isSelected ? 
                                        AnyShapeStyle(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        ) : 
                                        AnyShapeStyle(Color.secondary.opacity(0.08))
                                    )
                            )
                            .scaleEffect(isSelected ? 1.02 : 1.0)
                    }
                    .buttonStyle(SpringyButtonStyle())
                }
            }
        }
        .padding(.horizontal, 12)
    }
}

/**
 * 发布模式枚举
 */
enum PublishMode: CaseIterable {
    case communication  // 交流
    
    var title: String {
        return "交流"
    }
    
    var placeholder: String {
        return "写下你想和历史人物交流的内容..."
    }
}



/**
 * 角色选择器视图
 * 用于浏览和选择角色
 */
struct CharacterSelectorView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedCharacters: [CharacterModel]
    @State private var searchText = ""
    @State private var localSelectedCharacters: [CharacterModel] = []
    @State private var selectedCategory: CharacterCategory? = .all
    @State private var showSearchCancelButton = false
    @State private var isSearchFocused: Bool = false
    
    // 动画效果控制
    @State private var isAnimating = false
    
    // 常量定义 - 提高复用性和一致性
    private let cornerRadius: CGFloat = 12
    private let primaryPadding: CGFloat = 16
    private let secondaryPadding: CGFloat = 8
    
    var body: some View {
        ZStack {
            // 全屏透明背景，用于点击收起键盘
            if isSearchFocused {
                Color.black.opacity(0.001) // 几乎完全透明
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onTapGesture {
                        hideKeyboard()
                        isSearchFocused = false
                    }
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                // 重新设计顶部区域 - 移除取消按钮，优化布局
                VStack(spacing: 12) { // 增加间距
                    // 标题与确定按钮
                    HStack {
                        // 左侧空间
                        Spacer()
                            .frame(width: 50)
                        
                        Spacer()
                        
                        Text("选择角色")
                            .font(.system(size: 17, weight: .semibold))
                        
                        Spacer()
                        
                        // 完全重新设计确定按钮 - 水平布局
                        Button(action: {
                            selectedCharacters = localSelectedCharacters
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text(localSelectedCharacters.isEmpty ? "确定" : "确定(\(localSelectedCharacters.count))")
                                .font(.system(size: 16))
                                .foregroundColor(localSelectedCharacters.isEmpty ? .gray : .primaryColor)
                        }
                        .disabled(localSelectedCharacters.isEmpty)
                        .frame(width: 60, alignment: .trailing)
                    }
                    .padding(.top, 8)
                    
                    // 搜索栏 - 独立成一行，不再与按钮共行
                    HStack(spacing: 4) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                        
                        TextField("搜索角色", text: $searchText, onEditingChanged: { isEditing in
                            withAnimation {
                                isSearchFocused = isEditing
                            }
                        })
                        .font(.system(size: 15))
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(cornerRadius)
                }
                .padding(.horizontal, primaryPadding)
                .padding(.top, 10)
                .padding(.bottom, secondaryPadding)
                
                // 已选角色预览 - 保持不变，仍然需要良好的视觉区分
                if !localSelectedCharacters.isEmpty {
                    selectedCharactersBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // 分类标签栏 - 更紧凑的设计
                categoryTabsCompact
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                
                Divider()
                    .padding(.horizontal, primaryPadding)
                
                // 角色网格 - 更高效的布局
                characterGridOptimized
                    .padding(.top, 6)
            }
        }
        .onAppear {
            localSelectedCharacters = selectedCharacters
            
            // 添加动画效果（从0.3秒延迟减少到0.1秒，动画时长从0.4秒减少到0.2秒）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAnimating = true
                }
            }
        }
        .background(DesignSystem.Colors.cardBackground)
    }
    
    // 已选角色预览条 - 紧凑版
    private var selectedCharactersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(localSelectedCharacters) { character in
                    selectedCharacterBadge(character: character)
                }
                
                if localSelectedCharacters.count > 1 {
                    Button(action: {
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    localSelectedCharacters.removeAll()
                }
                    }) {
                        Text("清空")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal, primaryPadding)
            .padding(.vertical, 8)
        }
        .background(Color.gray.opacity(0.05))
    }
    
    // 选中角色的小标签 - 紧凑版
    private func selectedCharacterBadge(character: CharacterModel) -> some View {
        HStack(spacing: 4) {
            // 角色头像或首字母
            Text(String(character.name.prefix(1)))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(character.category.color)
                .clipShape(Circle())
            
            // 角色名称
            Text(character.name)
                .font(.system(size: 13))
                .lineLimit(1)
            
            // 删除按钮
            Button(action: {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    localSelectedCharacters.removeAll { $0.id == character.id }
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // 更紧凑的分类标签设计
    private var categoryTabsCompact: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 全部分类按钮
                compactCategoryButton(category: .all)
                
                // 历史人物分类
                Group {
                    compactCategoryButton(category: .scientist)
                    compactCategoryButton(category: .artist)
                    compactCategoryButton(category: .philosopher)
                    compactCategoryButton(category: .writer)
                }
                
                // 虚构角色分类
                if CharacterCategory.allCases.contains(where: { $0.isVirtual }) {
                    Group {
                        compactCategoryButton(category: .animeCharacter)
                        compactCategoryButton(category: .gameCharacter)
                        compactCategoryButton(category: .fictionCharacter)
                    }
                }
            }
            .padding(.horizontal, primaryPadding)
        }
    }
    
    // 更紧凑的分类按钮
    private func compactCategoryButton(category: CharacterCategory) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = (selectedCategory == category) ? .all : category
            }
        }) {
            HStack(spacing: 4) {
                if category != .all {
                    Image(systemName: category.icon)
                        .font(.system(size: 12))
                }
                
                Text(category.displayName)
                    .font(.system(size: 13))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                Capsule()
                    .fill(selectedCategory == category 
                          ? category.color.opacity(0.15) 
                          : Color.gray.opacity(0.08))
            )
            .foregroundColor(selectedCategory == category 
                           ? category.color 
                           : .primary)
        }
    }
    
    // 优化的角色网格
    private var characterGridOptimized: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ],
                spacing: 8 // 进一步减少间距
            ) {
                ForEach(filteredCharacters) { character in
                    CharacterSelectionCell(
                        character: character,
                        isSelected: isSelected(character),
                        onToggle: { toggleCharacter(character) }
                    )
                    .opacity(isAnimating ? 1.0 : 0)
                    .offset(y: isAnimating ? 0 : 15) // 减小动画距离
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.7)
                        .delay(Double(filteredCharacters.firstIndex(where: { $0.id == character.id }) ?? 0) * 0.02),
                        value: isAnimating
                    )
                }
            }
            .padding(12)
            
            if filteredCharacters.isEmpty {
                emptyStateView
            }
        }
    }
    
    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 32))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(searchText.isEmpty ? "没有匹配的角色" : "没有找到\"\(searchText)\"相关的角色")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Button(action: { createNewCharacter() }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                    
                    Text("创建新角色")
                        .font(.system(size: 15, weight: .medium))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.primaryColor.opacity(0.8),
                                    Color.primaryColor
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .foregroundColor(.white)
                .shadow(color: Color.primaryColor.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(BouncyButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    // 创建新角色的方法
    private func createNewCharacter() {
        // 获取搜索词作为默认名称
        let defaultName = searchText.isEmpty ? "" : searchText
        
        // 关闭当前选择器
        self.presentationMode.wrappedValue.dismiss()
        
        // 模拟延迟，然后进行创建角色操作（从0.3秒减少到0.1秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 这里应该跳转到创建角色的页面或弹出创建角色的表单
            print("创建新角色: \(defaultName)")
        }
    }
    
    /**
     * 将角色的type和subtype映射到CharacterCategory
     */
    private func mapToCharacterCategory(type: String, subtype: String) -> CharacterCategory {
        switch (type, subtype) {
        case ("historical", "scientist"), ("literary", "scientist"), ("movie", "scientist"), ("anime", "scientist"):
            return .scientist
        case ("historical", "writer"), ("literary", "writer"), ("movie", "writer"), ("anime", "writer"):
            return .writer
        case ("historical", "artist"), ("literary", "artist"), ("movie", "artist"), ("anime", "artist"):
            return .artist
        case ("historical", "philosopher"), ("literary", "philosopher"), ("movie", "philosopher"), ("anime", "philosopher"):
            return .philosopher
        case ("historical", "politician"), ("literary", "politician"), ("movie", "politician"), ("anime", "politician"):
            return .historical
        case ("historical", "military"), ("literary", "military"), ("movie", "military"), ("anime", "military"):
            return .historical
        case ("historical", "explorer"), ("literary", "explorer"), ("movie", "explorer"), ("anime", "explorer"):
            return .historical
        case ("historical", "inventor"), ("literary", "inventor"), ("movie", "inventor"), ("anime", "inventor"):
            return .scientist
        case ("historical", "musician"), ("literary", "musician"), ("movie", "musician"), ("anime", "musician"):
            return .artist
        case ("historical", "athlete"), ("literary", "athlete"), ("movie", "athlete"), ("anime", "athlete"):
            return .historical
        case ("historical", "business"), ("literary", "business"), ("movie", "business"), ("anime", "business"):
            return .historical
        case ("historical", "religious"), ("literary", "religious"), ("movie", "religious"), ("anime", "religious"):
            return .historical
        case ("historical", "mythological"), ("literary", "mythological"), ("movie", "mythological"), ("anime", "mythological"):
            return .mythCharacter
        case ("historical", "fictional"), ("literary", "fictional"), ("movie", "fictional"), ("anime", "fictional"):
            return .fictionCharacter
        default:
            // 根据type进行默认分类
            switch type {
            case "historical":
                return .scientist
            case "literary":
                return .writer
            case "movie":
                return .movieCharacter
            case "anime":
                return .animeCharacter
            case "game":
                return .gameCharacter
            default:
                return .scientist
            }
        }
    }
    
    // 过滤后的角色列表 - 使用完整的角色库而不是硬编码的示例角色
    private var filteredCharacters: [CharacterModel] {
        // 从CharacterDataManager获取所有角色信息，转换为CharacterModel
        let allCharacterInfos = CharacterDataManager.shared.getAllCharactersInfo()
        var characters = allCharacterInfos.map { characterInfo in
            CharacterModel(
                id: characterInfo.id,
                name: characterInfo.name,
                avatar: characterInfo.avatar, // 使用真实的头像名称
                era: characterInfo.era, // 使用真实的时代信息
                profession: characterInfo.primaryField, // 使用真实的职业信息
                bio: "暂无描述", // 暂时使用默认值
                category: mapToCharacterCategory(type: characterInfo.type, subtype: characterInfo.subtype), // 使用映射的分类
                famousQuotes: [], // 暂时使用默认值
                characterID: characterInfo.id
            )
        }
        
        // 按分类筛选
        if selectedCategory != nil && selectedCategory != .all {
            characters = characters.filter { $0.category == selectedCategory }
        }
        
        // 按搜索文本筛选
        if !searchText.isEmpty {
            characters = characters.filter { character in
                character.name.lowercased().contains(searchText.lowercased()) ||
                character.profession.lowercased().contains(searchText.lowercased())
            }
        }
        
        return characters
    }
    
    // 检查角色是否已选中
    private func isSelected(_ character: CharacterModel) -> Bool {
        return localSelectedCharacters.contains { $0.id == character.id }
    }
    
    // 切换角色选中状态
    private func toggleCharacter(_ character: CharacterModel) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            if isSelected(character) {
                localSelectedCharacters.removeAll { $0.id == character.id }
            } else {
                localSelectedCharacters.append(character)
            }
        }
    }
    
    // 隐藏键盘
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

/**
 * 角色选择单元格
 * 用于角色选择器中的单元格显示
 */
struct CharacterSelectionCell: View {
    let character: CharacterModel
    let isSelected: Bool
    let onToggle: () -> Void
    
    @State private var isPressed = false
    
    // 定义固定尺寸常量
    private let cardWidth: CGFloat = 100 // 减小宽度适应三列布局
    private let cardHeight: CGFloat = 120 // 减小高度
    private let avatarSize: CGFloat = 50 // 减小头像尺寸
    
    var body: some View {
        Button(action: {
            onToggle()
            
            // 添加短暂的按压效果
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }) {
            VStack(spacing: 0) {
                // 角色头像与选中指示器
                ZStack {
                    // 背景圆形
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    character.category.color.opacity(0.1),
                                    character.category.color.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: avatarSize, height: avatarSize)
                    
                    // 角色头像 - 尝试显示真实头像，失败时使用首字母
                    if let image = UIImage(named: character.avatar) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: avatarSize, height: avatarSize)
                            .clipShape(Circle())
                    } else if let image = UIImage(named: "HistoricalFigures/\(character.avatar)") {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: avatarSize, height: avatarSize)
                            .clipShape(Circle())
                    } else {
                        // 如果头像加载失败，使用首字母作为占位符
                        Text(String(character.name.prefix(1)))
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(character.category.color)
                    }
                    
                    // 右上角显示选中状态
                    if isSelected {
                        Circle()
                            .stroke(character.category.color, lineWidth: 2)
                            .frame(width: avatarSize + 4, height: avatarSize + 4)
                        
                        ZStack {
                            Circle()
                                .fill(character.category.color)
                                .frame(width: 18, height: 18)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 20, y: -20)
                    }
                }
                .padding(.top, 10)
                
                // 紧凑的角色信息
                VStack(spacing: 2) {
                    // 角色名称
                    Text(character.name)
                        .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                        .foregroundColor(isSelected ? character.category.color : .primary)
                        .lineLimit(1)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // 职业
                    HStack(spacing: 3) {
                        Image(systemName: getProfessionIcon(for: character.profession))
                            .font(.system(size: 9))
                            .foregroundColor(character.category.color.opacity(0.7))
                        
                        Text(character.profession)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 1)
                    
                    // 时代标签 - 更紧凑的样式
                    Text(character.era)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.8))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(3)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
            .frame(width: cardWidth, height: cardHeight) // 使用固定尺寸
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(
                        color: isSelected ? character.category.color.opacity(0.2) : Color.black.opacity(0.05),
                        radius: isSelected ? 4 : 2,
                        x: 0,
                        y: isSelected ? 2 : 1
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? character.category.color.opacity(0.3) : Color.clear,
                        lineWidth: 1.2
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 根据职业获取图标
    private func getProfessionIcon(for profession: String) -> String {
        let lowercasedProfession = profession.lowercased()
        
        if lowercasedProfession.contains("科学") || lowercasedProfession.contains("物理") {
            return "atom"
        } else if lowercasedProfession.contains("文学") || lowercasedProfession.contains("作家") || lowercasedProfession.contains("诗人") {
            return "book.fill"
        } else if lowercasedProfession.contains("哲学") {
            return "brain"
        } else if lowercasedProfession.contains("艺术") || lowercasedProfession.contains("画家") {
            return "paintbrush.fill"
        } else if lowercasedProfession.contains("音乐") {
            return "music.note"
        } else if lowercasedProfession.contains("政治") || lowercasedProfession.contains("领袖") {
            return "flag.fill"
        } else {
            return "person.fill"
        }
    }
}

/**
 * 虫洞能量指示器 - 优化后的简化版本
 * 只保留核心因素：文本长度和角色数量
 * 移除复杂的关键词检测和时代因素，提高响应性和公平性
 */
struct WormholeEnergyIndicator: View {
    let contentText: String
    let characters: [CharacterModel]
    let isAnimating: Bool // 控制是否显示动画
    
    // 添加防抖状态，避免拼音输入时能量条频繁变化
    @State private var debouncedTextLength: Int = 0
    @State private var debounceTimer: Timer?
    
    // 计算能量等级 - 优化后的简化算法
    private var energyLevel: Int {
        // 🎯 优化说明：
        // 1. 删除了关键词检测：避免用户通过特定词汇"刷分"
        // 2. 删除了时代因素：时代选择主要用于内容生成，不影响穿越能量
        // 3. 调整了文本系数：从每3字符1点改为每2字符1点，提高响应性
        // 4. 降低了角色权重：从每个角色20点改为15点，避免角色数量过度影响
        
        // 📝 文本长度因素：使用防抖后的文本长度，每2个字符提供1点能量，最高40点
        let textFactor = min(debouncedTextLength / 2, 40)
        
        // 👥 角色数量因素：每个角色提供15点能量，最高45点
        let characterFactor = min(characters.count * 15, 45)
        
        // 🧮 总能量计算：文本 + 角色，除以17得到0-5级
        let totalEnergy = textFactor + characterFactor
        return min(totalEnergy / 17, 5) // 5级需要85点能量
    }
    
    // 移除关键词检测方法，简化逻辑
    
    // 获取能量百分比值
    private var energyPercentage: Int {
        // 确保即使没有文本也显示至少10%的能量
        let basePercentage = 10
        let calculatedPercentage = energyLevel * 20
        
        // 如果有输入内容但计算值低于基础值，至少显示基础值
        if !contentText.isEmpty && calculatedPercentage < basePercentage {
            return basePercentage
        }
        
        return max(calculatedPercentage, basePercentage) // 确保不低于基础值
    }
    
    // 移除高频计时器，改为基于内容变化的响应式更新
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                // 标题与图标
                HStack(spacing: 4) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(energyColor)
                    
                    Text("穿越能量")
                        .font(.system(size: 14, weight: .medium))
                }
                
                Spacer()
                
                // 能量百分比
                Text("\(formattedEnergyPercentage)%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(energyColor)
            }
            
            // 能量条
            ZStack(alignment: .leading) {
                // 背景
                energyBarBackground
                
                // 填充条 - 添加平滑动画
                energyBarFill
                    .frame(width: nil)
                    .mask(
                        GeometryReader { geometry in
                            Rectangle()
                                .frame(width: geometry.size.width * CGFloat(energyPercentage) / 100)
                        }
                    )
                    .animation(.easeInOut(duration: 0.3), value: energyPercentage)
                
                // 粒子效果 - 仅在能量足够且允许动画时显示
                if energyPercentage > 20 && isAnimating {
                    energyParticles
                }
            }
            .frame(height: 10)
            .clipShape(Capsule())
        }
        .onAppear {
            // 初始化防抖文本长度
            debouncedTextLength = contentText.count
        }
        .onChange(of: contentText) { oldValue, newText in
            // 防抖处理：延迟300ms更新文本长度，避免拼音输入时的频繁变化
            debounceTimer?.invalidate()
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                debouncedTextLength = newText.count
            }
        }
        .onDisappear {
            // 清理定时器
            debounceTimer?.invalidate()
            debounceTimer = nil
        }
    }
    
    // 能量条背景
    private var energyBarBackground: some View {
        ZStack {
            // 基础背景
            Capsule()
                .fill(Color.black.opacity(0.05))
                .overlay(
                    Capsule()
                        .stroke(
                            Color.gray.opacity(0.2),
                            lineWidth: 0.5
                        )
                )
            
            // 刻度线
            HStack(spacing: 0) {
                ForEach(0..<5) { i in
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 1, height: 4)
                    
                    if i < 4 {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // 能量条填充
    private var energyBarFill: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                energyColor.opacity(0.7),
                energyColor
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .overlay(
            // 能量波纹效果
            ZStack {
                ForEach(0..<3) { i in
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.0),
                                    Color.white.opacity(Double(i) * 0.1 + 0.2),
                                    Color.white.opacity(0.0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: CGFloat(i) * 10 - 30 + CGFloat(energyPercentage) * 0.3)
                }
            }
        )
    }
    
    // 能量粒子效果 - 根据动画状态显示不同效果
    private var energyParticles: some View {
        HStack(spacing: 4) {
            ForEach(0..<min(energyPercentage/10, 4), id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 3, height: 3)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 0.8 : 0.6)
                    .animation(
                        isAnimating ? 
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(Double(i) * 0.2) :
                        .none,
                        value: isAnimating
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // 能量颜色 - 更强的视觉效果
    private var energyColor: Color {
        switch energyLevel {
        case 0:
            return Color.gray
        case 1:
            return Color.blue.opacity(0.7)
        case 2:
            return Color.blue.opacity(0.8)
        case 3:
            return Color.primaryColor.opacity(0.85)
        case 4:
            return Color.primaryColor.opacity(0.9)
        case 5:
            return Color.primaryColor
        default:
            return Color.gray
        }
    }
    
    // 格式化能量百分比
    private var formattedEnergyPercentage: String {
        return "\(energyPercentage)"
    }
}

/**
 * 发布预览视图
 * 展示最终发布内容的预览
 */
struct PublishPreviewView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let contentText: String
    let selectedCharacters: [CharacterModel]
    let selectedEra: String
    let mode: PublishMode
    
    @State private var showingReactions = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 内容预览卡片
                    contentPreviewCard
                    
                    // 虫洞传送信息
                    wormholeInfoSection
                    
                    // 角色反应预览
                    characterReactionsSection
                }
                .padding()
            }
            .navigationTitle("发布预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("发布") {
                        // 处理发布逻辑
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(Color.primaryColor)
                }
            }
        }
    }
    
    // 内容预览卡片
    private var contentPreviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 模式标签
            HStack {
                Text(mode.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.primaryColor)
                    .cornerRadius(12)
                
                Spacer()
                
                // 时代标签
                Text(selectedEra)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
            
            // 内容文本
            Text(contentText)
                .font(.system(size: 16))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            // 选中角色头像
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedCharacters) { character in
                        if UIImage(named: character.avatar) != nil {
                            Image(character.avatar)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(character.category.color.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(character.name.prefix(1)))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(character.category.color)
                                )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
    
    // 虫洞传送信息
    private var wormholeInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("虫洞传送信息")
                .font(.system(size: 18, weight: .bold))
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("发送时间:")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("现在")
                }
                
                HStack {
                    Text("目标时空:")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(selectedEra)
                }
                
                HStack {
                    Text("接收者:")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(selectedCharacters.count)位角色")
                }
                
                HStack {
                    Text("预计反应时间:")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("30秒")
                }
            }
            .font(.system(size: 14))
            .padding(12)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    // 角色反应预览
    private var characterReactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("可能的角色反应")
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                Button(action: {
                    showingReactions.toggle()
                }) {
                    Text(showingReactions ? "收起" : "预览")
                        .font(.system(size: 14))
                        .foregroundColor(Color.primaryColor)
                }
            }
            
            if showingReactions {
                // 角色反应预览
                characterReactionView()
            } else {
                Text("点击预览查看角色可能的反应")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
            }
        }
    }
    
    // 角色反应视图
    private func characterReactionView() -> some View {
        VStack(spacing: 16) {
            ForEach(selectedCharacters) { character in
                VStack(alignment: .leading, spacing: 12) {
                    // 角色信息栏
                    HStack {
                        // 角色头像
                        if UIImage(named: character.avatar) != nil {
                            Image(character.avatar)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(character.category.color.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(character.name.prefix(1)))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(character.category.color)
                                )
                        }
                        
                        // 角色名称和领域
                        VStack(alignment: .leading, spacing: 2) {
                            Text(character.name)
                                .font(.system(size: 14, weight: .semibold))
                            
                            HStack(spacing: 8) {
                                Text(character.profession)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                
                                Text(character.era)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(character.category.color.opacity(0.7))
                                    .cornerRadius(8)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // 角色反应内容
                    Text(generateCharacterResponse(character: character))
                        .font(.system(size: 14))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    // 生成角色反应
    private func generateCharacterResponse(character: CharacterModel) -> String {
        // 这里可以接入AI生成真实的角色反应
        // 示例中使用简单的模板
        
        let templates = [
            "作为一位[field]，[name]对于'[content]'这一观点有着独特的见解。在[era]的背景下，[pronoun]认为这体现了时代的特征，同时也反映了人类思维的演变。",
            "来自[era]的[name]，以[field]的视角思考了'[content]'这个话题。[pronoun]表示这让[pronoun]想起了[era]时期的类似情况，并对此发表了自己的见解。",
            "[name]，这位[era]的著名[field]，对'[content]'表现出了浓厚的兴趣。[pronoun]分享了[pronoun]在[field]领域的经验，并提出了一些独到的见解。"
        ]
        
        let template = templates.randomElement()!
        
        let pronoun = ["他", "她"].randomElement()!
        
        return template
            .replacingOccurrences(of: "[name]", with: character.name)
            .replacingOccurrences(of: "[field]", with: character.profession)
            .replacingOccurrences(of: "[era]", with: character.era)
            .replacingOccurrences(of: "[content]", with: contentText.count > 20 ? String(contentText.prefix(20)) + "..." : contentText)
            .replacingOccurrences(of: "[pronoun]", with: pronoun)
    }
}

/**
 * 图片选择器
 * 使用UIKit的UIImagePickerController来选择图片
 */
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    let maxSelections: Int
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                // 检查是否已达到最大选择数
                if parent.selectedImages.count < parent.maxSelections {
                    parent.selectedImages.append(image)
                }
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// 添加弹性按钮样式
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// 发布按钮专用弹性效果
struct SpringyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// 增强型弹性按钮样式 - 更现代的交互效果
struct EnhancedBouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// 增强型发布按钮样式 - 更丰富的动画效果
struct EnhancedSpringyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .brightness(configuration.isPressed ? -0.1 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

/**
 * 增强型滚动视图
 * 用于改善水平滚动体验，提供视觉指引
 */
struct EnhancedScrollView<Content: View>: View {
    let title: String
    let content: Content
    @State private var scrollOffset: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    private var hasMoreContent: Bool {
        return contentWidth > containerWidth && scrollOffset < contentWidth - containerWidth
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary.opacity(0.8))
                
                Spacer()
                
                ScrollIndicatorArrows(hasMoreContent: hasMoreContent)
                    .modifier(SlightPulseAnimation(isActive: hasMoreContent))
            }
            .padding(.horizontal, 2)
            
            ScrollViewOffsetTracker(scrollOffset: $scrollOffset) {
                ScrollView(.horizontal, showsIndicators: false) {
                    content
                        .background(
                            GeometryReader { contentGeometry in
                                Color.clear
                                    .onAppear {
                                        contentWidth = contentGeometry.size.width
                                    }
                                    .onChange(of: contentGeometry.size.width) { _, newWidth in
                                        contentWidth = newWidth
                                    }
                            }
                        )
                }
                .coordinateSpace(name: LayoutNamespace.scrollView)
            }
            .background(
                GeometryReader { containerGeometry in
                    Color.clear
                        .onAppear {
                            containerWidth = containerGeometry.size.width
                        }
                        .onChange(of: containerGeometry.size.width) { _, newWidth in
                            containerWidth = newWidth
                        }
                }
            )
        }
    }
}

/**
 * 滚动指示箭头
 * 提供视觉提示，指示有更多内容可以水平滚动
 */
struct ScrollIndicatorArrows: View {
    let hasMoreContent: Bool
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(hasMoreContent ? 0.6 - Double(index) * 0.15 : 0.2))
            }
        }
    }
}

/**
 * 轻微脉冲动画修饰器
 * 为滚动指示器提供精细的视觉反馈
 */
struct SlightPulseAnimation: ViewModifier {
    let isActive: Bool
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing && isActive ? 1.1 : 1.0)
            .onAppear {
                if isActive {
                    withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue && !isPulsing {
                    withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                } else if !newValue {
                    isPulsing = false
                }
            }
    }
}

/**
 * 滚动视图偏移量跟踪器
 * 跟踪水平滚动视图的滚动位置
 */
struct ScrollViewOffsetTracker<Content: View>: View {
    @Binding var scrollOffset: CGFloat
    let content: Content
    
    init(scrollOffset: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
        self._scrollOffset = scrollOffset
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
            
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: PublishPanelScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .global).minX * -1
                    )
            }
        }
        .onPreferenceChange(PublishPanelScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
        }
    }
}

/**
 * 滚动偏移量首选项键
 */
struct PublishPanelScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/**
 * 布局命名空间
 * 用于统一管理视图中使用的协调空间名称
 */
enum LayoutNamespace {
    static let scrollView = "horizontal-scroll-view"
    static let eraSelector = "era-selector"
    static let contentInput = "content-input"
    static let previewSection = "preview-section"
}

// 添加视图扩展以支持TextEditor的placeholder
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

/**
 * UITextView的SwiftUI包装器
 * 使用UIKit原生的UITextView来确保可靠的文本输入
 */
struct PublishPanelTextView: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var isFirstResponder: Bool = false
    var onTap: (() -> Void)?
    
    // 从SwiftUI向UIKit传递数据使用的协调器
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: PublishPanelTextView
        var didBecomeFirstResponder = false
        
        init(_ parent: PublishPanelTextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            // 当开始编辑时，移除占位符样式
            textView.textColor = .black
            if textView.text == parent.placeholder {
                textView.text = ""
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            // 如果文本为空，恢复占位符
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = UIColor.lightGray
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        
        // 基本设置
        textView.backgroundColor = .white
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = UIColor.black
        textView.tintColor = UIColor.systemBlue // 光标颜色
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.showsVerticalScrollIndicator = false
        
        // 设置占位符
        if text.isEmpty {
            textView.text = placeholder
            textView.textColor = UIColor.lightGray
        } else {
            textView.text = text
            textView.textColor = UIColor.black
        }
        
        // 设置内边距，使文本不贴边显示
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        textView.textContainer.lineFragmentPadding = 0
        
        // 增强点击响应性
        if let tapAction = onTap {
            let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
            textView.addGestureRecognizer(tapGesture)
            context.coordinator.parent.onTap = tapAction
        }
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        // 更新文本内容 - 仅在值发生变化且用户没有正在编辑时更新
        if textView.text != text && !textView.isFirstResponder {
            textView.text = text.isEmpty && !textView.isFirstResponder ? placeholder : text
            textView.textColor = text.isEmpty && !textView.isFirstResponder ? UIColor.lightGray : UIColor.black
        }
        
        // 处理首次响应状态
        if isFirstResponder && !context.coordinator.didBecomeFirstResponder {
            textView.becomeFirstResponder()
            context.coordinator.didBecomeFirstResponder = true
        }
        
        // 强制重新绘制视图以确保文本可见
        textView.setNeedsDisplay()
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        return nil // 让SwiftUI决定大小
    }
}

extension PublishPanelTextView.Coordinator {
    @objc func handleTap() {
        if let onTap = parent.onTap {
            onTap()
        }
    }
}

/**
 * 文本显示和输入组件
 * 用于解决UIKitTextView在失去焦点时文本不显示的问题
 */
struct PanelTextDisplayView: View {
    @Binding var text: String
    var isFocused: Binding<Bool>
    var placeholder: String
    @State private var tappedCount: Int = 0 // 用于跟踪点击次数
    
    // 始终使用文本叠加模式，无需用户手动切换
    private let useTextOverlay: Bool = true
    
    // 新增初始化方法，接收FocusState参数
    init(text: Binding<String>, isFocused: FocusState<Bool>, placeholder: String) {
        self._text = text
        // 创建一个自定义Binding，读取FocusState的值，修改时同时设置FocusState
        self.isFocused = Binding<Bool>(
            get: { isFocused.wrappedValue },
            set: { newValue in
                isFocused.wrappedValue = newValue
            }
        )
        self.placeholder = placeholder
    }
    
    // 原始初始化方法，接收Binding参数
    init(text: Binding<String>, isFocused: Binding<Bool>, placeholder: String) {
        self._text = text
        self.isFocused = isFocused
        self.placeholder = placeholder
    }
    
    var body: some View {
        ZStack {
            // 背景
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
            
            // 边框 - 根据焦点状态更改边框颜色
            RoundedRectangle(cornerRadius: 16)
                .stroke(isFocused.wrappedValue ? Color.blue : Color.purple.opacity(0.8), lineWidth: 2)
            
            // 简化设计：移除多余的调试信息和按钮，仅在需要时显示必要信息
            if !text.isEmpty {
                // 顶部内容长度指示器 - 只显示字数，不显示其他调试信息
                HStack {
                    Spacer()
                    Text("\(text.count)字")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                        .padding(.trailing, 12)
                }
                .allowsHitTesting(false)
            }
            
            // 构建双层输入系统：透明的PublishPanelTextView用于输入 + Text视图用于显示
            
            // 1. 主输入层 - 透明的PublishPanelTextView接收输入
            PublishPanelTextView(
                text: $text,
                placeholder: placeholder,
                isFirstResponder: isFocused.wrappedValue,
                onTap: {
                    // 触发点击事件
                    isFocused.wrappedValue = true
                    tappedCount += 1
                }
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .opacity(0.05) // 几乎透明，仅用于接收输入
            
            // 2. 显示层 - 文本内容叠加层，专门负责显示文本
            if useTextOverlay {
                ScrollView {
                    Text(text.isEmpty ? " " : text) // 确保即使内容为空也有高度
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                }
                .padding(.vertical, 12)
                .allowsHitTesting(false) // 禁止点击，让事件穿透到输入层
            }
            
            // 占位文本 - 只在文本为空且无焦点时显示
            if text.isEmpty && !isFocused.wrappedValue {
                VStack {
                    Text(placeholder)
                        .font(.system(size: 18))
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.top, 16)
                        .padding(.leading, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                }
                .allowsHitTesting(false) // 确保点击可以穿透占位文本
            }
            
            // 移除所有多余的状态指示器，让界面更加简洁
        }
        .frame(height: 180)
        .contentShape(Rectangle())
        .onTapGesture { // 整体的点击手势，仅当PublishPanelTextView未能响应时触发
            forceFocus()
        }
    }
    
    // 强制设置焦点
    private func forceFocus() {
        isFocused.wrappedValue = true
        tappedCount += 1
        
        // 在点击视图后主动尝试激活文本输入
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

/**
 * 包装原生TextEditor的视图
 * 通过手动管理焦点状态避免FocusState兼容性问题
 */
struct NativeTextEditorView: View {
    @Binding var text: String
    var isActive: Binding<Bool>
    
    // 用于直接控制文本视图的引用
    @State private var textViewActive = false
    
    var body: some View {
        ZStack {
            // 原生TextEditor
            TextEditor(text: $text)
                .foregroundColor(.black)
                .background(Color.white)
                .font(.system(size: 18))
                .onTapGesture {
                    isActive.wrappedValue = true
                    textViewActive = true
                }
        }
        .onAppear {
            // 初始化时同步焦点状态
            textViewActive = isActive.wrappedValue
            
            // 如果初始状态是激活的，尝试激活文本视图
            if isActive.wrappedValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        // 使用onReceive替代onChange，以提高不同iOS版本的兼容性
        .onReceive(Just(isActive.wrappedValue)) { newValue in
            if newValue != textViewActive {
                textViewActive = newValue
                // 根据新的焦点状态设置响应者
                if newValue {
                    UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                } else {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }
}

/**
 * 全屏图片查看器
 * 支持图片缩放和左右滑动切换
 */
public struct ImageFullScreenViewer: View {
    let images: [UIImage]
    @State private var currentIndex: Int
    @Binding var isPresented: Bool
    
    public init(images: [UIImage], initialIndex: Int, isPresented: Binding<Bool>) {
        self.images = images
        self._currentIndex = State(initialValue: initialIndex)
        self._isPresented = isPresented
    }
    
    public var body: some View {
        ZStack {
            // 背景
            Color.black.edgesIgnoringSafeArea(.all)
            
            // 内容
            VStack(spacing: 0) {
                // 顶部控制栏
                HStack {
                    // 关闭按钮
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // 页码指示器
                    Text("\(currentIndex + 1) / \(images.count)")
                        .foregroundColor(.white)
                        .font(.system(size: 15))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(15)
                }
                .padding()
                
                // 图片显示区域
                TabView(selection: $currentIndex) {
                    ForEach(0..<images.count, id: \.self) { index in
                        ZoomableImage(image: images[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            // 添加触感反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
}

/**
 * 可缩放图片视图
 * 支持双指缩放和拖动
 */
public struct ZoomableImage: View {
    let image: UIImage
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    public init(image: UIImage) {
        self.image = image
    }
    
    var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale = min(max(scale * delta, 1), 4)
            }
            .onEnded { _ in
                lastScale = 1.0
                if scale < 1.1 {
                    withAnimation {
                        scale = 1.0
                        offset = .zero
                    }
                }
            }
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let newOffset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                offset = newOffset
            }
            .onEnded { _ in
                lastOffset = offset
                if scale < 1.1 {
                    withAnimation {
                        offset = .zero
                    }
                }
            }
    }
    
    var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    if scale > 1.0 {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    } else {
                        scale = 2.0
                    }
                }
                
                // 添加触感反馈
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
    }
    
    public var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .offset(offset)
            .gesture(SimultaneousGesture(magnificationGesture, dragGesture))
            .gesture(doubleTapGesture)
            .edgesIgnoringSafeArea(.all)
    }
}

/**
 * 全屏图片查看器 - 支持图片ID
 * 用于显示用户上传的图片
 */
struct PostImageFullScreenViewer: View {
    let imageIds: [String]
    @State private var currentIndex: Int
    @Binding var isPresented: Bool
    @State private var loadedImages: [Int: UIImage] = [:]
    @State private var isLoading: [Int: Bool] = [:]
    
    init(imageIds: [String], initialIndex: Int, isPresented: Binding<Bool>) {
        self.imageIds = imageIds
        self._currentIndex = State(initialValue: initialIndex)
        self._isPresented = isPresented
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.edgesIgnoringSafeArea(.all)
            
            // 内容
            VStack(spacing: 0) {
                // 顶部控制栏
                HStack {
                    // 关闭按钮
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // 页码指示器
                    Text("\(currentIndex + 1) / \(imageIds.count)")
                        .foregroundColor(.white)
                        .font(.system(size: 15))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(15)
                }
                .padding()
                
                // 图片显示区域
                TabView(selection: $currentIndex) {
                    ForEach(0..<imageIds.count, id: \.self) { index in
                        ZStack {
                            if let image = loadedImages[index] {
                                // 显示已加载的图片
                                ZoomableImage(image: image)
                                    .tag(index)
                            } else if isLoading[index] == true {
                                // 显示加载中状态
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            } else {
                                // 显示加载失败状态
                                VStack(spacing: 12) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("无法加载图片")
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Button("重试") {
                                        loadImage(at: index)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                                }
                            }
                        }
                        .tag(index)
                        .onAppear {
                            loadImage(at: index)
                            
                            // 预加载下一张图片
                            if index + 1 < imageIds.count {
                                loadImage(at: index + 1)
                            }
                            
                            // 预加载上一张图片
                            if index - 1 >= 0 {
                                loadImage(at: index - 1)
                            }
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            // 添加触感反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // 加载当前图片
            loadImage(at: currentIndex)
        }
    }
    
    // 加载图片
    private func loadImage(at index: Int) {
        // 检查图片是否已加载
        if loadedImages[index] != nil || isLoading[index] == true {
            return
        }
        
        // 设置加载状态
        isLoading[index] = true
        
        // 获取图片ID
        let imageId = imageIds[index]
        
        // 在后台线程加载图片
        DispatchQueue.global(qos: .userInitiated).async {
            let image: UIImage?
            
            // 检查是否是用户上传的图片
            if imageId.contains("_image_") {
                // 从ImageManager获取图片
                image = ImageManager.shared.getImage(withId: imageId)
            } else {
                // 从资源中获取图片
                image = UIImage(named: imageId)
            }
            
            // 在主线程更新UI
            DispatchQueue.main.async {
                if let loadedImage = image {
                    loadedImages[index] = loadedImage
                }
                isLoading[index] = false
            }
        }
    }
}