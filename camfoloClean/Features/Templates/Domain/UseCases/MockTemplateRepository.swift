//
//  MockTemplateRepository.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import UIKit

/// Templates模块Mock实现
/// 用于测试和Preview，提供模拟数据
final class MockTemplateRepository: @unchecked Sendable, TemplateRepository {
    
    private var templates: [Template] = []
    private var favoriteTemplateIds: Set<String> = []
    
    init() {
        setupMockTemplates()
    }
    
    private func setupMockTemplates() {
        templates = [
            Template(
                name: "Classic Portrait",
                description: "经典人像滤镜，适合日常拍摄",
                category: .classic,
                filterSettings: FilterSettings(brightness: 0.1, contrast: 0.15, saturation: 0.05)
            ),
            Template(
                name: "Golden Hour",
                description: "黄金时刻，温暖的色调",
                category: .glam,
                filterSettings: FilterSettings(brightness: 0.05, contrast: 0.1, warmth: 0.3)
            ),
            Template(
                name: "Dramatic B&W",
                description: "戏剧性黑白效果",
                category: .blackAndWhite,
                filterSettings: FilterSettings(contrast: 0.4, saturation: -1.0, vignette: 0.2)
            ),
            Template(
                name: "Vintage Film",
                description: "复古胶片质感",
                category: .vintage,
                filterSettings: FilterSettings(brightness: -0.05, contrast: 0.2, saturation: -0.2, warmth: 0.15)
            ),
            Template(
                name: "Clean Modern",
                description: "简洁现代风格",
                category: .modern,
                filterSettings: FilterSettings(brightness: 0.05, contrast: 0.1, saturation: 0.1)
            ),
            Template(
                name: "Artistic Glow",
                description: "艺术光晕效果",
                category: .artistic,
                filterSettings: FilterSettings(brightness: 0.1, contrast: 0.05, saturation: 0.15, vignette: -0.1),
                isPreium: true
            )
        ]
    }
    
    func getAllTemplates() async throws -> [Template] {
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        return templates
    }
    
    func getTemplatesByCategory(_ category: TemplateCategory) async throws -> [Template] {
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
        return templates.filter { $0.category == category }
    }
    
    func getTemplate(by templateId: String) async throws -> Template {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        guard let template = templates.first(where: { $0.id == templateId }) else {
            throw TemplateError.templateNotFound
        }
        
        return template
    }
    
    func getFeaturedTemplates(limit: Int) async throws -> [Template] {
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
        return Array(templates.prefix(limit))
    }
    
    func applyTemplate(_ template: Template, to image: UIImage) async throws -> UIImage {
        // 模拟图片处理时间
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        
        // 在实际实现中，这里会应用真正的滤镜效果
        // 这里只是返回原图作为Mock
        return image
    }
    
    func favoriteTemplate(_ templateId: String) async throws {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        favoriteTemplateIds.insert(templateId)
    }
    
    func unfavoriteTemplate(_ templateId: String) async throws {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        favoriteTemplateIds.remove(templateId)
    }
    
    func getFavoriteTemplates() async throws -> [Template] {
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
        return templates.filter { favoriteTemplateIds.contains($0.id) }
    }
    
    // MARK: - Mock Configuration Methods
    
    func configureFavorites(_ templateIds: [String]) {
        favoriteTemplateIds = Set(templateIds)
    }
    
    func addMockTemplate(_ template: Template) {
        templates.append(template)
    }
    
    func clearMockTemplates() {
        templates.removeAll()
        favoriteTemplateIds.removeAll()
        setupMockTemplates()
    }
}
