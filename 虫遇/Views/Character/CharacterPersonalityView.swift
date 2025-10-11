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
    

    
    // 初始化方法
    init(characterId: String, character: Character, onClose: @escaping () -> Void) {
        self.characterId = characterId
        self.character = character
        self.onClose = onClose
        self.viewModel = CharacterPersonalityViewModel(characterId: characterId, characterName: character.name)
    }
    
    var body: some View {
            VStack(spacing: 0) {
                // 顶部导航栏
                topBar
                
            // 主要内容区域 - 使用GeometryReader确保按钮在底部
            GeometryReader { geometry in
                VStack(spacing: 0) {
                // 滚动内容区
                ScrollView {
                        VStack(spacing: 20) {
                        // 角色信息头部
                        characterHeader
                            .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .padding(.bottom, 8)
                        
                        // 个性化调整部分
                        personalityAdjustments
                            .padding(.horizontal, 16)
                        
                            // 底部安全距离，确保内容不会被按钮遮挡
                        Spacer()
                                .frame(height: 10)
                        }
                    }
                    
                    Spacer() // 推送按钮到底部
                
                    // 底部操作按钮 - 固定在底部
                bottomButtons
                    .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, -8)
                    .background(
                        Rectangle()
                            .fill(DesignSystem.Colors.background)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, y: -5)
                    )
            }
        }
        }
        .background(DesignSystem.Colors.background)
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
                .font(.system(size: 17, weight: .medium))
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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            DesignSystem.Colors.background
                .shadow(color: Color.black.opacity(0.05), radius: 1, y: 1)
        )
    }
    
    // 角色信息头部
    private var characterHeader: some View {
        VStack(spacing: 12) {
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
            
            // 介绍文字
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
    }
    
    // 个性化调整部分
    private var personalityAdjustments: some View {
        VStack(spacing: 22) {
            SectionHeader(title: "性格参数调整", iconName: "slider.horizontal.3")
                .padding(.bottom, 8)
            
            // 亲密度滑块
            AdjustmentSlider(
                title: "亲密度",
                leftLabel: "陌生人",
                rightLabel: "老朋友",
                value: $viewModel.intimacy,
                onChange: { viewModel.updatePersonality() }
            )
            
            // 互动深度滑块
            AdjustmentSlider(
                title: "互动深度",
                leftLabel: "浅层交流",
                rightLabel: "深度探索",
                value: $viewModel.engagementDepth,
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
            
            // 回应方式滑块
            AdjustmentSlider(
                title: "回应方式",
                leftLabel: "直接建议",
                rightLabel: "启发引导",
                value: $viewModel.responseStyle,
                onChange: { viewModel.updatePersonality() }
            )
            
            // 交流节奏滑块
            AdjustmentSlider(
                title: "交流节奏",
                leftLabel: "简洁",
                rightLabel: "详细",
                value: $viewModel.communicationPace,
                onChange: { viewModel.updatePersonality() }
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignSystem.Colors.background)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    

    
    // 底部操作按钮
    private var bottomButtons: some View {
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
                    
                Text("保存参数")
                        .font(.system(size: 16, weight: .medium))
                }
                .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
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
    
    // 获取顶部安全区域高度
    private func getSafeAreaTop() -> CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.top
        }
        return 0
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
            
            // 5档位滑块
            VStack(spacing: 8) {
                // 自定义滑块容器
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景轨道
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        // 进度轨道
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.purple.opacity(0.6),
                                        Color.purple.opacity(0.8)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: CGFloat(value) * geometry.size.width, height: 4)
                            .cornerRadius(2)
                        
                        // 档位节点 (5个档位：0, 0.25, 0.5, 0.75, 1.0)
                        HStack {
                            ForEach(0..<5) { index in
                                let position = Float(index) * 0.25
                                let isActive = abs(value - position) < 0.125
                                
                                Circle()
                                    .fill(isActive ? Color.purple.opacity(0.9) : Color.gray.opacity(0.6))
                                    .frame(width: isActive ? 12 : 8, height: isActive ? 12 : 8)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: isActive ? 2 : 1)
                                    )
                                    .scaleEffect(isActive ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: value)
                                
                                if index < 4 {
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 6)
                        
                        // 滑动手柄
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.purple.opacity(0.8), lineWidth: 2)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                            .offset(x: CGFloat(value) * (geometry.size.width - 20))
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { dragValue in
                                        let newValue = Float(dragValue.location.x / (geometry.size.width - 20))
                                        let clampedValue = max(0, min(1, newValue))
                                        
                                        // 吸附到最近的档位
                                        let snapPoints: [Float] = [0, 0.25, 0.5, 0.75, 1.0]
                                        let closestPoint = snapPoints.min { abs($0 - clampedValue) < abs($1 - clampedValue) } ?? 0.5
                                        
                                        value = closestPoint
                                    }
                                    .onEnded { _ in
                        onChange()
                                        
                                        // 触觉反馈
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    }
                            )
                    }
                }
                .frame(height: 20)
                
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
    @Published var intimacy: Float = 0.5
    @Published var engagementDepth: Float = 0.5
    @Published var emotionality: Float = 0.5
    @Published var responseStyle: Float = 0.5
    @Published var communicationPace: Float = 0.5
    
    // 记录哪些参数被用户调整过
    private var adjustedParameters: Set<String> = []

    

    
    // 初始化
    init(characterId: String, characterName: String) {
        self.characterId = characterId
        self.characterName = characterName
    }
    
    // 加载角色个性化设置
    func loadPersonality() {
        if let personality = personalityManager.getUserAdjustments(for: characterId) {
            // 用户有调整，加载用户的设置
            intimacy = personality.intimacy
            engagementDepth = personality.engagementDepth
            emotionality = personality.emotionality
            responseStyle = personality.responseStyle
            communicationPace = personality.communicationPace
            
            // 标记这些参数为已调整（如果不是默认值）
            adjustedParameters.removeAll()
            if personality.intimacy != 0.5 { adjustedParameters.insert("intimacy") }
            if personality.engagementDepth != 0.5 { adjustedParameters.insert("engagementDepth") }
            if personality.emotionality != 0.5 { adjustedParameters.insert("emotionality") }
            if personality.responseStyle != 0.5 { adjustedParameters.insert("responseStyle") }
            if personality.communicationPace != 0.5 { adjustedParameters.insert("communicationPace") }
            
            print("✅ 加载了用户调整的个性化设置: \(characterName)，已调整参数: \(adjustedParameters)")
        } else {
            // 用户没有调整，使用默认值(0.5)
            intimacy = 0.5
            engagementDepth = 0.5
            emotionality = 0.5
            responseStyle = 0.5
            communicationPace = 0.5
            adjustedParameters.removeAll()
            print("📝 使用默认个性化设置: \(characterName)")
        }
    }
    
    // 更新个性参数 - 只上传用户调整的参数
    func updatePersonality() {
        // 构建只包含用户调整参数的CharacterPersonality
        var personality = CharacterPersonality()
        
        // 只设置用户调整过的参数
        if adjustedParameters.contains("intimacy") || intimacy != 0.5 {
            personality.intimacy = intimacy
            if intimacy != 0.5 { adjustedParameters.insert("intimacy") }
            else { adjustedParameters.remove("intimacy") }
        }
        
        if adjustedParameters.contains("engagementDepth") || engagementDepth != 0.5 {
            personality.engagementDepth = engagementDepth
            if engagementDepth != 0.5 { adjustedParameters.insert("engagementDepth") }
            else { adjustedParameters.remove("engagementDepth") }
        }
        
        if adjustedParameters.contains("emotionality") || emotionality != 0.5 {
            personality.emotionality = emotionality
            if emotionality != 0.5 { adjustedParameters.insert("emotionality") }
            else { adjustedParameters.remove("emotionality") }
        }
        
        if adjustedParameters.contains("responseStyle") || responseStyle != 0.5 {
            personality.responseStyle = responseStyle
            if responseStyle != 0.5 { adjustedParameters.insert("responseStyle") }
            else { adjustedParameters.remove("responseStyle") }
        }
        
        if adjustedParameters.contains("communicationPace") || communicationPace != 0.5 {
            personality.communicationPace = communicationPace
            if communicationPace != 0.5 { adjustedParameters.insert("communicationPace") }
            else { adjustedParameters.remove("communicationPace") }
        }
        
        personalityManager.updatePersonality(for: characterId, personality: personality)
        print("🔄 更新个性化参数，只包含调整的参数: \(adjustedParameters)")
    }

    
    // 重置为默认设置
    func resetToDefault() {
        personalityManager.resetPersonality(for: characterId)
        adjustedParameters.removeAll()
        loadPersonality() // 重新加载默认设置
    }
    
    // 保存并应用设置
    func saveAndApply() {
        updatePersonality()
        print("✅ 已保存并应用角色个性化设置: \(characterName)，调整的参数: \(adjustedParameters)")
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