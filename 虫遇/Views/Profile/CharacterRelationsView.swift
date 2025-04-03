import SwiftUI
import Foundation

/**
 * 角色关系视图
 * 展示用户与历史人物的关系网络
 */
struct CharacterRelationsView: View {
    let relations: [CharacterRelationModel]
    @State private var selectedRelation: CharacterRelationModel?
    @State private var showRelationDetail = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 关系网络概览
                    RelationNetworkView(relations: relations)
                        .frame(height: 200)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    
                    // 关系列表
                    VStack(alignment: .leading, spacing: 16) {
                        Text("我的虚拟好友")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                        
                        if relations.isEmpty && !isLoading {
                            VStack(spacing: 16) {
                                Image(systemName: "person.2.slash")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .padding(.top, 32)
                                
                                Text("暂无虚拟好友")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                
                                AddFriendButton(largeSized: true)
                                    .padding(.horizontal, 32)
                                    .padding(.top, 16)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 32)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(relations) { relation in
                                    RelationCardView(relation: relation)
                                        .onTapGesture {
                                            selectedRelation = relation
                                            showRelationDetail = true
                                            HapticFeedback.light()
                                        }
                                }
                                
                                // 添加好友按钮
                                AddFriendButton()
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .refreshable {
                await refreshData()
            }
            .overlay(
                errorMessage.map { message in
                    VStack {
                        Text(message)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(8)
                            .padding()
                            .onTapGesture {
                                withAnimation {
                                    errorMessage = nil
                                }
                            }
                        Spacer()
                    }
                }
            )
            
            if isLoading {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color(hex: "4371E5"))
                    )
            }
        }
        .sheet(isPresented: $showRelationDetail) {
            if let relation = selectedRelation {
                RelationDetailView(relation: relation)
            }
        }
    }
    
    /**
     * 刷新数据
     */
    private func refreshData() async {
        withAnimation {
            isLoading = true
            errorMessage = nil
        }
        
        // 模拟网络请求
        do {
            try await Task.sleep(nanoseconds: 1_500_000_000)
            // 这里应替换为实际的网络请求
            
            withAnimation {
                isLoading = false
            }
        } catch {
            withAnimation {
                isLoading = false
                errorMessage = "更新数据失败，请稍后再试"
            }
            
            // 5秒后自动隐藏错误信息
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    if errorMessage != nil {
                        errorMessage = nil
                    }
                }
            }
        }
    }
}

/**
 * 关系网络视图
 */
struct RelationNetworkView: View {
    let relations: [CharacterRelationModel]
    @State private var phase: CGFloat = 0
    @State private var isAnimating = false
    
    private var centerPoint: CGPoint {
        CGPoint(x: 100, y: 100)
    }
    
    private var radius: CGFloat {
        80
    }
    
    private func calculatePoint(angle: Double) -> CGPoint {
        CGPoint(
            x: centerPoint.x + radius * CGFloat(Foundation.cos(angle)),
            y: centerPoint.y + radius * CGFloat(Foundation.sin(angle))
        )
    }
    
