//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import IdentityAccessDomainModel

public class InMemorySessionRepository: SessionRepository {

    private var session: XSession?
    private var policy: AuthenticationPolicy?

    public init() {}

    public func save(_ session: XSession) throws {
        self.session = session
    }

    public func latestSession() -> XSession? {
        return session
    }

    public func nextId() -> SessionID {
        do {
            return try SessionID(String(repeating: "a", count: 36))
        } catch let e {
            preconditionFailure("Failed to create session ID: \(e)")
        }
    }

    public func save(_ policy: AuthenticationPolicy) throws {
        self.policy = policy
    }

    public func authenticationPolicy() -> AuthenticationPolicy? {
        return policy
    }

}
