//
//  MetalPixelBufferView.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI
import UIKit
import CoreVideo
@preconcurrency import CoreImage
import os.log

/// 像素缓冲区视图（UIViewRepresentable）
/// 使用Core Image高效渲染CVPixelBuffer，提供流畅的相机预览
/// 支持实时更新和自动适应屏幕方向
struct MetalPixelBufferView: UIViewRepresentable {
    /// 要渲染的像素缓冲区
    let pixelBuffer: CVPixelBuffer?
    
    func makeUIView(context: Context) -> PixelBufferDisplayView {
        let displayView = PixelBufferDisplayView()
        return displayView
    }
    
    func updateUIView(_ uiView: PixelBufferDisplayView, context: Context) {
        uiView.updatePixelBuffer(pixelBuffer)
    }
}

/// 像素缓冲区显示视图
/// 使用Core Image进行高效的像素缓冲区渲染
final class PixelBufferDisplayView: UIView {
    
    // MARK: - Logging
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "camfoloClean",
        category: "Camera.PixelBufferDisplayView"
    )
    
    // MARK: - Core Image Components
    
    private let ciContext: CIContext
    private var displayLayer: CALayer?
    
    // MARK: - State
    
    private var currentPixelBuffer: CVPixelBuffer?
    
    // 🚀 极致性能：60fps渲染目标
    private var lastRenderTime: CFTimeInterval = 0
    private let renderInterval: CFTimeInterval = 1.0/60.0  // 60fps渲染限制
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        // 性能优化：创建高性能Core Image上下文
        let options: [CIContextOption: Any] = [
            .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
            .outputColorSpace: CGColorSpaceCreateDeviceRGB(),
            .useSoftwareRenderer: false  // 强制使用GPU渲染
        ]
        self.ciContext = CIContext(options: options)
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        // 性能优化：创建高性能Core Image上下文
        let options: [CIContextOption: Any] = [
            .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
            .outputColorSpace: CGColorSpaceCreateDeviceRGB(),
            .useSoftwareRenderer: false  // 强制使用GPU渲染
        ]
        self.ciContext = CIContext(options: options)
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = .black
        contentMode = .scaleAspectFit
        
        // 创建显示层
        let layer = CALayer()
        layer.contentsGravity = .resizeAspect
        layer.backgroundColor = UIColor.black.cgColor
        self.layer.addSublayer(layer)
        self.displayLayer = layer
        
        Self.logger.info("PixelBufferDisplayView setup completed")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        displayLayer?.frame = bounds
    }
    
    // MARK: - Public Methods
    
    /// 更新像素缓冲区（高性能版本）
    /// - Parameter pixelBuffer: 新的像素缓冲区
    func updatePixelBuffer(_ pixelBuffer: CVPixelBuffer?) {
        guard let pixelBuffer = pixelBuffer else {
            DispatchQueue.main.async { [weak self] in
                self?.displayLayer?.contents = nil
            }
            return
        }
        
        // 性能优化：避免重复处理相同的缓冲区（首要检查）
        if let currentBuffer = currentPixelBuffer,
           CFEqual(currentBuffer, pixelBuffer) {
            return
        }
        
        // 性能优化：渲染限流，避免过度渲染
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastRenderTime >= renderInterval else {
            return  // 跳过这次渲染以保持稳定帧率
        }
        lastRenderTime = currentTime
        
        currentPixelBuffer = pixelBuffer
        
        // 性能优化：使用高优先级队列快速处理
        let context = ciContext
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            
            // 创建CIImage（使用局部变量避免并发警告）
            let localPixelBuffer = pixelBuffer
            let ciImage = CIImage(cvPixelBuffer: localPixelBuffer)
            
            // 性能优化：使用固定格式和色彩空间提升渲染速度
            guard let cgImage = context.createCGImage(
                ciImage, 
                from: ciImage.extent,
                format: .RGBA8,
                colorSpace: CGColorSpaceCreateDeviceRGB()
            ) else {
                print("Failed to create CGImage from pixel buffer")
                return
            }
            
            // 在主线程更新UI
            DispatchQueue.main.async {
                self.displayLayer?.contents = cgImage
            }
        }
    }
}
