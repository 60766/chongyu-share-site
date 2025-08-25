import SwiftUI

// 颜色预览视图 - 用于调试和预览所有等级的渐变效果
struct ColorPreviewView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("🎨 成就等级颜色预览")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                // 青铜等级预览
                VStack(spacing: 15) {
                    Text("🥉 青铜等级")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 15) {
                        VStack {
                            Text("已解锁")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.97, blue: 0.90),  // 温暖象牙白
                                            Color(red: 0.96, green: 0.87, blue: 0.70), // 浅金色
                                            Color(red: 0.80, green: 0.52, blue: 0.25)  // 青铜色调
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 80)
                                .overlay(
                                    Text("RGB:\n255,247,230\n245,222,179\n205,133,63")
                                        .font(.system(size: 8))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.black.opacity(0.7))
                                )
                        }
                        
                        VStack {
                            Text("未解锁")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.98, green: 0.98, blue: 0.98), // 纯净白
                                            Color(red: 0.94, green: 0.96, blue: 0.97), // 淡蓝灰
                                            Color(red: 0.89, green: 0.91, blue: 0.94)  // 深蓝灰
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 80)
                                .overlay(
                                    Text("RGB:\n250,250,250\n240,244,248\n226,232,240")
                                        .font(.system(size: 8))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.black.opacity(0.7))
                                )
                        }
                    }
                }
                
                Divider()
                
                // 白银等级预览
                VStack(spacing: 15) {
                    Text("🥈 白银等级")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 15) {
                        VStack {
                            Text("已解锁")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.97, green: 0.98, blue: 1.0),  // 冷白色
                                            Color(red: 0.88, green: 0.92, blue: 0.99), // 银蓝色
                                            Color(red: 0.75, green: 0.82, blue: 0.95)  // 深银蓝
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 80)
                                .overlay(
                                    Text("RGB:\n247,250,255\n224,234,252\n192,209,242")
                                        .font(.system(size: 8))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.black.opacity(0.7))
                                )
                        }
                        
                        VStack {
                            Text("未解锁")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.97, green: 0.97, blue: 0.98),
                                            Color(red: 0.92, green: 0.92, blue: 0.96),
                                            Color(red: 0.86, green: 0.86, blue: 0.93)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 80)
                                .overlay(
                                    Text("RGB:\n247,247,250\n234,234,244\n220,220,238")
                                        .font(.system(size: 8))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.black.opacity(0.7))
                                )
                        }
                    }
                }
                
                Divider()
                
                // 黄金等级预览
                VStack(spacing: 15) {
                    Text("🥇 黄金等级")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 15) {
                        VStack {
                            Text("已解锁")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.98, blue: 0.85),  // 香槟金
                                            Color(red: 1.0, green: 0.90, blue: 0.50),  // 纯金色
                                            Color(red: 0.95, green: 0.75, blue: 0.20)  // 深金色
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 80)
                                .overlay(
                                    Text("RGB:\n255,251,217\n255,230,128\n242,191,51")
                                        .font(.system(size: 8))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.black.opacity(0.7))
                                )
                        }
                        
                        VStack {
                            Text("未解锁")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.98, green: 0.96, blue: 0.94),
                                            Color(red: 0.94, green: 0.90, blue: 0.86),
                                            Color(red: 0.90, green: 0.84, blue: 0.78)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 80)
                                .overlay(
                                    Text("RGB:\n250,245,240\n240,230,220\n230,214,200")
                                        .font(.system(size: 8))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.black.opacity(0.7))
                                )
                        }
                    }
                }
                
                Divider()
                
                // 实际成就卡片预览
                VStack(spacing: 15) {
                    Text("📱 实际成就卡片效果")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    // 模拟成就卡片
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                        // 青铜已解锁 - 进度中
                        AchievementCardPreview(
                            name: "心灵共振",
                            icon: "🌟",
                            level: .bronze,
                            isUnlocked: true,
                            progress: 75
                        )
                        
                        // 青铜未解锁
                        AchievementCardPreview(
                            name: "璀璨之星",
                            icon: "✨",
                            level: .bronze,
                            isUnlocked: false,
                            progress: 40
                        )
                        
                        // 白银已解锁 - 进度中
                        AchievementCardPreview(
                            name: "时空旅者",
                            icon: "🕰️",
                            level: .silver,
                            isUnlocked: true,
                            progress: 85
                        )
                        
                        // 白银未解锁
                        AchievementCardPreview(
                            name: "夜空守望",
                            icon: "🌙",
                            level: .silver,
                            isUnlocked: false,
                            progress: 30
                        )
                        
                        // 黄金已解锁 - 进度中
                        AchievementCardPreview(
                            name: "次元大师",
                            icon: "👑",
                            level: .gold,
                            isUnlocked: true,
                            progress: 65
                        )
                        
                        // 黄金未解锁
                        AchievementCardPreview(
                            name: "知识探索",
                            icon: "🧭",
                            level: .gold,
                            isUnlocked: false,
                            progress: 20
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("颜色预览")
        .navigationBarTitleDisplayMode(.large)
    }
}

