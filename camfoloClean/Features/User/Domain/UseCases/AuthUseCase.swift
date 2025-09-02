//
//  AuthUseCase.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation

/// 统一的认证用例
/// 将所有简单的认证操作合并到一个UseCase中，减少不必要的抽象层次
/// 保留UseCase层的主要原因：
/// 1. 为未来可能的业务逻辑扩展预留空间（如登录后的数据同步、权限检查等）
/// 2. 保持与Clean Architecture的一致性
/// 3. 便于单元测试时的Mock
protocol AuthUseCaseProtocol: Sendable {
    func signInWithGoogle() async throws -> AuthResult
    func signInWithApple() async throws -> AuthResult
    func signOut() async throws
    func getCurrentUser() async -> User?
    func deleteAccount() async throws
}

final class AuthUseCase: @unchecked Sendable, AuthUseCaseProtocol {
    private let authRepository: AuthRepository
    
    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }
    
    // MARK: - Authentication Methods
    
    /// Google登录
    /// 未来可在此处添加登录后的业务逻辑（如用户数据同步、分析事件等）
    func signInWithGoogle() async throws -> AuthResult {
        return try await authRepository.signInWithGoogle()
    }
    
    /// Apple登录  
    /// 未来可在此处添加登录后的业务逻辑
    func signInWithApple() async throws -> AuthResult {
        return try await authRepository.signInWithApple()
    }
    
    /// 用户登出
    /// 未来可在此处添加登出前的清理逻辑（如清除缓存、停止服务等）
    func signOut() async throws {
        try await authRepository.signOut()
    }
    
    // MARK: - User Management
    
    /// 获取当前用户
    func getCurrentUser() async -> User? {
        return await authRepository.getCurrentUser()
    }
    
    /// 删除账号
    /// 未来可在此处添加账号删除前的数据清理逻辑
    func deleteAccount() async throws {
        try await authRepository.deleteAccount()
    }
}
