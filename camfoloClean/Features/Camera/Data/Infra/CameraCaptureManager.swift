import Foundation
import GPUImage

@MainActor
final class ImprovedCameraCaptureManager {
    let camera: Camera
    private var connections: [ObjectIdentifier: (BasicOperation, RenderView)] = [:]
    private var mainConnection: (BasicOperation, RenderView)?
    
    init() {
        camera = try! Camera(sessionPreset: .hd1280x720)
        camera.runBenchmark = false
        try? camera.startCapture()
    }
    
    func bindMainPreview(to renderView: RenderView, with filter: BasicOperation) {
        // 移除旧的主连接
        if let oldConnection = mainConnection {
            oldConnection.0.removeAllTargets()
        }
        
        // 建立新的主连接
        camera --> filter --> renderView
        mainConnection = (filter, renderView)
        
        print("📱 主预览已连接: \(type(of: filter))")
    }
    
    func addPreviewConnection(filter: BasicOperation, renderView: RenderView) {
        let connectionId = ObjectIdentifier(renderView)
        
        // 移除可能存在的旧连接
        if let oldConnection = connections[connectionId] {
            oldConnection.0.removeAllTargets()
        }
        
        // 建立新连接
        camera --> filter --> renderView
        connections[connectionId] = (filter, renderView)
        
        print("📱 预览连接已添加: \(type(of: filter)), 总连接数: \(connections.count)")
    }
    
    func removePreviewConnection(filter: BasicOperation, renderView: RenderView) {
        let connectionId = ObjectIdentifier(renderView)
        
        if let connection = connections.removeValue(forKey: connectionId) {
            connection.0.removeAllTargets()
            print("📱 预览连接已移除: \(type(of: filter)), 剩余连接数: \(connections.count)")
        }
    }
    
    func reconnectAll() {
        // 重新连接所有现有连接（用于故障恢复）
        print("🔄 重新连接所有预览...")
        
        // 重连主预览
        if let mainConn = mainConnection {
            camera --> mainConn.0 --> mainConn.1
        }
        
        // 重连所有预览连接
        for (_, connection) in connections {
            camera --> connection.0 --> connection.1
        }
    }
}
