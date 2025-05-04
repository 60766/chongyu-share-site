//
//  __App.swift
//  虫遇
//
//  Created by 李世龙 on 2025/3/18.
//

import SwiftUI
import SwiftData
import UIKit

// AppDelegate已经存在，不再重复声明

@main
struct ChongYuApp: App {
    // 添加AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Character.self,
            User.self,
            Message.self,
            Conversation.self,
            Post.self,
            Comment.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("无法创建ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppTabView()
                .environmentObject(CreationTypeManager.shared)
        }
        .modelContainer(sharedModelContainer)
    }
}
