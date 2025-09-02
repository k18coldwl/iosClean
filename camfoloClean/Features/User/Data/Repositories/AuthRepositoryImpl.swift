//
//  AuthRepositoryImpl.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
@preconcurrency import FirebaseAuth

/// Firebase实现的用户认证仓库
/// 负责与Firebase Auth服务进行交互，实现用户认证相关的所有操作
/// 通过依赖注入使用第三方认证服务，符合依赖倒置原则
final class AuthRepositoryImpl: @unchecked Sendable, AuthRepository {
    
    // MARK: - Private Properties
    private let auth = Auth.auth()
    private let appleSignInService: AuthProviderService
    private let googleSignInService: AuthProviderService
    
    // MARK: - Initialization
    
    /// 初始化认证仓库
    /// - Parameters:
    ///   - appleSignInService: Apple登录服务
    ///   - googleSignInService: Google登录服务
    init(
        appleSignInService: AuthProviderService,
        googleSignInService: AuthProviderService
    ) {
        self.appleSignInService = appleSignInService
        self.googleSignInService = googleSignInService
    }
    
    // MARK: - Authentication Methods
    
    /// 使用Google账号登录
    func signInWithGoogle() async throws -> AuthResult {
        let thirdPartyCredential = try await googleSignInService.getCredential()
        let firebaseCredential = createFirebaseCredential(from: thirdPartyCredential)
        let authDataResult = try await auth.signIn(with: firebaseCredential)
        return UserMapper.mapFromAuthResult(authDataResult)
    }
    
    /// 使用Apple账号登录
    func signInWithApple() async throws -> AuthResult {
        let thirdPartyCredential = try await appleSignInService.getCredential()
        let firebaseCredential = createFirebaseCredential(from: thirdPartyCredential)
        let authDataResult = try await auth.signIn(with: firebaseCredential)
        return UserMapper.mapFromAuthResult(authDataResult)
    }
    
    /// 用户登出
    func signOut() async throws {
        try auth.signOut()
    }
    
    // MARK: - User Management
    
    /// 获取当前用户
    func getCurrentUser() async -> User? {
        guard let firebaseUser = auth.currentUser else {
            return nil
        }
        return UserMapper.mapFromFirebaseUser(firebaseUser)
    }
    
    /// 删除用户账号
    func deleteAccount() async throws {
        guard let user = auth.currentUser else {
            throw AuthError.userNotFound
        }
        try await user.delete()
    }
    
    /// 关联账号到其他提供商
    func linkAccount(with provider: AuthProvider) async throws -> AuthResult {
        // Implementation depends on the specific provider
        throw AuthError.operationNotAllowed
    }
    
    /// 取消关联账号
    func unlinkAccount(from provider: AuthProvider) async throws -> User {
        // Implementation depends on the specific provider and current user state
        throw AuthError.operationNotAllowed
    }
    
    // MARK: - Private Methods
    
    /// 根据第三方认证凭证创建Firebase认证凭证
    /// - Parameter credential: 第三方认证凭证
    /// - Returns: Firebase认证凭证
    private func createFirebaseCredential(from credential: ThirdPartyCredential) -> AuthCredential {
        switch credential.providerID {
        case AuthUtils.ProviderID.google:
            return GoogleAuthProvider.credential(
                withIDToken: credential.idToken,
                accessToken: credential.accessToken ?? ""
            )
        case AuthUtils.ProviderID.apple:
            return OAuthProvider.credential(
                providerID: .apple,
                idToken: credential.idToken,
                rawNonce: credential.rawNonce ?? ""
            )
        default:
            fatalError("Unsupported provider: \(credential.providerID)")
        }
    }
}
