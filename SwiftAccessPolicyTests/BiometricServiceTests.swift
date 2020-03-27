//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
import LocalAuthentication
@testable import SwiftAccessPolicy

class BiometryServiceTests: XCTestCase {
    var biometryService: BiometryService!
    let context = MockLAContext()

    override func setUp() {
        super.setUp()
        let biometryReason = BiometryReason(touchIDActivation: "",
                                            touchIDAuth: "",
                                            faceIDActivation: "",
                                            faceIDAuth: "",
                                            unrecognizedBiometryType: "")
        biometryService = SystemBiometryService(biometryReason: biometryReason,
                                                localAuthenticationContext: self.context)
    }

    func test_activate_whenBiometryIsNotAvailable_thenIsNotActivated() throws {
        context.canEvaluatePolicy = false
        try activate()
        XCTAssertFalse(context.evaluatePolicyInvoked)
    }

    func test_activate_whenBiometryIsAvailable_thenIsActivated() throws {
        context.canEvaluatePolicy = true
        try activate()
        XCTAssertTrue(context.evaluatePolicyInvoked)
    }

    func test_authenticate_whenAvailableAndSuccess_thenAuthenticated() {
        context.canEvaluatePolicy = true
        XCTAssertTrue(authenticate())
        XCTAssertTrue(context.evaluatePolicyInvoked)
    }

    func test_authenticate_whenNotAvailable_thenNotAuthenticated() {
        context.canEvaluatePolicy = false
        XCTAssertFalse(authenticate())
        XCTAssertFalse(context.evaluatePolicyInvoked)
    }

    func test_authenticate_whenAvailableAndFails_thenNotAuthenticated() {
        context.canEvaluatePolicy = true
        context.policyShouldSucceed = false
        XCTAssertFalse(authenticate())
    }

    @available(iOS 10.0, *)
    func test_iOS_10_0_biometryType_whenNotAvailable_thenNone() {
        context.canEvaluatePolicy = false
        XCTAssertEqual(try! biometryService.biometryType(), .none)
    }

    @available(iOS 10.0, *)
    func test_iOS_10_0_biometryType_whenAvailable_thenTouchID() {
        context.canEvaluatePolicy = true
        XCTAssertEqual(try! biometryService.biometryType(), .touchID)
    }

    @available(iOS 11.0, *)
    func test_iOS_11_0_biometryType_whenNotAvailable_thenNone() {
        context.canEvaluatePolicy = false
        XCTAssertEqual(try! biometryService.biometryType(), .none)
    }

    @available(iOS 11.0, *)
    func test_iOS_11_0_biometryType_whenAvailableAndBiometryFaceID_thenFaceID() {
        context.canEvaluatePolicy = true
        context.isBiometryTypeFaceID = true
        XCTAssertEqual(try! biometryService.biometryType(), .faceID)
    }

    @available(iOS 11.0, *)
    func test_iOS_11_0_biometryType_whenAvailableAndBiometryTouchID_thenFaceID() {
        context.canEvaluatePolicy = true
        context.isBiometryTypeFaceID = false
        context.isBiometryTypeNone = false
        XCTAssertEqual(try! biometryService.biometryType(), .touchID)
    }

    @available(iOS 11.0, *)
    func test_iOS_11_0_biometryType_whenAvailableAndBiometryNone_thenNone() {
        context.canEvaluatePolicy = true
        context.isBiometryTypeFaceID = false
        context.isBiometryTypeNone = true
        XCTAssertEqual(try! biometryService.biometryType(), .none)
    }

    func test_whenCheckingPossibilityToEvaluatePolicyFails_thenErrorIsThrown() {
        context.evaluatePolicyError = LAError(.appCancel)
        XCTAssertThrowsError(try biometryService.activate())
    }

    func test_whenEvaluatingPolicyFails_thenErrorIsThrown() {
        context.evaluatePolicyError = LAError(.userCancel)
        XCTAssertThrowsError(try biometryService.authenticate())
    }
}

extension BiometryServiceTests {

    func authenticate() -> Bool {
        context.evaluatePolicyInvoked = false
        let success = try! biometryService.authenticate()
        return success
    }

    func activate() throws {
        context.evaluatePolicyInvoked = false
        _ = try biometryService.activate()
    }
}

class MockLAContext: LAContext {
    var isBiometryTypeFaceID = false
    var isBiometryTypeNone = false
    override var biometryType: LABiometryType {
        return isBiometryTypeFaceID ? .faceID : (isBiometryTypeNone ? .none : .touchID)
    }

    var canEvaluatePolicy = true
    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        return canEvaluatePolicy
    }

    var evaluatePolicyInvoked = false
    var policyShouldSucceed = true
    var evaluatePolicyError: LAError?
    override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void) {
        evaluatePolicyInvoked = true
        if let evaluatePolicyError = evaluatePolicyError {
            reply(false, evaluatePolicyError)
            return
        }
        reply(policyShouldSucceed, nil)
    }
}
