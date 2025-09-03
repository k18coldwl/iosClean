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
    
    // Camera Dependencies
    var cameraUseCase: CameraUseCaseProtocol { get }
    
    // ViewModels
    @MainActor
    func makeAuthViewModel() -> AuthViewModel
    
    @MainActor
    func makeCameraViewModel() -> CameraViewModel
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
        // 在Debug模式下，使用Mock认证来快速测试Camera功能
        #if DEBUG
        // 临时启用Mock认证，跳过登录流程，直接测试Camera功能
        // return MockAuthRepository(initialUser: User(id: "debug_user", email: "debug@test.com", displayName: "Debug User", photoURL: nil, provider: .google))
        #endif
        
        return AuthRepositoryImpl(
            appleSignInService: appleSignInService,
            googleSignInService: googleSignInService
        )
    }()
    
    // MARK: - Camera Services
    private lazy var cameraService: CameraServiceProtocol = {
        // 根据编译配置选择相机服务实现
        #if DEBUG
        // Debug模式：可以选择使用真实相机或Mock相机
        // 设置为true使用真实相机，false使用Mock相机
        let useRealCamera = true
        
        if useRealCamera {
            // RealCameraService需要在主线程创建
            return MainActor.assumeIsolated {
                RealCameraService()
            }
        } else {
            return SimpleCameraService()  // Mock实现
        }
        #else
        // Release模式：始终使用真实相机
        return MainActor.assumeIsolated {
            RealCameraService()
        }
        #endif
    }()
    
    private lazy var photoLibraryService: PhotoLibraryServiceProtocol = {
        PhotosLibraryService()
    }()
    
    private lazy var localPhotoStorageService: LocalPhotoStorageService = {
        do {
            return try LocalPhotoStorageService()
        } catch {
            fatalError("Failed to initialize LocalPhotoStorageService: \(error)")
        }
    }()
    
    // MARK: - Camera Repositories
    private lazy var cameraRepository: CameraRepository = {
        CameraRepositoryImpl(cameraService: cameraService)
    }()
    
    private lazy var localPhotoLibraryRepository: LocalPhotoLibraryRepository = {
        LocalPhotoLibraryRepositoryImpl(localStorageService: localPhotoStorageService)
    }()
    
    private lazy var systemPhotoLibraryRepository: SystemPhotoLibraryRepository = {
        SystemPhotoLibraryRepositoryImpl(photoLibraryService: photoLibraryService)
    }()
    
    // MARK: - Use Cases
    lazy var authUseCase: AuthUseCaseProtocol = {
        AuthUseCase(authRepository: authRepository)
    }()
    
    lazy var cameraUseCase: CameraUseCaseProtocol = {
        CameraUseCase(
            cameraRepository: cameraRepository,
            localPhotoLibraryRepository: localPhotoLibraryRepository,
            systemPhotoLibraryRepository: systemPhotoLibraryRepository
        )
    }()
    
    // MARK: - ViewModels
    @MainActor
    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(authUseCase: authUseCase)
    }
    
    @MainActor
    func makeCameraViewModel() -> CameraViewModel {
        CameraViewModel(cameraUseCase: cameraUseCase)
    }
}

