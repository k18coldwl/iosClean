//
//  CameraError.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation

/// 相机模块错误类型
/// 定义了相机功能中可能出现的各种错误情况
enum CameraError: LocalizedError, Equatable {
    case permissionDenied
    case cameraNotAvailable
    case deviceNotAvailable
    case configurationFailed
    case captureSessionFailed
    case photoCaptureFailed
    case captureFailed
    case imageProcessingFailed
    case saveToGalleryFailed
    case invalidImage
    case storageSpaceInsufficient
    case operationTimeout
    case unknown(String)
    
    static func == (lhs: CameraError, rhs: CameraError) -> Bool {
        switch (lhs, rhs) {
        case (.permissionDenied, .permissionDenied),
             (.cameraNotAvailable, .cameraNotAvailable),
             (.deviceNotAvailable, .deviceNotAvailable),
             (.configurationFailed, .configurationFailed),
             (.captureSessionFailed, .captureSessionFailed),
             (.photoCaptureFailed, .photoCaptureFailed),
             (.captureFailed, .captureFailed),
             (.imageProcessingFailed, .imageProcessingFailed),
             (.saveToGalleryFailed, .saveToGalleryFailed),
             (.invalidImage, .invalidImage),
             (.storageSpaceInsufficient, .storageSpaceInsufficient),
             (.operationTimeout, .operationTimeout):
            return true
        case (.unknown(let lhsMessage), .unknown(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "相机权限被拒绝，请在设置中允许访问相机"
        case .cameraNotAvailable:
            return "相机不可用，请检查设备是否支持相机功能"
        case .deviceNotAvailable:
            return "相机设备不可用，请检查设备硬件"
        case .configurationFailed:
            return "相机配置失败，请重新尝试"
        case .captureSessionFailed:
            return "相机会话启动失败，请重新尝试"
        case .photoCaptureFailed:
            return "拍照失败，请重新尝试"
        case .captureFailed:
            return "照片捕获失败，请重新尝试"
        case .imageProcessingFailed:
            return "图片处理失败，请重新尝试"
        case .saveToGalleryFailed:
            return "保存到相册失败，请检查相册权限"
        case .invalidImage:
            return "无效的图片数据"
        case .storageSpaceInsufficient:
            return "存储空间不足，请清理设备存储空间"
        case .operationTimeout:
            return "操作超时，请检查网络连接或重新尝试"
        case .unknown(let message):
            return "未知错误: \(message)"
        }
    }
}
