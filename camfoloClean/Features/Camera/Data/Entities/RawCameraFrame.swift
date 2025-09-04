//
//  RawCameraFrame.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import CoreVideo
import CoreMedia

/// 🚀 极简高性能相机帧
/// 直接包装CVPixelBuffer，零抽象开销
/// 专为60fps实时预览设计
public struct RawCameraFrame: @unchecked Sendable {
    public let pixelBuffer: CVPixelBuffer
    public let timestamp: CMTime
    public let frameNumber: Int
    
    public init(pixelBuffer: CVPixelBuffer, timestamp: CMTime, frameNumber: Int = 0) {
        self.pixelBuffer = pixelBuffer
        self.timestamp = timestamp
        self.frameNumber = frameNumber
    }
}