// Features/Camera/Infra/CameraCaptureManager.swift
import Foundation
import GPUImage
import Combine

final class CameraCaptureManager: ObservableObject {
    let camera: Camera
    @Published var currentFrame: PictureInput? // 如果只做小窗口处理，可以不用
    
    init() {
        camera = try! Camera(sessionPreset: .hd1280x720)
        camera.runBenchmark = false
        try? camera.startCapture()
    }
    
    /// 将 Camera 输出直接绑定到 RenderView
    func bind(to renderView: RenderView, with filter: BasicOperation) {
        camera --> filter --> renderView
    }
    
    /// 切换滤镜
    func switchFilter(_ newFilter: BasicOperation, renderView: RenderView) {
        camera.removeAllTargets()
        camera --> newFilter --> renderView
    }
}
