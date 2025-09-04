public protocol CameraUseCase: Sendable {
    func startPreview() async throws
    func stopPreview() async
    func setMainFilter(_ filter: FilterGraphDescription) async
    func updateVisiblePreviews(_ items: [FilterPreviewItem]) async
}