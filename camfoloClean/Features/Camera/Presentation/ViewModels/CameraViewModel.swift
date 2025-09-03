//
//  CameraViewModel.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import UIKit
import Observation
import os.log

/// 相机视图模型
/// 管理相机界面的状态和用户交互，连接UI层和业务逻辑层
@Observable
@MainActor
final class CameraViewModel {
    
    // MARK: - Logging
    
    /// 统一日志记录器
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "camfoloClean",
        category: "Camera.CameraViewModel"
    )
    
    // MARK: - Observable Properties
    
    /// 当前拍摄的照片
    var capturedPhoto: Photo?
    
    /// 最近的照片列表
    var recentPhotos: [Photo] = []
    
    /// 当前相机设置
    var cameraSettings = CameraSettings()
    
    /// 加载状态
    var isLoading = false
    
    /// 错误信息
    var errorMessage: String?
    
    /// 权限状态
    var hasCameraPermission = false
    var hasPhotoLibraryPermission = false
    var hasCheckedPermissions = false
    
    /// 相机状态
    var isCameraActive = false
    
    // MARK: - Use Cases
    
    private let cameraUseCase: CameraUseCaseProtocol
    
    // MARK: - Private Properties
    
    @ObservationIgnored
    private var permissionCheckTask: Task<Void, Never>?
    
    @ObservationIgnored
    private var photoLoadTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(cameraUseCase: CameraUseCaseProtocol) {
        self.cameraUseCase = cameraUseCase
        Self.logger.info("CameraViewModel initialized")
        // 延迟初始化，等到View真正显示时再执行
    }
    
    deinit {
        permissionCheckTask?.cancel()
        photoLoadTask?.cancel()
    }
    
    // MARK: - Setup Methods
    
    /// 启动相机功能初始化
    /// 当CameraView真正显示时调用，避免在ViewModel创建时就开始异步任务
    func startInitialization() {
        guard !hasCheckedPermissions && permissionCheckTask == nil else {
            Self.logger.info("Initialization already started or completed")
            return
        }
        
        Self.logger.info("Starting camera initialization")
        checkInitialPermissions()
        loadRecentPhotos()
    }
    
    /// 强制开始初始化（用于调试）
    func forceStartInitialization() {
        Self.logger.info("Force starting camera initialization")
        checkInitialPermissions()
        loadRecentPhotos()
    }
    
    /// 检查初始权限状态
    private func checkInitialPermissions() {
        Self.logger.info("Starting initial permission check")
        permissionCheckTask = Task { @MainActor in
            // 先设置加载状态
            self.isLoading = true
            Self.logger.info("Permission check: loading started")
            
            // 简化权限检查，避免可能的卡住问题
            Self.logger.info("Checking camera permission...")
            self.hasCameraPermission = await cameraUseCase.ensureCameraPermission()
            Self.logger.info("Camera permission result: \(self.hasCameraPermission)")
            
            Self.logger.info("Checking photo library permission...")
            self.hasPhotoLibraryPermission = await cameraUseCase.ensurePhotoLibraryPermission()
            Self.logger.info("Photo library permission result: \(self.hasPhotoLibraryPermission)")
            
            // 权限检查完成
            self.hasCheckedPermissions = true
            self.isLoading = false
            Self.logger.info("Permission check: loading finished")
        }
    }
    
    /// 加载最近的照片
    private func loadRecentPhotos() {
        photoLoadTask = Task { @MainActor in
            do {
                recentPhotos = try await cameraUseCase.getRecentPhotos(limit: 10)
            } catch {
                handleError(error)
            }
        }
    }
    
    // MARK: - Camera Actions
    
    /// 拍摄照片
    func capturePhoto() {
        Task { @MainActor in
            isLoading = true
            errorMessage = nil
            
            do {
                let photo = try await cameraUseCase.capturePhoto(with: cameraSettings)
                
                // 更新UI状态
                capturedPhoto = photo
                recentPhotos.insert(photo, at: 0)
                if recentPhotos.count > 10 {
                    recentPhotos.removeLast()
                }
            } catch let cameraError as CameraError {
                handleCameraError(cameraError)
            } catch {
                errorMessage = "操作失败: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
    
    /// 保存当前照片到相册
    func saveCurrentPhotoToGallery() {
        guard let photo = capturedPhoto else { return }
        
        Task { @MainActor in
            await performCameraAction {
                try await cameraUseCase.savePhotoToSystemLibrary(photo)
                return ()
            }
        }
    }
    
    /// 删除照片
    /// - Parameter photoId: 要删除的照片ID
    func deletePhoto(photoId: String) {
        Task { @MainActor in
            isLoading = true
            errorMessage = nil
            
            do {
                try await cameraUseCase.deletePhoto(photoId: photoId)
                
                // 更新UI状态
                recentPhotos.removeAll { $0.id == photoId }
                
                // 如果删除的是当前照片，清空当前照片
                if capturedPhoto?.id == photoId {
                    capturedPhoto = nil
                }
            } catch let cameraError as CameraError {
                handleCameraError(cameraError)
            } catch {
                errorMessage = "操作失败: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Settings Management
    
    /// 更新闪光灯模式
    /// - Parameter mode: 新的闪光灯模式
    func updateFlashMode(_ mode: FlashMode) {
        let newSettings = CameraSettings(
            flashMode: mode,
            cameraPosition: cameraSettings.cameraPosition,
            photoQuality: cameraSettings.photoQuality
        )
        updateSettings(newSettings)
    }
    
    /// 切换相机位置
    func toggleCameraPosition() {
        let newPosition: CameraPosition = cameraSettings.cameraPosition == .back ? .front : .back
        let newSettings = CameraSettings(
            flashMode: cameraSettings.flashMode,
            cameraPosition: newPosition,
            photoQuality: cameraSettings.photoQuality
        )
        updateSettings(newSettings)
    }
    
    /// 更新照片质量
    /// - Parameter quality: 新的照片质量
    func updatePhotoQuality(_ quality: PhotoQuality) {
        let newSettings = CameraSettings(
            flashMode: cameraSettings.flashMode,
            cameraPosition: cameraSettings.cameraPosition,
            photoQuality: quality
        )
        updateSettings(newSettings)
    }
    
    /// 更新相机设置
    /// - Parameter settings: 新的设置
    private func updateSettings(_ settings: CameraSettings) {
        Task { @MainActor in
            do {
                try await cameraUseCase.updateCameraSettings(settings)
                cameraSettings = settings
            } catch {
                handleError(error)
            }
        }
    }
    
    // MARK: - Permission Management
    
    /// 请求相机权限
    func requestCameraPermission() {
        Task { @MainActor in
            hasCameraPermission = await cameraUseCase.ensureCameraPermission()
        }
    }
    
    /// 请求相册权限
    func requestPhotoLibraryPermission() {
        Task { @MainActor in
            hasPhotoLibraryPermission = await cameraUseCase.ensurePhotoLibraryPermission()
        }
    }
    
    // MARK: - Utility Methods
    
    /// 清除错误信息
    func clearError() {
        errorMessage = nil
    }
    
    /// 刷新照片列表
    func refreshPhotos() {
        loadRecentPhotos()
    }
    
    /// 清除当前照片
    func clearCapturedPhoto() {
        capturedPhoto = nil
    }
    
    // MARK: - Private Methods
    
    /// 执行相机操作的通用方法
    /// - Parameter action: 要执行的异步操作
    private func performCameraAction<T: Sendable>(_ action: @Sendable () async throws -> T) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await action()
        } catch let cameraError as CameraError {
            handleCameraError(cameraError)
        } catch {
            errorMessage = "操作失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 处理相机错误
    /// - Parameter error: 相机错误
    private func handleCameraError(_ error: CameraError) {
        switch error {
        case .permissionDenied:
            errorMessage = "需要相机权限才能使用此功能"
            hasCameraPermission = false
        case .cameraNotAvailable:
            errorMessage = "相机不可用，请检查设备"
        case .saveToGalleryFailed:
            errorMessage = "保存到相册失败，请检查相册权限"
            hasPhotoLibraryPermission = false
        default:
            errorMessage = error.localizedDescription
        }
    }
    
    /// 处理通用错误
    /// - Parameter error: 错误对象
    private func handleError(_ error: Error) {
        if let cameraError = error as? CameraError {
            handleCameraError(cameraError)
        } else {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Photo Cache Actor

/// 照片缓存管理器
/// 提供内存级别的照片缓存，提高UI响应速度
private actor PhotoCache {
    private var cache: [String: Photo] = [:]
    
    func addPhoto(_ photo: Photo) {
        cache[photo.id] = photo
    }
    
    func getPhoto(photoId: String) -> Photo? {
        return cache[photoId]
    }
    
    func removePhoto(photoId: String) {
        cache.removeValue(forKey: photoId)
    }
    
    func updateCache(_ photos: [Photo]) {
        cache.removeAll()
        for photo in photos {
            cache[photo.id] = photo
        }
    }
    
    func clearCache() {
        cache.removeAll()
    }
}
