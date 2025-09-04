/// 用于描述滤镜管线的抽象，不依赖 GPUImage3
public struct FilterGraphDescription: Sendable {
    public let nodes: [String]
}