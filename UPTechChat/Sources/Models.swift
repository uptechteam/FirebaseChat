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
}

extension Message: ImmutableMappable {
    private enum Keys {
        static let Body = "body"
        static let Date = "date"
    }

    init(map: Map) throws {
        body = try map.value(Keys.Body)
        date = try map.value(Keys.Date, using: DateTransform())
    }

    func mapping(map: Map) {
        body >>> map[Keys.Body]
        date >>> (map[Keys.Date], DateTransform())
    }
}
