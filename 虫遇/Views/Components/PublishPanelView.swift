import SwiftUI
import UIKit
// CreateCharacterView位于：Views/Components/Character/CreateCharacterView.swift

/**
 * 内容发布面板视图
 * 发布内容、选择互动角色的主面板
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
    /// 发布模式：交流/质问/创作
    @State private var publishMode: PublishMode = .communication
    /// 是否显示键盘
    @State private var keyboardVisible = false
    /// 键盘高度
    @State private var keyboardHeight: CGFloat = 0
    /// 角色回复概率设置
    @State private var characterProbabilities: [Double] = []
    /// 是否显示概率设置区域
    @State private var showProbabilitySettings: Bool = false
    /// 选中的图片
    @State private var selectedImages: [UIImage] = []
    /// 是否显示图片选择器
    @State private var showingImagePicker: Bool = false
    /// 是否显示发布成功提示
    @State private var isShowingSuccessToast: Bool = false
    /// 潜在回复的角色列表(用于成功提示)
    @State private var potentialRespondingCharacters: [CharacterModel] = []
    
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
                    
                    // 虫洞能量指示器
                    energyIndicatorView
                        .padding(.top, 8)
                        .padding(.horizontal, 16)
                    
                    // 角色推荐区域
                    characterRecommendationView
                        .padding(.top, 8)
                        .padding(.horizontal, 16)
                    
                    // 角色回复概率设置区域
                    if !selectedCharacters.isEmpty && showProbabilitySettings {
                        characterResponseProbabilityView
                            .padding(.top, 8)
                    }
                    
                    // 底部工具栏
                    bottomToolbar
                        .padding(.bottom, keyboardVisible ? keyboardHeight : 16)
                }
                .padding(.horizontal, 12)
                .background(
                    Color(.systemBackground)
                        .appCornerRadius(24, corners: [.topLeft, .topRight])
                        .shadow(color: Color.black.opacity(0.1), radius: 10, y: -5)
                )
                .offset(y: isVisible ? 0 : UIScreen.main.bounds.height)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isVisible)
                .onAppear {
                    // 监听键盘事件
                    setupKeyboardObservers()
                }
                .onDisappear {
                    // 移除键盘监听
                    removeKeyboardObservers()
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .animation(.default, value: keyboardVisible)
        .sheet(isPresented: $showingCharacterSelector) {
            CharacterSelectorView(selectedCharacters: $selectedCharacters)
                .onDisappear {
                    // 更新角色概率
                    updateCharacterProbabilities()
                }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImages: $selectedImages, maxSelections: 9)
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
        VStack(spacing: 16) {
            // 发布模式选择
            HStack {
                ForEach(PublishMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation {
                            publishMode = mode
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(mode.title)
                                .font(.system(size: 14, weight: publishMode == mode ? .semibold : .medium))
                            
                            // 选中指示器
                            Rectangle()
                                .frame(height: 3)
                                .foregroundColor(publishMode == mode ? Color.primaryColor : .clear)
                                .cornerRadius(1.5)
                        }
                    }
                    .foregroundColor(publishMode == mode ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            
            // 分隔线
            Divider()
            
            // 文本输入区域
            ZStack(alignment: .topLeading) {
                TextEditor(text: $contentText)
                    .frame(height: 120)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                
                if contentText.isEmpty {
                    Text(publishMode.placeholder)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
            }
            
            // 图片选择区域
            imageSelectionArea
            
            // 时代选择器
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(eras, id: \.self) { era in
                        Button(action: {
                            selectedEra = era
                        }) {
                            Text(era)
                                .font(.system(size: 14))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedEra == era ? Color.primaryColor : Color.gray.opacity(0.1))
                                )
                                .foregroundColor(selectedEra == era ? .white : .primary)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 16)
    }
    
    // 图片选择区域 - 简化实现
    private var imageSelectionArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 显示选择图片的提示文本
            Text(selectedImages.isEmpty ? "添加图片（可选）" : "已选择 \(selectedImages.count) 张图片")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
            
            // 图片网格展示
            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(0..<selectedImages.count, id: \.self) { index in
                            imageCell(image: selectedImages[index], index: index)
                        }
                        
                        // 添加按钮放在已有图片之后
                        if selectedImages.count < 9 {
                            addImageButton
                        }
                    }
                    .padding(.horizontal, 16)
                }
            } else {
                // 无图片时显示独立的添加按钮
                HStack {
                    addImageButton
                        .padding(.horizontal, 16)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // 简化的图片单元格
    private func imageCell(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            // 图片显示
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .cornerRadius(8)
                .clipped()
            
            // 删除按钮 - 简化实现
            Button {
                withAnimation {
                    // 使用removeImage函数避免歧义
                    removeImage(at: index)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.5)))
                    .padding(4)
            }
        }
    }
    
    // 删除图片的函数
    private func removeImage(at index: Int) {
        if index < selectedImages.count {
            selectedImages.remove(at: index)
        }
    }
    
    // 添加图片按钮 - 简化实现
    private var addImageButton: some View {
        Button {
            showingImagePicker = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "photo")
                    .font(.system(size: 24))
                Text("添加")
                    .font(.system(size: 12))
            }
            .foregroundColor(.blue)
            .frame(width: 80, height: 80)
            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 1).background(Color.blue.opacity(0.05)))
        }
    }
    
    // 底部工具栏
    private var bottomToolbar: some View {
        HStack {
            // 角色选择按钮
            Button(action: {
                showingCharacterSelector = true
            }) {
                Image(systemName: "person.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.primaryColor)
                    .frame(width: 44, height: 44)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(22)
            }
            
            // 概率设置开关
            if !selectedCharacters.isEmpty {
                Button(action: {
                    withAnimation {
                        showProbabilitySettings.toggle()
                    }
                }) {
                    Image(systemName: showProbabilitySettings ? "chart.pie.fill" : "chart.pie")
                        .font(.system(size: 20))
                        .foregroundColor(showProbabilitySettings ? Color.primaryColor : .gray)
                        .frame(width: 44, height: 44)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(22)
                }
            }
            
            Spacer()
            
            // 选中角色数量
            if !selectedCharacters.isEmpty {
                Text("\(selectedCharacters.count)个角色")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 发布按钮
            Button(action: {
                // 修改发布条件：文本不为空或者有图片
                if !contentText.isEmpty || !selectedImages.isEmpty {
                    // 如果没有选择角色，自动添加推荐角色
                    if selectedCharacters.isEmpty {
                        // 获取推荐角色
                        let recommendedCharacters = PublishCharacterRecommendationView.getRecommendedCharacters(
                            contentText: contentText,
                            selectedEra: selectedEra,
                            selectedCharacters: []
                        )
                        
                        // 如果有推荐角色就使用前3个，否则从所有角色中随机选择3个
                        if !recommendedCharacters.isEmpty {
                            selectedCharacters = Array(recommendedCharacters.prefix(3))
                        } else {
                            // 随机选择3个不同类型的角色
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
                            
                            selectedCharacters = tempSelectedCharacters
                        }
                        
                        // 更新角色概率
                        updateCharacterProbabilities()
                    }
                    
                    publishContent()
                }
            }) {
                Text("发布")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        // 修改按钮颜色条件：文本不为空或有图片时为蓝色
                        (!contentText.isEmpty || !selectedImages.isEmpty) ?
                            Color.primaryColor :
                            Color.gray
                    )
                    .cornerRadius(22)
            }
            // 修改禁用条件：文本为空且没有图片时禁用
            .disabled(contentText.isEmpty && selectedImages.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // 发布内容
    private func publishContent() {
        // 确保概率总和为100%
        normalizeCharacterProbabilities()
        
        // 创建要发布的内容数据
        let _ = PostData(
            content: contentText,
            images: selectedImages,
            era: selectedEra,
            characters: selectedCharacters,
            characterProbabilities: getProbabilityDict(),
            publishMode: publishMode
        )
        
        // 这里可以添加保存数据的代码
        // postManager.save(postData)
        
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
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // 设置键盘观察者
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
                keyboardVisible = true
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            keyboardVisible = false
            keyboardHeight = 0
        }
    }
    
    // 移除键盘观察者
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
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
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 12, y: 6)
        .padding(.horizontal, 40)
    }
}

/**
 * 发布模式枚举
 */
