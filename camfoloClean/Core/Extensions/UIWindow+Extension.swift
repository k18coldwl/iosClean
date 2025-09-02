//
//  UIWindow+Extension.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import UIKit

extension UIWindow {
    /// 获取当前窗口的顶部视图控制器
    static var cam: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    /// 获取当前顶部的视图控制器
    var topViewController: UIViewController? {
        return rootViewController?.topViewController
    }
}

extension UIViewController {
    /// 递归获取最顶层的视图控制器
    var topViewController: UIViewController {
        if let presentedViewController = presentedViewController {
            return presentedViewController.topViewController
        }
        
        if let navigationController = self as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return visibleViewController.topViewController
        }
        
        if let tabBarController = self as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return selectedViewController.topViewController
        }
        
        return self
    }
}
