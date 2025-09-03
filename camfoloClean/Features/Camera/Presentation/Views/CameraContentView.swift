//
//  CameraContentView.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI
import AVFoundation

/// 相机内容视图
/// 基于Figma设计的相机界面，用于Tab内嵌显示
struct CameraContentView: View {
    @State private var viewModel: CameraViewModel
    let geometry: GeometryProxy
    
    init(viewModel: CameraViewModel, geometry: GeometryProxy) {
        self._viewModel = State(initialValue: viewModel)
        self.geometry = geometry
    }
    
    var body: some View {
        ZStack {
            // 背景图像（从Figma设计提取）
            backgroundImage
            
            // 相机功能覆盖层
            cameraOverlay
            
            // 加载覆盖层
            if viewModel.isLoading {
                loadingOverlay
            }
        }
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
            viewModel.startInitialization()
        }
    }
    
    // MARK: - Background Image
    
    private var backgroundImage: some View {
        Image("main_interface")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .ignoresSafeArea(.all)
    }
    
    // MARK: - Camera Overlay
    
    private var cameraOverlay: some View {
        VStack(spacing: 0) {
            // 主要内容区域
            Spacer()
            
            if !viewModel.hasCheckedPermissions {
                // 权限检查中
                permissionCheckingView
            } else if !viewModel.hasCameraPermission {
                // 权限请求
                permissionRequestView
            } else {
                // 相机功能区域
                cameraFunctionArea
            }
            
            // 为底部Tab Bar预留空间
            Spacer()
                .frame(height: 100) // Tab Bar高度 + 安全区域
        }
    }
    
    // MARK: - Camera Function Area
    
    private var cameraFunctionArea: some View {
        VStack(spacing: 20) {
            // 设置面板区域（基于Figma设计的弹出设置）
            if viewModel.showingSettings {
                settingsPanel
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // 预设选择器区域（基于Figma设计的滤镜选择）
            if viewModel.showingPresets {
                presetsPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // 照片预览区域
            if let photo = viewModel.capturedPhoto {
                photoPreviewArea(photo: photo)
            }
            
            // 拍照控制区域
            captureControlArea
                .padding(.bottom, 20)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showingSettings)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showingPresets)
    }
    
    // MARK: - Settings Panel
    
    private var settingsPanel: some View {
        VStack(spacing: 0) {
            // 设置项列表（基于Figma设计）
            VStack(spacing: 32) {
                settingItem(icon: "timer.off", title: "Timer", action: {})
                settingItem(icon: "flash.auto", title: "Flash", action: {})
                settingItem(icon: "size.1:1", title: "Ratio", action: {})
                settingItem(icon: "swap", title: "Swap", action: {})
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 0)
            )
            
            // 收起按钮
            Button(action: {
                viewModel.toggleSettings()
            }) {
                Image(systemName: "chevron.up")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 20)
    }
    
    private func settingItem(icon: String, title: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 16) {
            // 图标
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "2A2A2C"))
                    .frame(width: 32, height: 32)
            }
            
            // 标题
            Text(title)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(Color(hex: "2A2A2C"))
                .frame(width: 35, alignment: .center)
            
            Spacer()
        }
    }
    
    // MARK: - Presets Panel
    
    private var presetsPanel: some View {
        VStack(spacing: 16) {
            // 预设选择器
            HStack(spacing: 20) {
                presetButton(title: "Classic", isSelected: true)
                presetButton(title: "Glam", isSelected: false)
                presetButton(title: "B&W", isSelected: false)
                presetButton(title: "All", isSelected: false)
            }
            .padding(.horizontal, 40)
            
            // 调整按钮
            Button(action: {}) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }
            
            // 收起按钮
            Button(action: {
                viewModel.togglePresets()
            }) {
                Image(systemName: "chevron.up")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 0)
        )
        .padding(.horizontal, 16)
    }
    
    private func presetButton(title: String, isSelected: Bool) -> some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Circle()
                    .fill(isSelected ? Color(hex: "2A2A2C") : Color(hex: "D8D8D8"))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "camera.filters")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    )
                
                Text(title)
                    .font(.system(size: 8, weight: .regular))
                    .foregroundColor(Color(hex: "2A2A2C"))
            }
        }
    }
    
    // MARK: - Photo Preview Area
    
    @ViewBuilder
    private func photoPreviewArea(photo: Photo) -> some View {
        VStack(spacing: 16) {
            Image(uiImage: photo.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .cornerRadius(12)
                .padding(.horizontal, 20)
            
            HStack(spacing: 20) {
                Button("Retake") {
                    viewModel.clearCapturedPhoto()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Save") {
                    viewModel.saveCurrentPhotoToGallery()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Capture Control Area
    
    private var captureControlArea: some View {
        HStack {
            // 最近照片缩略图
            recentPhotoThumbnail
            
            Spacer()
            
            VStack(spacing: 16) {
                // 拍照按钮
                if viewModel.capturedPhoto == nil {
                    captureButton
                }
                
                // 设置和滤镜按钮
                HStack(spacing: 32) {
                    // 焦距控制按钮
                    Button(action: {}) {
                        Image(systemName: "viewfinder")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                            )
                    }
                    
                    // 翻转相机按钮
                    Button(action: {
                        viewModel.toggleCameraPosition()
                    }) {
                        Image(systemName: "camera.rotate")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.clear)
                    }
                }
            }
            
            Spacer()
            
            // 设置按钮（空占位，保持布局平衡）
            Rectangle()
                .fill(Color.clear)
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 30)
    }
    
    private var recentPhotoThumbnail: some View {
        Group {
            if let recentPhoto = viewModel.recentPhotos.first {
                Button(action: {}) {
                    Image(uiImage: recentPhoto.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 32, height: 32)
            }
        }
    }
    
    private var captureButton: some View {
        Button(action: {
            viewModel.capturePhoto()
        }) {
            ZStack {
                // 外圈
                Circle()
                    .stroke(Color.white, lineWidth: 5)
                    .frame(width: 72, height: 72)
                
                // 内圈
                Circle()
                    .fill(Color(hex: "ADAFB3").opacity(0.3))
                    .frame(width: 52, height: 52)
            }
        }
        .disabled(viewModel.isLoading)
        .scaleEffect(viewModel.isLoading ? 0.9 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: viewModel.isLoading)
    }
    
    // MARK: - Permission Views
    
    private var permissionCheckingView: some View {
        VStack(spacing: 24) {
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
        }
        .padding()
    }
    
    private var permissionRequestView: some View {
        VStack(spacing: 24) {
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
}

#Preview {
    GeometryReader { geometry in
        let mockDIContainer = MockDIContainer()
        let viewModel = mockDIContainer.makeCameraViewModel()
        CameraContentView(viewModel: viewModel, geometry: geometry)
            .environmentObject(AppContainer.shared)
    }
}
