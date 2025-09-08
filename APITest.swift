#if DEBUG
import Foundation
import Combine

// 简单的测试程序，用于验证DeepSeek API调用
// 使用 swift APITest.swift 运行

// 等待异步操作完成的信号量
let semaphore = DispatchSemaphore(value: 0)

// 保存订阅
var cancellables = Set<AnyCancellable>()

func runTest() {
    print("📱 开始测试DeepSeek API...")
    
    // 确保API密钥已加载
    _ = APIConfigManager.shared
    
    // 等待1秒确保API配置加载完成
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        // 测试不同角色的评论生成
        let characters = ["einstein", "shakespeare", "davinci", "confucius", "libai"]
        let testCharacter = characters.randomElement() ?? "einstein"
        
        print("🧪 测试角色: \(testCharacter)")
        
        // 调用测试方法
        VirtualCharacterService.shared.testGenerateCharacterComment(characterID: testCharacter)
        
        // 等待10秒后结束测试（给API调用足够的时间）
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            print("🏁 测试结束")
            semaphore.signal()
        }
    }
    
    // 等待测试完成
    semaphore.wait()
}

// 执行测试
runTest()
#endif 