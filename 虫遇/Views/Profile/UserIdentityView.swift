import SwiftUI

/**
 * 用户身份展示组件
 * 提供沉浸式的用户身份和成就展示
 */
struct UserIdentityView: View {
    let user: UserModel
    @State private var isLevelInfoVisible = false
    @State private var animateStars = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部弧形背景
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "4371E5"),
                        Color(hex: "2E5FD3")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 160)
                .overlay(
                    // 星空粒子效果
                    TimeSpaceParticlesView()
                        .opacity(0.2)
                )
                
                // 用户信息卡片
                VStack(spacing: 2) {
                    HStack(alignment: .top) {
                        // 头像 - 使用统一的Avatar组件
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 84, height: 84)
                                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                            
                            // 使用统一的Avatar组件
                            Avatar(
                                url: user.avatar,
                                name: user.username,
                                size: 78
                            )
                            
                            // 发光效果
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                .frame(width: 84, height: 84)
                        }
                        .padding(.top, 24)
                        
                        Spacer()
                        
                        // 设置按钮
                        Button(action: {}) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    
                    // 用户名和等级按钮
                    HStack(alignment: .center) {
                        Text(user.username)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        // 奇遇等级按钮 - 更加显眼的位置
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isLevelInfoVisible.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                
                                Text("Lv.\(user.level)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.yellow.opacity(0.3))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.yellow.opacity(0.7), lineWidth: 1.5)
                            )
                        }
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .padding(.leading, 8)
                    }
                    .padding(.top, 8)
                    
                    // 用户简介
                    Text("穿越时空的历史探索者")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 4)
                        .padding(.bottom, 16)
                }
            }
            .clipShape(
                RoundedShape(corners: [.bottomLeft, .bottomRight], radius: 24)
            )
            
            // 等级信息浮层
            if isLevelInfoVisible {
                LevelInfoView(level: user.level)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            // 将状态更新移到 onAppear 中
            DispatchQueue.main.async {
                // 在这里更新状态
                // 例如：
                // someState = newValue
            }
        }
        
        // 或者使用 Task
        .task {
            // 在这里更新状态
            // 例如：
            // someState = newValue
        }
    }
}

/**
 * 时空粒子效果视图
 */
struct TimeSpaceParticlesView: View {
    @State private var phase = 0.0
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.2)) { timeline in
            let timeValue = timeline.date.timeIntervalSince1970
            let currentPhase = timeValue.truncatingRemainder(dividingBy: 10)
            
            Canvas { context, size in
                for i in 0..<40 {
                    let position = CGPoint(
                        x: size.width * (0.1 + 0.8 * sin(CGFloat(i) * 0.3 + currentPhase)),
                        y: size.height * (0.1 + 0.8 * cos(CGFloat(i) * 0.2 + currentPhase * 0.5))
                    )
                    
                    let size = 2.0 + 3.0 * sin(CGFloat(i) * 0.2 + currentPhase)
                    
                    let alpha = 0.3 + 0.7 * abs(sin(CGFloat(i) * 0.1 + currentPhase * 0.3))
                    
                    context.opacity = alpha
                    context.fill(Path(ellipseIn: CGRect(x: position.x - size/2, y: position.y - size/2, width: size, height: size)), with: .color(.white))
                }
            }
        }
    }
}

/**
 * 等级信息视图
 */
struct LevelInfoView: View {
    let level: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("奇遇等级")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            // 等级进度条
            HStack(spacing: 2) {
                ForEach(0..<10) { i in
                    Rectangle()
                        .fill(i < level ? Color(hex: "4371E5") : Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                }
            }
            
            // 等级描述
            Text("Lv.\(level): 穿越先驱")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "4371E5"))
            
            Text("成就：已与\(level)位历史人物建立关系")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            // 下一等级提示
            Text("距离Lv.\(level+1)：还需要与\(3-level%3)位历史人物交流")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
}

/**
 * 自定义圆角形状
 */
struct RoundedShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, 
                                byRoundingCorners: corners, 
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview("用户身份视图") {
    VStack {
        UserIdentityView(user: UserModel.sampleUser)
        Spacer()
    }
    .background(Color(red: 246/255, green: 248/255, blue: 250/255))
} 