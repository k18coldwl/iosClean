//
//  SystemPhotoLibraryRepositoryImpl.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import UIKit
import os.log

/// 系统相册仓库实现
/// 专门负责与iOS系统相册的交互，遵循单一职责原则
final class SystemPhotoLibraryRepositoryImpl: @unchecked Sendable, SystemPhotoLibraryRepository {
    
    // MARK: - Dependencies
    
    private let photoLibraryService: PhotoLibraryServiceProtocol
    
    // MARK: - Properties
    
    /// 统一日志记录器
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "camfoloClean",
        category: "Camera.SystemPhotoLibraryRepository"
    )
    
    // MARK: - Initialization
    
    init(photoLibraryService: PhotoLibraryServiceProtocol) {
        self.photoLibraryService = photoLibraryService
    }
    
    // MARK: - Permission Management
    
    /// 检查相册权限状态
    func checkPhotoLibraryPermission() async -> Bool {
        return await photoLibraryService.checkPermission()
    }
    
    /// 请求相册权限
    func requestPhotoLibraryPermission() async -> Bool {
        return await photoLibraryService.requestPermission()
    }
    
    // MARK: - System Photo Library Operations
    
    /// 保存照片到系统相册
    func savePhotoToSystemLibrary(_ photo: Photo) async throws {
        Self.logger.info("Saving photo to system library: \(photo.id)")
        try await photoLibraryService.savePhotoToGallery(photo.image)
    }
    
    /// 从系统相册获取最近的照片
    func getRecentPhotosFromSystem(limit: Int) async throws -> [Photo] {
        Self.logger.info("Fetching recent photos from system library, limit: \(limit)")
        
        let images = try await photoLibraryService.getRecentPhotos(limit: limit)
        
        return images.enumerated().map { index, image in
            Photo(
                id: "system_\(index)_\(Date().timeIntervalSince1970)",
                image: image,
                createdAt: Date().addingTimeInterval(-TimeInterval(index * 3600)),
                fileName: "system_photo_\(index).jpg"
            )
        }
    }
}
