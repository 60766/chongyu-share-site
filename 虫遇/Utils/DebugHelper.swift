import Foundation
import UIKit
import SwiftUI

/**
 * 调试辅助类
 * 用于在应用中显示调试信息，帮助诊断问题
 */
class DebugHelper {
    static let shared = DebugHelper()
    
    // 调试窗口
    private var debugWindow: UIWindow?
    private var debugViewController: DebugViewController?
    
    // 调试日志
    private var logs: [String] = []
    
    private init() {}
    
    // 添加日志
    func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logEntry = "[\(timestamp)] \(message)"
        logs.append(logEntry)
        
        // 如果日志超过100条，删除最早的日志
        if logs.count > 100 {
            logs.removeFirst()
        }
        
        // 更新调试视图
        if let debugVC = debugViewController {
            DispatchQueue.main.async {
                debugVC.updateLogs(self.logs)
            }
        }
        
        print("🐞 \(logEntry)")
    }
    
    // 显示调试窗口
    func showDebugWindow() {
        guard debugWindow == nil else {
            // 如果已经显示，则隐藏
            hideDebugWindow()
            return
        }
        
        let debugVC = DebugViewController()
        debugVC.logs = logs
        
        if let windowScene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .first as? UIWindowScene {
            
            let window = UIWindow(windowScene: windowScene)
            window.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 300)
            window.windowLevel = UIWindow.Level.alert + 1
            window.rootViewController = debugVC
            window.isHidden = false
            window.backgroundColor = .clear
            
            debugWindow = window
            debugViewController = debugVC
        }
    }
    
    // 隐藏调试窗口
    func hideDebugWindow() {
        debugWindow?.isHidden = true
        debugWindow = nil
        debugViewController = nil
    }
    
    // 测试API连接
    func testAPI() {
        log("开始测试API连接...")
        
        APITestHelper.testAPIConnectivity { success, message in
            DispatchQueue.main.async {
                if success {
                    self.log("✅ API测试成功: \(message)")
                } else {
                    self.log("❌ API测试失败: \(message)")
                }
                
                // 显示调试窗口
                self.showDebugWindow()
            }
        }
    }
    
    // 测试评论生成
    func testCommentGeneration() {
        log("开始测试评论生成...")
        
        APITestHelper.testCommentGeneration { success, message in
            DispatchQueue.main.async {
                if success {
                    self.log("✅ 评论生成测试成功: \(message)")
                } else {
                    self.log("❌ 评论生成测试失败: \(message)")
                }
                
                // 显示调试窗口
                self.showDebugWindow()
            }
        }
    }
    
    // 测试虚拟角色评论生成并添加到帖子
    func testVirtualCharacterComment(characterID: String? = nil) {
        log("开始测试虚拟角色评论生成并添加到帖子...")
        
        // 调用VirtualCharacterService的测试方法
        APITestHelper.testVirtualCharacterComment(characterID: characterID) { success, message in
            DispatchQueue.main.async {
                if success {
                    self.log("✅ 虚拟角色评论生成成功: \(message)")
                } else {
                    self.log("❌ 虚拟角色评论生成失败: \(message)")
                }
                
                // 显示调试窗口
                self.showDebugWindow()
            }
        }
    }
}

/**
 * 调试视图控制器
 */
class DebugViewController: UIViewController {
    // 日志文本视图
    private let logTextView = UITextView()
    
    // 关闭按钮
    private let closeButton = UIButton(type: .system)
    
    // 测试API按钮
    private let testAPIButton = UIButton(type: .system)
    
    // 测试虚拟角色按钮
    private let testCharacterButton = UIButton(type: .system)
    
    // 日志数据
    var logs: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        // 配置日志文本视图
        logTextView.translatesAutoresizingMaskIntoConstraints = false
        logTextView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        logTextView.textColor = .white
        logTextView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        logTextView.isEditable = false
        logTextView.text = logs.joined(separator: "\n")
        view.addSubview(logTextView)
        
        // 配置关闭按钮
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("关闭", for: .normal)
        closeButton.backgroundColor = .systemRed
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.layer.cornerRadius = 15
        closeButton.addTarget(self, action: #selector(closeDebugWindow), for: .touchUpInside)
        view.addSubview(closeButton)
        
        // 配置测试API按钮
        testAPIButton.translatesAutoresizingMaskIntoConstraints = false
        testAPIButton.setTitle("测试API", for: .normal)
        testAPIButton.backgroundColor = .systemBlue
        testAPIButton.setTitleColor(.white, for: .normal)
        testAPIButton.layer.cornerRadius = 15
        testAPIButton.addTarget(self, action: #selector(testAPI), for: .touchUpInside)
        view.addSubview(testAPIButton)
        
        // 配置测试虚拟角色按钮
        testCharacterButton.translatesAutoresizingMaskIntoConstraints = false
        testCharacterButton.setTitle("测试角色回复", for: .normal)
        testCharacterButton.backgroundColor = .systemGreen
        testCharacterButton.setTitleColor(.white, for: .normal)
        testCharacterButton.layer.cornerRadius = 15
        testCharacterButton.addTarget(self, action: #selector(testCharacter), for: .touchUpInside)
        view.addSubview(testCharacterButton)
        
        // 布局约束
        NSLayoutConstraint.activate([
            logTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            logTextView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            logTextView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            logTextView.bottomAnchor.constraint(equalTo: closeButton.topAnchor, constant: -10),
            
            closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            closeButton.heightAnchor.constraint(equalToConstant: 40),
            closeButton.widthAnchor.constraint(equalToConstant: 80),
            
            testAPIButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            testAPIButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            testAPIButton.heightAnchor.constraint(equalToConstant: 40),
            testAPIButton.widthAnchor.constraint(equalToConstant: 80),
            
            testCharacterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testCharacterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            testCharacterButton.heightAnchor.constraint(equalToConstant: 40),
            testCharacterButton.widthAnchor.constraint(equalToConstant: 120),
        ])
        
        // 添加拖动手势
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(panGesture)
    }
    
    // 更新日志
    func updateLogs(_ newLogs: [String]) {
        logs = newLogs
        logTextView.text = logs.joined(separator: "\n")
        
        // 滚动到底部
        let bottom = NSMakeRange(logTextView.text.count - 1, 1)
        logTextView.scrollRangeToVisible(bottom)
    }
    
    // 关闭调试窗口
    @objc private func closeDebugWindow() {
        DebugHelper.shared.hideDebugWindow()
    }
    
    // 测试API
    @objc private func testAPI() {
        DebugHelper.shared.testAPI()
    }
    
    // 测试虚拟角色评论
    @objc private func testCharacter() {
        // 默认使用莎士比亚角色
        DebugHelper.shared.testVirtualCharacterComment(characterID: "shakespeare")
    }
    
    // 处理拖动手势
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let window = view.window else { return }
        
        let translation = gesture.translation(in: view)
        
        // 仅允许垂直拖动
        window.frame.origin.y += translation.y
        
        // 确保不超出屏幕
        if window.frame.origin.y < 0 {
            window.frame.origin.y = 0
        } else if window.frame.origin.y > UIScreen.main.bounds.height - window.frame.height {
            window.frame.origin.y = UIScreen.main.bounds.height - window.frame.height
        }
        
        gesture.setTranslation(.zero, in: view)
    }
} 