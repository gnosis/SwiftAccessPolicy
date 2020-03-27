//
//  AccessService.swift
//  SwiftAccessPolicy
//
//  Created by Andrey Scherbovich on 25.03.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import CryptoKit

public enum AccessServiceError: Error {
    case userAlreadyExists
    case userDoesNotExist
    case couldNotEncodeStringToUTF8Data
}

public class AccessService {
    private var accessPolicy: AccessPolicy
    private var userRepository: UserRepository
    private var clockService: ClockService
    private var biometryService: BiometryService

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

    /// Registers user
    ///
    /// - Parameters:
    ///   - userID: unique user ID
    ///   - password: password
    /// - Throws: AccessServiceError
    /// - Returns: registered user id
    public func registerUser(userID: UUID = UUID(), password: String) throws -> UUID {
        do {
            _ = try user(id: userID)
            throw AccessServiceError.userAlreadyExists
        } catch {}
        let user = User(userID: userID, encryptedPassword: try encrypted(password))
        userRepository.save(user: user)
        return user.id
    }

    // TODO: should we store biometry activatoin status for the user?
    public func requestBiometryAccess(userID: UUID) throws -> Bool {
        return try biometryService.activate()
    }

    public func deleteUser(userID: UUID) throws {
        try _ = user(id: userID)
        userRepository.delete(userID: userID)
    }

    public func users() -> [User] {
        return userRepository.users()
    }

    /// Update user password.
    ///
    /// - Parameters:
    ///   - userID: unique user ID
    ///   - password: new password
    /// - Throws: AccessServiceError
    public func updateUserPassword(userID: UUID, password: String) throws {
        var user = try self.user(id: userID)
        user.updatePassword(encryptedPassword: try encrypted(password))
        userRepository.save(user: user)
    }

    /// Verifies if the password is correct
    ///
    /// - Parameters:
    ///   - userID: unique user ID
    ///   - password: password in plain text
    /// - Throws: AccessServiceError
    /// - Returns: true, if password matches user's password, false otherwise.
    public func verifyPassword(userID: UUID, password: String) throws -> Bool {
        let user = try self.user(id: userID)
        return try user.encryptedPassword == encrypted(password)
    }

    private func encrypted(_ string: String) throws -> String {
        guard let data = string.data(using: .utf8) else {
            throw AccessServiceError.couldNotEncodeStringToUTF8Data
        }
        return SHA256.hash(data: data).description
    }

    private func user(id: UUID) throws -> User {
        guard let user = userRepository.user(userID: id) else {
            throw AccessServiceError.userDoesNotExist
        }
        return user
    }

    // MARK: - Authentication

    /// Checks wheter user is authenticated.
    ///
    /// - Parameters:
    ///   - userID: unique user ID
    ///   - time: current time
    /// - Throws: AccessServiceError
    /// - Returns: authentication status
    public func authenticationStatus(userID: UUID, at time: Date = Date()) throws -> AuthStatus {
        let user = try self.user(id: userID)
        if let sessionRenewedTime = user.sessionRenewedAt,
            sessionRenewedTime.addingTimeInterval(accessPolicy.sessionDuration) > time {
            return .authenticated
        } else if let accessBlockedTime = user.accessBlockedAt,
            accessBlockedTime.addingTimeInterval(accessPolicy.blockDuration) > time {
            return .blocked(accessBlockedTime.addingTimeInterval(accessPolicy.blockDuration).timeIntervalSince(time))
        } else {
            return .notAuthenticated
        }
    }

    // TODO
    public func logout() {}

    // TODO
    public func authenticationAttemptsLeft(userID: UUID) -> Int {
        return 1
    }

    /// Queries the operating system and application capabilities to determine if the `method` of authentication
    /// supported.
    ///
    /// - Parameter method: authentication method
    /// - Throws: BiometryServiceError
    /// - Returns: True if the authentication `method` is supported.
    public func isAuthenticationMethodSupported(_ method: AuthMethod) throws -> Bool {
        var supportedSet: AuthMethod = .password
        switch try biometryService.biometryType() {
        case .touchID: supportedSet.insert(.touchID)
        case .faceID: supportedSet.insert(.faceID)
        default: break
        }
        return !supportedSet.isDisjoint(with: method)
    }

    /// Queries current state of the app (for example, session state) and the state of biometric service to
    /// determine if the authentication `method` can potentially succeed at this time. Returns false if
    /// access is blocked.
    ///
    /// - Parameters:
    ///   - userID: unique user ID
    ///   - method: The authentication type
    /// - Throws: AccessServiceError, BiometryServiceError
    /// - Returns: True if the authentication `method` can succeed.
    public func isAuthenticationMethodPossible(
        userID: UUID, method: AuthMethod, at time: Date = Date()) throws -> Bool {
        if case AuthStatus.blocked(_) = try authenticationStatus(userID: userID, at: time) {
            return false
        }
        return try isAuthenticationMethodSupported(method)
    }

    /// Authenticate user
    ///
    /// - Parameters:
    ///   - userID: unique user ID
    ///   - password: not encrypted user password to authenticate with
    ///   - time: authentication time
    /// - Throws: AccessServiceError, BiometryServiceError
    /// - Returns: authentication result
    public func authenticateUser(userID: UUID, request: AuthRequest, at time: Date = Date()) throws -> AuthStatus {
        if case let AuthStatus.blocked(blockingTimeLeft) = try authenticationStatus(userID: userID, at: time) {
            return .blocked(blockingTimeLeft)
        }
        switch request {
        case .password(let password):
            if try verifyPassword(userID: userID, password: password) {
                return try allowAccess(userID: userID, at: time)
            } else {
                return try denyAccess(userID: userID, at: time)
            }
        case .biometry:
            if try biometryService.authenticate() {
                return try allowAccess(userID: userID, at: time)
            } else {
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
        var user = try self.user(id: userID)
        user.denyAccess()
        if user.failedAuthAttempts > accessPolicy.maxFailedAttempts {
            user.blockAccess(at: time)
        }
        userRepository.save(user: user)
        return try authenticationStatus(userID: userID, at: time)
    }

    /// Force allow acess for user.
    ///
    /// - Parameters:
    ///   - userID: unique user ID
    ///   - time: authentication time
    /// - Throws: AccessServiceError
    /// - Returns: authentication result
    public func allowAccess(userID: UUID, at time: Date = Date()) throws -> AuthStatus {
        var user = try self.user(id: userID)
        user.renewSession(at: time)
        userRepository.save(user: user)
        return .authenticated
    }
}
