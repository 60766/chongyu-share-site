import SwiftUI

/**
 * 我的点赞记录视图 - Apple Design System
 * 采用苹果设计语言，注重层次感、空间感和内容可读性
 */

/**
 * 增强的点赞记录卡片视图 - 苹果风格
 */
struct LikeRecordCardView: View {
    let record: LikeRecord
    @State private var isExpanded = false
    @State private var isPressed = false
    @State private var showingCancelAlert = false
    var onTap: () -> Void
    var onRemove: (() -> Void)?
    
    init(record: LikeRecord, onTap: @escaping () -> Void = {}, onRemove: (() -> Void)? = nil) {
        self.record = record
        self.onTap = onTap
        self.onRemove = onRemove
    }
    
    // 内容截断长度
    private let collapsedContentLength = 120
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // 主要内容区域
                VStack(alignment: .leading, spacing: 16) {
                    // 头部信息区域
                    headerSection
                    
                    // 内容区域
                    contentSection
                    
                    // 互动信息区域
                    interactionSection
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.quaternary, lineWidth: 0.5)
                        )
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
        .alert("取消点赞", isPresented: $showingCancelAlert) {
            Button("取消", role: .cancel) { }
            Button("确认", role: .destructive) {
                // 执行取消点赞
                UserLikeService.shared.removeLikeRecord(record)
                onRemove?()
            }
        } message: {
            Text("确定要取消对这条内容的点赞吗？")
        }
    }
    
    // 头部信息区域
    private var headerSection: some View {
        HStack(spacing: 12) {
            // 作者头像 - 更大更精致
            authorAvatar
                
            VStack(alignment: .leading, spacing: 6) {
                // 作者信息行
                HStack(spacing: 8) {
                            Text(record.authorName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                    // 类型标签 - 重新设计
                    typeLabel
                    
                    Spacer()
                }
                
                // 时间和角色信息
                HStack(spacing: 8) {
                    Text(formatChineseTime(record.timestamp))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    if let characterName = record.characterName {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.purple)
                            
                            Text("与\(characterName)相关")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.purple)
                            }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.purple.opacity(0.08))
                        )
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // 作者头像
    private var authorAvatar: some View {
        Group {
            if UIImage(named: record.authorAvatar) != nil {
                Image(record.authorAvatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(.quaternary, lineWidth: 1)
                    )
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(record.authorName.prefix(1)))
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    )
            }
        }
                        }
                        
    // 类型标签
    private var typeLabel: some View {
                            HStack(spacing: 4) {
            Image(systemName: record.type.iconName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(record.type.color)
            
            Text(record.type.displayName)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(record.type.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(record.type.color.opacity(0.12))
        )
                }
                
                // 内容区域
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
                    // 标题（仅帖子类型显示）
                    if record.type == .post && !record.title.isEmpty {
                        Text(record.title)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                            .foregroundColor(.primary)
                    .lineLimit(isExpanded ? nil : 2)
                    .multilineTextAlignment(.leading)
                    }
                    
            // 内容文本
            VStack(alignment: .leading, spacing: 8) {
                Text(displayContent)
                    .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.secondary)
                    .lineLimit(isExpanded ? nil : 4)
                        .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                
                // 展开/收起按钮
                if shouldShowExpandButton {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isExpanded ? "收起" : "展开")
                                .font(.system(size: 14, weight: .medium))
                            
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    // 互动信息区域
    private var interactionSection: some View {
                HStack {
                    Spacer()
                    
            // 取消点赞按钮
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    cancelLike()
                }
            }) {
                HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.pink)
                        
                        Text("\(record.likeCount)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.pink.opacity(0.08))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .onLongPressGesture(minimumDuration: 0) {
                // 长按开始
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
            } onPressingChanged: { pressing in
                // 按压状态改变
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }
            
            // 查看详情指示器
            Image(systemName: "arrow.up.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                }
    }
    
    // 计算属性
    private var displayContent: String {
        if isExpanded || record.content.count <= collapsedContentLength {
            return record.content
        }
        return String(record.content.prefix(collapsedContentLength)) + "..."
    }
    
    private var shouldShowExpandButton: Bool {
        record.content.count > collapsedContentLength
    }
    
    // 格式化中文时间
    private func formatChineseTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)
        
        if let year = components.year, year > 0 {
            return "\(year)年前"
        } else if let month = components.month, month > 0 {
            return "\(month)个月前"
        } else if let week = components.weekOfYear, week > 0 {
            return "\(week)周前"
        } else if let day = components.day, day > 0 {
            return "\(day)天前"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)小时前"
        } else if let minute = components.minute, minute > 5 {
            return "\(minute)分钟前"
        } else {
            return "刚刚"
        }
    }
    
    // 取消点赞
    private func cancelLike() {
        showingCancelAlert = true
    }
}

