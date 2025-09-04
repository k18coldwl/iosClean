//
//  DIContainer.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation

protocol DIContainer: Sendable {
    // Core Services
    var permissionService: PermissionServiceProtocol { get }
    
    // Auth Dependencies
    var authRepository: AuthRepository { get }
    var authUseCase: AuthUseCaseProtocol { get }
    
    // Template Dependencies
    var templateUseCase: TemplateUseCaseProtocol { get }
    
    // 🚀 High-Performance Managers (单一职责)
    @MainActor
    var cameraManager: CameraManager { get }
    
    @MainActor
    var photosManager: PhotosManager { get }
    
    // ViewModels
    @MainActor
    func makeAuthViewModel() -> AuthViewModel
    
    // 🔥 Ultra High-Performance Camera View (零抽象开销)
    @MainActor
    func makeHighPerformanceCameraView() -> CameraView
}

final class DefaultDIContainer: @unchecked Sendable, DIContainer {
    
    // MARK: - Core Services
    lazy var permissionService: PermissionServiceProtocol = {
        PermissionService()
    }()
    
    // MARK: - Auth Services
    private lazy var appleSignInService: AuthProviderService = {
        AppleSignInService()
    }()
    
    private lazy var googleSignInService: AuthProviderService = {
        GoogleSignInService()
    }()
    
    // MARK: - Repositories
    lazy var authRepository: AuthRepository = {
        return AuthRepositoryImpl(
            appleSignInService: appleSignInService,
            googleSignInService: googleSignInService
        )
    }()
    
    // MARK: - Use Cases
    lazy var authUseCase: AuthUseCaseProtocol = {
        AuthUseCase(authRepository: authRepository)
    }()
    
    lazy var templateUseCase: TemplateUseCaseProtocol = {
        TemplateUseCase(templateRepository: MockTemplateRepository())
    }()
    
    // MARK: - 🚀 High-Performance Managers (单一职责)
    
    @MainActor
    lazy var cameraManager: CameraManager = {
        CameraManager()
    }()
    
    @MainActor
    lazy var photosManager: PhotosManager = {
        PhotosManager()
    }()
    
    // MARK: - ViewModels
    @MainActor
    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(authUseCase: authUseCase)
    }
    
    // MARK: - 🔥 Ultra High-Performance Camera Views
    @MainActor
    func makeHighPerformanceCameraView() -> CameraView {
        CameraView()  // Manager模式：每个View管理自己的Manager实例
    }
}

