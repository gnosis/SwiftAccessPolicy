//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import IdentityAccessDomainModel

/// The registry implements a Service Locator pattern to allow for dependency injection.
public class ApplicationServiceRegistry: AbstractRegistry {

    public static var authenticationService: AuthenticationApplicationService {
        return service(for: AuthenticationApplicationService.self)
    }

    public static var clock: ClockService {
        return service(for: ClockService.self)
    }

    public static var logger: Logger {
        return service(for: Logger.self)
    }

}
