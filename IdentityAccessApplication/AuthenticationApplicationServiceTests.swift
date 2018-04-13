//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import IdentityAccessApplication

class AuthenticationApplicationServiceTests: ApplicationServiceTestCase {

    let password = "MyPassword1"

    func test_registerUser_createsUser() throws {
        try authenticationService.registerUser(password: password)
        XCTAssertNotNil(userRepository.primaryUser())
    }

    func test_registerUser_activatesBiometry() throws {
        try authenticationService.registerUser(password: password)
        XCTAssertTrue(biometricService.didActivate)
    }

}
