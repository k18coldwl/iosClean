//
//  TemplateRepository.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import UIKit

/// 模板数据访问协议
/// 定义模板相关的数据操作接口
protocol TemplateRepository: Sendable {
    
    /// 获取所有模板
    /// - Returns: 模板列表
    func getAllTemplates() async throws -> [Template]
    
    /// 根据分类获取模板
    /// - Parameter category: 模板分类
    /// - Returns: 该分类下的模板列表
    func getTemplatesByCategory(_ category: TemplateCategory) async throws -> [Template]
    
    /// 根据ID获取特定模板
    /// - Parameter templateId: 模板ID
    /// - Returns: 指定的模板
    func getTemplate(by templateId: String) async throws -> Template
    
    /// 获取推荐模板
    /// - Parameter limit: 返回数量限制
    /// - Returns: 推荐模板列表
    func getFeaturedTemplates(limit: Int) async throws -> [Template]
    
    /// 应用模板到图片
    /// - Parameters:
    ///   - template: 要应用的模板
    ///   - image: 原始图片
    /// - Returns: 处理后的图片
    func applyTemplate(_ template: Template, to image: UIImage) async throws -> UIImage
    
    /// 收藏模板
    /// - Parameter templateId: 模板ID
    func favoriteTemplate(_ templateId: String) async throws
    
    /// 取消收藏模板
    /// - Parameter templateId: 模板ID
    func unfavoriteTemplate(_ templateId: String) async throws
    
    /// 获取收藏的模板
    /// - Returns: 收藏的模板列表
    func getFavoriteTemplates() async throws -> [Template]
}
