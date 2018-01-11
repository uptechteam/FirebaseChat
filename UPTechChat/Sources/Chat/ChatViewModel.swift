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

private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM d, h:mm a"
    return dateFormatter
}()

final class ChatViewModel {
    let items: Property<[ChatViewItem]>
    let clearInputText: Signal<Void, NoError>

    let inputTextChangesObserver: Signal<String, NoError>.Observer
    let sendButtonTapObserver: Signal<Void, NoError>.Observer

    init(messagesProvider: MessagesProvider, userProvider: UserProvider, chatEntity: FirebaseEntity<Chat>) {
        let (inputTextChanges, inputTextChangesObserver) = Signal<String, NoError>.pipe()
        let (sendButtonTap, sendButtonTapObserver) = Signal<Void, NoError>.pipe()

        let (_clearInputText, _clearInputTextObserver) = Signal<Void, NoError>.pipe()
        let inputText = Property<String>(
            initial: "",
            then: Signal.merge([
                inputTextChanges,
                _clearInputText.map { _ in "" }
            ])
        )

        let currentUser = userProvider.currentUser

        let messages = messagesProvider.fetchMessageEntities(chatEntity: chatEntity, loadMoreMessages: Signal<Void, NoError>.never)
        let items = messages
            .combineLatest(with: currentUser)
            .map { (messages, currentUser) -> [ChatViewItem] in
                var items = [ChatViewItem]()
                for index in (0..<messages.count) {
                    let previousMessage: FirebaseEntity<Message>? = index > 0 ? messages[index - 1] : nil
                    let message = messages[index]

                    if (previousMessage.map { message.model.date.timeIntervalSince($0.model.date) > 300 } ?? true) {
                        items.append(.header(dateFormatter.string(from: message.model.date)))
                    }

                    let body = message.model.body
                    let isCurrentSender = message.model.sender == currentUser
                    let shouldShowTitle = !isCurrentSender && previousMessage?.model.sender != message.model.sender
                    let title: String? = shouldShowTitle ? message.model.sender.name : nil
                    let content = ChatViewMessageContent(title: title, body: body, isCurrentSender: isCurrentSender)
                    items.append(ChatViewItem.message(content))
                }
                return items
            }

        let clearInputText = inputText.signal
            .sample(on: sendButtonTap)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .withLatest(from: currentUser.producer)
            .flatMap(.latest) { (text, currentUser) -> SignalProducer<Void, NoError> in
                let message = Message(body: text, date: Date(), sender: currentUser)
                return messagesProvider.post(message: message, to: chatEntity)
                    .flatMapError { _ in SignalProducer<Void, NoError>.empty }
            }
            .on(value: _clearInputTextObserver.send)

        self.items = items
        self.clearInputText = clearInputText
        self.inputTextChangesObserver = inputTextChangesObserver
        self.sendButtonTapObserver = sendButtonTapObserver
    }
}
