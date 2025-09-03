//
//  CameraView.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI
import AVFoundation

/// 相机主视图
/// 提供完整的相机拍照界面，包含预览、拍照控制和设置
struct CameraView: View {
    @State private var viewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: CameraViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景色
                Color.black
                    .ignoresSafeArea(.all)
                
                if !viewModel.hasCheckedPermissions {
                    // 权限检查中，显示加载界面
                    permissionCheckingView
                } else if viewModel.hasCameraPermission {
                    // 相机界面
                    cameraInterface(geometry: geometry)
                } else {
                    // 权限请求界面
                    permissionRequestView
                }
                
                // 加载覆盖层
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden()
        .alert("Camera Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            // 当CameraView显示时启动初始化
            viewModel.startInitialization()
        }
    }
    
    // MARK: - Camera Interface
    
    @ViewBuilder
    private func cameraInterface(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // 顶部控制栏
            topControlBar
                .padding(.top, geometry.safeAreaInsets.top)
            
            // 相机预览区域
            Spacer()
            
            // 如果有拍摄的照片，显示照片预览
            if let photo = viewModel.capturedPhoto {
                photoPreviewSection(photo: photo)
            } else {
                // 相机预览占位
                cameraPreviewPlaceholder
            }
            
            Spacer()
            
            // 底部控制栏
            bottomControlBar
                .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
        }
    }
    
    // MARK: - Top Control Bar
    
    private var topControlBar: some View {
        HStack {
            // 关闭按钮
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // 闪光灯控制
            flashControl
            
            // 相机切换按钮
            Button(action: {
                viewModel.toggleCameraPosition()
            }) {
                Image(systemName: "camera.rotate")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var flashControl: some View {
        Button(action: {
            cycleFlashMode()
        }) {
            Image(systemName: flashIcon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
        }
    }
    
    private var flashIcon: String {
        switch viewModel.cameraSettings.flashMode {
        case .auto:
            return "bolt.badge.automatic"
        case .on:
            return "bolt.fill"
        case .off:
            return "bolt.slash"
        }
    }
    
    // MARK: - Camera Preview
    
    private var cameraPreviewPlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(maxWidth: .infinity)
            .aspectRatio(4/3, contentMode: .fit)
            .overlay(
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Camera Preview")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                }
            )
            .cornerRadius(12)
            .padding(.horizontal, 20)
    }
    
    // MARK: - Photo Preview Section
    
    @ViewBuilder
    private func photoPreviewSection(photo: Photo) -> some View {
        VStack(spacing: 16) {
            // 照片预览
            Image(uiImage: photo.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .cornerRadius(12)
                .padding(.horizontal, 20)
            
            // 照片操作按钮
            HStack(spacing: 20) {
                // 重新拍摄
                Button("Retake") {
                    viewModel.clearCapturedPhoto()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                // 保存到相册
                Button("Save") {
                    viewModel.saveCurrentPhotoToGallery()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Bottom Control Bar
    
    private var bottomControlBar: some View {
        HStack {
            // 最近照片缩略图
            recentPhotoThumbnail
            
            Spacer()
            
            // 拍照按钮
            if viewModel.capturedPhoto == nil {
                captureButton
            }
            
            Spacer()
            
            // 设置按钮
            settingsButton
        }
        .padding(.horizontal, 30)
    }
    
    private var recentPhotoThumbnail: some View {
        Group {
            if let recentPhoto = viewModel.recentPhotos.first {
                Button(action: {
                    // 可以导航到照片库
                }) {
                    Image(uiImage: recentPhoto.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 50, height: 50)
            }
        }
    }
    
    private var captureButton: some View {
        Button(action: {
            viewModel.capturePhoto()
        }) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 90, height: 90)
            }
        }
        .disabled(viewModel.isLoading)
        .scaleEffect(viewModel.isLoading ? 0.9 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: viewModel.isLoading)
    }
    
    private var settingsButton: some View {
        Button(action: {
            // 可以显示设置面板
        }) {
            Image(systemName: "gearshape.fill")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
        }
    }
    
    // MARK: - Permission Checking View
    
    private var permissionCheckingView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            
            VStack(spacing: 8) {
                Text("Checking Camera Access")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Please wait while we check camera permissions")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Permission Request View
    
    private var permissionRequestView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "camera.fill")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.7))
            
            VStack(spacing: 12) {
                Text("Camera Access Required")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Please allow camera access to take photos")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            Button("Grant Permission") {
                viewModel.requestCameraPermission()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea(.all)
            .overlay(
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            )
    }
    
    // MARK: - Helper Methods
    
    private func cycleFlashMode() {
        let allModes = FlashMode.allCases
        let currentIndex = allModes.firstIndex(of: viewModel.cameraSettings.flashMode) ?? 0
        let nextIndex = (currentIndex + 1) % allModes.count
        viewModel.updateFlashMode(allModes[nextIndex])
    }
}





// MARK: - Preview

#Preview {
    let mockDIContainer = MockDIContainer()
    let viewModel = mockDIContainer.makeCameraViewModel()
    CameraView(viewModel: viewModel)
        .environmentObject(AppContainer.shared)
}
