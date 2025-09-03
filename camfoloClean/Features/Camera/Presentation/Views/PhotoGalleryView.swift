//
//  PhotoGalleryView.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI

/// 照片库视图
/// 显示用户拍摄的照片，支持浏览、删除等操作
struct PhotoGalleryView: View {
    @State private var viewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss
    
    // 网格布局配置
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    init(viewModel: CameraViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea(.all)
                
                if viewModel.recentPhotos.isEmpty {
                    emptyStateView
                } else {
                    photoGridView
                }
                
                // 加载覆盖层
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle("Photo Gallery")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        viewModel.refreshPhotos()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Photos Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Take your first photo with the camera")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Open Camera") {
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
        }
        .padding()
    }
    
    // MARK: - Photo Grid View
    
    private var photoGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(viewModel.recentPhotos) { photo in
                    PhotoGridItem(
                        photo: photo,
                        onDelete: {
                            viewModel.deletePhoto(photoId: photo.id)
                        }
                    )
                }
            }
            .padding(.top, 8)
        }
        .refreshable {
            viewModel.refreshPhotos()
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea(.all)
            .overlay(
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            )
    }
}

// MARK: - Photo Grid Item

/// 照片网格项
/// 单个照片的显示组件，支持点击查看和删除操作
struct PhotoGridItem: View {
    let photo: Photo
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    @State private var showingFullScreen = false
    
    var body: some View {
        Button(action: {
            showingFullScreen = true
        }) {
            Image(uiImage: photo.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 120, height: 120)
                .clipped()
                .overlay(
                    // 删除按钮
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                showingDeleteAlert = true
                            }) {
                                Image(systemName: "trash.fill")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.red)
                                    .clipShape(Circle())
                            }
                            .padding(8)
                        }
                        Spacer()
                    }
                    .opacity(0.8)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .alert("Delete Photo", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this photo?")
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
            PhotoDetailView(photo: photo)
        }
    }
}

// MARK: - Photo Detail View

/// 照片详细视图
/// 全屏显示照片，支持缩放和详细信息查看
struct PhotoDetailView: View {
    let photo: Photo
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var showingInfo = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(.all)
            
            VStack {
                // 顶部工具栏
                HStack {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Info") {
                        showingInfo.toggle()
                    }
                    .foregroundColor(.white)
                }
                .padding()
                
                // 照片显示区域
                GeometryReader { geometry in
                    Image(uiImage: photo.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = value
                                }
                                .onEnded { _ in
                                    withAnimation(.spring()) {
                                        if scale < 1.0 {
                                            scale = 1.0
                                        } else if scale > 3.0 {
                                            scale = 3.0
                                        }
                                    }
                                }
                                .simultaneously(with:
                                    DragGesture()
                                        .onChanged { value in
                                            offset = value.translation
                                        }
                                        .onEnded { _ in
                                            withAnimation(.spring()) {
                                                offset = .zero
                                            }
                                        }
                                )
                        )
                }
                
                Spacer()
            }
            
            // 信息面板
            if showingInfo {
                photoInfoPanel
            }
        }
        .statusBarHidden()
    }
    
    // MARK: - Photo Info Panel
    
    private var photoInfoPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Photo Information")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    showingInfo = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(title: "Created", value: formatDate(photo.createdAt))
                InfoRow(title: "File Size", value: formatFileSize(photo.fileSize))
                
                if let settings = photo.cameraSettings {
                    InfoRow(title: "Camera", value: settings.cameraPosition.displayName)
                    InfoRow(title: "Flash", value: settings.flashMode.displayName)
                    InfoRow(title: "Quality", value: settings.photoQuality.displayName)
                }
                
                if let location = photo.location {
                    InfoRow(title: "Location", value: location.placeName ?? "Unknown")
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
        )
        .padding()
        .transition(.opacity.combined(with: .scale))
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// MARK: - Info Row Component

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview

#Preview("Camera View") {
    let mockDIContainer = MockDIContainer()
    let viewModel = mockDIContainer.makeCameraViewModel()
    CameraView(viewModel: viewModel)
        .environmentObject(AppContainer.shared)
}

#Preview("Photo Gallery") {
    let mockDIContainer = MockDIContainer()
    let viewModel = mockDIContainer.makeCameraViewModel()
    PhotoGalleryView(viewModel: viewModel)
        .environmentObject(AppContainer.shared)
}
