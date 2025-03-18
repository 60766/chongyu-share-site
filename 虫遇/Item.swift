//
//  Item.swift
//  虫遇
//
//  Created by 李世龙 on 2025/3/18.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
