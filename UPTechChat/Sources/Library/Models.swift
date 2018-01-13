//
//  Models.swift
//  UPTechChat
//
//  Created by Evgeny Matviyenko on 1/4/18.
//  Copyright © 2018 upteachteam. All rights reserved.
//

import Foundation
import ObjectMapper

struct Chat {
    let name: String
    let lastMessage: Message?
}

extension Chat: ImmutableMappable {
    private enum Keys {
        static let Name = "name"
        static let LastMessage = "lastMessage"
    }

    init(map: Map) throws {
        name = try map.value(Keys.Name)
        lastMessage = try? map.value(Keys.LastMessage)
    }

    func mapping(map: Map) {
        name >>> map[Keys.Name]
        lastMessage >>> map[Keys.LastMessage]
    }
}

struct Message {
    let body: String
    let date: Date
    let sender: User
}

extension Message: ImmutableMappable {
    private enum Keys {
        static let Body = "body"
        static let Date = "date"
        static let Sender = "sender"
    }

    init(map: Map) throws {
        body = try map.value(Keys.Body)
        date = try map.value(Keys.Date, using: DateTransform())
        sender = try map.value(Keys.Sender)
    }

    func mapping(map: Map) {
        body >>> map[Keys.Body]
        date >>> (map[Keys.Date], DateTransform())
        sender >>> map[Keys.Sender]
    }
}

struct User {
    let name: String
}

extension User: ImmutableMappable {
    private enum Keys {
        static let Name = "name"
    }

    init(map: Map) throws {
        name = try map.value(Keys.Name)
    }

    func mapping(map: Map) {
        name >>> map[Keys.Name]
    }
}

extension User: Equatable {
    static func ==(lhs: User, rhs: User) -> Bool {
        return lhs.name == rhs.name
    }
}
