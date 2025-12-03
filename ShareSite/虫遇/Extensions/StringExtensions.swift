import Foundation

extension String {
    /// 计算稳定的哈希值，不受应用重启影响
    /// 使用简单的字符累加算法，确保相同字符串始终产生相同结果
    var stableHashValue: Int {
        var hash = 0
        for char in self.utf8 {
            hash = hash &* 31 &+ Int(char)
        }
        return hash
    }
} 