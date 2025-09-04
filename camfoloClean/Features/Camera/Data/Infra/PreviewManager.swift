import GPUImage

@MainActor
final class PreviewManager {
    private var filterInstances: [ObjectIdentifier: BasicOperation] = [:]
    
    func activatePreview(
        item: FilterPreviewItem,
        renderView: RenderView,
        cameraManager: CameraCaptureManager
    ) {
        let renderViewId = ObjectIdentifier(renderView)
        
        // 创建滤镜实例
        let filterInstance = createFilterInstance(from: item.filter)
        filterInstances[renderViewId] = filterInstance
        
        // 直接在主线程上执行
        cameraManager.addPreviewConnection(filter: filterInstance, renderView: renderView)
    }
    
    func deactivatePreview(renderView: RenderView) {
        let renderViewId = ObjectIdentifier(renderView)
        
        if let filterInstance = filterInstances.removeValue(forKey: renderViewId) {
            // 清理滤镜连接
            filterInstance.removeAllTargets()
        }
    }
    
    func createFilterInstance(from template: BasicOperation) -> BasicOperation {
        switch template {
        case is SaturationAdjustment:
            return SaturationAdjustment()
        case is Vignette:
            return Vignette()
        case is ColorInversion:
            return ColorInversion()
        case is Pixellate:
            return Pixellate()
        case is BrightnessAdjustment:
            return BrightnessAdjustment()
        default:
            return Vignette()
        }
    }
}
