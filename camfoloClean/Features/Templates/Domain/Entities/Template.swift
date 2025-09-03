//
//  Template.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import UIKit

/// 模板实体
/// 定义拍照模板的基本属性和行为
struct Template: Identifiable, Sendable {
    let id: String
    let name: String
    let description: String
    let category: TemplateCategory
    let previewImage: UIImage?
    let filterSettings: FilterSettings
    let isPreium: Bool
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        category: TemplateCategory,
        previewImage: UIImage? = nil,
        filterSettings: FilterSettings = FilterSettings(),
        isPreium: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.previewImage = previewImage
        self.filterSettings = filterSettings
        self.isPreium = isPreium
        self.createdAt = createdAt
    }
}

/// 模板分类
enum TemplateCategory: String, CaseIterable, Sendable {
    case classic = "Classic"
    case glam = "Glam"
    case blackAndWhite = "B&W"
    case vintage = "Vintage"
    case modern = "Modern"
    case artistic = "Artistic"
    
    var displayName: String {
        return rawValue
    }
}

/// 滤镜设置
struct FilterSettings: Sendable {
    let brightness: Float
    let contrast: Float
    let saturation: Float
    let warmth: Float
    let vignette: Float
    
    init(
        brightness: Float = 0.0,
        contrast: Float = 0.0,
        saturation: Float = 0.0,
        warmth: Float = 0.0,
        vignette: Float = 0.0
    ) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.warmth = warmth
        self.vignette = vignette
    }
}

/// 模板错误类型
enum TemplateError: LocalizedError, Equatable {
    case templateNotFound
    case invalidTemplate
    case loadingFailed
    case processingFailed
    case permissionDenied
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .templateNotFound:
            return "模板未找到"
        case .invalidTemplate:
            return "无效的模板"
        case .loadingFailed:
            return "模板加载失败"
        case .processingFailed:
            return "模板处理失败"
        case .permissionDenied:
            return "没有访问权限"
        case .networkError:
            return "网络连接错误"
        case .unknown(let message):
            return "未知错误: \(message)"
        }
    }
}
