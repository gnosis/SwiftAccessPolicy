//
//  AccessServiceTests.swift
//  SwiftAccessPolicyTests
//
//  Created by Andrey Scherbovich on 30.03.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import SwiftAccessPolicy

class AccessServiceTests: XCTestCase {

    var accessService: AccessService!
    var mockBiometryService = MockBiometryService()

    override func setUpWithError() throws {
        let accessPolicy = AccessPolicy(sessionDuration: 10*60, maxFailedAttempts: 1, blockDuration: 5)
        let biometryReason = BiometryReason(touchIDActivation: "Please activate TouchID",
                                            touchIDAuth: "Login with TouchID",
                                            faceIDActivation: "Please activate FaceID",
                                            faceIDAuth: "Login with FaceID",
                                            unrecognizedBiometryType: "Unrecognised biometry type.")
        accessService = AccessService(accessPolicy: accessPolicy, biometryReason: biometryReason)
        accessService.biometryService = mockBiometryService
    }

    let sha256Hashes = [
        "password": "SHA256 digest: 5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8",
        "password2": "SHA256 digest: 6cf615d5bcaac778352a8f1f3360d23f02f34ec182e259897fd6ce485d7870d4"
    ]

    // MARK: - Users management

    func test_registerUser_savesUserInRepoWithEncryptedPassword() throws {
        try sha256Hashes.forEach { key, value in
            let userID = try accessService.registerUser(password: key)
            let user = try accessService.user(id: userID)
            XCTAssertEqual(user.id, userID)
            XCTAssertEqual(user.encryptedPassword, value)
        }
    }

    func test_registerUser_whenUserAlreadyExists_thenThrows() throws {
        let userID = try accessService.registerUser(password: "password")
        XCTAssertThrowsError(try accessService.registerUser(userID: userID, password: "password2")) { error in
            XCTAssertEqual(error as? AccessServiceError, .userAlreadyExists)
        }
    }

    func test_requestBiometryAccess_callsBiometryService() throws {
        XCTAssertFalse(mockBiometryService.didActivate)
        try accessService.requestBiometryAccess(userID: UUID())
        XCTAssertTrue(mockBiometryService.didActivate)
    }

    func test_requestBiometryAccess_whenBiometryServiceThrows_thenThrows() {
        mockBiometryService.shouldThrow = true
        XCTAssertThrowsError(try accessService.requestBiometryAccess(userID: UUID()))
    }

    func test_deleteUser_removesUserFromRepo() throws {
        let userID = try accessService.registerUser(password: "password")
        XCTAssertEqual(accessService.users().count, 1)
        try accessService.deleteUser(userID: userID)
        XCTAssertEqual(accessService.users().count, 0)
    }

    func test_deleteUser_whenUserDoesNotExist_thenThrows() {
        XCTAssertThrowsError(try accessService.deleteUser(userID: UUID())) { error in
            XCTAssertEqual(error as? AccessServiceError, .userDoesNotExist)
        }
    }

    func test_users() throws {
        XCTAssertEqual(accessService.users().count, 0)
        try accessService.registerUser(password: "password")
        try accessService.registerUser(password: "password2")
        XCTAssertEqual(accessService.users().count, 2)
    }

    func test_updateUserPassword_savesUserInRepoWithEncryptedPassword() throws {
        let userID = try accessService.registerUser(password: "password")
        try accessService.updateUserPassword(userID: userID, password: "password2")
        let user = try accessService.user(id: userID)
        XCTAssertEqual(user.encryptedPassword, sha256Hashes["password2"])
    }

    func test_updateUserPassword_whenUserNotFound_thenThrows() {
        XCTAssertThrowsError(try accessService.updateUserPassword(userID: UUID(), password: "password")) { error in
            XCTAssertEqual(error as? AccessServiceError, .userDoesNotExist)
        }
    }

