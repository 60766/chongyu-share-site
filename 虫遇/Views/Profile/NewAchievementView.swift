import SwiftUI

// MARK: - 新成就界面主视图
struct NewAchievementView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var evaluator = AchievementEvaluator.shared
    @State private var showingDetailView = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题和查看全部按钮
            HStack {
                Text("成就展示")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.8))
                
                Spacer()
                
                Button("查看全部") {
                    showingDetailView = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.warmAccent)
            }
            .padding(.horizontal, 20)
            
            // 成就网格 (3x2显示前6个，优先展示固定的成就)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(Array(evaluator.getDisplayAchievements().enumerated()), id: \.element.id) { index, achievement in
                    AchievementCardView(achievement: achievement, showPinButton: false)
                        .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.1), value: achievement.currentProgress)
                }
            }
            .padding(.horizontal, 20)
            .id(evaluator.achievements.map(\.isPinned)) // 监听固定状态变化以刷新网格
        }
        .sheet(isPresented: $showingDetailView) {
            AchievementDetailView(evaluator: evaluator)
        }
        .onAppear {
            // 页面出现时刷新成就数据

            evaluator.updateAllAchievements(using: modelContext)
        }
        .refreshable {
            // 支持下拉刷新
            #if DEBUG
            debugLog("🔄 用户触发下拉刷新成就数据")
            #endif
            evaluator.updateAllAchievements(using: modelContext)
        }
    }
}

// MARK: - 成就卡片视图
struct AchievementCardView: View {
    let achievement: CYAchievement
    let showPinButton: Bool
    @ObservedObject private var evaluator = AchievementEvaluator.shared
    
    // 获取实时的固定状态
    private var currentAchievement: CYAchievement {
        return evaluator.achievements.first(where: { $0.id == achievement.id }) ?? achievement
    }
    
