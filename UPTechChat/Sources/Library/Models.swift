//
//  Models.swift
//  UPTechChat
//
//  Created by Evgeny Matviyenko on 1/4/18.
//  Copyright © 2018 upteachteam. All rights reserved.
//

import Foundation
import ObjectMapper

struct FirebaseEntity<Model> {
    let identifier: String
    let model: Model
}

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

enum LocalMessageContent {
    case text(String)
    case image(data: Data, type: String)
}

extension LocalMessageContent: Equatable {
    static func ==(lhs: LocalMessageContent, rhs: LocalMessageContent) -> Bool {
        switch (lhs, rhs) {
        case let (.text(lText), .text(rText)):
            return lText == rText
        case let (.image(lData, lType), .image(rData, rType)):
            return lData == rData && lType == rType
        default:
            return false
        }
    }
}

extension LocalMessageContent: Hashable {
    var hashValue: Int {
        switch self {
        case .text(let text):
            return "Text".hashValue ^
                text.hashValue
        case .image(let data, let type):
            return "Image".hashValue ^
                data.hashValue ^
                type.hashValue
        }
    }
}

struct LocalMessage {
    let date: Date
    let sender: User
    let content: LocalMessageContent
}

extension LocalMessage: Equatable {
    static func ==(lhs: LocalMessage, rhs: LocalMessage) -> Bool {
        return lhs.date.timeIntervalSince1970 == rhs.date.timeIntervalSince1970 &&
            lhs.sender == rhs.sender &&
            lhs.content == rhs.content
    }
}

extension LocalMessage: Hashable {
    var hashValue: Int {
        return date.timeIntervalSince1970.hashValue ^
            sender.hashValue ^
            content.hashValue
    }
}

enum MessageType: String {
    case text
    case image
}

struct Message {
    let date: Date
    let sender: User
    let contentType: MessageType
    let text: String?
    let image: URL?
}

extension Message: ImmutableMappable {
    private enum Keys {
        static let Date = "date"
        static let Sender = "sender"
        static let ContentType = "contentType"
        static let Text = "text"
        static let Image = "image"
    }

    init(map: Map) throws {
        date = try map.value(Keys.Date, using: DateTransform())
        sender = try map.value(Keys.Sender)
        contentType = try map.value(Keys.ContentType)
        text = try? map.value(Keys.Text)
        image = try? map.value(Keys.Image, using: URLTransform())
    }

    func mapping(map: Map) {
        date >>> (map[Keys.Date], DateTransform())
        sender >>> map[Keys.Sender]
        contentType >>> map[Keys.ContentType]
        text >>> map[Keys.Text]
        image >>> (map[Keys.Image], URLTransform())
    }
}

extension Message: Equatable {
    static func ==(lhs: Message, rhs: Message) -> Bool {
        return lhs.date.timeIntervalSince1970 == rhs.date.timeIntervalSince1970 &&
            lhs.sender == rhs.sender &&
            lhs.contentType == rhs.contentType &&
            lhs.text == rhs.text &&
            lhs.image == rhs.image
    }
}

extension Message: Hashable {
    var hashValue: Int {
        var hash = date.timeIntervalSince1970.hashValue ^
            sender.hashValue ^
            contentType.hashValue

        if let text = text {
            hash ^= text.hashValue
        }

        if let image = image {
            hash ^= image.absoluteString.hashValue
        }

        return hash
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

extension User: Hashable {
    var hashValue: Int { return name.hashValue }
}
