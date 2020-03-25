//
//  User.swift
//  SwiftAccessPolicy
//
//  Created by Andrey Scherbovich on 25.03.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

public protocol User {
    var id: UUID { get }
    var encryptedPassword: String { get }
    var sessionRenewedAt: Date? { get set }
    var faileAuthAttempts: Int? { get set }
    var accessBlockedAt: Date? { get set }

    func updatePassword(encryptedPassword: String)
    func renewSession(at time: Date)
    func blockAccess(at time: Date)
}
