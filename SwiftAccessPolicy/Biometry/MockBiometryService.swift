//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Mock biometric service for testing purposes.
public class MockBiometryService: BiometryService {
    private var savedActivationCompletion: (() -> Void)?
    public var biometryAuthenticationResult = true
    private var savedAuthenticationCompletion: ((Bool) -> Void)?
    public var shouldThrow = false

    public init() {}

    public var _biometryType: BiometryType = .touchID
    public func biometryType() throws -> BiometryType {
        if shouldThrow {
            throw BiometryServiceError.authenticationCanceled
        }
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
        if shouldThrow {
            throw BiometryServiceError.authenticationCanceled
        }
        didActivate = true
        return didActivate
    }

    public var shouldAuthenticate = false
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
