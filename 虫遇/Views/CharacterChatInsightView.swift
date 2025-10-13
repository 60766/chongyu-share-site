import SwiftUI
import SwiftData

/**
 * 角色聊天画像视图
 * 展示用户与某个角色的互动画像
 */
struct CharacterChatInsightView: View {
    let characterId: String
    let characterName: String
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var service = CharacterChatInsightService.shared
    
    @State private var insight: CharacterChatInsight?
    @State private var showError = false
    @State private var showRefreshConfirm = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if service.isGenerating {
                    // 加载状态
                    VStack(spacing: 16) {
                        // 动画图标
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue.opacity(0.1),
                                            Color.purple.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(1.2)
                        }
                        
                        // 加载文字
                        VStack(spacing: 8) {
                            Text("正在生成你的互动画像...")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            Text("分析聊天记录中，请稍候")
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .foregroundStyle(.secondary)
                        }
                        .multilineTextAlignment(.center)
                        
                        // 提示卡片
                        HStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.orange)
                                .symbolRenderingMode(.hierarchical)
                            Text("通常需要 10-30 秒")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.orange.opacity(0.08))
                                .stroke(.orange.opacity(0.2), lineWidth: 0.5)
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("正在生成互动画像，请稍候")
                    
                } else if let insight = insight {
                    // 显示画像
                    insightCard(insight)
                    
                } else {
                    // 空状态
                    emptyState
                }
            }
            .padding()
        }
        .navigationTitle("互动画像")
        .navigationBarTitleDisplayMode(.inline)
        .alert("提示", isPresented: $showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(service.errorMessage ?? "生成失败")
        }
        .alert("确认刷新", isPresented: $showRefreshConfirm) {
            Button("取消", role: .cancel) { }
            Button("确定", role: .destructive) {
                refreshInsight()
            }
        } message: {
            Text("确定要重新生成吗？这将替换当前内容")
        }
        .onAppear {
            // 清除之前的错误信息，避免显示其他角色的错误
            service.errorMessage = nil
            loadCachedInsight()
        }
    }
    
    // MARK: - 画像卡片
    
    @ViewBuilder
    private func insightCard(_ insight: CharacterChatInsight) -> some View {
        VStack(spacing: 20) {
            // 标题和标签（带刷新按钮）
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 16) {
                    // 主标题
                    Text(insight.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    // 标签容器 - 单排水平布局
                    if !insight.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(insight.tags, id: \.self) { tag in
                                    tagView(tag)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                
                // 刷新按钮（右上角）
                Button(action: {
                    showRefreshConfirm = true
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.blue)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.regularMaterial)
                                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                        )
                }
                .padding(16)
                .accessibilityLabel("刷新画像")
                .accessibilityHint("重新生成互动画像")
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "E3F2FD").opacity(0.9),  // 淡蓝色
                        Color(hex: "F3E5F5").opacity(0.8),  // 淡紫色
                        Color(hex: "FCE4EC").opacity(0.7),  // 淡粉色
                        Color.white.opacity(0.8)            // 纯白
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.2),
                                Color.purple.opacity(0.15),
                                Color.pink.opacity(0.1),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
            .cornerRadius(16)
            .shadow(color: Color.blue.opacity(0.1), radius: 10, x: 0, y: 3)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            // 总结
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.blue)
                        .symbolRenderingMode(.multicolor)
                    Text("画像总结")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                .accessibilityElement(children: .combine)
                
                Text(insight.summary)
                    .font(.system(size: 15))
                    .foregroundColor(.primary.opacity(0.85))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "E8F4FD").opacity(0.8),  // 淡蓝色
                        Color(hex: "F0F8FF").opacity(0.6),  // 爱丽丝蓝
                        Color(hex: "F8FBFF").opacity(0.4),  // 极淡蓝白
                        Color.white.opacity(0.9)            // 纯白
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.15),
                                Color.purple.opacity(0.1),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: Color.blue.opacity(0.08), radius: 8, x: 0, y: 2)
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
            
            // 最近关注点
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.purple)
                        .symbolRenderingMode(.hierarchical)
                    Text("最近关注")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                .accessibilityElement(children: .combine)
                
                Text(insight.recentFocus)
                    .font(.system(size: 15))
                    .foregroundColor(.primary.opacity(0.85))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "F0E6FF").opacity(0.8),  // 淡紫色
                        Color(hex: "F8F0FF").opacity(0.6),  // 薰衣草白
                        Color(hex: "FDFBFF").opacity(0.4),  // 极淡紫白
                        Color.white.opacity(0.9)            // 纯白
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.purple.opacity(0.15),
                                Color.pink.opacity(0.1),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: Color.purple.opacity(0.08), radius: 8, x: 0, y: 2)
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
            
            // 下一步建议
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.orange)
                        .symbolRenderingMode(.multicolor)
                    Text("聊天建议")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                .accessibilityElement(children: .combine)
                
                Text(insight.nextSuggestion)
                    .font(.system(size: 15))
                    .foregroundColor(.primary.opacity(0.85))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "FFF4E6").opacity(0.9),  // 温暖的桃色
                        Color(hex: "FFF8F0").opacity(0.7),  // 淡桃白
                        Color(hex: "FFFCF8").opacity(0.5),  // 极淡桃白
                        Color.white.opacity(0.9)            // 纯白
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.orange.opacity(0.2),
                                Color.yellow.opacity(0.15),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: Color.orange.opacity(0.1), radius: 8, x: 0, y: 2)
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
            
            // 数据说明和生成时间
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .symbolRenderingMode(.hierarchical)
                    Text("基于最近 20 条互动生成")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .symbolRenderingMode(.hierarchical)
                    Text("生成于 \(formatDate(insight.generatedAt))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - 空状态
    
    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 16) {
                // 使用说明卡片
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.blue)
                            .symbolRenderingMode(.hierarchical)
                        Text("画像生成说明")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                    .accessibilityElement(children: .combine)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "heart.text.square.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.pink)
                                .symbolRenderingMode(.hierarchical)
                                .frame(width: 20)
                            Text("看看你在 TA 眼中是什么样子")
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                        
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.orange)
                                .symbolRenderingMode(.multicolor)
                                .frame(width: 20)
                            Text("发现你们独特的聊天默契")
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                        
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "face.smiling.inverse")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.purple)
                                .symbolRenderingMode(.hierarchical)
                                .frame(width: 20)
                            Text("获得专属于你的有趣标签")
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .stroke(.quaternary, lineWidth: 0.5)
                )
                .padding(.horizontal, 20)
                
                // 温馨提示
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.orange)
                        .symbolRenderingMode(.hierarchical)
                    Text("需要至少 10 轮对话才能生成哦～")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.orange.opacity(0.08))
                        .stroke(.orange.opacity(0.2), lineWidth: 0.5)
                )
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .accessibilityElement(children: .combine)
                
                // 生成按钮
                Button(action: {
                    generateInsight()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .symbolRenderingMode(.multicolor)
                        Text("生成画像")
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue,
                                Color.purple.opacity(0.9)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .accessibilityLabel("生成互动画像")
                .accessibilityHint("分析您与角色的聊天记录并生成个性化画像")
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 方法
    
    private func loadCachedInsight() {
        // 只加载缓存，不自动生成
        print("🔍 CharacterChatInsightView - 尝试加载缓存画像，角色ID: \(characterId)")
        let cachedInsight = service.loadCachedInsight(characterId: characterId, modelContext: modelContext)
        
        if let cachedInsight = cachedInsight {
            print("✅ CharacterChatInsightView - 成功加载缓存画像: \(cachedInsight.title)")
            insight = cachedInsight
        } else {
            print("⚠️ CharacterChatInsightView - 未找到缓存画像")
            insight = nil
        }
    }
    
    private func generateInsight() {
        service.generateInsight(
            characterId: characterId,
            characterName: characterName,
            modelContext: modelContext
        ) { result in
            switch result {
            case .success(let generatedInsight):
                self.insight = generatedInsight
            case .failure:
                // 稍微延迟显示错误，确保service.errorMessage已经更新
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.showError = true
                }
            }
        }
    }
    
    private func refreshInsight() {
        // 清除缓存后重新生成
        service.clearCache(characterId: characterId, modelContext: modelContext)
        insight = nil
        generateInsight()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    // MARK: - 辅助视图
    
    // 流式布局容器
    
    @ViewBuilder
    private func tagView(_ tag: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.blue)
            Text(tag)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.blue)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .blue.opacity(0.06),
                            .blue.opacity(0.12)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .stroke(.blue.opacity(0.25), lineWidth: 0.8)
        )
        .shadow(color: .blue.opacity(0.1), radius: 1, x: 0, y: 0.5)
    }
}

// MARK: - 预览

#Preview {
    NavigationStack {
        CharacterChatInsightView(
            characterId: "shakespeare",
            characterName: "莎士比亚"
        )
    }
}

