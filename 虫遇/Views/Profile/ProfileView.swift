import SwiftUI
import SwiftData

/**
 * 个人空间页
 * 展示用户个人信息、时空旅行记录和历史人物关系
 */
struct ProfileView: View {
    /// 当前选中的标签索引
    @State private var selectedTabIndex = 0
    /// 标签选项
    private let tabOptions = ["角色关系", "我的动态", "互动记录"]
    /// 是否显示成就详情
    @State private var showAchievements = false
    /// 是否显示等级详情
    @State private var showLevelDetails = false
    /// 用于标签指示器动画的命名空间
    @Namespace private var namespace
    
    // 模拟用户成就数据
    private let userAchievements = [
        Achievement(id: "1", name: "时空旅行者", icon: "clock.arrow.2.circlepath", description: "完成10次历史对话"),
        Achievement(id: "2", name: "历史学者", icon: "book.fill", description: "与5位不同时代的历史人物交流"),
        Achievement(id: "3", name: "文艺复兴", icon: "paintpalette.fill", description: "与达芬奇进行3次深度交流")
    ]
    
    // 模拟时间线数据
    private let timelineEvents = [
        TimelineEvent(date: "2024-03-15", title: "遇见爱因斯坦", icon: "atom", description: "第一次与爱因斯坦交谈关于相对论"),
        TimelineEvent(date: "2024-03-10", title: "探索文艺复兴", icon: "paintbrush.fill", description: "与达芬奇讨论艺术与科学"),
        TimelineEvent(date: "2024-03-05", title: "哲学之旅", icon: "questionmark.circle", description: "向苏格拉底请教人生智慧")
    ]
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // 顶部区域：用户名和头像
                VStack(spacing: 0) {
                    HStack {
                        Text("我的空间")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primaryColor)
                            .tracking(-0.5) // 紧凑排版
                        
                        Spacer()
                        
                        Button(action: {
                            // 设置按钮
                        }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                                .padding(8)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                }
                
                // 用户信息卡片 - 增强设计、与APP统一风格
                VStack(spacing: 0) {
                    // 卡片顶部 - 星空背景
                    ZStack(alignment: .top) {
                        // 背景渐变
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.primaryColor,
                                        Color.primaryColor.opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 110)
                            .overlay(
                                // 星空效果
                                ZStack {
                                    ForEach(0..<20, id: \.self) { i in
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: i % 3 == 0 ? 2 : 1)
                                            .position(
                                                x: CGFloat.random(in: 0...UIScreen.main.bounds.width - 40),
                                                y: CGFloat.random(in: 0...100)
                                            )
                                            .opacity(Double.random(in: 0.3...0.7))
                                    }
                                }
                            )
                    }
                    
