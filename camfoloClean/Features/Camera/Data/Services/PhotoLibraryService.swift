//
//  PhotoLibraryService.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import Photos
import UIKit
import os.log

/// 相册服务协议
/// 定义相册访问和照片管理的抽象接口
protocol PhotoLibraryServiceProtocol: Sendable {
    func checkPermission() async -> Bool
    func requestPermission() async -> Bool
    func savePhotoToGallery(_ image: UIImage) async throws
    func getRecentPhotos(limit: Int) async throws -> [UIImage]
}

/// Photos框架相册服务实现
/// 使用Photos框架实现相册访问功能，包含权限管理和照片操作
final class PhotosLibraryService: @unchecked Sendable, PhotoLibraryServiceProtocol {
    
    // MARK: - Properties
    
    /// 统一日志记录器
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "camfoloClean",
        category: "Camera.PhotosLibraryService"
    )
    
    // MARK: - Permission Management
    
    /// 检查相册权限状态
    func checkPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        return status == .authorized || status == .limited
    }
    
    /// 请求相册权限
    func requestPermission() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        Self.logger.info("Photo library permission request result: \(status.rawValue)")
        return status == .authorized || status == .limited
    }
    
    // MARK: - Photo Operations
    
    /// 保存照片到系统相册
    /// - Parameter image: 要保存的图片
    /// - Throws: CameraError
    func savePhotoToGallery(_ image: UIImage) async throws {
        Self.logger.info("Starting save photo to gallery")
        
        // 检查权限
        guard await checkPermission() else {
            Self.logger.error("Photo library permission not granted")
            throw CameraError.permissionDenied
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetCreationRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if let error = error {
                    Self.logger.error("Failed to save photo: \(error.localizedDescription)")
                    continuation.resume(throwing: CameraError.saveToGalleryFailed)
                } else if success {
                    Self.logger.info("Photo saved to gallery successfully")
                    continuation.resume()
                } else {
                    Self.logger.error("Failed to save photo: unknown error")
                    continuation.resume(throwing: CameraError.saveToGalleryFailed)
                }
            }
        }
    }
    
    /// 获取最近的照片
    /// - Parameter limit: 获取数量限制
    /// - Returns: 图片数组
    /// - Throws: CameraError
    func getRecentPhotos(limit: Int) async throws -> [UIImage] {
        Self.logger.info("Fetching recent photos, limit: \(limit)")
        
        // 检查权限
        guard await checkPermission() else {
            Self.logger.error("Photo library permission not granted")
            throw CameraError.permissionDenied
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = limit
            
            let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            var images: [UIImage] = []
            let group = DispatchGroup()
            
            let imageManager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = false
            requestOptions.deliveryMode = .highQualityFormat
            
            assets.enumerateObjects { asset, index, stop in
                group.enter()
                
                imageManager.requestImage(
                    for: asset,
                    targetSize: CGSize(width: 300, height: 300),
                    contentMode: .aspectFill,
                    options: requestOptions
                ) { image, info in
                    defer { group.leave() }
                    
                    if let image = image {
                        images.append(image)
                    }
                }
            }
            
            group.notify(queue: .main) {
                Self.logger.info("Successfully fetched \(images.count) photos")
                continuation.resume(returning: images)
            }
        }
    }
}

/// 本地文件系统照片服务
/// 管理应用内部的照片存储，提供快速的本地访问
final class LocalPhotoStorageService: @unchecked Sendable {
    
    // MARK: - Properties
    
