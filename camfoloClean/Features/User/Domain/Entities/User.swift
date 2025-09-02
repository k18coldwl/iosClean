//
//  User.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation

struct User: Equatable, Identifiable {
    let id: String
    let email: String?
    let displayName: String?
    let photoURL: URL?
    let provider: AuthProvider
    let isEmailVerified: Bool
    let createdAt: Date
    let lastSignInAt: Date?
    
    init(
        id: String,
        email: String? = nil,
        displayName: String? = nil,
        photoURL: URL? = nil,
        provider: AuthProvider,
        isEmailVerified: Bool = false,
        createdAt: Date = Date(),
        lastSignInAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.provider = provider
        self.isEmailVerified = isEmailVerified
        self.createdAt = createdAt
        self.lastSignInAt = lastSignInAt
    }
}

enum AuthProvider: String, CaseIterable {
    case google = "google.com"
    case apple = "apple.com"
    case email = "password"
    
    var displayName: String {
        switch self {
        case .google:
            return "Google"
        case .apple:
            return "Apple"
        case .email:
            return "Email"
        }
    }
}

