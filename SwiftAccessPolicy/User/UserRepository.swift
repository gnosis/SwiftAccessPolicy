//
//  UserRepository.swift
//  SwiftAccessPolicy
//
//  Created by Andrey Scherbovich on 25.03.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

public protocol UserRepository {
    func save(user: User)
    func delete(user: User)
    func user(userID: UUID) -> User?
    func users() -> [User]
}
