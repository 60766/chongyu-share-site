import SwiftUI
import UIKit

struct EnhancedTextDisplayView: View {
    @Binding var text: String
    var placeholder: String
    
    init(text: Binding<String>, 
         placeholder: String = "") {
        self._text = text
        self.placeholder = placeholder
    }
    
    var body: some View {
        // 使用UIKitTextView替代TextEditor
        UIKitTextView(text: $text, placeholder: placeholder)
            .frame(height: 100)
            .overlay(
                // 紫色边框
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.purple, lineWidth: 1)
            )
    }
}

struct UIKitTextView: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.text = placeholder
        textView.textColor = UIColor.lightGray
        textView.backgroundColor = .white
        textView.layer.cornerRadius = 15
        textView.layer.borderColor = UIColor.purple.cgColor
        textView.layer.borderWidth = 1
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if text.isEmpty {
            uiView.text = placeholder
            uiView.textColor = UIColor.lightGray
        } else {
            uiView.text = text
            uiView.textColor = UIColor.black
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: UIKitTextView
        
        init(_ parent: UIKitTextView) {
            self.parent = parent
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.text == parent.placeholder {
                textView.text = ""
                textView.textColor = UIColor.black
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = UIColor.lightGray
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}

// 预览
struct EnhancedTextDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedTextDisplayView(
            text: .constant(""),
            placeholder: "请输入内容..."
        )
        .padding()
    }
} 