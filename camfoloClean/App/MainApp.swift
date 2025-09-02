//
//  MainApp.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI
import SwiftData
import Network

@main
struct camfoloCleanApp: App {
    @StateObject private var appContainer = AppContainer.shared
    
    init() {
        // 在应用启动时请求网络权限
        requestNetworkPermission()
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
            RootView()
                .environmentObject(appContainer)
                .preferredColorScheme(.light) // 可选：设置默认颜色方案
        }
        .modelContainer(sharedModelContainer)
    }
    
    /// 申请网络权限
    private func requestNetworkPermission() {
        // 创建本地网络监视器来触发权限申请
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkPermission")
        
        monitor.pathUpdateHandler = { path in
            print("Network status: \(path.status)")
            if path.status == .satisfied {
                print("Network connection available")
                // 进行一次实际的网络请求来触发权限申请
                Task {
                    await self.triggerNetworkPermissionRequest()
                }
            }
            monitor.cancel()
        }
        
        monitor.start(queue: queue)
        
        // 3秒后自动停止监视器
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            monitor.cancel()
        }
    }
    
    /// 触发网络权限申请
    private func triggerNetworkPermissionRequest() async {
        // 尝试连接到Firebase来触发网络权限申请
        do {
            let url = URL(string: "https://www.qq.com")!
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                print("Network test successful: \(httpResponse.statusCode)")
            }
        } catch {
            print("Network test failed (expected for permission trigger): \(error)")
        }
    }
}
