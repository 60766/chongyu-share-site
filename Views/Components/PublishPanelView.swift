import SwiftUI

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
    /// 是否显示图片选择器
    @State private var showingImagePicker: Bool = false
    /// 选中的图片
    @State private var selectedImages: [UIImage] = []
    /// 是否显示发布成功提示
    @State private var isShowingSuccessToast: Bool = false
    /// 潜在回复的角色列表
    @State private var potentialRespondingCharacters: [CharacterModel] = []
    /// 文本编辑器焦点状态
    @FocusState private var isTextEditorFocused: Bool
    
    // 时代选项
    private let eras = ["现代", "古代", "中世纪", "文艺复兴", "启蒙运动", "未来"]
    
    // MARK: - 常量
    private struct Constants {
        static let buttonCornerRadius: CGFloat = 24
        static let buttonPaddingHorizontal: CGFloat = 20
        static let buttonPaddingVertical: CGFloat = 12
        static let maxAutoSelectedCharacters: Int = 3
    }
    
    var body: some View {
        VStack(spacing: 0) {
            contentInputArea
            bottomToolbar
        }
        .background(Color.systemBackground)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 2)
    }
    
    // MARK: - 私有视图
    
    // 内容输入区域
    private var contentInputArea: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                EnhancedTextDisplayView(
                    text: $contentText,
                    placeholder: "穿越时空，与历史人物对话...",
                    minHeight: 100,
                    maxHeight: 200,
                    cornerRadius: 20,
                    borderColor: Color.primaryColor,
                    backgroundColor: Color.white.opacity(0.98)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .shadow(color: Color.primaryColor.opacity(0.1), radius: 6, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.primaryColor.opacity(0.5), Color.primaryColor.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
            }
            .frame(height: UIScreen.main.bounds.height * 0.2)
            
            HStack(spacing: 14) {
                Button(action: { showingImagePicker = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo")
                            .font(.system(size: 15, weight: .medium))
                        Text("添加图片")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.08)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .foregroundColor(Color.blue.opacity(0.9))
                }
                
                Spacer()
                
                Menu {
                    ForEach(eras, id: \.self) { era in
                        Button(era) {
                            selectedEra = era
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 15, weight: .medium))
                        Text(selectedEra)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.primaryColor.opacity(0.15), Color.primaryColor.opacity(0.08)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .foregroundColor(Color.primaryColor.opacity(0.9))
                }
            }
            
            energyIndicatorView
            
            characterRecommendationView
                .padding(.top, 2)
        }
        .padding(.horizontal, 16)
    }
    
    // 底部工具栏
    private var bottomToolbar: some View {
        HStack {
            // 角色选择按钮
            Button(action: {
                showingCharacterSelector = true
                // 添加触感反馈
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 15))
                    Text("选择角色")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(Color.primaryColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 8) 
                .background(
                    Capsule()
                        .fill(Color.primaryColor.opacity(0.12))
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(BouncyButtonStyle())
            
            // 选中角色数量
            if !selectedCharacters.isEmpty {
                Text("\(selectedCharacters.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(Color.primaryColor)
                    .clipShape(Circle())
                    .offset(x: -8)
                    .shadow(color: Color.primaryColor.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            
            Spacer()
            
            publishButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - 私有方法
    
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
    
    private var hasValidContent: Bool {
        !contentText.isEmpty || !selectedImages.isEmpty
    }
    
    private func autoSelectCharacters() {
        // 获取推荐角色
        let recommendedCharacters = PublishCharacterRecommendationView.getRecommendedCharacters(
            contentText: contentText,
            selectedEra: selectedEra,
            selectedCharacters: []
        )
        
        if !recommendedCharacters.isEmpty {
            selectedCharacters = Array(recommendedCharacters.prefix(Constants.maxAutoSelectedCharacters))
        } else {
            selectedCharacters = selectRandomCharacters()
        }
        
        updateCharacterProbabilities()
    }
    
    private func selectRandomCharacters() -> [CharacterModel] {
        var tempSelectedCharacters: [CharacterModel] = []
        let categories = CharacterCategory.allCases
        
        for category in categories {
            if let character = CharacterModel.sampleCharacters.filter({ $0.category == category }).randomElement() {
                tempSelectedCharacters.append(character)
                if tempSelectedCharacters.count >= Constants.maxAutoSelectedCharacters {
                    break
                }
            }
        }
        
        return tempSelectedCharacters
    }
    
    // 发布按钮视图
    private var publishButton: some View {
        Button(action: handlePublishButtonTapped) {
            HStack(spacing: 8) {
                // 图标与文本
                Text("发布")
                    .font(.system(size: 16, weight: .semibold))
                    .offset(x: hasValidContent ? 0 : -10) // 动画效果
                
                if hasValidContent {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14))
                        .offset(x: -4, y: -2)
                        .rotationEffect(.degrees(15))
                }
            }
            .padding(.horizontal, Constants.buttonPaddingHorizontal)
            .padding(.vertical, Constants.buttonPaddingVertical)
            .background(
                ZStack {
                    // 基础背景
                    hasValidContent
                        ? angledGradientBackground
                        : disabledBackground
                    
                    // 内部光效 - 仅在启用状态显示
                    if hasValidContent {
                        RoundedRectangle(cornerRadius: Constants.buttonCornerRadius - 1)
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.3), Color.clear]),
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 70
                                )
                            )
                            .padding(1)
                            .blendMode(.overlay)
                        
                        // 底部光晕效果
                        RoundedRectangle(cornerRadius: Constants.buttonCornerRadius)
                            .fill(Color.clear)
                            .shadow(color: Color.primaryColor.opacity(0.5), radius: 6, x: 0, y: 3)
                            .blur(radius: 4)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: Constants.buttonCornerRadius))
            .overlay(
                // 边框
                RoundedRectangle(cornerRadius: Constants.buttonCornerRadius)
                    .stroke(
                        hasValidContent
                            ? LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.5), Color.primaryColor.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : Color.clear,
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: hasValidContent ? Color.primaryColor.opacity(0.4) : Color.black.opacity(0.05),
                radius: hasValidContent ? 10 : 0,
                x: 0,
                y: hasValidContent ? 4 : 0
            )
            .foregroundColor(.white)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: hasValidContent)
        }
        .disabled(!hasValidContent)
    }
    
    // 彩色渐变背景
    private var angledGradientBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.primaryColor,
                Color.primaryColor.opacity(0.8)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // 禁用状态背景
    private var disabledBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.gray.opacity(0.5),
                Color.gray.opacity(0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // 虫洞能量指示器
    private var energyIndicatorView: some View {
        WormholeEnergyIndicator(
            contentText: contentText,
            characters: selectedCharacters
        )
    }
} 