import SwiftUI
import GPUImage

@MainActor
@Observable
final class CameraViewModel {
    var filterItems: [FilterPreviewItem] = []
    var selectedFilterID: String?
    
    let cameraManager = CameraCaptureManager()
    var mainRenderView: RenderView = RenderView(frame: .zero)
    
    // 使用 actor 管理并发状态
    private let previewManager = PreviewManager()
    private var activeRenderViews: [RenderView: FilterPreviewItem] = [:]
    
    // 性能控制
    private var maxConcurrentPreviews = 4
    private var currentActiveCount = 0
    
    init() {
        Task {
            await setupFilters()
            await activateMainPreview()
        }
    }
    
    private func setupFilters() async {
        filterItems = [
            FilterPreviewItem(id: "0", name: "Sepia", filter: SaturationAdjustment()),
            FilterPreviewItem(id: "1", name: "Grayscale", filter: SaturationAdjustment()),
            FilterPreviewItem(id: "2", name: "Vignette", filter: Vignette()),
            FilterPreviewItem(id: "3", name: "Invert", filter: ColorInversion()),
            FilterPreviewItem(id: "4", name: "Pixel", filter: Pixellate()),
            FilterPreviewItem(id: "5", name: "Brightness", filter: BrightnessAdjustment()),
            FilterPreviewItem(id: "6", name: "Sketch", filter: SaturationAdjustment()),
            FilterPreviewItem(id: "7", name: "Emboss", filter: SaturationAdjustment())
        ]
        selectedFilterID = filterItems.first?.id
    }
    
    private func activateMainPreview() async {
        guard let first = filterItems.first else { return }
        cameraManager.bindMainPreview(to: mainRenderView, with: first.filter)
    }
    
    func activatePreview(item: FilterPreviewItem, renderView: RenderView) {
        // 检查并发限制
        guard currentActiveCount < maxConcurrentPreviews else {
            print("达到最大并发预览限制")
            return
        }
        
        Task {
            await previewManager.activatePreview(
                item: item,
                renderView: renderView,
                cameraManager: cameraManager
            )
            
            activeRenderViews[renderView] = item
            currentActiveCount += 1
        }
    }
    
    func deactivatePreview(renderView: RenderView) {
        Task {
            await previewManager.deactivatePreview(renderView: renderView)
            
            if activeRenderViews.removeValue(forKey: renderView) != nil {
                currentActiveCount -= 1
            }
        }
    }
    
    func selectFilter(item: FilterPreviewItem) {
        selectedFilterID = item.id
        
        Task {
            let filterInstance = await previewManager.createFilterInstance(from: item.filter)
            cameraManager.bindMainPreview(to: mainRenderView, with: filterInstance)
        }
    }
    
    // 动态调整性能设置
    func adjustPerformanceSettings() {
        let thermalState = ProcessInfo.processInfo.thermalState
        
        switch thermalState {
        case .critical:
            maxConcurrentPreviews = 2
        case .serious:
            maxConcurrentPreviews = 3
        case .fair:
            maxConcurrentPreviews = 4
        case .nominal:
            maxConcurrentPreviews = 6
        @unknown default:
            maxConcurrentPreviews = 4
        }
        
        // 如果当前活跃数量超过新限制，暂停一些预览
        if currentActiveCount > maxConcurrentPreviews {
            pauseExcessPreviews()
        }
    }
    
    private func pauseExcessPreviews() {
        let excessCount = currentActiveCount - maxConcurrentPreviews
        let renderViewsToDeactivate = Array(activeRenderViews.keys.prefix(excessCount))
        
        for renderView in renderViewsToDeactivate {
            deactivatePreview(renderView: renderView)
        }
    }
}
