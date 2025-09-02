//
//  GoogleSignInService.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
@preconcurrency import GoogleSignIn
import FirebaseCore
import UIKit
import os.log

/// Google登录服务
/// 负责处理Google Sign-In的具体实现逻辑，只获取Google凭证，不直接进行Firebase认证
/// 使用iOS 17现代异步编程模式，简化代码结构
/// 
/// 特性：
/// - 支持超时机制，避免无限等待
/// - 统一的日志记录和错误处理
/// - 线程安全的实现
/// - 详细的错误映射和调试信息
final class GoogleSignInService: @unchecked Sendable, AuthProviderService {
    
    // MARK: - Properties
    
    /// 统一日志记录器
    private static let logger = AuthUtils.createLogger(for: "GoogleSignIn")
    
    // MARK: - AuthProviderService Implementation
    
    /// 获取Google认证凭证
    /// 
    /// 使用120秒的用户交互超时时间，考虑以下场景：
    /// - 用户需要时间阅读权限说明
    /// - 可能需要输入密码或进行双重验证
    /// - 网络延迟导致的响应延迟
    /// - 用户可能临时切换到其他应用
    /// 
    /// - Returns: Google第三方认证凭证
    /// - Throws: AuthError
    func getCredential() async throws -> ThirdPartyCredential {
        Self.logger.info("Starting Google Sign-In authorization request")
        
        // 验证配置
        try Self.validateConfiguration()
        
        // 获取Firebase客户端ID
        let clientID = FirebaseApp.app()!.options.clientID!
        
        // 在主线程执行整个Google登录流程，避免跨线程传递非Sendable类型
        // 使用用户交互超时，给用户更多时间在第三方UI上操作
        return try await AuthUtils.withUserInteractionTimeout {
            try await Task { @MainActor in
            // 验证展示上下文
            try AuthUtils.validatePresentationContext(Self.logger)
            let presentingViewController = UIWindow.cam!.topViewController!
            
            // 配置Google Sign In
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            
            // 执行Google登录
            let result: GIDSignInResult
            do {
                result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            } catch let gidError as GIDSignInError {
                // 处理Google特定的错误
                AuthUtils.logAuthError(Self.logger, error: gidError, context: "Google Sign-In")
                throw Self.mapGoogleSignInError(gidError)
            } catch {
                // 处理其他错误
                AuthUtils.logAuthError(Self.logger, error: error, context: "Google Sign-In unexpected")
                throw AuthError.unknown("Google登录失败: \(error.localizedDescription)")
            }
            
            // 验证并获取必要的token
            guard let idToken = result.user.idToken?.tokenString else {
                Self.logger.error("Missing ID token in Google credential")
                throw AuthError.invalidCredential
            }
            
            Self.logger.info("Successfully obtained Google credentials")
            
            // 返回第三方认证凭证
            return ThirdPartyCredential(
                providerID: AuthUtils.ProviderID.google,
                idToken: idToken,
                accessToken: result.user.accessToken.tokenString,
                rawNonce: nil
            )
            }.value
        }
    }
    
    // MARK: - Private Methods
    
    /// 验证Google Sign-In配置
    /// - Throws: AuthError 如果配置无效
    private static func validateConfiguration() throws {
        guard FirebaseApp.app() != nil else {
            Self.logger.error("Firebase not configured")
            throw AuthUtils.createConfigurationError("Firebase未正确配置")
        }
        
        guard FirebaseApp.app()?.options.clientID != nil else {
            Self.logger.error("Firebase client ID not found")
            throw AuthUtils.createConfigurationError("Firebase client ID未配置")
        }
    }
    
    /// 映射Google登录错误到AuthError
    /// - Parameter error: Google登录错误
    /// - Returns: 映射后的AuthError
    private static func mapGoogleSignInError(_ error: GIDSignInError) -> AuthError {
        Self.logger.debug("Mapping Google Sign-In error: \(error.code.rawValue)")
        
        switch error.code {
        case .canceled:
            return .cancelled
        case .EMM:
            return .operationNotAllowed
        case .keychain:
            return AuthUtils.createConfigurationError("Keychain访问错误，请检查应用权限设置")
        case .hasNoAuthInKeychain:
            return .userNotFound
        case .scopesAlreadyGranted:
            return .operationNotAllowed
        case .mismatchWithCurrentUser:
            return .invalidCredential
        case .unknown:
            return .unknown("Google登录服务暂时不可用，请稍后重试")
        @unknown default:
            return .unknown("Google登录错误: \(error.localizedDescription)")
        }
    }
}
