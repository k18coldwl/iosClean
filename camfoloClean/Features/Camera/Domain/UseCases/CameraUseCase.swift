//
//  CameraUseCase.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import UIKit

/// 相机用例协议
/// 定义相机模块的所有业务操作，将简单的操作合并到统一的UseCase中
/// 遵循项目的UseCase设计原则，避免过度抽象
/// 协调多个Repository实现完整的相机业务流程
protocol CameraUseCaseProtocol: Sendable {
    
    // MARK: - Core Camera Operations (核心相机操作)
    
    /// 拍摄照片 - 核心业务流程
    /// 包含完整的拍照流程：权限检查、相机配置、拍照、自动本地保存
    /// - Parameter settings: 相机设置
    /// - Returns: 拍摄并保存的照片
    /// - Throws: CameraError
    func capturePhoto(with settings: CameraSettings) async throws -> Photo
    
    /// 检查并请求相机权限
    /// - Returns: 权限是否已获得
    func ensureCameraPermission() async -> Bool
    
    /// 获取当前相机设置
    /// - Returns: 当前的相机设置
    func getCurrentCameraSettings() async -> CameraSettings
    
    /// 更新相机设置
    /// - Parameter settings: 新的相机设置
    /// - Throws: CameraError
    func updateCameraSettings(_ settings: CameraSettings) async throws
    
    // MARK: - Photo Library Operations (照片库操作)
    
    /// 保存照片到系统相册
    /// 业务逻辑：检查权限 → 保存到系统相册
    /// - Parameter photo: 要保存的照片
    /// - Throws: CameraError
    func savePhotoToSystemLibrary(_ photo: Photo) async throws
    
    /// 检查并请求相册权限（用于保存到系统相册）
    /// - Returns: 权限是否已获得
    func ensurePhotoLibraryPermission() async -> Bool
    
    /// 获取最近的照片
    /// 优先从本地存储获取，提供更好的性能
    /// - Parameter limit: 获取数量限制
    /// - Returns: 照片数组，按创建时间倒序排列
    /// - Throws: CameraError
    func getRecentPhotos(limit: Int) async throws -> [Photo]
    
    /// 删除照片
    /// 从本地存储删除，不影响系统相册
    /// - Parameter photoId: 照片ID
    /// - Throws: CameraError
    func deletePhoto(photoId: String) async throws
}

/// 相机用例实现
/// 统一处理相机相关的业务逻辑，协调多个Repository实现完整的相机业务流程
/// 包含权限管理、拍照流程、照片管理等复杂业务操作
final class CameraUseCase: @unchecked Sendable, CameraUseCaseProtocol {
    
    // MARK: - Dependencies
    
    private let cameraRepository: CameraRepository
    private let localPhotoLibraryRepository: LocalPhotoLibraryRepository
    private let systemPhotoLibraryRepository: SystemPhotoLibraryRepository
    
    // MARK: - Private Properties
    
    private var currentSettings: CameraSettings
    
    // MARK: - Initialization
    
    init(
        cameraRepository: CameraRepository,
        localPhotoLibraryRepository: LocalPhotoLibraryRepository,
        systemPhotoLibraryRepository: SystemPhotoLibraryRepository,
        defaultSettings: CameraSettings = CameraSettings()
    ) {
        self.cameraRepository = cameraRepository
        self.localPhotoLibraryRepository = localPhotoLibraryRepository
        self.systemPhotoLibraryRepository = systemPhotoLibraryRepository
        self.currentSettings = defaultSettings
    }
    
    // MARK: - Core Camera Operations
    
    /// 确保相机权限已获得
    /// 先检查权限状态，如未授权则请求权限
    func ensureCameraPermission() async -> Bool {
        let hasPermission = await cameraRepository.checkCameraPermission()
        if hasPermission {
            return true
        }
        
        return await cameraRepository.requestCameraPermission()
    }
    
    // MARK: - Photo Capture
    
    /// 执行完整的拍照流程
    /// 业务逻辑：权限检查 → 拍照 → 本地保存 → 相册保存（可选）
    func capturePhoto(with settings: CameraSettings) async throws -> Photo {
        // 1. 检查相机权限
        let hasPermission = await ensureCameraPermission()
        guard hasPermission else {
            throw CameraError.permissionDenied
        }
        
        // 2. 更新当前设置
        currentSettings = settings
        
        // 3. 拍摄照片
        let photo = try await cameraRepository.capturePhoto(with: settings)
        
        // 4. 自动保存到本地存储
        let savedPhoto = try await localPhotoLibraryRepository.savePhoto(photo)
        
        return savedPhoto
    }
    
    /// 获取当前相机设置
    /// - Returns: 当前的相机设置
    func getCurrentCameraSettings() async -> CameraSettings {
        return currentSettings
    }
    
    /// 更新相机设置
    /// - Parameter settings: 新的相机设置
    /// - Throws: CameraError
    func updateCameraSettings(_ settings: CameraSettings) async throws {
        currentSettings = settings
    }
    
    // MARK: - Photo Library Operations
    
    /// 确保相册权限已获得
    /// 先检查权限状态，如未授权则请求权限
    func ensurePhotoLibraryPermission() async -> Bool {
        let hasPermission = await systemPhotoLibraryRepository.checkPhotoLibraryPermission()
        if hasPermission {
            return true
        }
        
        return await systemPhotoLibraryRepository.requestPhotoLibraryPermission()
    }
    
    /// 保存照片到系统相册
    /// 业务逻辑：权限检查 → 保存到系统相册
    func savePhotoToSystemLibrary(_ photo: Photo) async throws {
        // 检查相册权限
        let hasPermission = await ensurePhotoLibraryPermission()
        guard hasPermission else {
            throw CameraError.permissionDenied
        }
        
        // 保存到系统相册
        try await systemPhotoLibraryRepository.savePhotoToSystemLibrary(photo)
    }
    
    /// 获取最近照片
    /// 优先从本地存储获取，提供更好的用户体验
    func getRecentPhotos(limit: Int = 20) async throws -> [Photo] {
        return try await localPhotoLibraryRepository.getAllPhotos()
            .prefix(limit)
            .map { $0 }
    }
    
    /// 删除照片
    /// 业务逻辑：从本地存储删除，不影响系统相册
    func deletePhoto(photoId: String) async throws {
        // 从本地存储删除
        try await localPhotoLibraryRepository.deletePhoto(photoId: photoId)
        
        // 注意：不自动从系统相册删除，因为用户可能希望保留
        // 如需要删除系统相册照片，可以调用systemPhotoLibraryRepository
    }
}