    /// 统一日志记录器
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "camfoloClean",
        category: "Camera.LocalPhotoStorage"
    )
    
    /// 照片存储目录
    private let photosDirectory: URL
    
    // MARK: - Initialization
    
    init() throws {
        // 创建照片存储目录
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        photosDirectory = documentsPath.appendingPathComponent("Photos")
        
        // 确保目录存在
        try FileManager.default.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        
        Self.logger.info("Local photo storage initialized at: \(self.photosDirectory.path)")
    }
    
    // MARK: - Storage Operations
    
    /// 保存照片到本地存储
    /// - Parameters:
    ///   - image: 要保存的图片
    ///   - fileName: 文件名
    /// - Returns: 保存的文件URL
    /// - Throws: CameraError
    func savePhoto(_ image: UIImage, fileName: String) async throws -> URL {
        let fileURL = self.photosDirectory.appendingPathComponent(fileName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            Self.logger.error("Failed to convert image to JPEG data")
            throw CameraError.invalidImage
        }
        
        do {
            try imageData.write(to: fileURL)
            Self.logger.info("Photo saved locally: \(fileName)")
            return fileURL
        } catch {
            Self.logger.error("Failed to save photo locally: \(error.localizedDescription)")
            throw CameraError.saveToGalleryFailed
        }
    }
    
    /// 从本地存储加载照片
    /// - Parameter fileName: 文件名
    /// - Returns: 加载的图片
    /// - Throws: CameraError
    func loadPhoto(fileName: String) async throws -> UIImage {
        let fileURL = self.photosDirectory.appendingPathComponent(fileName)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            Self.logger.error("Photo file not found: \(fileName)")
            throw CameraError.invalidImage
        }
        
        do {
            let imageData = try Data(contentsOf: fileURL)
            guard let image = UIImage(data: imageData) else {
                Self.logger.error("Failed to create image from data: \(fileName)")
                throw CameraError.invalidImage
            }
            
            return image
        } catch {
            Self.logger.error("Failed to load photo: \(error.localizedDescription)")
            throw CameraError.invalidImage
        }
    }
    
    /// 删除本地照片
    /// - Parameter fileName: 文件名
    /// - Throws: CameraError
    func deletePhoto(fileName: String) async throws {
        let fileURL = self.photosDirectory.appendingPathComponent(fileName)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            Self.logger.info("Photo deleted locally: \(fileName)")
        } catch {
            Self.logger.error("Failed to delete photo: \(error.localizedDescription)")
            throw CameraError.unknown("删除照片失败: \(error.localizedDescription)")
        }
    }
    
    /// 获取所有本地照片文件名
    /// - Returns: 文件名数组
    /// - Throws: CameraError
    func getAllPhotoFileNames() async throws -> [String] {
        do {
            let fileNames = try FileManager.default.contentsOfDirectory(atPath: self.photosDirectory.path)
            return fileNames.filter { $0.hasSuffix(".jpg") || $0.hasSuffix(".jpeg") || $0.hasSuffix(".png") }
        } catch {
            Self.logger.error("Failed to list photos: \(error.localizedDescription)")
            throw CameraError.unknown("获取照片列表失败: \(error.localizedDescription)")
        }
    }
    
    /// 清理临时文件
    /// - Throws: CameraError
    func cleanupTemporaryFiles() async throws {
        do {
            let fileNames = try await getAllPhotoFileNames()
            let now = Date()
            
            for fileName in fileNames {
                let fileURL = self.photosDirectory.appendingPathComponent(fileName)
                let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                
                if let creationDate = attributes[.creationDate] as? Date,
                   now.timeIntervalSince(creationDate) > 24 * 60 * 60 { // 24小时前的文件
                    try FileManager.default.removeItem(at: fileURL)
                    Self.logger.info("Cleaned up old photo: \(fileName)")
                }
            }
        } catch {
            Self.logger.error("Failed to cleanup temporary files: \(error.localizedDescription)")
            throw CameraError.unknown("清理临时文件失败: \(error.localizedDescription)")
        }
    }
    
    /// 获取存储目录大小
    /// - Returns: 目录大小（字节）
    func getStorageSize() async throws -> Int64 {
        do {
            let fileNames = try await getAllPhotoFileNames()
            var totalSize: Int64 = 0
            
            for fileName in fileNames {
                let fileURL = self.photosDirectory.appendingPathComponent(fileName)
                let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                if let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            }
            
            return totalSize
        } catch {
            Self.logger.error("Failed to calculate storage size: \(error.localizedDescription)")
            throw CameraError.unknown("计算存储大小失败: \(error.localizedDescription)")
        }
    }
}

// MARK: - Photo Capture Delegate

/// 照片拍摄delegate
/// 处理AVCapturePhotoOutput的拍照结果回调
private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Result<UIImage, Error>) -> Void
    
    init(completion: @escaping (Result<UIImage, Error>) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completion(.failure(CameraError.invalidImage))
            return
        }
        
        completion(.success(image))
    }
}