    func test_verifyPassword() throws {
        let userID = try accessService.registerUser(password: "password")
        XCTAssertTrue(try accessService.verifyPassword(userID: userID, password: "password"))
        XCTAssertFalse(try accessService.verifyPassword(userID: userID, password: "password2"))
    }

    func test_verifyPassword_whenUserNotFound_thenThrows() {
        XCTAssertThrowsError(try accessService.verifyPassword(userID: UUID(), password: "password")) { error in
            XCTAssertEqual(error as? AccessServiceError, .userDoesNotExist)
        }
    }

    // MARK: - Authentication

    func test_authenticationStatus_whenUserRegistered_thenNotAuthenticated() throws {
        let userID = try accessService.registerUser(password: "password")
        XCTAssertEqual(try accessService.authenticationStatus(userID: userID), .notAuthenticated)
    }

    func test_authenticationStatus_whenUserAccessAllowed_thenAuthenticated() throws {
        let userID = try accessService.registerUser(password: "password")
        try accessService.allowAccess(userID: userID)
        XCTAssertEqual(try accessService.authenticationStatus(userID: userID), .authenticated)
    }

    /// accessPolicy.maxFailedAttempts == 1; accessPolicy.blockDuration == 5
    func test_authenticationStatus_blocked() throws {
        let userID = try accessService.registerUser(password: "password")
        XCTAssertEqual(try accessService.denyAccess(userID: userID), .notAuthenticated)
        XCTAssertEqual(try accessService.authenticationStatus(userID: userID), .notAuthenticated)
        let now = Date()
        XCTAssertEqual(try accessService.denyAccess(userID: userID, at: now), .blocked(5))
        XCTAssertEqual(try accessService.authenticationStatus(userID: userID, at: now), .blocked(5))
        XCTAssertEqual(try accessService.authenticationStatus(
            userID: userID, at: now.addingTimeInterval(4)), .blocked(1))
        XCTAssertEqual(try accessService.authenticationStatus(
            userID: userID, at: now.addingTimeInterval(5)), .notAuthenticated)
    }

    func test_authenticationStatus_whenUserNotFound_thenThrows() {
        XCTAssertThrowsError(try accessService.authenticationStatus(userID: UUID())) { error in
            XCTAssertEqual(error as? AccessServiceError, .userDoesNotExist)
        }
    }

    func test_isAuthenticationMethodSupported() throws {
        mockBiometryService._biometryType = .none
        XCTAssertTrue(try accessService.isAuthenticationMethodSupported(.password))
        XCTAssertFalse(try accessService.isAuthenticationMethodSupported(.biometry))

        mockBiometryService._biometryType = .faceID
        XCTAssertTrue(try accessService.isAuthenticationMethodSupported(.password))
        XCTAssertTrue(try accessService.isAuthenticationMethodSupported(.faceID))
        XCTAssertFalse(try accessService.isAuthenticationMethodSupported(.touchID))
        XCTAssertTrue(try accessService.isAuthenticationMethodSupported(.biometry))

        mockBiometryService._biometryType = .touchID
        XCTAssertTrue(try accessService.isAuthenticationMethodSupported(.password))
        XCTAssertTrue(try accessService.isAuthenticationMethodSupported(.touchID))
        XCTAssertFalse(try accessService.isAuthenticationMethodSupported(.faceID))
        XCTAssertTrue(try accessService.isAuthenticationMethodSupported(.biometry))
    }

    func test_isAuthenticationMethodSupported_whenBiometryServiceThrows_andBiometryRequested_thenThrows() {
        mockBiometryService.shouldThrow = true
        XCTAssertThrowsError(try accessService.isAuthenticationMethodSupported(.touchID))
    }

    func test_isAuthenticationMethodSupported_whenBiometryServiceThrows_andPasswordRequested_thenSuccess() {
        mockBiometryService.shouldThrow = true
        XCTAssertTrue(try accessService.isAuthenticationMethodSupported(.password))
    }

