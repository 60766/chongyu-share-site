import Foundation
import SwiftUI

/**
 * 角色置顶管理器
 * 用于管理角色置顶功能，包括保存、加载和管理置顶角色列表
 */
class CharacterPinManager {
    // 单例
    static let shared = CharacterPinManager()
    
    // 置顶角色ID列表
    private(set) var pinnedCharacterIds: [String] = []
    
    // 通知名称
    static let characterPinStatusChanged = Notification.Name("CharacterPinStatusChanged")
    
    // 私有初始化方法
    private init() {
        loadPinnedCharacters()
    }
    
    // 加载置顶角色列表
    func loadPinnedCharacters() {
        if let data = UserDefaults.standard.data(forKey: "PinnedCharacters"),
           let decodedIds = try? JSONDecoder().decode([String].self, from: data) {
            pinnedCharacterIds = decodedIds
    
        }
    }
    
    // 保存置顶角色列表
    private func savePinnedCharacters() {
        if let encoded = try? JSONEncoder().encode(pinnedCharacterIds) {
            UserDefaults.standard.set(encoded, forKey: "PinnedCharacters")
            #if DEBUG
            print("保存了\(pinnedCharacterIds.count)个置顶角色到UserDefaults")
            #endif
        }
    }
    
    // 检查角色是否已置顶
    func isCharacterPinned(_ characterId: String) -> Bool {
        return pinnedCharacterIds.contains(characterId)
    }
    
    // 切换角色的置顶状态
    func togglePinStatus(for characterId: String, characterName: String) {
        if isCharacterPinned(characterId) {
            // 如果已经置顶，则取消置顶
            pinnedCharacterIds.removeAll { $0 == characterId }
            #if DEBUG
            print("取消置顶角色: \(characterName)")
            #endif
        } else {
            // 如果未置顶，则添加到置顶列表
            pinnedCharacterIds.append(characterId)
            #if DEBUG
            print("置顶角色: \(characterName)")
            #endif
        }
        
        // 保存置顶状态
        savePinnedCharacters()
        
        // 发送通知
        NotificationCenter.default.post(
            name: CharacterPinManager.characterPinStatusChanged,
            object: nil,
            userInfo: ["characterId": characterId, "isPinned": isCharacterPinned(characterId)]
        )
    }
    
    // 获取排序后的角色列表（置顶角色在前）
    func getSortedCharacters<T: Identifiable>(characters: [T], idKeyPath: KeyPath<T, String>) -> [T] {
        // 如果没有置顶角色，直接返回原列表
        if pinnedCharacterIds.isEmpty {
            return characters
        }
        
        // 分离置顶角色和非置顶角色
        let pinnedChars = characters.filter { pinnedCharacterIds.contains($0[keyPath: idKeyPath]) }
        let unpinnedChars = characters.filter { !pinnedCharacterIds.contains($0[keyPath: idKeyPath]) }
        
        // 按置顶列表的顺序排序置顶角色
        let sortedPinnedChars = pinnedChars.sorted { char1, char2 in
            let index1 = pinnedCharacterIds.firstIndex(of: char1[keyPath: idKeyPath]) ?? Int.max
            let index2 = pinnedCharacterIds.firstIndex(of: char2[keyPath: idKeyPath]) ?? Int.max
            return index1 < index2
        }
        
        // 合并排序后的列表
        return sortedPinnedChars + unpinnedChars
    }
}

/**
 * 置顶按钮组件
 * 一个可以在任何角色卡片上使用的置顶按钮视图
 */
struct PinButton: View {
    let characterId: String
    let characterName: String
    
    @State private var isPinned: Bool
    
    init(characterId: String, characterName: String) {
        self.characterId = characterId
        self.characterName = characterName
        _isPinned = State(initialValue: CharacterPinManager.shared.isCharacterPinned(characterId))
    }
    
    var body: some View {
        Button(action: {
            CharacterPinManager.shared.togglePinStatus(for: characterId, characterName: characterName)
            isPinned.toggle()
        }) {
            ZStack {
                Circle()
                    .fill(isPinned ? Color.yellow : Color.gray.opacity(0.8))
                    .frame(width: 24, height: 24)
                
                Image(systemName: isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
} 