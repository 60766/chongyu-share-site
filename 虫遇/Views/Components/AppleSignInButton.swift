import SwiftUI
import AuthenticationServices

struct AppleSignInButton: View {
    @ObservedObject private var appleSignInManager = AppleSignInManager.shared
    
    let buttonType: ASAuthorizationAppleIDButton.ButtonType
    let buttonStyle: ASAuthorizationAppleIDButton.Style
    
    init(
        buttonType: ASAuthorizationAppleIDButton.ButtonType = .signIn,
        buttonStyle: ASAuthorizationAppleIDButton.Style = .black
    ) {
        self.buttonType = buttonType
        self.buttonStyle = buttonStyle
    }
    
    var body: some View {
        SignInWithAppleButtonRepresentable(
            buttonType: buttonType,
            buttonStyle: buttonStyle
        ) {
            appleSignInManager.signInWithApple()
        }
        .frame(height: 50)
        .cornerRadius(8)
    }
}

struct SignInWithAppleButtonRepresentable: UIViewRepresentable {
    let buttonType: ASAuthorizationAppleIDButton.ButtonType
    let buttonStyle: ASAuthorizationAppleIDButton.Style
    let action: () -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(
            authorizationButtonType: buttonType,
            authorizationButtonStyle: buttonStyle
        )
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.buttonTapped),
            for: .touchUpInside
        )
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        // 无需更新
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        let action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func buttonTapped() {
            action()
        }
    }
}

// MARK: - 预览

struct AppleSignInButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AppleSignInButton(
                buttonType: .signIn,
                buttonStyle: .black
            )
            
            AppleSignInButton(
                buttonType: .signIn,
                buttonStyle: .white
            )
            
            AppleSignInButton(
                buttonType: .signIn,
                buttonStyle: .whiteOutline
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
} 