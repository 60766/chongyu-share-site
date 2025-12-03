import SwiftUI

/**
 * 头像快速测试视图
 * 用于验证ImageHelper是否正常工作
 */
struct AvatarQuickTest: View {
    // 测试角色列表
    let testCharacters = [
        "einstein",    // 爱因斯坦
        "shakespeare", // 莎士比亚
        "davinci",     // 达芬奇
        "kongzi",      // 孔子
        "newton",      // 牛顿
        "socrates",    // 苏格拉底
        "plato",       // 柏拉图
        "mozart",      // 莫扎特
        "beethoven",   // 贝多芬
        "tesla"        // 特斯拉
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("头像加载测试").font(.title)
                    
                    // 使用CharacterAvatarSimple加载头像
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 15) {
                        ForEach(testCharacters, id: \.self) { id in
                            VStack {
                                CharacterAvatarSimple(id, size: 60)
                                Text(id)
                                    .font(.caption)
                            }
                            .padding(5)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    
                    // 显示路径可用性信息
                    VStack(alignment: .leading, spacing: 10) {
                        Text("路径可用性检查:").font(.headline)
                        
                        ForEach(testCharacters, id: \.self) { id in
                            HStack {
                                Text(id)
                                    .frame(width: 100, alignment: .leading)
                                
                                if UIImage(named: id) != nil {
                                    Text("直接路径 ✅")
                                        .foregroundColor(.green)
                                } else {
                                    Text("直接路径 ❌")
                                        .foregroundColor(.red)
                                }
                                
                                if UIImage(named: "HistoricalFigures/\(id)") != nil {
                                    Text("历史路径 ✅")
                                        .foregroundColor(.green)
                                } else {
                                    Text("历史路径 ❌")
                                        .foregroundColor(.red)
                                }
                            }
                            .font(.caption)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("头像测试")
        }
    }
}
