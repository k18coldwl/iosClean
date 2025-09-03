//
//  MockDIContainer.swift
//  camfoloClean
//
//  Created by admin on 2025/1/27.
//

import Foundation

/// 统一的Mock DI容器，用于测试和Preview
/// 提供所有模块的Mock依赖，支持集成测试和UI预览
final class MockDIContainer: @unchecked Sendable, DIContainer {
    
    // MARK: - Mock Repositories
    
    /// Mock认证仓库，创建已登录的测试用户，避免认证流程阻塞Camera功能测试
    private let mockAuthRepository = MockAuthRepository(initialUser: User(
        id: "test_user_123",
        email: "test@example.com", 
        displayName: "Test User",
        photoURL: nil as URL?,
        provider: AuthProvider.google
    ))
    
    private let mockCameraRepository = MockCameraRepository()
    private let mockLocalPhotoLibraryRepository = MockLocalPhotoLibraryRepository()
    private let mockSystemPhotoLibraryRepository = MockSystemPhotoLibraryRepository()
    
    // MARK: - Repository Access
    
    var authRepository: AuthRepository {
        mockAuthRepository
    }
    
    // MARK: - Use Cases
    
    lazy var authUseCase: AuthUseCaseProtocol = {
        AuthUseCase(authRepository: authRepository)
    }()
    
    private lazy var mockCameraUseCase: CameraUseCaseProtocol = {
        CameraUseCase(
            cameraRepository: mockCameraRepository,
            localPhotoLibraryRepository: mockLocalPhotoLibraryRepository,
            systemPhotoLibraryRepository: mockSystemPhotoLibraryRepository
        )
    }()
    
    var cameraUseCase: CameraUseCaseProtocol {
        mockCameraUseCase
    }
    
    // MARK: - ViewModels
    
    @MainActor
    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(authUseCase: authUseCase)
    }
    
    @MainActor
    func makeCameraViewModel() -> CameraViewModel {
        CameraViewModel(cameraUseCase: cameraUseCase)
    }
    
    // MARK: - Configuration Methods
    
    /// 配置Mock认证行为
    /// - Parameters:
    ///   - shouldFail: 是否模拟认证失败
    ///   - user: 预设的用户对象
    func configureMockAuth(shouldFail: Bool = false, user: User? = nil) {
        mockAuthRepository.configure(shouldFail: shouldFail, user: user)
    }
    
    /// 配置Mock相机行为
    /// - Parameters:
    ///   - hasPermission: 是否有相机权限
    ///   - shouldFailCapture: 是否模拟拍照失败
    func configureMockCamera(hasPermission: Bool = true, shouldFailCapture: Bool = false) {
        mockCameraRepository.configure(hasPermission: hasPermission, shouldFailCapture: shouldFailCapture)
    }
}
