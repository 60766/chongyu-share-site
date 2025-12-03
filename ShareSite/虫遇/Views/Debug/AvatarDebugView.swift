import SwiftUI

struct AvatarDebugView: View {
    let characterIds = ["einstein", "shakespeare", "davinci", "kongzi", "newton", "libai"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("头像调试视图")
                    .font(.title)
                    .padding()
                
                ForEach(characterIds, id: \.self) { id in
                    VStack {
                        Text(id)
                            .font(.headline)
                        
                        // 直接使用Image加载
                        Image(id)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            .padding(.bottom, 5)
                        
                        Text("直接加载")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
    }
}

#Preview {
    AvatarDebugView()
}
