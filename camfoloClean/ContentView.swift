//
//  ContentView.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI
import SwiftData
import os.log

/// 应用主界面
/// 提供相机和相册功能的入口，使用Clean Architecture管理依赖
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appContainer: AppContainer
    
    // MARK: - State Properties
    
    @State private var showingCamera = false
    @State private var showingGallery = false
    
    // MARK: - Logging
    
    /// 统一日志记录器
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "camfoloClean",
        category: "ContentView"
    )
    
    // MARK: - Body

    var body: some View {
        NavigationView {
            mainContent
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(viewModel: appContainer.diContainer.makeCameraViewModel())
        }
        .sheet(isPresented: $showingGallery) {
            PhotoGalleryView(viewModel: appContainer.diContainer.makeCameraViewModel())
        }
    }
    
    // MARK: - View Components
    
    /// 主界面内容
    private var mainContent: some View {
        VStack {
            Spacer()
            
            welcomeSection
            
            Spacer()
            
            actionButtons
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("CamFolo")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// 欢迎文本区域
    private var welcomeSection: some View {
        VStack(spacing: 12) {
            Text("Welcome to CamFolo")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your camera companion app")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    /// 功能按钮区域
    private var actionButtons: some View {
        VStack(spacing: 20) {
            Button("Open Camera") {
                Self.logger.info("Open Camera button pressed")
                showingCamera = true
            }
            .buttonStyle(PrimaryButtonStyle())
            
            Button("Photo Gallery") {
                Self.logger.info("Photo Gallery button pressed")
                showingGallery = true
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(.horizontal)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppContainer.shared)
}
