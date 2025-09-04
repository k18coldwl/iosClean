// Features/Camera/Presentation/CameraView.swift
import SwiftUI
import GPUImage

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some View {
        VStack {
            // 主预览 80%
            RenderViewRepresentable(renderView: viewModel.mainRenderView)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 横向滤镜小窗口
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(viewModel.filterItems) { item in
                        FilterPreviewCell(id: item.id, item: item, viewModel: viewModel)
                            .onTapGesture {
                                viewModel.selectFilter(item: item)
                            }
                    }
                }
                .padding()
            }
            .frame(height: 120)
        }
    }
}
