//
//  LocalPhotoLibraryRepository.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation

/// 本地照片库仓库协议
/// 专门负责应用内部的照片存储和管理，遵循单一职责原则
/// 处理应用本地的照片持久化、缓存和文件管理
protocol LocalPhotoLibraryRepository: Sendable {
    
    // MARK: - Local Photo Storage
    
    /// 保存照片到本地存储
    /// - Parameter photo: 要保存的照片
    /// - Returns: 保存后的照片（包含文件路径等信息）
    /// - Throws: CameraError
    func savePhoto(_ photo: Photo) async throws -> Photo
    
    /// 从本地存储获取照片
    /// - Parameter photoId: 照片ID
    /// - Returns: 照片对象
    /// - Throws: CameraError
    func getPhoto(photoId: String) async throws -> Photo
    
    /// 获取所有本地照片
    /// - Returns: 照片数组，按创建时间倒序排列
    /// - Throws: CameraError
    func getAllPhotos() async throws -> [Photo]
    
    /// 删除本地照片
    /// - Parameter photoId: 照片ID
    /// - Throws: CameraError
    func deletePhoto(photoId: String) async throws
    
    // MARK: - Storage Management
    
    /// 清理临时文件
    /// - Throws: CameraError
    func cleanupTemporaryFiles() async throws
    
    /// 获取本地存储大小
    /// - Returns: 存储大小（字节）
    /// - Throws: CameraError
    func getStorageSize() async throws -> Int64
    
    /// 检查存储空间是否充足
    /// - Parameter requiredSpace: 需要的空间大小（字节）
    /// - Returns: 空间是否充足
    func hasEnoughStorage(requiredSpace: Int64) async -> Bool
}
