//
//  SimpleCameraService.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import AVFoundation
import UIKit
import os.log

/// 相机服务协议
/// 定义底层相机操作的抽象接口
protocol CameraServiceProtocol: Sendable {
    func checkPermission() async -> Bool
    func requestPermission() async -> Bool
    func capturePhoto(with settings: CameraSettings) async throws -> UIImage
}

/// 简化版相机服务实现
/// 提供基本的相机功能，避免复杂的并发问题
final class SimpleCameraService: @unchecked Sendable, CameraServiceProtocol {
    
    // MARK: - Properties
    
    /// 统一日志记录器
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "camfoloClean",
        category: "Camera.SimpleCameraService"
    )
    
    // MARK: - Permission Management
    
    /// 检查相机权限状态
    func checkPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        Self.logger.info("Camera permission status: \(status.rawValue)")
        return status == .authorized
    }
    
    /// 请求相机权限
    func requestPermission() async -> Bool {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        Self.logger.info("Camera permission request result: \(status)")
        return status
    }
    
    // MARK: - Photo Capture
    
    /// 拍摄照片（简化实现）
    /// - Parameter settings: 相机设置
    /// - Returns: 拍摄的UIImage
    /// - Throws: CameraError
    func capturePhoto(with settings: CameraSettings) async throws -> UIImage {
        Self.logger.info("Starting photo capture")
        
        // 检查权限
        guard await checkPermission() else {
            Self.logger.error("Camera permission not granted")
            throw CameraError.permissionDenied
        }
        
        // 模拟拍照过程（在实际实现中，这里会使用AVCaptureSession）
        try await Task.sleep(nanoseconds: 1_000_000_000) // 模拟拍照延迟
        
        // 创建模拟照片
        let image = createMockImage(for: settings)
        
        Self.logger.info("Photo capture completed")
        return image
    }
    
    // MARK: - Private Methods
    
    /// 创建模拟照片
    /// - Parameter settings: 相机设置
    /// - Returns: 模拟的UIImage
    private func createMockImage(for settings: CameraSettings) -> UIImage {
        let size = CGSize(width: 400, height: 600)
        
        // 根据相机位置选择不同的颜色
        let baseColor: UIColor = settings.cameraPosition == .front ? .systemBlue : .systemGreen
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        // 绘制背景
        baseColor.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        // 添加文本标识
        let text = "Camera: \(settings.cameraPosition.displayName)\nFlash: \(settings.flashMode.displayName)\nQuality: \(settings.photoQuality.displayName)"
        let textColor = UIColor.white
        let font = UIFont.systemFont(ofSize: 20, weight: .medium)
        
        let textRect = CGRect(x: 20, y: size.height - 120, width: size.width - 40, height: 100)
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
