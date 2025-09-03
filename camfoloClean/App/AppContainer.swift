//
//  AppContainer.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import FirebaseCore

final class AppContainer: ObservableObject, @unchecked Sendable {
    @MainActor
    static let shared = AppContainer()
    
    let diContainer: DIContainer
    
    private init() {
        self.diContainer = DefaultDIContainer()
        configureFirebase()
        
        // 异步初始化系统权限
        Task {
            await initializeSystemPermissions()
        }
    }
    
    private func configureFirebase() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // 注意：Analytics数据收集已在Info.plist中通过FIREBASE_ANALYTICS_COLLECTION_ENABLED=false禁用
        // 这应该能消除"Data Collection flag is not set"的控制台警告
    }
    
    /// 初始化系统权限
    /// 使用PermissionService统一管理应用启动时需要的权限申请
    private func initializeSystemPermissions() async {
        await diContainer.permissionService.initializeSystemPermissions()
    }
}
