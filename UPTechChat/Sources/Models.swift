//
//  Models.swift
//  UPTechChat
//
//  Created by Evgeny Matviyenko on 1/4/18.
//  Copyright © 2018 upteachteam. All rights reserved.
//

import Foundation

protocol FirebaseSerializable {
    var identifier: String { get }
    var jsonValue: [String: Any] { get }
    init?(identifier: String, json: [String: Any])
}

struct Chat: FirebaseSerializable {
    let identifier: String
    let name: String
    let lastMessage: String

    init?(identifier: String, json: [String : Any]) {
        guard
            let name = json["name"] as? String,
            let lastMessage = json["lastMessage"] as? String
        else {
            return nil
        }

        self.identifier = identifier
        self.name = name
        self.lastMessage = lastMessage
    }

    var jsonValue: [String : Any] {
        return [
            "name": name,
            "lastMessage": lastMessage
        ]
    }
}

struct Message: FirebaseSerializable {
    let identifier: String
    let body: String

    init?(identifier: String, json: [String : Any]) {
        guard let body = json["body"] as? String else {
            return nil
        }

        self.identifier = identifier
        self.body = body
    }

    var jsonValue: [String : Any] {
        return ["body": body]
    }
}
