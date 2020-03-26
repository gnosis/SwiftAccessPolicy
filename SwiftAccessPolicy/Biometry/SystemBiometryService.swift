//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import LocalAuthentication

// TODO: better name
public enum BiometryAuthenticationError: Error {
    case cancelled
}

public struct BiometryReason {
    let touchIDActivation: String
    let touchIDAuth: String
    let faceIDActivation: String
    let faceIDAuth: String
    let unrecognizedBiometryType: String

    public init(touchIDActivation: String,
                touchIDAuth: String,
                faceIDActivation: String,
                faceIDAuth: String,
                unrecognizedBiometryType: String) {
        self.touchIDActivation = touchIDActivation
        self.touchIDAuth = touchIDAuth
        self.faceIDActivation = faceIDActivation
        self.faceIDAuth = faceIDAuth
        self.unrecognizedBiometryType = unrecognizedBiometryType
    }
}

/// Biometric error
///
/// - unexpectedBiometryType: encountered unrecognized biometry type.
public enum BiometricServiceError: Error {
    case unexpectedBiometryType
}

public final class SystemBiometryService: BiometryService {

    private let contextProvider: () -> LAContext
    private var context: LAContext
    private let biometryReason: BiometryReason

    /// Creates new biometric service with LAContext provider.
    ///
    /// Autoclosure here means that LAContext will be fetched every time from the closure.
    /// By default, it will be created anew when contextProvider() is called.
    /// We have to re-create LAContext so that previous biometry authentication is not reused by the system.
    ///
    /// - Parameter localAuthenticationContext: closure that returns LAContext.
    public init(biometryReason: BiometryReason,
                localAuthenticationContext: @escaping @autoclosure () -> LAContext = LAContext()) {
        self.biometryReason = biometryReason
        self.contextProvider = localAuthenticationContext
        context = contextProvider()
    }

    public var isAuthenticationAvailable: Bool {
        context = contextProvider()
        context.interactionNotAllowed = false
        var evaluationError: NSError?
        let result = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &evaluationError)
        if let error = evaluationError {
            // TODO
//            ApplicationServiceRegistry.logger.error("Can't evaluate policy: \(error)")
        }
        return result
    }

    public var biometryType: BiometryType {
        guard isAuthenticationAvailable else { return .none }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .none:
// TODO: Could not cast value of type 'IdentityAccessImplementationsTests.MockLogger'
//            ApplicationServiceRegistry.logger.error("Received unexpected biometry type: none")
            return .none
        @unknown default:
            return .none
        }
    }

    public func activate() throws -> Bool {
        var reason: String
        switch biometryType {
        case .touchID:
            reason = biometryReason.touchIDActivation
        case .faceID:
            reason = biometryReason.faceIDActivation
        case .none:
            reason = biometryReason.unrecognizedBiometryType
        }
        return try requestBiometry(reason: reason)
    }

    public func authenticate() throws -> Bool {
        var reason: String
        switch biometryType {
        case .touchID:
            reason = biometryReason.touchIDAuth
        case .faceID:
            reason = biometryReason.faceIDAuth
        case .none:
            reason = biometryReason.unrecognizedBiometryType
        }
        return try requestBiometry(reason: reason)
    }

    // TODO: implement as result, without throw
    @discardableResult
    private func requestBiometry(reason: String) throws -> Bool {
        guard isAuthenticationAvailable else { return false }
        var success: Bool = false
        var evaluationError: Error?
        let semaphore = DispatchSemaphore(value: 0)
        let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
        context.evaluatePolicy(policy, localizedReason: reason) { result, errorOrNil in
            evaluationError = errorOrNil
            success = result
            semaphore.signal()
        }
        semaphore.wait()
        if let error = evaluationError {
            guard let laError = error as? LAError else { throw error }

            switch laError.code {
            case .authenticationFailed:
                return false
            case .userCancel,
                 .appCancel,
                 .systemCancel,
                 .userFallback,
                 .passcodeNotSet,
                 .biometryNotEnrolled,
                 .biometryNotAvailable,
                 .biometryLockout:
                throw BiometryAuthenticationError.cancelled

            case .invalidContext,
                 .notInteractive:
                fallthrough

            default:
                throw error
            }
        }
        return success
    }

}
