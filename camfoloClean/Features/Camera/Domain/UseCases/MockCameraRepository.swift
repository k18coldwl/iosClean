//
//  MockCameraRepository.swift
//  camfoloClean
//
//  Created by admin on 2025/1/27.
//

import Foundation
import UIKit

// 导入必要的Camera模块类型
// 这些类型定义在同一模块的Domain层中

// MARK: - Mock Camera Repository

/// Mock相机仓库，用于测试和预览
/// 提供可配置的Mock行为，避免真实权限检查和相机操作
final class MockCameraRepository: @unchecked Sendable, CameraRepository {
    private var hasPermission = true
    private var shouldFailCapture = false
    private var mockPhotos: [Photo] = []
    
    init() {
        // 创建一些示例照片用于测试
        createMockPhotos()
    }
    
    // MARK: - Configuration Methods for Testing
    
    func configure(hasPermission: Bool = true, shouldFailCapture: Bool = false) {
        self.hasPermission = hasPermission
        self.shouldFailCapture = shouldFailCapture
    }
    
    // MARK: - Camera Operations
    
    func checkCameraPermission() async -> Bool {
        return hasPermission
    }
    
    func requestCameraPermission() async -> Bool {
        // 模拟权限请求延迟
        try? await Task.sleep(nanoseconds: 500_000_000)
        hasPermission = true
        return hasPermission
    }
    
    func capturePhoto(with settings: CameraSettings) async throws -> Photo {
        // 模拟拍照延迟
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        if shouldFailCapture {
            throw CameraError.photoCaptureFailed
        }
        
        // 创建模拟照片
        let mockImage = createMockImage()
        let photo = Photo(
            image: mockImage,
            cameraSettings: settings,
            fileName: "photo_\(Date().timeIntervalSince1970).jpg"
        )
        
        return photo
    }
    
    // MARK: - Camera Device Operations
    
    func isCameraDeviceAvailable(position: CameraPosition) async -> Bool {
        // Mock环境中假设所有设备都可用
        return true
    }
    
    func isFlashAvailable(for position: CameraPosition) async -> Bool {
        // Mock环境中假设闪光灯都可用
        return true
    }
    
    // MARK: - Private Methods
    
    private func createMockPhotos() {
        for i in 1...5 {
            let photo = Photo(
                id: "mock_\(i)",
                image: createMockImage(),
                createdAt: Date().addingTimeInterval(-TimeInterval(i * 3600)), // i小时前
                fileName: "mock_photo_\(i).jpg"
            )
            mockPhotos.append(photo)
        }
    }
    
    private func createMockImage() -> UIImage {
        // 创建一个简单的彩色矩形作为模拟图片
        let size = CGSize(width: 300, height: 300)
        let color = UIColor(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1),
            alpha: 1.0
        )
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        
        return image
    }
}

// MARK: - Mock Photo Library Repositories

/// Mock本地照片库仓库，用于测试和预览
final class MockLocalPhotoLibraryRepository: @unchecked Sendable, LocalPhotoLibraryRepository {
    private var photos: [String: Photo] = [:]
    private var shouldFail = false
    
    func configure(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }
    
    func savePhoto(_ photo: Photo) async throws -> Photo {
        if shouldFail {
            throw CameraError.saveToGalleryFailed
        }
        
        // 模拟保存延迟
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // 添加文件信息
        let savedPhoto = Photo(
            id: photo.id,
            image: photo.image,
            createdAt: photo.createdAt,
            location: photo.location,
            cameraSettings: photo.cameraSettings,
            fileSize: Int64.random(in: 1024...5_000_000), // 1KB - 5MB
            fileName: photo.fileName.isEmpty ? "photo_\(Date().timeIntervalSince1970).jpg" : photo.fileName
        )
        
        photos[savedPhoto.id] = savedPhoto
        return savedPhoto
    }
    
    func getPhoto(photoId: String) async throws -> Photo {
        guard let photo = photos[photoId] else {
            throw CameraError.invalidImage
        }
        return photo
    }
    
    func getAllPhotos() async throws -> [Photo] {
        return Array(photos.values).sorted { $0.createdAt > $1.createdAt }
    }
    
    func deletePhoto(photoId: String) async throws {
        photos.removeValue(forKey: photoId)
    }
    
    func cleanupTemporaryFiles() async throws {
        // 模拟清理操作
        print("Mock: Cleanup temporary files")
    }
    
    // MARK: - Storage Management
    
    func getStorageSize() async throws -> Int64 {
        return photos.values.reduce(0) { $0 + $1.fileSize }
    }
    
    func hasEnoughStorage(requiredSpace: Int64) async -> Bool {
        let currentSize = (try? await getStorageSize()) ?? 0
        let maxSize: Int64 = 100 * 1024 * 1024 // 100MB
        return (currentSize + requiredSpace) < maxSize
    }
}

/// Mock系统相册仓库，用于测试和预览
final class MockSystemPhotoLibraryRepository: @unchecked Sendable, SystemPhotoLibraryRepository {
    private var hasPermission = true
    private var shouldFail = false
    
