//
//  EditOperation.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import UIKit

/// 编辑操作实体
/// 定义图片编辑操作的基本属性和行为
struct EditOperation: Identifiable, Sendable {
    let id: String
    let type: EditOperationType
    let parameters: EditParameters
    let timestamp: Date
    
    init(
        id: String = UUID().uuidString,
        type: EditOperationType,
        parameters: EditParameters,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.parameters = parameters
        self.timestamp = timestamp
    }
}

/// 编辑操作类型
enum EditOperationType: String, CaseIterable, Sendable {
    case crop = "crop"
    case rotate = "rotate"
    case flip = "flip"
    case brightness = "brightness"
    case contrast = "contrast"
    case saturation = "saturation"
    case temperature = "temperature"
    case exposure = "exposure"
    case highlights = "highlights"
    case shadows = "shadows"
    case filter = "filter"
    case text = "text"
    case sticker = "sticker"
    
    var displayName: String {
        switch self {
        case .crop: return "裁剪"
        case .rotate: return "旋转"
        case .flip: return "翻转"
        case .brightness: return "亮度"
        case .contrast: return "对比度"
        case .saturation: return "饱和度"
        case .temperature: return "色温"
        case .exposure: return "曝光"
        case .highlights: return "高光"
        case .shadows: return "阴影"
        case .filter: return "滤镜"
        case .text: return "文字"
        case .sticker: return "贴纸"
        }
    }
}

/// 编辑参数
struct EditParameters: Sendable {
    let floatValue: Float?
    let stringValue: String?
    let rectValue: CGRect?
    let colorValue: UIColor?
    let fontValue: UIFont?
    
    init(
        floatValue: Float? = nil,
        stringValue: String? = nil,
        rectValue: CGRect? = nil,
        colorValue: UIColor? = nil,
        fontValue: UIFont? = nil
    ) {
        self.floatValue = floatValue
        self.stringValue = stringValue
        self.rectValue = rectValue
        self.colorValue = colorValue
        self.fontValue = fontValue
    }
    
    static func float(_ value: Float) -> EditParameters {
        EditParameters(floatValue: value)
    }
    
    static func string(_ value: String) -> EditParameters {
        EditParameters(stringValue: value)
    }
    
    static func rect(_ value: CGRect) -> EditParameters {
        EditParameters(rectValue: value)
    }
    
    static func color(_ value: UIColor) -> EditParameters {
        EditParameters(colorValue: value)
    }
}

/// 编辑会话
/// 表示一次完整的编辑会话，包含多个编辑操作
struct EditSession: Identifiable, Sendable {
    let id: String
    let originalImage: UIImage
    let operations: [EditOperation]
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        originalImage: UIImage,
        operations: [EditOperation] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.originalImage = originalImage
        self.operations = operations
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// 编辑错误类型
enum EditError: LocalizedError, Equatable {
    case invalidImage
    case invalidOperation
    case processingFailed
    case unsupportedFormat
    case memoryWarning
    case operationNotAllowed
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无效的图片"
        case .invalidOperation:
            return "无效的编辑操作"
        case .processingFailed:
            return "图片处理失败"
        case .unsupportedFormat:
            return "不支持的图片格式"
        case .memoryWarning:
            return "内存不足，无法处理"
        case .operationNotAllowed:
            return "不允许的操作"
        case .unknown(let message):
            return "未知错误: \(message)"
        }
    }
}
