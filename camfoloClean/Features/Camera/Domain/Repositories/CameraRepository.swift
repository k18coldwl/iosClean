//
//  CameraRepository.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import UIKit

/// 相机仓库协议
/// 专门负责相机硬件相关的操作，遵循单一职责原则
/// 只处理相机拍照和相机权限管理，不涉及照片存储和相册操作
protocol CameraRepository: Sendable {
    
    // MARK: - Camera Permission Management
    
    /// 检查相机权限状态
    /// - Returns: 权限是否已授权
    func checkCameraPermission() async -> Bool
    
    /// 请求相机权限
    /// - Returns: 权限请求结果
    func requestCameraPermission() async -> Bool
    
    // MARK: - Camera Operations
    
    /// 拍摄照片
    /// - Parameter settings: 相机设置
    /// - Returns: 拍摄的照片（仅包含图片数据，不涉及存储）
    /// - Throws: CameraError
    func capturePhoto(with settings: CameraSettings) async throws -> Photo
    
    /// 检查相机设备可用性
    /// - Parameter position: 相机位置
    /// - Returns: 设备是否可用
    func isCameraDeviceAvailable(position: CameraPosition) async -> Bool
    
    /// 检查闪光灯可用性
    /// - Parameter position: 相机位置
    /// - Returns: 闪光灯是否可用
    func isFlashAvailable(for position: CameraPosition) async -> Bool
}