    func test_isAuthenticationMethodPossible_whenNotBlocked_thenReliesOnAuthSupportedMethod() throws {
        let userID = try accessService.registerUser(password: "password")
        mockBiometryService._biometryType = .none
        XCTAssertTrue(try accessService.isAuthenticationMethodPossible(userID: userID, method: .password))
        XCTAssertFalse(try accessService.isAuthenticationMethodPossible(userID: userID, method: .touchID))
    }

    /// accessPolicy.maxFailedAttempts == 1; accessPolicy.blockDuration == 5
    func test_isAuthenticationMethodPossible_whenBlocked_thenNotPossible() throws {
        let userID = try accessService.registerUser(password: "password")
        try accessService.denyAccess(userID: userID)
        XCTAssertTrue(try accessService.isAuthenticationMethodPossible(userID: userID, method: .password))
        let now = Date()
        try accessService.denyAccess(userID: userID, at: now)
        XCTAssertFalse(try accessService.isAuthenticationMethodPossible(userID: userID, method: .password))
        XCTAssertTrue(try accessService.isAuthenticationMethodPossible(
            userID: userID, method: .password, at: now.addingTimeInterval(5)))
    }

    func test_isAuthenticationMethodPossible_whenUserNotFound_thenThrows() {
        XCTAssertThrowsError(try accessService.isAuthenticationMethodPossible(userID: UUID(), method: .password)) {
            error in
            XCTAssertEqual(error as? AccessServiceError, .userDoesNotExist)
        }
    }

    func test_isAuthenticationMethodPossible_whenBiometryServiceThrows_andBiometryRequested_thenThrows() throws {
        mockBiometryService.shouldThrow = true
        let userID = try accessService.registerUser(password: "password")
        XCTAssertThrowsError(try accessService.isAuthenticationMethodPossible(userID: userID, method: .touchID))
    }

    func test_isAuthenticationMethodPossible_whenBiometryServiceThrows_andPasswordRequested_thenSuccess() throws {
        mockBiometryService.shouldThrow = true
        let userID = try accessService.registerUser(password: "password")
        XCTAssertTrue(try accessService.isAuthenticationMethodPossible(userID: userID, method: .password))
    }

    /// accessPolicy.maxFailedAttempts == 1; accessPolicy.blockDuration == 5
    func test_authenticateUser_whenBlocked_thenReturnsBlocked() throws {
        let userID = try accessService.registerUser(password: "password")
        try accessService.denyAccess(userID: userID)
        let now = Date()
        try accessService.denyAccess(userID: userID, at: now)
        XCTAssertEqual(try accessService.authenticateUser(userID: userID, request: .password("password"), at: now),
                       .blocked(5))
    }

    func test_authenticateUser_whenWrongPassword_thenAccessDenied() throws {
        let userID = try accessService.registerUser(password: "password")
        XCTAssertEqual(try accessService.authenticateUser(userID: userID, request: .password("wrong")),
                       .notAuthenticated)
    }

    func test_authenticateUser_whenCorrectPassword_thenAccessAllowed() throws {
        let userID = try accessService.registerUser(password: "password")
        XCTAssertEqual(try accessService.authenticateUser(userID: userID, request: .password("password")),
                       .authenticated)
    }

    func test_authenticateUser_whenWrongBiometry_thenAccessDenied() throws {
        mockBiometryService.shouldAuthenticate = false
        let userID = try accessService.registerUser(password: "password")
        XCTAssertEqual(try accessService.authenticateUser(userID: userID, request: .biometry),
                       .notAuthenticated)
    }

    func test_authenticateUser_whenCorrectBiometry_thenAccessAllowed() throws {
        mockBiometryService.shouldAuthenticate = true
        let userID = try accessService.registerUser(password: "password")
        XCTAssertEqual(try accessService.authenticateUser(userID: userID, request: .biometry),
                       .authenticated)
    }

