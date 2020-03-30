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
        let accessPolicy = AccessPolicy(sessionDuration: 10*60, maxFailedAttempts: 3, blockDuration: 15)
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

    func test_authenticationStatus() {}
    func test_authenticationStatus_whenBlockingPeriodFinished_thenNotBlocked() {}
    func test_authenticationStatus_whenUserNotFound_thenThrows() {}
    func test_logout() {}
    func test_authenticationAttemptsLeft() {}
    func test_isAuthenticationMethodSupported() {}
    func test_isAuthenticationMethodSupported_whenBiometryServiceThrows_thenThrows() {}
    func test_isAuthenticationMethodPossible_whenNotBlocked_thenPossible() {}
    func test_isAuthenticationMethodPossible_whenBlocked_thenNotPossible() {}
    func test_isAuthenticationMethodPossible_whenUserNotFound_thenThrows() {}
    func test_isAuthenticationMethodPossible_whenBiometryServiceThrows_thenThrows() {}
    func test_authenticateUser_whenBlocked_thenReturnsBlocked() {}
    func test_authenticateUser_whenWrongPassword_thenAccessDenied() {}
    func test_authenticateUser_whenCorrectPassword_thenAccessAllowed() {}
    func test_authenticateUser_whenWrongBiometry_thenAccessDenied() {}
    func test_authenticateUser_whenCorrectBiometry_thenAccessAllowed() {}
    func test_authenticateUser_whenUserNotFound_thenThrows() {}
    func test_authenticateUser_whenBiometryServiceThrows_thenThrows() {}
    func test_denyAccess_whenNotExceedingMaxFailedAttempts_thenReturnsNotAuthenticated() {
        // should it invalidate session?
    }
    func test_denyAccess_whenExceedingMaxFailedAttempts_thenAccessBlocked() {
        // check that max failed attempts continues counting
    }
    func test_denyAccess_whenUserNotFound_thenThrows() {}
    func test_allowAccess() {
        // test that always updates session renewed time
        // renews failed attempts counter
    }
    func test_allowAccess_whenUserNotFound_thenThrows() {}
}
