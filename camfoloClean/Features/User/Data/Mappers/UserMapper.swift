//
//  UserMapper.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import FirebaseAuth

struct UserMapper {
    static func mapFromFirebaseUser(_ firebaseUser: FirebaseAuth.User) -> User {
        let provider = determineAuthProvider(from: firebaseUser)
        
        return User(
            id: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL,
            provider: provider,
            isEmailVerified: firebaseUser.isEmailVerified,
            createdAt: firebaseUser.metadata.creationDate ?? Date(),
            lastSignInAt: firebaseUser.metadata.lastSignInDate
        )
    }
    
    static func mapFromAuthResult(_ authResult: AuthDataResult) -> AuthResult {
        let user = mapFromFirebaseUser(authResult.user)
        let isNewUser = authResult.additionalUserInfo?.isNewUser ?? false
        
        return AuthResult(user: user, isNewUser: isNewUser)
    }
    
    private static func determineAuthProvider(from firebaseUser: FirebaseAuth.User) -> AuthProvider {
        guard let providerData = firebaseUser.providerData.first else {
            return .email
        }
        
        switch providerData.providerID {
        case "google.com":
            return .google
        case "apple.com":
            return .apple
        default:
            return .email
        }
    }
}

extension AuthError {
    static func mapFromFirebaseError(_ error: Error) -> AuthError {
        guard let authError = error as? AuthErrorCode else {
            return .unknown(error.localizedDescription)
        }
        
        switch authError.code {
        case .networkError:
            return .networkError(error: error)
        case .invalidCredential:
            return .invalidCredential
        case .userDisabled:
            return .accountDisabled
        case .tooManyRequests:
            return .tooManyRequests
        case .operationNotAllowed:
            return .operationNotAllowed
        case .weakPassword:
            return .weakPassword
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .invalidEmail:
            return .invalidEmail
        case .userNotFound:
            return .userNotFound
        case .wrongPassword:
            return .wrongPassword
        default:
            return .unknown(error.localizedDescription)
        }
    }
}

