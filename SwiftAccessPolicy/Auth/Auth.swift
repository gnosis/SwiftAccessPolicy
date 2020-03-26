//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Valid authentication methods supported by the application
public struct AuthMethod: OptionSet {

    public let rawValue: Int

    public static let password = AuthMethod(rawValue: 1 << 0)
    public static let touchID = AuthMethod(rawValue: 1 << 1)
    public static let faceID = AuthMethod(rawValue: 1 << 2)

    public static let biometry: AuthMethod = [.touchID, .faceID]

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// Represents authentication intent
public enum AuthRequest {
    case password(String)
    case biometry
}

/// Authentication status
/// For blocked status return the left blocking time interval
public enum AuthStatus {
    case authenticated
    case notAuthenticated
    case blocked(TimeInterval)
}
