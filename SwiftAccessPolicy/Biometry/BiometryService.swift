//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Biometric authentication types
///
/// - none: no biometric authentication
/// - touchID: touch ID
/// - faceID: face ID
public enum BiometryType {
    case none, touchID, faceID
}

/// Represents biometric authentication service provided by the operating system
public protocol BiometryService {

    /// Available biometry type
    ///
    /// - Throws: error if underlying service errored
    /// - Returns: available biometry type on the device
    func biometryType() throws -> BiometryType

    /// Activates biometric authentication. This requests user to allow biometric authentication.
    ///
    /// - Throws: error if underlying service errored
    /// - Returns: True if user successfully activated biometry
    func activate() throws -> Bool

    /// Authenticates user with activated biometry type.
    ///
    /// - Throws: Throws error when authentication was cancelled by user, system, or underlying auth mechanism failed.
    /// - Returns: True if user authenticated successfully, false when authentication credentials were wrong.
    func authenticate() throws -> Bool

}
