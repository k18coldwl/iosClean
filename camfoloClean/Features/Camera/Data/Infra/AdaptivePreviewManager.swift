import GPUImage

public enum PreviewMode {
    case fullRealtime
    case hybrid
}

public final class AdaptivePreviewManager {
    private let camera: Camera
    private var mainRenderView: RenderView?
    private var previewRenderViews: [String: RenderView] = [:]
    private let previewMode: PreviewMode
    private let maxRealtimePreviews: Int
    
    public init(camera: Camera) {
        self.camera = camera
        self.previewMode = AdaptivePreviewManager.detectDeviceMode()
        self.maxRealtimePreviews = (previewMode == .fullRealtime) ? 8 : 3
    }

    public func attachMainRenderView(_ renderView: RenderView) {
        self.mainRenderView = renderView
    }

    public func setMainFilter(_ graph: FilterGraphDescription) {
        camera.removeAllTargets()
        let filters = buildFilterChain(from: graph)
        camera --> filters.first!
        filters.last! --> mainRenderView!
    }

    public func updateVisiblePreviews(_ items: [FilterPreviewItem]) {
        let realtimeItems = Array(items.prefix(maxRealtimePreviews))
        let staticItems = Array(items.dropFirst(maxRealtimePreviews))
        
        for item in realtimeItems {
            let renderView = previewRenderViews[item.id] ?? RenderView()
            previewRenderViews[item.id] = renderView
            let filters = buildFilterChain(from: item.filterGraph, lowRes: true)
            camera --> filters.first!
            filters.last! --> renderView
        }
        
        for item in staticItems {
            let renderView = previewRenderViews[item.id] ?? RenderView()
            previewRenderViews[item.id] = renderView
            let snapshot = generateThumbnail(filter: item.filterGraph)
            renderView.image = snapshot
        }
    }

    private static func detectDeviceMode() -> PreviewMode {
        let device = UIDevice.current
        return device.hasA14OrAbove ? .fullRealtime : .hybrid
    }

    private func buildFilterChain(from graph: FilterGraphDescription, lowRes: Bool = false) -> [ImageProcessingOperation] {
        var filters: [ImageProcessingOperation] = []
        // TODO: 映射 graph -> GPUImage Filter
        return filters
    }

    private func generateThumbnail(filter: FilterGraphDescription) -> UIImage {
        return UIImage()
    }
}
