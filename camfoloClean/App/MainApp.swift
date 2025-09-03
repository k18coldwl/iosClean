//
//  MainApp.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI
import SwiftData

@main
struct camfoloCleanApp: App {
    @StateObject private var appContainer = AppContainer.shared
    
    // 应用级AuthViewModel - 使用@State管理@Observable ViewModel
    @State private var authViewModel = AppContainer.shared.diContainer.makeAuthViewModel()
    
    init() {
        // 应用启动配置已移至AppContainer
        // 权限管理现在通过PermissionService统一处理
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Add your data models here when needed
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView(authViewModel: authViewModel)
                .environmentObject(appContainer)
                .preferredColorScheme(.light) // 可选：设置默认颜色方案
        }
        .modelContainer(sharedModelContainer)
    }
}
