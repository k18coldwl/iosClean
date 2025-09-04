import SwiftUI
import GPUImage

struct FilterPreviewCell: View {
    let item: FilterPreviewItem
    let viewModel: CameraViewModel
    
    @State private var renderView: RenderView?
    @State private var isLoading = true
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if let renderView = renderView {
                RenderViewRepresentable(renderView: renderView)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .opacity(isLoading ? 0.3 : 1.0)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.black)
                    .frame(width: 80, height: 80)
            }
            
            // 加载指示器
            if isLoading {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.black.opacity(0.7))
                    .frame(width: 80, height: 80)
                    .overlay {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                    }
            }
            
            // 选中指示器
            if viewModel.selectedFilterID == item.id {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(width: 80, height: 80)
            }
            
            // 滤镜名称标签
            VStack {
                Spacer()
                Text(item.name)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.black.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(.bottom, 4)
            }
        }
        .task(id: item.id) {
            // 使用 task 修饰符，自动处理取消
            await setupPreview()
        }
        .onDisappear {
            cleanupPreview()
        }
    }
    
    @MainActor
    private func setupPreview() async {
        guard !isActive else { return }
        
        isLoading = true
        isActive = true
        
        // 直接同步调用，避免复杂的异步回调
        let newRenderView = await requestRenderView()
        
        guard !Task.isCancelled else {
            cleanupPreview()
            return
        }
        
        renderView = newRenderView
        
        // 给GPU时间初始化
        try? await Task.sleep(for: .milliseconds(200))
        
        guard !Task.isCancelled else {
            cleanupPreview()
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = false
        }
    }
    
    @MainActor
    private func requestRenderView() async -> RenderView {
        return await withCheckedContinuation { continuation in
            viewModel.requestPreviewActivation(item: item) { newRenderView in
                continuation.resume(returning: newRenderView)
            }
        }
    }
    
    private func cleanupPreview() {
        guard isActive else { return }
        
        if let rv = renderView {
            viewModel.deactivatePreview(renderView: rv)
        }
        
        renderView = nil
        isLoading = true
        isActive = false
    }
}
