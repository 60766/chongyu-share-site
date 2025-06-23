import SwiftUI
import PhotosUI
import UIKit

/**
 * 编辑帖子视图
 * 用于用户编辑自己发布的帖子
 * 支持编辑文本内容和图片
 */
struct EditPostView: View {
    // 要编辑的帖子
    let post: UserPostModel
    
    // 关闭回调
    var onClose: () -> Void
    
    // 更新回调
    var onUpdate: (String, [UIImage]) -> Void
    
    // MARK: - 状态变量
    @State private var editedContent: String = ""
    @State private var selectedImages: [UIImage] = []
    @State private var shouldShowImagePicker: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showingFullScreenImage: Bool = false
    @State private var previewingImageIndex: Int = 0
    @State private var isInitialized: Bool = false
    @State private var showConfirmDiscard: Bool = false
    @State private var hasUnsavedChanges: Bool = false
    @State private var textViewRef: UITextView? = nil
    
    // 拖拽相关状态
    @State private var isDragging: Bool = false
    @State private var draggedIndex: Int? = nil
    @State private var currentDropIndex: Int? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var imagePositions: [Int: CGRect] = [:] // 存储每个图片的实际位置
    @State private var needsPositionRefresh: Bool = false // 标记是否需要刷新位置
    @State private var overlapAreas: [Int: CGFloat] = [:] // 存储每个图片的重叠面积
    
    // 环境值
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    // 添加新的状态变量
    @State private var showDiscardChangesAlert: Bool = false
    
    // 初始化方法
    init(post: UserPostModel, onClose: @escaping () -> Void, onUpdate: @escaping (String, [UIImage]) -> Void) {
        self.post = post
        self.onClose = onClose
        self.onUpdate = onUpdate
        _editedContent = State(initialValue: post.content)
        print("EditPostView初始化: 帖子ID=\(post.id), 内容长度=\(post.content.count)")
    }
    
    // 主题颜色
    private var primaryColor: Color {
        Color(red: 130/255, green: 120/255, blue: 220/255)
    }
    
