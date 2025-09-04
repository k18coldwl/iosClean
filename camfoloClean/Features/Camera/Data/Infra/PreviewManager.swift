import SwiftUI
import GPUImage

// MARK: - 滤镜池管理器
@MainActor
final class FilterPool {
    private var availableFilters: [String: [BasicOperation]] = [:]
    private var usedFilters: [ObjectIdentifier: (String, BasicOperation)] = [:]
    private let maxPoolSize = 3 // 每种滤镜最多缓存3个实例
    
    func borrowFilter(for filterType: String, renderView: RenderView) -> BasicOperation {
        let renderViewId = ObjectIdentifier(renderView)
        
        // 检查是否已经分配了滤镜
        if let (existingType, existingFilter) = usedFilters[renderViewId] {
            if existingType == filterType {
                return existingFilter // 复用现有滤镜
            } else {
                // 类型不同，归还旧滤镜，借用新滤镜
                returnFilter(renderView: renderView)
            }
        }
        
        // 从池中获取或创建新滤镜
        let filter = getOrCreateFilter(filterType: filterType)
        usedFilters[renderViewId] = (filterType, filter)
        
        return filter
    }
    
    func returnFilter(renderView: RenderView) {
        let renderViewId = ObjectIdentifier(renderView)
        
        guard let (filterType, filter) = usedFilters.removeValue(forKey: renderViewId) else {
            return
        }
        
        // 清理滤镜状态
        filter.removeAllTargets()
        
        // 归还到池中
        if availableFilters[filterType] == nil {
            availableFilters[filterType] = []
        }
        
        if availableFilters[filterType]!.count < maxPoolSize {
            availableFilters[filterType]!.append(filter)
        }
        // 超过池大小限制的滤镜会被自动释放
    }
    
    private func getOrCreateFilter(filterType: String) -> BasicOperation {
        // 先从池中获取
        if let filters = availableFilters[filterType], !filters.isEmpty {
            return availableFilters[filterType]!.removeFirst()
        }
        
        // 池中没有，创建新实例
        return createNewFilter(filterType: filterType)
    }
    
    private func createNewFilter(filterType: String) -> BasicOperation {
        switch filterType {
        case "SepiaTone":
            return Pixellate()
        case "Grayscale":
            return SaturationAdjustment()
        case "Vignette":
            return Vignette()
        case "ColorInversion":
            return ColorInversion()
        case "Pixellate":
            return Pixellate()
        case "BrightnessAdjustment":
            return BrightnessAdjustment()
        case "Sketch":
            return Pixellate()
        case "Emboss":
            return Pixellate()
        default:
            return Pixellate()
        }
    }
    
    // 清理所有资源
    func cleanup() {
        // 归还所有正在使用的滤镜
        for renderViewId in usedFilters.keys {
            if let renderView = findRenderView(by: renderViewId) {
                returnFilter(renderView: renderView)
            }
        }
        
        // 清空池
        availableFilters.removeAll()
        usedFilters.removeAll()
    }
    
    private func findRenderView(by id: ObjectIdentifier) -> RenderView? {
        // 这里需要根据你的实际情况来实现
        // 暂时返回 nil，表示无法找到对应的 RenderView
        return nil
    }
}

// MARK: - RenderView 池管理器
@MainActor
final class RenderViewPool {
    private var availableViews: [RenderView] = []
    private var usedViews: Set<ObjectIdentifier> = []
    private let maxPoolSize = 8 // 最多缓存8个视图
    private let renderViewSize = CGSize(width: 80, height: 80)
    
    func borrowRenderView() -> RenderView {
        if !availableViews.isEmpty {
            let renderView = availableViews.removeFirst()
            usedViews.insert(ObjectIdentifier(renderView))
            return renderView
        }
        
        // 创建新的 RenderView
        let frame = CGRect(origin: .zero, size: renderViewSize)
        let renderView = RenderView(frame: frame)
        usedViews.insert(ObjectIdentifier(renderView))
        
        return renderView
    }
    
