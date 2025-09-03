//
//  TabType.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation

/// Tab类型枚举
/// 定义应用中的四个主要Tab页面
enum TabType: CaseIterable {
    case capture
    case templates  
    case edit
    case mine
    
    var title: String {
        switch self {
        case .capture: return "Capture"
        case .templates: return "Templates"
        case .edit: return "Edit"
        case .mine: return "Mine"
        }
    }
    
    var activeIcon: String {
        switch self {
        case .capture: return "tab_camera_active"
        case .templates: return "tab_templates_active"
        case .edit: return "tab_edit_active"
        case .mine: return "tab_mine_active"
        }
    }
    
    var inactiveIcon: String {
        switch self {
        case .capture: return "tab_camera_inactive"
        case .templates: return "tab_templates_inactive"
        case .edit: return "tab_edit_inactive"
        case .mine: return "tab_mine_inactive"
        }
    }
}
