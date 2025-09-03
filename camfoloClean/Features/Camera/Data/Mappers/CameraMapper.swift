//
//  CameraMapper.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import AVFoundation
import Photos

/// 相机模块数据映射器
/// 负责在不同数据格式之间进行转换，统一错误处理
struct CameraMapper {
    
    // MARK: - Error Mapping
    
    /// 映射AVFoundation错误到CameraError
    /// - Parameter error: AVFoundation相关错误
    /// - Returns: 映射后的CameraError
    static func mapFromAVError(_ error: Error) -> CameraError {
        if let avError = error as? AVError {
            switch avError.code {
            case .deviceNotConnected:
                return .cameraNotAvailable
            case .sessionNotRunning:
                return .captureSessionFailed
            case .mediaServicesWereReset:
                return .captureSessionFailed
            case .deviceInUseByAnotherApplication:
                return .cameraNotAvailable
            default:
                return .unknown("相机服务错误: \(error.localizedDescription)")
            }
        }
        
        return .unknown("未知相机错误: \(error.localizedDescription)")
    }
    
    /// 映射Photos框架错误到CameraError
    /// - Parameter error: Photos框架相关错误
    /// - Returns: 映射后的CameraError
    static func mapFromPhotosError(_ error: Error) -> CameraError {
        if let photosError = error as? PHPhotosError {
            switch photosError.code {
            case .accessRestricted, .accessUserDenied:
                return .permissionDenied
            case .networkAccessRequired:
                return .unknown("需要网络连接来访问iCloud照片")
            case .invalidResource:
                return .invalidImage
            case .userCancelled:
                return .unknown("操作被用户取消")
            default:
                return .saveToGalleryFailed
            }
        }
        
        return .saveToGalleryFailed
    }
    
    /// 映射文件系统错误到CameraError
    /// - Parameter error: 文件系统相关错误
    /// - Returns: 映射后的CameraError
    static func mapFromFileSystemError(_ error: Error) -> CameraError {
        let nsError = error as NSError
        
        switch nsError.code {
        case NSFileWriteFileExistsError:
            return .unknown("文件已存在")
        case NSFileWriteVolumeReadOnlyError:
            return .storageSpaceInsufficient
        case NSFileWriteOutOfSpaceError:
            return .storageSpaceInsufficient
        case NSFileWriteNoPermissionError:
            return .permissionDenied
        default:
            return .unknown("文件操作失败: \(error.localizedDescription)")
        }
    }
}

/// 相机设置映射器
/// 处理相机设置在不同表示形式之间的转换
extension CameraMapper {
    
    /// 将FlashMode映射到AVCaptureDevice.FlashMode
    /// - Parameter flashMode: 应用的闪光灯模式
    /// - Returns: AVFoundation的闪光灯模式
    static func mapToAVFlashMode(_ flashMode: FlashMode) -> AVCaptureDevice.FlashMode {
        switch flashMode {
        case .auto:
            return .auto
        case .on:
            return .on
        case .off:
            return .off
        }
    }
    
    /// 将CameraPosition映射到AVCaptureDevice.Position
    /// - Parameter position: 应用的相机位置
    /// - Returns: AVFoundation的相机位置
    static func mapToAVCameraPosition(_ position: CameraPosition) -> AVCaptureDevice.Position {
        switch position {
        case .front:
            return .front
        case .back:
            return .back
        }
    }
    
    /// 将PhotoQuality映射到AVCaptureSession.Preset
    /// - Parameter quality: 应用的照片质量设置
    /// - Returns: AVFoundation的会话预设
    static func mapToAVSessionPreset(_ quality: PhotoQuality) -> AVCaptureSession.Preset {
        switch quality {
        case .low:
            return .medium
        case .medium:
            return .high
        case .high:
            return .photo
        }
    }
}
