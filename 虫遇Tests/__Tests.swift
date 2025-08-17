//
//  __Tests.swift
//  虫遇Tests
//
//  Created by 李世龙 on 2025/3/18.
//

import Testing
@testable import 虫遇

struct 虫遇Tests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func testNotificationServiceExists() async throws {
        // 测试 NotificationService 能够正常初始化
        let service = NotificationService.shared
        #expect(service != nil)
        print("✅ NotificationService 初始化成功")
    }

}
