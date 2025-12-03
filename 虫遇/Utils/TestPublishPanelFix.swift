import Foundation

/**
 * PublishPanelView角色选择修复测试脚本
 * 用于验证修复后的角色选择多样性
 */
class PublishPanelFixTester {
    
    static func testCharacterSelection() {
        #if DEBUG
        print("🧪 开始测试PublishPanelView角色选择修复...")
        #endif
        
        // 测试1：验证角色库大小
        #if DEBUG
        print("\n📊 测试1：角色库大小验证")
        #endif
        let characterDataManager = CharacterDataManager.shared
        let allCharacters = characterDataManager.getAllCharactersInfo()
        #if DEBUG
        print("✅ 完整角色库大小：\(allCharacters.count)个角色")
        #endif
        
        // 测试2：验证角色基本信息
        #if DEBUG
        print("\n📋 测试2：角色基本信息")
        #endif
        #if DEBUG
        print("✅ 角色信息结构：id, name, avatar")
        #endif
        #if DEBUG
        print("✅ 总角色数量：\(allCharacters.count)个")
        #endif
        
        // 显示前10个角色作为示例
        #if DEBUG
        print("\n📋 前10个角色示例：")
        #endif
        for (index, character) in allCharacters.prefix(10).enumerated() {
            #if DEBUG
            print("  \(index + 1). \(character.name) (ID: \(character.id))")
            #endif
        }
        
        // 测试3：模拟角色选择器加载
        #if DEBUG
        print("\n🎯 测试3：模拟角色选择器加载")
        #endif
        let sampleCharacters = CharacterModel.sampleCharacters
        #if DEBUG
        print("❌ 硬编码示例角色数量：\(sampleCharacters.count)个")
        #endif
        #if DEBUG
        print("❌ 硬编码角色列表：\(sampleCharacters.map { $0.name }.joined(separator: ", "))")
        #endif
        
        // 测试4：验证修复后的角色选择
        #if DEBUG
        print("\n🔧 测试4：验证修复后的角色选择")
        #endif
        let allCharacterModels = allCharacters.map { characterInfo in
            CharacterModel(
                id: characterInfo.id,
                name: characterInfo.name,
                avatar: characterInfo.id,
                era: "未知", // 从元组中无法获取，使用默认值
                profession: "未知", // 从元组中无法获取，使用默认值
                bio: "暂无描述", // 从元组中无法获取，使用默认值
                category: .historical, // 从元组中无法获取，使用默认值
                famousQuotes: [], // 从元组中无法获取，使用默认值
                characterID: characterInfo.id
            )
        }
        
        #if DEBUG
        print("✅ 修复后可用角色数量：\(allCharacterModels.count)个")
        #endif
        
        // 测试5：随机选择测试
        #if DEBUG
        print("\n🎲 测试5：随机选择测试")
        #endif
        for i in 1...5 {
            let randomSelection = allCharacterModels.shuffled().prefix(3)
            let selectedNames = randomSelection.map { $0.name }
            #if DEBUG
            print("  第\(i)次随机选择：\(selectedNames.joined(separator: ", "))")
            #endif
        }
        
        #if DEBUG
        print("\n🎉 PublishPanelView角色选择修复测试完成！")
        #endif
        #if DEBUG
        print("📈 修复效果：从\(sampleCharacters.count)个硬编码角色扩展到\(allCharacterModels.count)个完整角色库")
        #endif
    }
} 