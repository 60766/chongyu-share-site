import SwiftUI

/**
 * 点击事件调试视图
 * 用于显示点击事件的位置和传递情况
 * 帮助用户理解和解决点击事件问题
 */
struct TouchDebugView: View {
    @State private var touchPoints: [CGPoint] = []
    @State private var isEnabled = true
    @State private var showOverlay = true
    
    var body: some View {
        ZStack {
            // 主内容
            VStack(spacing: 20) {
                // 标题
                Text("点击事件调试")
                    .font(.title)
                    .padding()
                
                // 控制按钮
                HStack(spacing: 20) {
                    // 启用/禁用按钮
                    Button(action: {
                        isEnabled.toggle()
                    }) {
                        Text(isEnabled ? "禁用调试" : "启用调试")
                            .padding()
                            .background(isEnabled ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    // 清除按钮
                    Button(action: {
                        touchPoints.removeAll()
                    }) {
                        Text("清除点击")
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    // 显示/隐藏覆盖层按钮
                    Button(action: {
                        showOverlay.toggle()
                    }) {
                        Text(showOverlay ? "隐藏覆盖层" : "显示覆盖层")
                            .padding()
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                
                // 说明文本
                Text("点击屏幕任意位置，将显示点击位置")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                
                // 点击记录列表
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(0..<touchPoints.count, id: \.self) { index in
                            Text("点击 \(index + 1): x=\(Int(touchPoints[index].x)), y=\(Int(touchPoints[index].y))")
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding()
            }
            .padding()
            
            // 点击覆盖层
            if isEnabled && showOverlay {
                Color.clear
                    .contentShape(Rectangle())
                    .edgesIgnoringSafeArea(.all)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let location = value.location
                                if touchPoints.isEmpty || touchPoints.last != location {
                                    touchPoints.append(location)
                                    #if DEBUG
                                    print("触摸点: x=\(location.x), y=\(location.y)")
                                    #endif
                                }
                            }
                    )
                    .overlay(
                        ZStack {
                            // 显示所有点击点
                            ForEach(0..<touchPoints.count, id: \.self) { index in
                                Circle()
                                    .fill(Color.red.opacity(0.5))
                                    .frame(width: 20, height: 20)
                                    .position(touchPoints[index])
                                    .overlay(
                                        Text("\(index + 1)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .position(touchPoints[index])
                                    )
                            }
                        }
                    )
            }
        }
        .navigationTitle("点击调试")
    }
}

// 预览
struct TouchDebugView_Previews: PreviewProvider {
    static var previews: some View {
        TouchDebugView()
    }
} 