//
//  TemplatesViewModel.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import UIKit

/// Templates模块的ViewModel
/// 负责管理模板列表和应用逻辑
@MainActor
final class TemplatesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 所有模板按分类组织
    @Published var templatesByCategory: [TemplateCategory: [Template]] = [:]
    
    /// 推荐模板
    @Published var featuredTemplates: [Template] = []
    
    /// 加载状态
    @Published var isLoading = false
    
    /// 错误信息
    @Published var errorMessage: String?
    
    /// 搜索关键词
    @Published var searchKeyword = ""
    
    /// 搜索结果
    @Published var searchResults: [Template] = []
    
    // MARK: - Dependencies
    
    private let templateUseCase: TemplateUseCaseProtocol
    
    // MARK: - Initialization
    
    init(templateUseCase: TemplateUseCaseProtocol) {
        self.templateUseCase = templateUseCase
    }
    
    // MARK: - Public Methods
    
    /// 加载模板数据
    func loadTemplates() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 并行加载推荐模板和分类模板
            async let featured = templateUseCase.getFeaturedTemplates()
            async let byCategory = templateUseCase.getTemplatesByCategories()
            
            featuredTemplates = try await featured
            templatesByCategory = try await byCategory
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// 搜索模板
    func searchTemplates() async {
        guard !searchKeyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        do {
            searchResults = try await templateUseCase.searchTemplates(keyword: searchKeyword)
        } catch {
            errorMessage = error.localizedDescription
            searchResults = []
        }
    }
    
    /// 应用模板到图片
    func applyTemplate(_ template: Template, to image: UIImage) async -> UIImage? {
        do {
            return try await templateUseCase.applyTemplate(templateId: template.id, to: image)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    /// 预览模板效果
    func previewTemplate(_ template: Template, with image: UIImage) async -> UIImage? {
        do {
            // 目前使用应用模板的方法作为预览
            return try await templateUseCase.applyTemplate(templateId: template.id, to: image)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    /// 清除错误信息
    func clearError() {
        errorMessage = nil
    }
}
