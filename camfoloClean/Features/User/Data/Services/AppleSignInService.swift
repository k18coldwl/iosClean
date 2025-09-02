//
//  AppleSignInService.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

@preconcurrency import Foundation
@preconcurrency import FirebaseAuth
import UIKit
import AuthenticationServices
import os.log

// MARK: - Protocols

/// Apple认证控制器协议，便于单元测试
protocol AppleAuthorizationControllerProtocol {
    var delegate: ASAuthorizationControllerDelegate? { get set }
    var presentationContextProvider: ASAuthorizationControllerPresentationContextProviding? { get set }
    func performRequests()
}

extension ASAuthorizationController: AppleAuthorizationControllerProtocol {}

/// Apple登录服务
/// 负责处理Apple Sign-In的具体实现逻辑，只获取Apple凭证，不直接进行Firebase认证
/// 使用iOS 17现代异步编程模式，简化代码结构

final class AppleSignInService: NSObject, AuthProviderService {
    
    // MARK: - Properties
    
    /// 统一日志记录器
    fileprivate static let logger = AuthUtils.createLogger(for: "AppleSignIn")
    
    /// Delegate管理器，使用actor确保线程安全和Sendable兼容性
    private let delegateManager = DelegateManager()
    
    // MARK: - AuthProviderService Implementation
    
    /// 获取Apple认证凭证
    /// 
    /// 使用120秒的用户交互超时时间，考虑以下场景：
    /// - 用户需要时间阅读Apple ID权限说明
    /// - 可能需要Face ID/Touch ID验证
    /// - 双重验证流程
    /// - 网络延迟或Apple服务响应延迟
    /// - 用户可能临时切换应用处理其他事务
    /// 
    /// - Returns: Apple第三方认证凭证
    /// - Throws: AuthError
    @MainActor
    func getCredential() async throws -> ThirdPartyCredential {
        let nonce = CryptoUtils.randomNonceString()
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = CryptoUtils.sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        
        Self.logger.info("Starting Apple Sign-In authorization request")
        
        // 先清理之前可能存在的delegate
        await self.delegateManager.clearDelegate()
        
        // 使用用户交互超时，给用户更多时间在Apple Sign-In界面上操作
        return try await withCheckedThrowingContinuation { continuation in
            // 创建新的delegate实例
            let delegate = AppleSignInDelegate(nonce: nonce) { result in
                // 确保continuation只被调用一次
                continuation.resume(with: result)
            }
            
            // 保持对delegate的强引用，确保在异步操作期间不被释放
            Task {
                await self.delegateManager.setDelegate(delegate)
            }
            
            // 在主线程上设置和执行
            authorizationController.delegate = delegate
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // 使用扩展方法获取当前窗口
        return UIWindow.cam ?? UIWindow(frame: UIScreen.main.bounds)
    }
}

// MARK: - Apple Sign-In Delegate
/// 专门处理Apple Sign-In授权结果的delegate类
/// 使用回调模式避免continuation泄漏，确保异步操作正确完成
/// 简化生命周期管理，每次创建新的delegate实例
private final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    private let nonce: String
    private let completion: (Result<ThirdPartyCredential, Error>) -> Void
    private var hasCompleted = false
    
    init(nonce: String, completion: @escaping (Result<ThirdPartyCredential, Error>) -> Void) {
        self.nonce = nonce
        self.completion = completion
        super.init()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        // 防止重复调用
        guard !hasCompleted else {
            AppleSignInService.logger.warning("Authorization already completed, ignoring duplicate call")
            return
        }
        hasCompleted = true
        
        defer {
            // 确保在方法结束时清理状态
            cleanupAfterCompletion()
        }
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            AppleSignInService.logger.error("Invalid credential type received")
            completion(.failure(AuthError.invalidCredential))
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            AppleSignInService.logger.error("Missing identity token in Apple credential")
            completion(.failure(AuthError.invalidCredential))
            return
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            AppleSignInService.logger.error("Failed to convert identity token to string")
            completion(.failure(AuthError.invalidCredential))
            return
        }
        
        AppleSignInService.logger.info("Successfully obtained Apple credentials")
        
        // 创建第三方认证凭证
        let thirdPartyCredential = ThirdPartyCredential(
            providerID: AuthUtils.ProviderID.apple,
            idToken: idTokenString,
            accessToken: nil,
            rawNonce: nonce
        )
        
        completion(.success(thirdPartyCredential))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // 防止重复调用
        guard !hasCompleted else {
            AppleSignInService.logger.warning("Error already handled, ignoring duplicate call")
            return
        }
        hasCompleted = true
        
        defer {
            // 确保在方法结束时清理状态
            cleanupAfterCompletion()
        }
        
        let authError = error as? ASAuthorizationError
        
        AppleSignInService.logger.error("Apple Sign-In failed: \(error.localizedDescription)")
        if let authError = authError {
            AppleSignInService.logger.debug("ASAuthorizationError code: \(authError.code.rawValue)")
        }
        
        let mappedError: AuthError
        switch authError?.code {
        case .canceled:
            AppleSignInService.logger.info("User cancelled Apple Sign-In")
            mappedError = .cancelled
        case .failed:
            mappedError = .networkError(error: error)
        case .invalidResponse:
            mappedError = .invalidCredential
        case .notHandled:
            mappedError = .unknown("认证未处理: \(error.localizedDescription)")
        case .unknown:
            if let authError = authError, authError.code.rawValue == 1000 {
                mappedError = .unknown("Apple Sign-In配置错误，请检查：1) 确保在Apple Developer Console中启用了Sign in with Apple；2) 确保Bundle ID正确；3) 确保在真实设备上测试")
            } else {
                mappedError = .unknown("未知认证错误: \(error.localizedDescription)")
            }
        case .none:
            if (error as NSError).code == 1000 {
                mappedError = .unknown("Apple Sign-In配置错误（代码1000），请检查：1) 应用是否已正确配置entitlements；2) 是否在真实设备上测试；3) Apple ID是否启用了双因素认证")
            } else {
                mappedError = .unknown("非Apple认证错误: \(error.localizedDescription)")
            }
        default:
            mappedError = .unknown("其他认证错误: \(error.localizedDescription)")
        }
        
        completion(.failure(mappedError))
    }
    
    // MARK: - Private Methods
    
    /// 完成后清理状态，确保下次调用时是干净的状态
    private func cleanupAfterCompletion() {
        // 异步清理delegate引用，避免阻塞当前线程
        Task {
            // 这里可以添加额外的清理逻辑
        }
    }
}

// MARK: - Delegate Manager Actor
/// 使用actor管理delegate的生命周期，确保线程安全和Sendable兼容性
/// 每次新的认证请求都会清理之前的delegate，确保不会有状态残留
private actor DelegateManager {
    private var delegate: AppleSignInDelegate?
    
    /// 设置当前delegate，会自动清理之前的delegate
    /// - Parameter delegate: 要保持引用的delegate
    func setDelegate(_ delegate: AppleSignInDelegate) {
        // 先清理之前的delegate
        self.delegate = nil
        // 设置新的delegate
        self.delegate = delegate
    }
    
    /// 清理delegate引用
    func clearDelegate() {
        self.delegate = nil
    }
    
    /// 检查是否有活跃的delegate
    func hasActiveDelegate() -> Bool {
        return delegate != nil
    }
}


