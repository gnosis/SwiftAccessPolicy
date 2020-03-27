//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import IdentityAccessDomainModel

/// Mock biometric service for testing purposes.
public class MockBiometryService: BiometryService {
    private var savedActivationCompletion: (() -> Void)?
    public var biometryAuthenticationResult = true
    private var savedAuthenticationCompletion: ((Bool) -> Void)?
    private var shouldAuthenticate = false

    public func allowAuthentication() {
        shouldAuthenticate = true
    }

    public func prohibitAuthentication() {
        shouldAuthenticate = false
    }

    public init() {}

    public var _biometryType: BiometryType = .touchID
    public func biometryType() throws -> BiometryType {
        return _biometryType
    }

    public var shouldActivateImmediately = false
    public func activate(completion: @escaping () -> Void) {
        _ = try? activate()
        if shouldActivateImmediately {
            completion()
        } else {
            savedActivationCompletion = completion
        }
    }

    public var didActivate = false
    public func activate() throws -> Bool {
        didActivate = true
        return didActivate
    }

    public func authenticate() -> Bool {
        return shouldAuthenticate
    }

    public func completeActivation() {
        savedActivationCompletion?()
    }

    public var shouldAuthenticateImmediately = false
    public func authenticate(completion: @escaping (Bool) -> Void) {
        if shouldAuthenticateImmediately {
            completion(biometryAuthenticationResult)
        } else {
            savedAuthenticationCompletion = completion
        }
    }

    public func completeAuthentication(result: Bool) {
        savedAuthenticationCompletion?(result)
    }

}
