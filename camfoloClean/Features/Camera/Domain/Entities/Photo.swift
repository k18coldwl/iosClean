//
//  Photo.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import UIKit

/// 照片实体
/// 表示应用中的照片对象，包含照片的基本信息和元数据
struct Photo: Identifiable, Equatable, Sendable {
    let id: String
    let image: UIImage
    let createdAt: Date
    let location: PhotoLocation?
    let cameraSettings: CameraSettings?
    let fileSize: Int64
    let fileName: String
    
    init(
        id: String = UUID().uuidString,
        image: UIImage,
        createdAt: Date = Date(),
        location: PhotoLocation? = nil,
        cameraSettings: CameraSettings? = nil,
        fileSize: Int64 = 0,
        fileName: String = ""
    ) {
        self.id = id
        self.image = image
        self.createdAt = createdAt
        self.location = location
        self.cameraSettings = cameraSettings
        self.fileSize = fileSize
        self.fileName = fileName
    }
}

/// 照片位置信息
struct PhotoLocation: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
    let placeName: String?
    
    init(latitude: Double, longitude: Double, placeName: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.placeName = placeName
    }
}

/// 相机设置
struct CameraSettings: Equatable, Sendable {
    let flashMode: FlashMode
    let cameraPosition: CameraPosition
    let photoQuality: PhotoQuality
    
    init(
        flashMode: FlashMode = .auto,
        cameraPosition: CameraPosition = .back,
        photoQuality: PhotoQuality = .high
    ) {
        self.flashMode = flashMode
        self.cameraPosition = cameraPosition
        self.photoQuality = photoQuality
    }
}

/// 闪光灯模式
enum FlashMode: String, CaseIterable, Sendable {
    case auto = "auto"
    case on = "on"
    case off = "off"
    
    var displayName: String {
        switch self {
        case .auto:
            return "Auto"
        case .on:
            return "On"
        case .off:
            return "Off"
        }
    }
}

/// 相机位置
enum CameraPosition: String, CaseIterable, Sendable {
    case front = "front"
    case back = "back"
    
    var displayName: String {
        switch self {
        case .front:
            return "Front"
        case .back:
            return "Back"
        }
    }
}

/// 照片质量
enum PhotoQuality: String, CaseIterable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        }
    }
}