    var body: some View {
        ZStack {
            // 背景
            Circle()
                .fill(Color(hex: "4371E5").opacity(0.1))
                .frame(width: 180, height: 180)
            
            // 关系连线
            ForEach(relations.indices, id: \.self) { index in
                if !relations.isEmpty {
                    let angle = Double(index) * (2 * .pi / Double(relations.count))
                    let nextAngle = Double((index + 1) % relations.count) * (2 * .pi / Double(relations.count))
                    
                    Path { path in
                        let start = calculatePoint(angle: angle)
                        let end = calculatePoint(angle: nextAngle)
                        
                        path.move(to: start)
                        path.addLine(to: end)
                    }
                    .stroke(
                        relations[index].relationColor.opacity(0.3),
                        lineWidth: 2
                    )
                }
            }
            
            // 角色头像
            ForEach(relations.indices, id: \.self) { index in
                if !relations.isEmpty {
                    let angle = Double(index) * (2 * .pi / Double(relations.count))
                    let offset = calculatePoint(angle: angle)
                    
                    AvatarView(imageName: relations[index].character.avatar)
                        .offset(x: offset.x - centerPoint.x, y: offset.y - centerPoint.y)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .animation(
                            Animation.spring(response: 0.5, dampingFraction: 0.6)
                                .delay(Double(index) * 0.1),
                            value: isAnimating
                        )
                }
            }
            
            // 中心用户头像
            Circle()
                .fill(Color.white)
                .frame(width: 60, height: 60)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "4371E5"))
                )
                .scaleEffect(isAnimating ? 1.0 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: isAnimating)
        }
        .onAppear {
            // 延迟一点开始动画，让它看起来更像是一个反应
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    isAnimating = true
                }
            }
            
            withAnimation(Animation.linear(duration: 10).repeatForever(autoreverses: false)) {
                phase = 2 * .pi
            }
        }
    }
}

/**
 * 关系卡片视图
 */
struct RelationCardView: View {
    let relation: CharacterRelationModel
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 8) {
            // 角色头像
            AvatarView(imageName: relation.character.avatar, size: 64)
            
            // 角色名称
            Text(relation.character.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            // 关系类型
            Text(relation.relationType.rawValue)
                .font(.system(size: 12))
                .foregroundColor(relation.relationColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(relation.relationColor.opacity(0.1))
                .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(isPressed ? 0.02 : 0.05), radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: 50, pressing: { pressing in
            withAnimation {
                isPressed = pressing
            }
        }, perform: {})
    }
}

/**
 * 添加好友按钮
 */
struct AddFriendButton: View {
    var largeSized: Bool = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // 添加好友
            HapticFeedback.medium()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "4371E5").opacity(0.1))
                        .frame(width: largeSized ? 80 : 64, height: largeSized ? 80 : 64)
                    
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: largeSized ? 30 : 24))
                        .foregroundColor(Color(hex: "4371E5"))
                }
                
                Text("添加好友")
                    .font(.system(size: largeSized ? 16 : 14))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(isPressed ? 0.02 : 0.05), radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 2)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: 50, pressing: { pressing in
            withAnimation {
                isPressed = pressing
            }
        }, perform: {})
    }
}

/**
 * 关系详情视图
 */
