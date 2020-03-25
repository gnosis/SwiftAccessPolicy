//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Represents biometric authentication service provided by the operating system
public protocol BiometricAuthenticationService {

    /// True if biometric authentication may succeed
    var isAuthenticationAvailable: Bool { get }

    /// Available biometry type
    var biometryType: BiometryType { get }

    /// Activates biometric authentication. This requests user to allow biometric authentication.
    ///
    /// - Throws: error if underlying service errored
    func activate() throws

    /// Authenticates user with activated biometry type.
    ///
    /// - Returns: True if user authenticated successfully, false when authentication credentials were wrong.
    /// - Throws: Throws error when authentication was cancelled by user, system, or underlying auth mechanism failed.
    func authenticate() throws -> Bool

}
