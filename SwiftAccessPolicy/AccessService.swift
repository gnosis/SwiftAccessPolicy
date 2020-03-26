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

    /// Checks wheter user is authenticated.
    ///
    /// - Parameters:
    ///   - userID: unique user ID
    ///   - time: current time
    /// - Returns: authentication status
    public func authenticationStatus(userID: UUID, at time: Date = Date()) throws -> AuthStatus {
        guard let user = userRepository.user(userID: userID) else {
            throw AccessServiceError.userDoesNotExist
        }
        if let sessionRenewedTime = user.sessionRenewedAt,
            sessionRenewedTime.addingTimeInterval(accessPolicy.sessionDuration) > time {
            return .authenticated
        } else if let accessBlockedTime = user.accessBlockedAt,
            accessBlockedTime.addingTimeInterval(accessPolicy.blockDuration) > time {
            return .blocked
        } else {
            return .notAuthenticated
        }
    }

    // TODO
    public func logout() {}

    /// Queries the operating system and application capabilities to determine if the `method` of authentication
    /// supported.
    ///
    /// - Parameter method: authentication method
    /// - Returns: True if the authentication `method` is supported.
    public func isAuthenticationMethodSupported(_ method: AuthMethod) -> Bool {
        var supportedSet: AuthMethod = .password
        if biometryService.biometryType == .touchID {
            supportedSet.insert(.touchID)
        }
        if biometryService.biometryType == .faceID {
            supportedSet.insert(.faceID)
        }
        return supportedSet.intersects(with: method)
    }

    /// Queries current state of the app (for example, session state) and the state of biometric service to
    /// determine if the authentication `method` can potentially succeed at this time. Returns false if
    /// access is blocked.
    ///
    /// - Parameters:
    ///   - userID: unique user ID
    ///   - method: The authentication type
    /// - Throws: AccessServiceError
    /// - Returns: True if the authentication `method` can succeed.
    public func isAuthenticationMethodPossible(
        userID: UUID, method: AuthMethod, at time: Date = Date()) throws -> Bool {
        guard try authenticationStatus(userID: userID, at: time) != .blocked else { return false }
        var possibleSet: AuthMethod = .password
        if isAuthenticationMethodSupported(.faceID) {
            possibleSet.insert(.faceID)
        }
        if isAuthenticationMethodSupported(.touchID) {
            possibleSet.insert(.touchID)
        }
        return possibleSet.intersects(with: method)
    }


    /// Authenticate user
    ///
    /// - Parameters:
    ///   - userID: unique user ID
    ///   - password: not encrypted user password to authenticate with
    ///   - time: authentication time
    /// - Throws: AccessServiceError, BiometryAuthenticationError
    /// - Returns: authentication result
    public func authenticateUser(userID: UUID, request: AuthRequest, at time: Date = Date()) throws -> AuthStatus {
        guard try authenticationStatus(userID: userID, at: time) != .blocked else { return .blocked }
        switch request {
        case .password(let password):
            let user = userRepository.user(userID: userID)!
            if try user.encryptedPassword == encrypted(password) {
                return try allowAccess(userID: userID, at: time)
            } else {
                return try denyAccess(userID: userID, at: time)
            }
        case .biometry:
            do {
                if try biometryService.authenticate() {
                    return try allowAccess(userID: userID, at: time)
                } else {
                    return try denyAccess(userID: userID, at: time)
                }
            } catch BiometryAuthenticationError.cancelled {
                return try denyAccess(userID: userID, at: time)
            }
        }
    }

    /// Force deny acess for user.
    ///
    /// - Parameters:
    ///   - userID: unique user ID
    ///   - time: authentication time
    /// - Throws: AccessServiceError
    /// - Returns: authentication result
    public func denyAccess(userID: UUID, at time: Date = Date()) throws -> AuthStatus {
        guard var user = userRepository.user(userID: userID) else {
            throw AccessServiceError.userDoesNotExist
        }
        user.denyAccess()
        if user.failedAuthAttempts > accessPolicy.maxFailedAttempts {
            user.blockAccess(at: time)
            return .blocked
        }
        userRepository.save(user: user)
        return .notAuthenticated
    }

    /// Force allow acess for user.
    ///
    /// - Parameters:
    ///   - userID: unique user ID
    ///   - time: authentication time
    /// - Throws: AccessServiceError
    /// - Returns: authentication result
    public func allowAccess(userID: UUID, at time: Date = Date()) throws -> AuthStatus {
        guard var user = userRepository.user(userID: userID) else {
            throw AccessServiceError.userDoesNotExist
        }
        user.renewSession(at: time)
        userRepository.save(user: user)
        return .authenticated
    }
}