    // 背景颜色
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(.systemBackground)
    }
    
    // 次要文本颜色 - 增加统一的次要文本颜色
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color(.systemGray) : Color(.systemGray2)
    }
    
    // 边框颜色 - 统一边框颜色
    private var borderColor: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray4)
    }
    
    // 检查是否有未保存的更改
    private var hasChanges: Bool {
        editedContent != post.content || selectedImages.count != post.images.count
    }
    
    // 检查是否有内容
    private var hasContent: Bool {
        !editedContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色 - 使用系统背景色以保持一致性
                backgroundColor
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    if isInitialized {
                        // 内容区域
                        ScrollView {
                            VStack(spacing: 16) {
                                // 内容编辑区 - 使用自定义文本编辑器
                                VStack(alignment: .leading, spacing: 10) {
                                    // 使用自定义文本编辑器替代TextEditor
                                    CustomTextEditor(
                                        text: $editedContent,
                                        font: .systemFont(ofSize: 16),
                                        textColor: colorScheme == .dark ? .white : .black,
                                        backgroundColor: colorScheme == .dark ? UIColor.systemGray6 : UIColor.systemBackground,
                                        onTextViewCreated: { textView in
                                            // 使用Task避免在视图更新期间修改状态
                                            Task { @MainActor in
                                                textViewRef = textView
                                            }
                                        }
                                    )
                                    .frame(minHeight: 120, maxHeight: 200)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(primaryColor.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                                    .onChange(of: editedContent) { oldValue, newValue in
                                        hasUnsavedChanges = hasChanges
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 10)
                                
                                // 图片功能区 - 符合iOS设计规范
                                VStack(alignment: .leading, spacing: 12) {
                                    // 图片区域标题
                                    HStack {
                                        Text("图片")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(secondaryTextColor)
                                        
                                        Spacer()
                                        
                                        // 添加调试按钮
                                        Button(action: debugPositions) {
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.trailing, 8)
                                        .opacity(0.7)
                                        
                                        if !selectedImages.isEmpty {
                                            Text("\(selectedImages.count)/9")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(secondaryTextColor)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    
                                    // 图片网格 - 包含已选择图片和添加按钮
                                    ZStack {
                                        LazyVGrid(columns: [
                                            GridItem(.adaptive(minimum: 75, maximum: 85), spacing: 10)
                                        ], spacing: 10) {
                                            // 已选择的图片
                                            ForEach(0..<selectedImages.count, id: \.self) { index in
                                                imageCell(for: selectedImages[index], at: index)
                                                    .overlay(
                                                        // 拖拽激活时显示的高亮效果
                                                        ZStack {
                                                            if isDragging && currentDropIndex == index && draggedIndex != index {
                                                                RoundedRectangle(cornerRadius: 8)
                                                                    .stroke(primaryColor, lineWidth: 2)
                                                                    .background(
                                                                        RoundedRectangle(cornerRadius: 8)
                                                                            .fill(primaryColor.opacity(0.15))
                                                                    )
                                                            }
                                                        }
                                                        .animation(.easeInOut(duration: 0.2), value: currentDropIndex)
                                                    )
                                                    .background(
                                                        GeometryReader { geometry in
                                                            Color.clear
                                                                .preference(key: ImagePositionPreferenceKey.self, value: [ImagePosition(id: index, frame: geometry.frame(in: .named("dragContainer")))])
                                                        }
                                                    )
                                                    .id("image-\(index)-\(selectedImages.count)") // 确保在图片数量变化时重新创建视图
                                            }
                                            
                                            // 添加图片按钮 - 显示在所有图片后面
                                            Button(action: { shouldShowImagePicker = true }) {
                                                VStack(spacing: 4) {
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(borderColor, style: StrokeStyle(lineWidth: 1, dash: [5]))
                                                            .frame(width: 75, height: 75)
                                                            .background(
                                                                RoundedRectangle(cornerRadius: 8)
                                                                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6).opacity(0.2))
                                                                )
                                                            
                                                        VStack(spacing: 5) {
                                                            Image(systemName: "plus.circle.fill")
                                                                .font(.system(size: 22))
                                                                .foregroundColor(primaryColor)
                                                            
                                                            Text("添加图片")
                                                                .font(.system(size: 11, weight: .medium))
                                                                .foregroundColor(secondaryTextColor)
                                                        }
                                                    }
                                                }
                                            }
                                            .buttonStyle(EditPostButtonStyle())
                                            .disabled(selectedImages.count >= 9)
                                        }
                                        .padding(.horizontal, 16)
                                        .coordinateSpace(name: "dragContainer")
                                        .id("imageGrid-\(selectedImages.count)") // 添加ID，确保在图片数量变化时重新布局
                                        
                                        // 拖拽中的图片 - 放在ZStack最上层
                                        if isDragging, let draggedIndex = draggedIndex, draggedIndex < selectedImages.count {
                                            Image(uiImage: selectedImages[draggedIndex])
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 75, height: 75)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(primaryColor, lineWidth: 2)
                                                )
                                                .position(
                                                    x: (imagePositions[draggedIndex]?.midX ?? 0) + dragOffset.width,
                                                    y: (imagePositions[draggedIndex]?.midY ?? 0) + dragOffset.height
                                                )
                                                .zIndex(100) // 确保在最上层
                                        }
                                    }
                                }
                                
                                // 拖拽提示
                                if selectedImages.count > 1 {
                                    Text("长按图片可拖拽调整顺序")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(secondaryTextColor.opacity(0.8))
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.top, 6)
                                        .padding(.bottom, 2)
                                }
                                
                                Spacer(minLength: 16)
                            }
                            .padding(.bottom, 60)
                        }
                        // 在拖拽过程中禁用滚动
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    // 空实现，仅用于在拖拽状态下捕获滚动手势
                                }
                                .onEnded { _ in
                                    // 空实现
                                }
                                .exclusively(
                                    before: TapGesture()
                                        .onEnded { _ in }
                                )
                        )
                        .allowsHitTesting(!isDragging) // 在拖拽过程中禁用滚动视图的交互
                        
                        // 底部操作区 - 符合iOS设计规范
                        VStack {
                            HStack(spacing: 16) {
                                cancelButton()
                                
                                saveButton()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(backgroundColor)
                        }
                        .background(backgroundColor)
                        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: -1)
                    } else {
                        // 加载中状态 - 符合iOS设计规范
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.3)
                                .tint(primaryColor)
                            
                            Text("正在加载帖子内容...")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .navigationTitle("编辑动态")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(colorScheme, for: .navigationBar)
                .toolbarBackground(backgroundColor, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("编辑动态")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Color(.darkGray))
                            .padding(.bottom, 4)
                    }
                }
                .onPreferenceChange(ImagePositionPreferenceKey.self) { positions in
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
            .discardChangesAlert(
                isPresented: $showDiscardChangesAlert,
                primaryColor: primaryColor,
                onContinue: { /* 继续编辑，不需要额外操作 */ },
                onDiscard: { onClose() }
            )
            .onAppear {
                // 确保内容已正确设置
                print("EditPostView出现: 内容长度=\(editedContent.count), 原帖子内容长度=\(post.content.count)")
                
                // 延迟加载，确保视图已完全准备好
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // 加载已有图片
                    loadExistingImages()
                    
                    // 标记为已初始化
                    isInitialized = true
                    
                    // 延迟更新图片位置，确保布局已完成
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // 强制刷新一次位置
                        needsPositionRefresh = true
                    }
                    
                    // 自动聚焦到文本编辑器
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // 使用保存的引用聚焦
                        if let textView = textViewRef {
                            textView.becomeFirstResponder()
                        }
                    }
                }
            }
            .sheet(isPresented: $shouldShowImagePicker) {
                PHImagePicker(selectedImages: $selectedImages) { newImages in
                    // 不要替换原有图片，而是追加新选择的图片
                    hasUnsavedChanges = hasChanges
                }
            }
            .fullScreenCover(isPresented: $showingFullScreenImage) {
                // 使用符合iOS设计的图片查看器
                SimpleImageViewer(
                    image: selectedImages[previewingImageIndex],
                    onClose: { showingFullScreenImage = false }
                )
            }
            .alert("保存失败", isPresented: $showingError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .overlay(
                Group {
                    if isSubmitting {
                        // 提交中遮罩 - 减弱模糊效果
                        ZStack {
                            Color.black.opacity(0.3)
                                .edgesIgnoringSafeArea(.all)
                            
                            VStack(spacing: 14) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(1.3)
                                    .tint(primaryColor)
                                
                                Text("正在保存...")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(22)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.black.opacity(0.7))
                            )
                        }
                    }
                }
            )
            .interactiveDismissDisabled(hasUnsavedChanges)
        }
        .presentationDetents([.height(550), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Material.regularMaterial)
        .presentationCornerRadius(24)
    }
    
    // 图片单元格
    private func imageCell(for image: UIImage, at index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            // 图片
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 75, height: 75)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                .contentShape(Rectangle())
                .opacity(isDragging && index == draggedIndex ? 0.0 : 1.0) // 完全透明，使原图不可见
                .scaleEffect(isDragging && currentDropIndex == index ? 1.05 : 1.0) // 当作为目标时略微放大
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentDropIndex) // 添加动画
                .onTapGesture {
                    previewingImageIndex = index
                    showingFullScreenImage = true
                }
                // 使用简单直接的长按手势
                .onLongPressGesture(minimumDuration: 0.2, maximumDistance: 50) {
                    // 这个闭包在长按结束后触发，但我们需要在长按开始时就触发拖拽
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
                // 添加拖拽手势，设置高优先级
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("dragContainer"))
                        .onChanged { value in
                            // 只有在拖拽模式下才处理拖拽
                            if isDragging && draggedIndex == index {
                                // 更新拖拽偏移 - 使用Task避免在视图更新期间修改状态
                                Task { @MainActor in
                                    self.dragOffset = value.translation
                                    
                                    // 使用拖拽位置检测目标
                                    findDropTarget(dragPosition: value.location)
                                }
                            }
                        }
                        .onEnded { value in
                            // 只有在拖拽模式下才处理拖拽结束
                            if isDragging && draggedIndex == index {
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
                        }
                )
            
            // 删除按钮 - 符合iOS设计语言
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    removeImage(at: index)
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.7))
                        .frame(width: 20, height: 20)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(3)
            .opacity(isDragging && index == draggedIndex ? 0.0 : 1.0) // 拖动时隐藏删除按钮
        }
        .transition(.scale(scale: 0.8).combined(with: .opacity))
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
            let distanceThreshold: CGFloat = 75
            
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
            
            // 执行交换 - 只交换两张图片的位置
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                // 交换图片
                selectedImages.swapAt(draggedIndex, dropIndex)
                
                // 标记为有未保存的更改
                hasUnsavedChanges = true
            }
            
            // 交换成功触觉反馈
            let feedback = UIImpactFeedbackGenerator(style: .heavy)
            feedback.impactOccurred()
            
            // 延迟刷新位置信息，确保UI已更新
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
            self.needsPositionRefresh = true
        }
    }
    
    // 移除图片
    private func removeImage(at index: Int) {
        withAnimation {
            selectedImages.remove(at: index)
            hasUnsavedChanges = hasChanges
            
            // 图片数量变化后，标记需要刷新位置
            needsPositionRefresh = true
        }
    }
    
    // 加载已有图片
    private func loadExistingImages() {
        // 这里加载原帖子中的图片
        for imageId in post.images {
            if let image = ImageManager.shared.getImage(withId: imageId) {
                selectedImages.append(image)
            }
        }
        
        // 图片加载完成后，标记需要刷新位置
        if !selectedImages.isEmpty {
            needsPositionRefresh = true
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
                    // 如果有缺失的位置，稍后再次尝试刷新
                    try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
                    self.needsPositionRefresh = true
                    break
                }
            }
        }
    }
    
    // 提交编辑
    private func submitEdit() {
        // 验证输入 - 允许只有图片的情况
        let trimmedContent = editedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedContent.isEmpty && selectedImages.isEmpty {
            showErrorMessage("内容或图片至少需要一项")
            return
        }
        
        isSubmitting = true
        
        // 触发触觉反馈
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // 调用更新回调
        onUpdate(trimmedContent, selectedImages)
        
        // 关闭编辑视图
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSubmitting = false
            hasUnsavedChanges = false
            onClose()
        }
    }
    
    // 显示错误信息
    private func showErrorMessage(_ message: String) {
        self.errorMessage = message
        self.showingError = true
    }
    
    // 添加调试按钮动作
    private func debugPositions() {
        // 强制刷新位置
        for index in 0..<selectedImages.count {
            if let frame = imagePositions[index] {
                print("图片 \(index) 位置: \(frame)")
            } else {
                print("图片 \(index) 位置未收集")
            }
        }
        
        // 重新触发位置收集
        needsPositionRefresh = true
    }
    
    // 保存按钮
    private func saveButton() -> some View {
        let isDisabled = !isInitialized || (!hasContent && selectedImages.isEmpty) || isSubmitting
        let buttonColor = isDisabled ? Color.gray.opacity(0.8) : primaryColor
        let shadowColor = isDisabled ? Color.clear : primaryColor.opacity(0.3)
        
        return Button(action: submitEdit) {
            Text("保存")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(buttonColor)
                        .shadow(color: shadowColor, radius: 3, x: 0, y: 2)
                )
        }
        .disabled(isDisabled)
    }
    
    // 取消按钮
    private func cancelButton() -> some View {
        Button(action: {
            if hasUnsavedChanges {
                showDiscardChangesAlert = true
            } else {
                onClose()
            }
        }) {
            Text("取消")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(.darkGray))
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                )
        }
    }
}

