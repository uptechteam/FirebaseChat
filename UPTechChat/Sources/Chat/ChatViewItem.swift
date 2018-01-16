//
//  ChatViewItem.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/8/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import Foundation

enum Image {
    case raw(data: Data, type: String)
    case url(URL)
}

extension Image: Equatable {
    static func ==(lhs: Image, rhs: Image) -> Bool {
        switch (lhs, rhs) {
        case let (.raw(lData, lType), .raw(rData, rType)):
            return lData == rData && lType == rType
        case let (.url(lUrl), .url(rUrl)):
            return lUrl == rUrl
        default:
            return false
        }
    }
}

enum ChatViewMessageContentType {
    case text(String)
    case image(image: Image, loadingProgress: Double?)
}

extension ChatViewMessageContentType: Equatable {
    static func ==(lhs: ChatViewMessageContentType, rhs: ChatViewMessageContentType) -> Bool {
        switch (lhs, rhs) {
        case let (.text(lText), .text(rText)):
            return lText == rText
        case let (.image(lImage, lLoadingProgress), .image(rImage, rLoadingProgress)):
            return lImage == rImage && lLoadingProgress == rLoadingProgress
        default:
            return false
        }
    }
}

struct ChatViewMessageContent {
    let type: ChatViewMessageContentType
    let title: String?
    let isCurrentSender: Bool
    let isCrooked: Bool
    let hiddenText: String
    let statusText: String?
    let isRetryShown: Bool
}

extension ChatViewMessageContent: Equatable {
    static func ==(lhs: ChatViewMessageContent, rhs: ChatViewMessageContent) -> Bool {
        return lhs.type == rhs.type &&
            lhs.title == rhs.title &&
            lhs.isCurrentSender == rhs.isCurrentSender &&
            lhs.isCrooked == rhs.isCrooked &&
            lhs.hiddenText == rhs.hiddenText &&
            lhs.statusText == rhs.statusText &&
            lhs.isRetryShown == rhs.isRetryShown
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
