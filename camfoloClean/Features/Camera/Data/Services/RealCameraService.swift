//
//  RealCameraService.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import AVFoundation
import UIKit
import os.log

/// 真实相机服务实现
/// 使用UIImagePickerController实现简单的相机功能
/// 这是一个更简单且稳定的相机实现方案
final class RealCameraService: NSObject, @unchecked Sendable, CameraServiceProtocol {
    
    // MARK: - Properties
    
    /// 统一日志记录器
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "camfoloClean",
        category: "Camera.RealCameraService"
    )
    
    /// 拍照完成回调
    private var photoCaptureCompletion: ((Result<UIImage, Error>) -> Void)?
    
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
    
    /// 拍摄照片
    /// - Parameter settings: 相机设置
    /// - Returns: 拍摄的UIImage
    /// - Throws: CameraError
    func capturePhoto(with settings: CameraSettings) async throws -> UIImage {
        Self.logger.info("Starting real photo capture")
        
        // 检查权限
        guard await checkPermission() else {
            Self.logger.error("Camera permission not granted")
            throw CameraError.permissionDenied
        }
        
        // 检查相机是否可用
        guard await UIImagePickerController.isSourceTypeAvailable(.camera) else {
            Self.logger.error("Camera not available")
            throw CameraError.deviceNotAvailable
        }
        
        // 使用UIImagePickerController进行拍照
        return try await presentCameraPicker(with: settings)
    }
    
    // MARK: - Private Methods
    
    /// 展示相机选择器
    /// - Parameter settings: 相机设置
    /// - Returns: 拍摄的UIImage
    /// - Throws: CameraError
    @MainActor
    private func presentCameraPicker(with settings: CameraSettings) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            // 保存完成回调
            self.photoCaptureCompletion = { result in
                continuation.resume(with: result)
            }
            
            // 创建UIImagePickerController
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            
            // 配置相机设置
            if UIImagePickerController.isCameraDeviceAvailable(.rear) && settings.cameraPosition == .back {
                picker.cameraDevice = .rear
            } else if UIImagePickerController.isCameraDeviceAvailable(.front) && settings.cameraPosition == .front {
                picker.cameraDevice = .front
            }
            
            // 配置闪光灯
            if UIImagePickerController.isFlashAvailable(for: picker.cameraDevice) {
                switch settings.flashMode {
                case .on:
                    picker.cameraFlashMode = .on
                case .off:
                    picker.cameraFlashMode = .off
                case .auto:
                    picker.cameraFlashMode = .auto
                }
            }
            
            // 配置图片质量
            switch settings.photoQuality {
            case .high:
                picker.cameraCaptureMode = .photo
            case .medium, .low:
                picker.cameraCaptureMode = .photo
            }
            
            // 获取当前窗口并展示相机
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                Self.logger.error("Failed to get root view controller")
                continuation.resume(throwing: CameraError.configurationFailed)
                return
            }
            
            // 找到最顶层的视图控制器
            var topViewController = rootViewController
            while let presentedViewController = topViewController.presentedViewController {
                topViewController = presentedViewController
            }
            
            topViewController.present(picker, animated: true)
            
            Self.logger.info("Camera picker presented")
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension RealCameraService: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    /// 图片选择完成回调
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        defer {
            photoCaptureCompletion = nil
            picker.dismiss(animated: true)
        }
        
        guard let image = info[.originalImage] as? UIImage else {
            Self.logger.error("Failed to get original image from picker")
            photoCaptureCompletion?(.failure(CameraError.imageProcessingFailed))
            return
        }
        
        Self.logger.info("Photo capture completed successfully")
        photoCaptureCompletion?(.success(image))
    }
    
    /// 取消选择回调
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        defer {
            photoCaptureCompletion = nil
            picker.dismiss(animated: true)
        }
        
        Self.logger.info("Photo capture cancelled by user")
        photoCaptureCompletion?(.failure(CameraError.operationTimeout))
    }
}