// Features/Camera/Presentation/RenderViewRepresentable.swift
import SwiftUI
import GPUImage

struct RenderViewRepresentable: UIViewRepresentable {
    let renderView: RenderView
    
    func makeUIView(context: Context) -> RenderView { renderView }
    
    func updateUIView(_ uiView: RenderView, context: Context) {}
}
