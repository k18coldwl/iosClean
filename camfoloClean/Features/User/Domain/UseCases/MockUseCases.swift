//
//  MockUseCases.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation

// MARK: - Mock Repository for Testing and Previews
final class MockAuthRepository: @unchecked Sendable, AuthRepository {
    private var currentUserValue: User?
    
    init(initialUser: User? = nil) {
        self.currentUserValue = initialUser
    }
    
    private func updateUser(_ user: User?) {
        currentUserValue = user
    }
    
    func signInWithGoogle() async throws -> AuthResult {
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
        
        let user = User(
            id: "google_123",
            email: "test@gmail.com",
            displayName: "Test User",
            photoURL: nil,
            provider: .google
        )
        
        updateUser(user)
        return AuthResult(user: user, isNewUser: false)
    }
    
    func signInWithApple() async throws -> AuthResult {
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
        
        let user = User(
            id: "apple_123",
            email: "test@privaterelay.appleid.com",
            displayName: "Test User",
            photoURL: nil,
            provider: .apple
        )
        
        updateUser(user)
        return AuthResult(user: user, isNewUser: true)
    }
    
    func signOut() async throws {
        updateUser(nil)
    }
    
    func getCurrentUser() async -> User? {
        return currentUserValue
    }
    
    func deleteAccount() async throws {
        updateUser(nil)
    }
    
    func linkAccount(with provider: AuthProvider) async throws -> AuthResult {
        throw AuthError.operationNotAllowed
    }
    
    func unlinkAccount(from provider: AuthProvider) async throws -> User {
        throw AuthError.operationNotAllowed
    }
}

// MARK: - Mock DI Container for Testing
final class MockDIContainer: @unchecked Sendable, DIContainer {
    private let mockAuthRepository = MockAuthRepository()
    
    var authRepository: AuthRepository {
        mockAuthRepository
    }
    
    lazy var authUseCase: AuthUseCaseProtocol = {
        AuthUseCase(authRepository: authRepository)
    }()
    
    @MainActor
    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(authUseCase: authUseCase)
    }
}
