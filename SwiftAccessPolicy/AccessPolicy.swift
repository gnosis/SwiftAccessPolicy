//
//  AccessPolicy.swift
//  SwiftAccessPolicy
//
//  Created by Andrey Scherbovich on 25.03.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

public struct AccessPolicy {
    public let sessionDuration: TimeInterval
    public let maxFailedAttempts: Int
    public let blockDuration: TimeInterval

    public init(
        sessionDuration: TimeInterval,
        maxFailedAttempts: Int,
        blockDuration: TimeInterval) {
        self.sessionDuration = sessionDuration
        self.maxFailedAttempts = maxFailedAttempts
        self.blockDuration = blockDuration
    }
}
