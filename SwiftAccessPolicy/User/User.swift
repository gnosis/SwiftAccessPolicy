//
//  User.swift
//  SwiftAccessPolicy
//
//  Created by Andrey Scherbovich on 25.03.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

public struct User {
    let id: UUID
    private var encryptedPassword: String
    private var sessionRenewedAt: Date?
    private var faileAuthAttempts: Int?
    private var accessBlockedAt: Date?

    public init(userID: UUID, encryptedPassword: String) {
        self.id = userID
        self.encryptedPassword = encryptedPassword
    }

    mutating func updatePassword(encryptedPassword: String) {
        self.encryptedPassword = encryptedPassword
    }

    mutating func renewSession(at time: Date) {
        self.sessionRenewedAt = time
    }

    mutating func blockAccess(at time: Date) {
        self.accessBlockedAt = time
    }
}
