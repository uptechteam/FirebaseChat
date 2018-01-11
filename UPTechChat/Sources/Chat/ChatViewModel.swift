//
//  ChatViewModel.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/8/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import ReactiveSwift
import ReactiveCocoa
import Result

final class ChatViewModel {
    let items: Property<[ChatViewItem]>

    let viewWillAppear: Signal<Void, NoError>.Observer

    init() {
        let (viewWillAppear, viewWillAppearObserver) = Signal<Void, NoError>.pipe()

        let itemsFlow = viewWillAppear
            .flatMap(.latest) { () -> SignalProducer<[ChatViewItem], NoError> in
                let timer = SignalProducer.timer(interval: .seconds(5), on: QueueScheduler.main)

                return timer
                    .scan([ChatViewItem.loading]) { (accum, _) -> [ChatViewItem] in
                        let isCurrentSender = arc4random_uniform(2) == 1
                        let array = Array<ChatViewItem>(repeating: ChatViewItem.message(ChatViewMessageContent(body: "Hello world!", isCurrentSender: isCurrentSender)), count: 1)
                        return accum + [ChatViewItem.header("Monday, 12:00AM")] + array
                    }
            }

        let items = Property<[ChatViewItem]>(initial: [], then: itemsFlow)

        self.items = items
        self.viewWillAppear = viewWillAppearObserver
    }
}
