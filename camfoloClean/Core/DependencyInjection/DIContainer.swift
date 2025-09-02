//
//  DIContainer.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation

protocol DIContainer: Sendable {
    // Auth Dependencies
    var authRepository: AuthRepository { get }
    var authUseCase: AuthUseCaseProtocol { get }
    
    // ViewModels
    @MainActor
    func makeAuthViewModel() -> AuthViewModel
}

final class DefaultDIContainer: @unchecked Sendable, DIContainer {
    
    // MARK: - Services
    private lazy var appleSignInService: AuthProviderService = {
        AppleSignInService()
    }()
    
    private lazy var googleSignInService: AuthProviderService = {
        GoogleSignInService()
    }()
    
    // MARK: - Repositories
    lazy var authRepository: AuthRepository = {
        AuthRepositoryImpl(
            appleSignInService: appleSignInService,
            googleSignInService: googleSignInService
        )
    }()
    
    // MARK: - Use Cases
    lazy var authUseCase: AuthUseCaseProtocol = {
        AuthUseCase(authRepository: authRepository)
    }()
    
    // MARK: - ViewModels
    @MainActor
    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(authUseCase: authUseCase)
    }
}