/**
 * 我的点赞列表视图 - 苹果风格
 */
struct MyLikesListView: View {
    let records: [LikeRecord]
    var onRecordTap: (LikeRecord) -> Void = { _ in }
    var onRecordRemove: (LikeRecord) -> Void = { _ in }
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(records) { record in
                LikeRecordCardView(
                    record: record,
                    onTap: {
                    onRecordTap(record)
                    },
                    onRemove: {
                        onRecordRemove(record)
                }
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

/**
 * 我的点赞主视图 - 重新设计
 */
struct MyLikesView: View {
    @StateObject private var likeService = UserLikeService.shared
    @State private var selectedFilter: LikeRecordType? = nil
    
    private var filteredRecords: [LikeRecord] {
        let records = likeService.getUserLikes()
        if let filter = selectedFilter {
            return records.filter { $0.type == filter }
        }
        return records
    }
    
    var body: some View {
        NavigationView {
        VStack(spacing: 0) {
                // 顶部筛选区域
                filterSection
                
                // 内容区域
                if filteredRecords.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        MyLikesListView(
                            records: filteredRecords,
                            onRecordTap: { record in
                                handleRecordTap(record)
                            },
                            onRecordRemove: { record in
                                handleRecordRemove(record)
                            }
                        )
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("我的点赞")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // 筛选区域
    private var filterSection: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // 全部按钮
                FilterChip(
                        title: "全部",
                    count: likeService.getUserLikes().count,
                        isSelected: selectedFilter == nil,
                    color: .blue
                    ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFilter = nil
                    }
                    }
                    
                    // 类型筛选按钮
                    ForEach(LikeRecordType.allCases, id: \.self) { type in
                    FilterChip(
                        title: type.displayName,
                        count: likeService.getUserLikes().filter { $0.type == type }.count,
                            isSelected: selectedFilter == type,
                        color: type.color
                        ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = selectedFilter == type ? nil : type
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            }
        .padding(.vertical, 16)
        .background(.regularMaterial)
    }
    
    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // 图标
            ZStack {
                Circle()
                    .fill(.pink.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                    Image(systemName: "heart")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.pink.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                Text("暂无点赞记录")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("去发现感兴趣的内容\n与历史人物展开精彩对话吧")
                    .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 80)
    }
    
    private func handleRecordTap(_ record: LikeRecord) {
        
        print("点击了\(record.type.rawValue): \(record.postId)")
    }
    
    private func handleRecordRemove(_ record: LikeRecord) {
        // 记录已经在UserLikeService中被移除
        // 这里可以添加额外的处理逻辑，比如显示提示信息
        withAnimation(.easeInOut(duration: 0.3)) {
            // 视图会自动更新，因为likeService是@StateObject
        }
        print("移除了点赞记录: \(record.type.rawValue) - \(record.authorName)")
    }
}

/**
 * 筛选按钮组件 - 重新设计
 */
struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? .white.opacity(0.3) : color.opacity(0.15))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.08))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// 扩展LikeRecordType以支持更好的显示
extension LikeRecordType {
    var displayName: String {
        switch self {
        case .post:
            return "帖子"
        case .comment:
            return "评论"
        }
    }
}

#Preview("我的点赞") {
    MyLikesView()
} 