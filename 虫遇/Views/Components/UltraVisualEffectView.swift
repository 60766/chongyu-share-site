import SwiftUI
import UIKit

/**
 * 高级模糊效果视图
 * 提供多种模糊风格，支持SwiftUI与UIKit的桥接
 */
struct UltraVisualEffectView: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    var vibrancy: Bool = false
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: blurStyle)
        let blurView = UIVisualEffectView(effect: blurEffect)
        
        // 添加振动效果（可选）
        if vibrancy {
            let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
            let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
            vibrancyView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            blurView.contentView.addSubview(vibrancyView)
        }
        
        return blurView
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        // 更新模糊效果（如有需要）
        if let currentEffect = uiView.effect as? UIBlurEffect,
           currentEffect != UIBlurEffect(style: blurStyle) {
            uiView.effect = UIBlurEffect(style: blurStyle)
            
            // 如果启用了振动效果，也需要更新
            if vibrancy {
                let newBlurEffect = UIBlurEffect(style: blurStyle)
                let vibrancyEffect = UIVibrancyEffect(blurEffect: newBlurEffect)
                
                if let vibrancyView = uiView.contentView.subviews.first as? UIVisualEffectView {
                    vibrancyView.effect = vibrancyEffect
                }
            }
        }
    }
}

// 预览
struct UltraVisualEffectView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.blue
                .edgesIgnoringSafeArea(.all)
            
            UltraVisualEffectView(blurStyle: .systemMaterial)
                .frame(width: 200, height: 200)
                .cornerRadius(20)
                .overlay(
                    Text("磨砂效果")
                        .foregroundColor(.primary)
                )
        }
    }
} 