enum PublishMode: CaseIterable {
    case communication  // 交流
    case question       // 质问
    case creation       // 创作
    
    var title: String {
        switch self {
        case .communication:
            return "交流"
        case .question:
            return "质问"
        case .creation:
            return "创作"
        }
    }
    
    var placeholder: String {
        switch self {
        case .communication:
            return "与角色交流，分享想法..."
        case .question:
            return "向角色提出问题，探索思想..."
        case .creation:
            return "与角色共同创作，讨论灵感..."
        }
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
        
        let filtered = allCharacters.filter { character in
            // 排除已选择的角色
            if selectedCharacters.contains(where: { $0.id == character.id }) {
                return false
            }
            
            // 匹配时代
            let eraMatch = character.era.contains(selectedEra) || selectedEra == "现代"
            
            // 匹配内容文本关键词
            let contentMatch = contentText.isEmpty ? true : (
                contentText.contains(character.name) ||
                character.profession.contains(where: { contentText.contains($0) }) ||
                character.bio.contains(where: { contentText.contains($0) })
            )
            
            return eraMatch && contentMatch
        }
        
        // 限制数量
        return Array(filtered.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("推荐角色")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Button(action: {
                    // 显示角色选择器
                }) {
                    Text("更多 >")
                        .font(.system(size: 14))
                        .foregroundColor(Color.primaryColor)
                }
            }
            
            if recommendedCharacters.isEmpty {
                Text("没有匹配的推荐角色")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recommendedCharacters) { character in
                            RecommendedCharacterCell(
                                character: character,
                                isSelected: selectedCharacters.contains { $0.id == character.id },
                                onSelect: { isSelected in
                                    if isSelected {
                                        selectedCharacters.append(character)
                                    } else {
                                        selectedCharacters.removeAll { $0.id == character.id }
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
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
    
    var body: some View {
        NavigationView {
            VStack {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("搜索角色", text: $searchText)
                        .font(.system(size: 16))
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // 角色网格
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredCharacters) { character in
                            CharacterSelectionCell(
                                character: character,
                                isSelected: isSelected(character),
                                onToggle: { toggleCharacter(character) }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("选择角色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确定") {
                        selectedCharacters = localSelectedCharacters
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                localSelectedCharacters = selectedCharacters
            }
        }
    }
    
    private var filteredCharacters: [CharacterModel] {
        if searchText.isEmpty {
            return CharacterModel.sampleCharacters
        } else {
            return CharacterModel.sampleCharacters.filter { character in
                character.name.lowercased().contains(searchText.lowercased()) ||
                character.profession.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    private func isSelected(_ character: CharacterModel) -> Bool {
        return localSelectedCharacters.contains { $0.id == character.id }
    }
    
    private func toggleCharacter(_ character: CharacterModel) {
        if isSelected(character) {
            localSelectedCharacters.removeAll { $0.id == character.id }
        } else {
            localSelectedCharacters.append(character)
        }
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
    
    var body: some View {
        VStack {
            // 角色头像
            ZStack {
                if UIImage(named: character.avatar) != nil {
                    Image(character.avatar)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(character.category.color.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(String(character.name.prefix(1)))
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(character.category.color)
                        )
                }
                
                // 选中指示器
                if isSelected {
                    Circle()
                        .stroke(Color.primaryColor, lineWidth: 3)
                        .frame(width: 86, height: 86)
                }
            }
            
            // 角色名称
            Text(character.name)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
            
            // 角色职业
            Text(character.profession)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(8)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.primaryColor.opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.primaryColor : Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
        .onTapGesture {
            onToggle()
        }
    }
}

/**
 * 推荐角色单元格
 * 用于推荐角色列表中的单元格显示
 */
struct RecommendedCharacterCell: View {
    let character: CharacterModel
    let isSelected: Bool
    let onSelect: (Bool) -> Void
    
    var body: some View {
        VStack {
            // 角色头像
            ZStack {
                if UIImage(named: character.avatar) != nil {
                    Image(character.avatar)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(character.category.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(String(character.name.prefix(1)))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(character.category.color)
                        )
                }
                
                // 选中指示器
                if isSelected {
                    Circle()
                        .stroke(Color.primaryColor, lineWidth: 2)
                        .frame(width: 64, height: 64)
                }
            }
            
            // 角色名称
            Text(character.name)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
        }
        .frame(width: 70)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.primaryColor.opacity(0.1) : Color.clear)
        )
        .onTapGesture {
            onSelect(!isSelected)
        }
    }
}

/**
 * 虫洞能量指示器
 * 显示当前内容和角色组合的穿越能量等级
 */
struct WormholeEnergyIndicator: View {
    let contentText: String
    let characters: [CharacterModel]
    
    // 计算能量等级
    private var energyLevel: Int {
        // 计算规则：文本长度 + 角色数量 * 10
        let textFactor = min(contentText.count / 10, 10)
        let characterFactor = min(characters.count * 10, 30)
        
        // 不同时代的角色会产生更高能量
        let uniqueEras = Set(characters.map { $0.era }).count
        let eraFactor = uniqueEras * 5
        
        let totalEnergy = textFactor + characterFactor + eraFactor
        return min(totalEnergy, 100) / 20 // 0-5级
    }
    
    var body: some View {
        HStack {
            // 能量标题
            Text("穿越能量")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            // 能量等级
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(index < energyLevel ? energyColor : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            
            // 能量值
            Text("\(energyLevel * 20)%")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(energyColor)
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
    
    // 能量颜色
    private var energyColor: Color {
        switch energyLevel {
        case 0:
            return .gray
        case 1:
            return .blue
        case 2:
            return .green
        case 3:
            return .yellow
        case 4:
            return .orange
        case 5:
            return .red
        default:
            return .gray
        }
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