// 成就卡片预览组件
struct AchievementCardPreview: View {
    let name: String
    let icon: String
    let level: AchievementLevel
    let isUnlocked: Bool
    let progress: Int
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部图标区域 - 苹果风格的焦点设计
            ZStack {
                // 多层背景光晕
                Circle()
                    .fill(
                        RadialGradient(
                            colors: isUnlocked ? [
                                level.color.opacity(0.35),
                                level.color.opacity(0.18),
                                level.color.opacity(0.08),
                                Color.clear
                            ] : [
                                Color.gray.opacity(0.12),
                                Color.gray.opacity(0.06),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 32
                        )
                    )
                    .frame(width: 64, height: 64)
                    .blur(radius: isUnlocked ? 4 : 2)
                
                // 内层光晕
                Circle()
                    .fill(
                        RadialGradient(
                            colors: isUnlocked ? [
                                level.color.opacity(0.25),
                                level.color.opacity(0.08),
                                Color.clear
                            ] : [
                                Color.gray.opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 24
                        )
                    )
                    .frame(width: 48, height: 48)
                    .blur(radius: 2)
                
                // 闪光效果
                if isUnlocked {
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 2.5, height: 2.5)
                        .offset(x: -10, y: -10)
                        .blur(radius: 0.4)
                    
                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 2, height: 2)
                        .offset(x: 12, y: -8)
                        .blur(radius: 0.4)
                }
                
                // 主图标背景
                Circle()
                    .fill(backgroundGradient)
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: isUnlocked ? [
                                        level.color.opacity(0.3),
                                        level.color.opacity(0.1),
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
                
                Text(icon)
                    .font(.system(size: 30))
                    .shadow(
                        color: isUnlocked ? 
                            level.color.opacity(0.4) : 
                            Color.black.opacity(0.15),
                        radius: isUnlocked ? 3 : 1,
                        x: 0,
                        y: isUnlocked ? 1 : 0.5
                    )
            }
            .frame(height: 56)
            .padding(.top, 14)
            
            // 紧凑的内容组 - 苹果风格的信息密度
            VStack(spacing: 4) {
                // 等级标签 - 更加优雅精致
                Text(level.rawValue)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: isUnlocked ? [
                                        level.color,
                                        level.color.opacity(0.85)
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
                                        lineWidth: 0.6
                                    )
                            )
                    )
                    .shadow(
                        color: isUnlocked ? 
                            level.color.opacity(0.5) : 
                            Color.black.opacity(0.3),
                        radius: 1.5,
                        x: 0,
                        y: 0.8
                    )
            
                // 成就名称 - 完美的视觉平衡
            Text(name)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(previewOptimizedTextColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
                    .padding(.top, 2)
                    .shadow(
                        color: previewTextShadowColor,
                        radius: 0.8,
                        x: 0,
                        y: 0.6
                    )
                    .shadow(
                        color: Color.white.opacity(0.9),
                        radius: 0.4,
                        x: 0,
                        y: 0.4
                    )
            }
            .padding(.top, 6)
            
            Spacer(minLength: 8)
            
