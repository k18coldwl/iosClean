//
//  AuthUtils.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import UIKit
import os.log

/// 认证工具类
/// 提供认证相关的公共方法和常量
struct AuthUtils {
    
    // MARK: - Constants
    
    /// 超时配置
    enum TimeoutConfig {
        /// 网络请求超时时间（秒）- 用于纯网络操作
        static let networkTimeout: TimeInterval = 30.0
        
        /// 用户交互超时时间（秒）- 用于需要用户在第三方UI上操作的场景
        static let userInteractionTimeout: TimeInterval = 120.0
        
        /// 默认认证超时时间（秒）- 平衡用户体验和系统稳定性
        static let defaultAuthTimeout: TimeInterval = 90.0
    }
    
    /// 提供商ID常量
    enum ProviderID {
        static let apple = "apple.com"
        static let google = "google.com"
    }
    
    // MARK: - Logging
    
    /// 创建认证服务专用的日志记录器
    /// - Parameter category: 日志分类名称
    /// - Returns: 配置好的Logger实例
    static func createLogger(for category: String) -> Logger {
        return Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "camfoloClean",
            category: "Auth.\(category)"
        )
    }
    
    // MARK: - Timeout Helper
    
    /// 为异步操作添加超时机制
    /// - Parameters:
    ///   - timeout: 超时时间（秒）
    ///   - operation: 要执行的异步操作
    /// - Returns: 操作结果
    /// - Throws: AuthError.networkError 如果超时
    static func withTimeout<T: Sendable>(
        _ timeout: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            // 添加主要操作任务
            group.addTask {
                try await operation()
            }
            
            // 添加超时任务
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw AuthError.networkError(
                    error: NSError(
                        domain: "AuthTimeout",
                        code: -1001,
                        userInfo: [NSLocalizedDescriptionKey: "Authentication timeout after \(timeout) seconds"]
                    )
                )
            }
            
            // 返回第一个完成的任务结果，并取消其他任务
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    /// 为用户交互认证操作添加超时机制（更长的超时时间）
    /// 适用于需要用户在第三方UI上进行操作的场景，如Apple Sign-In、Google Sign-In
    /// - Parameter operation: 要执行的异步操作
    /// - Returns: 操作结果
    /// - Throws: AuthError.networkError 如果超时
    static func withUserInteractionTimeout<T: Sendable>(
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        return try await withTimeout(TimeoutConfig.userInteractionTimeout, operation: operation)
    }
    
    /// 为网络操作添加超时机制（较短的超时时间）
    /// 适用于纯网络请求，如token验证、用户信息获取等
    /// - Parameter operation: 要执行的异步操作
    /// - Returns: 操作结果
    /// - Throws: AuthError.networkError 如果超时
    static func withNetworkTimeout<T: Sendable>(
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        return try await withTimeout(TimeoutConfig.networkTimeout, operation: operation)
    }
    
    /// 智能超时机制 - 根据应用状态动态调整超时时间
    /// 当应用在后台时，延长超时时间；当应用在前台时，使用标准超时时间
    /// - Parameter operation: 要执行的异步操作
    /// - Returns: 操作结果
    /// - Throws: AuthError.networkError 如果超时
    @MainActor
    static func withAdaptiveTimeout<T: Sendable>(
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        // 检查应用状态来决定超时时间
        let isAppActive = UIApplication.shared.applicationState == .active
        let timeout = isAppActive ? TimeoutConfig.userInteractionTimeout : TimeoutConfig.userInteractionTimeout * 1.5
        
        return try await withTimeout(timeout, operation: operation)
    }
    
    /// 可取消的用户交互超时机制
    /// 提供更友好的用户体验，允许在超时前给用户提示
    /// - Parameters:
    ///   - warningTime: 警告时间（秒），在此时间后显示警告
    ///   - operation: 要执行的异步操作
    ///   - onWarning: 警告回调，可用于显示用户提示
    /// - Returns: 操作结果
    /// - Throws: AuthError.networkError 如果超时
    static func withCancellableTimeout<T: Sendable>(
        warningTime: TimeInterval = 60.0,
        operation: @escaping @Sendable () async throws -> T,
        onWarning: (@Sendable () -> Void)? = nil
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            // 添加主要操作任务
            group.addTask {
                try await operation()
            }
            
            // 添加警告任务
            if let onWarning = onWarning {
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(warningTime * 1_000_000_000))
                    onWarning()
                    // 继续等待直到用户交互超时
                    try await Task.sleep(nanoseconds: UInt64((TimeoutConfig.userInteractionTimeout - warningTime) * 1_000_000_000))
                    throw AuthError.networkError(
                        error: NSError(
                            domain: "AuthTimeout",
                            code: -1001,
                            userInfo: [NSLocalizedDescriptionKey: "Authentication timeout after \(TimeoutConfig.userInteractionTimeout) seconds"]
                        )
                    )
                }
            } else {
                // 如果没有警告回调，直接使用标准超时
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(TimeoutConfig.userInteractionTimeout * 1_000_000_000))
                    throw AuthError.networkError(
                        error: NSError(
                            domain: "AuthTimeout",
                            code: -1001,
                            userInfo: [NSLocalizedDescriptionKey: "Authentication timeout after \(TimeoutConfig.userInteractionTimeout) seconds"]
                        )
                    )
                }
            }
            
            // 返回第一个完成的任务结果
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - Error Handling
    
    /// 创建配置错误
    /// - Parameter message: 错误消息
    /// - Returns: AuthError实例
    static func createConfigurationError(_ message: String) -> AuthError {
        return .unknown("配置错误: \(message)")
    }
    
    /// 创建网络错误
    /// - Parameter underlyingError: 底层错误
    /// - Returns: AuthError实例
    static func createNetworkError(_ underlyingError: Error) -> AuthError {
        return .networkError(error: underlyingError)
    }
    
    /// 统一的认证错误日志记录
    /// - Parameters:
    ///   - logger: 日志记录器
    ///   - error: 错误信息
    ///   - context: 上下文信息
    static func logAuthError(_ logger: Logger, error: Error, context: String) {
        logger.error("\(context) failed: \(error.localizedDescription)")
        
        // 为调试提供更详细的错误信息
        if let nsError = error as NSError? {
            logger.debug("Error domain: \(nsError.domain), code: \(nsError.code)")
        }
    }
    
    /// 验证必要的认证组件是否可用
    /// - Parameter logger: 日志记录器
    /// - Throws: AuthError 如果组件不可用
    @MainActor
    static func validatePresentationContext(_ logger: Logger) throws {
        guard UIWindow.cam?.topViewController != nil else {
            logger.error("No presenting view controller available")
            throw createConfigurationError("无法获取当前视图控制器，请确保应用已正确初始化")
        }
    }
}
