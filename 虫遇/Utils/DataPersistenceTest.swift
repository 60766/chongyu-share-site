import Foundation
import SwiftUI

/**
 * 数据持久化测试工具
 * 用于验证优化后的数据保存机制
 */
class DataPersistenceTest {
    static let shared = DataPersistenceTest()
    private init() {}
    
    /**
     * 测试数据一致性检查
     */
    func testDataConsistency() {
        #if DEBUG
        print("🧪 开始数据一致性测试...")
        #endif
        
        let viewModel = PostViewModel.shared
        
        // 获取当前状态
        let consistencyInfo = viewModel.getDataConsistencyInfo()
        #if DEBUG
        print("📊 当前数据状态:")
        #endif
        #if DEBUG
        print(consistencyInfo)
        #endif
        
        // 验证数据
        DispatchQueue.global(qos: .utility).async {
            let memoryUserPosts = viewModel.posts.filter { $0.source == "user" }
            let savedUserPosts = viewModel.restoreUserPostsData()
            
            let memoryAIPosts = viewModel.posts.filter { post in
                guard let source = post.source else { return false }
                return source != "user" && source != "welcome"
            }
            let savedAIPosts = viewModel.restoreAIPostsData()
            
            DispatchQueue.main.async {
                #if DEBUG
                print("📈 测试结果:")
                #endif
                #if DEBUG
                print("   内存用户帖子: \(memoryUserPosts.count)")
                #endif
                #if DEBUG
                print("   持久化用户帖子: \(savedUserPosts.count)")
                #endif
                #if DEBUG
                print("   内存AI帖子: \(memoryAIPosts.count)")
                #endif
                #if DEBUG
                print("   持久化AI帖子: \(savedAIPosts.count)")
                #endif
                #if DEBUG
                print("   数据一致性: \(viewModel.isDataConsistent ? "✅" : "❌")")
                #endif
            }
        }
    }
    
    /**
     * 测试关键节点保存
     */
    func testCriticalPointSave() {
        #if DEBUG
        print("🧪 测试关键节点保存...")
        #endif
        
        let viewModel = PostViewModel.shared
        let startTime = Date()
        
        // 触发保存
        viewModel.saveAtCriticalPoint(reason: "测试保存")
        
        // 等待500ms后检查
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            #if DEBUG
            print("⏱️ 保存测试完成:")
            #endif
            #if DEBUG
            print("   耗时: \(String(format: "%.3f", duration))秒")
            #endif
            #if DEBUG
            print("   数据一致性: \(viewModel.isDataConsistent ? "✅" : "❌")")
            #endif
        }
    }
    
    /**
     * 测试强制保存
     */
    func testForceSave() {
        #if DEBUG
        print("🧪 测试强制保存...")
        #endif
        
        let viewModel = PostViewModel.shared
        let startTime = Date()
        
        // 触发强制保存
        viewModel.forceSave(reason: "测试强制保存")
        
        // 立即检查
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            #if DEBUG
            print("⚡ 强制保存测试完成:")
            #endif
            #if DEBUG
            print("   耗时: \(String(format: "%.3f", duration))秒")
            #endif
            #if DEBUG
            print("   数据一致性: \(viewModel.isDataConsistent ? "✅" : "❌")")
            #endif
        }
    }
    
    /**
     * 运行完整测试套件
     */
    func runFullTestSuite() {
        #if DEBUG
        print("🚀 开始完整测试套件...")
        #endif
        
        testDataConsistency()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.testCriticalPointSave()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.testForceSave()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            #if DEBUG
            print("✅ 测试套件完成")
            #endif
        }
    }
}

// MARK: - SwiftUI调试视图

/**
 * 数据持久化调试视图
 */
struct DataPersistenceDebugView: View {
    @ObservedObject private var postViewModel = PostViewModel.shared
    @State private var consistencyInfo = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("数据持久化调试")
                .font(.title2)
                .fontWeight(.bold)
            
            // 数据状态显示
            VStack(alignment: .leading, spacing: 8) {
                Text("数据状态")
                    .font(.headline)
                
                Text(consistencyInfo)
                    .font(.system(.caption, design: .monospaced))
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // 测试按钮
            VStack(spacing: 12) {
                Button("测试数据一致性") {
                    DataPersistenceTest.shared.testDataConsistency()
                    updateConsistencyInfo()
                }
                .buttonStyle(.borderedProminent)
                
                Button("测试关键节点保存") {
                    DataPersistenceTest.shared.testCriticalPointSave()
                }
                .buttonStyle(.bordered)
                
                Button("测试强制保存") {
                    DataPersistenceTest.shared.testForceSave()
                }
                .buttonStyle(.bordered)
                
                Button("运行完整测试") {
                    DataPersistenceTest.shared.runFullTestSuite()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            updateConsistencyInfo()
            
            // 定期更新状态信息
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                updateConsistencyInfo()
            }
        }
    }
    
    private func updateConsistencyInfo() {
        consistencyInfo = postViewModel.getDataConsistencyInfo()
    }
}

// MARK: - 预览
struct DataPersistenceDebugView_Previews: PreviewProvider {
    static var previews: some View {
        DataPersistenceDebugView()
    }
} 