import SwiftUI

/**
 * 图片加载测试工具
 * 用于验证不同方式加载图片的效果
 */
struct ImageLoadingTest: View {
    let characterIds = ["einstein", "shakespeare", "davinci", "kongzi", "socrates"]
    
    var body: some View {
        VStack {
            Text("图片加载测试").font(.title)
            
            ForEach(characterIds, id: \.self) { id in
                HStack {
                    // 方式1: 直接使用Image(id)
                    Image(id)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Text("方式1"))
                    
                    // 方式2: 使用Image(uiImage:)
                    if let uiImage = UIImage(named: id) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .overlay(Text("方式2"))
                    } else {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 50, height: 50)
                            .overlay(Text("方式2失败"))
                    }
                    
                    Text(id)
                }
                .padding(.vertical, 5)
            }
        }
        .padding()
    }
}
