import SwiftUI
import GPUImage

@MainActor
@Observable
final class CameraViewModel {
    var filterItems: [FilterPreviewItem] = []
    var selectedFilterID: String?
    
    let cameraManager = CameraCaptureManager()
    var mainRenderView: RenderView = RenderView(frame: .zero)
    
    // 使用优化的预览管理器
    private let previewManager = OptimizedPreviewManager()
    
    // 性能控制
    private var maxConcurrentPreviews = 8
    private var pendingActivations: [(FilterPreviewItem, (RenderView) -> Void)] = []
    
        // 公开的状态属性
    var currentActiveCount: Int {
        previewManager.activeConnectionCount
    }
    
    var maxConcurrentCount: Int {
        maxConcurrentPreviews
    }

    init() {
        setupFilters()
        activateMainPreview()
        setupPerformanceMonitoring()
    }
    
    deinit {
        //previewManager.cleanup()
    }
    
    private func setupFilters() {
        filterItems = [
            FilterPreviewItem(id: "0", name: "Sepia", filter: Vignette()),
            FilterPreviewItem(id: "1", name: "Grayscale", filter: SaturationAdjustment()),
            FilterPreviewItem(id: "2", name: "Vignette", filter: Vignette()),
            FilterPreviewItem(id: "3", name: "Invert", filter: ColorInversion()),
            FilterPreviewItem(id: "4", name: "Pixel", filter: Pixellate()),
            FilterPreviewItem(id: "5", name: "Brightness", filter: BrightnessAdjustment()),
            FilterPreviewItem(id: "6", name: "Sketch", filter: Pixellate()),
            FilterPreviewItem(id: "7", name: "Emboss", filter: Vignette())
        ]
        selectedFilterID = filterItems.first?.id
    }
    
    private func activateMainPreview() {
        guard let first = filterItems.first else { return }
        let mainFilter = createMainFilterInstance(from: first.filter)
        cameraManager.bindMainPreview(to: mainRenderView, with: mainFilter)
    }
    
    // MARK: - 预览管理
    
    func requestPreviewActivation(item: FilterPreviewItem, completion: @escaping (RenderView) -> Void) {
        // 检查并发限制
        if previewManager.activeConnectionCount >= maxConcurrentPreviews {
            // 加入等待队列
            pendingActivations.append((item, completion))
            print("📱 预览请求加入队列: \(item.name)")
            return
        }
        
        // 立即激活
        activatePreviewInternal(item: item, completion: completion)
    }
    
    private func activatePreviewInternal(item: FilterPreviewItem, completion: @escaping (RenderView) -> Void) {
        let renderView = previewManager.activatePreview(item: item, cameraManager: cameraManager)
        completion(renderView)
        
        print("📱 预览已激活: \(item.name), 当前活跃数: \(previewManager.activeConnectionCount)")
    }
    
    func deactivatePreview(renderView: RenderView) {
        previewManager.deactivatePreview(renderView: renderView)
        
        // 处理等待队列
        if let (pendingItem, pendingCompletion) = pendingActivations.first {
            pendingActivations.removeFirst()
            activatePreviewInternal(item: pendingItem, completion: pendingCompletion)
        }
        
        print("📱 预览已停用, 当前活跃数: \(previewManager.activeConnectionCount)")
    }
    
    func pausePreview(renderView: RenderView) {
        previewManager.pausePreview(renderView: renderView)
    }
    
    func resumePreview(renderView: RenderView) {
        previewManager.resumePreview(renderView: renderView, cameraManager: cameraManager)
    }
    
    func selectFilter(item: FilterPreviewItem) {
        selectedFilterID = item.id
        let filterInstance = createMainFilterInstance(from: item.filter)
        cameraManager.bindMainPreview(to: mainRenderView, with: filterInstance)
        
        print("📱 主滤镜已切换: \(item.name)")
    }
    
    // MARK: - 滤镜实例创建
    
    private func createMainFilterInstance(from template: BasicOperation) -> BasicOperation {
        // 主预览使用独立的滤镜实例，不与预览共享
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
            return Pixellate()
        }
    }
    
    // MARK: - 性能优化
    
    private func setupPerformanceMonitoring() {
//        Task {
//            for await _ in NotificationCenter.default.notifications(
//                named: ProcessInfo.thermalStateDidChangeNotification
//            ) {
//                await adjustPerformanceSettings()
//            }
//        }
    }
    
    func adjustPerformanceSettings() {
        let thermalState = ProcessInfo.processInfo.thermalState
        let newMaxPreviews: Int
        
        switch thermalState {
        case .critical:
            newMaxPreviews = 2
        case .serious:
            newMaxPreviews = 3
        case .fair:
            newMaxPreviews = 4
        case .nominal:
            newMaxPreviews = 6
        @unknown default:
            newMaxPreviews = 4
        }
        
        if newMaxPreviews < maxConcurrentPreviews {
            // 需要减少活跃预览数量
            let excessCount = previewManager.activeConnectionCount - newMaxPreviews
            // 这里可以暂停最老的或最不重要的预览
            print("📱 热状态变化，需要减少 \(excessCount) 个预览")
        }
        
        maxConcurrentPreviews = newMaxPreviews
        print("📱 性能设置已调整: 最大并发预览 \(maxConcurrentPreviews)")
    }
    
    // MARK: - 调试信息
    
    var debugInfo: String {
        """
        活跃预览: \(previewManager.activeConnectionCount)/\(maxConcurrentPreviews)
        等待队列: \(pendingActivations.count)
        热状态: \(ProcessInfo.processInfo.thermalState.rawValue)
        """
    }
}
