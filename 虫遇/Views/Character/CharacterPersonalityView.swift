import SwiftUI
import Combine

/**
 * 角色个性化调整视图
 * 允许用户调整角色的性格、表达方式等特性
 */
struct CharacterPersonalityView: View {
    // 角色ID
    var characterId: String
    
    // 角色信息
    var character: Character
    
    // 关闭回调
    var onClose: () -> Void
    
    // 个性化管理器
    @ObservedObject private var viewModel: CharacterPersonalityViewModel
    
    // 标题和说明
    @State private var title: String = "个性化调整"
    @State private var subtitle: String = "调整历史人物在互动中的性格特点和表达方式，使其更贴合您的期望。"
    
    // 动画状态
    @State private var isExpressionsExpanded: Bool = true
    
    // 初始化方法
    init(characterId: String, character: Character, onClose: @escaping () -> Void) {
        self.characterId = characterId
        self.character = character
        self.onClose = onClose
        self.viewModel = CharacterPersonalityViewModel(characterId: characterId, characterName: character.name)
    }
    
    var body: some View {
        ZStack {
            // 背景色
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            // 主内容
            VStack(spacing: 0) {
                // 顶部导航栏
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                
                // 滚动内容区
                ScrollView {
                    VStack(spacing: 24) {
                        // 角色信息头部
                        characterHeader
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 16)
                        
                        // 个性化调整部分
                        personalityAdjustments
                            .padding(.horizontal, 16)
                        
                        // 表达偏好部分
                        expressionPreferences
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        
                        // 底部间距
                        Spacer()
                            .frame(height: 100)
                    }
                }
                
                // 底部操作按钮
                bottomButtons
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(
                        Rectangle()
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, y: -5)
                    )
            }
        }
        .onAppear {
            viewModel.loadPersonality()
        }
    }
    
    // MARK: - 组件视图
    
    // 顶部导航栏
    private var topBar: some View {
        HStack {
            // 返回按钮
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primary.opacity(0.7))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                    )
            }
            
            Spacer()
            
            // 页面标题
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // 重置按钮
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred(intensity: 0.6)
                viewModel.resetToDefault()
            }) {
                Text("重置")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.purple.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.purple.opacity(0.12))
                    )
            }
        }
    }
    
    // 角色信息头部
    private var characterHeader: some View {
        VStack(spacing: 16) {
            // 标题和副标题
            VStack(spacing: 8) {
                Text("\(character.name)的个性化调整")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // 角色头像和信息
            HStack(spacing: 14) {
                // 头像
                ZStack {
                    if UIImage(named: character.avatarUrl) != nil {
                        Image(character.avatarUrl)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            )
                    } else {
                        // 默认头像
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(Color(.systemGray))
                            )
                    }
                }
                
                // 角色信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(character.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("\(character.field) | \(character.birthYear)-\(character.deathYear ?? "现在")")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6).opacity(0.5))
            )
        }
    }
    
    // 个性化调整部分
    private var personalityAdjustments: some View {
        VStack(spacing: 22) {
            SectionHeader(title: "性格参数调整", iconName: "slider.horizontal.3")
                .padding(.bottom, 8)
            
            // 直接程度滑块
            AdjustmentSlider(
                title: "表达方式",
                leftLabel: "含蓄",
                rightLabel: "直接",
                value: $viewModel.directness,
                onChange: { viewModel.updatePersonality() }
            )
            
            // 正式程度滑块
            AdjustmentSlider(
                title: "语言风格",
                leftLabel: "随意",
                rightLabel: "正式",
                value: $viewModel.formality,
                onChange: { viewModel.updatePersonality() }
            )
            
            // 情感程度滑块
            AdjustmentSlider(
                title: "情感表达",
                leftLabel: "理性",
                rightLabel: "感性",
                value: $viewModel.emotionality,
                onChange: { viewModel.updatePersonality() }
            )
            
            // 详细程度滑块
            AdjustmentSlider(
                title: "回复详细度",
                leftLabel: "简短",
                rightLabel: "详细",
                value: $viewModel.verbosity,
                onChange: { viewModel.updatePersonality() }
            )
            
            // 创造性滑块
            AdjustmentSlider(
                title: "创意程度",
                leftLabel: "保守",
                rightLabel: "创新",
                value: $viewModel.creativity,
                onChange: { viewModel.updatePersonality() }
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // 表达偏好部分
    private var expressionPreferences: some View {
        VStack(spacing: 16) {
            // 标题和展开按钮
            HStack {
                SectionHeader(title: "表达偏好选择", iconName: "text.bubble")
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpressionsExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpressionsExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                        )
                }
            }
            .padding(.bottom, 8)
            
            // 表达偏好选项
            if isExpressionsExpanded {
                VStack(spacing: 12) {
                    ForEach(viewModel.availableExpressions, id: \.self) { expression in
                        PreferenceToggle(
                            label: expression,
                            isOn: Binding(
                                get: { viewModel.expressionPreferences[expression] ?? false },
                                set: { 
                                    viewModel.expressionPreferences[expression] = $0
                                    viewModel.updateExpressionPreferences()
                                }
                            )
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // 底部操作按钮
    private var bottomButtons: some View {
        HStack(spacing: 16) {
            // 预览示例按钮
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred(intensity: 0.6)
                viewModel.showPreview()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "eye")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("预览示例")
                        .font(.system(size: 16, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.6), lineWidth: 1.5)
                )
                .foregroundColor(Color.purple.opacity(0.8))
            }
            
            // 保存应用按钮
            Button(action: {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                viewModel.saveAndApply()
                onClose()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("保存应用")
                        .font(.system(size: 16, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.65, green: 0.48, blue: 0.87),
                                    Color(red: 0.59, green: 0.38, blue: 0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .foregroundColor(.white)
            }
        }
    }
}

// MARK: - 辅助组件

/**
 * 分区标题组件
 */
struct SectionHeader: View {
    var title: String
    var iconName: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.purple.opacity(0.8))
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}

/**
 * 调整滑块组件
 */
struct AdjustmentSlider: View {
    var title: String
    var leftLabel: String
    var rightLabel: String
    @Binding var value: Float
    var onChange: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // 标题
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // 滑块和标签
            VStack(spacing: 8) {
                // 滑块
                Slider(value: $value, in: 0...1, step: 0.05, onEditingChanged: { editing in
                    if !editing {
                        onChange()
                    }
                })
                .accentColor(Color.purple.opacity(0.8))
                
                // 左右标签
                HStack {
                    Text(leftLabel)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(rightLabel)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

/**
 * 偏好开关组件
 */
struct PreferenceToggle: View {
    var label: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.primary)
        }
        .toggleStyle(SwitchToggleStyle(tint: Color.purple.opacity(0.8)))
    }
}

// MARK: - ViewModel

/**
 * 角色个性化视图模型
 * 处理视图和数据之间的交互
 */
class CharacterPersonalityViewModel: ObservableObject {
    // 角色ID和名称
    private let characterId: String
    private let characterName: String
    
    // 个性化管理器
    private let personalityManager = CharacterPersonalityManager.shared
    
    // UI绑定属性
    @Published var directness: Float = 0.5
    @Published var formality: Float = 0.5
    @Published var emotionality: Float = 0.5
    @Published var verbosity: Float = 0.5
    @Published var creativity: Float = 0.5
    
    // 表达偏好
    @Published var availableExpressions: [String] = []
    @Published var expressionPreferences: [String: Bool] = [:]
    
    // 预览状态
    @Published var isShowingPreview: Bool = false
    @Published var previewText: String = ""
    
    // 初始化
    init(characterId: String, characterName: String) {
        self.characterId = characterId
        self.characterName = characterName
    }
    
    // 加载角色个性化设置
    func loadPersonality() {
        guard let template = personalityManager.getTemplate(for: characterId),
              let personality = personalityManager.getPersonality(for: characterId) else {
            print("⚠️ 无法加载角色模板: \(characterId)")
            return
        }
        
        // 加载调整参数
        directness = personality.directness
        formality = personality.formality
        emotionality = personality.emotionality
        verbosity = personality.verbosity
        creativity = personality.creativity
        
        // 加载表达偏好
        availableExpressions = template.availableExpressions
        expressionPreferences = personality.expressionPreferences
        
        print("✅ 已加载角色个性化设置: \(characterName)")
    }
    
    // 更新个性参数
    func updatePersonality() {
        let adjustments: [String: Float] = [
            "directness": directness,
            "formality": formality,
            "emotionality": emotionality,
            "verbosity": verbosity,
            "creativity": creativity
        ]
        
        personalityManager.updatePersonalityAdjustments(for: characterId, adjustments: adjustments)
    }
    
    // 更新表达偏好
    func updateExpressionPreferences() {
        personalityManager.updateExpressionPreferences(for: characterId, preferences: expressionPreferences)
    }
    
    // 重置为默认设置
    func resetToDefault() {
        personalityManager.resetToDefault(characterId: characterId)
        loadPersonality() // 重新加载默认设置
    }
    
    // 保存并应用设置
    func saveAndApply() {
        updatePersonality()
        updateExpressionPreferences()
        print("✅ 已保存并应用角色个性化设置: \(characterName)")
    }
    
    // 显示预览
    func showPreview() {
        // 这里应该调用API预览效果，现在只是显示简单提示
        let examples = [
            "这个问题让我想起了一个有趣的思考实验。从相对论的角度来看，时间和空间是相互关联的维度，这意味着我们对宇宙的理解需要超越传统的直觉。",
            "科学的魅力在于它永远充满未知。正如我常说的，想象力比知识更重要，因为知识是有限的，而想象力概括着世界的一切。",
            "从物理学的角度，这个观点有其合理性，但也存在一些需要考虑的限制条件。简单来说，我们需要区分理论的优雅和实际的应用。"
        ]
        
        // 随机选择一个例子
        previewText = "基于当前设置，\(characterName)可能会这样回复：\n\n" + examples.randomElement()!
        
        // 显示预览对话框
        let alert = UIAlertController(
            title: "\(characterName)的回复风格预览",
            message: previewText,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "关闭", style: .default))
        
        // 更新获取rootViewController的方式
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }
}

// 预览
struct CharacterPersonalityView_Previews: PreviewProvider {
    static var previews: some View {
        let mockCharacter = Character(
            id: "einstein",
            name: "爱因斯坦",
            introduction: "物理学家，相对论创立者",
            field: "物理学",
            birthYear: "1879",
            deathYear: "1955",
            avatarUrl: "einstein",
            eraTag: "近代",
            achievements: ["发现相对论", "质能方程"],
            mainWorks: ["相对论", "光电效应"],
            keyThoughts: ["宇宙是有限的", "光速不变原理"],
            followerCount: 1000,
            interactionCount: 5000,
            rating: 4.9
        )
        
        return CharacterPersonalityView(
            characterId: "einstein",
            character: mockCharacter,
            onClose: {}
        )
    }
} 