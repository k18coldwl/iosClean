//
//  AuthResult.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation

struct AuthResult: Equatable {
    let user: User
    let isNewUser: Bool
    
    init(user: User, isNewUser: Bool = false) {
        self.user = user
        self.isNewUser = isNewUser
    }
}

enum AuthError: LocalizedError, Equatable {
    case userCancelled
    case cancelled
    case networkError(error: Error)
    case invalidCredentials
    case invalidCredential
    case accountDisabled
    case tooManyRequests
    case operationNotAllowed
    case weakPassword
    case emailAlreadyInUse
    case invalidEmail
    case userNotFound
    case wrongPassword
    case unknown(String)
    
    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.userCancelled, .userCancelled),
             (.cancelled, .cancelled),
             (.invalidCredentials, .invalidCredentials),
             (.invalidCredential, .invalidCredential),
             (.accountDisabled, .accountDisabled),
             (.tooManyRequests, .tooManyRequests),
             (.operationNotAllowed, .operationNotAllowed),
             (.weakPassword, .weakPassword),
             (.emailAlreadyInUse, .emailAlreadyInUse),
             (.invalidEmail, .invalidEmail),
             (.userNotFound, .userNotFound),
             (.wrongPassword, .wrongPassword):
            return true
        case (.networkError, .networkError):
            return true // Simplified comparison for network errors
        case (.unknown(let lhsMessage), .unknown(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "User cancelled the authentication"
        case .cancelled:
            return "Operation was cancelled"
        case .networkError(let error):
            return "Network error occurred: \(error.localizedDescription)"
        case .invalidCredentials:
            return "Invalid credentials provided"
        case .invalidCredential:
            return "Invalid credential"
        case .accountDisabled:
            return "User account has been disabled"
        case .tooManyRequests:
            return "Too many requests. Try again later"
        case .operationNotAllowed:
            return "This operation is not allowed"
        case .weakPassword:
            return "Password is too weak"
        case .emailAlreadyInUse:
            return "Email is already in use"
        case .invalidEmail:
            return "Invalid email address"
        case .userNotFound:
            return "User not found"
        case .wrongPassword:
            return "Wrong password"
        case .unknown(let message):
            return message
        }
    }
}

