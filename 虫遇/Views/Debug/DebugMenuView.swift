//
// DebugMenuView.swift
// 虫遇
//

import SwiftUI

/**
 * 调试菜单视图
 * 集中管理所有调试工具
 */
struct DebugMenuView: View {
    @State private var showingAvatarTest = false
    @State private var showingLetterAvatarTest = false
    @State private var showingHermioneTest = false
    @State private var showingPostAvatarTest = false
    @State private var showingCommentAvatarTest = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("头像测试")) {
                    Button("测试角色头像") {
                        showingAvatarTest = true
                    }
                    
                    Button("测试字母头像") {
                        showingLetterAvatarTest = true
                    }
                    
                    Button("测试赫敏头像") {
                        showingHermioneTest = true
                    }
                    
                    Button("测试PostAvatar组件") {
                        showingPostAvatarTest = true
                    }
                    
                    Button("测试评论头像") {
                        showingCommentAvatarTest = true
                    }
                }
                
                Section(header: Text("界面测试")) {
                    NavigationLink("键盘测试", destination: KeyboardDebugView())
                    NavigationLink("发布面板测试", destination: PublishPanelTestView())
                    NavigationLink("标签栏测试", destination: TabBarTest())
                }
            }
            .navigationTitle("调试菜单")
        }
        .sheet(isPresented: $showingAvatarTest) {
            AvatarDebugView()
        }
        .sheet(isPresented: $showingLetterAvatarTest) {
            LetterAvatarTestView()
        }
        .sheet(isPresented: $showingHermioneTest) {
            HermioneAvatarTestView()
        }
        .sheet(isPresented: $showingPostAvatarTest) {
            PostAvatarTestView()
        }
        .sheet(isPresented: $showingCommentAvatarTest) {
            CommentAvatarTestView()
        }
    }
}

// MARK: - 预览
struct DebugMenuView_Previews: PreviewProvider {
    static var previews: some View {
        DebugMenuView()
    }
} 