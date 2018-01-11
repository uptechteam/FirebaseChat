//
//  QueueScheduler+Chat.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/12/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import ReactiveSwift

extension QueueScheduler {
    public static let messages = QueueScheduler(qos: .background, name: "com.uptechteam.uptechchat.messages", targeting: nil)
}
