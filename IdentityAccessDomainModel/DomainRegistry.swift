//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Service locator for domain model services and repositories.
public class DomainRegistry: AbstractRegistry {

    public static var biometricAuthenticationService: BiometryService {
        return service(for: BiometryService.self)
    }

    public static var encryptionService: EncryptionService {
        return service(for: EncryptionService.self)
    }

    public static var userRepository: SingleUserRepository {
        return service(for: SingleUserRepository.self)
    }

    public static var identityService: IdentityService {
        return service(for: IdentityService.self)
    }

    public static var gatekeeperRepository: SingleGatekeeperRepository {
        return service(for: SingleGatekeeperRepository.self)
    }
}
