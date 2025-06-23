import SwiftUI
import Combine
import UIKit  // iOS应用中的UI组件库

// MARK: - 帖子选项按钮
struct PostOptionsButton: View {
    var post: UserPostModel? // 添加post参数
    var onDislikeCharacter: () -> Void
    var onReport: () -> Void
    var onFollowCharacter: ((Bool) -> Void)? = nil
    var isOneKeyGeneration: Bool = false
    
    @State private var isPressed: Bool = false
    @State private var showOptions: Bool = false
    @State private var isFollowing: Bool = false
    @State private var isBlocked: Bool = false
    @State private var showContentTypeStats: Bool = false
    @State private var contentTypeWeights: [String: Double] = [:]
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    
    // 计算是否在"虫洞探索"模式下
    private var isWormholeExploration: Bool {
        if let post = post {
            return post.source == "wormhole" || post.characterID == "wormhole" || post.username == "虫洞探索"
        }
        return false
    }
    
    // 确定是否显示计数和权重控制
    private var showCountAndWeightControls: Bool {
        isWormholeExploration && post != nil
    }
    
    var body: some View {
        Button(action: {
            isPressed = true
            
            // 添加触感反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // 显示选项菜单
            showOptions = true
        }) {
            Image(systemName: "ellipsis")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isPressed ? Color(.systemGray5) : Color.clear)
                )
                .contentShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $showOptions, arrowEdge: .bottom) {
            List {
                // 关注/取消关注角色选项
                if let onFollowCharacter = onFollowCharacter, let post = post {
                    let characterName = post.username
                    Button(action: {
                        isFollowing.toggle()
                        onFollowCharacter(isFollowing)
                        
                        // 显示提示消息
                        toastMessage = isFollowing ? "已关注 \(characterName)" : "已取消关注 \(characterName)"
                        withAnimation {
                            showToast = true
                        }
                        
                        // 2秒后隐藏提示消息
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showToast = false
                            }
                        }
                        
                        showOptions = false
                    }) {
                        Label(
                            isFollowing ? "取消关注 \(characterName)" : "关注 \(characterName)",
                            systemImage: isFollowing ? "person.badge.minus" : "person.badge.plus"
                        )
                    }
                }
                
                // 屏蔽角色选项
                if let post = post {
                    let characterName = post.username
                    Button(action: {
                        isBlocked.toggle()
                        
                        // 显示提示消息
                        toastMessage = isBlocked ? "已屏蔽 \(characterName)" : "已解除屏蔽 \(characterName)"
                        withAnimation {
                            showToast = true
                        }
                        
                        // 2秒后隐藏提示消息
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showToast = false
                            }
                        }
                        
                        showOptions = false
                        
                        // 如果屏蔽了角色，调用不喜欢角色的回调
                        if isBlocked {
                            onDislikeCharacter()
                        }
                    }) {
                        Label(
                            isBlocked ? "解除屏蔽 \(characterName)" : "屏蔽 \(characterName)",
                            systemImage: isBlocked ? "person.fill.checkmark" : "person.fill.xmark"
                        )
                    }
                }
                
                // 内容类型统计与权重控制
                if showCountAndWeightControls {
                    Section(header: Text("内容类型统计")) {
                        Button(action: {
                            showContentTypeStats.toggle()
                        }) {
                            HStack {
                                Label(
                                    "查看内容类型统计",
                                    systemImage: "chart.bar"
                                )
                                
                                Spacer()
                                
                                Image(systemName: showContentTypeStats ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if showContentTypeStats {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(Array(contentTypeWeights.keys.sorted()), id: \.self) { key in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(key)
                                                .font(.system(size: 14))
                                            
                                            Spacer()
                                            
                                            Text("\(Int(contentTypeWeights[key] ?? 0))")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        
                                        Slider(value: Binding(
                                            get: { contentTypeWeights[key] ?? 0 },
                                            set: { contentTypeWeights[key] = $0 }
                                        ), in: 0...100, step: 1)
                                    }
                                }
                                
                                Button(action: {
                                    // 更新内容类型权重的逻辑
                                    // 这里可以调用后端API或本地更新权重
                                    showOptions = false
                                    
                                    // 显示提示消息
                                    toastMessage = "已更新内容类型权重"
                                    withAnimation {
                                        showToast = true
                                    }
                                    
                                    // 2秒后隐藏提示消息
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation {
                                            showToast = false
                                        }
                                    }
                                }) {
                                    Text("应用更改")
                                        .font(.system(size: 14, weight: .medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .padding(.top, 4)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                // 举报选项
                Button(action: {
                    onReport()
                    showOptions = false
                }) {
                    Label("举报", systemImage: "flag")
                        .foregroundColor(.red)
                }
            }
            .frame(width: 300)
        }
        // 使用iOS 17兼容的onChange API
        .onChange(of: isPressed) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPressed = false
                }
            }
        }
        // 加载初始状态
        .onAppear {
            if let post = post {
                let characterId = post.characterID ?? post.username
                // 这里可以从UserDefaults或其他存储中加载关注状态和屏蔽状态
                isFollowing = UserDefaults.standard.bool(forKey: "following_\(characterId)")
                isBlocked = UserDefaults.standard.bool(forKey: "blocked_\(characterId)")
                
                // 加载内容类型权重
                if isWormholeExploration {
                    contentTypeWeights = [
                        "历史": 50,
                        "科学": 30,
                        "艺术": 20,
                        "哲学": 40,
                        "文学": 60
                    ]
                }
            }
        }
        // 提示消息
        .overlay(
            Group {
                if showToast {
                    VStack {
                        Spacer()
                        
                        Text(toastMessage)
                            .font(.system(size: 14))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black.opacity(0.7))
                            )
                            .foregroundColor(.white)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 20)
                    }
                }
            }
        )
    }
}
