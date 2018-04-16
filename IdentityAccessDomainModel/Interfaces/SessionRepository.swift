//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public protocol SessionRepository {

    func save(_ session: XSession) throws
    func latestSession() -> XSession?
    func nextId() -> SessionID

}
