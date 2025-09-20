import SwiftUI
import Combine

/**
 * 空评论状态视图
 * 显示无评论时的友好提示，鼓励用户与历史人物互动
 * 设计重点：情感连接、视觉引导和降低用户互动心理门槛
 */
struct EmptyCommentsView: View {
    // 角色互动状态
    @State private var activeCharacterIndex = 0
    @State private var showThinking = false
    @State private var pulseEffect = false
    
    // 角色列表 - 从CharacterAvatarService获取
    private let characters: [String]
    private let avatarService = CharacterAvatarService.shared
    
    // 计时器用于切换"思考中"的角色
    @State private var timerPublisher = Timer.publish(every: 5, on: .main, in: .common)
    @State private var timerCancellable: Cancellable? = nil
    
    init() {
        // 明确指定要使用的角色，不再依赖前5个
        self.characters = ["einstein", "shakespeare", "davinci", "newton", "plato"]
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // 图标区域 - 增强情感化设计
            ZStack {
                // 底层光晕效果 - 增强温暖感
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "9A8BB0").opacity(0.1), 
                                Color(hex: "A890B8").opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                // 中层脉动光圈 - 增强生命感
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "9A8BB0").opacity(0.2), 
                            Color(hex: "A890B8").opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 70, height: 70)
                                .scaleEffect(pulseEffect ? 1.1 : 1.0)
                                .opacity(pulseEffect ? 0.6 : 1.0)
                                .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseEffect)
                    .onAppear {
            // 连接Timer
            timerCancellable = timerPublisher.connect()
                        pulseEffect = true
                    }
                
                // 主图标 - 使用更符合情感沟通的图标
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "9A8BB0").opacity(0.6))
            }
            .padding(.bottom, 4)
            
            // 文本提示区域 - 情感优化
            VStack(spacing: 10) {
                Text("·穿越时空的对话")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(Color(hex: "A190B2").opacity(0.9))
                    .kerning(0.3)
                
                Text("每个想法都值得被倾听\n那些伟大心灵或许正等待与你共鸣")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }
            
            // 分隔装饰线 - 增加视觉韵律
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "9A8BB0").opacity(0.0),
                            Color(hex: "9A8BB0").opacity(0.2),
                            Color(hex: "9A8BB0").opacity(0.0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 40)
            
            // 历史人物头像区域 - 增强角色个性化
            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    ForEach(Array(characters.enumerated()), id: \.element) { index, characterId in
                        Avatar(url: characterId, name: avatarService.getCharacterChineseName(for: characterId), category: "", size: 36)
                            .overlay(
                                Circle()
                                    .stroke(avatarService.getCharacterTagColor(for: characterId), lineWidth: 2)
                            )
                            .offset(x: CGFloat(-10 * index), y: 0)
                            .scaleEffect(activeCharacterIndex == index ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: activeCharacterIndex)
                            .shadow(color: avatarService.getCharacterTagColor(for: characterId).opacity(0.3), radius: 3, x: 0, y: 1)
                            .zIndex(Double(characters.count - index))
                    }
                }
                .padding(.leading, CGFloat(10 * (characters.count - 1)))
                
                // 角色思考状态指示器 - 增强期待感
                if showThinking {
                    CharacterThinkingIndicator(characterId: characters.map { $0 }[activeCharacterIndex])
                        .transition(.opacity)
                }
            }
            
            // 引导行动区域 - 情感化操作按钮
            Button(action: {
                // 触发评论输入框通知
                NotificationCenter.default.post(
                    name: Notification.Name("FocusCommentInput"),
                    object: nil
                )
                
                // 增强触感反馈
                let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
                feedbackGenerator.impactOccurred()
            }) {
                HStack {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 15))
                    
                    Text("留下你的心声")
                        .font(.system(size: 15, weight: .medium))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "9A8BB0"), Color(hex: "A890B8")]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(20)
                .shadow(color: Color(hex: "9A8BB0").opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(EmptyCommentsScaleButtonStyle(scaleAmount: 0.96))
            .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .onAppear {
            // 连接Timer
            timerCancellable = timerPublisher.connect()
            // 随机显示角色思考状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showThinking = true
                }
            }
        }
        .onReceive(timerPublisher) { _ in
            // 定时切换活跃角色
            withAnimation {
                activeCharacterIndex = (activeCharacterIndex + 1) % characters.count
            }
        }
        .onDisappear {
            // 在视图消失时取消计时器
            timerCancellable?.cancel()
        }
    }
    
    // 角色主题色获取函数
    private func getCharacterThemeColor(for character: String) -> Color {
        return avatarService.getCharacterTagColor(for: character)
    }
}

/**
 * 角色思考状态指示器组件
 * 显示虚拟角色正在思考的动态效果
 */
struct CharacterThinkingIndicator: View {
    let characterId: String
    private let avatarService = CharacterAvatarService.shared
    
    @State private var typingPhase = 0
    @State private var timerPublisher = Timer.publish(every: 0.5, on: .main, in: .common)
    @State private var timerCancellable: Cancellable? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            // 角色头像
            Avatar(url: characterId, name: getCharacterName(), category: "", size: 24)
            
            // 思考指示动画
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(getCharacterColor())
                        .frame(width: 5, height: 5)
                        .opacity(typingPhase == i ? 0.8 : 0.3)
                }
            }
            
            // 思考文本提示
            Text("\(getCharacterName())正在思考...")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(getCharacterColor().opacity(0.08))
        .cornerRadius(15)
        .onAppear {
            // 连接Timer
            timerCancellable = timerPublisher.connect()
        }
        .onReceive(timerPublisher) { _ in
            typingPhase = (typingPhase + 1) % 3
        }
    }
    
    // 获取角色颜色
    private func getCharacterColor() -> Color {
        return avatarService.getCharacterTagColor(for: characterId)
    }
    
    // 获取角色名称
    private func getCharacterName() -> String {
        return avatarService.getCharacterChineseName(for: characterId)
    }
}

// 预览
struct EmptyCommentsView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyCommentsView()
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

// 缩放按钮样式 - 私有实现，避免命名冲突
fileprivate struct EmptyCommentsScaleButtonStyle: ButtonStyle {
    let scaleAmount: CGFloat
    
    init(scaleAmount: CGFloat = 0.95) {
        self.scaleAmount = scaleAmount
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
} 