    // 获取高级渐变色彩
    private var backgroundGradient: LinearGradient {
        switch achievement.level {
        case .bronze:
            if achievement.isUnlocked {
                return LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.95, blue: 0.85), // 温暖的象牙白
                        Color(red: 0.98, green: 0.85, blue: 0.65), // 浅金色
                        Color(red: 0.96, green: 0.75, blue: 0.45)  // 青铜色调
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.98, blue: 0.98), // 纯净白
                        Color(red: 0.94, green: 0.94, blue: 0.96), // 淡蓝灰
                        Color(red: 0.90, green: 0.90, blue: 0.94)  // 更深的蓝灰
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .silver:
            if achievement.isUnlocked {
                return LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.95, blue: 1.0),  // 冷白色
                        Color(red: 0.85, green: 0.90, blue: 0.98), // 银蓝色
                        Color(red: 0.70, green: 0.80, blue: 0.95)  // 深银蓝
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.96, blue: 0.98),
                        Color(red: 0.92, green: 0.92, blue: 0.96),
                        Color(red: 0.88, green: 0.88, blue: 0.94)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .gold:
            if achievement.isUnlocked {
                return LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.98, blue: 0.85),  // 香槟金
                        Color(red: 1.0, green: 0.90, blue: 0.50),  // 纯金色
                        Color(red: 0.95, green: 0.75, blue: 0.20)  // 深金色
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.96, blue: 0.94),
                        Color(red: 0.94, green: 0.90, blue: 0.86),
                        Color(red: 0.90, green: 0.84, blue: 0.78)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    // 获取边框渐变
    private var borderGradient: LinearGradient {
        if achievement.isUnlocked {
            switch achievement.level {
            case .bronze:
                return LinearGradient(
                    colors: [
                        Color(red: 0.90, green: 0.65, blue: 0.35).opacity(0.6),
                        Color(red: 0.85, green: 0.55, blue: 0.25).opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .silver:
                return LinearGradient(
                    colors: [
                        Color(red: 0.60, green: 0.70, blue: 0.90).opacity(0.6),
                        Color(red: 0.50, green: 0.60, blue: 0.85).opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .gold:
                return LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.75, blue: 0.20).opacity(0.7),
                        Color(red: 0.90, green: 0.65, blue: 0.10).opacity(0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        } else {
            return LinearGradient(
                colors: [
                    Color.gray.opacity(0.15),
                    Color.gray.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // 图标区域组件
    private var iconArea: some View {
            ZStack {
            // 多层背景光晕 - 创造深度感
                Circle()
                    .fill(
                        RadialGradient(
                            colors: achievement.isUnlocked ? [
                            achievement.level.color.opacity(0.35),
                            achievement.level.color.opacity(0.18),
                            achievement.level.color.opacity(0.08),
                                Color.clear
                            ] : [
                            Color.gray.opacity(0.12),
                            Color.gray.opacity(0.06),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                        endRadius: 28
                        )
                    )
                .frame(width: 56, height: 56)
                .blur(radius: achievement.isUnlocked ? 4 : 2)
                
            // 内层光晕 - 更强的中心光效
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: achievement.isUnlocked ? [
                            achievement.level.color.opacity(0.25),
                            achievement.level.color.opacity(0.08),
                                            Color.clear
                                        ] : [
                            Color.gray.opacity(0.08),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 0,
                        endRadius: 20
                                    )
                                )
                .frame(width: 40, height: 40)
                .blur(radius: 2)
            
            // 闪光效果 - 只在已解锁时显示
            if achievement.isUnlocked {
                sparkleEffects
            }
            
            // 主图标背景圆环 - 增加质感
            iconBackground
            
            // 主图标
            mainIcon
        }
    }
    
    // 闪光效果组件
    private var sparkleEffects: some View {
        Group {
            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 3, height: 3)
                .offset(x: -8, y: -8)
                .blur(radius: 0.5)
            
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 2, height: 2)
                .offset(x: 10, y: -6)
                .blur(radius: 0.5)
            
            Circle()
                .fill(achievement.level.color.opacity(0.7))
                .frame(width: 1.5, height: 1.5)
                .offset(x: -6, y: 12)
                .blur(radius: 0.3)
        }
    }
    
    // 图标背景组件
    private var iconBackground: some View {
                            Circle()
                                .fill(
                                    LinearGradient(
                    colors: achievement.isUnlocked ? [
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.05),
                        Color.clear
                    ] : [
                        Color.white.opacity(0.08),
                        Color.clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
            .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(
                        LinearGradient(
                            colors: achievement.isUnlocked ? [
                                achievement.level.color.opacity(0.3),
                                achievement.level.color.opacity(0.1),
                                Color.clear
                            ] : [
                                Color.gray.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                                            lineWidth: 0.5
                                        )
                                )
    }
    
    // 主图标组件
    private var mainIcon: some View {
        Text(achievement.icon)
            .font(.system(size: 32))
            .scaleEffect(achievement.isUnlocked ? 1.0 : 0.85)
                                .shadow(
                                    color: achievement.isUnlocked ? 
                                        achievement.level.color.opacity(0.5) : 
                                        Color.black.opacity(0.15),
                radius: achievement.isUnlocked ? 5 : 2,
                                    x: 0,
                y: achievement.isUnlocked ? 2 : 1
                                )
            .shadow(
                color: achievement.isUnlocked ? 
                    Color.white.opacity(0.4) : 
                    Color.clear,
                radius: 1,
                x: 0,
                y: -0.5
            )
    }
    
    // 针对不同背景优化的文字颜色
    private var optimizedTextColor: Color {
        if achievement.isUnlocked {
            switch achievement.level {
            case .bronze:
                // 青铜背景：使用深棕色确保对比度
                return Color(red: 0.45, green: 0.25, blue: 0.1)
            case .silver:
                // 银色背景：使用深蓝灰色
                return Color(red: 0.2, green: 0.3, blue: 0.45)
            case .gold:
                // 金色背景：使用深金棕色
                return Color(red: 0.6, green: 0.35, blue: 0.05)
            }
        } else {
            // 未解锁：使用中性深灰
            return Color.primary.opacity(0.85)
        }
    }
    
    // 文字阴影颜色
    private var textShadowColor: Color {
        if achievement.isUnlocked {
            switch achievement.level {
            case .bronze:
                return achievement.level.color.opacity(0.25)
            case .silver:
                return achievement.level.color.opacity(0.2)
            case .gold:
                return achievement.level.color.opacity(0.3)
                        }
        } else {
            return Color.black.opacity(0.15)
        }
    }
    
    // 进度百分比文字颜色 - 更强对比度
    private var progressPercentageTextColor: Color {
        if achievement.isUnlocked {
            switch achievement.level {
            case .bronze:
                // 青铜背景：使用更深的棕色
                return Color(red: 0.4, green: 0.2, blue: 0.05)
            case .silver:
                // 银色背景：使用更深的蓝色
                return Color(red: 0.15, green: 0.25, blue: 0.4)
            case .gold:
                // 金色背景：使用更深的金棕色
                return Color(red: 0.55, green: 0.3, blue: 0.0)
            }
        } else {
            // 未解锁：使用深灰色
            return Color.primary.opacity(0.9)
                }
            }
    
    // 进度辅助文字颜色
    private var progressSecondaryTextColor: Color {
        if achievement.isUnlocked {
            // 完成状态时减弱文字显示
            let isCompleted = achievement.progressPercentage >= 1.0
            let opacity = isCompleted ? 0.5 : 1.0
            
            switch achievement.level {
            case .bronze:
                // 青铜背景：深棕色
                return Color(red: 0.35, green: 0.18, blue: 0.08).opacity(opacity)
            case .silver:
                // 银色背景：深蓝灰色
                return Color(red: 0.2, green: 0.3, blue: 0.4).opacity(opacity)
            case .gold:
                // 金色背景：深金色
                return Color(red: 0.5, green: 0.25, blue: 0.02).opacity(opacity)
            }
        } else {
            // 未解锁：更亮的文字颜色，与进度条呼应
            return Color.primary.opacity(0.75)  // 从0.9降低到0.75，更亮
        }
    }
    
    // 进度文字阴影颜色
    private var progressTextShadowColor: Color {
        if achievement.isUnlocked {
            switch achievement.level {
            case .bronze:
                return achievement.level.color.opacity(0.2)
            case .silver:
                return achievement.level.color.opacity(0.15)
            case .gold:
                return achievement.level.color.opacity(0.25)
            }
        } else {
            return Color.black.opacity(0.1)
        }
    }
    
    // 进度条背景轨道颜色 - 深色槽提供对比
    private var progressTrackColors: [Color] {
        if achievement.isUnlocked {
            switch achievement.level {
            case .bronze:
                return [
                    Color(red: 0.6, green: 0.35, blue: 0.15).opacity(0.4),  // 深青铜色
                    Color(red: 0.5, green: 0.3, blue: 0.12).opacity(0.5)    // 更深的青铜色
                ]
            case .silver:
                return [
                    Color(red: 0.5, green: 0.6, blue: 0.75).opacity(0.4),   // 深银蓝色
                    Color(red: 0.4, green: 0.5, blue: 0.65).opacity(0.5)    // 更深的银蓝色
                ]
            case .gold:
                return [
                    Color(red: 0.7, green: 0.5, blue: 0.1).opacity(0.4),    // 深金色
                    Color(red: 0.6, green: 0.4, blue: 0.08).opacity(0.5)    // 更深的金色
                ]
            }
        } else {
            // 未解锁状态：根据等级使用对应的深色轨道
            switch achievement.level {
            case .bronze:
                return [
                    Color(red: 0.7, green: 0.7, blue: 0.75).opacity(0.5),   // 深蓝灰色
                    Color(red: 0.6, green: 0.6, blue: 0.7).opacity(0.6)     // 更深的蓝灰色
                ]
            case .silver:
                return [
                    Color(red: 0.65, green: 0.65, blue: 0.75).opacity(0.5), // 深银灰色
                    Color(red: 0.55, green: 0.55, blue: 0.7).opacity(0.6)   // 更深的银灰色
                ]
            case .gold:
                return [
                    Color(red: 0.7, green: 0.6, blue: 0.5).opacity(0.5),    // 深金灰色
                    Color(red: 0.6, green: 0.5, blue: 0.4).opacity(0.6)     // 更深的金灰色
                ]
            }
        }
    }
    
    // 进度条填充颜色 - 与背景融合的设计
    private var progressFillColors: [Color] {
        if achievement.isUnlocked {
            // 完成状态：与背景完全融合，未完成状态：轻微渐变融合
            let isCompleted = achievement.progressPercentage >= 1.0
            
            switch achievement.level {
            case .bronze:
                if isCompleted {
                    // 与青铜背景完全融合
                    return [Color(red: 0.96, green: 0.87, blue: 0.70)]
                } else {
                    // 轻微渐变，但整体接近背景色
                    return [
                        Color(red: 0.98, green: 0.92, blue: 0.80),   // 接近背景的浅色
                        Color(red: 0.96, green: 0.87, blue: 0.70),   // 背景中间色
                        Color(red: 0.88, green: 0.75, blue: 0.58)    // 稍深但仍接近背景
                    ]
                }
            case .silver:
                if isCompleted {
                    // 与银色背景完全融合
                    return [Color(red: 0.88, green: 0.92, blue: 0.99)]
                } else {
                    // 轻微渐变，但整体接近背景色
                    return [
                        Color(red: 0.94, green: 0.96, blue: 1.0),    // 接近背景的浅色
                        Color(red: 0.88, green: 0.92, blue: 0.99),   // 背景中间色
                        Color(red: 0.82, green: 0.88, blue: 0.96)    // 稍深但仍接近背景
                    ]
                }
            case .gold:
                if isCompleted {
                    // 与金色背景完全融合
                    return [Color(red: 1.0, green: 0.90, blue: 0.50)]
                } else {
                    // 轻微渐变，但整体接近背景色
                    return [
                        Color(red: 1.0, green: 0.95, blue: 0.65),    // 接近背景的浅色
                        Color(red: 1.0, green: 0.90, blue: 0.50),    // 背景中间色
                        Color(red: 0.98, green: 0.85, blue: 0.42)    // 稍深但仍接近背景
                    ]
                }
            }
        } else {
            // 未解锁状态：与各自的未解锁背景色融合
            switch achievement.level {
            case .bronze:
                // 比青铜未解锁背景稍亮
                return [Color(red: 0.97, green: 0.97, blue: 0.99)]  // 稍亮的蓝灰白
            case .silver:
                // 比银色未解锁背景稍亮
                return [Color(red: 0.95, green: 0.95, blue: 0.99)]  // 稍亮的银灰白
            case .gold:
                // 比金色未解锁背景稍亮
                return [Color(red: 0.97, green: 0.94, blue: 0.90)]  // 稍亮的金灰白
            }
        }
    }
    
    // 卡片背景组件
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(backgroundGradient)
            .overlay(cardBorder)
            .overlay(cardDecorations)
            .shadow(color: achievement.isUnlocked ? achievement.level.color.opacity(0.15) : .black.opacity(0.05), radius: 8, x: 0, y: 4)
            .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
            .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 0.5)
            .overlay(innerGlow)
            .overlay(surfaceGloss)
    }
    
    // 卡片边框
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                    colors: achievement.isUnlocked ? [
                        achievement.level.color.opacity(0.6),
                        achievement.level.color.opacity(0.3),
                        achievement.level.color.opacity(0.1),
                        Color.clear
                    ] : [
                        Color.gray.opacity(0.25),
                        Color.gray.opacity(0.1),
                        Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                lineWidth: 1.0
            )
    }
    
    // 卡片装饰 - 移除顶部横线，保持底部微妙装饰
    private var cardDecorations: some View {
        Group {
            if achievement.isUnlocked {
                VStack {
                    Spacer()
                    HStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        achievement.level.color.opacity(0.15),
                                        Color.clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 35, height: 1)
                            .cornerRadius(0.5)
                            .blur(radius: 0.6)
                    }
                    .padding(.bottom, 10)
                }
            }
        }
    }
    
    // 内部光晕
    private var innerGlow: some View {
        RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: [
                        Color.white.opacity(achievement.isUnlocked ? 0.5 : 0.2),
                        Color.white.opacity(achievement.isUnlocked ? 0.25 : 0.1),
                        Color.white.opacity(achievement.isUnlocked ? 0.1 : 0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .center
                ),
                lineWidth: 0.8
            )
            .padding(0.5)
    }
    
    // 表面光泽
    private var surfaceGloss: some View {
        Group {
            if achievement.isUnlocked {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.clear,
                                Color.clear,
                                achievement.level.color.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }
    
    var body: some View {
        ZStack {
        VStack(spacing: 0) {
            
            // 顶部图标区域 - 苹果风格的焦点设计
            iconArea
            .frame(height: 60)
            .padding(.top, 16)
            
            // 紧凑的内容组 - 苹果风格的信息密度
            VStack(spacing: 5) {
                // 等级标签 - 更加优雅精致
                Text(achievement.level.rawValue)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: achievement.isUnlocked ? [
                                    achievement.level.color,
                                        achievement.level.color.opacity(0.85)
                                    ] : [
                                        Color.gray.opacity(0.8),
                                        Color.gray.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                            LinearGradient(
                                colors: [
                                                Color.white.opacity(0.3),
                                                Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                                        lineWidth: 0.8
                        )
                            )
                    )
                        .shadow(
                            color: achievement.isUnlocked ? 
                            achievement.level.color.opacity(0.5) : 
                            Color.black.opacity(0.3),
                        radius: 2,
                            x: 0,
                        y: 1
                        )
                    
                // 成就名称 - 完美的视觉平衡
                Text(achievement.name)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(optimizedTextColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.9)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 10)
                    .padding(.top, 3)
                    .shadow(
                        color: textShadowColor,
                        radius: 1,
                        x: 0,
                        y: 0.8
                    )
                    .shadow(
                        color: Color.white.opacity(0.9),
                        radius: 0.5,
                        x: 0,
                        y: 0.5
                    )
            }
            .padding(.top, 8)
            
            Spacer(minLength: 12)
            
            // 底部进度信息 - 极简优雅
            VStack(spacing: 5) {
                // 进度数据 - 右对齐显示，优雅展示完成状态
                        HStack {
                            Spacer()
                    Text(achievement.progressText)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(progressSecondaryTextColor)
                        .shadow(
                            color: achievement.progressPercentage >= 1.0 ? 
                                Color.white.opacity(0.4) : Color.white.opacity(0.9),
                            radius: achievement.progressPercentage >= 1.0 ? 0.5 : 1,
                            x: 0,
                            y: achievement.progressPercentage >= 1.0 ? 0.4 : 0.8
                        )
                        .shadow(
                            color: achievement.progressPercentage >= 1.0 ? 
                                progressTextShadowColor.opacity(0.3) : progressTextShadowColor,
                            radius: achievement.progressPercentage >= 1.0 ? 0.4 : 0.8,
                            x: 0,
                            y: achievement.progressPercentage >= 1.0 ? 0.3 : 0.5
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(width: 70)
                
                // 进度条 - 美丽的等级专属渐变
                ZStack(alignment: .leading) {
                    // 背景轨道
                    RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                colors: progressTrackColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                            )
                        )
                        .frame(width: 70, height: 4)
                    
                    // 进度填充 - 完成状态用纯色，进行状态用渐变
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            // 根据完成状态选择填充方式
                            achievement.progressPercentage >= 1.0 ?
                                AnyShapeStyle(progressFillColors.first ?? Color.gray) :
                                AnyShapeStyle(LinearGradient(
                                    colors: progressFillColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                ))
                                    )
                        .frame(width: 70 * achievement.progressPercentage, height: 4)
                                .shadow(
                                    color: achievement.isUnlocked ? 
                                progressFillColors.first?.opacity(0.4) ?? Color.clear : 
                                        Color.clear,
                            radius: 1.5,
                                    x: 0,
                            y: 0.8
                        )
                .overlay(
                            // 顶部高光效果
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                            LinearGradient(
                                colors: [
                                            Color.white.opacity(achievement.isUnlocked ? 0.4 : 0.2),
                                            Color.white.opacity(achievement.isUnlocked ? 0.2 : 0.1),
                                    Color.clear
                                ],
                                        startPoint: .top,
                                endPoint: .center
                                    )
                                )
                                .frame(width: 70 * achievement.progressPercentage, height: 4)
                        )
                }
            }
            .padding(.bottom, 18)
        }
        .frame(width: 95, height: 135)  // 稍微增加高度以适应等级标签
        .padding(.horizontal, 6)  // 减小水平内边距
        .padding(.vertical, 10)   // 减小垂直内边距
        .background(cardBackground)
        .opacity(achievement.isUnlocked ? 1.0 : 0.75)
        // 移除 scaleEffect，保持所有卡片大小一致
        .animation(.easeInOut(duration: 0.3), value: achievement.isUnlocked)
        
        // 固定按钮 (只在详情页显示)
        if showPinButton {
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        evaluator.toggleAchievementPin(achievementId: achievement.id)
                    }) {
                        ZStack {
                            // 背景圆圈
                            Circle()
                                .fill(currentAchievement.isPinned ? Color.warmAccent : Color.white)
                                .frame(width: 28, height: 28)
                                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                            
                            // 图标
                            Image(systemName: currentAchievement.isPinned ? "pin.fill" : "pin")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(currentAchievement.isPinned ? .white : .gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(currentAchievement.isPinned ? 1.1 : 1.0)
                    .animation(.easeOut(duration: 0.15), value: currentAchievement.isPinned)
                    .id("pin-button-\(achievement.id)-\(currentAchievement.isPinned)") // 强制重新渲染按钮
                }
                Spacer()
            }
            .padding(8)
        }
        }
        .id("achievement-card-\(achievement.id)-\(currentAchievement.isPinned)") // 确保固定状态变化时重新渲染整个卡片
    }
}

// MARK: - 成就详情页面
struct AchievementDetailView: View {
    let evaluator: AchievementEvaluator
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(evaluator.achievements) { achievement in
                        AchievementDetailCard(achievement: achievement, showPinButton: true)
                            .id("\(achievement.id)-\(achievement.isPinned)") // 确保固定状态变化时重新渲染
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .navigationTitle("全部成就")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("完成") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(Color(red: 149/255, green: 138/255, blue: 177/255)))
        }
        .onAppear {
            // 详情页面出现时刷新成就数据
            evaluator.updateAllAchievements(using: modelContext)
        }
    }
}

