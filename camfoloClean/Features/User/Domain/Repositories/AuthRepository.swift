//
//  AuthRepository.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation

protocol AuthRepository: Sendable {
    // Authentication methods
    func signInWithGoogle() async throws -> AuthResult
    func signInWithApple() async throws -> AuthResult
    func signOut() async throws
    
    // User management
    func getCurrentUser() async -> User?
    func deleteAccount() async throws
    func linkAccount(with provider: AuthProvider) async throws -> AuthResult
    func unlinkAccount(from provider: AuthProvider) async throws -> User
}