    func test_authenticateUser_whenUserNotFound_thenThrows() {
        XCTAssertThrowsError(try accessService.authenticateUser(userID: UUID(), request: .biometry)) { error in
            XCTAssertEqual(error as? AccessServiceError, .userDoesNotExist)
        }
    }

    func test_authenticateUser_whenBiometryServiceThrows_thenThrows() throws {
        mockBiometryService.shouldThrow = true
        let userID = try accessService.registerUser(password: "password")
        XCTAssertThrowsError(try accessService.isAuthenticationMethodPossible(userID: userID, method: .touchID))
    }

    func test_denyAccess_whenNotExceedingMaxFailedAttempts_thenReturnsNotAuthenticated() throws {
        let userID = try accessService.registerUser(password: "password")
        XCTAssertEqual(try accessService.denyAccess(userID: userID), .notAuthenticated)
    }

    /// accessPolicy.maxFailedAttempts == 1; accessPolicy.blockDuration == 5
    func test_denyAccess_whenExceedingMaxFailedAttempts_thenAccessBlocked() throws {
        let userID = try accessService.registerUser(password: "password")
        try accessService.denyAccess(userID: userID)
        XCTAssertEqual(try accessService.authenticationAttemptsLeft(userID: userID), 0)
        let now = Date()
        XCTAssertEqual(try accessService.denyAccess(userID: userID, at: now), .blocked(5))
        XCTAssertEqual(try accessService.authenticationAttemptsLeft(userID: userID), 0)
        XCTAssertEqual(try accessService.denyAccess(userID: userID, at: now.addingTimeInterval(10)), .blocked(5))
        XCTAssertEqual(try accessService.authenticationAttemptsLeft(userID: userID), 0)
    }

    func test_denyAccess_whenUserNotFound_thenThrows() {
        XCTAssertThrowsError(try accessService.denyAccess(userID: UUID())) { error in
            XCTAssertEqual(error as? AccessServiceError, .userDoesNotExist)
        }
    }

    /// accessPolicy.maxFailedAttempts == 1; accessPolicy.blockDuration == 5
    func test_allowAccess() throws {
        let userID = try accessService.registerUser(password: "password")
        try accessService.denyAccess(userID: userID)
        try accessService.denyAccess(userID: userID)
        XCTAssertEqual(try accessService.authenticationAttemptsLeft(userID: userID), 0)
        XCTAssertFalse(try accessService.isAuthenticationMethodPossible(userID: userID, method: .password))

        try accessService.allowAccess(userID: userID)
        XCTAssertEqual(try accessService.authenticationAttemptsLeft(userID: userID), 1)
        XCTAssertTrue(try accessService.isAuthenticationMethodPossible(userID: userID, method: .password))
    }

    func test_allowAccess_whenUserNotFound_thenThrows() {
        XCTAssertThrowsError(try accessService.allowAccess(userID: UUID())) { error in
            XCTAssertEqual(error as? AccessServiceError, .userDoesNotExist)
        }
    }

    func test_logout() throws {
        let userID = try accessService.registerUser(password: "password")
        try accessService.allowAccess(userID: userID)
        XCTAssertEqual(try accessService.authenticationStatus(userID: userID), .authenticated)
        try accessService.logout(userID: userID)
        XCTAssertEqual(try accessService.authenticationStatus(userID: userID), .notAuthenticated)
    }

    func test_logout_whenUserNotFound_thenThrows() {
        XCTAssertThrowsError(try accessService.logout(userID: UUID())) { error in
            XCTAssertEqual(error as? AccessServiceError, .userDoesNotExist)
        }
    }

    func test_authenticationAttemptsLeft_whenUserNotFound_thenThrows() {
        XCTAssertThrowsError(try accessService.authenticationAttemptsLeft(userID: UUID())) { error in
            XCTAssertEqual(error as? AccessServiceError, .userDoesNotExist)
        }
    }
}