    func returnRenderView(_ renderView: RenderView) {
        let renderViewId = ObjectIdentifier(renderView)
        
        guard usedViews.contains(renderViewId) else {
            return // 不是我们管理的视图
        }
        
        usedViews.remove(renderViewId)
        
        // 清理视图状态
        renderView.removeFromSuperview()
        
        // 归还到池中
        if availableViews.count < maxPoolSize {
            availableViews.append(renderView)
        }
        // 超过池大小的视图会被自动释放
    }
    
    func cleanup() {
        for renderView in availableViews {
            renderView.removeFromSuperview()
        }
        availableViews.removeAll()
        usedViews.removeAll()
    }
}

// MARK: - 优化的预览管理器
@MainActor
final class OptimizedPreviewManager {
    private let filterPool = FilterPool()
    private let renderViewPool = RenderViewPool()
    private var activeConnections: [ObjectIdentifier: PreviewConnection] = [:]
    
    struct PreviewConnection {
        let renderView: RenderView
        let filter: BasicOperation
        let filterType: String
        var isActive: Bool
    }
    
    func activatePreview(
        item: FilterPreviewItem,
        cameraManager: CameraCaptureManager
    ) -> RenderView {
        let renderView = renderViewPool.borrowRenderView()
        let filter = filterPool.borrowFilter(for: item.name, renderView: renderView)
        let renderViewId = ObjectIdentifier(renderView)
        
        // 建立连接
        cameraManager.addPreviewConnection(filter: filter, renderView: renderView)
        
        // 记录连接信息
        activeConnections[renderViewId] = PreviewConnection(
            renderView: renderView,
            filter: filter,
            filterType: item.name,
            isActive: true
        )
        
        return renderView
    }
    
    func deactivatePreview(renderView: RenderView) {
        let renderViewId = ObjectIdentifier(renderView)
        
        guard let connection = activeConnections.removeValue(forKey: renderViewId) else {
            return
        }
        
        // 断开连接
        connection.filter.removeAllTargets()
        
        // 归还资源
        filterPool.returnFilter(renderView: renderView)
        renderViewPool.returnRenderView(renderView)
    }
    
    func pausePreview(renderView: RenderView) {
        let renderViewId = ObjectIdentifier(renderView)
        
        if var connection = activeConnections[renderViewId] {
            connection.filter.removeAllTargets()
            connection.isActive = false
            activeConnections[renderViewId] = connection
        }
    }
    
    func resumePreview(renderView: RenderView, cameraManager: CameraCaptureManager) {
        let renderViewId = ObjectIdentifier(renderView)
        
        if var connection = activeConnections[renderViewId], !connection.isActive {
            cameraManager.addPreviewConnection(filter: connection.filter, renderView: renderView)
            connection.isActive = true
            activeConnections[renderViewId] = connection
        }
    }
    
    func cleanup() {
        // 清理所有活跃连接
        for connection in activeConnections.values {
            connection.filter.removeAllTargets()
            renderViewPool.returnRenderView(connection.renderView)
        }
        activeConnections.removeAll()
        
        // 清理池
        filterPool.cleanup()
        renderViewPool.cleanup()
    }
    
    // 获取当前活跃连接数
    var activeConnectionCount: Int {
        activeConnections.values.filter { $0.isActive }.count
    }
}

// MARK: - 优化的 FilterPreviewItem
extension FilterPreviewItem {
    var filterTypeName: String {
        switch filter {
        case is SaturationAdjustment:
            return "Grayscale"
        case is Vignette:
            return "Vignette"
        case is ColorInversion:
            return "ColorInversion"
        case is Pixellate:
            return "Pixellate"
        case is BrightnessAdjustment:
            return "BrightnessAdjustment"
        default:
            return "BasicOperation"
        }
    }
}
