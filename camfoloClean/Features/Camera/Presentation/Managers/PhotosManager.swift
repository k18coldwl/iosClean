//
//  PhotosManager.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import SwiftUI
import Photos
import UIKit
import os.log

/// 🎯 高性能系统相册管理器（单一职责）
/// 职责：仅负责iOS系统相册的读写操作
/// - 相册权限管理
/// - 照片保存到系统相册
/// - 从系统相册读取照片
/// - Photos框架错误处理
/// 不负责：本地存储、相机操作、业务逻辑
@Observable
final class PhotosManager: @unchecked Sendable {
    
    // MARK: - Logging
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "camfoloClean",
        category: "Camera.PhotosManager"
    )
    
    // MARK: - Published State
    
    /// 相册权限状态
    var hasPhotoLibraryPermission = false
    
    /// 最近的照片（缓存）
    var recentPhotos: [UIImage] = []
    
    /// 错误信息
    var errorMessage: String?
    
    /// 加载状态
    var isLoading = false
    
    // MARK: - Performance Optimization
    
    /// 图片缓存（避免重复加载）
    private var imageCache: [String: UIImage] = [:]
    private let maxCacheSize = 50
    
    /// 高优先级队列（IO操作）
    private let photosQueue = DispatchQueue(
        label: "photos.queue",
        qos: .userInitiated
    )
    
    // MARK: - Initialization
    
    init() {
        Self.logger.info("PhotosManager initialized")
    }
    
    // MARK: - 🎯 核心功能：权限管理
    
    /// 检查相册权限状态
    func checkPhotoLibraryPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        let hasPermission = status == .authorized || status == .limited
        
        await MainActor.run {
            self.hasPhotoLibraryPermission = hasPermission
        }
        
        return hasPermission
    }
    
    /// 请求相册权限
    func requestPhotoLibraryPermission() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        let hasPermission = status == .authorized || status == .limited
        
        await MainActor.run {
            self.hasPhotoLibraryPermission = hasPermission
        }
        
        Self.logger.info("Photo library permission result: \(status.rawValue)")
        return hasPermission
    }
    
    // MARK: - 🎯 核心功能：保存照片
    
    /// 🚀 高性能保存照片到系统相册
    func savePhotoToSystemLibrary(_ image: UIImage) async throws {
        Self.logger.info("Starting save photo to system library")
        
        // 权限检查
        if !hasPhotoLibraryPermission {
            guard await checkPhotoLibraryPermission() else {
                throw PhotosError.permissionDenied
            }
        }
        
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        return try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetCreationRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if let error = error {
                    let mappedError = Self.mapPhotosError(error)
                    Self.logger.error("Failed to save photo: \(error.localizedDescription)")
                    Task { @MainActor [weak self] in
                        self?.errorMessage = mappedError.localizedDescription
                    }
                    continuation.resume(throwing: mappedError)
                } else if success {
                    Self.logger.info("Photo saved to system library successfully")
                    continuation.resume()
                } else {
                    let error = PhotosError.saveToGalleryFailed
                    Task { @MainActor [weak self] in
                        self?.errorMessage = error.localizedDescription
                    }
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - 🎯 核心功能：读取照片
    
    /// 🚀 高性能获取最近照片
    func getRecentPhotos(limit: Int = 20) async throws -> [UIImage] {
        Self.logger.info("Fetching recent photos, limit: \(limit)")
        
        // 权限检查
        if !hasPhotoLibraryPermission {
            guard await checkPhotoLibraryPermission() else {
                throw PhotosError.permissionDenied
            }
        }
        
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        return try await withCheckedThrowingContinuation { continuation in
            photosQueue.async { [weak self] in
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [
                    NSSortDescriptor(key: "creationDate", ascending: false)
                ]
                fetchOptions.fetchLimit = limit
                
                let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                var images: [UIImage] = []
                
                let group = DispatchGroup()
                let imageManager = PHImageManager.default()
                
                // 🚀 性能优化：使用合适的图片尺寸
                let targetSize = CGSize(width: 300, height: 300)
                let requestOptions = PHImageRequestOptions()
                requestOptions.isSynchronous = false
                requestOptions.deliveryMode = .highQualityFormat
                requestOptions.isNetworkAccessAllowed = true
                
                assets.enumerateObjects { asset, index, stop in
                    group.enter()
                    
                    imageManager.requestImage(
                        for: asset,
                        targetSize: targetSize,
                        contentMode: .aspectFill,
                        options: requestOptions
                    ) { image, info in
                        defer { group.leave() }
                        
                        if let image = image {
                            images.append(image)
                        }
                    }
                }
                
                group.notify(queue: .main) { [weak self] in
                    let imagesCopy = images  // 创建本地副本避免数据竞争
                    Self.logger.info("Successfully fetched \(imagesCopy.count) photos")
                    Task { @MainActor [weak self] in
                        self?.recentPhotos = imagesCopy
                    }
                    continuation.resume(returning: imagesCopy)
                }
            }
        }
    }
    
    // MARK: - 🎯 错误处理（专用）
    
    /// 映射Photos框架错误到应用错误
    private static func mapPhotosError(_ error: Error) -> PhotosError {
        if let photosError = error as? PHPhotosError {
            switch photosError.code {
            case .accessRestricted, .accessUserDenied:
                return .permissionDenied
            case .networkAccessRequired:
                return .networkRequired
            case .invalidResource:
                return .invalidImage
            case .userCancelled:
                return .userCancelled
            default:
                return .saveToGalleryFailed
            }
        }
        return .unknown(error.localizedDescription)
    }
}

// MARK: - 📦 专用错误类型

/// Photos管理器专用错误
enum PhotosError: LocalizedError, Equatable {
    case permissionDenied
    case saveToGalleryFailed
    case loadFromGalleryFailed
    case networkRequired
    case invalidImage
    case userCancelled
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "相册权限被拒绝，请在设置中允许访问相册"
        case .saveToGalleryFailed:
            return "保存到相册失败，请重试"
        case .loadFromGalleryFailed:
            return "从相册加载失败，请重试"
        case .networkRequired:
            return "需要网络连接来访问iCloud照片"
        case .invalidImage:
            return "无效的图片数据"
        case .userCancelled:
            return "操作被取消"
        case .unknown(let message):
            return "相册操作失败: \(message)"
        }
    }
    
    static func == (lhs: PhotosError, rhs: PhotosError) -> Bool {
        switch (lhs, rhs) {
        case (.permissionDenied, .permissionDenied),
             (.saveToGalleryFailed, .saveToGalleryFailed),
             (.loadFromGalleryFailed, .loadFromGalleryFailed),
             (.networkRequired, .networkRequired),
             (.invalidImage, .invalidImage),
             (.userCancelled, .userCancelled):
            return true
        case (.unknown(let lMsg), .unknown(let rMsg)):
            return lMsg == rMsg
        default:
            return false
        }
    }
}
