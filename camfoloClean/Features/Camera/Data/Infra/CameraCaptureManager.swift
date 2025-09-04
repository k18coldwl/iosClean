import Foundation
import GPUImage

@MainActor
final class CameraCaptureManager {
    let camera: Camera
    private var activeConnections: Set<ObjectIdentifier> = []
    
    init() {
        camera = try! Camera(sessionPreset: .hd1280x720)
        camera.runBenchmark = false
        try? camera.startCapture()
    }
    
    /// 为主预览绑定滤镜
    func bindMainPreview(to renderView: RenderView, with filter: BasicOperation) {
        // 对于主预览，我们可以安全地重新连接
        camera.removeAllTargets()
        camera --> filter --> renderView
        
        // 重新连接所有活跃的预览连接
        // （这里需要你确认 GPUImage3 是否支持多目标连接）
    }
    
    /// 添加预览连接
    func addPreviewConnection(filter: BasicOperation, renderView: RenderView) {
        let connectionId = ObjectIdentifier(renderView)
        if !activeConnections.contains(connectionId) {
            camera --> filter --> renderView
            activeConnections.insert(connectionId)
        }
    }
    
    /// 移除预览连接
    func removePreviewConnection(renderView: RenderView) {
        let connectionId = ObjectIdentifier(renderView)
        if activeConnections.contains(connectionId) {
            // 移除特定连接（需要确认 GPUImage3 的具体方法）
            renderView.removeFromSuperview() // 临时方案
            activeConnections.remove(connectionId)
        }
    }
}
