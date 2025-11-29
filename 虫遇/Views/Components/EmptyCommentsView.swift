import SwiftUI

/**
 * 空评论状态视图
 * 显示无评论时的简洁提示
 */
struct EmptyCommentsView: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("虫洞已开启，等你一起相遇")
                .font(.system(size: 14))
                    .foregroundColor(.secondary)
                .padding(.vertical, 20)
                    }
        .frame(maxWidth: .infinity)
    }
}

// 预览
struct EmptyCommentsView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyCommentsView()
            .previewLayout(.sizeThatFits)
            .padding()
    }
} 