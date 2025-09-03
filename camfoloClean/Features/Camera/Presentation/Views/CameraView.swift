//
//  CameraView.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI
import AVFoundation

/// 简化的相机视图（仅用于独立显示）
/// 现在主要功能已移到CameraContentView用于Tab显示
struct CameraView: View {
    @State private var viewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: CameraViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        GeometryReader { geometry in
            CameraContentView(viewModel: viewModel, geometry: geometry)
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
            viewModel.startInitialization()
        }
    }
}

// MARK: - Preview

#Preview {
    let mockDIContainer = MockDIContainer()
    let viewModel = mockDIContainer.makeCameraViewModel()
    CameraView(viewModel: viewModel)
        .environmentObject(AppContainer.shared)
}