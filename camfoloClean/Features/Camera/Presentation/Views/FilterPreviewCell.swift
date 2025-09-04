import SwiftUI
import GPUImage

struct FilterPreviewCell: View {
    let item: FilterPreviewItem
    let viewModel: CameraViewModel
    
    @State private var renderView: RenderView?
    @State private var isActive = false
    @State private var cellSize: CGSize = CGSize(width: 80, height: 80)
    
    var body: some View {
        ZStack {
            if let renderView = renderView {
                RenderViewRepresentable(renderView: renderView)
                    .frame(width: cellSize.width, height: cellSize.height)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.black)
                    .frame(width: cellSize.width, height: cellSize.height)
            }
            
            if !isActive {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.black.opacity(0.5))
                    .frame(width: cellSize.width, height: cellSize.height)
                    .overlay {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                    }
            }
        }
        .onAppear {
            setupPreview()
        }
        .onDisappear {
            cleanupPreview()
        }
        .task {
            // 监控设备性能，动态调整预览质量
            await monitorPerformance()
        }
    }
    
    private func setupPreview() {
        guard renderView == nil else { return }
        
        let frame = CGRect(origin: .zero, size: cellSize)
        let rv = RenderView(frame: frame)
        renderView = rv
        
        viewModel.activatePreview(item: item, renderView: rv)
        
        // 延迟激活状态，给 GPU 时间初始化
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            await MainActor.run {
                isActive = true
            }
        }
    }
    
    private func cleanupPreview() {
        guard let rv = renderView else { return }
        
        viewModel.deactivatePreview(renderView: rv)
        renderView = nil
        isActive = false
    }
    
    private func monitorPerformance() async {
        // 根据设备性能动态调整预览尺寸
//        let deviceModel = await UIDevice.current.model
//        let memoryPressure = ProcessInfo.processInfo.performsLowMemoryResponse
//        
//        if memoryPressure {
//            await MainActor.run {
//                cellSize = CGSize(width: 60, height: 60)
//            }
//        }
    }
}
