//
//  ShareCardPreviewView.swift
//  虫遇
//
//  Created by AI Assistant on 2025-10-17.
//

import SwiftUI

struct ShareCardPreviewView: View {
    @State private var selectedTab = 0
    @State private var showDesignNotes = true
    
    // 示例数据
    private let sampleMessages = [
        ChatMessage(
            characterId: "libai",
            content: "你好，我是李白，今日月色甚美，不如我们一起作诗如何？",
            timestamp: Date().addingTimeInterval(-120)
        ),
        ChatMessage(
            characterId: "user",
            content: "好啊！我很喜欢你的诗，能教我一些作诗的技巧吗？",
            timestamp: Date().addingTimeInterval(-60),
            isUserMessage: true
        ),
        ChatMessage(
            characterId: "libai",
            content: "作诗之道，在于情真意切。观山川之壮美，感人生之起伏，自然成章。",
            timestamp: Date()
        )
    ]
    
    private let multiChatMessages = [
        ChatMessage(
            characterId: "libai",
            content: "诸位好，今日我们来讨论一下诗词的韵律美。",
            timestamp: Date().addingTimeInterval(-120)
        ),
        ChatMessage(
            characterId: "dufu",
            content: "李兄说得对，诗词确实需要讲究韵律。",
            timestamp: Date().addingTimeInterval(-60)
        ),
        ChatMessage(
            characterId: "user",
            content: "我觉得诗词不仅要有韵律，更要有深刻的内涵。",
            timestamp: Date(),
            isUserMessage: true
        )
    ]
    
    // 示例角色数据
    private let sampleCharacters = [
        CharacterModel(
            id: "libai",
            name: "李白",
            avatar: "avatar_libai",
            era: "701-762",
            profession: "诗人",
            bio: "唐代伟大的浪漫主义诗人，被后人誉为\"诗仙\"。",
            category: .writer
        ),
        CharacterModel(
            id: "dufu",
            name: "杜甫",
            avatar: "avatar_dufu",
            era: "712-770",
            profession: "诗人",
            bio: "唐代伟大的现实主义诗人，被后人誉为\"诗圣\"。",
            category: .writer
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标签页选择器
                Picker("卡片类型", selection: $selectedTab) {
                    Text("单人聊天").tag(0)
                    Text("多人聊天").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                ScrollView {
                    VStack(spacing: 30) {
                        if selectedTab == 0 {
                            // 单人聊天分享卡片预览
                            VStack(alignment: .leading, spacing: 16) {
                                Text("单人聊天分享卡片")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                // 由于 ChatShareCardGenerator 使用不同的数据类型，这里展示多人聊天卡片
                                MultiChatMergedCardView(
                                    messages: sampleMessages,
                                    characters: sampleCharacters,
                                    theme: "诗词创作交流"
                                )
                                .scaleEffect(0.8)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            }
                        } else {
                            // 多人聊天分享卡片预览
                            VStack(alignment: .leading, spacing: 16) {
                                Text("多人聊天分享卡片")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                MultiChatMergedCardView(
                                    messages: multiChatMessages,
                                    characters: sampleCharacters,
                                    theme: "诗词韵律讨论"
                                )
                                .scaleEffect(0.8)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                
                                Text("单条消息卡片")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                if let firstMessage = multiChatMessages.first,
                                   let character = sampleCharacters.first(where: { $0.id == firstMessage.characterId }) {
                                    MultiChatShareCardView(
                                        message: firstMessage,
                                        character: character,
                                        theme: "诗词韵律讨论"
                                    )
                                    .scaleEffect(0.8)
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                }
                            }
                        }
                        
                        // 设计说明
                        if showDesignNotes {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("设计优化亮点")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        withAnimation {
                                            showDesignNotes.toggle()
                                        }
                                    }) {
                                        Image(systemName: "chevron.up")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    ShareCardFeatureRow(icon: "🎨", title: "渐变背景", description: "采用多层次渐变，营造深度感")
                                    ShareCardFeatureRow(icon: "✨", title: "装饰元素", description: "添加几何图案和光效，增强视觉吸引力")
                                    ShareCardFeatureRow(icon: "💬", title: "消息气泡", description: "3D立体效果，带有光影和边框")
                                    ShareCardFeatureRow(icon: "🎯", title: "主题标签", description: "精美的胶囊设计，突出对话主题")
                                    ShareCardFeatureRow(icon: "🌈", title: "色彩搭配", description: "角色主题色与整体配色和谐统一")
                                    ShareCardFeatureRow(icon: "📐", title: "间距优化", description: "调整文本和元素间距，提高可读性")
                                    ShareCardFeatureRow(icon: "🔠", title: "字体层次", description: "通过字重和大小区分不同内容重要性")
                                    ShareCardFeatureRow(icon: "🖼️", title: "阴影效果", description: "增强消息气泡的立体感和层次感")
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical)
                            .background(Color(UIColor.systemBackground).opacity(0.8))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else {
                            HStack {
                                Text("设计优化亮点")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        showDesignNotes.toggle()
                                    }
                                }) {
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground).opacity(0.8))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("分享卡片预览")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ShareCardFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ShareCardPreviewView()
}