// MARK: - 详情卡片视图
struct AchievementDetailCard: View {
    let achievement: CYAchievement
    let showPinButton: Bool
    @ObservedObject private var evaluator = AchievementEvaluator.shared
    
    // 获取实时的固定状态
    private var currentAchievement: CYAchievement {
        return evaluator.achievements.first(where: { $0.id == achievement.id }) ?? achievement
    }
    
    // 获取详情卡片的高级渐变色彩
    private var detailBackgroundGradient: LinearGradient {
        switch achievement.level {
        case .bronze:
            if achievement.isUnlocked {
                return LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.97, blue: 0.90), // 温暖象牙白
                        Color(red: 0.98, green: 0.92, blue: 0.78), // 浅金
                        Color(red: 0.96, green: 0.88, blue: 0.68), // 青铜调
                        Color(red: 0.94, green: 0.82, blue: 0.58)  // 深青铜
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [
                        Color(red: 0.99, green: 0.99, blue: 0.99),
                        Color(red: 0.96, green: 0.96, blue: 0.98),
                        Color(red: 0.93, green: 0.93, blue: 0.97),
                        Color(red: 0.90, green: 0.90, blue: 0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .silver:
            if achievement.isUnlocked {
                return LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.97, blue: 1.0),  // 冷白
                        Color(red: 0.90, green: 0.93, blue: 0.98), // 银蓝
                        Color(red: 0.82, green: 0.87, blue: 0.96), // 中银蓝
                        Color(red: 0.74, green: 0.81, blue: 0.94)  // 深银蓝
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.97, blue: 0.99),
                        Color(red: 0.94, green: 0.94, blue: 0.97),
                        Color(red: 0.91, green: 0.91, blue: 0.95),
                        Color(red: 0.88, green: 0.88, blue: 0.93)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .gold:
            if achievement.isUnlocked {
                return LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.99, blue: 0.90),  // 香槟金
                        Color(red: 1.0, green: 0.94, blue: 0.65),  // 纯金
                        Color(red: 0.98, green: 0.85, blue: 0.40), // 中金
                        Color(red: 0.95, green: 0.76, blue: 0.25)  // 深金
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [
                        Color(red: 0.99, green: 0.97, blue: 0.95),
                        Color(red: 0.96, green: 0.92, blue: 0.88),
                        Color(red: 0.93, green: 0.87, blue: 0.81),
                        Color(red: 0.90, green: 0.82, blue: 0.74)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    var body: some View {
        ZStack {
        HStack(spacing: 20) {
            // 左侧图标区域
            VStack(spacing: 12) {
                // 图标背景
                ZStack {
                    // 外圈光晕效果
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: achievement.isUnlocked ? [
                                    achievement.level.color.opacity(0.3),
                                    achievement.level.color.opacity(0.15),
                                    achievement.level.color.opacity(0.05),
                                    Color.clear
                                ] : [
                                    Color.gray.opacity(0.15),
                                    Color.gray.opacity(0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 35
                            )
                        )
                        .frame(width: 70, height: 70)
                        .blur(radius: 3)
                    
                    // 主背景圆
                    Circle()
                        .fill(
                            achievement.isUnlocked ?
                            RadialGradient(
                                colors: [
                                    Color(.systemBackground),
                                    achievement.level.color.opacity(0.08),
                                    achievement.level.color.opacity(0.03)
                                ],
                                center: UnitPoint(x: 0.3, y: 0.3),
                                startRadius: 0,
                                endRadius: 35
                            ) :
                            RadialGradient(
                                colors: [
                                    Color(.systemBackground),
                                    Color(.secondarySystemBackground).opacity(0.5)
                                ],
                                center: UnitPoint(x: 0.3, y: 0.3),
                                startRadius: 0,
                                endRadius: 35
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(
                                    achievement.isUnlocked ?
                                    LinearGradient(
                                        colors: [
                                            achievement.level.color.opacity(0.4),
                                            achievement.level.color.opacity(0.2),
                                            achievement.level.color.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [
                                            Color.gray.opacity(0.2),
                                            Color.gray.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(
                            color: achievement.isUnlocked ? 
                                achievement.level.color.opacity(0.2) : 
                                Color.black.opacity(0.05),
                            radius: achievement.isUnlocked ? 8 : 4,
                            x: 0,
                            y: 4
                        )
                    
                    Text(achievement.icon)
                        .font(.system(size: 30))
                        .scaleEffect(achievement.isUnlocked ? 1.0 : 0.85)
                        .shadow(
                            color: achievement.isUnlocked ? 
                                achievement.level.color.opacity(0.4) : 
                                Color.black.opacity(0.15),
                            radius: achievement.isUnlocked ? 4 : 2,
                            x: 0,
                            y: 2
                        )
                }
                
                // 等级标签
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                achievement.isUnlocked ?
                                RadialGradient(
                                    colors: [
                                        achievement.level.color.opacity(0.9),
                                        achievement.level.color.opacity(0.7)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 10
                                ) :
                                RadialGradient(
                                    colors: [
                                        Color.gray.opacity(0.6),
                                        Color.gray.opacity(0.4)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 10
                                )
                            )
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                            .shadow(
                                color: achievement.isUnlocked ? 
                                    achievement.level.color.opacity(0.5) : 
                                    Color.black.opacity(0.2),
                                radius: 3,
                                x: 0,
                                y: 2
                            )
                        
                        Text(achievement.level.emoji)
                            .font(.system(size: 11))
                    }
                    
                    Text(achievement.level.rawValue)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(achievement.isUnlocked ? achievement.level.color : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    achievement.isUnlocked ?
                                    LinearGradient(
                                        colors: [
                                            achievement.level.color.opacity(0.15),
                                            achievement.level.color.opacity(0.08)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [
                                            Color.gray.opacity(0.1),
                                            Color.gray.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            achievement.isUnlocked ? 
                                                achievement.level.color.opacity(0.3) : 
                                                Color.gray.opacity(0.2),
                                            lineWidth: 1
                                        )
                                )
                        )
                }
            }
            .frame(width: 90)
            
            // 右侧内容区域
            VStack(alignment: .leading, spacing: 12) {
                // 标题区域
                VStack(alignment: .leading, spacing: 6) {
                    Text(achievement.name)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .shadow(
                            color: achievement.isUnlocked ? 
                                achievement.level.color.opacity(0.2) : 
                                Color.clear,
                            radius: 1,
                            x: 0,
                            y: 1
                        )
                    
                    // 达成条件说明
                    VStack(alignment: .leading, spacing: 4) {
                        Text("达成条件")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary.opacity(0.8))
                        
                        Text(getAchievementCondition(for: achievement))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        
                        // 心有灵犀成就显示前三聊天角色
                        if achievement.name == "心有灵犀" {
                            TopCharactersView()
                                .padding(.top, 8)
                        }
                    }
                    .padding(.top, 4)
                }
                
                // 进度区域
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("完成进度")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(achievement.isUnlocked ? .secondary : Color.primary.opacity(0.6))
                        
                        Spacer()
                        
                        Text(achievement.progressText)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(achievement.isUnlocked ? .primary : Color.primary.opacity(0.75))
                        
                        Text("(\(Int(achievement.progressPercentage * 100))%)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(achievement.isUnlocked ? achievement.level.color : Color.primary.opacity(0.65))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(
                                        achievement.isUnlocked ? 
                                            achievement.level.color.opacity(0.1) : 
                                            Color.gray.opacity(0.1)
                                    )
                            )
                    }
                    
                    // 背景融合进度条 - 详细视图版本
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // 背景轨道 - 深色槽提供对比
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: achievement.isUnlocked ? detailProgressTrackColors : [
                                            Color.gray.opacity(0.25),
                                            Color.gray.opacity(0.35)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                                )
                            
                            // 进度填充 - 与背景融合的设计
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    // 根据完成状态选择填充方式
                                    achievement.progressPercentage >= 1.0 ?
                                        AnyShapeStyle(detailProgressFillColors.first ?? Color.gray) :
                                        AnyShapeStyle(LinearGradient(
                                            colors: detailProgressFillColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                        ))
                                )
                                .frame(
                                    width: geometry.size.width * achievement.progressPercentage,
                                    height: 12
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(achievement.isUnlocked ? 0.35 : 0.15),
                                                    Color.white.opacity(achievement.isUnlocked ? 0.15 : 0.08),
                                                    Color.clear
                                                ],
                                                startPoint: .top,
                                                endPoint: .center
                                            )
                                        )
                                        .frame(
                                            width: geometry.size.width * achievement.progressPercentage,
                                            height: 12
                                        )
                                )
                                .shadow(
                                    color: achievement.isUnlocked ? 
                                        detailProgressFillColors.first?.opacity(0.4) ?? Color.clear : 
                                        Color.clear,
                                    radius: 2,
                                    x: 0,
                                    y: 1
                                )
                                .animation(.easeInOut(duration: 1.0), value: achievement.progressPercentage)
                        }
                    }
                    .frame(height: 12)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(detailBackgroundGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            achievement.isUnlocked ?
                            LinearGradient(
                                colors: [
                                    achievement.level.color.opacity(0.3),
                                    achievement.level.color.opacity(0.15),
                                    achievement.level.color.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(0.15),
                                    Color.gray.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(
                    color: achievement.isUnlocked ? 
                        achievement.level.color.opacity(0.12) : 
                        Color.black.opacity(0.04),
                    radius: achievement.isUnlocked ? 16 : 8,
                    x: 0,
                    y: achievement.isUnlocked ? 8 : 4
                )
                .overlay(
                    // 内部高光
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(achievement.isUnlocked ? 0.5 : 0.3),
                                    Color.white.opacity(achievement.isUnlocked ? 0.2 : 0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            ),
                            lineWidth: 1
                        )
                        .padding(1.5)
                )
        )
        .opacity(achievement.isUnlocked ? 1.0 : 0.8)
        .scaleEffect(achievement.isUnlocked ? 1.0 : 0.98)
        
        // 固定按钮 (只在详情页显示)
        if showPinButton {
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        evaluator.toggleAchievementPin(achievementId: achievement.id)
                    }) {
                        ZStack {
                            // 背景圆圈
                            Circle()
                                .fill(currentAchievement.isPinned ? Color.warmAccent : Color.white)
                                .frame(width: 32, height: 32)
                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                            
                            // 图标
                            Image(systemName: currentAchievement.isPinned ? "pin.fill" : "pin")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(currentAchievement.isPinned ? .white : .gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(currentAchievement.isPinned ? 1.1 : 1.0)
                    .animation(.easeOut(duration: 0.15), value: currentAchievement.isPinned)
                    .id("detail-pin-button-\(achievement.id)-\(currentAchievement.isPinned)") // 强制重新渲染按钮
                }
                Spacer()
            }
            .padding(12)
        }
        }
        .id("achievement-detail-card-\(achievement.id)-\(currentAchievement.isPinned)") // 确保固定状态变化时重新渲染整个详情卡片
    }
    
    // 详细视图进度条背景轨道颜色 - 深色槽提供对比
    private var detailProgressTrackColors: [Color] {
        if achievement.isUnlocked {
            switch achievement.level {
            case .bronze:
                return [
                    Color(red: 0.6, green: 0.35, blue: 0.15).opacity(0.4),  // 深青铜色
                    Color(red: 0.5, green: 0.3, blue: 0.12).opacity(0.5)    // 更深的青铜色
                ]
            case .silver:
                return [
                    Color(red: 0.5, green: 0.6, blue: 0.75).opacity(0.4),   // 深银蓝色
                    Color(red: 0.4, green: 0.5, blue: 0.65).opacity(0.5)    // 更深的银蓝色
                ]
            case .gold:
                return [
                    Color(red: 0.7, green: 0.5, blue: 0.1).opacity(0.4),    // 深金色
                    Color(red: 0.6, green: 0.4, blue: 0.08).opacity(0.5)    // 更深的金色
                ]
            }
        } else {
            // 未解锁状态：根据等级使用对应的深色轨道
            switch achievement.level {
            case .bronze:
                return [
                    Color(red: 0.7, green: 0.7, blue: 0.75).opacity(0.5),   // 深蓝灰色
                    Color(red: 0.6, green: 0.6, blue: 0.7).opacity(0.6)     // 更深的蓝灰色
                ]
            case .silver:
                return [
                    Color(red: 0.65, green: 0.65, blue: 0.75).opacity(0.5), // 深银灰色
                    Color(red: 0.55, green: 0.55, blue: 0.7).opacity(0.6)   // 更深的银灰色
                ]
            case .gold:
                return [
                    Color(red: 0.7, green: 0.6, blue: 0.5).opacity(0.5),    // 深金灰色
                    Color(red: 0.6, green: 0.5, blue: 0.4).opacity(0.6)     // 更深的金灰色
                ]
            }
        }
    }
    
    // 详细视图进度条填充颜色 - 与背景融合的设计
    private var detailProgressFillColors: [Color] {
        if achievement.isUnlocked {
            // 完成状态：与背景完全融合，未完成状态：轻微渐变融合
            let isCompleted = achievement.progressPercentage >= 1.0
            
            switch achievement.level {
            case .bronze:
                if isCompleted {
                    // 与青铜背景完全融合
                    return [Color(red: 0.96, green: 0.87, blue: 0.70)]
                } else {
                    // 轻微渐变，但整体接近背景色
                    return [
                        Color(red: 0.98, green: 0.92, blue: 0.80),   // 接近背景的浅色
                        Color(red: 0.96, green: 0.87, blue: 0.70),   // 背景中间色
                        Color(red: 0.88, green: 0.75, blue: 0.58)    // 稍深但仍接近背景
                    ]
                }
            case .silver:
                if isCompleted {
                    // 与银色背景完全融合
                    return [Color(red: 0.88, green: 0.92, blue: 0.99)]
                } else {
                    // 轻微渐变，但整体接近背景色
                    return [
                        Color(red: 0.94, green: 0.96, blue: 1.0),    // 接近背景的浅色
                        Color(red: 0.88, green: 0.92, blue: 0.99),   // 背景中间色
                        Color(red: 0.82, green: 0.88, blue: 0.96)    // 稍深但仍接近背景
                    ]
                }
            case .gold:
                if isCompleted {
                    // 与金色背景完全融合
                    return [Color(red: 1.0, green: 0.90, blue: 0.50)]
                } else {
                    // 轻微渐变，但整体接近背景色
                    return [
                        Color(red: 1.0, green: 0.95, blue: 0.65),    // 接近背景的浅色
                        Color(red: 1.0, green: 0.90, blue: 0.50),    // 背景中间色
                        Color(red: 0.98, green: 0.85, blue: 0.42)    // 稍深但仍接近背景
                    ]
                }
            }
        } else {
            // 未解锁状态：比背景稍亮，保持微妙的可见性
            switch achievement.level {
            case .bronze:
                // 比青铜未解锁背景稍亮
                return [Color(red: 0.97, green: 0.97, blue: 0.99)]  // 稍亮的蓝灰白
            case .silver:
                // 比银色未解锁背景稍亮
                return [Color(red: 0.95, green: 0.95, blue: 0.99)]  // 稍亮的银灰白
            case .gold:
                // 比金色未解锁背景稍亮
                return [Color(red: 0.97, green: 0.94, blue: 0.90)]  // 稍亮的金灰白
            }
        }
    }
    
    // 获取成就达成条件说明
    private func getAchievementCondition(for achievement: CYAchievement) -> String {
        switch achievement.name {
        case "心有灵犀":
            switch achievement.level {
            case .bronze:
                return "与单个AI角色累计对话10轮，建立初步连接"
            case .silver:
                return "与单个AI角色累计对话50轮，发展深度关系"
            case .gold:
                return "与单个AI角色累计对话200轮，成为真正知音"
            }
            
        case "共鸣之星":
            switch achievement.level {
            case .bronze:
                return "发布的内容获得10个点赞，获得初步认可"
            case .silver:
                return "发布的内容获得100个点赞，成为受欢迎用户"
            case .gold:
                return "发布的内容获得500个点赞，成为社区明星"
            }
            
        case "时光旅人":
            switch achievement.level {
            case .bronze:
                return "累计7天有真实活动（发消息、发帖、评论等），养成良好习惯"
            case .silver:
                return "累计30天有真实活动，展现持续热情"
            case .gold:
                return "累计100天有真实活动，成为忠实用户"
            }
            
        case "夜猫子":
            switch achievement.level {
            case .bronze:
                return "在深夜时段(22:00-02:00)累计发送7条消息"
            case .silver:
                return "在深夜时段(22:00-02:00)累计发送30条消息"
            case .gold:
                return "在深夜时段(22:00-02:00)累计发送100条消息，成为夜之主宰"
            }
            
        case "次元段位":
            switch achievement.level {
            case .bronze:
                return "综合评分达到200分，获得新人段位"
            case .silver:
                return "综合评分达到600分，晋升探索者段位"
            case .gold:
                return "综合评分达到1200分，登顶大师段位"
            }
            
        case "领域漫游者":
            switch achievement.level {
            case .bronze:
                return "深度探索1个领域（与该领域5个不同角色互动）"
            case .silver:
                return "深度探索3个不同领域（每个领域5个角色）"
            case .gold:
                return "深度探索6个不同领域（每个领域5个角色），成为全能探索者"
            }
            
        case "晨光对话":
            switch achievement.level {
            case .bronze:
                return "在早晨时段(06:00-10:00)累计发送7条消息"
            case .silver:
                return "在早晨时段(06:00-10:00)累计发送30条消息"
            case .gold:
                return "在早晨时段(06:00-10:00)累计发送100条消息，成为晨光使者"
            }
            
        case "社交达人":
            switch achievement.level {
            case .bronze:
                return "与15个不同的AI角色都有过对话互动，开启社交之路"
            case .silver:
                return "与40个不同的AI角色都有过对话互动，扩展交际圈"
            case .gold:
                return "与80个不同的AI角色都有过对话互动，成为真正的社交达人"
            }
            
        default:
            return "完成相关任务即可获得此成就"
        }
    }
}

// MARK: - 前三聊天角色显示组件
struct TopCharactersView: View {
    @ObservedObject private var evaluator = AchievementEvaluator.shared
    @State private var topCharacters: [(characterId: String, messageCount: Int, character: CharacterSystem.CharacterIdentity?)] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            titleRow
            characterList
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            loadTopCharacters()
        }
        .onChange(of: evaluator.achievements) { oldValue, newValue in
            loadTopCharacters()
        }
    }
    
    // 标题行
    private var titleRow: some View {
        HStack {
            Text("聊天最多的角色")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    // 角色列表
    private var characterList: some View {
        Group {
            if topCharacters.isEmpty {
                emptyState
            } else {
                characterRow
            }
        }
    }
    
    // 空状态
    private var emptyState: some View {
        HStack {
            Text("暂无对话记录")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary.opacity(0.7))
            Spacer()
        }
    }
    
    // 角色行
    private var characterRow: some View {
        HStack(spacing: 12) {
            ForEach(Array(topCharacters.enumerated()), id: \.offset) { index, characterData in
                CharacterRankItem(
                    character: characterData.character,
                    messageCount: characterData.messageCount,
                    rank: index
                )
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // 加载前三角色数据
    private func loadTopCharacters() {
        topCharacters = evaluator.getTopThreeCharactersForHeartConnection()
    }
}

// MARK: - 角色排名项组件
struct CharacterRankItem: View {
    let character: CharacterSystem.CharacterIdentity?
    let messageCount: Int
    let rank: Int
    
    var body: some View {
        VStack(spacing: 4) {
            avatarSection
            infoSection
        }
        .frame(width: 50)
    }
    
    // 头像区域
    private var avatarSection: some View {
        ZStack {
            backgroundCircle
            avatarContent
            rankBadge
        }
    }
    
    // 背景圆圈
    private var backgroundCircle: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        rankColor.opacity(0.2),
                        rankColor.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 36, height: 36)
            .overlay(
                Circle()
                    .stroke(rankColor.opacity(0.4), lineWidth: 1.5)
            )
    }
    
    // 头像内容
    @ViewBuilder
    private var avatarContent: some View {
        if let character = character {
            // 优先尝试加载自定义头像
            if let customImage = CustomAvatarLoader.shared.loadCustomAvatar(characterId: character.id, avatarName: character.avatarName) {
                Image(uiImage: customImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
            } else if UIImage(named: character.avatarName) != nil {
                // 如果是系统内置角色，使用bundle中的图片
                Image(character.avatarName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
                } else {
                    // 使用统一的CharacterAvatarService显示首字母头像
                    CharacterAvatarService.shared.getAvatarView(
                        for: character.id,
                        name: character.name,
                        size: 28
                    )
                }
        } else {
            Text("?")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(rankColor)
                .frame(width: 28, height: 28)
        }
    }
    
    // 排名徽章
    private var rankBadge: some View {
        VStack {
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(rankColor)
                        .frame(width: 16, height: 16)
                        .shadow(color: rankColor.opacity(0.5), radius: 2, x: 0, y: 1)
                    
                    Text("\(rank + 1)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 6, y: -6)
            }
            Spacer()
        }
    }
    
    // 信息区域
    private var infoSection: some View {
        VStack(spacing: 2) {
            Text(character?.name ?? "未知")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text("\(messageCount)轮")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    // 排名颜色
    private var rankColor: Color {
        switch rank {
        case 0: return Color(red: 1.0, green: 0.84, blue: 0.0)  // 金色
        case 1: return Color(red: 0.75, green: 0.75, blue: 0.75) // 银色
        case 2: return Color(red: 0.80, green: 0.50, blue: 0.20) // 铜色
        default: return Color.gray
        }
    }
}

// MARK: - 预览
#Preview {
    NewAchievementView()
} 
