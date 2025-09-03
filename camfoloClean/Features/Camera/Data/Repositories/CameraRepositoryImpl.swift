//
//  CameraRepositoryImpl.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import UIKit
import os.log

/// 相机仓库实现
/// 专门负责相机硬件相关的操作，遵循单一职责原则
/// 只处理相机拍照和权限管理，不涉及照片存储
final class CameraRepositoryImpl: @unchecked Sendable, CameraRepository {
    
    // MARK: - Dependencies
    
    private let cameraService: CameraServiceProtocol
    
    // MARK: - Properties
    
    /// 统一日志记录器
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "camfoloClean",
        category: "Camera.CameraRepository"
    )
    
    // MARK: - Initialization
    
    /// 初始化相机仓库
    /// - Parameter cameraService: 相机服务
    init(cameraService: CameraServiceProtocol) {
        self.cameraService = cameraService
    }
    
    // MARK: - Camera Operations
    
    /// 检查相机权限状态
    func checkCameraPermission() async -> Bool {
        return await cameraService.checkPermission()
    }
    
    /// 请求相机权限
    func requestCameraPermission() async -> Bool {
        return await cameraService.requestPermission()
    }
    
    /// 拍摄照片
    /// 专注于相机硬件操作：拍摄 → 创建Photo实体
    func capturePhoto(with settings: CameraSettings) async throws -> Photo {
        Self.logger.info("Starting photo capture process")
        
        // 拍摄照片
        let image = try await cameraService.capturePhoto(with: settings)
        
        // 创建Photo实体（不涉及存储）
        let photo = Photo(
            image: image,
            cameraSettings: settings,
            fileName: generateFileName()
        )
        
        Self.logger.info("Photo capture completed: \(photo.id)")
        return photo
    }
    
    /// 检查相机设备可用性
    func isCameraDeviceAvailable(position: CameraPosition) async -> Bool {
        // 这里可以调用底层相机服务检查设备可用性
        // 目前返回true，实际实现中应该检查具体的相机设备
        return true
    }
    
    /// 检查闪光灯可用性
    func isFlashAvailable(for position: CameraPosition) async -> Bool {
        // 这里可以调用底层相机服务检查闪光灯可用性
        // 目前返回true，实际实现中应该检查具体的设备能力
        return true
    }
    

    
    // MARK: - Private Methods
    
    /// 生成唯一的文件名
    /// - Returns: 基于时间戳的文件名
    private func generateFileName() -> String {
        let timestamp = Date().timeIntervalSince1970
        return "photo_\(Int(timestamp)).jpg"
    }
}
