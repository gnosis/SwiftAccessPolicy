//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Mock biometric service for testing purposes.
public class MockBiometryService: BiometryService {
    public var biometryReason: BiometryReason
    public var shouldThrow = false

    public init(biometryReason: BiometryReason) {
        self.biometryReason = biometryReason
    }

    public var _biometryType: BiometryType = .touchID
    public func biometryType() throws -> BiometryType {
        if shouldThrow {
            throw BiometryServiceError.authenticationCanceled
        }
        return _biometryType
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
}
