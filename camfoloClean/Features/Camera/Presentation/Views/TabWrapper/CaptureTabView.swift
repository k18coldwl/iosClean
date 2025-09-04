//
//  CaptureTabView.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI

/// 🚀 高性能Capture Tab视图
/// 使用Manager模式，零抽象开销
struct CaptureTabView: View {
    @EnvironmentObject private var appContainer: AppContainer
    
    var body: some View {
        // 🚀 极简架构：直接使用高性能相机视图
        appContainer.makeHighPerformanceCameraView()
    }
}
