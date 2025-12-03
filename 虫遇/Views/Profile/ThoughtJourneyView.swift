import SwiftUI
import SwiftData

/**
 * 虫遇回忆视图
 * 展示用户的次元相遇回忆录
 */
struct ThoughtJourneyView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var service = ThoughtJourneyService.shared
    @State private var selectedTimeRange: TimeRange = .lastWeek
    @State private var animationRotation: Double = 0
    @State private var showingRegenerateConfirmation = false
    
    var body: some View {
        ZStack {
            // 主内容区域
            VStack(spacing: 0) {
            if service.isGenerating {
                loadingView
            } else if let report = service.currentReport {
                reportView(report)
            } else if let error = service.errorMessage {
                errorView(error)
            } else {
                emptyView
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 控制按钮悬浮在右上角
            VStack {
                HStack {
                    Spacer()
                    controlButtons
        }
        .padding(.horizontal, 12)
                .padding(.top, 8)
                Spacer()
            }
        }
        .onAppear {
            loadCachedReport()
        }
        .alert("重新生成回顾报告", isPresented: $showingRegenerateConfirmation) {
            Button("取消", role: .cancel) { }
            Button("确认生成", role: .destructive) {
                regenerateReport()
            }
        } message: {
            Text("这将替换当前保存的回顾内容。\n确定要重新生成吗？")
        }
    }
    
    // 控制按钮组
    private var controlButtons: some View {
        HStack(spacing: 12) {
            // 重新生成按钮
            Button(action: { 
                showingRegenerateConfirmation = true
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                            )
                    )
            }
            
                // 时间范围选择器
            Menu {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button(range.description) {
                        selectedTimeRange = range
                        loadCachedReport()
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selectedTimeRange.description)
                        .font(.system(size: 14, weight: .medium))
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(DesignSystem.Colors.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                        )
                )
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 0) {
            // 增加顶部间距以进一步下移整体位置
            Spacer()
                .frame(height: 140)
            
        VStack(spacing: 24) {
            // 加载动画
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.primary.opacity(0.2), lineWidth: 3)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                DesignSystem.Colors.primary,
                                DesignSystem.Colors.primary.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(animationRotation))
            }
            
            VStack(spacing: 8) {
                Text("正在生成回顾...")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("请稍候")
                    .font(.system(size: 14))
                .foregroundColor(.secondary)
            }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
        .padding(.horizontal, 12)
        .onAppear {
            startLoadingAnimation()
        }
        .onChange(of: service.isGenerating) { _, isGenerating in
            if isGenerating {
                startLoadingAnimation()
            } else {
                stopLoadingAnimation()
            }
        }
    }
    
    private func reportView(_ report: ThoughtJourneyReport) -> some View {
        VStack(spacing: 24) {
            // 内容区域
            reportContentCard(report.content)
        }
    }
    
    private func reportContentCard(_ content: String) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // 简洁的内容开始标识
                HStack(alignment: .center, spacing: 8) {
                Rectangle()
                    .fill(DesignSystem.Colors.primary)
                    .frame(width: 3, height: 20)
                    .cornerRadius(1.5)
                    
                Text("次元回放")
                    .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.top, 4)  // 微调垂直位置，让标题与刷新按钮在同一水平线上
                
            ExpandableTextView(content: content)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8) // 减小顶部padding，配合HStack的padding.top来对齐
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.red.opacity(0.7))
            
            Text("生成失败")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(error)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("重新生成") {
                generateReport()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(DesignSystem.Colors.primary)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
    }
    
    private var emptyView: some View {
        VStack(spacing: 28) {
            // 美化的图标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                DesignSystem.Colors.primary.opacity(0.1),
                                DesignSystem.Colors.primary.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 10)
                
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                DesignSystem.Colors.primary.opacity(0.15),
                                DesignSystem.Colors.primary.opacity(0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
            Image(systemName: "doc.text.below.ecg")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                    .shadow(color: DesignSystem.Colors.primary.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            
            VStack(spacing: 12) {
                Text("生成回顾报告")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                VStack(spacing: 8) {
                    Text("为这段时光生成专属回顾")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                    
                    Text("生成后将永久保存，可随时查看")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            
            Button("开始生成") {
                generateReport()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        DesignSystem.Colors.primary,
                                DesignSystem.Colors.primary.opacity(0.85)
                    ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                )
            )
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            .shadow(
                        color: DesignSystem.Colors.primary.opacity(0.4),
                        radius: 12,
                x: 0,
                        y: 6
                    )
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
        .padding(.horizontal, 20)
    }
    
    // MARK: - 方法
    
    private func loadCachedReport() {
        if let cachedReport = service.getCachedReport(for: selectedTimeRange) {
            service.currentReport = cachedReport
        }
        // 不自动生成报告，只显示缓存的报告或空状态
    }
    
    private func generateReport() {
        service.generateReport(timeRange: selectedTimeRange, modelContext: modelContext)
    }
    
    /// 重新生成报告 - 清除现有内容并生成新内容
    private func regenerateReport() {
        #if DEBUG
        print("🔄 用户确认重新生成次元回放报告")
        #endif
        service.currentReport = nil
        generateReport()
    }
    
    /// 启动加载动画
    private func startLoadingAnimation() {
        animationRotation = 0
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            animationRotation = 360
        }
    }
    
    /// 停止加载动画
    private func stopLoadingAnimation() {
        withAnimation(.none) {
            animationRotation = 0
        }
    }
}

// MARK: - 可展开文本视图
struct ExpandableTextView: View {
    let content: String
    @State private var isExpanded = false
    
    private let lineLimit = 8 // 默认显示8行
    private var shouldShowExpandButton: Bool {
        // 简单估算：如果内容超过一定长度就显示展开按钮
        content.count > 200
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 内容文本区域
            Text(content)
                .font(.system(size: 17, weight: .regular))
                .lineSpacing(6)
                .foregroundColor(Color.primary.opacity(0.8))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(isExpanded ? nil : lineLimit)
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
            
            // 展开/收起按钮 - 更大更明显的设计
            if shouldShowExpandButton {
                    Button(action: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 8) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.7, green: 0.5, blue: 0.9))  // 梦幻紫，与次元回放标签颜色一致
                        
                            Text(isExpanded ? "收起" : "展开全文")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(red: 0.7, green: 0.5, blue: 0.9))  // 梦幻紫，与次元回放标签颜色一致
                        }
                    .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 28)  // 更大的左右内边距，让按钮更拉长
                    .padding(.vertical, 10)  // 更小的上下边距，让按钮更扁
                        .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(red: 0.7, green: 0.5, blue: 0.9).opacity(0.1))  // 更明显的背景
                                .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color(red: 0.7, green: 0.5, blue: 0.9).opacity(0.25), lineWidth: 1)  // 更明显的边框
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                .padding(.top, 16)  // 增加按钮上方间距，让按钮更靠下
                .padding(.horizontal, 8)  // 减少按钮左右边距，让按钮更宽
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)  // 减少底部边距，让按钮下方空白更少
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                UIPasteboard.general.string = content.trimmingCharacters(in: .whitespacesAndNewlines)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowToast"),
                    object: nil,
                    userInfo: ["message": "已复制文字"]
                )
            } label: {
                Label("复制文字", systemImage: "doc.on.doc")
            }
        }
    }
} 