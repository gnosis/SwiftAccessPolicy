//
//  AccessService.swift
//  SwiftAccessPolicy
//
//  Created by Andrey Scherbovich on 25.03.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import CryptoKit

public class AccessService {
    public var authStatus: AuthStatus {
        return .notAuthenticated
    }

    private var accessPolicy: AccessPolicy
    private var userRepository: UserRepository
    private var clockService: ClockService

    enum AccessServiceError: Error {
        case userAlreadyExists
        case userDoesNotExist
        case couldNotEncodeStringToUTF8Data
    }

    public init(accessPolicy: AccessPolicy,
                userRepository: UserRepository?,
                clockService: ClockService?) {
        self.accessPolicy = accessPolicy
        if let userRepository = userRepository {
            self.userRepository = userRepository
        } else {
            self.userRepository = InMemotyUserRepository()
        }
        if let clockService = clockService {
            self.clockService = clockService
        } else {
            self.clockService = SystemClockService()
        }
    }

    // MARK: - Users management

    func registerUser(userID: UUID = UUID(), password: String) throws {
        guard userRepository.user(userID: userID) == nil else {
            throw AccessServiceError.userAlreadyExists
        }
        let user = User(userID: userID, encryptedPassword: try encrypted(password))
        userRepository.save(user: user)
    }

    func deleteUser(userID: UUID) throws {
        guard userRepository.user(userID: userID) != nil else {
            throw AccessServiceError.userDoesNotExist
        }
        userRepository.delete(userID: userID)
    }

    func users() -> [User] {
        return userRepository.users()
    }

    func updateUserPassword(userID: UUID, password: String) throws {
        guard var user = userRepository.user(userID: userID) else {
            throw AccessServiceError.userDoesNotExist
        }
        user.updatePassword(encryptedPassword: try encrypted(password))
        userRepository.save(user: user)
    }

    func verifyPassword(userID: UUID, password: String) throws -> Bool {
        return false
    }

    private func encrypted(_ string: String) throws -> String {
        guard let data = string.data(using: .utf8) else {
            throw AccessServiceError.couldNotEncodeStringToUTF8Data
        }
        return SHA256.hash(data: data).description
    }

    // MARK: - Authentication

    func isAuthMethodSupported(_ method: AuthMethod) -> Bool {
        return false
    }
}
