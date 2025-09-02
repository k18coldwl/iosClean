//
//  CryptoUtils.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import CryptoKit

/// 加密工具类
/// 提供常用的加密和随机数生成功能
struct CryptoUtils {
    
    /// 生成加密安全的随机nonce字符串
    /// - Parameter length: nonce长度，默认32位
    /// - Returns: 随机nonce字符串
    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    /// SHA256哈希加密
    /// - Parameter input: 需要加密的字符串
    /// - Returns: SHA256哈希值的十六进制字符串
    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}