struct RelationDetailView: View {
    let relation: CharacterRelationModel
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var interactions: [InteractionModel] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // 角色信息
                        VStack(spacing: 16) {
                            AvatarView(imageName: relation.character.avatar, size: 100)
                            
                            Text(relation.character.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text(relation.relationType.rawValue)
                                .font(.system(size: 16))
                                .foregroundColor(relation.relationColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(relation.relationColor.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .padding(.top, 20)
                        
                        // 关系数据
                        HStack(spacing: 40) {
                            RelationDataItem(
                                title: "互动次数",
                                value: "\(relation.interactionCount)",
                                icon: "bubble.left.and.bubble.right.fill"
                            )
                            
                            RelationDataItem(
                                title: "对话时长",
                                value: relation.conversationTime,
                                icon: "clock.fill"
                            )
                            
                            RelationDataItem(
                                title: "收藏内容",
                                value: "\(relation.favoriteCount)",
                                icon: "star.fill"
                            )
                        }
                        .padding(.vertical, 20)
                        
                        // 最近互动
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("最近互动")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button("查看全部") {
                                    // 跳转到全部互动记录页面
                                    HapticFeedback.light()
                                }
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "4371E5"))
                            }
                            .padding(.horizontal, 16)
                            
                            if interactions.isEmpty && !isLoading {
                                VStack(spacing: 16) {
                                    Image(systemName: "bubble.left.slash")
                                        .font(.system(size: 32))
                                        .foregroundColor(.secondary.opacity(0.5))
                                        .padding(.top, 24)
                                    
                                    Text("暂无互动记录")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .padding(.bottom, 24)
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                ForEach(interactions.isEmpty ? InteractionModel.samples : interactions) { interaction in
                                    InteractionItem(interaction: interaction)
                                }
                            }
                        }
                        .padding(.top, 10)
                        
                        // 操作按钮
                        HStack(spacing: 20) {
                            ActionButton(
                                title: "发起对话",
                                icon: "bubble.left.fill",
                                color: Color(hex: "4371E5")
                            ) {
                                // 处理发起对话
                                HapticFeedback.medium()
                            }
                            
                            ActionButton(
                                title: "修改关系",
                                icon: "pencil",
                                color: Color(hex: "FFB347")
                            ) {
                                // 处理修改关系
                                HapticFeedback.medium()
                            }
                        }
                        .padding(.vertical, 24)
                    }
                    .padding(.bottom, 16)
                }
                .refreshable {
                    await loadInteractions()
                }
                
                if isLoading {
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(Color(hex: "4371E5"))
                        )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // 显示菜单
                        HapticFeedback.light()
                    }) {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                    }
                }
            }
            .onAppear {
                Task {
                    await loadInteractions()
                }
            }
        }
    }
    
    /**
     * 加载互动数据
     */
    private func loadInteractions() async {
        withAnimation {
            isLoading = true
        }
        
        // 模拟网络请求
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            // 实际项目中应替换为真实的网络请求
            
            withAnimation {
                isLoading = false
                // 假设我们从服务器得到了数据
                interactions = InteractionModel.samples
            }
        } catch {
            withAnimation {
                isLoading = false
            }
        }
    }
}

/**
 * 操作按钮
 */
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(color)
            .cornerRadius(12)
            .shadow(color: color.opacity(0.3), radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 2)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: 50, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

/**
 * 触觉反馈工具类
 */
struct HapticFeedback {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}

/**
 * 为CharacterRelationModel模型添加一些展示用的属性
 */
extension CharacterRelationModel {
    /// 互动次数
    var interactionCount: Int {
        Int.random(in: 10...200)
    }
    
    /// 对话时长
    var conversationTime: String {
        let hours = Int.random(in: 1...50)
        return "\(hours)h"
    }
    
    /// 收藏内容数量
    var favoriteCount: Int {
        Int.random(in: 0...50)
    }
}

/**
 * 关系数据项
 */
struct RelationDataItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "4371E5"))
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

/**
 * 互动记录项
 */
struct InteractionItem: View {
    let interaction: InteractionModel
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // 查看互动详情
            HapticFeedback.light()
        }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(interaction.color.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: interaction.icon)
                            .font(.system(size: 20))
                            .foregroundColor(interaction.color)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(interaction.title)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                    
                    Text(interaction.time)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(isPressed ? 0.02 : 0.05), radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 2)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: 50, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

/**
 * 互动记录模型
 */
struct InteractionModel: Identifiable {
    let id = UUID()
    let title: String
    let time: String
    let icon: String
    let color: Color
    
    static var samples: [InteractionModel] = [
        InteractionModel(
            title: "探讨了相对论的基本原理",
            time: "2小时前",
            icon: "bubble.left.fill",
            color: Color(hex: "4371E5")
        ),
        InteractionModel(
            title: "分享了一篇关于量子力学的文章",
            time: "昨天",
            icon: "doc.text.fill",
            color: Color(hex: "FFB347")
        ),
        InteractionModel(
            title: "一起解决了一个物理学难题",
            time: "3天前",
            icon: "lightbulb.fill",
            color: Color(hex: "50C878")
        )
    ]
}

#Preview("角色关系视图") {
    CharacterRelationsView(relations: CharacterRelationModel.sampleRelations)
        .background(Color(red: 246/255, green: 248/255, blue: 250/255))
}

#Preview("空关系视图") {
    CharacterRelationsView(relations: [])
        .background(Color(red: 246/255, green: 248/255, blue: 250/255))
} 