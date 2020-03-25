//
//  AccessService.swift
//  SwiftAccessPolicy
//
//  Created by Andrey Scherbovich on 25.03.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

public class AccessService {
    public var authStatus: AuthStatus {
        return .notAuthenticated
    }

    private var accessPolicy: AccessPolicy
    private var userRepository: UserRepository
    private var clockService: ClockService

    public init(accessPolicy: AccessPolicy,
                userRepository: UserRepository?,
                clockService: ClockService?) {
        self.accessPolicy = accessPolicy
        if let userRepository = userRepository {
            self.userRepository = userRepository
        } else {
            self.userRepository = InMemotyUserRepository()
        }
        if let clockService = clockService {
            self.clockService = clockService
        } else {
            self.clockService = SystemClockService()
        }
    }
}
