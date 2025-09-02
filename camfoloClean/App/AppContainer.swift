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
    }
    
    private func configureFirebase() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // 注意：Analytics数据收集已在Info.plist中通过FIREBASE_ANALYTICS_COLLECTION_ENABLED=false禁用
        // 这应该能消除"Data Collection flag is not set"的控制台警告
    }
}
