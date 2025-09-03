//
//  LocalPhotoLibraryRepositoryImpl.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import UIKit
import os.log

/// 本地照片库仓库实现
/// 专门负责应用内部的照片存储和管理，遵循单一职责原则
final class LocalPhotoLibraryRepositoryImpl: @unchecked Sendable, LocalPhotoLibraryRepository {
    
    // MARK: - Dependencies
    
    private let localStorageService: LocalPhotoStorageService
    
    // MARK: - Properties
    
    /// 统一日志记录器
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "camfoloClean",
        category: "Camera.LocalPhotoLibraryRepository"
    )
    
    /// 内存中的照片缓存，使用actor确保线程安全
    private let photoCache = PhotoCache()
    
    // MARK: - Initialization
    
    init(localStorageService: LocalPhotoStorageService) {
        self.localStorageService = localStorageService
    }
    
    // MARK: - Photo Storage Operations
    
    /// 保存照片到本地存储
    func savePhoto(_ photo: Photo) async throws -> Photo {
        Self.logger.info("Saving photo to local storage: \(photo.id)")
        
        // 保存到本地文件系统
        let fileURL = try await localStorageService.savePhoto(photo.image, fileName: photo.fileName)
        
        // 计算文件大小
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        // 创建包含文件信息的新Photo实体
        let savedPhoto = Photo(
            id: photo.id,
            image: photo.image,
            createdAt: photo.createdAt,
            location: photo.location,
            cameraSettings: photo.cameraSettings,
            fileSize: fileSize,
            fileName: photo.fileName
        )
        
        // 更新缓存
        await photoCache.addPhoto(savedPhoto)
        
        Self.logger.info("Photo saved successfully: \(savedPhoto.id), size: \(fileSize) bytes")
        return savedPhoto
    }
    
    /// 获取照片
    func getPhoto(photoId: String) async throws -> Photo {
        // 先尝试从缓存获取
        if let cachedPhoto = await photoCache.getPhoto(photoId: photoId) {
            return cachedPhoto
        }
        
        // 从存储加载
        let photos = try await getAllPhotos()
        guard let photo = photos.first(where: { $0.id == photoId }) else {
            throw CameraError.invalidImage
        }
        
        return photo
    }
    
    /// 获取所有照片
    func getAllPhotos() async throws -> [Photo] {
        Self.logger.info("Loading all photos from local storage")
        
        let fileNames = try await localStorageService.getAllPhotoFileNames()
        var photos: [Photo] = []
        
        for fileName in fileNames {
            do {
                let image = try await localStorageService.loadPhoto(fileName: fileName)
                
                // 从文件名解析创建时间（如果可能）
                let createdAt = parseCreationDateFromFileName(fileName) ?? Date()
                
                let photo = Photo(
                    id: fileName.replacingOccurrences(of: ".jpg", with: "").replacingOccurrences(of: ".jpeg", with: ""),
                    image: image,
                    createdAt: createdAt,
                    fileName: fileName
                )
                
                photos.append(photo)
            } catch {
                Self.logger.warning("Failed to load photo: \(fileName), error: \(error.localizedDescription)")
                // 继续处理其他照片，不因单个照片加载失败而中断
            }
        }
        
        // 更新缓存
        await photoCache.updateCache(photos)
        
        Self.logger.info("Loaded \(photos.count) photos from local storage")
        return photos.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Storage Management
    
    /// 获取本地存储大小
    func getStorageSize() async throws -> Int64 {
        return try await localStorageService.getStorageSize()
    }
    
    /// 检查存储空间是否充足
    func hasEnoughStorage(requiredSpace: Int64) async -> Bool {
        do {
            let currentSize = try await getStorageSize()
            let availableSpace = 100 * 1024 * 1024 // 假设100MB为可用空间阈值
            return (currentSize + requiredSpace) < availableSpace
        } catch {
            Self.logger.warning("Failed to check storage space: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 删除照片
    func deletePhoto(photoId: String) async throws {
        Self.logger.info("Deleting photo: \(photoId)")
        
        // 获取照片信息
        let photo = try await getPhoto(photoId: photoId)
        
        // 从本地存储删除
        try await localStorageService.deletePhoto(fileName: photo.fileName)
        
        // 从缓存删除
        await photoCache.removePhoto(photoId: photoId)
        
        Self.logger.info("Photo deleted successfully: \(photoId)")
    }
    
    /// 清理临时文件
    func cleanupTemporaryFiles() async throws {
        Self.logger.info("Starting cleanup of temporary files")
        try await localStorageService.cleanupTemporaryFiles()
        
        // 清理缓存
        await photoCache.clearCache()
        
        Self.logger.info("Temporary files cleanup completed")
    }
    
    // MARK: - Private Methods
    
    /// 从文件名解析创建时间
    /// - Parameter fileName: 文件名
    /// - Returns: 解析的日期，如果解析失败返回nil
    private func parseCreationDateFromFileName(_ fileName: String) -> Date? {
        // 尝试从文件名中提取时间戳
        let components = fileName.components(separatedBy: "_")
        if components.count >= 2,
           let timestamp = Double(components[1].components(separatedBy: ".").first ?? "") {
            return Date(timeIntervalSince1970: timestamp)
        }
        return nil
    }
}

// MARK: - Photo Cache Actor

/// 照片缓存管理器
/// 使用actor确保线程安全的照片缓存操作
private actor PhotoCache {
    private var cache: [String: Photo] = [:]
    
    /// 添加照片到缓存
    func addPhoto(_ photo: Photo) {
        cache[photo.id] = photo
    }
    
    /// 从缓存获取照片
    func getPhoto(photoId: String) -> Photo? {
        return cache[photoId]
    }
    
    /// 从缓存删除照片
    func removePhoto(photoId: String) {
        cache.removeValue(forKey: photoId)
    }
    
    /// 更新整个缓存
    func updateCache(_ photos: [Photo]) {
        cache.removeAll()
        for photo in photos {
            cache[photo.id] = photo
        }
    }
    
    /// 清空缓存
    func clearCache() {
        cache.removeAll()
    }
}
