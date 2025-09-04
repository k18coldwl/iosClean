// Features/Camera/Presentation/CameraViewModel.swift
import SwiftUI
import GPUImage

@MainActor
final class CameraViewModel: ObservableObject {
    @Published var filterItems: [FilterPreviewItem] = []
    @Published var selectedFilterID: String?
    
    let cameraManager = CameraCaptureManager()
    let filterRenderer = FilterRenderer()
    
    var mainRenderView: RenderView = RenderView(frame: .zero)
    private var activeRenderViews: Set<RenderView> = []
    
    init() {
        setupFilters()
        observeCameraFrames()
    }
    
    private func setupFilters() {
        filterItems = [
            FilterPreviewItem(id: "0", name: "Sepia", filter: SepiaTone()),
            FilterPreviewItem(id: "1", name: "Grayscale", filter: SaturationAdjustment(saturation: 0)),
            FilterPreviewItem(id: "2", name: "Vignette", filter: Vignette()),
            FilterPreviewItem(id: "3", name: "Invert", filter: ColorInversion()),
            FilterPreviewItem(id: "4", name: "Pixel", filter: Pixellate()),
            FilterPreviewItem(id: "5", name: "Brightness", filter: BrightnessAdjustment()),
            FilterPreviewItem(id: "6", name: "Sketch", filter: Sketch()),
            FilterPreviewItem(id: "7", name: "Emboss", filter: Emboss())
        ]
        selectedFilterID = filterItems.first?.id
    }
    
    private func observeCameraFrames() {
        cameraManager.$currentFrame.sink { [weak self] frame in
            guard let self = self, let frame = frame else { return }
            if let selected = self.filterItems.first(where: { $0.id == self.selectedFilterID }) {
                self.filterRenderer.renderMain(frame: frame, filter: selected.filter, renderView: self.mainRenderView)
            }
        }
        .store(in: &cancellables)
    }
    
    func activatePreview(item: FilterPreviewItem, renderView: RenderView, frame: PictureInput) {
        activeRenderViews.insert(renderView)
        filterRenderer.renderPreview(frame: frame, filter: item.filter, renderView: renderView)
    }
    
    func deactivate(renderView: RenderView) {
        filterRenderer.release(renderView: renderView)
        activeRenderViews.remove(renderView)
    }
    
    func selectFilter(item: FilterPreviewItem) {
        selectedFilterID = item.id
        guard let frame = cameraManager.currentFrame else { return }
        filterRenderer.renderMain(frame: frame, filter: item.filter, renderView: mainRenderView)
    }
    
    private var cancellables = Set<AnyCancellable>()
}
