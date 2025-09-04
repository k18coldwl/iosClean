import SwiftUI
import GPUImage

struct CameraView: View {
    @State private var viewModel = CameraViewModel()
    @State private var visibleItems: Set<String> = []
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 主预览区域 - 占据除了滤镜选择区域外的所有空间
                RenderViewRepresentable(renderView: viewModel.mainRenderView)
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height - filterSectionHeight
                    )
                    .clipped()
                    .background(Color.black)
                
                // 滤镜选择区域 - 固定高度
                filterSelectionView
                    .frame(height: filterSectionHeight)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(Color.black)
        .task {
            // 监控热状态，动态调整性能
            await monitorThermalState()
        }
    }
    
    // MARK: - Filter Selection View
    
    private var filterSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(viewModel.filterItems) { item in
                    FilterPreviewCell(item: item, viewModel: viewModel)
                        .scaleEffect(viewModel.selectedFilterID == item.id ? 1.1 : 1.0)
                        .animation(.spring(duration: 0.3), value: viewModel.selectedFilterID)
                        .onTapGesture {
                            viewModel.selectFilter(item: item)
                        }
                        .onAppear {
                            visibleItems.insert(item.id)
                        }
                        .onDisappear {
                            visibleItems.remove(item.id)
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Helper Properties
    
    private var filterSectionHeight: CGFloat {
        104 // 滤镜选择区域的固定高度
    }
    
    // MARK: - Thermal Monitoring
    
    private func monitorThermalState() async {
        // for await _ in NotificationCenter.default.notifications(
        //     named: ProcessInfo.thermalStateDidChangeNotification
        // ) {
        //     await MainActor.run {
        //         viewModel.adjustPerformanceSettings()
        //     }
        // }
    }
}