/**
 * 简单图片查看器
 * 极简版的图片查看器，避免复杂组件引用问题
 */
struct SimpleImageViewer: View {
    let image: UIImage
    let onClose: () -> Void
    
    // 添加缩放状态
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.edgesIgnoringSafeArea(.all)
            
            // 图片
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    // 双击缩放手势
                    TapGesture(count: 2).onEnded {
                        withAnimation(.spring()) {
                            if scale > 1 {
                                // 重置缩放和偏移
                                scale = 1.0
                                offset = .zero
                            } else {
                                // 放大到2倍
                                scale = 2.0
                            }
                            lastScale = scale
                            lastOffset = offset
                        }
                    }
                )
                .gesture(
                    // 拖动手势
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .gesture(
                    // 缩放手势
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            // 限制最小和最大缩放
                            scale = min(max(scale * delta, 0.5), 4.0)
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                        }
                )
                .edgesIgnoringSafeArea(.all)
            
            // 顶部控制栏
            VStack {
                HStack {
                    // 关闭按钮
                    Button(action: onClose) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(20)
                    
                    Spacer()
                    
                    // 重置按钮
                    Button(action: {
                        withAnimation(.spring()) {
                            scale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(20)
                    .opacity(scale != 1.0 || offset != .zero ? 1 : 0)
                }
                
                Spacer()
            }
        }
    }
}

