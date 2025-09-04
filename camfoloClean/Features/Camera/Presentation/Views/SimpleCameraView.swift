//
//  SimpleCameraView.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI

/// 🚀 极简高性能相机视图
/// 使用Manager模式实现单一职责：
/// - CameraManager：相机硬件和实时预览
/// - PhotosManager：系统相册读写
/// 专为60fps实时预览设计，零抽象开销
struct SimpleCameraView: View {
    @State private var cameraManager = CameraManager()
    @State private var photosManager = PhotosManager()
    @State private var capturedPhoto: Photo?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // 高性能实时预览
            if let pixelBuffer = cameraManager.currentPixelBuffer {
                MetalPixelBufferView(pixelBuffer: pixelBuffer)
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
                    .overlay(
                        Text(cameraManager.isLoading ? "启动中..." : "无预览")
                            .foregroundColor(.white)
                    )
            }
            
            // UI覆盖层
            VStack {
                // 帧信息显示
                if let frameInfo = cameraManager.frameInfo {
                    frameInfoOverlay(frameInfo)
                }
                
                Spacer()
                
                // 照片预览区域
                if let photo = capturedPhoto {
                    photoPreviewArea(photo)
                } else {
                    // 相机控制
                    cameraControlsView
                }
            }
            .padding()
        }
        .navigationBarHidden(true)
        .statusBarHidden()
        .alert("相机错误", isPresented: .constant(cameraManager.errorMessage != nil)) {
            Button("确定") {
                cameraManager.errorMessage = nil
            }
        } message: {
            if let errorMessage = cameraManager.errorMessage {
                Text(errorMessage)
            }
        }
        .task {
            // 启动流程：检查权限 → 启动预览
            let hasPermission = await cameraManager.checkCameraPermission()
            if !hasPermission {
                _ = await cameraManager.requestCameraPermission()
            }
            
            if cameraManager.hasCameraPermission {
                await cameraManager.startPreview()
            }
        }
        .onDisappear {
            cameraManager.stopPreview()
        }
    }
    
    // MARK: - View Components
    
    /// 帧信息覆盖层（高性能版本）
    private func frameInfoOverlay(_ info: (width: Int, height: Int, fps: String)) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("分辨率: \(info.width)×\(info.height)")
                    .font(.system(.caption, design: .monospaced))
                Text("帧率: \(info.fps) FPS")
                    .font(.system(.caption, design: .monospaced))
                Text("位置: \(cameraManager.currentCameraPosition.displayName)")
                    .font(.system(.caption, design: .monospaced))
            }
            Spacer()
        }
        .padding(12)
        .background(.black.opacity(0.6))
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    /// 相机控制视图
    private var cameraControlsView: some View {
        HStack(spacing: 30) {
            // 闪光灯切换
            Button(action: { cameraManager.toggleFlashMode() }) {
                Image(systemName: flashIcon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(.black.opacity(0.6))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // 拍照按钮
            Button(action: capturePhoto) {
                Circle()
                    .fill(.white)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(.black, lineWidth: 2)
                            .frame(width: 60, height: 60)
                    )
            }
            .disabled(cameraManager.isLoading)
            
            Spacer()
            
            // 相机切换
            Button(action: { Task { await cameraManager.switchCamera() } }) {
                Image(systemName: "camera.rotate")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(.black.opacity(0.6))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var flashIcon: String {
        switch cameraManager.currentFlashMode {
        case .auto: return "bolt.badge.automatic"
        case .on: return "bolt.fill"
        case .off: return "bolt.slash"
        }
    }
    
    // MARK: - Actions
    
    /// 🚀 高性能拍照流程（Manager协作）
    private func capturePhoto() {
        Task {
            do {
                // 1. 相机硬件拍照（CameraManager单一职责）
                let image = try await cameraManager.capturePhoto()
                
                // 2. 创建Photo实体
                let photo = Photo(
                    image: image,
                    cameraSettings: CameraSettings(
                        flashMode: cameraManager.currentFlashMode,
                        cameraPosition: cameraManager.currentCameraPosition,
                        photoQuality: .high
                    ),
                    fileName: generateFileName()
                )
                
                // 3. 更新UI状态
                await MainActor.run {
                    capturedPhoto = photo
                }
                
                print("📸 照片拍摄成功，尺寸：\(image.size)")
                
            } catch {
                await MainActor.run {
                    cameraManager.errorMessage = "拍照失败：\(error.localizedDescription)"
                }
            }
        }
    }
    
    /// 保存照片到系统相册
    private func savePhotoToGallery(_ photo: Photo) {
        Task {
            do {
                // PhotosManager单一职责：系统相册操作
                try await photosManager.savePhotoToSystemLibrary(photo.image)
                
                await MainActor.run {
                    capturedPhoto = nil // 保存成功后清除
                }
                
                print("📱 照片已保存到系统相册")
                
            } catch {
                await MainActor.run {
                    photosManager.errorMessage = "保存失败：\(error.localizedDescription)"
                }
            }
        }
    }
    
    /// 生成文件名
    private func generateFileName() -> String {
        let timestamp = Date().timeIntervalSince1970
        return "photo_\(Int(timestamp)).jpg"
    }
    
    // MARK: - Photo Preview Area
    
    /// 照片预览区域
    private func photoPreviewArea(_ photo: Photo) -> some View {
        VStack(spacing: 16) {
            // 照片预览
            Image(uiImage: photo.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // 操作按钮
            HStack(spacing: 20) {
                // 重拍按钮
                Button("重拍") {
                    capturedPhoto = nil
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.black.opacity(0.6))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // 保存按钮
                Button("保存到相册") {
                    savePhotoToGallery(photo)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .disabled(photosManager.isLoading)
            }
        }
        .padding()
        .background(.black.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview("🚀 极简高性能相机") {
    SimpleCameraView()
}