    func configure(hasPermission: Bool = true, shouldFail: Bool = false) {
        self.hasPermission = hasPermission
        self.shouldFail = shouldFail
    }
    
    // MARK: - Permission Management
    
    func checkPhotoLibraryPermission() async -> Bool {
        return hasPermission
    }
    
    func requestPhotoLibraryPermission() async -> Bool {
        // 模拟权限请求延迟
        try? await Task.sleep(nanoseconds: 300_000_000)
        return hasPermission
    }
    
    // MARK: - System Photo Library Operations
    
    func savePhotoToSystemLibrary(_ photo: Photo) async throws {
        if !hasPermission {
            throw CameraError.permissionDenied
        }
        
        if shouldFail {
            throw CameraError.saveToGalleryFailed
        }
        
        // 模拟保存到系统相册
        try await Task.sleep(nanoseconds: 500_000_000)
        print("Mock: Photo saved to system library: \(photo.id)")
    }
    
    func getRecentPhotosFromSystem(limit: Int) async throws -> [Photo] {
        if !hasPermission {
            throw CameraError.permissionDenied
        }
        
        // 返回一些模拟的系统相册照片
        var systemPhotos: [Photo] = []
        for i in 0..<min(limit, 5) {
            let image = createMockImage()
            let photo = Photo(
                id: "system_\(i)",
                image: image,
                createdAt: Date().addingTimeInterval(-TimeInterval(i * 3600)),
                fileName: "system_photo_\(i).jpg"
            )
            systemPhotos.append(photo)
        }
        
        return systemPhotos
    }
    
    // MARK: - Private Methods
    
    private func createMockImage() -> UIImage {
        let size = CGSize(width: 300, height: 300)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        UIColor.systemBlue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}

// MARK: - Mock Camera UseCase

/// Mock相机用例，用于测试和预览
/// 提供可配置的Mock行为，避免真实权限检查和相机操作
final class MockCameraUseCase: @unchecked Sendable, CameraUseCaseProtocol {
    private var hasPermission = true
    private var mockPhotos: [Photo] = []
    
    init() {
        // 创建一些示例照片
        createMockPhotos()
    }
    
    // MARK: - Configuration for Testing
    
    func configure(hasPermission: Bool = true) {
        self.hasPermission = hasPermission
    }
    
    // MARK: - Permission Management
    
    func ensureCameraPermission() async -> Bool {
        // Mock环境中立即返回权限状态，避免异步延迟
        return hasPermission
    }
    
    func ensurePhotoLibraryPermission() async -> Bool {
        // Mock环境中立即返回权限状态，避免异步延迟
        return hasPermission
    }
    
    // MARK: - Photo Operations
    
    func capturePhoto(with settings: CameraSettings) async throws -> Photo {
        // 模拟拍照延迟
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let mockImage = createMockImage(for: settings)
        let photo = Photo(
            image: mockImage,
            cameraSettings: settings,
            fileName: "photo_\(Date().timeIntervalSince1970).jpg"
        )
        
        // 添加到mock照片列表
        mockPhotos.insert(photo, at: 0)
        if mockPhotos.count > 10 {
            mockPhotos.removeLast()
        }
        
        return photo
    }
    
    func getRecentPhotos(limit: Int) async throws -> [Photo] {
        return Array(mockPhotos.prefix(limit))
    }
    
    func savePhotoToSystemLibrary(_ photo: Photo) async throws {
        // 模拟保存延迟
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    func deletePhoto(photoId: String) async throws {
        mockPhotos.removeAll { $0.id == photoId }
    }
    
    func updateCameraSettings(_ settings: CameraSettings) async throws {
        // Mock实现不需要实际更新硬件设置
    }
    
    func getCurrentCameraSettings() async -> CameraSettings {
        // 返回默认的相机设置
        return CameraSettings()
    }
    
    // MARK: - Private Methods
    
    private func createMockPhotos() {
        for i in 1...3 {
            let settings = CameraSettings(
                flashMode: FlashMode.allCases.randomElement() ?? .auto,
                cameraPosition: CameraPosition.allCases.randomElement() ?? .back,
                photoQuality: PhotoQuality.allCases.randomElement() ?? .high
            )
            
            let photo = Photo(
                id: "mock_\(i)",
                image: createMockImage(for: settings),
                createdAt: Date().addingTimeInterval(-TimeInterval(i * 3600)),
                cameraSettings: settings,
                fileName: "mock_photo_\(i).jpg"
            )
            mockPhotos.append(photo)
        }
    }
    
    private func createMockImage(for settings: CameraSettings) -> UIImage {
        let size = CGSize(width: 300, height: 400)
        
        // 根据相机位置选择不同的颜色
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemPink]
        let baseColor = colors.randomElement() ?? .systemBlue
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        // 绘制背景
        baseColor.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        // 添加文本标识
        let text = "Mock Photo\n\(settings.cameraPosition.displayName) Camera\nFlash: \(settings.flashMode.displayName)"
        let textColor = UIColor.white
        let font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        let textRect = CGRect(x: 20, y: size.height - 100, width: size.width - 40, height: 80)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]
        
        text.draw(in: textRect, withAttributes: attributes)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}
