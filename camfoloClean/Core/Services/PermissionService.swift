//
//  PermissionService.swift
//  camfoloClean
//
//  Created by admin on 2025/1/27.
//

import Foundation
import Network
import os.log

/// 应用权限管理服务
/// 负责统一处理应用启动时需要的各种权限申请
/// 包括网络权限、本地网络权限等系统级权限
protocol PermissionServiceProtocol: Sendable {
    /// 请求网络权限
    /// 通过网络监控和实际网络请求来触发iOS系统的网络权限申请
    func requestNetworkPermission() async
    
    /// 初始化所有必要的系统权限
    /// 在应用启动时调用，确保所有必要的权限都被正确申请
    func initializeSystemPermissions() async
}

/// 权限管理服务的具体实现
final class PermissionService: @unchecked Sendable, PermissionServiceProtocol {
    
    // MARK: - Properties
    
    /// 统一日志记录器
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "camfoloClean",
        category: "Core.PermissionService"
    )
    
    // MARK: - Public Methods
    
    /// 初始化所有系统权限
    /// 在应用启动时调用，确保Firebase和其他网络服务能正常工作
    func initializeSystemPermissions() async {
        Self.logger.info("开始初始化系统权限")
        
        // 请求网络权限（用于Firebase等服务）
        await requestNetworkPermission()
        
        Self.logger.info("系统权限初始化完成")
    }
    
    /// 请求网络权限
    /// 通过实际的网络请求来触发iOS的网络权限申请
    func requestNetworkPermission() async {
        Self.logger.info("开始请求网络权限")
        
        // 直接进行网络请求来触发权限申请
        await triggerNetworkPermissionRequest()
        
        Self.logger.info("网络权限申请完成")
    }
    
    // MARK: - Private Methods
    
    /// 触发网络权限申请
    /// 通过实际的网络请求来确保系统权限对话框被触发
    private func triggerNetworkPermissionRequest() async {
        Self.logger.info("执行网络权限触发请求")
        
        do {
            // 使用可靠的测试URL
            let url = URL(string: "https://www.apple.com")!
            let request = URLRequest(url: url, timeoutInterval: 10)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                Self.logger.info("网络权限测试成功: HTTP \(httpResponse.statusCode)")
            }
        } catch {
            // 权限申请过程中的网络错误是预期的，不需要特殊处理
            Self.logger.info("网络权限测试完成（可能触发了权限申请）: \(error.localizedDescription)")
        }
    }
}

// MARK: - Mock Implementation

/// Mock权限服务，用于测试和Preview
final class MockPermissionService: @unchecked Sendable, PermissionServiceProtocol {
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "camfoloClean",
        category: "Core.MockPermissionService"
    )
    
    func initializeSystemPermissions() async {
        Self.logger.info("Mock: 系统权限初始化完成")
        // Mock实现：立即返回，不进行实际的权限申请
    }
    
    func requestNetworkPermission() async {
        Self.logger.info("Mock: 网络权限申请完成")
        // Mock实现：模拟短暂延迟后完成
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
    }
}