                    // 用户信息内容
                    VStack(spacing: 10) {
                        // 用户头像 - 带星轨环绕效果
                        ZStack {
                            // 星轨环绕效果
                            Circle()
                                .strokeBorder(
                                    AngularGradient(
                                        gradient: Gradient(colors: [
                                            Color.primaryColor.opacity(0.2),
                                            Color.primaryColor,
                                            Color.primaryColor.opacity(0.2)
                                        ]),
                                        center: .center
                                    ),
                                    lineWidth: 2
                                )
                                .frame(width: 110, height: 110)
                                .rotationEffect(.degrees(35))
                            
                            // 头像外圈光晕
                            Circle()
                                .fill(Color.white)
                                .frame(width: 100, height: 100)
                                .shadow(color: Color.primaryColor.opacity(0.2), radius: 15)
                            
                            // 头像图片
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 90, height: 90)
                                .foregroundColor(Color.primaryColor)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .offset(y: -55)
                        .padding(.bottom, -55)
                        
                        // 用户名和等级
                        VStack(spacing: 4) {
                            Text("历史探索者")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                            
                            // 等级标签 - 可点击查看详情
                            Button(action: { showLevelDetails.toggle() }) {
                                HStack(spacing: 5) {
                                    // 等级图标
                                    HStack(spacing: 2) {
                                        Text("Lv.8")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.primaryColor)
                                    .cornerRadius(10)
                                    
                                    Text("穿越时空的历史探索者")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                    
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        // 成就勋章栏
                        HStack(spacing: 20) {
                            ForEach(userAchievements.prefix(3)) { achievement in
                                VStack(spacing: 6) {
                                    ZStack {
                                        // 成就背景
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.primaryColor,
                                                        Color.primaryColor.opacity(0.7)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 44, height: 44)
                                            .shadow(color: Color.primaryColor.opacity(0.2), radius: 4, x: 0, y: 2)
                                        
                                        // 成就图标
                                        Image(systemName: achievement.icon)
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(achievement.name)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.vertical, 10)
                        
                        // 查看全部成就按钮
                        Button(action: { showAchievements.toggle() }) {
                            Text("查看全部成就")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primaryColor)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.primaryColor.opacity(0.1))
                                .cornerRadius(18)
                        }
                        .padding(.bottom, 6)
                    }
                    .padding(.horizontal, 20)
                    .background(Color.white)
                }
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                .padding(.horizontal, 20)
                
                // 时空旅行统计数据 - 重新设计为与探索页类似的卡片风格
                HStack(spacing: 12) {
                    ForEach([
                        ("动态", "128", "square.text.square"),
                        ("获赞", "1.2K", "heart.fill"),
                        ("好友", "12", "person.2.fill")
                    ], id: \.0) { title, value, icon in
                        VStack(spacing: 8) {
                            // 图标容器
                            ZStack {
                                Circle()
                                    .fill(Color.primaryColor.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.primaryColor)
                            }
                            
                            // 数值 - 大数字
                            Text(value)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            
                            // 标题
                            Text(title)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 20)
                
                // 时空旅行里程碑 - 重新设计为与探索页相似的卡片风格
                VStack(alignment: .leading, spacing: 0) {
                    // 标题区域
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.primaryColor)
                            
                            Text("时空旅行里程")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // 查看全部时间线
                        }) {
                            Text("查看全部")
                                .font(.system(size: 14))
                                .foregroundColor(.primaryColor)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    // 分隔线 - 使用渐变色减淡
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.1),
                                    Color.gray.opacity(0.05)
                                ]), 
                                startPoint: .leading, 
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                    
                    // 时间线 - 更现代的设计
                    VStack(spacing: 0) {
                        ForEach(timelineEvents) { event in
                            // 改用现代化的时间线视图
                            HStack(alignment: .top, spacing: 15) {
                                // 日期 - 更醒目的日期标签
                                Text(event.date.components(separatedBy: "-").last ?? "")
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.primaryColor.opacity(0.1))
                                    .cornerRadius(8)
                                    .frame(width: 50)
                                
                                // 时间线轴 - 更光滑的设计
                                VStack(spacing: 0) {
                                    // 上半圆
                                    Circle()
                                        .fill(Color.primaryColor)
                                        .frame(width: 12, height: 12)
                                    
                                    // 线条
                                    Rectangle()
                                        .fill(Color.primaryColor.opacity(0.3))
                                        .frame(width: 2)
                                        .frame(maxHeight: .infinity)
                                }
                                .frame(height: 70)
                                
                                // 事件内容 - 卡片式设计
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Image(systemName: event.icon)
                                            .foregroundColor(.white)
                                            .font(.system(size: 12))
                                            .padding(6)
                                            .background(Color.primaryColor)
                                            .clipShape(Circle())
                                        
                                        Text(event.title)
                                            .font(.system(size: 16, weight: .semibold))
                                            .lineLimit(1)
                                    }
                                    
                                    Text(event.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.trailing, 10)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                
                // 内容标签选择器 - 现代化设计
                VStack(spacing: 0) {
                    // 标签栏
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 30) {
                            ForEach(Array(tabOptions.enumerated()), id: \.element) { index, tab in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedTabIndex = index
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        Text(tab)
                                            .font(.system(size: 16, weight: selectedTabIndex == index ? .semibold : .regular))
                                            .foregroundColor(selectedTabIndex == index ? Color.primaryColor : .secondary)
                                        
                                        // 增强的选中指示器
                                        if selectedTabIndex == index {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.primaryColor)
                                                .frame(width: 20, height: 4)
                                                .matchedGeometryEffect(id: "tabIndicator", in: namespace)
                                        } else {
                                            Rectangle()
                                                .fill(Color.clear)
                                                .frame(width: 20, height: 4)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                    .background(Color.white)
                    
                    // 内容区域 - 现代化设计，增强视觉反馈
                    ZStack {
                        // 角色关系视图
                        if selectedTabIndex == 0 {
                            if characterRelations.isEmpty {
                                enhancedEmptyContentView(
                                    icon: "person.2.circle.fill",
                                    message: "暂无角色关系",
                                    description: "尝试与历史人物聊天，建立与他们的关系吧！",
                                    buttonTitle: "去探索历史人物",
                                    buttonAction: {
                                        // 跳转到探索页面的代码
                                    }
                                )
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                            } else {
                                characterRelationsView()
                                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                            }
                        }
                        
                        // 我的动态视图
                        if selectedTabIndex == 1 {
                            enhancedEmptyContentView(
                                icon: "square.text.square",
                                message: "暂无动态",
                                description: "您还没有发布过动态，与历史人物对话并分享您的见解吧！",
                                buttonTitle: "发布动态",
                                buttonAction: {
                                    // 发布动态的代码
                                }
                            )
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                        
                        // 互动记录视图
                        if selectedTabIndex == 2 {
                            enhancedEmptyContentView(
                                icon: "text.bubble",
                                message: "暂无互动记录",
                                description: "尝试与历史人物聊天、点赞或评论，建立互动关系吧！",
                                buttonTitle: "开始互动",
                                buttonAction: {
                                    // 开始互动的代码
                                }
                            )
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                    }
                    .frame(height: 300)
                    .background(
                        Color.white
                            .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: -1)
                    )
                    .animation(.spring(response: 0.3), value: selectedTabIndex)
                }
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 20)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 246/255, green: 248/255, blue: 252/255),
                    Color(red: 250/255, green: 250/255, blue: 252/255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $showAchievements) {
            achievementsView()
        }
        .sheet(isPresented: $showLevelDetails) {
            levelDetailsView()
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // 模拟数据 - 角色关系
    private var characterRelations: [CharacterRelation] {
        [] // 目前为空，未来可以添加实际数据
    }
    
    // 数据统计视图 - 增加图标
    private func statView(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.primaryColor)
                
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
    
    // 角色关系视图
    private func characterRelationsView() -> some View {
        VStack {
            Text("此处将展示您与历史人物的互动关系")
                .foregroundColor(.gray)
        }
    }
    
    // 时间线事件视图
    private func timelineEventView(event: TimelineEvent) -> some View {
        HStack(alignment: .top, spacing: 15) {
            // 日期
            Text(event.date)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .trailing)
            
            // 时间线轴
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.primaryColor)
                    .frame(width: 12, height: 12)
                
                Rectangle()
                    .fill(Color.primaryColor.opacity(0.3))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(height: 70)
            
            // 事件内容
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: event.icon)
                        .foregroundColor(.primaryColor)
                    
                    Text(event.title)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(event.description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // 成就视图 - 现代化设计
    private func achievementsView() -> some View {
        VStack(spacing: 0) {
            // 导航栏
            HStack {
                Spacer()
                Text("我的成就")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                
                Button(action: {
                    showAchievements = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.gray.opacity(0.7))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 16)
            .background(Color.white)
            
            // 成就等级概览
            VStack(spacing: 8) {
                HStack {
                    Text("成就等级")
                        .font(.system(size: 16, weight: .medium))
                    
                    Spacer()
                    
                    Text("大师级探索者")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryColor)
                }
                
                // 成就进度
                VStack(spacing: 8) {
                    HStack {
                        Text("\(userAchievements.count)/30")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("解锁下一等级还需3项成就")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    // 进度条
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.primaryColor,
                                        Color.primaryColor.opacity(0.7)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: UIScreen.main.bounds.width * 0.3, height: 8)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
            
            // 主要内容 - 成就列表
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 16
                ) {
                    ForEach(userAchievements) { achievement in
                        // 成就卡片
                        VStack(spacing: 12) {
                            ZStack {
                                // 外圈装饰
                                Circle()
                                    .strokeBorder(
                                        AngularGradient(
                                            gradient: Gradient(colors: [
                                                Color.primaryColor.opacity(0.3),
                                                Color.primaryColor,
                                                Color.primaryColor.opacity(0.3)
                                            ]),
                                            center: .center
                                        ),
                                        lineWidth: 2
                                    )
                                    .frame(width: 70, height: 70)
                                
                                // 背景
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.primaryColor,
                                                Color.primaryColor.opacity(0.8)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 60)
                                
                                // 图标
                                Image(systemName: achievement.icon)
                                    .font(.system(size: 26))
                                    .foregroundColor(.white)
                            }
                            
                            // 成就名称
                            Text(achievement.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            // 成就描述
                            Text(achievement.description)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(height: 40)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 12)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(20)
            }
            .background(
                Color(red: 246/255, green: 248/255, blue: 252/255)
            )
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // 等级详情视图 - 现代化设计
    private func levelDetailsView() -> some View {
        VStack(spacing: 0) {
            // 导航栏
            HStack {
                Spacer()
                Text("等级详情")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                
                Button(action: {
                    showLevelDetails = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.gray.opacity(0.7))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 16)
            .background(Color.white)
            
            ScrollView {
                VStack(spacing: 20) {
                    // 当前等级卡片
                    VStack(spacing: 16) {
                        // 等级图标
                        ZStack {
                            // 发光背景
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            Color.primaryColor.opacity(0.7),
                                            Color.primaryColor.opacity(0.0)
                                        ]),
                                        center: .center,
                                        startRadius: 25,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .blur(radius: 5)
                            
                            // 等级显示
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.primaryColor,
                                                Color.primaryColor.opacity(0.8)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.primaryColor.opacity(0.3), radius: 10)
                                
                                Text("Lv.8")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // 等级名称
                        Text("穿越时空的历史探索者")
                            .font(.system(size: 18, weight: .medium))
                            .multilineTextAlignment(.center)
                        
                        // 进度区域
                        VStack(spacing: 10) {
                            // 进度标题
                            HStack {
                                Text("等级进度")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Spacer()
                                
                                Text("750/1000 经验")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            // 进度条 - 平滑动画效果
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 12)
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.primaryColor,
                                                Color.primaryColor.opacity(0.7)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: UIScreen.main.bounds.width * 0.6, height: 12)
                            }
                            
                            Text("距离下一级还需: 250经验")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 4)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                Color.white
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // 等级特权卡片
                    VStack(alignment: .leading, spacing: 16) {
                        Text("等级特权")
                            .font(.system(size: 18, weight: .semibold))
                        
                        // 特权列表
                        VStack(spacing: 0) {
                            LevelPrivilegeRow(icon: "message.fill", title: "解锁更多历史人物对话", level: "Lv.5", isUnlocked: true)
                            Divider().background(Color.gray.opacity(0.1))
                            
                            LevelPrivilegeRow(icon: "wand.and.stars", title: "个性化空间装饰", level: "Lv.8", isUnlocked: true)
                            Divider().background(Color.gray.opacity(0.1))
                            
                            LevelPrivilegeRow(icon: "crown.fill", title: "专属徽章展示", level: "Lv.10", isUnlocked: false)
                            Divider().background(Color.gray.opacity(0.1))
                            
                            LevelPrivilegeRow(icon: "key.fill", title: "历史隐藏场景", level: "Lv.15", isUnlocked: false)
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(
                Color(red: 246/255, green: 248/255, blue: 252/255)
            )
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // 等级特权行
    private func levelPrivilegeRow(icon: String, title: String, level: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.primaryColor)
                .frame(width: 30)
            
            Text(title)
                .font(.system(size: 16))
            
            Spacer()
            
            Text(level)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
    }
    
    // 简单的空内容提示视图
    private func emptyContentView(icon: String, message: String, description: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // 增强的空内容提示视图
    private func enhancedEmptyContentView(icon: String, message: String, description: String, buttonTitle: String, buttonAction: @escaping () -> Void) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: buttonAction) {
                Text(buttonTitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primaryColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.primaryColor.opacity(0.1))
                    .cornerRadius(18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/**
 * 成就模型
 */
struct Achievement: Identifiable {
    var id: String
    var name: String
    var icon: String
    var description: String
}

/**
 * 时间线事件模型
 */
struct TimelineEvent: Identifiable {
    var id = UUID()
    var date: String
    var title: String
    var icon: String
    var description: String
}

/**
 * 角色关系模型
 */
struct CharacterRelation: Identifiable {
    var id = UUID()
    var characterName: String
    var characterIcon: String
    var relationshipType: String
    var lastInteraction: String
}

/**
 * 个人空间页预览
 */
#Preview("个人空间") {
    ProfileView()
} 

#Preview("调试版空间") {
    DebugProfileView()
} 