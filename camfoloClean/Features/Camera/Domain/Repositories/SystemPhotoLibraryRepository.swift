//
//  SystemPhotoLibraryRepository.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation

/// 系统相册仓库协议
/// 专门负责系统相册的读写操作，遵循单一职责原则
/// 处理与iOS系统相册的交互，包括权限管理和照片保存
protocol SystemPhotoLibraryRepository: Sendable {
    
    // MARK: - Photo Library Permission Management
    
    /// 检查相册权限状态
    /// - Returns: 权限是否已授权
    func checkPhotoLibraryPermission() async -> Bool
    
    /// 请求相册权限
    /// - Returns: 权限请求结果
    func requestPhotoLibraryPermission() async -> Bool
    
    // MARK: - System Photo Library Operations
    
    /// 保存照片到系统相册
    /// - Parameter photo: 要保存的照片
    /// - Throws: CameraError
    func savePhotoToSystemLibrary(_ photo: Photo) async throws
    
    /// 从系统相册获取最近的照片
    /// - Parameter limit: 获取照片的数量限制
    /// - Returns: 照片数组
    /// - Throws: CameraError
    func getRecentPhotosFromSystem(limit: Int) async throws -> [Photo]
}
