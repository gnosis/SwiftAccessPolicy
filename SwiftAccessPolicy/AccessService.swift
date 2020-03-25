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
    private var biometryService: BiometryService

    enum AccessServiceError: Error {
        case userAlreadyExists
        case userDoesNotExist
        case couldNotEncodeStringToUTF8Data
    }

    public init(accessPolicy: AccessPolicy, biometryReason: BiometryReason) {
        self.accessPolicy = accessPolicy
        self.userRepository = InMemotyUserRepository()
        self.clockService = SystemClockService()
        self.biometryService = SystemBiometryService(biometryReason: biometryReason)
    }

    // MARK: - Services

    public func setUserRepository(_ userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    public func setClockService(_ clockService: ClockService) {
        self.clockService = clockService
    }

    public func setBiometryService(_ biometryService: BiometryService) {
        self.biometryService = biometryService
    }

    // MARK: - Users management

    public func registerUser(userID: UUID = UUID(), password: String) throws {
        guard userRepository.user(userID: userID) == nil else {
            throw AccessServiceError.userAlreadyExists
        }
        let user = User(userID: userID, encryptedPassword: try encrypted(password))
        userRepository.save(user: user)
    }

    public func deleteUser(userID: UUID) throws {
        guard userRepository.user(userID: userID) != nil else {
            throw AccessServiceError.userDoesNotExist
        }
        userRepository.delete(userID: userID)
    }

    public func users() -> [User] {
        return userRepository.users()
    }

    public func updateUserPassword(userID: UUID, password: String) throws {
        guard var user = userRepository.user(userID: userID) else {
            throw AccessServiceError.userDoesNotExist
        }
        user.updatePassword(encryptedPassword: try encrypted(password))
        userRepository.save(user: user)
    }

    public func verifyPassword(userID: UUID, password: String) throws -> Bool {
        return false
    }

    private func encrypted(_ string: String) throws -> String {
        guard let data = string.data(using: .utf8) else {
            throw AccessServiceError.couldNotEncodeStringToUTF8Data
        }
        return SHA256.hash(data: data).description
    }

    // MARK: - Authentication

    public func isAuthMethodSupported(_ method: AuthMethod) -> Bool {
        var supportedSet: AuthMethod = .password
        if biometryService.biometryType == .touchID {
            supportedSet.insert(.touchID)
        }
        if biometryService.biometryType == .faceID {
            supportedSet.insert(.faceID)
        }
        return supportedSet.intersects(with: method)
    }
}
