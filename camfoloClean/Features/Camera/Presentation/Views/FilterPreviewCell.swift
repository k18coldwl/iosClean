// Features/Camera/Presentation/FilterPreviewCell.swift
import SwiftUI
import GPUImage

struct FilterPreviewCell: View, Identifiable {
    let id: String
    let item: FilterPreviewItem
    @ObservedObject var viewModel: CameraViewModel
    @State private var renderView: RenderView? = nil
    
    var body: some View {
        ZStack {
            if let renderView = renderView {
                RenderViewRepresentable(renderView: renderView)
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
            } else {
                Color.black.frame(width: 100, height: 100)
                    .cornerRadius(8)
            }
        }
        .onAppear {
            guard renderView == nil, let frame = viewModel.cameraManager.currentFrame else { return }
            let rv = RenderView(frame: .zero)
            renderView = rv
            viewModel.activatePreview(item: item, renderView: rv, frame: frame)
        }
        .onDisappear {
            if let rv = renderView {
                viewModel.deactivate(renderView: rv)
                renderView = nil
            }
        }
    }
}
