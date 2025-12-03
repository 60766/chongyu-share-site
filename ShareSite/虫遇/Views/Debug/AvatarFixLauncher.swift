import SwiftUI

/**
 * 头像修复启动器
 * 在ContentView中添加此视图可快速访问测试工具
 */
struct AvatarFixLauncher: View {
    @State private var showTestView = false
    
    var body: some View {
        VStack {
            Button(action: {
                showTestView = true
            }) {
                Text("测试头像修复")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $showTestView) {
                AvatarFixTestView()
            }
        }
    }
}

struct AvatarFixLauncher_Previews: PreviewProvider {
    static var previews: some View {
        AvatarFixLauncher()
    }
}
