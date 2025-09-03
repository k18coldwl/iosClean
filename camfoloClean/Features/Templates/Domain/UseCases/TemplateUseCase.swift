//
//  TemplateUseCase.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import UIKit

/// 模板业务用例协议
/// 定义模板相关的业务逻辑接口
protocol TemplateUseCaseProtocol: Sendable {
    
    /// 获取所有模板分类及其模板
    /// - Returns: 按分类组织的模板字典
    func getTemplatesByCategories() async throws -> [TemplateCategory: [Template]]
    
    /// 获取推荐模板
    /// - Returns: 推荐模板列表
    func getFeaturedTemplates() async throws -> [Template]
    
    /// 搜索模板
    /// - Parameter keyword: 搜索关键词
    /// - Returns: 匹配的模板列表
    func searchTemplates(keyword: String) async throws -> [Template]
    
    /// 应用模板到图片
    /// - Parameters:
    ///   - templateId: 模板ID
    ///   - image: 原始图片
    /// - Returns: 处理后的图片
    func applyTemplate(templateId: String, to image: UIImage) async throws -> UIImage
    
    /// 预览模板效果
    /// - Parameters:
    ///   - templateId: 模板ID
    ///   - image: 原始图片
    /// - Returns: 预览图片（可能是缩略图）
    func previewTemplate(templateId: String, with image: UIImage) async throws -> UIImage
    
    /// 切换模板收藏状态
    /// - Parameter templateId: 模板ID
    /// - Returns: 新的收藏状态
    func toggleTemplateFavorite(templateId: String) async throws -> Bool
    
    /// 获取收藏的模板
    /// - Returns: 收藏的模板列表
    func getFavoriteTemplates() async throws -> [Template]
    
    /// 检查模板是否需要付费
    /// - Parameter templateId: 模板ID
    /// - Returns: 是否需要付费
    func isTemplatePreium(_ templateId: String) async throws -> Bool
}

/// 模板业务用例实现
final class TemplateUseCase: TemplateUseCaseProtocol {
    
    private let templateRepository: TemplateRepository
    
    init(templateRepository: TemplateRepository) {
        self.templateRepository = templateRepository
    }
    
    func getTemplatesByCategories() async throws -> [TemplateCategory: [Template]] {
        let allTemplates = try await templateRepository.getAllTemplates()
        
        var categorizedTemplates: [TemplateCategory: [Template]] = [:]
        
        for category in TemplateCategory.allCases {
            let templates = allTemplates.filter { $0.category == category }
            if !templates.isEmpty {
                categorizedTemplates[category] = templates
            }
        }
        
        return categorizedTemplates
    }
    
    func getFeaturedTemplates() async throws -> [Template] {
        return try await templateRepository.getFeaturedTemplates(limit: 6)
    }
    
    func searchTemplates(keyword: String) async throws -> [Template] {
        let allTemplates = try await templateRepository.getAllTemplates()
        
        let lowercaseKeyword = keyword.lowercased()
        return allTemplates.filter { template in
            template.name.lowercased().contains(lowercaseKeyword) ||
            template.description.lowercased().contains(lowercaseKeyword) ||
            template.category.displayName.lowercased().contains(lowercaseKeyword)
        }
    }
    
    func applyTemplate(templateId: String, to image: UIImage) async throws -> UIImage {
        let template = try await templateRepository.getTemplate(by: templateId)
        return try await templateRepository.applyTemplate(template, to: image)
    }
    
    func previewTemplate(templateId: String, with image: UIImage) async throws -> UIImage {
        // 为了预览，可以先缩小图片尺寸以提高性能
        let previewSize = CGSize(width: 300, height: 300)
        let previewImage = image.resized(to: previewSize)
        
        return try await applyTemplate(templateId: templateId, to: previewImage)
    }
    
    func toggleTemplateFavorite(templateId: String) async throws -> Bool {
        let favoriteTemplates = try await templateRepository.getFavoriteTemplates()
        let isFavorited = favoriteTemplates.contains { $0.id == templateId }
        
        if isFavorited {
            try await templateRepository.unfavoriteTemplate(templateId)
            return false
        } else {
            try await templateRepository.favoriteTemplate(templateId)
            return true
        }
    }
    
    func getFavoriteTemplates() async throws -> [Template] {
        return try await templateRepository.getFavoriteTemplates()
    }
    
    func isTemplatePreium(_ templateId: String) async throws -> Bool {
        let template = try await templateRepository.getTemplate(by: templateId)
        return template.isPreium
    }
}

// MARK: - UIImage Extension

private extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
