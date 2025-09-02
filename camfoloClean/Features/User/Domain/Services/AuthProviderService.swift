//
//  AuthProviderService.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import AuthenticationServices

/// 第三方认证提供商服务协议
/// 定义了各种第三方认证服务的统一接口，符合依赖倒置原则
protocol AuthProviderService: Sendable {
    /// 获取认证凭证
    /// - Returns: 第三方认证凭证信息
    /// - Throws: AuthError
    func getCredential() async throws -> ThirdPartyCredential
}

/// 第三方认证凭证
/// 封装了第三方认证服务返回的凭证信息
struct ThirdPartyCredential: Sendable {
    let providerID: String
    let idToken: String
    let accessToken: String?
    let rawNonce: String?
    
    init(providerID: String, idToken: String, accessToken: String? = nil, rawNonce: String? = nil) {
        self.providerID = providerID
        self.idToken = idToken
        self.accessToken = accessToken
        self.rawNonce = rawNonce
    }
}
