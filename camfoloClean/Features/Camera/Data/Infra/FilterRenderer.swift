// Features/Camera/Infra/FilterRenderer.swift
import Foundation
import GPUImage

final class FilterRenderer {
    
    /// 渲染主预览（全分辨率）
    func renderMain(frame: PictureInput, filter: BasicOperation, renderView: RenderView) {
        frame --> filter --> renderView
        frame.processImage()
    }
    
    /// 渲染小窗口（低分辨率 + 异步）
    func renderPreview(frame: PictureInput, filter: BasicOperation, renderView: RenderView) {
        let downsample = PictureInput(image: frame.imageFromCurrentFramebuffer()!.resize(to: CGSize(width: 160, height: 160)))
        DispatchQueue.global(qos: .userInitiated).async {
            downsample --> filter --> renderView
            downsample.processImage()
        }
    }
    
    func release(renderView: RenderView) {
        renderView.removeAllTargets()
    }
}
