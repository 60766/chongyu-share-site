import SwiftUI
import Combine
import UIKit

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
    /// 文本编辑器焦点状态
    @FocusState private var isTextEditorFocused: Bool
    
    // 时代选项
    private let eras = ["现代", "古代", "中世纪", "文艺复兴", "启蒙运动", "未来"]
    
    // 推荐角色视图
    private var characterRecommendationView: some View {
        PublishCharacterRecommendationView(
            contentText: contentText,
            selectedEra: selectedEra,
            selectedCharacters: $selectedCharacters
        )
    }
    
    // 虫洞能量指示器
    private var energyIndicatorView: some View {
        WormholeEnergyIndicator(
            contentText: contentText,
            characters: selectedCharacters
        )
    }
    
    var body: some View {
        ZStack {
            // 背景蒙版
            if isVisible {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        // 点击背景区域时隐藏键盘并关闭发布面板，但不重置状态
                        hideKeyboard()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isVisible = false
                        }
                        // 移除重置面板状态的代码，保留用户输入的内容
                    }
            }
            
            // 主面板
            VStack(spacing: 0) {
                Spacer()
                
                // 面板内容
                VStack(spacing: 0) {
                    // 顶部拖拽条
                    Rectangle()
                        .frame(width: 40, height: 4)
                        .foregroundColor(Color.gray.opacity(0.3))
                        .padding(.vertical, 12)
                    
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
                    Color(.systemBackground)
                        .appCornerRadius(24, corners: [.topLeft, .topRight])
                        .shadow(color: Color.black.opacity(0.1), radius: 10, y: -5)
                )
                .offset(y: isVisible ? 0 : UIScreen.main.bounds.height)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isVisible)
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
                    // 半透明背景蒙版
                    Color.black.opacity(0.2)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                    
                    VStack {
                        Spacer()
                        successToastView
                        Spacer().frame(height: 80)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isShowingSuccessToast)
        )
    }
    
    // 内容输入区域
    private var contentInputArea: some View {
        VStack(spacing: 12) {
            // 输入区域
            VStack {
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
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            }
            .frame(height: UIScreen.main.bounds.height * 0.2)
            
            // 功能按钮区 - 极简布局
            HStack(spacing: 10) {
                // 图片选择按钮 - 极简化
                Button(action: { showingImagePicker = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: selectedImages.isEmpty ? "photo" : "photo.fill")
                            .font(.system(size: 13, weight: .medium))
                        
                        if !selectedImages.isEmpty {
                            Text("\(selectedImages.count)")
                                .font(.system(size: 13, weight: .medium))
                        } else {
                            Text("图片")
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(selectedImages.isEmpty ? 0.08 : 0.12))
                    )
                    .foregroundColor(Color.blue.opacity(0.9))
                }
                
                Spacer()
                
                // 时代选择按钮 - 极简化
                Menu {
                    ForEach(eras, id: \.self) { era in
                        Button(era) {
                            selectedEra = era
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 13, weight: .medium))
                        Text(selectedEra)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.primaryColor.opacity(0.08))
                    )
                    .foregroundColor(Color.primaryColor.opacity(0.9))
                }
            }
            
            // 图片预览区域
            if !selectedImages.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    // 图片预览滚动区 - 极简设计
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(0..<selectedImages.count, id: \.self) { index in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: selectedImages[index])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 55, height: 55)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .onTapGesture {
                                            previewingImageIndex = index
                                            showingFullScreenImage = true
                                        }
                                    
                                    // 极简删除按钮
                                    Button(action: {
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                        
                                        _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
                                }
                            }
                        }
                        .padding(.vertical, 1)
                    }
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
            }
            
            energyIndicatorView
                .padding(.top, 2)
            
            characterRecommendationView
                .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedImages.count)
    }
    
    // 强制激活文本输入框
    private func forceActivateTextInput() {
        isTextEditorFocused = true
        
        // 使用轻微触感反馈提示用户输入框已激活
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // 尝试使用系统级方法激活第一响应者
        UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
        
        // 延迟再次尝试激活焦点
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isTextEditorFocused = true
        }
    }
    
    // 底部工具栏 - 优化设计
    private var bottomToolbar: some View {
        HStack {
            // 角色选择按钮 - 增大尺寸
            Button(action: {
                showingCharacterSelector = true
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: selectedCharacters.isEmpty ? "person.fill" : "person.2.fill")
                        .font(.system(size: 15, weight: .medium))
                    
                    Text(selectedCharacters.isEmpty ? "角色" : "角色")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(Color.primaryColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 8) 
                .background(
                    Capsule()
                        .fill(Color.primaryColor.opacity(0.1))
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(BouncyButtonStyle())
            
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
            
            // 发布按钮 - 增大尺寸
            Button(action: handlePublishButtonTapped) {
                HStack(spacing: 8) {
                    Text("发布")
                        .font(.system(size: 16, weight: .medium))
                    
                    if hasValidContent {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14, weight: .medium))
                            .offset(x: -1, y: -1)
                            .rotationEffect(.degrees(15))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(hasValidContent ? Color.primaryColor : Color.gray.opacity(0.3))
                )
                .foregroundColor(.white)
                .shadow(color: hasValidContent ? Color.primaryColor.opacity(0.2) : Color.clear, radius: 3, x: 0, y: 1)
            }
            .disabled(!hasValidContent)
            .buttonStyle(SpringyButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .padding(.bottom, 4) // 减小底部边距，提高位置
    }
    
    // 发布内容判断 - 文本不为空或有图片
    private var hasValidContent: Bool {
        !contentText.isEmpty || !selectedImages.isEmpty
    }
    
    // 处理发布按钮点击
    private func handlePublishButtonTapped() {
        // 触感反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        guard hasValidContent else { return }
        
        // 如果没有选择角色，自动添加推荐角色
        if selectedCharacters.isEmpty {
            autoSelectCharacters()
        }
        
        publishContent()
    }
    
    // 自动选择推荐角色
    private func autoSelectCharacters() {
        // 获取推荐角色
        let recommendedCharacters = PublishCharacterRecommendationView.getRecommendedCharacters(
            contentText: contentText,
            selectedEra: selectedEra,
            selectedCharacters: []
        )
        
        // 如果有推荐角色就使用前3个，否则随机选择
        if !recommendedCharacters.isEmpty {
            selectedCharacters = Array(recommendedCharacters.prefix(3))
        } else {
            selectedCharacters = selectRandomCharacters()
        }
        
        // 更新角色概率
        updateCharacterProbabilities()
    }
    
    // 随机选择角色
    private func selectRandomCharacters() -> [CharacterModel] {
        let allCharacters = CharacterModel.sampleCharacters
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
    private func publishContent() {
        // 确保概率总和为100%
        normalizeCharacterProbabilities()
        
        // 创建要发布的内容数据
        let postData = PostData(
            content: contentText,
            images: selectedImages,
            era: selectedEra,
            characters: selectedCharacters,
            characterProbabilities: getProbabilityDict(),
            publishMode: publishMode
        )
        
        // 将PostData转换为UserPostModel并添加到PostViewModel
        let userPost = createUserPostFromPostData(postData)
        
        // 添加到PostViewModel，使其显示在主页
        PostViewModel.shared.addPosts([userPost])
        
        // 发送通知，告知HomeView有新帖子
        NotificationCenter.default.post(
            name: NSNotification.Name("NewPostsGenerated"),
            object: nil,
            userInfo: ["count": 1]
        )
        
        // 生成可能回复的角色
        generatePotentialRespondingCharacters()
        
        // 先关闭发布面板
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isVisible = false
        }
        
        // 延迟一段时间后显示发布成功提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                isShowingSuccessToast = true
            }
            
            // 3秒后关闭提示
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    isShowingSuccessToast = false
                }
                
                // 成功发布后重置面板状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    resetPanelState()
                }
            }
        }
    }
    
    // 将PostData转换为UserPostModel
    private func createUserPostFromPostData(_ postData: PostData) -> UserPostModel {
        // 创建评论
        var comments: [DetailedCommentModel] = []
        
        // 为选中的角色创建初始评论
        for character in postData.characters {
            // 获取角色回复概率
            let probability = postData.characterProbabilities[character.id.uuidString] ?? 0
            
            // 如果概率大于0，添加评论
            if probability > 0 {
                let comment = DetailedCommentModel(
                    id: UUID(),
                    username: character.name,
                    userAvatar: character.avatar,
                    content: generateInitialComment(from: character, about: postData.content),
                    datePosted: Date().addingTimeInterval(Double.random(in: 60...300)), // 1-5分钟后
                    isVirtualCharacter: true,
                    characterID: character.id.uuidString,
                    likes: Int.random(in: 0...10),
                    isLikedByCurrentUser: false
                )
                comments.append(comment)
            }
        }
        
        // 处理图片 - 将UIImage转换为图片URL或标识符
        var imageIdentifiers: [String] = []
        for (index, image) in postData.images.enumerated() {
            // 生成唯一图片标识符
            let imageId = "\(postData.id)_image_\(index)"
            
            // 保存图片到本地存储或云存储
            if let savedImageId = saveImage(image, withId: imageId) {
                imageIdentifiers.append(savedImageId)
            }
        }
        
        // 创建用户帖子
        let userPost = UserPostModel(
            id: UUID(uuidString: postData.id) ?? UUID(),
            username: "当前用户", // 使用当前用户名
            userAvatar: "person.circle.fill", // 使用当前用户头像
            content: postData.content,
            images: imageIdentifiers, // 添加图片标识符
            datePosted: postData.timestamp,
            likes: 0,
            comments: comments,
            isLikedByCurrentUser: false,
            isBookmarkedByCurrentUser: false,
            contentType: "user_post", // 用户发布的内容
            source: "user" // 来源为用户
        )
        
        return userPost
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
    
    // 为角色生成初始评论
    private func generateInitialComment(from character: CharacterModel, about content: String) -> String {
        // 根据不同角色类型生成不同风格的评论
        let comments = [
            "作为\(character.profession)，我认为这个观点很有意思。",
            "从\(character.era)的角度来看，这确实值得思考。",
            "这让我想起了我在\(character.era)时期的一些经历。",
            "如果用\(character.profession)的视角分析，这个问题有更深层次的含义。",
            "我很欣赏你的想法，这在\(character.era)时期是很前卫的。"
        ]
        
        return comments.randomElement() ?? "这个观点很有趣，请继续分享。"
    }
    
    // 将概率转换为字典
    private func getProbabilityDict() -> [String: Int] {
        var dict = [String: Int]()
        for i in 0..<min(selectedCharacters.count, characterProbabilities.count) {
            dict[selectedCharacters[i].id.uuidString] = Int(characterProbabilities[i])
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
    
    // 生成可能回复的角色
    private func generatePotentialRespondingCharacters() {
        // 基于概率选择角色
        var selectedForResponse: [CharacterModel] = []
        
        // 确保概率总和正确
        normalizeCharacterProbabilities()
        
        // 基于概率添加角色
        for i in 0..<min(selectedCharacters.count, characterProbabilities.count) {
            let prob = Int(characterProbabilities[i])
            if Int.random(in: 1...100) <= prob {
                selectedForResponse.append(selectedCharacters[i])
            }
        }
        
        // 如果回复的角色不足3个，添加更多角色直到达到3个
        if selectedForResponse.count < 3 {
            // 首先从已选择但未被添加的角色中选择
            let remainingSelectedCharacters = selectedCharacters.filter { character in
                !selectedForResponse.contains { $0.id == character.id }
            }
            
            for character in remainingSelectedCharacters {
                if selectedForResponse.count >= 3 {
                    break
                }
                selectedForResponse.append(character)
            }
            
            // 如果仍然不足3个，从所有角色中随机添加
            if selectedForResponse.count < 3 {
                let allCharacters = CharacterModel.sampleCharacters
                let additionalNeeded = 3 - selectedForResponse.count
                
                // 过滤掉已经在回复列表中的角色
                let availableCharacters = allCharacters.filter { character in
                    !selectedForResponse.contains { $0.id == character.id }
                }
                
                // 随机选择额外角色
                var additionalCharacters: [CharacterModel] = []
                for _ in 0..<additionalNeeded {
                    if let randomCharacter = availableCharacters.filter({ character in
                        !additionalCharacters.contains { $0.id == character.id }
                    }).randomElement() {
                        additionalCharacters.append(randomCharacter)
                    }
                }
                
                selectedForResponse.append(contentsOf: additionalCharacters)
            }
        }
        
        // 更新状态
        potentialRespondingCharacters = selectedForResponse
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
        isTextEditorFocused = false  // 使用FocusState取消焦点
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // 多次尝试激活文本输入焦点
    private func activateTextInputWithMultipleAttempts() {
        // 标记TextDisplayView中使用的UIKitTextView组件应该被激活
        UIKitTextView.globalShouldActivate = true
        
        // 第一次尝试立即激活
        print("第一次尝试激活输入框")
        isTextEditorFocused = true
        
        // 延迟激活，确保文本视图已被正确渲染
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            print("第二次尝试激活输入框")
            self.isTextEditorFocused = true
            
            // 告诉系统当前第一响应者应该变为文本输入视图
            UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
            
            // 触感反馈，增强用户体验
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            // 第三次尝试，延迟500ms
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("第三次尝试激活输入框")
                self.isTextEditorFocused = true
                UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
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
        VStack(spacing: 16) {
            // 成功标题
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
                
                Text("发布成功！")
                    .font(.headline)
            }
            
            // 内容预览 - 如果有文本则显示文本，如果只有图片则显示图片数量
            if !contentText.isEmpty {
                Text(contentText)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            } else if !selectedImages.isEmpty {
                Text("已发布 \(selectedImages.count) 张图片")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 潜在回复角色
            if !potentialRespondingCharacters.isEmpty {
                VStack(spacing: 8) {
                    Text("这些角色可能会回复：")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(potentialRespondingCharacters.prefix(5)) { character in
                                VStack(spacing: 4) {
                                    characterAvatar(for: character)
                                        .frame(width: 40, height: 40)
                                    
                                    Text(character.name)
                                        .font(.system(size: 12))
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 12, y: 6)
        .padding(.horizontal, 40)
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
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
 * 角色推荐视图
 * 基于用户输入内容和选择的时代，推荐相关角色
 */
struct PublishCharacterRecommendationView: View {
    /// 内容文本
    let contentText: String
    /// 选中的时代
    let selectedEra: String
    /// 选中的角色
    @Binding var selectedCharacters: [CharacterModel]
    
    /// 推荐角色列表
    private var recommendedCharacters: [CharacterModel] {
        return PublishCharacterRecommendationView.getRecommendedCharacters(
            contentText: contentText,
            selectedEra: selectedEra,
            selectedCharacters: selectedCharacters
        )
    }
    
    /// 静态方法：获取推荐角色
    static func getRecommendedCharacters(contentText: String, selectedEra: String, selectedCharacters: [CharacterModel]) -> [CharacterModel] {
        // 简单推荐算法，实际应用中可实现更复杂的推荐逻辑
        let allCharacters = CharacterModel.sampleCharacters
        
        // 如果内容为空，返回按时代过滤的随机角色
        if contentText.isEmpty {
            let eraFilteredCharacters = allCharacters.filter { character in
                // 排除已选角色
                if isCharacterAlreadySelected(character, in: selectedCharacters) {
                    return false
                }
                
                // 时代匹配
                return doesCharacterEraMatch(character.era, selectedEra: selectedEra)
            }
            
            // 随机选择不超过5个角色
            var randomCharacters: [CharacterModel] = []
            let shuffledCharacters = eraFilteredCharacters.shuffled()
            for character in shuffledCharacters {
                if randomCharacters.count >= 3 {
                    break
                }
                randomCharacters.append(character)
            }
            
            return randomCharacters
        }
        
        // 根据内容进行更智能的匹配
        // 1. 定义关键词类别
        let scienceKeywords = ["科学", "物理", "化学", "数学", "实验", "研究", "发现", "理论", "宇宙", "相对论", "量子"]
        let artKeywords = ["艺术", "绘画", "音乐", "雕塑", "创作", "美学", "色彩", "构图", "灵感", "表现", "风格"]
        let philosophyKeywords = ["哲学", "思想", "逻辑", "伦理", "道德", "存在", "真理", "意义", "价值", "认识论", "形而上学"]
        let literatureKeywords = ["文学", "诗歌", "小说", "散文", "戏剧", "创作", "写作", "语言", "表达", "情感", "意象"]
        let historicalKeywords = ["历史", "战争", "政治", "革命", "改革", "朝代", "时代", "文明", "帝国", "王朝", "统治"]
        
        // 2. 计算各类别匹配度
        let scienceScore = keywordsMatchScore(contentText, keywords: scienceKeywords)
        let artScore = keywordsMatchScore(contentText, keywords: artKeywords)
        let philosophyScore = keywordsMatchScore(contentText, keywords: philosophyKeywords)
        let literatureScore = keywordsMatchScore(contentText, keywords: literatureKeywords)
        let historicalScore = keywordsMatchScore(contentText, keywords: historicalKeywords)
        
        // 3. 根据类别匹配度过滤角色
        var matchedCharacters: [CharacterModel] = []
        let allScores: [(CharacterCategory, Double)] = [
            (.scientist, scienceScore),
            (.artist, artScore),
            (.philosopher, philosophyScore),
            (.writer, literatureScore),
            (.all, historicalScore)
        ].sorted { $0.1 > $1.1 }  // 按分数从高到低排序
        
        // 从每个高分类别中选择角色
        for (category, score) in allScores {
            // 只考虑分数大于0的类别
            if score <= 0 {
                continue
            }
            
            // 从该类别中找出符合条件的角色
            let filteredCharacters = allCharacters.filter { character in
                // 必须是该类别
                guard character.category == category else { return false }
                
                // 排除已选角色
                if isCharacterAlreadySelected(character, in: selectedCharacters) {
                    return false
                }
                
                // 时代匹配（如果不是跨时代角色，则需匹配所选时代）
                return doesCharacterEraMatch(character.era, selectedEra: selectedEra)
            }
            
            // 在该类别中最多选两个角色
            let categoryCharacters = filteredCharacters.prefix(2)
            matchedCharacters.append(contentsOf: categoryCharacters)
            
            // 如果已经有足够的角色，可以提前退出
            if matchedCharacters.count >= 3 {
                break
            }
        }
        
        // 如果没有找到足够的匹配角色，返回随机角色
        if matchedCharacters.isEmpty {
            return getRecommendedCharacters(contentText: "", selectedEra: selectedEra, selectedCharacters: selectedCharacters)
        }
        
        return Array(matchedCharacters.prefix(3))  // 最多返回3个角色
    }
    
    // 辅助方法：计算文本与关键词的匹配度
    private static func keywordsMatchScore(_ text: String, keywords: [String]) -> Double {
        var score = 0.0
        let textLower = text.lowercased()
        
        for keyword in keywords {
            if textLower.contains(keyword.lowercased()) {
                score += 1.0
            }
        }
        
        return score
    }
    
    // 辅助方法：检查角色是否已被选中
    private static func isCharacterAlreadySelected(_ character: CharacterModel, in selectedCharacters: [CharacterModel]) -> Bool {
        return selectedCharacters.contains { $0.id == character.id }
    }
    
    // 辅助方法：检查角色时代是否匹配
    private static func doesCharacterEraMatch(_ characterEra: String, selectedEra: String) -> Bool {
        if characterEra == "跨时代" {
            return true
        }
        return characterEra == selectedEra
    }
    
    // 视觉效果控制
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 标题区域
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 15))
                    .foregroundColor(Color.primaryColor)
                
                Text("推荐角色")
                    .font(.system(size: 14, weight: .medium))
                
                Spacer()
                
                Button(action: {
                    // 显示角色选择器
                }) {
                    HStack(spacing: 4) {
                        Text("更多")
                            .font(.system(size: 12))
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(Color.primaryColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 4)
            
            if recommendedCharacters.isEmpty {
                // 空状态提示
                Text("没有匹配的推荐角色")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
            } else {
                // 角色推荐卡片滚动视图
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(recommendedCharacters.enumerated()), id: \.element.id) { index, character in
                            characterCard(character: character, index: index)
                                // 移除依赖hover状态的动画
                                // .scaleEffect(hoverIndex == index ? 1.05 : 1.0)
                                // .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hoverIndex)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(height: 80)
                .onAppear {
                    // 添加微妙的动画效果
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isAnimating = true
                        }
                    }
                }
            }
        }
    }
    
    // 角色卡片视图
    private func characterCard(character: CharacterModel, index: Int) -> some View {
        let isSelected = selectedCharacters.contains { $0.id == character.id }
        
        return Button(action: {
            // 触感反馈
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            feedbackGenerator.impactOccurred()
            
            // 切换选择状态
            if isSelected {
                selectedCharacters.removeAll { $0.id == character.id }
            } else {
                selectedCharacters.append(character)
            }
        }) {
            VStack(spacing: 6) {
                // 角色头像
                ZStack {
                    // 背景圆形
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    character.category.color.opacity(0.15),
                                    character.category.color.opacity(0.25)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    // 角色首字
                    Text(String(character.name.prefix(1)))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(character.category.color)
                    
                    // 选中状态边框
                    if isSelected {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        character.category.color,
                                        character.category.color.opacity(0.6)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                        .frame(width: 48, height: 48)
                    }
                    
                    // 时代指示器 - 小标签
                    if character.era != "跨时代" && character.era == selectedEra {
                        Text("同期")
                            .font(.system(size: 8, weight: .medium))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.primaryColor.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .offset(y: 24)
                    }
                }
                .offset(y: isAnimating ? 0 : 10)
                .opacity(isAnimating ? 1 : 0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.7)
                    .delay(Double(index) * 0.1),
                    value: isAnimating
                )
                
                // 角色名称
                Text(character.name)
                    .font(.system(size: 12))
                    .fontWeight(isSelected ? .medium : .regular)
                    .foregroundColor(isSelected ? character.category.color : .primary)
                    .lineLimit(1)
            }
            .frame(width: 60)
            .contentShape(Rectangle())
            // 添加触摸时的动画效果，而不是依赖hover
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
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
            
            // 添加动画效果
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    isAnimating = true
                }
            }
        }
        .background(Color(.systemBackground))
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
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
        
        // 模拟延迟，然后进行创建角色操作
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // 这里应该跳转到创建角色的页面或弹出创建角色的表单
            print("创建新角色: \(defaultName)")
        }
    }
    
    // 过滤后的角色列表
    private var filteredCharacters: [CharacterModel] {
        var characters = CharacterModel.sampleCharacters
        
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
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
                    
                    // 角色首字
                    Text(String(character.name.prefix(1)))
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(character.category.color)
                    
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
 * 虫洞能量指示器 - 提高直观性和视觉吸引力
 */
struct WormholeEnergyIndicator: View {
    let contentText: String
    let characters: [CharacterModel]
    
    // 计算能量等级
    private var energyLevel: Int {
        // 修改计算规则：降低文本长度的阈值，使其更快响应输入
        let textFactor = min(contentText.count / 3, 30) // 每3个字符提供1点能量，最高30点
        let characterFactor = min(characters.count * 20, 40) // 每个角色提供20点能量，最高40点
        
        // 不同时代的角色会产生更高能量
        let uniqueEras = Set(characters.map { $0.era }).count
        let eraFactor = uniqueEras * 10 // 每个唯一时代提供10点能量
        
        // 额外因素：考虑文本内容是否包含关键词
        let keywordFactor = calculateKeywordFactor(text: contentText)
        
        let totalEnergy = textFactor + characterFactor + eraFactor + keywordFactor
        return min(totalEnergy / 20, 5) // 0-5级
    }
    
    // 计算关键词因素 - 检测文本中是否包含特定关键词
    private func calculateKeywordFactor(text: String) -> Int {
        let keywords = ["历史", "时代", "思想", "科学", "艺术", "哲学", "文化", "创新"]
        var factor = 0
        
        // 对每个出现的关键词给予5点能量
        for keyword in keywords {
            if text.contains(keyword) {
                factor += 5
            }
        }
        
        return min(factor, 20) // 最高20点能量
    }
    
    // 获取能量百分比值
    private var energyPercentage: Int {
        // 确保即使没有文本也显示至少15%的能量
        let basePercentage = 15
        let calculatedPercentage = energyLevel * 20
        
        // 如果有输入内容但计算值低于基础值，至少显示基础值
        if !contentText.isEmpty && calculatedPercentage < basePercentage {
            return basePercentage
        }
        
        return max(calculatedPercentage, basePercentage) // 确保不低于基础值
    }
    
    // 控制粒子动画
    @State private var animationPhase: CGFloat = 0
    
    // 粒子动画计时器
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
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
                
                // 填充条
                energyBarFill
                    .frame(width: nil)
                    .mask(
                        GeometryReader { geometry in
                            Rectangle()
                                .frame(width: geometry.size.width * CGFloat(energyPercentage) / 100)
                        }
                    )
                
                // 粒子效果 - 仅在能量足够时显示
                if energyPercentage > 20 {
                    energyParticles
                }
            }
            .frame(height: 10)
            .clipShape(Capsule())
            .onReceive(timer) { _ in
                withAnimation {
                    animationPhase += 0.05
                    if animationPhase > 1 {
                        animationPhase = 0
                    }
                }
            }
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
    
    // 能量粒子效果
    private var energyParticles: some View {
        ZStack {
            ForEach(0..<min(energyPercentage/10, 8), id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 2, height: 2)
                    .offset(
                        x: CGFloat(i * 12) + CGFloat(animationPhase) * 20,
                        y: CGFloat.random(in: -3...3)
                    )
                    .opacity(Double.random(in: 0.5...1.0))
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