//
//  CaptureTabView.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI

/// Capture Tab内容视图
/// 负责显示相机功能界面
struct CaptureTabView: View {
    @EnvironmentObject private var appContainer: AppContainer
    @State private var cameraViewModel: CameraViewModel?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 使用CameraView的核心功能
                if let viewModel = cameraViewModel {
                    CameraContentView(viewModel: viewModel, geometry: geometry)
                } else {
                    // 加载状态
                    loadingView
                }
            }
        }
        .ignoresSafeArea(.all)
        .clipped()
        .onAppear {
            initializeCameraViewModel()
        }
    }
    
    // MARK: - View Components
    
    private var loadingView: some View {
        VStack {
            ProgressView("Loading Camera...")
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // MARK: - Private Methods
    
    private func initializeCameraViewModel() {
        if cameraViewModel == nil {
            cameraViewModel = appContainer.diContainer.makeCameraViewModel()
        }
    }
}
