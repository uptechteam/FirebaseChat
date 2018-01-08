//
//  ChatViewItem.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/8/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import Foundation

struct ChatViewMessageContent {
    let body: String
    let isCurrentSender: Bool
}

extension ChatViewMessageContent: Equatable {
    static func ==(lhs: ChatViewMessageContent, rhs: ChatViewMessageContent) -> Bool {
        return lhs.body == rhs.body &&
            lhs.isCurrentSender == rhs.isCurrentSender
    }
}

enum ChatViewItem {
    case message(ChatViewMessageContent)
}

extension ChatViewItem: Equatable {
    static func ==(lhs: ChatViewItem, rhs: ChatViewItem) -> Bool {
        switch (lhs, rhs) {
        case let (.message(lhsContent), .message(rhsContent)):
            return lhsContent == rhsContent
        }
    }
}
