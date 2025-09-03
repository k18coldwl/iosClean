//
//  MockAuthRepository.swift
//  camfoloClean
//
//  Created by admin on 2025/1/27.
//

import Foundation

// 导入必要的User模块类型
// 这些类型定义在同一模块的Domain层中

/// Mock认证仓库，用于测试和预览
/// 提供可配置的认证行为，支持各种测试场景
final class MockAuthRepository: @unchecked Sendable, AuthRepository {
    private var currentUserValue: User?
    private var shouldFail = false
    
    // MARK: - Initialization
    
    init(initialUser: User? = nil) {
        self.currentUserValue = initialUser
    }
    
    // MARK: - Configuration
    
    /// 配置Mock行为
    /// - Parameters:
    ///   - shouldFail: 是否模拟失败
    ///   - user: 预设的用户对象
    func configure(shouldFail: Bool = false, user: User? = nil) {
        self.shouldFail = shouldFail
        if let user = user {
            updateUser(user)
        }
    }
    
    // MARK: - AuthRepository Implementation
    
    func signInWithGoogle() async throws -> AuthResult {
        if shouldFail {
            throw AuthError.networkError(error: NSError(domain: "MockError", code: -1))
        }
        
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
        
        let user = User(
            id: "google_123",
            email: "test@gmail.com",
            displayName: "Test User",
            photoURL: nil as URL?,
            provider: AuthProvider.google
        )
        
        updateUser(user)
        return AuthResult(user: user, isNewUser: false)
    }
    
    func signInWithApple() async throws -> AuthResult {
        if shouldFail {
            throw AuthError.networkError(error: NSError(domain: "MockError", code: -1))
        }
        
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
        
        let user = User(
            id: "apple_123",
            email: "test@privaterelay.appleid.com",
            displayName: "Test User",
            photoURL: nil as URL?,
            provider: AuthProvider.apple
        )
        
        updateUser(user)
        return AuthResult(user: user, isNewUser: true)
    }
    
    func signOut() async throws {
        if shouldFail {
            throw AuthError.operationNotAllowed
        }
        updateUser(nil as User?)
    }
    
    func getCurrentUser() async -> User? {
        return currentUserValue
    }
    
    func deleteAccount() async throws {
        if shouldFail {
            throw AuthError.operationNotAllowed
        }
        updateUser(nil as User?)
    }
    
    func linkAccount(with provider: AuthProvider) async throws -> AuthResult {
        throw AuthError.operationNotAllowed
    }
    
    func unlinkAccount(from provider: AuthProvider) async throws -> User {
        throw AuthError.operationNotAllowed
    }
    
    // MARK: - Private Methods
    
    private func updateUser(_ user: User?) {
        currentUserValue = user
    }
}
