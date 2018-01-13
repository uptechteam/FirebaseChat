//
//  ChatsViewItem.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/12/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import UIKit

enum ChatsViewItem {
    case loading
    case chat(title: String, subtitle: String)
    case info(title: String, message: String)
}

extension ChatsViewItem: Equatable {
    static func ==(lhs: ChatsViewItem, rhs: ChatsViewItem) -> Bool {
        switch (lhs, rhs) {
        case let (.chat(lTitle, lSubtitle), .chat(rTitle, rSubtitle)):
            return lTitle == rTitle && lSubtitle == rSubtitle
        case let (.info(lTitle, lMessage), .chat(rTitle, rMessage)):
            return lTitle == rTitle && lMessage == rMessage
        default:
            return false
        }
    }
}