            // 底部进度信息 - 极简优雅
            VStack(spacing: 4) {
                // 进度数据 - 右对齐显示，优雅展示完成状态
                HStack {
                    Spacer()
                    Text("\(progress)/100")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(previewProgressSecondaryTextColor)
                        .shadow(
                            color: progress >= 100 ? 
                                Color.white.opacity(0.3) : Color.white.opacity(0.9),
                            radius: progress >= 100 ? 0.4 : 0.8,
                            x: 0,
                            y: progress >= 100 ? 0.3 : 0.6
                        )
                        .shadow(
                            color: progress >= 100 ? 
                                previewProgressTextShadowColor.opacity(0.3) : previewProgressTextShadowColor,
                            radius: progress >= 100 ? 0.3 : 0.6,
                            x: 0,
                            y: progress >= 100 ? 0.2 : 0.4
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(width: 55)
                
                // 进度条 - 美丽的等级专属渐变
                ZStack(alignment: .leading) {
                    // 背景轨道
                    RoundedRectangle(cornerRadius: 1.8)
                        .fill(
                            LinearGradient(
                                colors: previewProgressTrackColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 55, height: 3.5)
                    
                    // 进度填充 - 完成状态用纯色，进行状态用渐变
                    RoundedRectangle(cornerRadius: 1.8)
                        .fill(
                            // 根据完成状态选择填充方式
                            progress >= 100 ?
                                AnyShapeStyle(previewProgressFillColors.first ?? Color.gray) :
                                AnyShapeStyle(LinearGradient(
                                    colors: previewProgressFillColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                        .frame(width: 55 * Double(progress) / 100.0, height: 3.5)
                        .shadow(
                            color: isUnlocked ? 
                                previewProgressFillColors.first?.opacity(0.4) ?? Color.clear : 
                                Color.clear,
                            radius: 1.2,
                            x: 0,
                            y: 0.6
                        )
                        .overlay(
                            // 顶部高光效果
                            RoundedRectangle(cornerRadius: 1.8)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(isUnlocked ? 0.35 : 0.15),
                                            Color.white.opacity(isUnlocked ? 0.15 : 0.08),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                )
                                .frame(width: 55 * Double(progress) / 100.0, height: 3.5)
                        )
                }
            }
            .padding(.bottom, 14)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBackgroundGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: isUnlocked ? [
                                    level.color.opacity(0.6),
                                    level.color.opacity(0.3),
                                    level.color.opacity(0.1),
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
                )
                .shadow(color: isUnlocked ? level.color.opacity(0.15) : .black.opacity(0.05), radius: 8, x: 0, y: 4)
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isUnlocked ? 0.5 : 0.2),
                                    Color.white.opacity(isUnlocked ? 0.25 : 0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            ),
                            lineWidth: 0.8
                        )
                        .padding(0.5)
                )
        )
    }
    
    // 针对不同背景优化的文字颜色（预览版）
    private var previewOptimizedTextColor: Color {
        if isUnlocked {
            switch level {
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
    
    // 文字阴影颜色（预览版）
    private var previewTextShadowColor: Color {
        if isUnlocked {
            switch level {
            case .bronze:
                return level.color.opacity(0.25)
            case .silver:
                return level.color.opacity(0.2)
            case .gold:
                return level.color.opacity(0.3)
            }
        } else {
            return Color.black.opacity(0.15)
        }
    }
    
    // 进度百分比文字颜色（预览版）- 更强对比度
    private var previewProgressPercentageTextColor: Color {
        if isUnlocked {
            switch level {
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
    
    // 进度辅助文字颜色（预览版）
    private var previewProgressSecondaryTextColor: Color {
        if isUnlocked {
            // 完成状态时减弱文字显示
            let isCompleted = progress >= 100
            let opacity = isCompleted ? 0.5 : 1.0
            
            switch level {
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
    
    // 进度文字阴影颜色（预览版）
    private var previewProgressTextShadowColor: Color {
        if isUnlocked {
            switch level {
            case .bronze:
                return level.color.opacity(0.2)
            case .silver:
                return level.color.opacity(0.15)
            case .gold:
                return level.color.opacity(0.25)
            }
        } else {
            return Color.black.opacity(0.1)
        }
    }
    
    // 进度条背景轨道颜色（预览版）- 深色槽提供对比
    private var previewProgressTrackColors: [Color] {
        if isUnlocked {
            switch level {
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
            switch level {
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
    
    // 进度条填充颜色（预览版）- 与背景融合的设计
    private var previewProgressFillColors: [Color] {
        if isUnlocked {
            // 完成状态：与背景完全融合，未完成状态：轻微渐变融合
            let isCompleted = progress >= 100
            
            switch level {
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
            switch level {
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
    
    private var backgroundGradient: LinearGradient {
        switch level {
        case .bronze:
            if isUnlocked {
                return LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.97, blue: 0.90),
                        Color(red: 0.96, green: 0.87, blue: 0.70),
                        Color(red: 0.80, green: 0.52, blue: 0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.98, blue: 0.98),
                        Color(red: 0.94, green: 0.96, blue: 0.97),
                        Color(red: 0.89, green: 0.91, blue: 0.94)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .silver:
            if isUnlocked {
                return LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.98, blue: 1.0),
                        Color(red: 0.88, green: 0.92, blue: 0.99),
                        Color(red: 0.75, green: 0.82, blue: 0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.97, blue: 0.98),
                        Color(red: 0.92, green: 0.92, blue: 0.96),
                        Color(red: 0.86, green: 0.86, blue: 0.93)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .gold:
            if isUnlocked {
                return LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.98, blue: 0.85),
                        Color(red: 1.0, green: 0.90, blue: 0.50),
                        Color(red: 0.95, green: 0.75, blue: 0.20)
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
    
    private var cardBackgroundGradient: LinearGradient {
        return LinearGradient(
            colors: [
                Color.white.opacity(0.8),
                Color.gray.opacity(0.1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview {
    NavigationView {
        ColorPreviewView()
    }
} 