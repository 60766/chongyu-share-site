import SwiftUI

/**
 * 头像修复测试入口
 * 提供多种测试视图的入口
 */
struct AvatarFixTestView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("修复演示", destination: FixedAvatarDemoView())
                NavigationLink("ImageHelper测试", destination: ImageHelperTestView())
                
                Section(header: Text("测试特定角色")) {
                    ForEach(["einstein", "shakespeare", "davinci", "kongzi", "newton"], id: \.self) { id in
                        NavigationLink(id, destination: SingleAvatarTestView(characterId: id))
                    }
                }
            }
            .navigationTitle("头像修复测试")
        }
    }
}

/**
 * 单个角色头像测试视图
 */
struct SingleAvatarTestView: View {
    let characterId: String
    
    var body: some View {
        VStack(spacing: 30) {
            Text("角色ID: \(characterId)")
                .font(.headline)
            
            VStack(spacing: 10) {
                Text("CharacterAvatarSimple").font(.caption)
                CharacterAvatarSimple(characterId, size: 100)
            }
            
            VStack(spacing: 10) {
                Text("ImageHelper").font(.caption)
                ImageHelper.loadCharacterAvatar(characterId, size: 100)
            }
            
            // 显示路径信息
            VStack(alignment: .leading, spacing: 5) {
                Text("路径信息:").font(.headline)
                Text("直接路径: \(UIImage(named: characterId) != nil ? "可用" : "不可用")")
                Text("历史人物路径: \(UIImage(named: "HistoricalFigures/\(characterId)") != nil ? "可用" : "不可用")")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            Spacer()
        }
        .padding()
        .navigationTitle(characterId)
    }
}
