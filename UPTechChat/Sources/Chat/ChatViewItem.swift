//
//  ChatViewItem.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/8/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import Foundation

struct ChatViewMessageContent {
    let title: String?
    let body: String
    let isCurrentSender: Bool
    let isCrooked: Bool
    let hiddenText: String
}

extension ChatViewMessageContent: Equatable {
    static func ==(lhs: ChatViewMessageContent, rhs: ChatViewMessageContent) -> Bool {
        return lhs.title == rhs.title &&
            lhs.body == rhs.body &&
            lhs.isCurrentSender == rhs.isCurrentSender &&
            lhs.isCrooked == rhs.isCrooked &&
            lhs.hiddenText == rhs.hiddenText
    }
}

enum ChatViewItem {
    case loading
    case header(String)
    case message(ChatViewMessageContent)
}

extension ChatViewItem: Equatable {
    static func ==(lhs: ChatViewItem, rhs: ChatViewItem) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case let (.header(lText), .header(rText)):
            return lText == rText
        case let (.message(lhsContent), .message(rhsContent)):
            return lhsContent == rhsContent
        default:
            return false
        }
    }
}