// 按钮样式
struct EditPostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

/**
 * 自定义文本编辑器
 * 使用UIViewRepresentable包装UITextView以获得更好的光标控制
 */
struct CustomTextEditor: UIViewRepresentable {
    @Binding var text: String
    var font: UIFont = .systemFont(ofSize: 16)
    var textColor: UIColor = .label
    var isEditable: Bool = true
    var backgroundColor: UIColor = .clear
    var onTextViewCreated: ((UITextView) -> Void)? = nil
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = font
        textView.textColor = textColor
        textView.backgroundColor = backgroundColor
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        textView.layer.cornerRadius = 14
        textView.text = text
        
        // 回调通知创建完成
        if let onCreated = onTextViewCreated {
            onCreated(textView)
        }
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // 只有当文本不同时才更新，避免光标位置重置
        if uiView.text != text {
            uiView.text = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CustomTextEditor
        
        init(_ parent: CustomTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}

// 辅助方法：获取包含特定UIImage的UIImageView
extension UIView {
    static func getEnclosingView(for view: UIView?, containingView: UIImage) -> UIView? {
        guard let view = view else { return nil }
        
        // 检查当前视图是否是UIImageView并包含目标图片
        if let imageView = view as? UIImageView, imageView.image == containingView {
            return imageView
        }
        
        // 递归检查所有子视图
        for subview in view.subviews {
            if let result = getEnclosingView(for: subview, containingView: containingView) {
                return result
            }
        }
        
        return nil
    }
}

// 添加位置偏好键
struct ImagePosition: Equatable {
    let id: Int
    let frame: CGRect
}

struct ImagePositionPreferenceKey: PreferenceKey {
    static var defaultValue: [ImagePosition] = []
    
    static func reduce(value: inout [ImagePosition], nextValue: () -> [ImagePosition]) {
        value.append(contentsOf: nextValue())
    }
}

// 添加全局弹窗视图修饰符
extension View {
    func discardChangesAlert(
        isPresented: Binding<Bool>,
        primaryColor: Color,
        onContinue: @escaping () -> Void,
        onDiscard: @escaping () -> Void
    ) -> some View {
        self.overlay(
            ZStack {
                if isPresented.wrappedValue {
                    // 半透明背景覆盖整个屏幕
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            // 点击背景不关闭对话框
                        }
                    
                    // 对话框
                    VStack(spacing: 0) {
                        // 标题和消息
                        VStack(spacing: 12) {
                            Text("放弃更改")
                                .font(.system(size: 17, weight: .semibold))
                                .padding(.top, 20)
                            
                            Text("您有未保存的更改，确定要放弃吗？")
                                .font(.system(size: 15))
                                .foregroundColor(Color(.systemGray))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 20)
                        }
                        
                        Divider()
                        
                        // 按钮
                        HStack(spacing: 0) {
                            Button {
                                isPresented.wrappedValue = false
                                onContinue()
                            } label: {
                                Text("继续编辑")
                                    .font(.system(size: 16))
                                    .foregroundColor(primaryColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            
                            Divider()
                            
                            Button {
                                isPresented.wrappedValue = false
                                onDiscard()
                            } label: {
                                Text("放弃更改")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                        }
                        .frame(height: 50)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.systemBackground))
                    )
                    .frame(width: UIScreen.main.bounds.width * 0.75)
                    .shadow(color: Color.black.opacity(0.1), radius: 10)
                }
            }
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(1000)
        )
    }
} 