//
//  UserProvider.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/11/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

final class UserProvider {
    static let shared = UserProvider()

    var currentUser: Property<User> {
        let user = User(name: UIDevice.current.name)
        return Property(value: user)
    }
}
